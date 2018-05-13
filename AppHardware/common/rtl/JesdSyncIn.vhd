-------------------------------------------------------------------------------
-- File       : JesdSyncIn.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-05-04
-- Last update: 2018-05-11
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

entity JesdSyncIn is
   generic (
      TPD_G    : time    := 1 ns;
      INVERT_G : boolean := false);
   port (
      -- Clock
      jesdClk   : in  sl;
      -- JESD Low speed Ports
      jesdSyncP : in  sl;
      jesdSyncN : in  sl;
      -- JESD Low speed Interface
      jesdSync  : out sl);
end JesdSyncIn;

architecture mapping of JesdSyncIn is

   signal jesdClkL : sl;
   signal ibufSync : sl;
   signal regSync  : sl;
   signal syncOut  : sl;

begin

   jesdClkL <= not(jesdClk);

   U_IBUFDS : IBUFDS
      port map (
         I  => jesdSyncP,
         IB => jesdSyncN,
         O  => ibufSync);

   U_IDDRE1 : IDDRE1
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
      port map (
         C  => jesdClk,
         CB => jesdClkL,
         D  => ibufSync,
         R  => '0',
         Q1 => regSync,
         Q2 => open);

   syncOut <= regSync when(INVERT_G = false) else not(regSync);

   -- Help with meeting timing
   U_sync : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => jesdClk,
         rstIn  => syncOut,
         rstOut => jesdSync);

end mapping;
