-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;

library amc_carrier_core;
use amc_carrier_core.FpgaTypePkg.all;

library unisim;
use unisim.vcomponents.all;

entity JesdSyncOut is
   generic (
      TPD_G       : time    := 1 ns;
      GEN_ASYNC_G : boolean := false;   -- default false don't add synchronizer
      INVERT_G    : boolean := false);
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

   GEN_ASYNC : if (GEN_ASYNC_G = true) generate

      U_Synchronizer : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => jesdClk,
            dataIn  => jesdSync,
            dataOut => syncIn);

   end generate;

   GEN_SYNC : if (GEN_ASYNC_G = false) generate

      process(jesdClk)
      begin
         if rising_edge(jesdClk) then
            syncIn <= jesdSync after TPD_G;
         end if;
      end process;

   end generate;

   sync <= syncIn when(INVERT_G = false) else not(syncIn);

   U_rxSyncReg : ODDRE1
      generic map (
         SIM_DEVICE => ite(ULTRASCALE_PLUS_C, "ULTRASCALE_PLUS", "ULTRASCALE"))
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
