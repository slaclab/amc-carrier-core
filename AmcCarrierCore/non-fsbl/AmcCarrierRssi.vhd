-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.EthMacPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;
use amc_carrier_core.FpgaTypePkg.all;

entity AmcCarrierRssi is
   generic (
      TPD_G                 : time             := 1 ns;
      ETH_USR_FRAME_LIMIT_G : positive         := 4096;  -- 4kB
      AXI_BASE_ADDR_G       : slv(31 downto 0) := (others => '0'));
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
      obAppDebugMaster : in  AxiStreamMasterType;
      obAppDebugSlave  : out AxiStreamSlaveType;
      ibAppDebugMaster : out AxiStreamMasterType;
      ibAppDebugSlave  : in  AxiStreamSlaveType;
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
end AmcCarrierRssi;

architecture mapping of AmcCarrierRssi is

   constant TIMEOUT_C          : real     := 1.0E-3;  -- In units of seconds
   constant WINDOW_ADDR_SIZE_C : positive := 3;
   constant MAX_CUM_ACK_CNT_C  : positive := WINDOW_ADDR_SIZE_C;
   constant MAX_RETRANS_CNT_C  : positive := ite((WINDOW_ADDR_SIZE_C > 1), WINDOW_ADDR_SIZE_C-1, 1);

   constant APP_AXIS_CONFIG_C  : AxiStreamConfigArray(4 downto 0) := (others => AXIS_8BYTE_CONFIG_C);
   constant TEMP_AXIS_CONFIG_C : AxiStreamConfigArray(1 downto 0) := (others => AXIS_8BYTE_CONFIG_C);

   signal rssiIbMasters : AxiStreamMasterArray(4 downto 0);
   signal rssiIbSlaves  : AxiStreamSlaveArray(4 downto 0);
   signal rssiObMasters : AxiStreamMasterArray(4 downto 0);
   signal rssiObSlaves  : AxiStreamSlaveArray(4 downto 0);

   constant NUM_AXI_MASTERS_C : natural := 2;
   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      0               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000000"),
         addrBits     => 12,
         connectivity => X"FFFF"),
      1               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00001000"),
         addrBits     => 12,
         connectivity => X"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);

   signal tempIbMasters : AxiStreamMasterArray(1 downto 0);
   signal tempIbSlaves  : AxiStreamSlaveArray(1 downto 0);
   signal tempObMasters : AxiStreamMasterArray(1 downto 0);
   signal tempObSlaves  : AxiStreamSlaveArray(1 downto 0);

   signal obRssiTspMasters : AxiStreamMasterArray(1 downto 0);
   signal obRssiTspSlaves  : AxiStreamSlaveArray(1 downto 0);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
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

   ------------------------------
   -- Software's RSSI Server@8193
   ------------------------------
   U_RssiServer : entity surf.RssiCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => ite(ULTRASCALE_PLUS_C,"ultra","block"),
         APP_STREAMS_G       => 5,
         APP_STREAM_ROUTES_G => (
            0                => X"00",  -- TDEST 0 routed to stream 0 (SRPv3)
            1                => X"01",  -- TDEST 1 routed to stream 1 (loopback)
            2                => X"02",  -- TDEST 2 routed to stream 2 (BSA async)
            3                => X"03",  -- TDEST 3 routed to stream 3 (Diag async)
            4                => "11------"),  -- TDEST 0xC0-0xFF routed to stream 2 (Application)
         CLK_FREQUENCY_G     => AXI_CLK_FREQ_C,
         TIMEOUT_UNIT_G      => TIMEOUT_C,
         SERVER_G            => true,
         RETRANSMIT_ENABLE_G => true,
         WINDOW_ADDR_SIZE_G  => WINDOW_ADDR_SIZE_C,
         MAX_NUM_OUTS_SEG_G  => (2**WINDOW_ADDR_SIZE_C),
         PIPE_STAGES_G       => 1,
         APP_AXIS_CONFIG_G   => APP_AXIS_CONFIG_C,
         TSP_AXIS_CONFIG_G   => EMAC_AXIS_CONFIG_C,
         MAX_RETRANS_CNT_G   => MAX_RETRANS_CNT_C,
         MAX_CUM_ACK_CNT_G   => MAX_CUM_ACK_CNT_C)
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
         mTspAxisMaster_o  => obRssiTspMasters(0),
         mTspAxisSlave_i   => obRssiTspSlaves(0),
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

   U_RssiTspObFifo_0 : entity amc_carrier_core.AmcCarrierRssiObFifo
      generic map (
         TPD_G    => TPD_G,
         BYPASS_G => true) -- true to reduce logic footprint
      port map (
         -- Clock and Reset
         axilClk         => axilClk,
         axilRst         => axilRst,
         -- RSSI Interface
         obRssiTspMaster => obRssiTspMasters(0),
         obRssiTspSlave  => obRssiTspSlaves(0),
         -- Interface to UDP Server engine
         ibServerMaster  => ibServerMasters(0),
         ibServerSlave   => ibServerSlaves(0));

   ------------------------------------------------
   -- AXI-Lite Master with RSSI Server: TDEST = 0x0
   ------------------------------------------------
   U_SRPv3 : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         TX_VALID_THOLD_G    => 256,  -- Pre-cache threshold set 256 out of 512 (prevent holding the ETH link during AXI-lite transactions)
         AXI_STREAM_CONFIG_G => AXIS_8BYTE_CONFIG_C)
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

   --------------------------------
   -- Debug Path: TDEST = 0xFF:0xC0
   --------------------------------
   ibAppDebugMaster <= rssiObMasters(4);
   rssiObSlaves(4)  <= ibAppDebugSlave;
   U_IbLimiter : entity surf.SsiFrameLimiter
      generic map (
         TPD_G               => TPD_G,
         EN_TIMEOUT_G        => true,
         MAXIS_CLK_FREQ_G    => AXI_CLK_FREQ_C,
         TIMEOUT_G           => TIMEOUT_C,
         FRAME_LIMIT_G       => (ETH_USR_FRAME_LIMIT_G/8),  -- AXIS_8BYTE_CONFIG_C is 64-bit, FRAME_LIMIT_G is in units of AXIS_8BYTE_CONFIG_C.TDATA_BYTES_C
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => AXIS_8BYTE_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_8BYTE_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => obAppDebugMaster,
         sAxisSlave  => obAppDebugSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => rssiIbMasters(4),
         mAxisSlave  => rssiIbSlaves(4));

   ------------------------------
   -- Software's RSSI Server@8194
   ------------------------------
   U_Temp : entity surf.RssiCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => ite(ULTRASCALE_PLUS_C,"ultra","block"),
         APP_STREAMS_G       => 2,
         APP_STREAM_ROUTES_G => (
            0                => X"04",  -- TDEST 4 routed to stream 0 (MEM)
            1                => "10------"),  -- TDEST x80-0xBF routed to stream 1 (Raw Data)
         CLK_FREQUENCY_G     => AXI_CLK_FREQ_C,
         TIMEOUT_UNIT_G      => TIMEOUT_C,
         SERVER_G            => true,
         RETRANSMIT_ENABLE_G => true,
         WINDOW_ADDR_SIZE_G  => WINDOW_ADDR_SIZE_C,
         MAX_NUM_OUTS_SEG_G  => (2**WINDOW_ADDR_SIZE_C),
         PIPE_STAGES_G       => 1,
         APP_AXIS_CONFIG_G   => TEMP_AXIS_CONFIG_C,
         TSP_AXIS_CONFIG_G   => EMAC_AXIS_CONFIG_C,
         MAX_RETRANS_CNT_G   => MAX_RETRANS_CNT_C,
         MAX_CUM_ACK_CNT_G   => MAX_CUM_ACK_CNT_C)
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
         mTspAxisMaster_o  => obRssiTspMasters(1),
         mTspAxisSlave_i   => obRssiTspSlaves(1),
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

   U_RssiTspObFifo_1 : entity amc_carrier_core.AmcCarrierRssiObFifo
      generic map (
         TPD_G    => TPD_G,
         BYPASS_G => true) -- true to reduce logic footprint
      port map (
         -- Clock and Reset
         axilClk         => axilClk,
         axilRst         => axilRst,
         -- RSSI Interface
         obRssiTspMaster => obRssiTspMasters(1),
         obRssiTspSlave  => obRssiTspSlaves(1),
         -- Interface to UDP Server engine
         ibServerMaster  => ibServerMasters(1),
         ibServerSlave   => ibServerSlaves(1));

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

end mapping;
