-------------------------------------------------------------------------------
-- File       : BsaWaveformEngine.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-12
-- Last update: 2016-08-30
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
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;

entity BsaWaveformEngine is

   generic (
      TPD_G                  : time                   := 1 ns;
      WAVEFORM_NUM_LANES_G   : positive range 1 to 4  := 4;
      WAVEFORM_TDATA_BYTES_G : positive range 4 to 16 := 4;
      AXIL_BASE_ADDR_G       : slv(31 downto 0)       := (others => '0');
      AXI_CONFIG_G           : AxiConfigType          := axiConfig(33, 16, 1, 8));
   port (
      -- Diagnostic data interface
      waveformClk : in sl;
      waveformRst : in sl;
      ibWaveformMasters : in  WaveformMasterType;
      ibWaveformSlaves  : out WaveformSlaveType := (others=>WAVEFORM_SLAVE_REC_FORCE_C);
      -- AXI-Lite configuration interface
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- Status stream
      axisStatusClk     : in  sl;
      axisStatusRst     : in  sl;
      axisStatusMaster  : out AxiStreamMasterType;
      axisStatusSlave   : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_FORCE_C;
      -- Data autoread output stream
      axisDataClk       : in  sl;
      axisDataRst       : in  sl;
      axisDataMaster    : out AxiStreamMasterType;
      axisDataSlave     : in  AxiStreamSlaveType;
      -- Axi Interface to RAM
      axiClk            : in  sl;
      axiRst            : in  sl;
      axiWriteMaster    : out AxiWriteMasterType := axiWriteMasterInit(AXI_CONFIG_G);
      axiWriteSlave     : in  AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
      axiReadMaster     : out AxiReadMasterType  := axiReadMasterInit(AXI_CONFIG_G);
      axiReadSlave      : in  AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C);



end entity BsaWaveformEngine;

