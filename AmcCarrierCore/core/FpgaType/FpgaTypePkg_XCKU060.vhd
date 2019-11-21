-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Example .MCS: The GZ header (0x1F8B) starts at offset: 05700000 + 1DEC + 6 = 0x5701DF2
-- :02   000004   0570   85
-- :10   1DEC00   27 C3 BF C3 BF 27 1F 8B 08 00 6A DF C1 5D 00 03    79
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

package FpgaTypePkg is

   constant CPSW_TARBALL_ADDR_C : slv(31 downto 0) := x"05701DF2";

   constant ULTRASCALE_PLUS_C : boolean := false;

end package FpgaTypePkg;
