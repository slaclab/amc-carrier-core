-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEth.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2016-01-13
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

entity AmcCarrierEth is
   generic (
      TPD_G             : time            := 1 ns;
      FFB_CLIENT_SIZE_G : positive        := 1;
      AXI_ERROR_RESP_G  : slv(1 downto 0) := AXI_RESP_DECERR_C);
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
      -- FFB Outbound Interface
      ffbObMaster       : in  AxiStreamMasterType;
      ffbObSlave        : out AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- FFB Inbound Interface (ffbClk domain)
      ffbClk            : in  sl;
      ffbRst            : in  sl;
      ffbBus            : out FfbBusType;
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

   signal ibMacMaster : AxiStreamMasterType;
   signal ibMacSlave  : AxiStreamSlaveType;
   signal obMacMaster : AxiStreamMasterType;
   signal obMacSlave  : AxiStreamSlaveType;

   constant RX_MTU_C      : positive := 1500;
   constant SERVER_SIZE_C : positive := 8;
   constant SERVER_PORTS_C : PositiveArray(SERVER_SIZE_C-1 downto 0) := (
      0 => 8192,                        -- EPICS IOC[0]
      1 => 8193,                        -- EPICS IOC[1]
      2 => 8194,                        -- EPICS IOC[2]
      3 => 8195,                        -- EPICS IOC[3]
      4 => 8196,                        -- EPICS BSA[0]
      5 => 8197,                        -- EPICS BSA[1]
      6 => 8198,                        -- EPICS BSA[2]      
      7 => 8199);                       -- FFB Inbound
   constant SERVER_MTU_C  : positive                                       := RX_MTU_C;
   signal obServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal obServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal ibServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ibServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   constant CLIENT_SIZE_C  : positive range 1 to 32                         := FFB_CLIENT_SIZE_G;
   constant CLIENT_PORTS_C : PositiveArray(CLIENT_SIZE_C-1 downto 0)        := (others => 8200);
   constant CLIENT_MTU_C   : positive                                       := RX_MTU_C;
   signal ibClientMasters  : AxiStreamMasterArray(CLIENT_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal ibClientSlaves   : AxiStreamSlaveArray(CLIENT_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal clientRemotePort : Slv16Array(CLIENT_SIZE_C-1 downto 0)           := (others => toSlv(SERVER_PORTS_C(7), 16));
   signal clientRemoteIp   : Slv32Array(CLIENT_SIZE_C-1 downto 0)           := (others => (others => '0'));

begin

   ----------------------
   -- 10 GigE XAUI Module
   ----------------------
   U_Xaui : entity work.XauiGthUltraScaleWrapper
      generic map (
         TPD_G            => TPD_G,
         -- XAUI Configurations
         XAUI_20GIGE_G    => false,
         REF_CLK_FREQ_G   => 156.25E+6,
         -- AXI-Lite Configurations
         AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C,
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
         axiLiteReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
         axiLiteReadSlave   => open,
         axiLiteWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
         axiLiteWriteSlave  => open,
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
         CLIENT_EN_G        => false,       -- Place holder for future implementation
         CLIENT_SIZE_G      => CLIENT_SIZE_C,
         CLIENT_PORTS_G     => CLIENT_PORTS_C,
         CLIENT_MTU_G       => CLIENT_MTU_C,
         -- IPv4/ARP Generics
         CLK_FREQ_G         => 156.25E+06,  -- In units of Hz
         COMM_TIMEOUT_EN_G  => true,        -- Disable the timeout by setting to false
         COMM_TIMEOUT_G     => 30,          -- In units of seconds, Client's Communication timeout before re-ARPing
         ARP_TIMEOUT_G      => 156250000,   -- 1 second ARP request timeout
         VLAN_G             => false)       -- no VLAN
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
         clientRemotePort => clientRemotePort,
         clientRemoteIp   => clientRemoteIp,
         obClientMasters  => open,
         obClientSlaves   => (others => AXI_STREAM_SLAVE_FORCE_C),
         ibClientMasters  => ibClientMasters,
         ibClientSlaves   => ibClientSlaves,
         -- Clock and Reset
         clk              => axilClk,
         rst              => axilRst);

   ---------------------
   -- AXI-Lite Interface
   ---------------------
   U_SRP : entity work.AmcCarrierSrpV0Wrapper
      generic map (
         -- Simulation Generics
         TPD_G      => TPD_G,
         IOC_SIZE_G => 4)
      port map (
         axilClk           => axilClk,
         axilRst           => axilRst,
         -- UDP Interface Interface
         obServerMasters   => obServerMasters(3 downto 0),
         obServerSlaves    => obServerSlaves(3 downto 0),
         ibServerMasters   => ibServerMasters(3 downto 0),
         ibServerSlaves    => ibServerSlaves(3 downto 0),
         -- Master AXI-Lite Interface
         mAxilReadMasters  => mAxilReadMasters,
         mAxilReadSlaves   => mAxilReadSlaves,
         mAxilWriteMasters => mAxilWriteMasters,
         mAxilWriteSlaves  => mAxilWriteSlaves);

   ---------------------------------
   -- BSA Inbound/Outbound Interface
   ---------------------------------
   ibServerMasters(6 downto 4) <= obBsaMasters;
   obBsaSlaves                 <= ibServerSlaves(6 downto 4);
   ibBsaMasters                <= obServerMasters(6 downto 4);
   obServerSlaves(6 downto 4)  <= ibBsaSlaves;

   ------------------------
   -- FFB Inbound Interface
   ------------------------
   U_FfbIbMsg : entity work.AmcCarrierFfbIbMsg
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and reset
         clk            => axilClk,
         rst            => axilRst,
         obServerMaster => obServerMasters(7),
         obServerSlave  => obServerSlaves(7),
         ----------------------
         -- Top Level Interface
         ----------------------
         -- FFB Inbound Interface (ffbClk domain)
         ffbClk         => ffbClk,
         ffbRst         => ffbRst,
         ffbBus         => ffbBus);

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
