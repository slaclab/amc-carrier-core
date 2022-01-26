-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
--   Accumulates BSA data and writes records to RAM.  Each channel has
--   sum, sum-of-squares, and number of accumulations recorded.
--   Record structure:
--     Each channnel:
--        [12:0]  # of samples accumulated
--        [13:13]  arithm exception in sum (underflow/overflow)
--        [14:14]  arithm exception in var (overflow)
--        [15:15]  fixed (no accumulation)
--        [47:16]  sum of samples
--        [95:48]  sum of squared-samples
--   No data is accumulated when BsaInit is asserted, but sevr validation
--   settings are latched from BsaActive, BsaAvgDone.
--   BsaDone may be asserted multiple times to allow flushing of data waiting
--   in the FIFO during slower acquisitions.
--   Five clock cycles are guaranteed between accumulateEn and another
--   accumulateEn; 1 cycle for math; 3 cycles for pushing to fifo; 1
--   cycle for shift register input (possible zeroing). DSP48E and SRL32CE
--   are called out explicitly for resource optimization.
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

entity BsaAccumulator is

   generic (
      TPD_G               : time                      := 1 ns;
      BSA_NUMBER_G        : integer range 0 to 64     := 0;
      NUM_ACCUMULATIONS_G : integer range 1 to 32     := 32;
      FRAME_SIZE_BYTES_G  : integer range 128 to 4096 := 2048;
      AXIS_CONFIG_G       : AxiStreamConfigType       := ssiAxiStreamConfig(4));

   port (
      clk : in sl;
      rst : in sl;

      enable         : in  sl;
      bsaInit        : in  sl;
      bsaActive      : in  sl;
      bsaAvgDone     : in  sl;
      bsaDone        : in  sl;
      bsaOverflow    : out sl;
      diagnosticData : in  slv(31 downto 0);
      diagnosticSqr  : in  slv(47 downto 0);
      diagnosticFixd : in  sl;
      diagnosticSevr : in  slv( 1 downto 0);
      diagnosticExc  : in  sl;
      accumulateEn   : in  sl;
      lastEn         : in  sl;
      axisMaster     : out AxiStreamMasterType := axiStreamMasterInit(AXIS_CONFIG_G);
      axisSlave      : in  AxiStreamSlaveType);

end entity BsaAccumulator;

architecture rtl of BsaAccumulator is

   type StateType is (DATA_S, SHIFT_FIFO1_S, SHIFT_FIFO2_S, SHIFT_FIFO3_S, SHIFT_REG_S);

   type RegType is record
      enabled       : sl;
      state         : StateType;
      sevr          : slv(1 downto 0);
      sumExcepts    : slv       (NUM_ACCUMULATIONS_G-1 downto 0);
      varExcepts    : slv       (NUM_ACCUMULATIONS_G-1 downto 0);
      fifoWrEn      : slv(2 downto 0);
      fifoDinP      : slv(2 downto 0);
      underflow     : sl;
      overflow      : sl;
      tValid        : sl;
      tLast         : sl;
      done          : sl;
      trigger       : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
     enabled        => '0',
     state          => DATA_S,
     sevr           => "00",
     sumExcepts     => (others=>'0'),
     varExcepts     => (others=>'0'),
     fifoWrEn       => "000",
     fifoDinP       => "000",
     underflow      => '0',
     overflow       => '0',
     tValid         => '0',
     tLast          => '0',
     done           => '0',
     trigger        => '0' );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   --
   --  DSP control: allows summing, latching, and reset for all bits
   --
   signal incDiag       : slv( 1 downto 0);  -- add current value to sums
   signal notFixd       : slv( 1 downto 0);  -- discard sums (only current)

   signal diagSign      : slv( 2 downto 0);
   signal sumsSign      : slv( 2 downto 0);
   signal resNacc       : slv(12 downto 0);
   signal resSum        : slv(34 downto 0);
   signal resVar        : slv(47 downto 0);
   signal ufSum, ofSum  : sl;
   signal ofVar         : slv(3 downto 0);

   signal srlCE         : sl;
   signal srlIn         : slv(95 downto 0);
   signal srlOut        : slv(95 downto 0);

   signal fifoRst       : sl;
   signal fifoFull      : sl;
   signal fifoProgFull  : sl;
   signal fifoWrCount   : slv(13 downto 0);
   signal fifoDin       : slv(31 downto 0);
   signal fifoDout      : slv(63 downto 0);
   signal fifoDoutP     : slv(7 downto 0)  := (others => '0');
   signal fifoRdEn      : sl;
   signal fifoEmpty     : sl;
   signal fifoProgEmpty : sl;
   signal fifoRdCount   : slv(13 downto 0);

   --  Vivado "optimizes" the DSP48E2 and breaks the rules (REQP-1667)
   attribute keep_hierarchy : string;
   attribute keep_hierarchy of U_SUM : label is "yes";

