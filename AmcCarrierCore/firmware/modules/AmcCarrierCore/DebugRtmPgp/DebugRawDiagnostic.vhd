-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaRawDiagnostic.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
--              Uros Legat <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-12
-- Last update: 2016-04-29
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

   constant WRITE_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => bitSize(DIAGNOSTIC_RAW_STREAMS_G),
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 1,
      TUSER_MODE_C  => TUSER_LAST_C);

   constant READ_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(AXI_CONFIG_G.DATA_BYTES_C);

   constant WRITE_AXIS_MASTER_INIT_C : AxiStreamMasterType := axiStreamMasterInit(WRITE_AXIS_CONFIG_C);

   -- Mux in 
   signal writeMuxInAxisMaster : AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0) :=
      (others => WRITE_AXIS_MASTER_INIT_C);
   signal writeMuxInAxisSlave : AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0) :=
      (others => AXI_STREAM_SLAVE_INIT_C);

   -- Mux out    
   signal writeMuxOutAxisMaster : AxiStreamMasterType := WRITE_AXIS_MASTER_INIT_C;
   signal writeMuxOutAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal writeMuxFifoAxisMaster : AxiStreamMasterType := WRITE_AXIS_MASTER_INIT_C;
   signal writeMuxFifoAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;


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
   signal readDmaDataMaster        : AxiStreamMasterType;
   signal readDmaDataSlave         : AxiStreamSlaveType;
   signal readDmaDataCtrl          : AxiStreamCtrlType;
   signal readFifoDataMaster       : AxiStreamMasterType;
   signal readFifoDataSlave        : AxiStreamSlaveType;
   signal readPacketizerDataMaster : AxiStreamMasterType;
   signal readPacketizerDataSlave  : AxiStreamSlaveType;

   signal mAxilReadMaster  : AxiLiteReadMasterType;
   signal mAxilReadSlave   : AxiLiteReadSlaveType;
   signal mAxilWriteMaster : AxiLiteWriteMasterType;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilReadMaster  : AxiLiteReadMasterType;
   signal locAxilReadSlave   : AxiLiteReadSlaveType;
   signal locAxilWriteMaster : AxiLiteWriteMasterType;
   signal locAxilWriteSlave  : AxiLiteWriteSlaveType;

   -- AXI
   signal locAxiWriteMasters : AxiWriteMasterArray(2 downto 0) := (others => AXI_WRITE_MASTER_INIT_C);
   signal locAxiWriteSlaves  : AxiWriteSlaveArray(2 downto 0)  := (others => AXI_WRITE_SLAVE_INIT_C);
   signal locAxiReadMasters  : AxiReadMasterArray(2 downto 0)  := (others => AXI_READ_MASTER_INIT_C);
   signal locAxiReadSlaves   : AxiReadSlaveArray(2 downto 0)   := (others => AXI_READ_SLAVE_INIT_C);

