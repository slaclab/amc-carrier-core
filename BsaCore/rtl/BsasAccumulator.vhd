-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
--   Accumulates BSA data and writes records to RAM.  Each channel has
--   sum, sum-of-squares, and number of accumulations recorded.
--   Record structure:
--     Each channnel:
--        [12:0]    # of samples accumulated
--        [13:13]   arithm exception in sum (underflow/overflow)
--        [14:14]   arithm exception in var (overflow)
--        [15:15]   fixed (no accumulation)
--        [47:16]   one sample
--        [79:48]   sum of samples
--        [127:80]  sum of squared-samples
--        [159:128] minimum of samples
--        [191:160] maximum of samples
--   The valid signal qualifies acquire, sample, and flush.  It is acknowledged
--   by the ready signal.
--   DSP48E and SRL32CE are called out explicitly for resource optimization.
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 Common Carrier Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library surf;
use surf.StdRtlPkg.all;
use surf.TextUtilPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity BsasAccumulator is

   generic (
      TPD_G          : time                      := 1 ns;
      NUM_CHANNELS_G : integer range 1 to 32     := 31;
      AXIS_CONFIG_G  : AxiStreamConfigType       := ssiAxiStreamConfig(4));
   port (
      clk            : in  sl;
      rst            : in  sl;
      valid          : in  sl;  -- validates acquire, flush
      acquire        : in  sl;
      sample         : in  sl;
      flush          : in  sl;
      diagnosticData : in  slv(31 downto 0);
      diagnosticSqr  : in  slv(47 downto 0);
      diagnosticFixd : in  sl;
      diagnosticSevr : in  sl;
      diagnosticExc  : in  sl;
      ready          : out sl;
      axisMaster     : out AxiStreamMasterType;
      axisSlave      : in  AxiStreamSlaveType);

end entity BsasAccumulator;

architecture rtl of BsasAccumulator is

   type StateType is (IDLE_S, DATA_S, SHIFT_FIFO_S, SHIFT_REG_S);

   type RegType is record
      state         : StateType;
      clear         : sl;
      nacc          : slv       (NUM_CHANNELS_G-1 downto 0);
      sumExcepts    : slv       (NUM_CHANNELS_G-1 downto 0);
      varExcepts    : slv       (NUM_CHANNELS_G-1 downto 0);
      underflow     : sl;
      overflow      : sl;
      flush         : sl;
      trigger       : sl;
      axisMaster    : AxiStreamMasterType;
      ready         : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
     state          => DATA_S,
     clear          => '1',
     nacc           => (others=>'0'),
     sumExcepts     => (others=>'0'),
     varExcepts     => (others=>'0'),
     underflow      => '0',
     overflow       => '0',
     flush          => '0',
     trigger        => '0',
     axisMaster     => axiStreamMasterInit(AXIS_CONFIG_G),
     ready          => '0' );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   --
   --  DSP control: allows summing, latching, and reset for all bits
   --
   signal incDiag       : slv( 1 downto 0);  -- add current value to sums
   signal notFixd       : slv( 1 downto 0);  -- discard sums (only current)

   signal diagSign      : slv( 2 downto 0);
   signal sumsSign      : slv( 2 downto 0);
   signal resNacc       : slv(15 downto 0);
   signal resSmp        : slv(31 downto 0);
   signal resSum        : slv(31 downto 0);
   signal resVar        : slv(47 downto 0);
   signal resMin        : slv(47 downto 0);
   signal resMax        : slv(47 downto 0);
   signal ufSum, ofSum  : sl;
   signal ofVar         : slv(3 downto 0);

   -- srl assignment
   -- [ 12:  0] count
   -- [ 44: 13] sum
   -- [ 95: 48] sum of squares
   -- [127: 96] minimum sample
   -- [159:128] maximum sample
   -- [191:160] single sample
   signal srlCE         : sl;
   signal srlIn         : slv(191 downto 0);
   signal srlOut        : slv(191 downto 0);

   signal diagnosticExt : slv(47 downto 0);
   signal diagnosticMin : slv(47 downto 0);
   signal diagnosticMax : slv(47 downto 0);

   --  Vivado "optimizes" the DSP48E2 and breaks the rules (REQP-1667)
   attribute keep_hierarchy : string;
   attribute keep_hierarchy of U_SUM : label is "yes";

