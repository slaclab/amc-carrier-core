-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierXaui.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-09-08
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.UdpEnginePkg.all;
use work.IpV4EnginePkg.all;

entity AmcCarrierXaui is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Local Configuration
      localMac         : in  slv(47 downto 0);  --  big-Endian configuration
      localIp          : in  slv(31 downto 0);  --  big-Endian configuration   
      -- Master AXI-Lite Interface
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;
      -- AXI-Lite Interface
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType;
      -- BSA Ethernet Client Interface
      obBsaMaster      : in  AxiStreamMasterType;
      obBsaSlave       : out AxiStreamSlaveType;
      ibBsaMaster      : out AxiStreamMasterType;
      ibBsaSlave       : in  AxiStreamSlaveType;
      -- Boot Prom AXI Streaming Interface
      obPromMaster     : in  AxiStreamMasterType;
      obPromSlave      : out AxiStreamSlaveType;
      ibPromMaster     : out AxiStreamMasterType;
      ibPromSlave      : in  AxiStreamSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- XAUI Ports
      xauiRxP          : in  slv(3 downto 0);
      xauiRxN          : in  slv(3 downto 0);
      xauiTxP          : out slv(3 downto 0);
      xauiTxN          : out slv(3 downto 0);
      xauiClkP         : in  sl;
      xauiClkN         : in  sl);  
end AmcCarrierXaui;

architecture mapping of AmcCarrierXaui is

   constant RX_MTU_C      : positive := 1500;
   constant SERVER_SIZE_C : positive := 3;
   constant SERVER_PORTS_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (
      0 => 8192,                        -- AXI-Lite Interface 
      1 => 8193,                        -- PROM Inbound/Outbound
      2 => 8194);                       -- BSA Inbound/Outbound
   constant SERVER_MTU_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (
      0 => 1500,                        -- AXI-Lite Interface 
      1 => 1500,                        -- PROM Inbound/Outbound
      2 => 1500);                       -- BSA Inbound/Outbound

   signal dmaIbMaster : AxiStreamMasterType;
   signal dmaIbSlave  : AxiStreamSlaveType;
   signal dmaObMaster : AxiStreamMasterType;
   signal dmaObSlave  : AxiStreamSlaveType;
   signal obMaster    : AxiStreamMasterType;

   signal ibMacMaster : AxiStreamMasterType;
   signal ibMacSlave  : AxiStreamSlaveType;
   signal obMacMaster : AxiStreamMasterType;
   signal obMacSlave  : AxiStreamSlaveType;

   signal obServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal obServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal ibServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ibServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal axilIbTxMaster : AxiStreamMasterType;
   signal axilObTxMaster : AxiStreamMasterType;
   
