-------------------------------------------------------------------------------
-- File       : DaqDecimatorTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-15
-- Last update: 2017-06-27
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for DaqDecimator
------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Common Carrier Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

entity DaqDecimatorTb is
end entity;

architecture tb of DaqDecimatorTb is

   constant CLK_PERIOD_C : time     := 4 ns;
   constant TPD_C        : time     := 1 ns;
   constant INCR_C       : positive := 4;

   constant dec16or32_c : sl               := '1';  -- '0' = 32b format, '1' = 16b format
   constant averaging_c : sl               := '1';  -- '0' = no averaging, '1' = averaging
   constant rateDiv_c   : slv(15 downto 0) := x"0004";  -- rate divide by 

   signal clk_i         : sl               := '0';
   signal rst_i         : sl               := '0';
   signal trig_i        : sl               := '0';
   signal rateClk_o     : sl               := '0';
   signal sampleData_i  : slv(31 downto 0) := x"0000_0000";
   signal decSampData_o : slv(31 downto 0) := (others => '0');
   signal s_cnt         : slv(31 downto 0) := (others => '0');

begin

   -----------------------------
   -- Generate clocks and resets
   -----------------------------
   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 1 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk_i,
         clkN => open,
         rst  => rst_i,
         rstL => open);

   ----------------------
   -- DaqDecimator Module
   ----------------------
   U_DaqDecimator : entity work.DaqDecimator
      generic map (
         TPD_G => TPD_C)
      port map (
         clk           => clk_i,
         rst           => rst_i,
         sampleData_i  => sampleData_i,
         decSampData_o => decSampData_o,
         dec16or32_i   => dec16or32_c,
         averaging_i   => averaging_c,
         signed_i      => '0',          -- '0' = unsigned, '1' = signed
         rateDiv_i     => rateDiv_c,
         trig_i        => trig_i,
         rateClk_o     => rateClk_o);

   seq : process (clk_i) is
   begin
      if (rising_edge(clk_i)) then
         if (rst_i = '1') then
            s_cnt <= (others => '0');
         elsif dec16or32_c = '0' then
            s_cnt <= s_cnt + INCR_C after TPD_C;
         else
            s_cnt <= s_cnt + 2*INCR_C after TPD_C;
         end if;
      end if;
   end process seq;

   sampleData_i <= s_cnt(15 downto 0)+INCR_C & s_cnt(15 downto 0) when (dec16or32_c = '1') else s_cnt;

   StimuliProcess : process
   begin
      wait until rst_i = '0';

      wait for CLK_PERIOD_C*800;
      trig_i <= '1';
      wait for CLK_PERIOD_C*1;
      trig_i <= '0';

      wait;
   end process StimuliProcess;

end tb;