begin

   -- Maybe pass bsaDone on tUser so that we can track when it gets to ram.

   fifoRst <= rst or bsaInit or not r.enabled;

   FIFO36E2_inst : FIFO36E2
      generic map (
         CASCADE_ORDER           => "NONE",                 -- FIRST, LAST, MIDDLE, NONE, PARALLEL
         CLOCK_DOMAINS           => "COMMON",               -- COMMON, INDEPENDENT
         EN_ECC_PIPE             => "FALSE",                -- ECC pipeline register, (FALSE, TRUE)
         EN_ECC_READ             => "FALSE",                -- Enable ECC decoder, (FALSE, TRUE)
         EN_ECC_WRITE            => "FALSE",                -- Enable ECC encoder, (FALSE, TRUE)
         FIRST_WORD_FALL_THROUGH => "TRUE",                 -- FALSE, TRUE
         INIT                    => X"000000000000000000",  -- Initial values on output port
         PROG_EMPTY_THRESH       => 42,                      -- Programmable Empty Threshold
         PROG_FULL_THRESH        => 511,                    -- Programmable Full Threshold
         -- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
         IS_RDCLK_INVERTED       => '0',                    -- Optional inversion for RDCLK
         IS_RDEN_INVERTED        => '0',                    -- Optional inversion for RDEN
         IS_RSTREG_INVERTED      => '0',                    -- Optional inversion for RSTREG
         IS_RST_INVERTED         => '0',                    -- Optional inversion for RST
         IS_WRCLK_INVERTED       => '0',                    -- Optional inversion for WRCLK
         IS_WREN_INVERTED        => '0',                    -- Optional inversion for WREN
         RDCOUNT_TYPE            => "RAW_PNTR",             -- EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
         READ_WIDTH              => 72,                     -- 18-9
         REGISTER_MODE           => "REGISTERED",         -- DO_PIPELINED, REGISTERED, UNREGISTERED
         RSTREG_PRIORITY         => "RSTREG",               -- REGCE, RSTREG
         SLEEP_ASYNC             => "FALSE",                -- FALSE, TRUE
         SRVAL                   => X"000000000000000000",  -- SET/reset value of the FIFO outputs
         WRCOUNT_TYPE            => "EXTENDED_DATACOUNT",             -- EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
         WRITE_WIDTH             => 36                      -- 18-9
         )
      port map (
         -- Cascade Signals outputs: Multi-FIFO cascade signals
         CASDOUT       => open,                             -- 64-bit output: Data cascade output bus
         CASDOUTP      => open,                             -- 8-bit output: Parity data cascade output bus
         CASNXTEMPTY   => open,                             -- 1-bit output: Cascade next empty
         CASPRVRDEN    => open,                             -- 1-bit output: Cascade previous read enable
         -- ECC Signals outputs: Error Correction Circuitry ports
         DBITERR       => open,                             -- 1-bit output: Double bit error status
         ECCPARITY     => open,                             -- 8-bit output: Generated error correction parity
         SBITERR       => open,                             -- 1-bit output: Single bit error status
         -- Read Data outputs: Read output data
         DOUT          => fifoDout,                         -- 64-bit output: FIFO data output bus
         DOUTP         => fifoDoutP,                        -- 8-bit output: FIFO parity output bus.
         -- Status outputs: Flags and other FIFO status outputs
         EMPTY         => fifoEmpty,                        -- 1-bit output: Empty
         FULL          => fifoFull,                         -- 1-bit output: Full
         PROGEMPTY     => fifoProgEmpty,                    -- 1-bit output: Programmable empty
         PROGFULL      => fifoProgFull,                     -- 1-bit output: Programmable full
         RDCOUNT       => fifoRdCount,                      -- 14-bit output: Read count
         RDERR         => open,                             -- 1-bit output: Read error
         RDRSTBUSY     => open,                             -- 1-bit output: Reset busy (sync to RDCLK)
         WRCOUNT       => fifoWrCount,                      -- 14-bit output: Write count
         WRERR         => open,                             -- 1-bit output: Write Error
         WRRSTBUSY     => open,                             -- 1-bit output: Reset busy (sync to WRCLK)
         -- Cascade Signals inputs: Multi-FIFO cascade signals
         CASDIN        => (others => '0'),                  -- 64-bit input: Data cascade input bus
         CASDINP       => (others => '0'),                  -- 8-bit input: Parity data cascade input bus
         CASDOMUX      => '0',                              -- 1-bit input: Cascade MUX select input
         CASDOMUXEN    => '0',                              -- 1-bit input: Enable for cascade MUX select
         CASNXTRDEN    => '0',                              -- 1-bit input: Cascade next read enable
         CASOREGIMUX   => '0',                              -- 1-bit input: Cascade output MUX select
         CASOREGIMUXEN => '0',                              -- 1-bit input: Cascade output MUX select enable
         CASPRVEMPTY   => '0',                              -- 1-bit input: Cascade previous empty
         -- ECC Signals inputs: Error Correction Circuitry ports
         INJECTDBITERR => '0',                              -- 1-bit input: Inject a double bit error
         INJECTSBITERR => '0',                              -- 1-bit input: Inject a single bit error
         -- Read Control Signals inputs: Read clock, enable and reset input signals
         RDCLK         => clk,                              -- 1-bit input: Read clock
         RDEN          => fifoRdEn,                         -- 1-bit input: Read enable
         REGCE         => '1',                              -- 1-bit input: Output register clock enable
         RSTREG        => fifoRst,                          -- 1-bit input: Output register reset
         SLEEP         => '0',                              -- 1-bit input: Sleep Mode
         -- Write Control Signals inputs: Write clock and enable input signals
         RST           => fifoRst,                          -- 1-bit input: Reset
         WRCLK         => clk,                              -- 1-bit input: Write clock
         WREN          => rin.fifoWrEn(0),                  -- 1-bit input: Write enable
         -- Write Data inputs: Write input data
         DIN(63 downto 32) => (others=>'0'),                -- 64-bit input: FIFO data input bus
         DIN(31 downto  0) => fifoDin,
         DINP(7 downto  1) => (others=>'0'),                -- 8-bit input: FIFO parity input bus
         DINP(0)           => rin.fifoDinP(0)
         );

   diagSign <= (others=>diagnosticData(31));
   sumsSign <= (others=>srlOut(44));

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
     P          (47 downto 13)    => resSum,
     P          (12 downto  0)    => resNacc,
     A          (29 downto 27)    => diagSign,
     A          (26 downto  0)    => diagnosticData(31 downto 5),
     ACIN                         => (others=>'0'),
     ALUMODE                      => "0000", -- Z+W+X+Y+CIN
     B          (17 downto 13)    => diagnosticData(4 downto 0),
     B          (12 downto  0)    => toSlv(1,13),
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

   fifoRdEn <= r.tValid and axisSlave.tReady;

   GEN_SRL : for i in 0 to 95 generate
     U_SRL : SRLC32E
       port map ( Q   => srlOut(i),
                  A   => toSlv(NUM_ACCUMULATIONS_G-1,5),
                  CE  => srlCE,
                  CLK => clk,
                  D   => srlIn(i) );
   end generate GEN_SRL;
   srlCE <= '1' when r.state = SHIFT_REG_S else '0';
   srlIn <= resVar & resSum & resNacc;

   assert (r.overflow = '0') report "BsaAccumulator " & str(BSA_NUMBER_G) & " overflowed." severity error;

   comb : process (diagnosticSevr, diagnosticFixd, diagnosticExc,
                   resNacc, resSum, resVar, ufSum, ofSum, ofVar, incDiag,
                   bsaInit, bsaActive, bsaAvgDone, bsaDone,
                   enable, accumulateEn, lastEn, fifoDout, axisSlave,
                   fifoDoutP, fifoFull, fifoEmpty, fifoProgEmpty, fifoProgFull, fifoWrCount, fifoRdCount, fifoRdEn, r, rst) is
      variable v : RegType;
      variable vlast : sl;
   begin
      v := r;

      if enable = '0' then
        v.enabled := '0';
      end if;

      v.fifoWrEn := '0' & r.fifoWrEn(2 downto 1);
      v.fifoDinP(1 downto 0) := r.fifoDinP(2 downto 1);

      if r.state = SHIFT_FIFO1_S then
        fifoDin                <= resSum(15 downto 0) &
                                  diagnosticFixd &
                                  (r.varExcepts(0) or ofVar(3) or
                                   (diagnosticExc and incDiag(0))) &
                                  (r.sumExcepts(0) or ufSum or ofSum) &
                                  resNacc(12 downto 0);
      elsif r.state = SHIFT_FIFO2_S then
        fifoDin                <= resVar(15 downto 0) & resSum(31 downto 16);
      else
        fifoDin                <= resVar(47 downto 16);
      end if;

      if diagnosticFixd = '1' then
        notFixd     <= "00";  -- not keeping a sum (replacing)
      else
        notFixd     <= "11";  -- keeping a sum
      end if;

      if bsaActive = '1' and diagnosticSevr <= r.sevr then
        incDiag     <= "11";  -- adding the new data
      else
        incDiag     <= "00";  -- not adding the new data
      end if;

      case r.state is
        when DATA_S =>
          if accumulateEn = '1' then
            v.state        := SHIFT_FIFO1_S;
          end if;
        when SHIFT_FIFO1_S =>
          --  Queue 3 cycles of FIFO writes
          if bsaActive = '1' and bsaAvgDone = '1' and r.overflow = '0' and bsaInit = '0' then
            v.fifoWrEn  := "111";
          end if;
          v.fifoDinP  := "00" & lastEn; -- Mark coming of end of record
          v.state := SHIFT_FIFO2_S;
        when SHIFT_FIFO2_S =>
          v.state := SHIFT_FIFO3_S;
        when SHIFT_FIFO3_S =>
          --  Clear shift register if init or avg done
          if bsaAvgDone = '1' or bsaInit = '1' then
            incDiag     <= "00";  -- not adding the new data
            notFixd     <= "00";  -- not keeping a sum
          end if;
          v.state     := SHIFT_REG_S;
        when SHIFT_REG_S =>
          --  Shift right
          v.sumExcepts(NUM_ACCUMULATIONS_G-2 downto 0) := r.sumExcepts(NUM_ACCUMULATIONS_G-1 downto 1);
          v.varExcepts(NUM_ACCUMULATIONS_G-2 downto 0) := r.varExcepts(NUM_ACCUMULATIONS_G-1 downto 1);

          --  Shift in others
          if bsaAvgDone = '1' or bsaInit = '1' then
            --  Clear on BsaAvgDone
            v.sumExcepts(NUM_ACCUMULATIONS_G-1) := '0';
            v.varExcepts(NUM_ACCUMULATIONS_G-1) := '0';
          else
            --  Shift updated result to back (left)
            v.sumExcepts(NUM_ACCUMULATIONS_G-1) := r.sumExcepts(0) or ufSum or ofSum;
            v.varExcepts(NUM_ACCUMULATIONS_G-1) := r.varExcepts(0) or ofVar(3) or diagnosticExc;
          end if;
          -- Queue readout for bsaDone (unless nothing to read)
          if (lastEn = '1' and bsaDone = '1' and fifoEmpty = '0') then
            v.done   := '1';
          end if;
          -- Clear under/overflow between records
          if lastEn = '1' then
            v.underflow := '0';
            v.overflow  := '0';
            v.enabled   := enable;
          end if;
          v.state     := DATA_S;
        when others => NULL;
      end case;


      -- Need to gracefully handle case when buffer backs up. Can't store half an entry.
      if (fifoFull = '1' and v.fifoWrEn(0) = '1') then
        v.overflow := '1';             -- Latch overflow if tReady ever drops
        v.enabled  := '0';
      end if;

      if (fifoRdEn = '1' and fifoEmpty = '1') then
        v.underflow := '1';
        v.enabled   := '0';
      end if;

      if (r.tValid = '0' and fifoProgFull = '1') then
         v.tValid := '1';
      end if;

      -- Done forces tValid so that bsaDone readout doesn't get lost if it arrives right after a normal readout
      if r.done = '1' then
         v.tValid := '1';
      end if;

      if (r.tValid = '1' and axisSlave.tReady = '1') then
        v.trigger := '0';
        if (fifoDoutP(4) = '1' and r.done = '1' and fifoProgEmpty = '1') then
          v.tLast   := '1';
          v.trigger := '1';
          v.done    := '0';
        -- Send tLast when 2k Bytes have been read out
        elsif (fifoRdCount(7 downto 0) = toSlv(0,8)) then
          v.tLast := '1';
        end if;

        -- Clear valid when tLast has been read
        if r.tLast = '1' then
          v.tValid := r.done;            -- bsaDone readout might have stacked
          v.tLast  := '0';
        end if;
      end if;


      axisMaster.tValid             <= r.tValid;
      axisMaster.tData(63 downto 0) <= fifoDout;
      axisMaster.tLast              <= r.tLast;
      axisMaster.tDest              <= toSlv(BSA_NUMBER_G, 8);
      axisMaster.tKeep              <= resize(x"00FF",AXI_STREAM_MAX_TKEEP_WIDTH_C);
      axisMaster.tStrb              <= resize(x"00FF",AXI_STREAM_MAX_TKEEP_WIDTH_C);
      axisMaster.tUser(14)          <= r.overflow or r.underflow;    -- EOFE
      axisMaster.tUser(15)          <= r.trigger;                    -- TRIGGER

      ----------------------------------------------------------------------------------------------
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (bsaInit = '1') then
         v.sevr      := bsaAvgDone & bsaActive;  -- latch severity on bsaInit
         v.fifoWrEn  := "000";
         v.overflow  := '0';
         v.tValid    := '0';
         v.tLast     := '0';
         v.done      := '0';
      end if;

      if (rst = '1') then
         v.overflow := '0';
         v.tValid    := '0';
         v.tLast     := '0';
         v.done      := '0';
      end if;

      rin         <= v;
      bsaOverflow <= r.overflow;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
