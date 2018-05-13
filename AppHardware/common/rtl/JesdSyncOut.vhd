-------------------------------------------------------------------------------
-- File       : JesdSyncOut.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-04
-- Last update: 2018-05-12
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity JesdSyncOut is
   generic (
      TPD_G    : time    := 1 ns;
      INVERT_G : boolean := false);
   port (
      -- Clock
      jesdClk   : in  sl;
      -- JESD Low speed Interface
      jesdSync  : in  sl;
      -- JESD Low speed Ports
      jesdSyncP : out sl;
      jesdSyncN : out sl);
end JesdSyncOut;

architecture mapping of JesdSyncOut is

   signal syncIn  : sl;
   signal sync    : sl;
   signal regSync : sl;

begin

   -- Help with meeting timing
   U_sync : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => jesdClk,
         rstIn  => jesdSync,
         rstOut => syncIn);

   sync <= syncIn when(INVERT_G = false) else not(syncIn);

   U_rxSyncReg : ODDRE1
      port map (
         C  => jesdClk,
         SR => '0',
         D1 => sync,
         D2 => sync,
         Q  => regSync);

   U_jesdRxSync : OBUFDS
      port map (
         I  => regSync,
         O  => jesdSyncP,
         OB => jesdSyncN);

end mapping;
