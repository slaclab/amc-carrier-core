-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthVlan.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2015-09-21
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
use work.AmcCarrierPkg.all;

entity AmcCarrierEthVlan is
   generic (
      TPD_G             : time            := 1 ns;
      FFB_CLIENT_SIZE_G : positive        := 1;
      AXI_ERROR_RESP_G  : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Local Configuration
      localMac        : in  slv(47 downto 0);  --  big-Endian configuration
      localIp         : in  slv(31 downto 0);  --  big-Endian configuration   
      -- Interface to Ethernet Media Access Controller (MAC)
      obMacMaster     : in  AxiStreamMasterType;
      obMacSlave      : out AxiStreamSlaveType;
      ibMacMaster     : out AxiStreamMasterType;
      ibMacSlave      : in  AxiStreamSlaveType;
      -- FFB Outbound Interface
      ffbObMaster     : in  AxiStreamMasterType;
      ffbObSlave      : out AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- FFB Inbound Interface (ffbClk domain)
      ffbClk          : in  sl;
      ffbRst          : in  sl;
      ffbData         : out FfbDataType);      
end AmcCarrierEthVlan;

architecture mapping of AmcCarrierEthVlan is

   constant RX_MTU_C : positive := 1500;

   constant SERVER_SIZE_C  : positive                                       := 1;
   constant SERVER_PORTS_C : PositiveArray(SERVER_SIZE_C-1 downto 0)        := (others => 8192);
   constant SERVER_MTU_C   : PositiveArray(SERVER_SIZE_C-1 downto 0)        := (others => 1500);
   signal obServerMasters  : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal obServerSlaves   : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   constant CLIENT_SIZE_C  : positive range 1 to 32                         := FFB_CLIENT_SIZE_G;
   constant CLIENT_PORTS_C : PositiveArray(CLIENT_SIZE_C-1 downto 0)        := (others => 8192);
   constant CLIENT_MTU_C   : PositiveArray(CLIENT_SIZE_C-1 downto 0)        := (others => 1500);
   signal ibClientMasters  : AxiStreamMasterArray(CLIENT_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ibClientSlaves   : AxiStreamSlaveArray(CLIENT_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal clientRemotePort : Slv16Array(CLIENT_SIZE_C-1 downto 0)           := (others => (others => '0'));
   signal clientRemoteIp   : Slv32Array(CLIENT_SIZE_C-1 downto 0)           := (others => (others => '0'));
   
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
         CLIENT_EN_G        => false,   -- Place holder for future implementation
         CLIENT_SIZE_G      => CLIENT_SIZE_C,
         CLIENT_PORTS_G     => CLIENT_PORTS_C,
         CLIENT_MTU_G       => CLIENT_MTU_C,
         -- IPv4/ARP Generics
         CLK_FREQ_G         => 156.25E+06,  -- In units of Hz
         COMM_TIMEOUT_EN_G  => true,    -- Disable the timeout by setting to false
         COMM_TIMEOUT_G     => 30,  -- In units of seconds, Client's Communication timeout before re-ARPing
         ARP_TIMEOUT_G      => 156250000,   -- 1 second ARP request timeout
         VLAN_G             => true)    -- VLAN
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
         ibServerMasters  => (others => AXI_STREAM_MASTER_INIT_C),
         ibServerSlaves   => open,
         -- Interface to UDP Client engine(s)
         clientRemotePort => clientRemotePort,
         clientRemoteIp   => clientRemoteIp,
         obClientMasters  => open,
         obClientSlaves   => (others => AXI_STREAM_SLAVE_FORCE_C),
         ibClientMasters  => ibClientMasters,
         ibClientSlaves   => ibClientSlaves,
         -- Clock and Reset
         clk              => axilClk,
         rst              => axilRst);

   -----------------------------------------------            
   -- Server[0]@8192 = FFB Inbound Interface
   ----------------------------------------------- 
   U_FfbIbMsg : entity work.AmcCarrierFfbIbMsg
      generic map (
         TPD_G => TPD_G) 
      port map (
         -- Clock and reset
         clk            => axilClk,
         rst            => axilRst,
         obServerMaster => obServerMasters(0),
         obServerSlave  => obServerSlaves(0),
         ----------------------
         -- Top Level Interface
         ----------------------
         -- FFB Inbound Interface (ffbClk domain)
         ffbClk         => ffbClk,
         ffbRst         => ffbRst,
         ffbData        => ffbData);

   -------------------------
   -- FFB Outbound Interface
   -------------------------
   ffbObSlave <= AXI_STREAM_SLAVE_FORCE_C;

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

end mapping;