begin

   diagSign <= (others=>diagnosticData(31));
   sumsSign <= (others=>srlOut(44));

   -- make a subtraction to determine comparison with min/max
   U_MIN : DSP48E2
     generic map ( ACASCREG   => 0,  -- unused
                   ADREG      => 0,
                   ALUMODEREG => 0,
                   AREG       => 0,  -- no regs before ADD
                   BCASCREG   => 0,
                   BREG       => 0,
                   CARRYINREG => 0,
                   CARRYINSELREG => 0,
                   CREG       => 0,
                   DREG       => 0,
                   INMODEREG  => 0,
                   MREG       => 0,
                   OPMODEREG  => 0,
                   USE_MULT   => "NONE",
                   USE_PATTERN_DETECT => "NO_PATDET" )
     port map (
       P                            => resMin,
       A                            => diagnosticMin(47 downto 18),
       ACIN                         => (others=>'0'),
       ALUMODE                      => "0011", -- Z-(X+Y+W)
       B                            => diagnosticMin(17 downto 0),
       BCIN                         => (others=>'0'),
       C                            => diagnosticExt,
       CARRYCASCIN                  => '0',
       CARRYIN                      => '0',
       CARRYINSEL                   => "000",
       CEA1                         => '0',
       CEA2                         => '0',
       CEAD                         => '0',
       CEALUMODE                    => '1',
       CEB1                         => '0',
       CEB2                         => '0',
       CEC                          => '0',
       CECARRYIN                    => '0',
       CECTRL                       => '1',
       CED                          => '0',
       CEINMODE                     => '1',
       CEM                          => '0',
       CEP                          => '1',
       CLK                          => clk,
       D                            => (others=>'0'),
       INMODE                       => "00000",
       MULTSIGNIN                   => '0',
       OPMODE      (8 downto 7)     => "00",
       OPMODE      (6 downto 4)     => "011",  -- Z = C
       OPMODE      (3 downto 2)     => "00", 
       OPMODE      (1 downto 0)     => "11",   -- X = A|B
       PCIN                         => (others=>'0'),  -- unused
       RSTA                         => '0',
       RSTALLCARRYIN                => '0',
       RSTALUMODE                   => '0',
       RSTB                         => '0',
       RSTC                         => '0',
       RSTCTRL                      => '0',
       RSTD                         => '0',
       RSTINMODE                    => '0',
       RSTM                         => '0',
       RSTP                         => rst,
       UNDERFLOW                    => open,
       OVERFLOW                     => open
       );

   U_MAX : DSP48E2
     generic map ( ACASCREG   => 0,  -- unused
                   ADREG      => 0,
                   ALUMODEREG => 0,
                   AREG       => 0,  -- no regs before ADD
                   BCASCREG   => 0,
                   BREG       => 0,
                   CARRYINREG => 0,
                   CARRYINSELREG => 0,
                   CREG       => 0,
                   DREG       => 0,
                   INMODEREG  => 0,
                   MREG       => 0,
                   OPMODEREG  => 0,
                   USE_MULT   => "NONE",
                   USE_PATTERN_DETECT => "NO_PATDET" )
     port map (
       P                            => resMax,
       A                            => diagnosticMax(47 downto 18),
       ACIN                         => (others=>'0'),
       ALUMODE                      => "0011", -- Z-(X+Y+W)
       B                            => diagnosticMax(17 downto 0),
       BCIN                         => (others=>'0'),
       C                            => diagnosticExt,
       CARRYCASCIN                  => '0',
       CARRYIN                      => '0',
       CARRYINSEL                   => "000",
       CEA1                         => '0',
       CEA2                         => '0',
       CEAD                         => '0',
       CEALUMODE                    => '1',
       CEB1                         => '0',
       CEB2                         => '0',
       CEC                          => '0',
       CECARRYIN                    => '0',
       CECTRL                       => '1',
       CED                          => '0',
       CEINMODE                     => '1',
       CEM                          => '0',
       CEP                          => '1',
       CLK                          => clk,
       D                            => (others=>'0'),
       INMODE                       => "00000",
       MULTSIGNIN                   => '0',
       OPMODE      (8 downto 7)     => "00",
       OPMODE      (6 downto 4)     => "011",  -- Z = C
       OPMODE      (3 downto 2)     => "00", 
       OPMODE      (1 downto 0)     => "11",   -- X = A|B
       PCIN                         => (others=>'0'),  -- unused
       RSTA                         => '0',
       RSTALLCARRYIN                => '0',
       RSTALUMODE                   => '0',
       RSTB                         => '0',
       RSTC                         => '0',
       RSTCTRL                      => '0',
       RSTD                         => '0',
       RSTINMODE                    => '0',
       RSTM                         => '0',
       RSTP                         => rst,
       UNDERFLOW                    => open,
       OVERFLOW                     => open
       );

   --  A|B  is the new data
   --  A[29:27] sign-ext, A[26:0] data[31:5], B[17:13] data[4:0], B[12:0] count
   --  C    is the old data
   --  incDiag determines whether new data is added
   --  notFixd determines whether there is a replacement or a sum with old data
   U_SUM : DSP48E2
     generic map ( ACASCREG   => 0,  -- unused
                   ADREG      => 0,
                   ALUMODEREG => 0,
                   AREG       => 0,  -- no regs before ADD
                   BCASCREG   => 0,
                   BREG       => 0,
                   CARRYINREG => 0,
                   CARRYINSELREG => 0,
                   CREG       => 0,
                   DREG       => 0,
                   INMODEREG  => 0,
                   MREG       => 0,
                   OPMODEREG  => 0,
                   USE_MULT   => "NONE",
                   USE_PATTERN_DETECT => "PATDET" )
     port map (
     P          (47 downto 16)    => resSum,
     P          (15 downto  0)    => resNacc,
     A          (29 downto  0)    => diagnosticData(31 downto 2),
     ACIN                         => (others=>'0'),
     ALUMODE                      => "0000", -- Z+W+X+Y+CIN
     B          (17 downto 16)    => diagnosticData(1 downto 0),
     B          (15 downto  0)    => toSlv(1,16),
     BCIN                         => (others=>'0'),
     C          (47 downto 45)    => sumsSign,
     C          (44 downto  0)    => srlOut(44 downto 0),
     CARRYCASCIN                  => '0',
     CARRYIN                      => '0',
     CARRYINSEL                   => "000",
     CEA1                         => '0',
     CEA2                         => '0',
     CEAD                         => '0',
     CEALUMODE                    => '1',
     CEB1                         => '0',
     CEB2                         => '0',
     CEC                          => '0',
     CECARRYIN                    => '0',
     CECTRL                       => '1',
     CED                          => '0',
     CEINMODE                     => '1',
     CEM                          => '0',
     CEP                          => '1',
     CLK                          => clk,
     D                            => (others=>'0'),
     INMODE                       => "00000",
     MULTSIGNIN                   => '0',
     OPMODE      (8 downto 4)     => "00000",
     OPMODE      (3 downto 2)     => notFixd,  -- include C
     OPMODE      (1 downto 0)     => incDiag,  -- include A|B
     PCIN                         => (others=>'0'),  -- unused
     RSTA                         => '0',
     RSTALLCARRYIN                => '0',
     RSTALUMODE                   => '0',
     RSTB                         => '0',
     RSTC                         => '0',
     RSTCTRL                      => '0',
     RSTD                         => '0',
     RSTINMODE                    => '0',
     RSTM                         => '0',
     RSTP                         => rst,
     UNDERFLOW                    => ufSum,
     OVERFLOW                     => ofSum
       );

   --  A|B  is the new data
   --  C    is the old data
   --  incDiag determines whether new data is added
   --  notFixd determines whether there is a replacement or a sum with old data
   U_VAR : DSP48E2
     generic map ( ACASCREG   => 0,  -- unused
                   ADREG      => 0,
                   ALUMODEREG => 0,
                   AREG       => 0,  -- no regs before ADD
                   BCASCREG   => 0,
                   BREG       => 0,
                   CARRYINREG => 0,
                   CARRYINSELREG => 0,
                   CREG       => 0,
                   DREG       => 0,
                   INMODEREG  => 0,
                   MREG       => 0,
                   OPMODEREG  => 0,
                   USE_MULT   => "NONE",
                   USE_PATTERN_DETECT => "NO_PATDET" )
     port map (
     P                            => resVar,
     A                            => diagnosticSqr(47 downto 18),
     ACIN                         => (others=>'0'),
     ALUMODE                      => "0000", -- Z+W+X+Y+CIN
     B                            => diagnosticSqr(17 downto 0),
     BCIN                         => (others=>'0'),
     C                            => srlOut(95 downto 48),
     CARRYCASCIN                  => '0',
     CARRYIN                      => '0',
     CARRYINSEL                   => "000",
     CARRYOUT                     => ofVar,
     CEA1                         => '0',
     CEA2                         => '0',
     CEAD                         => '0',
     CEALUMODE                    => '1',
     CEB1                         => '0',
     CEB2                         => '0',
     CEC                          => '0',
     CECARRYIN                    => '0',
     CECTRL                       => '1',
     CED                          => '0',
     CEINMODE                     => '1',
     CEM                          => '0',
     CEP                          => '1',
     CLK                          => clk,
     D                            => (others=>'0'),
     INMODE                       => "00000",
     MULTSIGNIN                   => '0',
     OPMODE      (8 downto 4)     => "00000",
     OPMODE      (3 downto 2)     => notFixd,  -- include C
     OPMODE      (1 downto 0)     => incDiag,  -- include A|B
     PCIN                         => (others=>'0'),  -- unused
     RSTA                         => '0',
     RSTALLCARRYIN                => '0',
     RSTALUMODE                   => '0',
     RSTB                         => '0',
     RSTC                         => '0',
     RSTCTRL                      => '0',
     RSTD                         => '0',
     RSTINMODE                    => '0',
     RSTM                         => '0',
     RSTP                         => rst
       );

   GEN_SRL : for i in srlOut'range generate
     U_SRL : SRLC32E
       port map ( Q   => srlOut(i),
                  A   => toSlv(NUM_CHANNELS_G-1,5),
                  CE  => srlCE,
                  CLK => clk,
                  D   => srlIn(i) );
   end generate GEN_SRL;

   --  Results are shifted in on SHIFT_REG_S state
   srlCE <= '1' when r.state = SHIFT_REG_S else '0';
   srlIn( 95 downto   0) <= resVar & resSum(31 downto 0) & resNacc;
   srlIn(127 downto  96) <= diagnosticMin(31 downto 0) when (resMin(32)='0' and r.clear='0') else diagnosticData;
   srlIn(159 downto 128) <= diagnosticMax(31 downto 0) when (resMax(32)='1' and r.clear='0') else diagnosticData;
   srlIn(191 downto 160) <= resSmp when sample='0' else diagnosticData;

   --  sign extend the data for 48-bit computations
   diagnosticExt <= resize(diagnosticData,48,diagnosticData(31));
   diagnosticMin <= resize(srlOut(127 downto  96),48,srlOut(127));
   diagnosticMax <= resize(srlOut(159 downto 128),48,srlOut(159));
   resSmp        <= srlOut(191 downto 160);
     
   comb : process (diagnosticSevr, diagnosticFixd, diagnosticExc,
                   resNacc, resSum, resSmp, resVar, ufSum, ofSum, ofVar, incDiag,
                   acquire, flush, valid,
                   r, rst) is
      variable v : RegType;
   begin
      v := r;

      v.axisMaster.tValid := '0';
      v.axisMaster.tLast  := '0';
      v.ready             := '0';
      
      case r.state is
        when IDLE_S =>
          if valid = '1' then
            if flush = '1' then
              v.state := SHIFT_FIFO_S;
            else
              v.state := DATA_S;
            end if;
          end if;

        when SHIFT_FIFO_S =>
          v.axisMaster.tValid := '1';
          v.axisMaster.tData(191 downto 128) := srlOut(159 downto 96);
          v.axisMaster.tData(127 downto  64) := srlOut( 95 downto 32);
          v.axisMaster.tData( 63 downto   0) := srlOut( 31 downto 16) &
                                                srlOut(191 downto 160) &
                                                diagnosticFixd &
                                                (r.varExcepts(0) or ofVar(3) or
                                                 (diagnosticExc and incDiag(0)) or uOr(resNacc(15 downto 13))) &
                                                (r.sumExcepts(0) or ufSum or ofSum or uOr(resNacc(15 downto 13))) &
                                                srlOut(12 downto 0);
          v.axisMaster.tLast  := '1';
          
          v.clear     := '1';
          v.state     := DATA_S;

        when DATA_S =>
          if diagnosticFixd = '1' or sample = '1' then
            notFixd     <= "00";  -- not keeping a sum (replacing)
          else
            notFixd     <= "11";  -- keeping a sum
          end if;

          if acquire = '1' and diagnosticSevr = '0' then
            incDiag     <= "11";  -- adding the new data
          else
            incDiag     <= "00";  -- not adding the new data
          end if;
          v.state     := SHIFT_REG_S;

        when SHIFT_REG_S =>
          --  Shift right
          v.sumExcepts(NUM_CHANNELS_G-2 downto 0) := r.sumExcepts(NUM_CHANNELS_G-1 downto 1);
          v.varExcepts(NUM_CHANNELS_G-2 downto 0) := r.varExcepts(NUM_CHANNELS_G-1 downto 1);

          --  Shift in others
          if flush = '1' then
            v.sumExcepts(NUM_CHANNELS_G-1) := '0';
            v.varExcepts(NUM_CHANNELS_G-1) := '0';
            v.underflow := '0';
            v.overflow  := '0';
          else
            --  Shift updated result to back (left)
            v.sumExcepts(NUM_CHANNELS_G-1) := r.sumExcepts(0) or ufSum or ofSum;
            v.varExcepts(NUM_CHANNELS_G-1) := r.varExcepts(0) or ofVar(3) or diagnosticExc;
          end if;
          v.clear     := '0';
          v.ready     := '1';
          v.state     := IDLE_S;
        when others => NULL;
      end case;

      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      rin         <= v;
      axisMaster  <= r.axisMaster;
   end process comb;

   ready  <= rin.ready;
   
   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
