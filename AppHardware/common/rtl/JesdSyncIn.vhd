-------------------------------------------------------------------------------
-- File       : JesdSyncIn.vhd
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

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity JesdSyncIn is
   generic (
      TPD_G      : time    := 1 ns;
      GEN_SYNC_G : boolean := true;  -- default true means to add synchronizer
      INVERT_G   : boolean := false);
   port (
      -- Edge Select
      edgeSelet : in  sl;  -- '0': jesdClk's rising edge sampled, '1': jesdClk's falling edge sampled
      -- Clock
      jesdClk   : in  sl;
      -- JESD Low speed Ports
      jesdSyncP : in  sl;
      jesdSyncN : in  sl;
      -- JESD Low speed Interface
      jesdSync  : out sl);
end JesdSyncIn;

architecture mapping of JesdSyncIn is

   signal jesdClkL   : sl;
   signal ibufSync   : sl;
   signal regSyncVec : slv(1 downto 0);
   signal regSync    : sl;
   signal syncOut    : sl;

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
         Q1 => regSyncVec(0),
         Q2 => regSyncVec(1));

   regSync <= regSyncVec(0) when(edgeSelet = '0') else regSyncVec(1);

   syncOut <= regSync when(INVERT_G = false) else not(regSync);

   GEN_ASYNC : if (GEN_SYNC_G = true) generate
      U_sync : entity work.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => jesdClk,
            rstIn  => syncOut,
            rstOut => jesdSync);
   end generate;

   GEN_SYNC : if (GEN_SYNC_G = false) generate
      process(jesdClk)
      begin
         if rising_edge(jesdClk) then
            jesdSync <= syncOut after TPD_G;
         end if;
      end process;
   end generate;

end mapping;
