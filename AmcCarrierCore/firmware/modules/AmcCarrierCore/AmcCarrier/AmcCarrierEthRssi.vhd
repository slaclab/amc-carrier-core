-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthRssi.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-23
-- Last update: 2016-04-18
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

entity AmcCarrierEthRssi is
   generic (
      TPD_G            : time            := 1 ns;
      TIMEOUT_G        : real            := 1.0E-3;  -- In units of seconds   
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);   
   port (
      -- Slave AXI-Lite Interface
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType;
      -- Master AXI-Lite Interface
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;
      -- BSA Ethernet Interface
      obBsaMasters     : in  AxiStreamMasterArray(2 downto 0);
      obBsaSlaves      : out AxiStreamSlaveArray(2 downto 0);
      ibBsaMasters     : out AxiStreamMasterArray(2 downto 0);
      ibBsaSlaves      : in  AxiStreamSlaveArray(2 downto 0);
      -- Interface to UDP Server engines
      obServerMaster   : in  AxiStreamMasterType;
      obServerSlave    : out AxiStreamSlaveType;
      ibServerMaster   : out AxiStreamMasterType;
      ibServerSlave    : in  AxiStreamSlaveType);   
end AmcCarrierEthRssi;

architecture mapping of AmcCarrierEthRssi is

   signal rssiIbMaster : AxiStreamMasterType;
   signal rssiIbSlave  : AxiStreamSlaveType;
   signal rssiObMaster : AxiStreamMasterType;
   signal rssiObSlave  : AxiStreamSlaveType;

   signal rssiIbMasters : AxiStreamMasterArray(4 downto 0);
   signal rssiIbSlaves  : AxiStreamSlaveArray(4 downto 0);
   signal rssiObMasters : AxiStreamMasterArray(4 downto 0);
   signal rssiObSlaves  : AxiStreamSlaveArray(4 downto 0);

begin

   -----------------------------------
   -- Software's RSSI Server Interface
   -----------------------------------
   U_RssiServer : entity work.RssiCoreWrapper
      generic map (
         TPD_G                   => TPD_G,
         CLK_FREQUENCY_G         => AXI_CLK_FREQ_C,
         TIMEOUT_UNIT_G          => TIMEOUT_G,
         SERVER_G                => true,
         RETRANSMIT_ENABLE_G     => true,
         WINDOW_ADDR_SIZE_G      => 3,
         PIPE_STAGES_G           => 1,
         APP_INPUT_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
         APP_OUTPUT_AXI_CONFIG_G => IP_ENGINE_CONFIG_C,
         TSP_INPUT_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
         TSP_OUTPUT_AXI_CONFIG_G => IP_ENGINE_CONFIG_C,
         INIT_SEQ_N_G            => 16#80#)
      port map (
         clk_i            => axilClk,
         rst_i            => axilRst,
         -- Application Layer Interface
         sAppAxisMaster_i => rssiIbMaster,
         sAppAxisSlave_o  => rssiIbSlave,
         mAppAxisMaster_o => rssiObMaster,
         mAppAxisSlave_i  => rssiObSlave,
         -- Transport Layer Interface
         sTspAxisMaster_i => obServerMaster,
         sTspAxisSlave_o  => obServerSlave,
         mTspAxisMaster_o => ibServerMaster,
         mTspAxisSlave_i  => ibServerSlave,
         -- High level  Application side interface
         openRq_i         => '1',  -- Automatically start the connection without debug SRP channel
         closeRq_i        => '0',
         inject_i         => '0',
         -- AXI-Lite Interface
         axiClk_i         => axilClk,
         axiRst_i         => axilRst,
         axilReadMaster   => axilReadMaster,
         axilReadSlave    => axilReadSlave,
         axilWriteMaster  => axilWriteMaster,
         axilWriteSlave   => axilWriteSlave);          

   U_AxiStreamMux : entity work.AxiStreamMux
      generic map (
         TPD_G        => TPD_G,
         NUM_SLAVES_G => 5)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMasters => rssiIbMasters,
         sAxisSlaves  => rssiIbSlaves,
         -- Master
         mAxisMaster  => rssiIbMaster,
         mAxisSlave   => rssiIbSlave); 

   U_AxiStreamDeMux : entity work.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 5)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMaster  => rssiObMaster,
         sAxisSlave   => rssiObSlave,
         -- Master
         mAxisMasters => rssiObMasters,
         mAxisSlaves  => rssiObSlaves);             

   -----------------------------------
   -- AXI-Lite Master with RSSI Server
   ----------------------------------- 
   U_SRPv3 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => IP_ENGINE_CONFIG_C)
      port map (
         -- AXIS Slave Interface (sAxisClk domain)
         sAxisClk         => axilClk,
         sAxisRst         => axilRst,
         sAxisMaster      => rssiObMasters(0),
         sAxisSlave       => rssiObSlaves(0),
         -- AXIS Master Interface (mAxisClk domain) 
         mAxisClk         => axilClk,
         mAxisRst         => axilRst,
         mAxisMaster      => rssiIbMasters(0),
         mAxisSlave       => rssiIbSlaves(0),
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave);        

   -----------------------------------
   -- AXI-Lite Master with RSSI Server
   -----------------------------------           
   ibBsaMasters(2 downto 0)  <= rssiObMasters(3 downto 1);
   rssiObSlaves(3 downto 1)  <= ibBsaSlaves(2 downto 0);
   rssiIbMasters(3 downto 1) <= obBsaMasters(2 downto 0);
   obBsaSlaves(2 downto 0)   <= rssiIbSlaves(3 downto 1);

   -------------------
   -- Loopback Channel
   -------------------
   rssiIbMasters(4) <= rssiObMasters(4);
   rssiObSlaves(4)  <= rssiIbSlaves(4);
   
end mapping;
