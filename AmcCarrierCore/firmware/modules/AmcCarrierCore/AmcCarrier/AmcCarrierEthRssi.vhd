-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthRssi.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-23
-- Last update: 2016-05-06
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.UdpEnginePkg.all;
use work.IpV4EnginePkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierEthRssi is
   generic (
      TPD_G            : time             := 1 ns;
      TIMEOUT_G        : real             := 1.0E-3;  -- In units of seconds   
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
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
      -- Application Debug Interface
      obDebugMaster    : in  AxiStreamMasterType;
      obDebugSlave     : out AxiStreamSlaveType;
      ibDebugMaster    : out AxiStreamMasterType;
      ibDebugSlave     : in  AxiStreamSlaveType;
      -- BSA Ethernet Interface
      obBsaMasters     : in  AxiStreamMasterArray(3 downto 0);
      obBsaSlaves      : out AxiStreamSlaveArray(3 downto 0);
      ibBsaMasters     : out AxiStreamMasterArray(3 downto 0);
      ibBsaSlaves      : in  AxiStreamSlaveArray(3 downto 0);
      -- Interface to UDP Server engines
      obServerMasters  : in  AxiStreamMasterArray(1 downto 0);
      obServerSlaves   : out AxiStreamSlaveArray(1 downto 0);
      ibServerMasters  : out AxiStreamMasterArray(1 downto 0);
      ibServerSlaves   : in  AxiStreamSlaveArray(1 downto 0));
end AmcCarrierEthRssi;

