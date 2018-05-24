-------------------------------------------------------------------------------
-- File       : AmcCarrierEth.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2018-03-14
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
use work.EthMacPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierSysRegPkg.all;

entity AmcCarrierEth is
   generic (
      TPD_G                 : time     := 1 ns;
      RSSI_ILEAVE_EN_G      : boolean  := false;
      RTM_ETH_G             : boolean  := false;
      ETH_USR_FRAME_LIMIT_G : positive := 4096);    -- 4kB
   port (
      -- Local Configuration and status
      localMac             : in  slv(47 downto 0);  --  big-Endian configuration
      localIp              : in  slv(31 downto 0);  --  big-Endian configuration   
      ethPhyReady          : out sl;
      -- Master AXI-Lite Interface
      mAxilReadMasters     : out AxiLiteReadMasterArray(1 downto 0);
      mAxilReadSlaves      : in  AxiLiteReadSlaveArray(1 downto 0);
      mAxilWriteMasters    : out AxiLiteWriteMasterArray(1 downto 0);
      mAxilWriteSlaves     : in  AxiLiteWriteSlaveArray(1 downto 0);
      -- AXI-Lite Interface
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType;
      -- BSA Ethernet Interface
      obBsaMasters         : in  AxiStreamMasterArray(3 downto 0);
      obBsaSlaves          : out AxiStreamSlaveArray(3 downto 0);
      ibBsaMasters         : out AxiStreamMasterArray(3 downto 0);
      ibBsaSlaves          : in  AxiStreamSlaveArray(3 downto 0);
      -- Timing ETH MSG Interface
      obTimingEthMsgMaster : in  AxiStreamMasterType;
      obTimingEthMsgSlave  : out AxiStreamSlaveType;
      ibTimingEthMsgMaster : out AxiStreamMasterType;
      ibTimingEthMsgSlave  : in  AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Application Debug Interface
      obAppDebugMaster     : in  AxiStreamMasterType;
      obAppDebugSlave      : out AxiStreamSlaveType;
      ibAppDebugMaster     : out AxiStreamMasterType;
      ibAppDebugSlave      : in  AxiStreamSlaveType;
      -- Backplane Messaging Interface
      obBpMsgClientMaster  : in  AxiStreamMasterType;
      obBpMsgClientSlave   : out AxiStreamSlaveType;
      ibBpMsgClientMaster  : out AxiStreamMasterType;
      ibBpMsgClientSlave   : in  AxiStreamSlaveType;
      obBpMsgServerMaster  : in  AxiStreamMasterType;
      obBpMsgServerSlave   : out AxiStreamSlaveType;
      ibBpMsgServerMaster  : out AxiStreamMasterType;
      ibBpMsgServerSlave   : in  AxiStreamSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- ETH Ports
      ethRxP               : in  slv(3 downto 0);
      ethRxN               : in  slv(3 downto 0);
      ethTxP               : out slv(3 downto 0);
      ethTxN               : out slv(3 downto 0);
      ethClkP              : in  sl;
      ethClkN              : in  sl);
end AmcCarrierEth;

