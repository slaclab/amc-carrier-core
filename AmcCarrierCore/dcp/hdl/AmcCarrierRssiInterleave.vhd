-------------------------------------------------------------------------------
-- File       : AmcCarrierRssiInterleave.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-02-09
-- Last update: 2018-02-09
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

entity AmcCarrierRssiInterleave is
   generic (
      TPD_G                 : time             := 1 ns;
      ETH_USR_FRAME_LIMIT_G : positive         := 4096;  -- 4kB
      AXI_ERROR_RESP_G      : slv(1 downto 0)  := AXI_RESP_DECERR_C;
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
      obServerMaster   : in  AxiStreamMasterType;
      obServerSlave    : out AxiStreamSlaveType;
      ibServerMaster   : out AxiStreamMasterType;
      ibServerSlave    : in  AxiStreamSlaveType);
end AmcCarrierRssiInterleave;

architecture mapping of AmcCarrierRssiInterleave is

   constant APP_STREAMS_C      : positive := 6;
   constant TIMEOUT_C          : real     := 1.0E-3;  -- In units of seconds   
   constant WINDOW_ADDR_SIZE_C : positive := 3;
   constant MAX_CUM_ACK_CNT_C  : positive := WINDOW_ADDR_SIZE_C;
   constant MAX_RETRANS_CNT_C  : positive := ite((WINDOW_ADDR_SIZE_C > 1), WINDOW_ADDR_SIZE_C-1, 1);

   constant APP_AXIS_CONFIG_C : AxiStreamConfigArray(APP_STREAMS_C-1 downto 0) := (others => ETH_AXIS_CONFIG_C);

   constant SRP_IDX_C        : natural := 0;
   constant BSA_ASYNC_IDX_C  : natural := 1;
   constant DIAG_ASYNC_IDX_C : natural := 2;
   constant MEM_DATA_IDX_C   : natural := 3;
   constant RAW_DATA_IDX_C   : natural := 4;
   constant APP_ASYNC_IDX_C  : natural := 5;

   signal rssiIbMasters : AxiStreamMasterArray(APP_STREAMS_C-1 downto 0);
   signal rssiIbSlaves  : AxiStreamSlaveArray(APP_STREAMS_C-1 downto 0);
   signal rssiObMasters : AxiStreamMasterArray(APP_STREAMS_C-1 downto 0);
   signal rssiObSlaves  : AxiStreamSlaveArray(APP_STREAMS_C-1 downto 0);

