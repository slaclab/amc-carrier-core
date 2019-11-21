-------------------------------------------------------------------------------
-- File       : RtmDigitalDebugDin.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_10_CXX
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


library surf;
use surf.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmDigitalDebugDin is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Digital Input Interface
      xDin : in  slv(7 downto 0);
      din  : out slv(7 downto 0));
end RtmDigitalDebugDin;

architecture mapping of RtmDigitalDebugDin is

begin

   GEN_VEC :
   for i in 7 downto 0 generate

      U_DIN : IBUF
         port map (
            I => xDin(i),
            O => din(i));

   end generate GEN_VEC;

end mapping;
