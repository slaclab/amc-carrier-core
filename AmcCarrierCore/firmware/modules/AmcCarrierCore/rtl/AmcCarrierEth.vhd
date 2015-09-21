-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEth.vhd
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
      mAxilReadMasters  : out AxiLiteReadMasterArray(3 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(3 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(3 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(3 downto 0);
      -- AXI-Lite Interface
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- BSA Ethernet Interface
      obBsaMaster       : in  AxiStreamMasterType;
      obBsaSlave        : out AxiStreamSlaveType;
      ibBsaMaster       : out AxiStreamMasterType;
      ibBsaSlave        : in  AxiStreamSlaveType;
      -- Boot Prom AXI Streaming Interface
      obPromMaster      : in  AxiStreamMasterType;
      obPromSlave       : out AxiStreamSlaveType;
      ibPromMaster      : out AxiStreamMasterType;
      ibPromSlave       : in  AxiStreamSlaveType;
      -- FFB Outbound Interface
      ffbObMaster       : in  AxiStreamMasterType;
      ffbObSlave        : out AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- FFB Inbound Interface (ffbClk domain)
      ffbClk            : in  sl;
      ffbRst            : in  sl;
      ffbData           : out FfbDataType;
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

   signal dmaIbMaster : AxiStreamMasterType;
   signal dmaIbSlave  : AxiStreamSlaveType;
   signal dmaObMaster : AxiStreamMasterType;
   signal dmaObSlave  : AxiStreamSlaveType;
   signal obMaster    : AxiStreamMasterType;

   signal ibMacMaster : AxiStreamMasterType;
   signal ibMacSlave  : AxiStreamSlaveType;
   signal obMacMaster : AxiStreamMasterType;
   signal obMacSlave  : AxiStreamSlaveType;
   
begin

   ----------------------
   -- 10 GigE XAUI Module
   ----------------------
   U_Xaui : entity work.XauiGthUltraScaleWrapper
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

   --------------------
   -- No VLAN Interface
   --------------------
   U_NoVlan : entity work.AmcCarrierEthNoVlan
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset   
         axilClk           => axilClk,
         axilRst           => axilRst,
         -- Local Configuration
         localMac          => localMac,
         localIp           => localIp,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster       => obMacMaster,
         obMacSlave        => obMacSlave,
         ibMacMaster       => ibMacMaster,
         ibMacSlave        => ibMacSlave,
         -- Master AXI-Lite Interface
         mAxilReadMasters  => mAxilReadMasters,
         mAxilReadSlaves   => mAxilReadSlaves,
         mAxilWriteMasters => mAxilWriteMasters,
         mAxilWriteSlaves  => mAxilWriteSlaves,
         -- BSA Ethernet Interface
         obBsaMaster       => obBsaMaster,
         obBsaSlave        => obBsaSlave,
         ibBsaMaster       => ibBsaMaster,
         ibBsaSlave        => ibBsaSlave,
         -- Boot Prom AXI Streaming Interface
         obPromMaster      => obPromMaster,
         obPromSlave       => obPromSlave,
         ibPromMaster      => ibPromMaster,
         ibPromSlave       => ibPromSlave);

   -----------------
   -- VLAN Interface
   -----------------   
   U_Vlan : entity work.AmcCarrierEthVlan
      generic map (
         TPD_G             => TPD_G,
         FFB_CLIENT_SIZE_G => FFB_CLIENT_SIZE_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- Local Configuration
         localMac        => localMac,
         localIp         => localIp,
         -- Interface to Ethernet Media Access Controller (MAC)
         obMacMaster     => AXI_STREAM_MASTER_INIT_C,
         obMacSlave      => open,
         ibMacMaster     => open,
         ibMacSlave      => AXI_STREAM_SLAVE_FORCE_C,
         -- FFB Outbound Interface
         ffbObMaster     => ffbObMaster,
         ffbObSlave      => ffbObSlave,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- FFB Inbound Interface (ffbClk domain)
         ffbClk          => ffbClk,
         ffbRst          => ffbRst,
         ffbData         => ffbData);      

end mapping;