begin

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);   

   ----------------------
   -- 10 GigE XAUI Module
   ----------------------
   XauiGthUltraScaleWrapper_Inst : entity work.XauiGthUltraScaleWrapper
      generic map (
         TPD_G         => TPD_G,
         -- AXI Streaming Configurations
         AXIS_CONFIG_G => ssiAxiStreamConfig(8))  
      port map (
         -- Local Configurations
         localMac           => localMac,
         -- Streaming DMA Interface 
         dmaClk             => axilClk,
         dmaRst             => axilRst,
         dmaIbMaster        => dmaIbMaster,
         dmaIbSlave         => dmaIbSlave,
         dmaObMaster        => dmaObMaster,
         dmaObSlave         => dmaObSlave,
         -- Slave AXI-Lite Interface 
         axiLiteClk         => axilClk,
         axiLiteRst         => axilRst,
         axiLiteReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
         axiLiteReadSlave   => open,
         axiLiteWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
         axiLiteWriteSlave  => open,
         -- MGT Clock Port (156.25 MHz)
         gtClkP             => xauiClkP,
         gtClkN             => xauiClkN,
         -- MGT Ports
         gtTxP              => xauiTxP,
         gtTxN              => xauiTxN,
         gtRxP              => xauiRxP,
         gtRxN              => xauiRxN);  

   ----------------------------------------         
   -- Retrofitting the "old" MAC
   -- to work with new IPv4 and UDP engines
   ----------------------------------------         
   SsiInsertSof_Inst : entity work.SsiInsertSof
      generic map (
         TPD_G               => TPD_G,
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => true,
         MASTER_FIFO_G       => true,
         SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(8),
         MASTER_AXI_CONFIG_G => IP_ENGINE_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => dmaIbMaster,
         sAxisSlave  => dmaIbSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => obMacMaster,
         mAxisSlave  => obMacSlave);   

   FIFO_Inbound : entity work.AxiStreamFifo
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => false,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 4,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
         MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(8))            
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => ibMacMaster,
         sAxisSlave  => ibMacSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => obMaster,
         mAxisSlave  => dmaObSlave);  

   -- Current MAC only support 64-bit inbound transfers
   dmaObMaster.tValid <= obMaster.tValid;
   dmaObMaster.tData  <= obMaster.tData;
   dmaObMaster.tStrb  <= obMaster.tStrb;
   dmaObMaster.tKeep  <= x"00FF";
   dmaObMaster.tLast  <= obMaster.tLast;
   dmaObMaster.tDest  <= obMaster.tDest;
   dmaObMaster.tId    <= obMaster.tId;
   dmaObMaster.tUser  <= obMaster.tUser;

   ----------------------
   -- IPv4/ARP/UDP Engine
   ----------------------
   U_UdpEngineWrapper : entity work.UdpEngineWrapper
      generic map (
         -- Simulation Generics
         TPD_G              => TPD_G,
         SIM_ERROR_HALT_G   => false,
         -- UDP General Generic
         RX_MTU_G           => RX_MTU_C,
         RX_FORWARD_EOFE_G  => false,
         TX_FORWARD_EOFE_G  => false,
         TX_CALC_CHECKSUM_G => true,
         -- UDP Server Generics
         SERVER_EN_G        => true,
         SERVER_SIZE_G      => SERVER_SIZE_C,
         SERVER_PORTS_G     => SERVER_PORTS_C,
         SERVER_MTU_G       => SERVER_MTU_C,
         -- UDP Client Generics
         CLIENT_EN_G        => false,
         CLIENT_SIZE_G      => 1,
         -- IPv4/ARP Generics
         CLK_FREQ_G         => 156.25E+06,  -- In units of Hz
         COMM_TIMEOUT_EN_G  => true,    -- Disable the timeout by setting to false
         COMM_TIMEOUT_G     => 30,  -- In units of seconds, Client's Communication timeout before re-ARPing
         ARP_TIMEOUT_G      => 156250000,   -- 1 second ARP request timeout
         VLAN_G             => false)   -- no VLAN
      port map (
         -- Local Configurations
         localMac         => localMac,
         localIp          => localIp,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster      => obMacMaster,
         obMacSlave       => obMacSlave,
         ibMacMaster      => ibMacMaster,
         ibMacSlave       => ibMacSlave,
         -- Interface to UDP Server engine(s)
         obServerMasters  => obServerMasters,
         obServerSlaves   => obServerSlaves,
         ibServerMasters  => ibServerMasters,
         ibServerSlaves   => ibServerSlaves,
         -- Interface to UDP Client engine(s)
         clientRemotePort => (others => (others => '0')),
         clientRemoteIp   => (others => (others => '0')),
         obClientMasters  => open,
         obClientSlaves   => (others => AXI_STREAM_SLAVE_FORCE_C),
         ibClientMasters  => (others => AXI_STREAM_MASTER_INIT_C),
         ibClientSlaves   => open,
         -- Clock and Reset
         clk              => axilClk,
         rst              => axilRst);

   --------------------------------------            
   -- Server[0]@8192 = AXI-Lite Interface 
   --------------------------------------            
   axilIbTxMaster     <= Axis32BitEndianConvert(obServerMasters(0));
   ibServerMasters(0) <= Axis32BitEndianConvert(axilObTxMaster);
   U_SsiAxiLiteMaster : entity work.SsiAxiLiteMaster
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         EN_32BIT_ADDR_G     => true,
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => true,
         AXI_STREAM_CONFIG_G => ssiAxiStreamConfig(16))   
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk            => axilClk,
         sAxisRst            => axilRst,
         sAxisMaster         => axilIbTxMaster,
         sAxisSlave          => ibServerSlaves(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk            => axilClk,
         mAxisRst            => axilRst,
         mAxisMaster         => axilObTxMaster,
         mAxisSlave          => obServerSlaves(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axiLiteClk          => axilClk,
         axiLiteRst          => axilRst,
         mAxiLiteReadMaster  => mAxilReadMaster,
         mAxiLiteReadSlave   => mAxilReadSlave,
         mAxiLiteWriteMaster => mAxilWriteMaster,
         mAxiLiteWriteSlave  => mAxilWriteSlave);            

   -----------------------------------------
   -- Server[1]@8193 = PROM Inbound/Outbound
   -----------------------------------------
   ibServerMasters(1) <= Axis32BitEndianConvert(obPromMaster);
   obPromSlave        <= ibServerSlaves(1);
   ibPromMaster       <= Axis32BitEndianConvert(obServerMasters(1));
   obServerSlaves(1)  <= ibPromSlave;

   ----------------------------------------     
   -- Server[2]@8194 = BSA Inbound/Outbound
   ----------------------------------------     
   ibServerMasters(2) <= obBsaMaster;
   obBsaSlave         <= ibServerSlaves(2);
   ibBsaMaster        <= obServerMasters(2);
   obServerSlaves(2)  <= ibBsaSlave;
   
end mapping;
