-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaRawDiagnostic.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
--              Uros Legat <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-12
-- Last update: 2016-03-09
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
use work.AxiPkg.all;
use work.SsiPkg.all;

entity DebugRawDiagnostic is

   generic (
      TPD_G                    : time                  := 1 ns;
      DIAGNOSTIC_RAW_STREAMS_G : positive range 1 to 8 := 1;
      DIAGNOSTIC_RAW_CONFIGS_G : AxiStreamConfigArray  := (0      => ssiAxiStreamConfig(4));
      AXIL_BASE_ADDR_G         : slv(31 downto 0)      := (others => '0');
      AXIL_AXI_ASYNC_G         : boolean               := true;
      AXI_CONFIG_G             : AxiConfigType         := axiConfig(33, 16, 1, 8)
      );
   port (
      -- Diagnostic data interface
      diagnosticRawClks    : in  slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawRsts    : in  slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawMasters : in  AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawSlaves  : out AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawCtrl    : out AxiStreamCtrlArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      -- AXI-Lite configuration interface
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType;
      -- Output Stream
      dataClk              : in  sl;
      dataRst              : in  sl;
      dataMaster           : out AxiStreamMasterType;
      dataSlave            : in  AxiStreamSlaveType;
      -- Axi Interface to RAM
      axiClk               : in  sl;
      axiRst               : in  sl;
      axiWriteMaster       : out AxiWriteMasterType := axiWriteMasterInit(AXI_CONFIG_G);
      axiWriteSlave        : in  AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
      axiReadMaster        : out AxiReadMasterType  := axiReadMasterInit(AXI_CONFIG_G);
      axiReadSlave         : in  AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C);



end entity DebugRawDiagnostic;

architecture rtl of DebugRawDiagnostic is

   constant INTERNAL_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => bitSize(DIAGNOSTIC_RAW_STREAMS_G),
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 1,
      TUSER_MODE_C  => TUSER_LAST_C);

   constant INTERNAL_AXIS_MASTER_INIT_C : AxiStreamMasterType := axiStreamMasterInit(INTERNAL_AXIS_CONFIG_C);

   -- Mux in 
   signal muxInAxisMaster : AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0) :=
      (others => INTERNAL_AXIS_MASTER_INIT_C);
   signal muxInAxisSlave : AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0) :=
      (others => AXI_STREAM_SLAVE_INIT_C);

   -- Mux out    
   signal muxOutAxisMaster : AxiStreamMasterType := INTERNAL_AXIS_MASTER_INIT_C;
   signal muxOutAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   constant STATUS_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 8,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 1,
      TUSER_MODE_C  => TUSER_NONE_C);

   -- Status stream
   signal axisStatusMaster : AxiStreamMasterType;
   signal axisStatusSlave  : AxiStreamSlaveType;

   -- Output data stream
   signal dmaDataMaster  : AxiStreamMasterType;
   signal dmaDataSlave   : AxiStreamSlaveType;
   signal dmaDataCtrl    : AxiStreamCtrlType;
   signal fifoDataMaster : AxiStreamMasterType;
   signal fifoDataSlave  : AxiStreamSlaveType;

   signal mAxilReadMaster  : AxiLiteReadMasterType;
   signal mAxilReadSlave   : AxiLiteReadSlaveType;
   signal mAxilWriteMaster : AxiLiteWriteMasterType;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilReadMaster  : AxiLiteReadMasterType;
   signal locAxilReadSlave   : AxiLiteReadSlaveType;
   signal locAxilWriteMaster : AxiLiteWriteMasterType;
   signal locAxilWriteSlave  : AxiLiteWriteSlaveType;
