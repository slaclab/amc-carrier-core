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

--------------------------------------------------------------------------------
entity  DaqDecimatorTb is

end entity ;
--------------------------------------------------------------------------------


architecture Bhv of DaqDecimatorTb is
  -----------------------------
  -- Port Signals 
  -----------------------------
   constant CLK_PERIOD_C : time    := 10 ns;
   constant TPD_C        : time    := 1 ns; 

   -- Clocking
   signal   clk_i                 : sl := '0';
   signal   rst_i                 : sl := '0';
   
   signal   sampleData_i    : slv(31 downto 0) := x"0000_0000";
   signal   dec16or32_i     : sl :='0';
   signal   rateDiv_i       : slv(15 downto 0) := x"0002";
   signal   trig_i          : sl :='0';
   signal   averaging_i     : sl :='1';  
   ----------------------------------------------

   signal   rateClk_o       : sl;
   signal   decSampData_o   : slv(31 downto 0);
   
   signal   s_cnt   : slv(31 downto 0);
begin  

   -- Generate clocks and resets
   DDR_ClkRst_Inst : entity work.ClkRst
   generic map (
     CLK_PERIOD_G      => CLK_PERIOD_C,
     RST_START_DELAY_G => 1 ns,     -- Wait this long into simulation before asserting reset
     RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
   port map (
     clkP => clk_i,
     clkN => open,
     rst  => rst_i,
     rstL => open);

  -----------------------------
  -- component instantiation 
  -----------------------------
  AmcA_INST: entity work.DaqDecimator
   generic map (
      TPD_G => TPD_C)
   port map (
      clk             => clk_i,
      rst             => rst_i,
      sampleData_i    => sampleData_i,
      decSampData_o   => decSampData_o,
      dec16or32_i     => dec16or32_i,
      rateDiv_i       => rateDiv_i,
      trig_i          => trig_i,
      averaging_i     => averaging_i,
      rateClk_o       => rateClk_o);

	
   seq : process (clk_i) is
   begin
      if (rising_edge(clk_i)) then
         if (rst_i = '1') then  
            s_cnt <= (others=>'0');
         elsif dec16or32_i = '0' then
            s_cnt <= s_cnt + 1 after TPD_C;
         else
            s_cnt <= s_cnt + 2 after TPD_C;
         end if;
      end if;
   end process seq;
   
   
   sampleData_i <= s_cnt(15 downto 0)+1 & s_cnt(15 downto 0) when dec16or32_i = '1' else s_cnt;
   
   
   StimuliProcess : process
   begin
      wait until rst_i = '0';

      wait for CLK_PERIOD_C*200;
      trig_i <= '1';    
      wait for CLK_PERIOD_C*1;
      trig_i <= '0';
      
      wait;
   end process StimuliProcess;
  
end architecture Bhv;