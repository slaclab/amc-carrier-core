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
use work.AmcCarrierPkg.all;

entity BsaRawDiagnosticRing is

   generic (
      TPD_G                    : time                  := 1 ns;
      DIAGNOSTIC_RAW_STREAMS_G : positive range 2 to 8 := 4;
      DIAGNOSTIC_RAW_CONFIGS_G : AxiStreamConfigArray  := (0      => ssiAxiStreamConfig(4),
                                                          1       => ssiAxiStreamConfig(4),
                                                          2       => ssiAxiStreamConfig(4),
                                                          3       => ssiAxiStreamConfig(4));
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
      -- Status stream
      axisStatusClk        : in  sl;
      axisStatusRst        : in  sl;
      axisStatusMaster     : out AxiStreamMasterType;
      axisStatusSlave      : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_FORCE_C;
      -- Data autoread output stream
      axisDataClk          : in  sl;
      axisDataRst          : in  sl;
      axisDataMaster       : out AxiStreamMasterType;
      axisDataSlave        : in  AxiStreamSlaveType;
      -- Axi Interface to RAM
      axiClk               : in  sl;
      axiRst               : in  sl;
      axiWriteMaster       : out AxiWriteMasterType := axiWriteMasterInit(AXI_CONFIG_G);
      axiWriteSlave        : in  AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
      axiReadMaster        : out AxiReadMasterType  := axiReadMasterInit(AXI_CONFIG_G);
      axiReadSlave         : in  AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C);



end entity BsaRawDiagnosticRing;

architecture rtl of BsaRawDiagnosticRing is

   constant INTERNAL_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => log2(DIAGNOSTIC_RAW_STREAMS_G),
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 3,
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

   signal bufferDone : slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);

   -- Status streams
   signal axisStatusMasterInt  : AxiStreamMasterType;
   signal axisStatusSlaveInt   : AxiStreamSlaveType;
   signal axisStatusMasterRead : AxiStreamMasterType;
   signal axisStatusSlaveRead  : AxiStreamSlaveType;

   -- Data readout stream
   signal readDmaDataMaster : AxiStreamMasterType;
   signal readDmaDataSlave  : AxiStreamSlaveType;
   signal readDmaDataCtrl   : AxiStreamCtrlType;

   -- Read Dma AxiLite bus
   signal mAxilReadMaster  : AxiLiteReadMasterType;
   signal mAxilReadSlave   : AxiLiteReadSlaveType;
   signal mAxilWriteMaster : AxiLiteWriteMasterType;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilReadMaster  : AxiLiteReadMasterType;
   signal locAxilReadSlave   : AxiLiteReadSlaveType;
   signal locAxilWriteMaster : AxiLiteWriteMasterType;
   signal locAxilWriteSlave  : AxiLiteWriteSlaveType;

