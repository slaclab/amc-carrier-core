-------------------------------------------------------------------------------
-- File       : FpgaTypePkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2018-07-21
-------------------------------------------------------------------------------
-- Description: 
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

use work.StdRtlPkg.all;

package FpgaTypePkg is

   -- constant CPSW_TARBALL_ADDR_C : slv(31 downto 0) := x"0622ED24";
   constant CPSW_TARBALL_ADDR_C : slv(31 downto 0) := x"0622ED28";  -- Include ones.bin 4 byte offset

end package FpgaTypePkg;