architecture mapping of AmcCarrierEthRssi is

   signal rssiIbMasters : AxiStreamMasterArray(3 downto 0);
   signal rssiIbSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal rssiObMasters : AxiStreamMasterArray(3 downto 0);
   signal rssiObSlaves  : AxiStreamSlaveArray(3 downto 0);

   constant NUM_AXI_MASTERS_C : natural := 2;
   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      0               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00030000"),
         addrBits     => 12,
         connectivity => X"FFFF"),
      1               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00038000"),
         addrBits     => 12,
         connectivity => X"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);

   signal tempIbMasters : AxiStreamMasterArray(2 downto 0);
   signal tempIbSlaves  : AxiStreamSlaveArray(2 downto 0);
   signal tempObMasters : AxiStreamMasterArray(2 downto 0);
   signal tempObSlaves  : AxiStreamSlaveArray(2 downto 0);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ------------------------------
   -- Software's RSSI Server@8193
   ------------------------------
   U_RssiServer : entity work.RssiCoreWrapper
      generic map (
         TPD_G                    => TPD_G,
         APP_STREAMS_G            => 4,
         APP_STREAM_ROUTES_G      => (
            0                     => X"00",   -- TDEST 0 routed to stream 0 (SRPv0)
            1                     => X"01",   -- TDEST 1 routed to stream 1 (loopback)
            2                     => X"02",   -- TDEST 2 routed to stream 2 (BSA async)
            3                     => X"03"),  -- TDEST 3 routed to stream 3 (Diag async)
         CLK_FREQUENCY_G          => AXI_CLK_FREQ_C,
         TIMEOUT_UNIT_G           => TIMEOUT_G,
         SERVER_G                 => true,
         RETRANSMIT_ENABLE_G      => true,
         WINDOW_ADDR_SIZE_G       => 3,
         PIPE_STAGES_G            => 1,
         APP_INPUT_AXIS_CONFIG_G  => ETH_AXIS_CONFIG_C,
         APP_OUTPUT_AXIS_CONFIG_G => ETH_AXIS_CONFIG_C,
         TSP_INPUT_AXIS_CONFIG_G  => ETH_AXIS_CONFIG_C,
         TSP_OUTPUT_AXIS_CONFIG_G => ETH_AXIS_CONFIG_C,
         INIT_SEQ_N_G             => 16#80#)
      port map (
         clk_i             => axilClk,
         rst_i             => axilRst,
         -- Application Layer Interface
         sAppAxisMasters_i => rssiIbMasters,
         sAppAxisSlaves_o  => rssiIbSlaves,
         mAppAxisMasters_o => rssiObMasters,
         mAppAxisSlaves_i  => rssiObSlaves,
         -- Transport Layer Interface
         sTspAxisMaster_i  => obServerMasters(0),
         sTspAxisSlave_o   => obServerSlaves(0),
         mTspAxisMaster_o  => ibServerMasters(0),
         mTspAxisSlave_i   => ibServerSlaves(0),
         -- High level  Application side interface
         openRq_i          => '1',  -- Automatically start the connection without debug SRP channel
         closeRq_i         => '0',
         inject_i          => '0',
         -- AXI-Lite Interface
         axiClk_i          => axilClk,
         axiRst_i          => axilRst,
         axilReadMaster    => axilReadMasters(0),
         axilReadSlave     => axilReadSlaves(0),
         axilWriteMaster   => axilWriteMasters(0),
         axilWriteSlave    => axilWriteSlaves(0));

   ------------------------------------------------
   -- AXI-Lite Master with RSSI Server: TDEST = 0x0
   ------------------------------------------------
   U_SRPv3 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => ETH_AXIS_CONFIG_C)
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

   --------------------------------
   -- Loopback Channel: TDEST = 0x1
   --------------------------------
   rssiIbMasters(1) <= rssiObMasters(1);
   rssiObSlaves(1)  <= rssiIbSlaves(1);

   ----------------------------------
   -- BSA ASYNC Messages: TDEST = 0x2
   ----------------------------------
   ibBsaMasters(1)  <= rssiObMasters(2);
   rssiObSlaves(2)  <= ibBsaSlaves(1);
   rssiIbMasters(2) <= obBsaMasters(1);
   obBsaSlaves(1)   <= rssiIbSlaves(2);

   -----------------------------------------
   -- Diagnostic ASYNC Messages: TDEST = 0x3
   -----------------------------------------
   ibBsaMasters(2)  <= rssiObMasters(3);
   rssiObSlaves(3)  <= ibBsaSlaves(2);
   rssiIbMasters(3) <= obBsaMasters(2);
   obBsaSlaves(2)   <= rssiIbSlaves(3);

   ------------------------------
   -- Software's RSSI Server@8194
   ------------------------------
   U_Temp : entity work.RssiCoreWrapper
      generic map (
         TPD_G                    => TPD_G,
         APP_STREAMS_G            => 3,
         APP_STREAM_ROUTES_G      => (
            0                     => X"04",        -- TDEST 4 routed to stream 0 (MEM)
            1                     => "10------",   -- TDEST x80-0xBF routed to stream 1 (Raw Data)
            2                     => "11------"),  -- TDEST 0xC0-0xFF routed to stream 2 (Application)            
         CLK_FREQUENCY_G          => AXI_CLK_FREQ_C,
         TIMEOUT_UNIT_G           => TIMEOUT_G,
         SERVER_G                 => true,
         RETRANSMIT_ENABLE_G      => true,
         WINDOW_ADDR_SIZE_G       => 3,
         PIPE_STAGES_G            => 1,
         APP_INPUT_AXIS_CONFIG_G  => ETH_AXIS_CONFIG_C,
         APP_OUTPUT_AXIS_CONFIG_G => ETH_AXIS_CONFIG_C,
         TSP_INPUT_AXIS_CONFIG_G  => ETH_AXIS_CONFIG_C,
         TSP_OUTPUT_AXIS_CONFIG_G => ETH_AXIS_CONFIG_C,
         INIT_SEQ_N_G             => 16#80#)
      port map (
         clk_i             => axilClk,
         rst_i             => axilRst,
         -- Application Layer Interface
         sAppAxisMasters_i => tempIbMasters,
         sAppAxisSlaves_o  => tempIbSlaves,
         mAppAxisMasters_o => tempObMasters,
         mAppAxisSlaves_i  => tempObSlaves,
         -- Transport Layer Interface
         sTspAxisMaster_i  => obServerMasters(1),
         sTspAxisSlave_o   => obServerSlaves(1),
         mTspAxisMaster_o  => ibServerMasters(1),
         mTspAxisSlave_i   => ibServerSlaves(1),
         -- High level  Application side interface
         openRq_i          => '1',  -- Automatically start the connection without debug SRP channel
         closeRq_i         => '0',
         inject_i          => '0',
         -- AXI-Lite Interface
         axiClk_i          => axilClk,
         axiRst_i          => axilRst,
         axilReadMaster    => axilReadMasters(1),
         axilReadSlave     => axilReadSlaves(1),
         axilWriteMaster   => axilWriteMasters(1),
         axilWriteSlave    => axilWriteSlaves(1));

   -----------------------------
   -- Memory Access: TDEST = 0x4
   -----------------------------
   ibBsaMasters(0)  <= tempObMasters(0);
   tempObSlaves(0)  <= ibBsaSlaves(0);
   tempIbMasters(0) <= obBsaMasters(0);
   obBsaSlaves(0)   <= tempIbSlaves(0);

   -----------------------------------
   -- Raw Data Path: TDEST = 0xBF:0x80
   -----------------------------------
   ibBsaMasters(3)  <= tempObMasters(1);
   tempObSlaves(1)  <= ibBsaSlaves(3);
   tempIbMasters(1) <= obBsaMasters(3);
   obBsaSlaves(3)   <= tempIbSlaves(1);

   --------------------------------
   -- Debug Path: TDEST = 0xFF:0xC0
   --------------------------------
   ibDebugMaster    <= tempObMasters(2);
   tempObSlaves(2)  <= ibDebugSlave;
   tempIbMasters(2) <= obDebugMaster;
   obDebugSlave     <= tempIbSlaves(2);

end mapping;
