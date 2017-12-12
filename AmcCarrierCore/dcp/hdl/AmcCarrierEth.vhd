-------------------------------------------------------------------------------
-- File       : AmcCarrierEth.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2017-02-24
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
      TPD_G                 : time            := 1 ns;
      RTM_ETH_G             : boolean         := false;
      ETH_USR_FRAME_LIMIT_G : positive        := 4096;  -- 4kB
      AXI_ERROR_RESP_G      : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Local Configuration and status
      localMac            : in  slv(47 downto 0);  --  big-Endian configuration
      localIp             : in  slv(31 downto 0);  --  big-Endian configuration   
      ethPhyReady         : out sl;
      -- Master AXI-Lite Interface
      mAxilReadMasters    : out AxiLiteReadMasterArray(1 downto 0);
      mAxilReadSlaves     : in  AxiLiteReadSlaveArray(1 downto 0);
      mAxilWriteMasters   : out AxiLiteWriteMasterArray(1 downto 0);
      mAxilWriteSlaves    : in  AxiLiteWriteSlaveArray(1 downto 0);
      -- AXI-Lite Interface
      axilClk             : in  sl;
      axilRst             : in  sl;
      axilReadMaster      : in  AxiLiteReadMasterType;
      axilReadSlave       : out AxiLiteReadSlaveType;
      axilWriteMaster     : in  AxiLiteWriteMasterType;
      axilWriteSlave      : out AxiLiteWriteSlaveType;
      -- BSA Ethernet Interface
      obBsaMasters        : in  AxiStreamMasterArray(3 downto 0);
      obBsaSlaves         : out AxiStreamSlaveArray(3 downto 0);
      ibBsaMasters        : out AxiStreamMasterArray(3 downto 0);
      ibBsaSlaves         : in  AxiStreamSlaveArray(3 downto 0);
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Application Debug Interface
      obAppDebugMaster    : in  AxiStreamMasterType;
      obAppDebugSlave     : out AxiStreamSlaveType;
      ibAppDebugMaster    : out AxiStreamMasterType;
      ibAppDebugSlave     : in  AxiStreamSlaveType;
      -- Backplane Messaging Interface
      obBpMsgClientMaster : in  AxiStreamMasterType;
      obBpMsgClientSlave  : out AxiStreamSlaveType;
      ibBpMsgClientMaster : out AxiStreamMasterType;
      ibBpMsgClientSlave  : in  AxiStreamSlaveType;
      obBpMsgServerMaster : in  AxiStreamMasterType;
      obBpMsgServerSlave  : out AxiStreamSlaveType;
      ibBpMsgServerMaster : out AxiStreamMasterType;
      ibBpMsgServerSlave  : in  AxiStreamSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- ETH Ports
      ethRxP              : in  slv(3 downto 0);
      ethRxN              : in  slv(3 downto 0);
      ethTxP              : out slv(3 downto 0);
      ethTxN              : out slv(3 downto 0);
      ethClkP             : in  sl;
      ethClkN             : in  sl);
end AmcCarrierEth;