begin

   diagnosticRawCtrl <= (others => AXI_STREAM_CTRL_INIT_C);

   -- Input fifos
   -- These should probably be 4k deep for best throughput
   AXIS_IN_FIFOS : for i in DIAGNOSTIC_RAW_STREAMS_G-1 downto 0 generate
      AxiStreamFifo : entity work.AxiStreamFifo
         generic map (
            TPD_G => TPD_G,

            SLAVE_READY_EN_G => true,
            VALID_THOLD_G    => 0,
            BRAM_EN_G        => true,
            XIL_DEVICE_G     => "ULTRASCALE",

            USE_BUILT_IN_G      => false,
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 9,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 1,   --2**(AXIS_FIFO_ADDR_WIDTH_G-1),

            SLAVE_AXI_CONFIG_G  => DIAGNOSTIC_RAW_CONFIGS_G(i),
            MASTER_AXI_CONFIG_G => INTERNAL_AXIS_CONFIG_C)  -- 128-bit
         port map (
            sAxisClk    => diagnosticRawClks(i),
            sAxisRst    => diagnosticRawRsts(i),
            sAxisMaster => diagnosticRawMasters(i),
            sAxisSlave  => diagnosticRawSlaves(i),
            sAxisCtrl   => open,
            mAxisClk    => axiClk,
            mAxisRst    => axiRst,
            mAxisMaster => muxInAxisMaster(i),
            mAxisSlave  => muxInAxisSlave(i));
   end generate AXIS_IN_FIFOS;

   -- Mux of two streams
   AxiStreamMux_INST : entity work.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => DIAGNOSTIC_RAW_STREAMS_G,
         PIPE_STAGES_G => 1,
         TDEST_HIGH_G  => 7,
         TDEST_LOW_G   => 0,
         KEEP_TDEST_G  => false)
      port map (
         sAxisMasters => muxInAxisMaster,
         sAxisSlaves  => muxInAxisSlave,
         mAxisMaster  => muxOutAxisMaster,
         mAxisSlave   => muxOutAxisSlave,
         axisClk      => axiClk,
         axisRst      => axiRst);

   U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => 1,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         MASTERS_CONFIG_G   => genAxiLiteConfig(1, AXIL_BASE_ADDR_G, 16, 12),
         DEBUG_G            => true)
      port map (
         axiClk              => axilClk,             -- [in]
         axiClkRst           => axilRst,             -- [in]
         sAxiWriteMasters(0) => axilWriteMaster,     -- [in]
         sAxiWriteMasters(1) => mAxilWriteMaster,    -- [in]
         sAxiWriteSlaves(0)  => axilWriteSlave,      -- [out]
         sAxiWriteSlaves(1)  => mAxilWriteSlave,     -- [out]
         sAxiReadMasters(0)  => axilReadMaster,      -- [in]
         sAxiReadMasters(1)  => mAxilReadMaster,     -- [in]
         sAxiReadSlaves(0)   => axilReadSlave,       -- [out]
         sAxiReadSlaves(1)   => mAxilReadSlave,      -- [out]
         mAxiWriteMasters(0) => locAxilWriteMaster,  -- [out]
         mAxiWriteSlaves(0)  => locAxilWriteSlave,   -- [in]
         mAxiReadMasters(0)  => locAxilReadMaster,   -- [out]
         mAxiReadSlaves(0)   => locAxilReadSlave);   -- [in]

   -------------------------------------------------------------------------------------------------
   -- AxiStreamDma Ring Buffers
   -------------------------------------------------------------------------------------------------
   U_AxiStreamDmaRingWrite_1 : entity work.AxiStreamDmaRingWrite
      generic map (
         TPD_G                      => TPD_G,
         BUFFERS_G                  => DIAGNOSTIC_RAW_STREAMS_G,
         BURST_SIZE_BYTES_G         => 4096,
         AXIL_AXI_ASYNC_G           => AXIL_AXI_ASYNC_G,
         AXIL_BASE_ADDR_G           => AXIL_BASE_ADDR_G,
         DATA_AXI_STREAM_CONFIG_G   => INTERNAL_AXIS_CONFIG_C,
         STATUS_AXI_STREAM_CONFIG_G => ssiAxiStreamConfig(8),
         AXI_WRITE_CONFIG_G         => AXI_CONFIG_G)
      port map (
         axilClk          => axilClk,             -- [in]
         axilRst          => axilRst,             -- [in]
         axilReadMaster   => locAxilReadMaster,   -- [in]
         axilReadSlave    => locAxilReadSlave,    -- [out]
         axilWriteMaster  => locAxilWriteMaster,  -- [in]
         axilWriteSlave   => locAxilWriteSlave,   -- [out]
         axisStatusClk    => axilClk,
         axisStatusRst    => axilRst,
         axisStatusMaster => axisStatusMaster,
         axisStatusSlave  => axisStatusSlave,
         axiClk           => axiClk,              -- [in]
         axiRst           => axiRst,              -- [in]
         axisDataMaster   => muxOutAxisMaster,    -- [in]
         axisDataSlave    => muxOutAxisSlave,     -- [out]
         axiWriteMaster   => axiWriteMaster,      -- [out]
         axiWriteSlave    => axiWriteSlave);      -- [in]

   U_AxiStreamDmaRingRead_1 : entity work.AxiStreamDmaRingRead
      generic map (
         TPD_G                 => TPD_G,
         BUFFERS_G             => DIAGNOSTIC_RAW_STREAMS_G,
         SSI_OUTPUT_G          => true,
         AXIL_BASE_ADDR_G      => AXIL_BASE_ADDR_G,
         AXI_STREAM_READY_EN_G => false,
         AXI_STREAM_CONFIG_G   => INTERNAL_AXIS_CONFIG_C,
         AXI_READ_CONFIG_G     => AXI_CONFIG_G)
      port map (
         axilClk         => axilClk,           -- [in]
         axilRst         => axilRst,           -- [in]
         axilReadMaster  => mAxilReadMaster,   -- [out]
         axilReadSlave   => mAxilReadSlave,    -- [in]
         axilWriteMaster => mAxilWriteMaster,  -- [out]
         axilWriteSlave  => mAxilWriteSlave,   -- [in]
         statusClk       => axilClk,           -- [in]
         statusRst       => axilRst,           -- [in]
         statusMaster    => axisStatusMaster,  -- [out]
         statusSlave     => axisStatusSlave,   -- [in]
         dataMaster      => dmaDataMaster,     -- [out]
         dataSlave       => dmaDataSlave,      -- [in]
         dataCtrl        => dmaDataCtrl,       -- [in]
         axiClk          => axiClk,            -- [in]
         axiRst          => axiRst,            -- [in]
         axiReadMaster   => axiReadMaster,     -- [out]
         axiReadSlave    => axiReadSlave);     -- [in]



   AxiStreamFifo_DATA : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => true,
         XIL_DEVICE_G        => "ULTRASCALE",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 12,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**12-32,
         SLAVE_AXI_CONFIG_G  => INTERNAL_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(2))
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => dmaDataMaster,
         sAxisSlave  => dmaDataSlave,
         sAxisCtrl   => dmaDataCtrl,
         mAxisClk    => dataClk,
         mAxisRst    => dataRst,
         mAxisMaster => fifoDataMaster,
         mAxisSlave  => fifoDataSlave);

   -- Need to add packetizer
   U_AxiStreamPacketizer_1 : entity work.AxiStreamPacketizer
      generic map (
         TPD_G                => TPD_G,
         MAX_PACKET_BYTES_G   => 4096,
         INPUT_PIPE_STAGES_G  => 0,
         OUTPUT_PIPE_STAGES_G => 1)
      port map (
         axisClk     => dataClk,         -- [in]
         axisRst     => dataRst,         -- [in]
         sAxisMaster => fifoDataMaster,  -- [in]
         sAxisSlave  => fifoDataSlave,   -- [out]
         mAxisMaster => dataMaster,      -- [out]
         mAxisSlave  => dataSlave);      -- [in]


end architecture rtl;
