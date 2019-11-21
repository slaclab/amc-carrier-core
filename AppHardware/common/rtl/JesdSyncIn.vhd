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

library unisim;
use unisim.vcomponents.all;

entity JesdSyncIn is
   generic (
      TPD_G       : time    := 1 ns;
      GEN_ASYNC_G : boolean := true;  -- default true means to add synchronizer
      INVERT_G    : boolean := false);
   port (
      -- Edge Select
      edgeSelet : in  sl := '0';  -- '0': jesdClk's rising edge sampled, '1': jesdClk's falling edge sampled
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

   attribute dont_touch             : string;
   attribute dont_touch of ibufSync : signal is "TRUE";
   attribute dont_touch of regSync  : signal is "TRUE";

begin

   jesdClkL <= not(jesdClk);

   U_IBUFDS : IBUFDS
      port map (
         I  => jesdSyncP,
         IB => jesdSyncN,
         O  => ibufSync);

   GEN_ASYNC : if (GEN_ASYNC_G = true) generate

      U_Synchronizer : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => jesdClk,
            dataIn  => ibufSync,
            dataOut => regSync);

   end generate;

   GEN_SYNC : if (GEN_ASYNC_G = false) generate

      U_IDDRE1 : IDDRE1
         generic map (
            DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
         port map (
            C  => jesdClk,
            CB => jesdClkL,
            D  => ibufSync,
            R  => '0',
            Q1 => regSyncVec(0),        -- Rising edge sample
            Q2 => regSyncVec(1));       -- Falling edge sample

      -- Select whether sampling the rising or falling edge sample
      regSync <= regSyncVec(0) when(edgeSelet = '0') else regSyncVec(1);

   end generate;

   -- Select whether the output is inverted for not
   jesdSync <= regSync when(INVERT_G = false) else not(regSync);

end mapping;