begin

   -------------------------
   -- Software's RSSI Server
   -------------------------
   U_RssiServer : entity work.RssiCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         APP_ILEAVE_EN_G     => true,    -- true = AxiStreamPacketizer2
         APP_STREAMS_G       => APP_STREAMS_C,
         APP_STREAM_ROUTES_G => (
            SRP_IDX_C        => X"00",  -- TDEST 0 routed to stream 0 (SRPv3)
            BSA_ASYNC_IDX_C  => X"02",  -- TDEST 2 routed to stream 2 (BSA async)
            DIAG_ASYNC_IDX_C => X"03",  -- TDEST 3 routed to stream 3 (Diag async)
            MEM_DATA_IDX_C   => X"04",  -- TDEST 4 routed to stream 0 (MEM)
            RAW_DATA_IDX_C   => "10------",  -- TDEST x80-0xBF routed to stream 1 (Raw Data)            
            APP_ASYNC_IDX_C  => "11------"),  -- TDEST 0xC0-0xFF routed to stream 2 (Application)   
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
         sTspAxisMaster_i  => obServerMaster,
         sTspAxisSlave_o   => obServerSlave,
         mTspAxisMaster_o  => ibServerMaster,
         mTspAxisSlave_i   => ibServerSlave,
         -- High level  Application side interface
         openRq_i          => '1',  -- Automatically start the connection without debug SRP channel
         closeRq_i         => '0',
         inject_i          => '0',
         -- AXI-Lite Interface
         axiClk_i          => axilClk,
         axiRst_i          => axilRst,
         axilReadMaster    => axilReadMaster,
         axilReadSlave     => axilReadSlave,
         axilWriteMaster   => axilWriteMaster,
         axilWriteSlave    => axilWriteSlave);

   ------------------------------------------------
   -- AXI-Lite Master with RSSI Server: TDEST = 0x0
   ------------------------------------------------
   U_SRPv3 : entity work.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         TX_VALID_THOLD_G    => 256,  -- Pre-cache threshold set 256 out of 512 (prevent holding the ETH link during AXI-lite transactions)
         AXI_STREAM_CONFIG_G => ETH_AXIS_CONFIG_C)
      port map (
         -- AXIS Slave Interface (sAxisClk domain)
         sAxisClk         => axilClk,
         sAxisRst         => axilRst,
         sAxisMaster      => rssiObMasters(SRP_IDX_C),
         sAxisSlave       => rssiObSlaves(SRP_IDX_C),
         -- AXIS Master Interface (mAxisClk domain) 
         mAxisClk         => axilClk,
         mAxisRst         => axilRst,
         mAxisMaster      => rssiIbMasters(SRP_IDX_C),
         mAxisSlave       => rssiIbSlaves(SRP_IDX_C),
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave);

   ----------------------------------
   -- BSA ASYNC Messages: TDEST = 0x2
   ----------------------------------
   ibBsaMasters(1)                <= rssiObMasters(BSA_ASYNC_IDX_C);
   rssiObSlaves(BSA_ASYNC_IDX_C)  <= ibBsaSlaves(1);
   rssiIbMasters(BSA_ASYNC_IDX_C) <= obBsaMasters(1);
   obBsaSlaves(1)                 <= rssiIbSlaves(BSA_ASYNC_IDX_C);

   -----------------------------------------
   -- Diagnostic ASYNC Messages: TDEST = 0x3
   -----------------------------------------
   ibBsaMasters(2)                 <= rssiObMasters(DIAG_ASYNC_IDX_C);
   rssiObSlaves(DIAG_ASYNC_IDX_C)  <= ibBsaSlaves(2);
   rssiIbMasters(DIAG_ASYNC_IDX_C) <= obBsaMasters(2);
   obBsaSlaves(2)                  <= rssiIbSlaves(DIAG_ASYNC_IDX_C);

   -----------------------------
   -- Memory Access: TDEST = 0x4
   -----------------------------
   ibBsaMasters(0)               <= rssiObMasters(MEM_DATA_IDX_C);
   rssiObSlaves(MEM_DATA_IDX_C)  <= ibBsaSlaves(0);
   rssiIbMasters(MEM_DATA_IDX_C) <= obBsaMasters(0);
   obBsaSlaves(0)                <= rssiIbSlaves(MEM_DATA_IDX_C);

   -----------------------------------
   -- Raw Data Path: TDEST = 0xBF:0x80
   -----------------------------------
   ibBsaMasters(3)               <= rssiObMasters(RAW_DATA_IDX_C);
   rssiObSlaves(RAW_DATA_IDX_C)  <= ibBsaSlaves(3);
   rssiIbMasters(RAW_DATA_IDX_C) <= obBsaMasters(3);
   obBsaSlaves(3)                <= rssiIbSlaves(RAW_DATA_IDX_C);

   --------------------------------
   -- Debug Path: TDEST = 0xFF:0xC0
   --------------------------------
   ibAppDebugMaster              <= rssiObMasters(APP_ASYNC_IDX_C);
   rssiObSlaves(APP_ASYNC_IDX_C) <= ibAppDebugSlave;
   U_IbLimiter : entity work.SsiFrameLimiter
      generic map (
         TPD_G               => TPD_G,
         EN_TIMEOUT_G        => true,
         MAXIS_CLK_FREQ_G    => AXI_CLK_FREQ_C,
         TIMEOUT_G           => TIMEOUT_C,
         FRAME_LIMIT_G       => (ETH_USR_FRAME_LIMIT_G/8),  -- ETH_AXIS_CONFIG_C is 64-bit, FRAME_LIMIT_G is in units of ETH_AXIS_CONFIG_C.TDATA_BYTES_C
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => ETH_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => ETH_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => obAppDebugMaster,
         sAxisSlave  => obAppDebugSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => rssiIbMasters(APP_ASYNC_IDX_C),
         mAxisSlave  => rssiIbSlaves(APP_ASYNC_IDX_C));

end mapping;