begin

   -- Input fifos
   -- These should probably be 4k deep for best throughput
   AXIS_IN_FIFOS : for i in DIAGNOSTIC_RAW_STREAMS_G-1 downto 0 generate
      AxiStreamFifo : entity work.AxiStreamFifo
         generic map (
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 0,
            BRAM_EN_G           => true,
            XIL_DEVICE_G        => "ULTRASCALE",
            USE_BUILT_IN_G      => false,
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 9,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 1,                       --2**(AXIS_FIFO_ADDR_WIDTH_G-1),
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

   -- Maybe add another buffer here

   -------------------------------------------------------------------------------------------------
   -- AxiStreamDma Ring Buffers
   -------------------------------------------------------------------------------------------------
   U_AxiStreamDmaRingWrite_1 : entity work.AxiStreamDmaRingWrite
      generic map (
         TPD_G                => TPD_G,
         BUFFERS_G            => DIAGNOSTIC_RAW_STREAMS_G,
         BURST_SIZE_BYTES_G   => 4096,
         AXIL_BASE_ADDR_G     => AXIL_BASE_ADDR_G,
         DATA_AXIS_CONFIG_G   => INTERNAL_AXIS_CONFIG_C,
         STATUS_AXIS_CONFIG_G => ssiAxiStreamConfig(1, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8), -- Shoud this be 4 tDest bits?
         AXI_WRITE_CONFIG_G   => AXI_CONFIG_G)
      port map (
         axilClk          => axilClk,              -- [in]
         axilRst          => axilRst,              -- [in]
         axilReadMaster   => locAxilReadMaster,    -- [in]
         axilReadSlave    => locAxilReadSlave,     -- [out]
         axilWriteMaster  => locAxilWriteMaster,   -- [in]
         axilWriteSlave   => locAxilWriteSlave,    -- [out]
         axisStatusClk    => axisStatusClk,        -- [in]
         axisStatusRst    => axisStatusRst,        -- [in]
         axisStatusMaster => axisStatusMasterInt,  -- [out]
         axisStatusSlave  => axisStatusSlaveInt,   -- [in]
         axiClk           => axiClk,               -- [in]
         axiRst           => axiRst,               -- [in]
         bufferDone       => bufferDone,           -- [out]
         axisDataMaster   => muxOutAxisMaster,     -- [in]
         axisDataSlave    => muxOutAxisSlave,      -- [out]
         axiWriteMaster   => axiWriteMaster,       -- [out]
         axiWriteSlave    => axiWriteSlave);       -- [in]

   -- Synchronize bufferDone back to raw clocks and use as ctrl.pause
   BUFFER_DONE_PAUSE : for i in DIAGNOSTIC_RAW_STREAMS_G-1 downto 0 generate
      U_Synchronizer_1 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => diagnosticRawClks(i),         -- [in]
            rst     => diagnosticRawRsts(i),         -- [in]
            dataIn  => bufferDone(i),                -- [in]
            dataOut => diagnosticRawCtrl(i).pause);  -- [out]
      diagnosticRawCtrl(i).overflow <= '0';
      diagnosticRawCtrl(i).idle     <= '0';
   end generate BUFFER_DONE_PAUSE;

   -------------------------------------------------------------------------------------------------
   -- Route status message based on tdest
   -------------------------------------------------------------------------------------------------
   U_AxiStreamDeMux_1 : entity work.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 2)
      port map (
         axisClk         => axisStatusClk,         -- [in]
         axisRst         => axisStatusRst,         -- [in]
         sAxisMaster     => axisStatusMasterInt,   -- [in]
         sAxisSlave      => axisStatusSlaveInt,    -- [out]
         mAxisMasters(0) => axisStatusMaster,      -- [out]
         mAxisMasters(1) => axisStatusMasterRead,  -- [out]         
         mAxisSlaves(0)  => axisStatusSlave,       -- [in]
         mAxisSlaves(1)  => axisStatusSlaveRead);  -- [in]         

   -------------------------------------------------------------------------------------------------
   -- AxiStreamDmaRingRead module optionally catches status messages from ring write
   -- Peforms the read itself and outputs the resulting data stream
   -------------------------------------------------------------------------------------------------
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
         axilClk         => axilClk,               -- [in]
         axilRst         => axilRst,               -- [in]
         axilReadMaster  => mAxilReadMaster,       -- [out]
         axilReadSlave   => mAxilReadSlave,        -- [in]
         axilWriteMaster => mAxilWriteMaster,      -- [out]
         axilWriteSlave  => mAxilWriteSlave,       -- [in]
         statusClk       => axisStatusClk,         -- [in]
         statusRst       => axisStatusRst,         -- [in]
         statusMaster    => axisStatusMasterRead,  -- [out]
         statusSlave     => axisStatusSlaveRead,   -- [in]
         dataMaster      => readDmaDataMaster,     -- [out]
         dataSlave       => readDmaDataSlave,      -- [in]
         dataCtrl        => readDmaDataCtrl,       -- [in]
         axiClk          => axiClk,                -- [in]
         axiRst          => axiRst,                -- [in]
         axiReadMaster   => axiReadMaster,         -- [out]
         axiReadSlave    => axiReadSlave);         -- [in]

   -------------------------------------------------------------------------------------------------
   -- Buffer the read dma data to transition to data clk and use CTRL for flow control with DmaRead
   -------------------------------------------------------------------------------------------------
   AxiStreamFifo_RD_DATA : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => true,
         XIL_DEVICE_G        => "ULTRASCALE",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 10,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**10-256,
         SLAVE_AXI_CONFIG_G  => INTERNAL_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => ETH_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => readDmaDataMaster,
         sAxisSlave  => readDmaDataSlave,
         sAxisCtrl   => readDmaDataCtrl,
         mAxisClk    => axisDataClk,
         mAxisRst    => axisDataRst,
         mAxisMaster => axisDataMaster,
         mAxisSlave  => axisDataSlave);

   -------------------------------------------------------------------------------------------------
   -- AxiLite crossbar to allow AxiStreamDmaRingRead to access AxiStreamDmaRingWrite registers
   -------------------------------------------------------------------------------------------------
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


end architecture rtl;