architecture mapping of AmcCarrierEth is

   ------------------------------------------
   --     AXI-Lite Configurations          --
   ------------------------------------------

   constant NUM_AXI_MASTERS_C : natural := 3;

   constant AXI_UDP_INDEX_C              : natural := 0;
   constant AXI_RSSI_NONE_ILEAVE_INDEX_C : natural := 1;
   constant AXI_RSSI_ILEAVE_INDEX_C      : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, ETH_ADDR_C, 20, 16);

   ------------------------------------------
   --     UDP Server Configurations        --
   ------------------------------------------   

   constant SERVER_SIZE_C : positive := 7;

   constant UDP_SRV_XVC_IDX_C         : natural := 0;
   constant UDP_SRV_SRPV0_IDX_C       : natural := 1;
   constant UDP_SRV_RSSI0_IDX_C       : natural := 2;
   constant UDP_SRV_RSSI1_IDX_C       : natural := 3;
   constant UDP_SRV_BP_MGS_IDX_C      : natural := 4;
   constant UDP_SRV_TIMING_IDX_C      : natural := 5;
   constant UDP_SRV_RSSI_ILEAVE_IDX_C : natural := 6;

   constant SERVER_PORTS_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (
      UDP_SRV_XVC_IDX_C         => 2542,  -- Xilinx XVC 
      UDP_SRV_SRPV0_IDX_C       => 8192,  -- Legacy SRPv0 register access (still used for remote FPGA reprogramming)
      UDP_SRV_RSSI0_IDX_C       => 8193,  -- Legacy Non-interleaved RSSI for Register access and ASYNC messages
      UDP_SRV_RSSI1_IDX_C       => 8194,  -- Legacy Non-interleaved RSSI for bulk data transfer
      UDP_SRV_BP_MGS_IDX_C      => 8195,  -- Backplane Messaging
      UDP_SRV_TIMING_IDX_C      => 8197,  -- Timing ASYNC Messaging
      UDP_SRV_RSSI_ILEAVE_IDX_C => 8198);  -- Interleaved RSSI 

   ------------------------------------------
   --     UDP Client Configurations        --
   ------------------------------------------  

   constant CLIENT_SIZE_C : positive := 1;

   constant UDP_CLT_BP_MGS_IDX_C : natural := 0;

   constant CLIENT_PORTS_C : PositiveArray(CLIENT_SIZE_C-1 downto 0) := (
      UDP_CLT_BP_MGS_IDX_C => 8196);    -- Backplane Messaging

   ------------------------------------------
   --                Signals               -- 
   ------------------------------------------ 

   signal ibMacMaster : AxiStreamMasterType;
   signal ibMacSlave  : AxiStreamSlaveType;
   signal obMacMaster : AxiStreamMasterType;
   signal obMacSlave  : AxiStreamSlaveType;

   signal obServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal obServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);
   signal ibServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal ibServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);

   signal obClientMasters : AxiStreamMasterArray(CLIENT_SIZE_C-1 downto 0);
   signal obClientSlaves  : AxiStreamSlaveArray(CLIENT_SIZE_C-1 downto 0);
   signal ibClientMasters : AxiStreamMasterArray(CLIENT_SIZE_C-1 downto 0);
   signal ibClientSlaves  : AxiStreamSlaveArray(CLIENT_SIZE_C-1 downto 0);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal phyReady : sl;

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
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

   -----------------------
   -- Zone2 10 GigE Module
   -----------------------
   ETH_ZONE2 : if (RTM_ETH_G = false) generate
      U_Xaui : entity work.XauiGthUltraScaleWrapper
         generic map (
            TPD_G         => TPD_G,
            EN_WDT_G      => true,
            -- AXI-Lite Configurations
            -- AXI Streaming Configurations
            AXIS_CONFIG_G => EMAC_AXIS_CONFIG_C)
         port map (
            -- Local Configurations
            localMac       => localMac,
            -- Streaming DMA Interface 
            dmaClk         => axilClk,
            dmaRst         => axilRst,
            dmaIbMaster    => obMacMaster,
            dmaIbSlave     => obMacSlave,
            dmaObMaster    => ibMacMaster,
            dmaObSlave     => ibMacSlave,
            -- Misc. Signals
            extRst         => axilRst,
            stableClk      => axilClk,
            phyReady       => phyReady,
            -- Transceiver Debug Interface
            gtTxPreCursor  => (others => '0'),  -- 0 dB
            gtTxPostCursor => (others => '0'),  -- 0 dB
            gtTxDiffCtrl   => (others => '1'),  -- 1.080 V
            gtRxPolarity   => x"0",
            gtTxPolarity   => x"0",
            -- MGT Clock Port (156.25 MHz)
            gtClkP         => ethClkP,
            gtClkN         => ethClkN,
            -- MGT Ports
            gtTxP          => ethTxP,
            gtTxN          => ethTxN,
            gtRxP          => ethRxP,
            gtRxN          => ethRxN);
   end generate;

   ----------------------
   -- Zone3 1 GigE Module
   ----------------------
   ETH_ZONE3 : if (RTM_ETH_G = true) generate
      U_Rtm : entity work.GigEthGthUltraScaleWrapper
         generic map (
            TPD_G              => TPD_G,
            -- DMA/MAC Configurations
            NUM_LANE_G         => 1,
            -- QUAD PLL Configurations
            USE_GTREFCLK_G     => false,
            CLKIN_PERIOD_G     => 6.4,   -- 156.25 MHz
            DIVCLK_DIVIDE_G    => 5,     -- 31.25 MHz = (156.25 MHz/5)
            CLKFBOUT_MULT_F_G  => 32.0,  -- 1 GHz = (32 x 31.25 MHz)
            CLKOUT0_DIVIDE_F_G => 8.0,   -- 125 MHz = (1.0 GHz/8)         
            -- AXI Streaming Configurations
            AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C))
         port map (
            -- Local Configurations
            localMac(0)     => localMac,
            -- Streaming DMA Interface 
            dmaClk(0)       => axilClk,
            dmaRst(0)       => axilRst,
            dmaIbMasters(0) => obMacMaster,
            dmaIbSlaves(0)  => obMacSlave,
            dmaObMasters(0) => ibMacMaster,
            dmaObSlaves(0)  => ibMacSlave,
            -- Misc. Signals
            extRst          => axilRst,
            phyReady(0)     => phyReady,
            -- MGT Clock Port
            gtClkP          => ethClkP,
            gtClkN          => ethClkN,
            -- MGT Ports
            gtTxP(0)        => ethTxP(0),
            gtTxN(0)        => ethTxN(0),
            gtRxP(0)        => ethRxP(0),
            gtRxN(0)        => ethRxN(0));
      -- Unused ports
      ethTxP(3 downto 1) <= "000";
      ethTxN(3 downto 1) <= "111";
   end generate;

   U_Sync : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => phyReady,
         dataOut => ethPhyReady);

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UdpEngineWrapper : entity work.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G          => TPD_G,
         -- UDP Server Generics
         SERVER_EN_G    => true,
         SERVER_SIZE_G  => SERVER_SIZE_C,
         SERVER_PORTS_G => SERVER_PORTS_C,
         -- UDP Client Generics
         CLIENT_EN_G    => true,
         CLIENT_SIZE_G  => CLIENT_SIZE_C,
         CLIENT_PORTS_G => CLIENT_PORTS_C,
         -- IPv4/ARP Generics
         CLK_FREQ_G     => AXI_CLK_FREQ_C,  -- In units of Hz
         COMM_TIMEOUT_G => 30,  -- In units of seconds, Client's Communication timeout before re-ARPing
         VLAN_G         => false,       -- no VLAN       
         DHCP_G         => false)       -- no DHCP       
      port map (
         -- Local Configurations
         localMac        => localMac,
         localIp         => localIp,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster     => obMacMaster,
         obMacSlave      => obMacSlave,
         ibMacMaster     => ibMacMaster,
         ibMacSlave      => ibMacSlave,
         -- Interface to UDP Server engine(s)
         obServerMasters => obServerMasters,
         obServerSlaves  => obServerSlaves,
         ibServerMasters => ibServerMasters,
         ibServerSlaves  => ibServerSlaves,
         -- Interface to UDP Client engine(s)
         obClientMasters => obClientMasters,
         obClientSlaves  => obClientSlaves,
         ibClientMasters => ibClientMasters,
         ibClientSlaves  => ibClientSlaves,
         -- AXI-Lite Interface
         axilReadMaster  => axilReadMasters(AXI_UDP_INDEX_C),
         axilReadSlave   => axilReadSlaves(AXI_UDP_INDEX_C),
         axilWriteMaster => axilWriteMasters(AXI_UDP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(AXI_UDP_INDEX_C),
         -- Clock and Reset
         clk             => axilClk,
         rst             => axilRst);

   -------------
   -- Xilinx XVC
   -------------
   U_Debug : entity work.AmcCarrierXvcDebug
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         axilClk        => axilClk,
         axilRst        => axilRst,
         -- UDP XVC Interface
         obServerMaster => obServerMasters(UDP_SRV_XVC_IDX_C),
         obServerSlave  => obServerSlaves(UDP_SRV_XVC_IDX_C),
         ibServerMaster => ibServerMasters(UDP_SRV_XVC_IDX_C),
         ibServerSlave  => ibServerSlaves(UDP_SRV_XVC_IDX_C));

   --------------------------------------
   -- Legacy AXI-Lite Master without RSSI
   --------------------------------------
   U_SRPv0 : entity work.SrpV0AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         EN_32BIT_ADDR_G     => true,
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk            => axilClk,
         sAxisRst            => axilRst,
         sAxisMaster         => obServerMasters(UDP_SRV_SRPV0_IDX_C),
         sAxisSlave          => obServerSlaves(UDP_SRV_SRPV0_IDX_C),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk            => axilClk,
         mAxisRst            => axilRst,
         mAxisMaster         => ibServerMasters(UDP_SRV_SRPV0_IDX_C),
         mAxisSlave          => ibServerSlaves(UDP_SRV_SRPV0_IDX_C),
         -- AXI Lite Bus (axiLiteClk domain)
         axiLiteClk          => axilClk,
         axiLiteRst          => axilRst,
         mAxiLiteReadMaster  => mAxilReadMasters(0),
         mAxiLiteReadSlave   => mAxilReadSlaves(0),
         mAxiLiteWriteMaster => mAxilWriteMasters(0),
         mAxiLiteWriteSlave  => mAxilWriteSlaves(0));

   -----------------------------------
   -- Software's RSSI Server Interface
   -----------------------------------
   NONE_ILEAVE : if (RSSI_ILEAVE_EN_G = false) generate

      U_RssiServer : entity work.AmcCarrierRssi
         generic map (
            TPD_G                 => TPD_G,
            ETH_USR_FRAME_LIMIT_G => ETH_USR_FRAME_LIMIT_G,
            AXI_BASE_ADDR_G       => AXI_CONFIG_C(AXI_RSSI_NONE_ILEAVE_INDEX_C).baseAddr)
         port map (
            -- Slave AXI-Lite Interface
            axilClk            => axilClk,
            axilRst            => axilRst,
            axilReadMaster     => axilReadMasters(AXI_RSSI_NONE_ILEAVE_INDEX_C),
            axilReadSlave      => axilReadSlaves(AXI_RSSI_NONE_ILEAVE_INDEX_C),
            axilWriteMaster    => axilWriteMasters(AXI_RSSI_NONE_ILEAVE_INDEX_C),
            axilWriteSlave     => axilWriteSlaves(AXI_RSSI_NONE_ILEAVE_INDEX_C),
            -- Master AXI-Lite Interface
            mAxilReadMaster    => mAxilReadMasters(1),
            mAxilReadSlave     => mAxilReadSlaves(1),
            mAxilWriteMaster   => mAxilWriteMasters(1),
            mAxilWriteSlave    => mAxilWriteSlaves(1),
            -- Application Debug Interface
            obAppDebugMaster   => obAppDebugMaster,
            obAppDebugSlave    => obAppDebugSlave,
            ibAppDebugMaster   => ibAppDebugMaster,
            ibAppDebugSlave    => ibAppDebugSlave,
            -- BSA Ethernet Interface
            obBsaMasters       => obBsaMasters,
            obBsaSlaves        => obBsaSlaves,
            ibBsaMasters       => ibBsaMasters,
            ibBsaSlaves        => ibBsaSlaves,
            -- Interface to UDP Server engines
            obServerMasters(0) => obServerMasters(UDP_SRV_RSSI0_IDX_C),
            obServerMasters(1) => obServerMasters(UDP_SRV_RSSI1_IDX_C),
            obServerSlaves(0)  => obServerSlaves(UDP_SRV_RSSI0_IDX_C),
            obServerSlaves(1)  => obServerSlaves(UDP_SRV_RSSI1_IDX_C),
            ibServerMasters(0) => ibServerMasters(UDP_SRV_RSSI0_IDX_C),
            ibServerMasters(1) => ibServerMasters(UDP_SRV_RSSI1_IDX_C),
            ibServerSlaves(0)  => ibServerSlaves(UDP_SRV_RSSI0_IDX_C),
            ibServerSlaves(1)  => ibServerSlaves(UDP_SRV_RSSI1_IDX_C));

      axilReadSlaves(AXI_RSSI_ILEAVE_INDEX_C)  <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
      axilWriteSlaves(AXI_RSSI_ILEAVE_INDEX_C) <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;

      obServerSlaves(UDP_SRV_RSSI_ILEAVE_IDX_C)  <= AXI_STREAM_SLAVE_FORCE_C;
      ibServerMasters(UDP_SRV_RSSI_ILEAVE_IDX_C) <= AXI_STREAM_MASTER_INIT_C;

   end generate;

   RSSI_ILEAVE : if (RSSI_ILEAVE_EN_G = true) generate

      U_RssiServer : entity work.AmcCarrierRssiInterleave
         generic map (
            TPD_G                 => TPD_G,
            ETH_USR_FRAME_LIMIT_G => ETH_USR_FRAME_LIMIT_G,
            AXI_BASE_ADDR_G       => AXI_CONFIG_C(AXI_RSSI_ILEAVE_INDEX_C).baseAddr)
         port map (
            -- Slave AXI-Lite Interface
            axilClk          => axilClk,
            axilRst          => axilRst,
            axilReadMaster   => axilReadMasters(AXI_RSSI_ILEAVE_INDEX_C),
            axilReadSlave    => axilReadSlaves(AXI_RSSI_ILEAVE_INDEX_C),
            axilWriteMaster  => axilWriteMasters(AXI_RSSI_ILEAVE_INDEX_C),
            axilWriteSlave   => axilWriteSlaves(AXI_RSSI_ILEAVE_INDEX_C),
            -- Master AXI-Lite Interface
            mAxilReadMaster  => mAxilReadMasters(1),
            mAxilReadSlave   => mAxilReadSlaves(1),
            mAxilWriteMaster => mAxilWriteMasters(1),
            mAxilWriteSlave  => mAxilWriteSlaves(1),
            -- Application Debug Interface
            obAppDebugMaster => obAppDebugMaster,
            obAppDebugSlave  => obAppDebugSlave,
            ibAppDebugMaster => ibAppDebugMaster,
            ibAppDebugSlave  => ibAppDebugSlave,
            -- BSA Ethernet Interface
            obBsaMasters     => obBsaMasters,
            obBsaSlaves      => obBsaSlaves,
            ibBsaMasters     => ibBsaMasters,
            ibBsaSlaves      => ibBsaSlaves,
            -- Interface to UDP Server engines
            obServerMaster   => obServerMasters(UDP_SRV_RSSI_ILEAVE_IDX_C),
            obServerSlave    => obServerSlaves(UDP_SRV_RSSI_ILEAVE_IDX_C),
            ibServerMaster   => ibServerMasters(UDP_SRV_RSSI_ILEAVE_IDX_C),
            ibServerSlave    => ibServerSlaves(UDP_SRV_RSSI_ILEAVE_IDX_C));

      axilReadSlaves(AXI_RSSI_NONE_ILEAVE_INDEX_C)  <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
      axilWriteSlaves(AXI_RSSI_NONE_ILEAVE_INDEX_C) <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;

      obServerSlaves(UDP_SRV_RSSI0_IDX_C)  <= AXI_STREAM_SLAVE_FORCE_C;
      ibServerMasters(UDP_SRV_RSSI0_IDX_C) <= AXI_STREAM_MASTER_INIT_C;

      obServerSlaves(UDP_SRV_RSSI1_IDX_C)  <= AXI_STREAM_SLAVE_FORCE_C;
      ibServerMasters(UDP_SRV_RSSI1_IDX_C) <= AXI_STREAM_MASTER_INIT_C;

   end generate;

   ----------------------
   -- BP Messenger Server
   ----------------------
   ibBpMsgServerMaster                  <= obServerMasters(UDP_SRV_BP_MGS_IDX_C);
   obServerSlaves(UDP_SRV_BP_MGS_IDX_C) <= ibBpMsgServerSlave;
   U_ServerLimiter : entity work.SsiFrameLimiter
      generic map (
         TPD_G               => TPD_G,
         EN_TIMEOUT_G        => true,
         MAXIS_CLK_FREQ_G    => AXI_CLK_FREQ_C,
         TIMEOUT_G           => 1.0E-3,
         FRAME_LIMIT_G       => (ETH_USR_FRAME_LIMIT_G/16),
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => ETH_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => ETH_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => obBpMsgServerMaster,
         sAxisSlave  => obBpMsgServerSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => ibServerMasters(UDP_SRV_BP_MGS_IDX_C),
         mAxisSlave  => ibServerSlaves(UDP_SRV_BP_MGS_IDX_C));

   --------------------
   -- Timing MSG Server
   --------------------
   ibServerMasters(UDP_SRV_TIMING_IDX_C) <= obTimingEthMsgMaster;
   obTimingEthMsgSlave                   <= ibServerSlaves(UDP_SRV_TIMING_IDX_C);
   ibTimingEthMsgMaster                  <= obServerMasters(UDP_SRV_TIMING_IDX_C);
   obServerSlaves(UDP_SRV_TIMING_IDX_C)  <= ibTimingEthMsgSlave;

   ----------------------
   -- BP Messenger Client
   ----------------------
   ibBpMsgClientMaster                  <= obClientMasters(UDP_CLT_BP_MGS_IDX_C);
   obClientSlaves(UDP_CLT_BP_MGS_IDX_C) <= ibBpMsgClientSlave;
   U_ClientLimiter : entity work.SsiFrameLimiter
      generic map (
         TPD_G               => TPD_G,
         EN_TIMEOUT_G        => true,
         MAXIS_CLK_FREQ_G    => AXI_CLK_FREQ_C,
         TIMEOUT_G           => 1.0E-3,
         FRAME_LIMIT_G       => (ETH_USR_FRAME_LIMIT_G/16),
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => ETH_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => ETH_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => obBpMsgClientMaster,
         sAxisSlave  => obBpMsgClientSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => ibClientMasters(UDP_CLT_BP_MGS_IDX_C),
         mAxisSlave  => ibClientSlaves(UDP_CLT_BP_MGS_IDX_C));

end mapping;
