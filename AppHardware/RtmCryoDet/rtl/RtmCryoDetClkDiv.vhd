-------------------------------------------------------------------------------
-- File       : RtmCryoDetClkDiv.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_13_CXX
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;

entity RtmCryoDetClkDiv is
   generic (
      TPD_G       : time     := 1 ns;
      CNT_WIDTH_G : positive := 8);
   port (
      jesdClk       : in  sl;
      jesdRst       : in  sl;
      jesdClkDiv    : out sl;
      rtmClockDelay : in  slv(2 downto 0);
      lowCycle      : in  slv(CNT_WIDTH_G-1 downto 0);
      highCycle     : in  slv(CNT_WIDTH_G-1 downto 0));
end RtmCryoDetClkDiv;

architecture rtl of RtmCryoDetClkDiv is

   type RegType is record
      clkDiv : sl;
      cnt    : slv(CNT_WIDTH_G-1 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
      clkDiv => '0',
      cnt    => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clkDiv : sl;

begin


   U_CLOCK_DELAY : entity surf.SlvDelay
   generic map (
      TPD_G   => TPD_G,
      DELAY_G => 8,
      WIDTH_G => 1)
   port map (
      clk     => jesdClk,
      delay   => rtmClockDelay, 
      din(0)  => clkDiv,
      dout(0) => jesdClkDiv);

   comb : process (highCycle, jesdRst, lowCycle, r) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Increment the counter
      v.cnt := r.cnt + 1;

      -- Check the divide clock phase
      if (r.clkDiv = '1') then
         -- Check the counter
         if (r.cnt = highCycle) then
            -- Reset the counter
            v.cnt    := (others => '0');
            -- Toggle the flag
            v.clkDiv := '0';
         end if;
      else
         -- Check the counter
         if (r.cnt = lowCycle) then
            -- Reset the counter
            v.cnt    := (others => '0');
            -- Toggle the flag
            v.clkDiv := '1';
         end if;
      end if;

      -- Synchronous Reset
      if (jesdRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      clkDiv <= r.clkDiv;

   end process comb;

   seq : process (jesdClk) is
   begin
      if (rising_edge(jesdClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
