-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEth.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2016-02-23
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
use work.AmcCarrierRegPkg.all;

entity AmcCarrierEth is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Local Configuration
      localMac          : in  slv(47 downto 0);  --  big-Endian configuration
      localIp           : in  slv(31 downto 0);  --  big-Endian configuration   
      -- Master AXI-Lite Interface
      mAxilReadMasters  : out AxiLiteReadMasterArray(0 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(0 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(0 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(0 downto 0);
      -- AXI-Lite Interface
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- BSA Ethernet Interface
      obBsaMasters      : in  AxiStreamMasterArray(2 downto 0);
      obBsaSlaves       : out AxiStreamSlaveArray(2 downto 0);
      ibBsaMasters      : out AxiStreamMasterArray(2 downto 0);
      ibBsaSlaves       : in  AxiStreamSlaveArray(2 downto 0);
      -- Backplane Messaging Interface
      bpMsgMasters      : in  AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
      bpMsgSlaves       : out AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Backplane Messaging Interface (bpMsgClk domain)
      bpMsgClk          : in  sl := '0';
      bpMsgRst          : in  sl := '0';
      bpMsgBus          : out BpMsgBusArray(BP_MSG_SIZE_C-1 downto 0);
      ----------------
      -- Core Ports --
      ----------------   
      -- XAUI Ports
      xauiRxP           : in  slv(3 downto 0);
      xauiRxN           : in  slv(3 downto 0);
      xauiTxP           : out slv(3 downto 0);
      xauiTxN           : out slv(3 downto 0);
      xauiClkP          : in  sl;
      xauiClkN          : in  sl);
end AmcCarrierEth;

architecture mapping of AmcCarrierEth is

   constant RSSI_C         : boolean  := false;
   constant RSSI_TIMEOUT_C : real     := 1.0E-3;  -- In units of seconds
   constant MTU_C          : positive := 1500;
   constant SERVER_SIZE_C  : positive := 7+BP_MSG_SIZE_C;
   constant CLIENT_SIZE_C  : positive := BP_MSG_SIZE_C;

   constant NUM_AXI_MASTERS_C : natural := 5;

   constant PHY_INDEX_C    : natural := 0;
   constant UDP_INDEX_C    : natural := 1;
   constant SRP_INDEX_C    : natural := 2;
   constant BSA_INDEX_C    : natural := 3;
   constant BP_MSG_INDEX_C : natural := 4;

   constant PHY_ADDR_C    : slv(31 downto 0) := (XAUI_ADDR_C + x"00000000");
   constant UDP_ADDR_C    : slv(31 downto 0) := (XAUI_ADDR_C + x"00010000");
   constant SRP_ADDR_C    : slv(31 downto 0) := (XAUI_ADDR_C + x"00020000");
   constant BSA_ADDR_C    : slv(31 downto 0) := (XAUI_ADDR_C + x"00030000");
   constant BP_MSG_ADDR_C : slv(31 downto 0) := (XAUI_ADDR_C + x"00040000");

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      PHY_INDEX_C     => (
         baseAddr     => PHY_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      UDP_INDEX_C     => (
         baseAddr     => UDP_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      SRP_INDEX_C     => (
         baseAddr     => SRP_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      BSA_INDEX_C     => (
         baseAddr     => BSA_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      BP_MSG_INDEX_C  => (
         baseAddr     => BP_MSG_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"));   

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

   ----------------------
   -- 10 GigE XAUI Module
   ----------------------
   U_Xaui : entity work.XauiGthUltraScaleWrapper
      generic map (
         TPD_G            => TPD_G,
         -- XAUI Configurations
         XAUI_20GIGE_G    => false,
         REF_CLK_FREQ_G   => AXI_CLK_FREQ_C,
         -- AXI-Lite Configurations
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         -- AXI Streaming Configurations
         AXIS_CONFIG_G    => IP_ENGINE_CONFIG_C)
      port map (
         -- Local Configurations
         localMac           => localMac,
         -- Streaming DMA Interface 
         dmaClk             => axilClk,
         dmaRst             => axilRst,
         dmaIbMaster        => obMacMaster,
         dmaIbSlave         => obMacSlave,
         dmaObMaster        => ibMacMaster,
         dmaObSlave         => ibMacSlave,
         -- Slave AXI-Lite Interface 
         axiLiteClk         => axilClk,
         axiLiteRst         => axilRst,
         axiLiteReadMaster  => axilReadMasters(PHY_INDEX_C),
         axiLiteReadSlave   => axilReadSlaves(PHY_INDEX_C),
         axiLiteWriteMaster => axilWriteMasters(PHY_INDEX_C),
         axiLiteWriteSlave  => axilWriteSlaves(PHY_INDEX_C),
         -- Misc. Signals
         extRst             => axilRst,
         phyClk             => open,
         phyRst             => open,
         phyReady           => open,
         -- MGT Clock Port (156.25 MHz)
         gtClkP             => xauiClkP,
         gtClkN             => xauiClkN,
         -- MGT Ports
         gtTxP              => xauiTxP,
         gtTxN              => xauiTxN,
         gtRxP              => xauiRxP,
         gtRxN              => xauiRxN);

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UdpEngineWrapper : entity work.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G              => TPD_G,
         SIM_ERROR_HALT_G   => false,
         -- UDP General Generic
         RX_MTU_G           => MTU_C,
         RX_FORWARD_EOFE_G  => false,
         TX_FORWARD_EOFE_G  => false,
         TX_CALC_CHECKSUM_G => true,
         -- UDP Server Generics
         SERVER_EN_G        => true,
         SERVER_SIZE_G      => SERVER_SIZE_C,
         SERVER_PORTS_G     => ServerPorts,
         SERVER_MTU_G       => MTU_C,
         -- UDP Client Generics
         CLIENT_EN_G        => true,
         CLIENT_SIZE_G      => CLIENT_SIZE_C,
         CLIENT_PORTS_G     => ClientPorts,
         CLIENT_MTU_G       => MTU_C,
         -- IPv4/ARP Generics
         CLK_FREQ_G         => AXI_CLK_FREQ_C,  -- In units of Hz
         COMM_TIMEOUT_EN_G  => true,    -- Disable the timeout by setting to false
         COMM_TIMEOUT_G     => 30,  -- In units of seconds, Client's Communication timeout before re-ARPing
         ARP_TIMEOUT_G      => 156250000,       -- 1 second ARP request timeout
         VLAN_G             => false,   -- no VLAN
         AXI_ERROR_RESP_G   => AXI_ERROR_RESP_G)            
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

   ---------------------
   -- AXI-Lite Interface
   ---------------------
   U_SRP : entity work.AmcCarrierEthSrp
      generic map (
         TPD_G            => TPD_G,
         RSSI_G           => RSSI_C,
         TIMEOUT_G        => RSSI_TIMEOUT_C,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(SRP_INDEX_C).baseAddr)   
      port map (
         -- Slave AXI-Lite Interface
         axilClk           => axilClk,
         axilRst           => axilRst,
         axilReadMaster    => axilReadMasters(SRP_INDEX_C),
         axilReadSlave     => axilReadSlaves(SRP_INDEX_C),
         axilWriteMaster   => axilWriteMasters(SRP_INDEX_C),
         axilWriteSlave    => axilWriteSlaves(SRP_INDEX_C),
         -- Interface to UDP Server engines
         obServerMasters   => obServerMasters(3 downto 0),
         obServerSlaves    => obServerSlaves(3 downto 0),
         ibServerMasters   => ibServerMasters(3 downto 0),
         ibServerSlaves    => ibServerSlaves(3 downto 0),
         -- Master AXI-Lite Interface
         mAxilReadMasters  => mAxilReadMasters,
         mAxilReadSlaves   => mAxilReadSlaves,
         mAxilWriteMasters => mAxilWriteMasters,
         mAxilWriteSlaves  => mAxilWriteSlaves);     

   ----------------
   -- BSA Interface
   ----------------
   U_BSA : entity work.AmcCarrierEthBsa
      generic map (
         TPD_G            => TPD_G,
         RSSI_G           => RSSI_C,
         TIMEOUT_G        => RSSI_TIMEOUT_C,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(BSA_INDEX_C).baseAddr)     
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(BSA_INDEX_C),
         axilReadSlave   => axilReadSlaves(BSA_INDEX_C),
         axilWriteMaster => axilWriteMasters(BSA_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(BSA_INDEX_C),
         -- BSA Ethernet Interface
         obBsaMasters    => obBsaMasters,
         obBsaSlaves     => obBsaSlaves,
         ibBsaMasters    => ibBsaMasters,
         ibBsaSlaves     => ibBsaSlaves,
         -- Interface to UDP Server engines
         obServerMasters => obServerMasters(6 downto 4),
         obServerSlaves  => obServerSlaves(6 downto 4),
         ibServerMasters => ibServerMasters(6 downto 4),
         ibServerSlaves  => ibServerSlaves(6 downto 4));

   -----------------------
   -- BP Messenger Network
   -----------------------
   U_BpMsg : entity work.AmcCarrierEthBpMsg
      generic map(
         TPD_G            => TPD_G,
         RSSI_G           => RSSI_C,
         TIMEOUT_G        => RSSI_TIMEOUT_C,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(BP_MSG_INDEX_C).baseAddr)   
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(BP_MSG_INDEX_C),
         axilReadSlave   => axilReadSlaves(BP_MSG_INDEX_C),
         axilWriteMaster => axilWriteMasters(BP_MSG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(BP_MSG_INDEX_C),
         -- Interface to UDP Server engines
         obServerMasters => obServerMasters((BP_MSG_SIZE_C+6) downto 7),
         obServerSlaves  => obServerSlaves((BP_MSG_SIZE_C+6) downto 7),
         ibServerMasters => ibServerMasters((BP_MSG_SIZE_C+6) downto 7),
         ibServerSlaves  => ibServerSlaves((BP_MSG_SIZE_C+6) downto 7),
         -- Interface to UDP Client engines
         obClientMasters => obClientMasters,
         obClientSlaves  => obClientSlaves,
         ibClientMasters => ibClientMasters,
         ibClientSlaves  => ibClientSlaves,
         -- Backplane Messaging Interface
         bpMsgMasters    => bpMsgMasters,
         bpMsgSlaves     => bpMsgSlaves,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- Backplane Messaging Interface (bpMsgClk domain)
         bpMsgClk        => bpMsgClk,
         bpMsgRst        => bpMsgRst,
         bpMsgBus        => bpMsgBus);

end mapping;
