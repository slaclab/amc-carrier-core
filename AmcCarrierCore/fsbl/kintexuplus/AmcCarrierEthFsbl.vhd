-------------------------------------------------------------------------------
-- File       : AmcCarrierEthFsbl.vhd
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

entity AmcCarrierEthFsbl is
   generic (
      TPD_G : time := 1 ns);
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
      rtmHsRxP            : in  sl;
      rtmHsRxN            : in  sl;
      rtmHsTxP            : out sl;
      rtmHsTxN            : out sl;
      ethClkP             : in  sl;
      ethClkN             : in  sl);
end AmcCarrierEthFsbl;

architecture mapping of AmcCarrierEthFsbl is

   signal phyReady : slv(1 downto 0);

   signal ibMacMasters : AxiStreamMasterArray(1 downto 0);
   signal ibMacSlaves  : AxiStreamSlaveArray(1 downto 0);
   signal obMacMasters : AxiStreamMasterArray(1 downto 0);
   signal obMacSlaves  : AxiStreamSlaveArray(1 downto 0);

   signal obServerMasters : AxiStreamMasterArray(1 downto 0);
   signal obServerSlaves  : AxiStreamSlaveArray(1 downto 0);
   signal ibServerMasters : AxiStreamMasterArray(1 downto 0);
   signal ibServerSlaves  : AxiStreamSlaveArray(1 downto 0);

   signal rtmMac : slv(47 downto 0);

begin

   rtmMac(47 downto 40) <= (localMac(47 downto 40) + 1);
   rtmMac(39 downto 0)  <= localMac(39 downto 0);

   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

   -- BSA Ethernet Interface
   obBsaSlaves  <= (others => AXI_STREAM_SLAVE_FORCE_C);
   ibBsaMasters <= (others => AXI_STREAM_MASTER_INIT_C);

   -- Application Debug Interface
   obAppDebugSlave  <= AXI_STREAM_SLAVE_FORCE_C;
   ibAppDebugMaster <= AXI_STREAM_MASTER_INIT_C;

   -- Backplane Messaging Interface
   obBpMsgClientSlave  <= AXI_STREAM_SLAVE_FORCE_C;
   ibBpMsgClientMaster <= AXI_STREAM_MASTER_INIT_C;
   obBpMsgServerSlave  <= AXI_STREAM_SLAVE_FORCE_C;
   ibBpMsgServerMaster <= AXI_STREAM_MASTER_INIT_C;

   -----------------------
   -- Zone2 10 GigE Module
   -----------------------
   U_Xaui : entity work.XauiGtyUltraScaleWrapper
      generic map (
         TPD_G         => TPD_G,
         EN_WDT_G      => true,
         -- AXI Streaming Configurations
         AXIS_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Local Configurations
         localMac       => localMac,
         -- Streaming DMA Interface 
         dmaClk         => axilClk,
         dmaRst         => axilRst,
         dmaIbMaster    => obMacMasters(0),
         dmaIbSlave     => obMacSlaves(0),
         dmaObMaster    => ibMacMasters(0),
         dmaObSlave     => ibMacSlaves(0),
         -- Misc. Signals
         extRst         => axilRst,
         stableClk      => axilClk,
         phyReady       => phyReady(0),
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

   ----------------------
   -- Zone3 1 GigE Module
   ----------------------
   U_Rtm : entity work.GigEthGtyUltraScaleWrapper
      generic map (
         TPD_G              => TPD_G,
         -- DMA/MAC Configurations
         NUM_LANE_G         => 1,
         -- QUAD PLL Configurations
         USE_GTREFCLK_G     => true,
         CLKIN_PERIOD_G     => 6.4,     -- 156.25 MHz
         DIVCLK_DIVIDE_G    => 5,       -- 31.25 MHz = (156.25 MHz/5)
         CLKFBOUT_MULT_F_G  => 32.0,    -- 1 GHz = (32 x 31.25 MHz)
         CLKOUT0_DIVIDE_F_G => 8.0,     -- 125 MHz = (1.0 GHz/8)         
         -- AXI Streaming Configurations
         AXIS_CONFIG_G      => (others => EMAC_AXIS_CONFIG_C))
      port map (
         -- Local Configurations
         localMac(0)     => rtmMac,
         -- Streaming DMA Interface 
         dmaClk(0)       => axilClk,
         dmaRst(0)       => axilRst,
         dmaIbMasters(0) => obMacMasters(1),
         dmaIbSlaves(0)  => obMacSlaves(1),
         dmaObMasters(0) => ibMacMasters(1),
         dmaObSlaves(0)  => ibMacSlaves(1),
         -- Misc. Signals
         extRst          => axilRst,
         phyReady(0)     => phyReady(1),
         -- MGT Clock Port 
         gtRefClk        => axilClk,
         gtClkP          => '1',
         gtClkN          => '0',
         -- MGT Ports
         gtTxP(0)        => rtmHsTxP,
         gtTxN(0)        => rtmHsTxN,
         gtRxP(0)        => rtmHsRxP,
         gtRxN(0)        => rtmHsRxN);

   ethPhyReady <= uOr(phyReady);

   GEN_VEC :
   for i in 1 downto 0 generate

      ----------------------
      -- IPv4/ARP/UDP Engine
      ----------------------
      U_UdpEngineWrapper : entity work.UdpEngineWrapper
         generic map (
            -- Simulation Generics
            TPD_G          => TPD_G,
            -- UDP Server Generics
            SERVER_EN_G    => true,
            SERVER_SIZE_G  => 1,
            SERVER_PORTS_G => (0 => 8192),
            -- UDP Client Generics
            CLIENT_EN_G    => false,
            -- IPv4/ARP Generics
            CLK_FREQ_G     => AXI_CLK_FREQ_C,  -- In units of Hz
            VLAN_G         => false,           -- no VLAN       
            DHCP_G         => false)           -- no DHCP       
         port map (
            -- Local Configurations
            localMac           => localMac,
            localIp            => localIp,
            -- Interface to Ethernet Media Access Controller (MAC)
            obMacMaster        => obMacMasters(i),
            obMacSlave         => obMacSlaves(i),
            ibMacMaster        => ibMacMasters(i),
            ibMacSlave         => ibMacSlaves(i),
            -- Interface to UDP Server engine(s)
            obServerMasters(0) => obServerMasters(i),
            obServerSlaves(0)  => obServerSlaves(i),
            ibServerMasters(0) => ibServerMasters(i),
            ibServerSlaves(0)  => ibServerSlaves(i),
            -- Clock and Reset
            clk                => axilClk,
            rst                => axilRst);

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
            sAxisMaster         => obServerMasters(i),
            sAxisSlave          => obServerSlaves(i),
            -- Streaming Master (Tx) Data Interface (mAxisClk domain)
            mAxisClk            => axilClk,
            mAxisRst            => axilRst,
            mAxisMaster         => ibServerMasters(i),
            mAxisSlave          => ibServerSlaves(i),
            -- AXI Lite Bus (axiLiteClk domain)
            axiLiteClk          => axilClk,
            axiLiteRst          => axilRst,
            mAxiLiteReadMaster  => mAxilReadMasters(i),
            mAxiLiteReadSlave   => mAxilReadSlaves(i),
            mAxiLiteWriteMaster => mAxilWriteMasters(i),
            mAxiLiteWriteSlave  => mAxilWriteSlaves(i));

   end generate GEN_VEC;

end mapping;
