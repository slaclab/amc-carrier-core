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

entity BsasSampler is

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

end entity BsasSampler;

architecture rtl of BsasSampler is

   type StateType is (IDLE_S, DATA_S, SHIFT_FIFO_S, SHIFT_REG_S);

   type RegType is record
      state         : StateType;
      nacc          : slv       (NUM_CHANNELS_G-1 downto 0);
      data          : Slv32Array(NUM_CHANNELS_G-1 downto 0);
      min           : Slv32Array(NUM_CHANNELS_G-1 downto 0);
      max           : Slv32Array(NUM_CHANNELS_G-1 downto 0);
      axisMaster    : AxiStreamMasterType;
      ready         : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
     state          => IDLE_S,
     nacc           => (others=>'0'),
     data           => (others=>(others=>'0')),
     min            => (others=>(others=>'0')),
     max            => (others=>(others=>'0')),
     axisMaster     => axiStreamMasterInit(AXIS_CONFIG_G),
     ready          => '0' );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (r, rst,
                   diagnosticSevr, diagnosticData, diagnosticSqr,
                   diagnosticFixd,
                   acquire, flush, sample, valid) is
     variable v : RegType;
     variable uval : slv(31 downto 0);
   begin
      v := r;

      v.ready             := '0';
      v.axisMaster.tValid := '0';
      v.axisMaster.tLast  := '0';
      uval                := r.data(0);

      case r.state is
        when IDLE_S =>
          if valid = '1' then
            if flush = '1' then
              v.state := SHIFT_FIFO_S;
            else
              v.state := DATA_S;
            end if;
          end if;
        when DATA_S =>
          if acquire = '1' and sample = '1' and diagnosticSevr = '0' then
            v.data   (0) := diagnosticData;
            v.nacc   (0) := '1';

            -- signed or unsigned?
            if signed(diagnosticData) < signed(r.min(0)) then
              v.min  (0) := v.data(0);
            end if;
            if signed(diagnosticData) > signed(r.max(0)) then
              v.max  (0) := v.data(0);
            end if;
          end if;
          v.state := SHIFT_REG_S;
        when SHIFT_FIFO_S =>
          v.axisMaster.tValid := '1';
          v.axisMaster.tData(191 downto 128) := r.max(0) & r.min(0);
          v.axisMaster.tData(127 downto  64) := toSlv(0,48) & uval(31 downto 16);
          v.axisMaster.tData( 63 downto   0) := uval(15 downto 0) &
                                                uval &
                                                diagnosticFixd & toSlv(0,14) & r.nacc(0);
          v.axisMaster.tLast  := '1';
          v.nacc(0) := '0';
          v.data(0) := (others=>'0');
          v.max (0)(31) := '1';
          v.max (0)(30 downto 0) := (others=>'0');
          v.min (0)(31) := '0';
          v.min (0)(30 downto 0) := (others=>'1');
          v.state     := DATA_S;
        when SHIFT_REG_S =>
          --  Shift in others
          v.data    := v.data(0) & r.data(r.data'left downto 1);
          v.nacc    := v.nacc(0) & r.nacc(r.nacc'left downto 1);
          v.max     := v.max (0) & r.max (r.max'left downto 1);
          v.min     := v.min (0) & r.min (r.min'left downto 1);
          v.ready   := '1';
          v.state   := IDLE_S;
        when others => NULL;
      end case;

      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      rin         <= v;

      axisMaster  <= r.axisMaster;
   end process comb;

   ready       <= rin.ready;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
