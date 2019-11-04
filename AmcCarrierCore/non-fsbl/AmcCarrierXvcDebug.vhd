-------------------------------------------------------------------------------
-- File       : AmcCarrierXvcDebug.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-02-09
-- Last update: 2018-02-09
-------------------------------------------------------------------------------
-- Description: Wrapper for UDP 'XVC' Server
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
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.EthMacPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;

entity AmcCarrierXvcDebug is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      axilClk        : in  sl;
      axilRst        : in  sl;
      -- UDP XVC Interface
      obServerMaster : in  AxiStreamMasterType;
      obServerSlave  : out AxiStreamSlaveType;
      ibServerMaster : out AxiStreamMasterType;
      ibServerSlave  : in  AxiStreamSlaveType);
end AmcCarrierXvcDebug;

architecture rtl of AmcCarrierXvcDebug is

   component UdpDebugBridge is
      port (
         axisClk : in sl;
         axisRst : in sl;

         \mAxisReq[tValid]\ : in  sl;
         \mAxisReq[tData]\  : in  slv (127 downto 0);
         \mAxisReq[tStrb]\  : in  slv (15 downto 0);
         \mAxisReq[tKeep]\  : in  slv (15 downto 0);
         \mAxisReq[tLast]\  : in  sl;
         \mAxisReq[tDest]\  : in  slv (7 downto 0);
         \mAxisReq[tId]\    : in  slv (7 downto 0);
         \mAxisReq[tUser]\  : in  slv (127 downto 0);
         \sAxisReq[tReady]\ : out sl;
         \mAxisTdo[tValid]\ : out sl;
         \mAxisTdo[tData]\  : out slv (127 downto 0);
         \mAxisTdo[tStrb]\  : out slv (15 downto 0);
         \mAxisTdo[tKeep]\  : out slv (15 downto 0);
         \mAxisTdo[tLast]\  : out sl;
         \mAxisTdo[tDest]\  : out slv (7 downto 0);
         \mAxisTdo[tId]\    : out slv (7 downto 0);
         \mAxisTdo[tUser]\  : out slv (127 downto 0);
         \sAxisTdo[tReady]\ : in  sl
         );
   end component UdpDebugBridge;

   type SofRegType is record
      sof : sl;
   end record SofRegType;

   constant SOF_REG_INIT_C : SofRegType := (sof => '1');

   signal rSof   : SofRegType := SOF_REG_INIT_C;
   signal rinSof : SofRegType;

   signal mXvcServerTdo : AxiStreamMasterType;

begin

   ----------------------------
   -- 'XVC' Server @2542 (modified protocol to work over UDP)
   ----------------------------
   P_SOF_COMB : process(ibServerSlave, mXvcServerTdo, rSof) is
      variable v : SofRegType;
   begin
      v := rSof;
      if ((mXvcServerTdo.tValid and ibServerSlave.tReady) = '1') then
         v.sof := mXvcServerTdo.tLast;
      end if;
      rinSof <= v;
   end process P_SOF_COMB;

   P_SOF_SEQ : process(axilClk) is
   begin
      if (rising_edge(axilClk)) then
         if (axilRst = '1') then
            rSof <= SOF_REG_INIT_C after TPD_G;
         else
            rSof <= rinSof after TPD_G;
         end if;
      end if;
   end process P_SOF_SEQ;

   -- splice in the SOF bit
   P_SOF_SPLICE : process(mXvcServerTdo, rSof) is
      variable v : AxiStreamMasterType;
   begin
      v              := mXvcServerTdo;
      ssiSetUserSof(EMAC_AXIS_CONFIG_C, v, rSof.sof);
      ibServerMaster <= v;
   end process P_SOF_SPLICE;

   U_XvcServer : component UdpDebugBridge
      port map (
         axisClk => axilClk,
         axisRst => axilRst,

         \mAxisReq[tValid]\ => obServerMaster.tValid,
         \mAxisReq[tData]\  => obServerMaster.tData(127 downto 0),
         \mAxisReq[tStrb]\  => obServerMaster.tStrb(15 downto 0),
         \mAxisReq[tKeep]\  => obServerMaster.tKeep(15 downto 0),
         \mAxisReq[tLast]\  => obServerMaster.tLast,
         \mAxisReq[tDest]\  => obServerMaster.tDest,
         \mAxisReq[tId]\    => obServerMaster.tId,
         \mAxisReq[tUser]\  => obServerMaster.tUser(127 downto 0),
         \sAxisReq[tReady]\ => obServerSlave.tReady,
         \mAxisTdo[tValid]\ => mXvcServerTdo.tValid,
         \mAxisTdo[tData]\  => mXvcServerTdo.tData(127 downto 0),
         \mAxisTdo[tStrb]\  => mXvcServerTdo.tStrb(15 downto 0),
         \mAxisTdo[tKeep]\  => mXvcServerTdo.tKeep(15 downto 0),
         \mAxisTdo[tLast]\  => mXvcServerTdo.tLast,
         \mAxisTdo[tDest]\  => mXvcServerTdo.tDest,
         \mAxisTdo[tId]\    => mXvcServerTdo.tId,
         \mAxisTdo[tUser]\  => mXvcServerTdo.tUser(127 downto 0),
         \sAxisTdo[tReady]\ => ibServerSlave.tReady);

end rtl;
