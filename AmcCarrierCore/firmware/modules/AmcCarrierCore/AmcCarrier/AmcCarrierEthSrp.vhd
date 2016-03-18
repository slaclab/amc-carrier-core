-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthSrp.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2016-03-16
-- Platform   : 
-- Standard   : VHDL'93/02
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.UdpEnginePkg.all;
use work.IpV4EnginePkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierEthSrp is
   generic (
      TPD_G            : time             := 1 ns);   
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;   
      -- Interface to RSSI Server engine
      obSrpMasters   : out AxiStreamMasterArray(2 downto 0);
      obSrpSlaves    : in  AxiStreamSlaveArray(2 downto 0);
      ibSrpMasters   : in  AxiStreamMasterArray(2 downto 0);
      ibSrpSlaves    : out AxiStreamSlaveArray(2 downto 0);
      -- Master AXI-Lite Interface
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType);      
end AmcCarrierEthSrp;

architecture mapping of AmcCarrierEthSrp is

   signal obSrpMaster : AxiStreamMasterType;
   signal obSrpSlave  : AxiStreamSlaveType;
   signal ibSrpMaster : AxiStreamMasterType;
   signal ibSrpSlave  : AxiStreamSlaveType;
   
begin

   U_AxiStreamMux : entity work.AxiStreamMux
      generic map (
         TPD_G        => TPD_G,
         NUM_SLAVES_G => 3)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMasters => ibSrpMasters,
         sAxisSlaves  => ibSrpSlaves,
         -- Master
         mAxisMaster  => ibSrpMaster,
         mAxisSlave   => ibSrpSlave); 

   U_SsiAxiLiteMaster : entity work.SsiAxiLiteMaster
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         EN_32BIT_ADDR_G     => true,
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => IP_ENGINE_CONFIG_C)   
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk            => axilClk,
         sAxisRst            => axilRst,
         sAxisMaster         => ibSrpMaster,
         sAxisSlave          => ibSrpSlave,
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk            => axilClk,
         mAxisRst            => axilRst,
         mAxisMaster         => obSrpMaster,
         mAxisSlave          => obSrpSlave,
         -- AXI Lite Bus (axiLiteClk domain)
         axiLiteClk          => axilClk,
         axiLiteRst          => axilRst,
         mAxiLiteReadMaster  => mAxilReadMaster,
         mAxiLiteReadSlave   => mAxilReadSlave,
         mAxiLiteWriteMaster => mAxilWriteMaster,
         mAxiLiteWriteSlave  => mAxilWriteSlave);  

   U_AxiStreamDeMux : entity work.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 3)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMaster  => obSrpMaster,
         sAxisSlave   => obSrpSlave,
         -- Master
         mAxisMasters => obSrpMasters,
         mAxisSlaves  => obSrpSlaves);     
   
end mapping;