architecture mapping of AmcCarrierEth is

   constant SERVER_SIZE_C : positive := 4;
   constant CLIENT_SIZE_C : positive := 1;

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant UDP_INDEX_C  : natural := 0;
   constant RSSI_INDEX_C : natural := 1;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      UDP_INDEX_C     => (
         baseAddr     => (ETH_ADDR_C + x"00000000"),
         addrBits     => 16,
         connectivity => X"FFFF"),
      RSSI_INDEX_C    => (
         baseAddr     => (ETH_ADDR_C + x"00010000"),
         addrBits     => 16,
         connectivity => X"FFFF"));

   function ServerPorts return PositiveArray is
      variable retConf   : PositiveArray(SERVER_SIZE_C-1 downto 0);
      variable baseIndex : positive;
   begin
      baseIndex := 8192;
      for i in SERVER_SIZE_C-1 downto 0 loop
         retConf(i) := baseIndex+i;
      end loop;
      return retConf;
   end function;

   function ClientPorts return PositiveArray is
      variable retConf   : PositiveArray(CLIENT_SIZE_C-1 downto 0);
      variable baseIndex : positive;
   begin
      baseIndex := 8192+SERVER_SIZE_C;
      for i in CLIENT_SIZE_C-1 downto 0 loop
         retConf(i) := baseIndex+i;
      end loop;
      return retConf;
   end function;

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

   -----------------------
   -- Zone2 10 GigE Module
   -----------------------
   ETH_ZONE2 : if (RTM_ETH_G = false) generate
      U_Xaui : entity work.XauiGthUltraScaleWrapper
         generic map (
            TPD_G            => TPD_G,
            EN_WDT_G         => true,
            -- XAUI Configurations
            REF_CLK_FREQ_G   => AXI_CLK_FREQ_C,
            -- AXI-Lite Configurations
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            -- AXI Streaming Configurations
            AXIS_CONFIG_G    => EMAC_AXIS_CONFIG_C)
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
            gtTxDiffCtrl   => x"FFFF",          -- 1.080 V
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
         TPD_G            => TPD_G,
         -- UDP Server Generics
         SERVER_EN_G      => true,
         SERVER_SIZE_G    => SERVER_SIZE_C,
         SERVER_PORTS_G   => ServerPorts,
         -- UDP Client Generics
         CLIENT_EN_G      => true,
         CLIENT_SIZE_G    => CLIENT_SIZE_C,
         CLIENT_PORTS_G   => ClientPorts,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         -- IPv4/ARP Generics
         CLK_FREQ_G       => AXI_CLK_FREQ_C,  -- In units of Hz
         COMM_TIMEOUT_G   => 30,  -- In units of seconds, Client's Communication timeout before re-ARPing
         VLAN_G           => false,     -- no VLAN       
         DHCP_G           => false)     -- no DHCP       
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
         axilReadMaster  => axilReadMasters(UDP_INDEX_C),
         axilReadSlave   => axilReadSlaves(UDP_INDEX_C),
         axilWriteMaster => axilWriteMasters(UDP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(UDP_INDEX_C),
         -- Clock and Reset
         clk             => axilClk,
         rst             => axilRst);

   --------------------------------------------------
   -- Legacy AXI-Lite Master without RSSI Server@8192
   --------------------------------------------------
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
         sAxisMaster         => obServerMasters(0),
         sAxisSlave          => obServerSlaves(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk            => axilClk,
         mAxisRst            => axilRst,
         mAxisMaster         => ibServerMasters(0),
         mAxisSlave          => ibServerSlaves(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axiLiteClk          => axilClk,
         axiLiteRst          => axilRst,
         mAxiLiteReadMaster  => mAxilReadMasters(0),
         mAxiLiteReadSlave   => mAxilReadSlaves(0),
         mAxiLiteWriteMaster => mAxilWriteMasters(0),
         mAxiLiteWriteSlave  => mAxilWriteSlaves(0));

   -----------------------------------------------
   -- Software's RSSI Server Interface@[8194:8193]
   -----------------------------------------------
   U_RssiServer : entity work.AmcCarrierRssi
      generic map (
         TPD_G                 => TPD_G,
         ETH_USR_FRAME_LIMIT_G => ETH_USR_FRAME_LIMIT_G,
         AXI_ERROR_RESP_G      => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G       => AXI_CONFIG_C(RSSI_INDEX_C).baseAddr)
      port map (
         -- Slave AXI-Lite Interface
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(RSSI_INDEX_C),
         axilReadSlave    => axilReadSlaves(RSSI_INDEX_C),
         axilWriteMaster  => axilWriteMasters(RSSI_INDEX_C),
         axilWriteSlave   => axilWriteSlaves(RSSI_INDEX_C),
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
         obServerMasters  => obServerMasters(2 downto 1),
         obServerSlaves   => obServerSlaves(2 downto 1),
         ibServerMasters  => ibServerMasters(2 downto 1),
         ibServerSlaves   => ibServerSlaves(2 downto 1));

   ----------------------------
   -- BP Messenger Network@8195
   ----------------------------
   ibBpMsgServerMaster <= obServerMasters(3);
   obServerSlaves(3)   <= ibBpMsgServerSlave;
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
         mAxisMaster => ibServerMasters(3),
         mAxisSlave  => ibServerSlaves(3));

   ----------------------------
   -- BP Messenger Network@8196
   ----------------------------
   ibBpMsgClientMaster <= obClientMasters(0);
   obClientSlaves(0)   <= ibBpMsgClientSlave;
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
         mAxisMaster => ibClientMasters(0),
         mAxisSlave  => ibClientSlaves(0));

end mapping;
