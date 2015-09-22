-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthNoVlan.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2015-09-22
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

entity AmcCarrierEthNoVlan is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset   
      axilClk           : in  sl;
      axilRst           : in  sl;
      -- Local Configuration
      localMac          : in  slv(47 downto 0);  --  big-Endian configuration
      localIp           : in  slv(31 downto 0);  --  big-Endian configuration   
      -- Interface to Ethernet Media Access Controller (MAC)
      obMacMaster       : in  AxiStreamMasterType;
      obMacSlave        : out AxiStreamSlaveType;
      ibMacMaster       : out AxiStreamMasterType;
      ibMacSlave        : in  AxiStreamSlaveType;
      -- Master AXI-Lite Interface
      mAxilReadMasters  : out AxiLiteReadMasterArray(3 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(3 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(3 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(3 downto 0);
      -- BSA Ethernet Interface
      obBsaMaster       : in  AxiStreamMasterType;
      obBsaSlave        : out AxiStreamSlaveType;
      ibBsaMaster       : out AxiStreamMasterType;
      ibBsaSlave        : in  AxiStreamSlaveType;
      -- Boot Prom AXI Streaming Interface
      obPromMaster      : in  AxiStreamMasterType;
      obPromSlave       : out AxiStreamSlaveType;
      ibPromMaster      : out AxiStreamMasterType;
      ibPromSlave       : in  AxiStreamSlaveType); 
end AmcCarrierEthNoVlan;

architecture mapping of AmcCarrierEthNoVlan is

   constant RX_MTU_C      : positive := 1500;
   constant SERVER_SIZE_C : positive := 6;
   constant SERVER_PORTS_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (
      0 => 8192,                        -- EPICS IOC[0]
      1 => 8193,                        -- EPICS IOC[1]
      2 => 8194,                        -- EPICS IOC[2]
      3 => 8195,                        -- EPICS IOC[3]
      4 => 8196,                        -- PROM Inbound/Outbound
      5 => 8197);                       -- BSA Inbound/Outbound
   constant SERVER_MTU_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (
      0 => 1500,                        -- EPICS IOC[0]
      1 => 1500,                        -- EPICS IOC[1]
      2 => 1500,                        -- EPICS IOC[2]
      3 => 1500,                        -- EPICS IOC[3]
      4 => 1500,                        -- PROM Inbound/Outbound
      5 => 1500);                       -- BSA Inbound/Outbound

   signal obServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal obServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal ibServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ibServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal sAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal mAxisMasters : AxiStreamMasterArray(3 downto 0);
   
begin

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

   -----------------------------------------------            
   -- Server[3:0]@[8915:8192] = AXI-Lite Interface 
   -----------------------------------------------        
   GEN_VEC :
   for i in 3 downto 0 generate
      
      sAxisMasters(i)    <= Axis32BitEndianConvert(obServerMasters(i));
      ibServerMasters(i) <= Axis32BitEndianConvert(mAxisMasters(i));
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
            sAxisMaster         => sAxisMasters(i),
            sAxisSlave          => obServerSlaves(i),
            -- Streaming Master (Tx) Data Interface (mAxisClk domain)
            mAxisClk            => axilClk,
            mAxisRst            => axilRst,
            mAxisMaster         => mAxisMasters(i),
            mAxisSlave          => ibServerSlaves(i),
            -- AXI Lite Bus (axiLiteClk domain)
            axiLiteClk          => axilClk,
            axiLiteRst          => axilRst,
            mAxiLiteReadMaster  => mAxilReadMasters(i),
            mAxiLiteReadSlave   => mAxilReadSlaves(i),
            mAxiLiteWriteMaster => mAxilWriteMasters(i),
            mAxiLiteWriteSlave  => mAxilWriteSlaves(i));            

   end generate GEN_VEC;

   -----------------------------------------
   -- Server[4]@8196 = PROM Inbound/Outbound
   -----------------------------------------
   ibServerMasters(4) <= Axis32BitEndianConvert(obPromMaster);
   obPromSlave        <= ibServerSlaves(4);
   ibPromMaster       <= Axis32BitEndianConvert(obServerMasters(4));
   obServerSlaves(4)  <= ibPromSlave;

   ----------------------------------------     
   -- Server[5]@8197 = BSA Inbound/Outbound
   ----------------------------------------     
   ibServerMasters(5) <= obBsaMaster;
   obBsaSlave         <= ibServerSlaves(5);
   ibBsaMaster        <= obServerMasters(5);
   obServerSlaves(5)  <= ibBsaSlave;
   
end mapping;