architecture rtl of BsaWaveformEngine is

   constant WAVEFORM_AXIS_CONFIG_C : AxiStreamConfigType :=
      ssiAxiStreamConfig(WAVEFORM_TDATA_BYTES_G, TKEEP_FIXED_C, TUSER_FIRST_LAST_C, 0, 3);  -- No tdest bits, 3 tUser bits

   -- constant STREAMS_C : positive := WaveformMasterType'length;
   constant STREAMS_C : positive := WAVEFORM_NUM_LANES_G;

   constant TDEST_ROUTES_C : Slv8Array(STREAMS_C-1 downto 0) := (others => "--------");

   -------------------------------------------------------------------------------------------------
   -- Write side constants and signals
   -------------------------------------------------------------------------------------------------
   constant WRITE_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => bitSize(STREAMS_C-1),
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 3,
      TUSER_MODE_C  => TUSER_LAST_C);

   constant WRITE_AXIS_MASTER_INIT_C : AxiStreamMasterType := axiStreamMasterInit(WRITE_AXIS_CONFIG_C);

   -- Mux in 
   signal muxInAxisMaster : AxiStreamMasterArray(STREAMS_C-1 downto 0) :=
      (others => WRITE_AXIS_MASTER_INIT_C);
   signal muxInAxisSlave : AxiStreamSlaveArray(STREAMS_C-1 downto 0) :=
      (others => AXI_STREAM_SLAVE_INIT_C);

   -- Mux out    
   signal muxOutAxisMaster : AxiStreamMasterType := WRITE_AXIS_MASTER_INIT_C;
   signal muxOutAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- Mux Fifo
   signal muxFifoAxisMaster : AxiStreamMasterType := WRITE_AXIS_MASTER_INIT_C;
   signal muxFifoAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal bufferDone : slv(STREAMS_C-1 downto 0);

   -- Status streams
   signal axisStatusMasterInt  : AxiStreamMasterType;
   signal axisStatusSlaveInt   : AxiStreamSlaveType;
   signal axisStatusMasterRead : AxiStreamMasterType;
   signal axisStatusSlaveRead  : AxiStreamSlaveType;

   -------------------------------------------------------------------------------------------------
   -- Read side constants and signals
   -------------------------------------------------------------------------------------------------
   constant READ_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => bitSize(STREAMS_C-1),
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);
   
   -- Data readout stream
   signal readDmaDataMaster : AxiStreamMasterType;
   signal readDmaDataSlave  : AxiStreamSlaveType;
   signal readDmaDataCtrl   : AxiStreamCtrlType;

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite local bus
   -------------------------------------------------------------------------------------------------

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
   -- These should probably be 4k bytes deep for best throughput
   AXIS_IN_FIFOS : for i in STREAMS_C-1 downto 0 generate
      AxiStreamFifo : entity work.AxiStreamFifoV2
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
            SLAVE_AXI_CONFIG_G  => WAVEFORM_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => WRITE_AXIS_CONFIG_C)  -- 128-bit
         port map (
            sAxisClk    => waveformClk,
            sAxisRst    => waveformRst,
            sAxisMaster => ibWaveformMasters(i),
            sAxisSlave  => ibWaveformSlaves(i).slave,
            sAxisCtrl   => open,
            mAxisClk    => axiClk,
            mAxisRst    => axiRst,
            mAxisMaster => muxInAxisMaster(i),
            mAxisSlave  => muxInAxisSlave(i));
   end generate AXIS_IN_FIFOS;

   -- Mux of two streams
   AxiStreamMux_INST : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => STREAMS_C,
         PIPE_STAGES_G  => 1,
         TDEST_LOW_G    => 0,
         TDEST_ROUTES_G => TDEST_ROUTES_C,
         MODE_G         => "INDEXED")
      port map (
         sAxisMasters => muxInAxisMaster,
         sAxisSlaves  => muxInAxisSlave,
         mAxisMaster  => muxOutAxisMaster,
         mAxisSlave   => muxOutAxisSlave,
         axisClk      => axiClk,
         axisRst      => axiRst);

   -- Extra buffer on output of mux
   AxiStreamFifo_MUX_FIFO : entity work.AxiStreamFifoV2
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
         sAxisMaster => muxOutAxisMaster,
         sAxisSlave  => muxOutAxisSlave,
         mAxisClk    => axiClk,
         mAxisRst    => axiRst,
         mAxisMaster => muxFifoAxisMaster,
         mAxisSlave  => muxFifoAxisSlave);

   -------------------------------------------------------------------------------------------------
   -- AxiStreamDma Ring Buffers
   -------------------------------------------------------------------------------------------------
   U_AxiStreamDmaRingWrite_1 : entity work.AxiStreamDmaRingWrite
      generic map (
         TPD_G                => TPD_G,
         BUFFERS_G            => STREAMS_C,
         BURST_SIZE_BYTES_G   => 4096,
         TRIGGER_USER_BIT_G   => WAVEFORM_TRIGGER_BIT_C,
         AXIL_BASE_ADDR_G     => AXIL_BASE_ADDR_G,
         DATA_AXIS_CONFIG_G   => WRITE_AXIS_CONFIG_C,
         STATUS_AXIS_CONFIG_G => ssiAxiStreamConfig(1, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 4),
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
         axisDataMaster   => muxFifoAxisMaster,    -- [in]
         axisDataSlave    => muxFifoAxisSlave,     -- [out]
         axiWriteMaster   => axiWriteMaster,       -- [out]
         axiWriteSlave    => axiWriteSlave);       -- [in]

   -- Use bufferDone as ctrl.pause
   CTRL : for i in STREAMS_C-1 downto 0 generate
      ibWaveformSlaves(i).ctrl.pause    <= bufferDone(i);
      ibWaveformSlaves(i).ctrl.overflow <= '0';
      ibWaveformSlaves(i).ctrl.idle     <= '0';
   end generate CTRL;

   -------------------------------------------------------------------------------------------------
   -- Route status message based on tdest
   -------------------------------------------------------------------------------------------------
   U_AxiStreamDeMux_1 : entity work.AxiStreamDeMux
      generic map (
         TPD_G          => TPD_G,
         NUM_MASTERS_G  => 2,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => (
            0           => "-------0",
            1           => "00000001"),
         PIPE_STAGES_G  => 0)
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
         BUFFERS_G             => STREAMS_C,
         BURST_SIZE_BYTES_G    => 4096,
         SSI_OUTPUT_G          => true,
         AXIL_BASE_ADDR_G      => AXIL_BASE_ADDR_G,
         AXI_STREAM_READY_EN_G => true,
         AXI_STREAM_CONFIG_G   => READ_AXIS_CONFIG_C,
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
   -- Buffer the read dma data to transition to data clk 
   -------------------------------------------------------------------------------------------------
   AxiStreamFifo_RD_DATA : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => false,
         XIL_DEVICE_G        => "ULTRASCALE",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1,
         SLAVE_AXI_CONFIG_G  => READ_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_8BYTE_CONFIG_C)
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