begin


   diagnosticRawCtrl <= (others => AXI_STREAM_CTRL_UNUSED_C);

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
            MASTER_AXI_CONFIG_G => WRITE_AXIS_CONFIG_C)  -- 128-bit
         port map (
            sAxisClk    => diagnosticRawClks(i),
            sAxisRst    => diagnosticRawRsts(i),
            sAxisMaster => diagnosticRawMasters(i),
            sAxisSlave  => diagnosticRawSlaves(i),
            sAxisCtrl   => open,
            mAxisClk    => axiClk,
            mAxisRst    => axiRst,
            mAxisMaster => writeMuxInAxisMaster(i),
            mAxisSlave  => writeMuxInAxisSlave(i));
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
         sAxisMasters => writeMuxInAxisMaster,
         sAxisSlaves  => writeMuxInAxisSlave,
         mAxisMaster  => writeMuxOutAxisMaster,
         mAxisSlave   => writeMuxOutAxisSlave,
         axisClk      => axiClk,
         axisRst      => axiRst);

   AxiStreamFifo_MUX_FIFO : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => true,
         XIL_DEVICE_G        => "ULTRASCALE",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**9-32,
         SLAVE_AXI_CONFIG_G  => WRITE_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => WRITE_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => writeMuxOutAxisMaster,
         sAxisSlave  => writeMuxOutAxisSlave,
         mAxisClk    => axiClk,
         mAxisRst    => axiRst,
         mAxisMaster => writeMuxFifoAxisMaster,
         mAxisSlave  => writeMuxFifoAxisSlave);

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
         TPD_G                => TPD_G,
         BUFFERS_G            => DIAGNOSTIC_RAW_STREAMS_G,
         BURST_SIZE_BYTES_G   => 4096,
         AXIL_BASE_ADDR_G     => AXIL_BASE_ADDR_G,
         DATA_AXIS_CONFIG_G   => WRITE_AXIS_CONFIG_C,
         STATUS_AXIS_CONFIG_G => ssiAxiStreamConfig(1),
         AXI_WRITE_CONFIG_G   => AXI_CONFIG_G)
      port map (
         axilClk          => axilClk,                 -- [in]
         axilRst          => axilRst,                 -- [in]
         axilReadMaster   => locAxilReadMaster,       -- [in]
         axilReadSlave    => locAxilReadSlave,        -- [out]
         axilWriteMaster  => locAxilWriteMaster,      -- [in]
         axilWriteSlave   => locAxilWriteSlave,       -- [out]
         axisStatusClk    => axiClk,
         axisStatusRst    => axiRst,
         axisStatusMaster => axisStatusMaster,
         axisStatusSlave  => axisStatusSlave,
         axiClk           => axiClk,                  -- [in]
         axiRst           => axiRst,                  -- [in]
         axisDataMaster   => writeMuxFifoAxisMaster,  -- [in]
         axisDataSlave    => writeMuxFifoAxisSlave,   -- [out]
         axiWriteMaster   => locAxiWriteMasters(2),   -- [out]
         axiWriteSlave    => locAxiWriteSlaves(2));   -- [in]

   U_AxiStreamDmaRingRead_1 : entity work.AxiStreamDmaRingRead
      generic map (
         TPD_G                 => TPD_G,
         BUFFERS_G             => DIAGNOSTIC_RAW_STREAMS_G,
         SSI_OUTPUT_G          => true,
         AXIL_BASE_ADDR_G      => AXIL_BASE_ADDR_G,
         AXI_STREAM_READY_EN_G => false,
         AXI_STREAM_CONFIG_G   => READ_AXIS_CONFIG_C,
         AXI_READ_CONFIG_G     => AXI_CONFIG_G)
      port map (
         axilClk         => axilClk,               -- [in]
         axilRst         => axilRst,               -- [in]
         axilReadMaster  => mAxilReadMaster,       -- [out]
         axilReadSlave   => mAxilReadSlave,        -- [in]
         axilWriteMaster => mAxilWriteMaster,      -- [out]
         axilWriteSlave  => mAxilWriteSlave,       -- [in]
         statusClk       => axiClk,                -- [in]
         statusRst       => axiRst,                -- [in]
         statusMaster    => axisStatusMaster,      -- [out]
         statusSlave     => axisStatusSlave,       -- [in]
         dataMaster      => readDmaDataMaster,     -- [out]
         dataSlave       => readDmaDataSlave,      -- [in]
         dataCtrl        => readDmaDataCtrl,       -- [in]
         axiClk          => axiClk,                -- [in]
         axiRst          => axiRst,                -- [in]
         axiReadMaster   => locAxiReadMasters(0),  -- [out]
         axiReadSlave    => locAxiReadSlaves(0));  -- [in]



   AxiStreamFifo_128_64 : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => true,
         XIL_DEVICE_G        => "ULTRASCALE",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 12,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**12-256,
         SLAVE_AXI_CONFIG_G  => READ_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(8))
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => readDmaDataMaster,
         sAxisSlave  => readDmaDataSlave,
         sAxisCtrl   => readDmaDataCtrl,
         mAxisClk    => dataClk,
         mAxisRst    => dataRst,
         mAxisMaster => readFifoDataMaster,
         mAxisSlave  => readFifoDataSlave);


   U_AxiStreamPacketizer_1 : entity work.AxiStreamPacketizer
      generic map (
         TPD_G                => TPD_G,
         MAX_PACKET_BYTES_G   => 4112,
         MIN_TKEEP_G          => X"000F",
         INPUT_PIPE_STAGES_G  => 0,
         OUTPUT_PIPE_STAGES_G => 1)
      port map (
         axisClk     => dataClk,                   -- [in]
         axisRst     => dataRst,                   -- [in]
         sAxisMaster => readFifoDataMaster,        -- [in]
         sAxisSlave  => readFifoDataSlave,         -- [out]
         mAxisMaster => readPacketizerDataMaster,  -- [out]
         mAxisSlave  => readPacketizerDataSlave);  -- [in]

   -- Need another fifo after packetizer to convert to pgp width
   AxiStreamFifo_64_16 : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => true,
         XIL_DEVICE_G        => "ULTRASCALE",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**9-1,
         SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(8),
         MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(2))
      port map (
         sAxisClk    => dataClk,
         sAxisRst    => dataRst,
         sAxisMaster => readPacketizerDataMaster,
         sAxisSlave  => readPacketizerDataSlave,
         mAxisClk    => dataClk,
         mAxisRst    => dataRst,
         mAxisMaster => dataMaster,
         mAxisSlave  => dataSlave);

   U_BsaAxiInterconnectWrapper_1 : entity work.BsaAxiInterconnectWrapper
      port map (
         axiClk           => axiClk,              -- [in]
         axiRst           => axiRst,              -- [in]
         sAxiWriteMasters => locAxiWriteMasters,  -- [in]
         sAxiWriteSlaves  => locAxiWriteSlaves,   -- [out]
         sAxiReadMasters  => locAxiReadMasters,   -- [in]
         sAxiReadSlaves   => locAxiReadSlaves,    -- [out]
         mAxiWriteMasters => axiWriteMaster,      -- [out]
         mAxiWriteSlaves  => axiWriteSlave,       -- [in]
         mAxiReadMasters  => axiReadMaster,       -- [out]
         mAxiReadSlaves   => axiReadSlave);       -- [in]
end architecture rtl;
