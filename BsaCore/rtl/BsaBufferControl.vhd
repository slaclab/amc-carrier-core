-------------------------------------------------------------------------------
-- File       : BsaBufferControl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2017-09-09
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiPkg.all;
use surf.AxiDmaPkg.all;

use surf.TextUtilPkg.all;


library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;
--use amc_carrier_core.AmcCarrierSysRegPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

entity BsaBufferControl is

   generic (
      TPD_G                   : time                      := 1 ns;
      AXIL_BASE_ADDR_G        : slv(31 downto 0)          := (others => '0');
      BSA_BUFFERS_G           : natural range 1 to 64     := 64;
      BSA_STREAM_BYTE_WIDTH_G : integer range 4 to 128    := 4;
      DIAGNOSTIC_OUTPUTS_G    : integer range 1 to 32     := 28;
      BSA_BURST_BYTES_G       : integer range 128 to 4096 := 2048;
      AXI_CONFIG_G            : AxiConfigType             := AXI_CONFIG_INIT_C);

   port (
      -- AXI-Lite Interface for local registers 
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Diagnostic Interface from application
      diagnosticClk : in sl;
      diagnosticRst : in sl;
      diagnosticBus : in DiagnosticBusType;

      -- Status stream
      axisStatusClk    : in  sl;
      axisStatusRst    : in  sl;
      axisStatusMaster : out AxiStreamMasterType;
      axisStatusSlave  : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_FORCE_C;

      -- AXI4 Interface for DDR 
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiWriteMaster : out AxiWriteMasterType;
      axiWriteSlave  : in  AxiWriteSlaveType);

end entity BsaBufferControl;

architecture rtl of BsaBufferControl is

   constant AXIL_MASTERS_C : integer := 2;

   constant TIMESTAMP_AXIL_C : integer := 0;
   constant DMA_RING_AXIL_C  : integer := 1;

   constant AXIL_CROSSBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_MASTERS_C-1 downto 0) :=
      genAxiLiteConfig(AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 16, 12);

   constant DMA_RING_BASE_ADDR_C : slv(31 downto 0) := AXIL_CROSSBAR_CONFIG_C(DMA_RING_AXIL_C).baseAddr;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);

   constant BSA_ADDR_BITS_C : integer := log2(BSA_BUFFERS_G);

   constant BSA_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => BSA_STREAM_BYTE_WIDTH_G,
      TDEST_BITS_C  => BSA_ADDR_BITS_C,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,  --ite(BSA_STREAM_BYTE_WIDTH_G = 4, TKEEP_FIXED_C, TKEEP_COMP_C),
      TUSER_BITS_C  => 2,    -- (OVFL, BSADONE)
      TUSER_MODE_C  => TUSER_LAST_C);

   constant INT_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => BSA_ADDR_BITS_C,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,  --ite(AXI_CONFIG_G.DATA_BYTES_C = 4, TKEEP_FIXED_C, TKEEP_COMP_C),
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_LAST_C);

   constant LAST_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => BSA_ADDR_BITS_C,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,  --ite(AXI_CONFIG_G.DATA_BYTES_C = 4, TKEEP_FIXED_C, TKEEP_COMP_C),
      TUSER_BITS_C  => 2,  -- (EOFE, TRIGGER)
      TUSER_MODE_C  => TUSER_LAST_C);

--    constant AXI_CONFIG_C : AxiConfigType := (
--       ADDR_WIDTH_C => 33,
--       DATA_BYTES_C => DDR_DATA_BYTE_WIDTH_G,
--       ID_BITS_C    => 1,
--       LEN_BITS_C   => 8);

   constant INT_AXIS_COUNT_C : integer                                := 8;  --integer(ceil(real(BSA_BUFFERS_G)/8.0));
   constant TDEST_ROUTES_C   : Slv8Array(INT_AXIS_COUNT_C-1 downto 0) := (others => "--------");

   signal bsaAxisMasters     : AxiStreamMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal bsaAxisSlaves      : AxiStreamSlaveArray(BSA_BUFFERS_G-1 downto 0);
   signal intAxisMasters     : AxiStreamMasterArray(INT_AXIS_COUNT_C-1 downto 0);
   signal intAxisSlaves      : AxiStreamSlaveArray(INT_AXIS_COUNT_C-1 downto 0);
   signal lastMuxAxisMaster  : AxiStreamMasterType;
   signal lastMuxAxisSlave   : AxiStreamSlaveType;
   signal lastFifoAxisMaster : AxiStreamMasterType;
   signal lastFifoAxisSlave  : AxiStreamSlaveType;
   signal diagAxisMaster     : AxiStreamMasterType;
   signal diagAxisSlave      : AxiStreamSlaveType;
   signal dmaAxisMaster      : AxiStreamMasterType;
   signal dmaAxisSlave       : AxiStreamSlaveType;

   -- Each accumulator maintains 128b header word + diagnostic output accumulations
--   constant NUM_ACCUMULATIONS_C      : integer := DIAGNOSTIC_OUTPUTS_G;
   constant NUM_ACCUMULATIONS_C      : integer := 31;

   type RegType is record
      diagnosticData : Slv32Array(NUM_ACCUMULATIONS_C downto 0);
      diagnosticSevr : Slv2Array (NUM_ACCUMULATIONS_C downto 0);
      diagnosticFixd : slv       (NUM_ACCUMULATIONS_C downto 0);
      dataSquare     : slv       (47 downto 0);
      excSquare      : sl;
      syncRdEn       : sl;
      timestampEn    : sl;
      timestampAddr  : slv(BSA_ADDR_BITS_C-1 downto 0);
      headerEn       : sl;
      accumulateEn   : sl;
      lastEn         : sl;
      adderEn        : sl;
      adderCount     : slv(5 downto 0);
      adderPhase     : slv(2 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      diagnosticData => (others => (others => '0')),
      diagnosticSevr => (others => (others => '0')),
      diagnosticFixd => (others => '0'),
      dataSquare     => (others => '0'),
      excSquare      => '0',
      syncRdEn       => '0',
      timestampEn    => '0',
      timestampAddr  => (others => '0'),
      headerEn       => '0',
      accumulateEn   => '0',
      lastEn         => '0',
      adderEn        => '0',
      adderCount     => (others => '0'),
      adderPhase     => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal diagnosticBusSyncValid : sl;
   signal diagnosticBusSync      : DiagnosticBusType;
   signal diagnosticBusSyncSlv   : slv(DIAGNOSTIC_BUS_BITS_C-1 downto 0);

   signal timeStampRamWe : sl;

   -- axilClk signals
   signal bufferClearEn : sl;
   signal bufferClear   : slv(BSA_ADDR_BITS_C-1 downto 0);
   signal bufferEnabled : slv(BSA_BUFFERS_G-1 downto 0);
   
begin

   U_AxiLiteCrossbar_1 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTERS_C,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         MASTERS_CONFIG_G   => AXIL_CROSSBAR_CONFIG_C,
         DEBUG_G            => true)
      port map (
         axiClk              => axilClk,              -- [in]
         axiClkRst           => axilRst,              -- [in]
         sAxiWriteMasters(0) => axilWriteMaster,      -- [in]
         sAxiWriteSlaves(0)  => axilWriteSlave,       -- [out]
         sAxiReadMasters(0)  => axilReadMaster,       -- [in]
         sAxiReadSlaves(0)   => axilReadSlave,        -- [out]
         mAxiWriteMasters    => locAxilWriteMasters,  -- [out]
         mAxiWriteSlaves     => locAxilWriteSlaves,   -- [in]
         mAxiReadMasters     => locAxilReadMasters,   -- [out]
         mAxiReadSlaves      => locAxilReadSlaves);   -- [in]

   -- Store timestamps during accumulate phase since we are already iterating over
   timestampRamWe <= r.timestampEn and diagnosticBusSync.timingMessage.bsaInit(conv_integer(r.timestampAddr));
   U_AxiDualPortRam_TimeStamps : entity surf.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         SYNTH_MODE_G => "inferred",
         MEMORY_TYPE_G=> "distributed",
         READ_LATENCY_G => 1,
         AXI_WR_EN_G  => false,
         SYS_WR_EN_G  => true,
         ADDR_WIDTH_G => BSA_ADDR_BITS_C,
         DATA_WIDTH_G => 64)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(TIMESTAMP_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(TIMESTAMP_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(TIMESTAMP_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(TIMESTAMP_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         we             => timeStampRamWe,
         addr           => r.timestampAddr,
         din            => diagnosticBusSync.timingMessage.timeStamp,
         dout           => open);


   -------------------------------------------------------------------------------------------------
   -- Synchronize diagnostic bus to local clock
   -------------------------------------------------------------------------------------------------
   SynchronizerFifo_1 : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         DATA_WIDTH_G => DIAGNOSTIC_BUS_BITS_C)
      port map (
         rst    => diagnosticRst,
         wr_clk => diagnosticClk,
         wr_en  => diagnosticBus.strobe,
         din    => toSlv(diagnosticBus),
         rd_clk => axiClk,
         valid  => diagnosticBusSyncValid,
         dout   => diagnosticBusSyncSlv,
         rd_en  => r.syncRdEn);

   diagnosticBusSync <= toDiagnosticBus(diagnosticBusSyncSlv);

   -------------------------------------------------------------------------------------------------
   -- One accumulator per BSA buffer
   -------------------------------------------------------------------------------------------------
   BsaAccumulator_GEN : for i in BSA_BUFFERS_G-1 downto 0 generate
      U_BsaAccumulator_1 : entity amc_carrier_core.BsaAccumulator
         generic map (
            TPD_G               => TPD_G,
            BSA_NUMBER_G        => i,
            NUM_ACCUMULATIONS_G => NUM_ACCUMULATIONS_C+1,
            FRAME_SIZE_BYTES_G  => BSA_BURST_BYTES_G,
            AXIS_CONFIG_G       => BSA_STREAM_CONFIG_C)
         port map (
            clk            => axiClk,                                         -- [in]
            rst            => axiRst,                                         -- [in]
            enable         => bufferEnabled(i),                               -- [in]
            bsaInit        => diagnosticBusSync.timingMessage.bsaInit(i),     -- [in]
            bsaActive      => diagnosticBusSync.timingMessage.bsaActive(i),   -- [in]
            bsaAvgDone     => diagnosticBusSync.timingMessage.bsaAvgDone(i),  -- [in]
            bsaDone        => diagnosticBusSync.timingMessage.bsaDone(i),     -- [in]
            diagnosticData => r.diagnosticData(NUM_ACCUMULATIONS_C),          -- [in]
            diagnosticSqr  => r.dataSquare,                                   -- [in]
            diagnosticFixd => r.diagnosticFixd(NUM_ACCUMULATIONS_C),          -- [in]
            diagnosticSevr => r.diagnosticSevr(NUM_ACCUMULATIONS_C),          -- [in]
            diagnosticExc  => r.excSquare,                                    -- [in]
            accumulateEn   => r.accumulateEn,                                 -- [in]
            lastEn         => r.lastEn,                                       -- [in]
            axisMaster     => bsaAxisMasters(i),                              -- [out]
            axisSlave      => bsaAxisSlaves(i));                              -- [in]
   end generate;

   -------------------------------------------------------------------------------------------------
   -- Multiplex the AXI stream outputs from all the bsa buffers down to a single stream
   -------------------------------------------------------------------------------------------------
   AxiStreamMux_INT : for i in INT_AXIS_COUNT_C-1 downto 0 generate
      signal intMuxAxisMasters : AxiStreamMasterArray(INT_AXIS_COUNT_C-1 downto 0);
      signal intMuxAxisSlaves  : AxiStreamSlaveArray(INT_AXIS_COUNT_C-1 downto 0);
      signal intBsaAxisMasters : AxiStreamMasterArray(7 downto 0);
      signal intBsaAxisSlaves  : AxiStreamSlaveArray(7 downto 0);
   begin

      mapping : for j in 7 downto 0 generate
         intBsaAxisMasters(j) <= bsaAxisMasters(j*8+i);
         bsaAxisSlaves(j*8+i) <= intBsaAxisSlaves(j);
      end generate mapping;

      U_AxiStreamMux_INT : entity surf.AxiStreamMux
         generic map (
            TPD_G          => TPD_G,
            NUM_SLAVES_G   => 8,
            PIPE_STAGES_G  => 1,
            TDEST_LOW_G    => 0,
            TDEST_ROUTES_G => TDEST_ROUTES_C,
            MODE_G         => "ROUTED")
         port map (
            sAxisMasters => intBsaAxisMasters,     -- [in]
            sAxisSlaves  => intBsaAxisSlaves,      -- [out]
            mAxisMaster  => intMuxAxisMasters(i),  -- [out]
            mAxisSlave   => intMuxAxisSlaves(i),   -- [in]
            axisClk      => axiClk,                -- [in]
            axisRst      => axiRst);               -- [in]

      U_AxiStreamFifo_INT : entity surf.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 0,
            PIPE_STAGES_G       => 1,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 1,
            BRAM_EN_G           => true,
            USE_BUILT_IN_G      => false,
            GEN_SYNC_FIFO_G     => true,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 10,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 1,
            CASCADE_PAUSE_SEL_G => 0,
            SLAVE_AXI_CONFIG_G  => BSA_STREAM_CONFIG_C,
            MASTER_AXI_CONFIG_G => INT_STREAM_CONFIG_C)
         port map (
            sAxisClk    => axiClk,                -- [in]
            sAxisRst    => axiRst,                -- [in]
            sAxisMaster => intMuxAxisMasters(i),  -- [in]
            sAxisSlave  => intMuxAxisSlaves(i),   -- [out]
            mAxisClk    => axiClk,                -- [in]
            mAxisRst    => axiRst,                -- [in]
            mAxisMaster => intAxisMasters(i),     -- [out]
            mAxisSlave  => intAxisSlaves(i));     -- [in]
   end generate;

   U_AxiStreamMux_LAST : entity surf.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => INT_AXIS_COUNT_C,
         PIPE_STAGES_G  => 1,
         TDEST_LOW_G    => 0,
         TDEST_ROUTES_G => TDEST_ROUTES_C,
         MODE_G         => "ROUTED")
      port map (
         sAxisMasters => intAxisMasters,     -- [in]
         sAxisSlaves  => intAxisSlaves,      -- [out]
         mAxisMaster  => lastMuxAxisMaster,  -- [out]
         mAxisSlave   => lastMuxAxisSlave,   -- [in]
         axisClk      => axiClk,             -- [in]
         axisRst      => axiRst);            -- [in]

   U_AxiStreamFifo_LAST : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 0,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 0,
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 10,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1,
         CASCADE_PAUSE_SEL_G => 0,
         SLAVE_AXI_CONFIG_G  => INT_STREAM_CONFIG_C,
         MASTER_AXI_CONFIG_G => LAST_STREAM_CONFIG_C)
      port map (
         sAxisClk    => axiClk,              -- [in]
         sAxisRst    => axiRst,              -- [in]
         sAxisMaster => lastMuxAxisMaster,   -- [in]
         sAxisSlave  => lastMuxAxisSlave,    -- [out]
         sAxisCtrl   => open,
         mAxisClk    => axiClk,              -- [in]
         mAxisRst    => axiRst,              -- [in]
         mAxisMaster => lastFifoAxisMaster,  -- [out]
         mAxisSlave  => lastFifoAxisSlave);  -- [in]

   axisStatusMaster <= AXI_STREAM_MASTER_INIT_C;

   U_AxiStreamDmaRingWrite_1 : entity surf.AxiStreamDmaRingWrite
      generic map (
         TPD_G                => TPD_G,
         BUFFERS_G            => BSA_BUFFERS_G,
         BURST_SIZE_BYTES_G   => BSA_BURST_BYTES_G,
         ENABLE_UNALIGN_G     => true,
         TRIGGER_USER_BIT_G   => 1,  -- EOFE is bit 0
         AXIL_BASE_ADDR_G     => DMA_RING_BASE_ADDR_C,
         DATA_AXIS_CONFIG_G   => LAST_STREAM_CONFIG_C,
         STATUS_AXIS_CONFIG_G => ssiAxiStreamConfig(1),
         AXI_WRITE_CONFIG_G   => AXI_CONFIG_G)
      port map (
         axilClk          => axilClk,                               -- [in]
         axilRst          => axilRst,                               -- [in]
         axilReadMaster   => locAxilReadMasters(DMA_RING_AXIL_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(DMA_RING_AXIL_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(DMA_RING_AXIL_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(DMA_RING_AXIL_C),   -- [out]
         axisStatusClk    => axisStatusClk,                         -- [in]
         axisStatusRst    => axisStatusRst,                         -- [in]
         axisStatusMaster => open,                                  -- [out]
         axisStatusSlave  => AXI_STREAM_SLAVE_FORCE_C,              -- [in]
         axiClk           => axiClk,                                -- [in]
         axiRst           => axiRst,                                -- [in]
         bufferClearEn    => timeStampRamWe,                        -- [in]
         bufferClear      => r.timestampAddr,                       -- [in]
         bufferEnabled    => bufferEnabled,                         -- [out]
         axisDataMaster   => lastFifoAxisMaster,                    -- [in]
         axisDataSlave    => lastFifoAxisSlave,                     -- [out]
         axiWriteMaster   => axiWriteMaster,                        -- [out]
         axiWriteSlave    => axiWriteSlave);                        -- [in]

   -------------------------------------------------------------------------------------------------
   -- Accumulation sequencing, and AXI-Lite logic
   -------------------------------------------------------------------------------------------------
   comb : process (axiRst, diagnosticBusSync, diagnosticBusSyncValid, r) is
      variable v : RegType;
      variable b : integer range 0 to BSA_BUFFERS_G-1;

   begin
      v := r;

      v.syncRdEn     := '0';
      v.accumulateEn := '0';
      v.headerEn     := '0';

      v.adderPhase := r.adderPhase+1;
      
      ----------------------------------------------------------------------------------------------
      -- Accumulation stage - shift new diagnostic data through the accumulators
      ----------------------------------------------------------------------------------------------
      if r.adderPhase="100" and r.adderEn='1' then

        v.adderPhase := "000";
        v.adderCount := r.adderCount + 1;

        v.diagnosticData := r.diagnosticData(0) & r.diagnosticData(r.diagnosticData'left downto 1);
        v.diagnosticSevr := r.diagnosticSevr(0) & r.diagnosticSevr(r.diagnosticSevr'left downto 1);
        v.diagnosticFixd := r.diagnosticFixd(0) & r.diagnosticFixd(r.diagnosticFixd'left downto 1);

        v.dataSquare := x"000" &
                        slv(signed(r.diagnosticData(0)(17 downto 0))*
                            signed(r.diagnosticData(0)(17 downto 0)));
        if (allBits(r.diagnosticData(0)(31 downto 17),'0') or
            allBits(r.diagnosticData(0)(31 downto 17),'1')) then
          v.excSquare := '0';
        else
          v.excSquare := '1';
        end if;

        v.lastEn  := '0';
        if (r.adderCount = NUM_ACCUMULATIONS_C-1) then
          v.lastEn   := '1';
        end if;
        if (r.adderCount < NUM_ACCUMULATIONS_C) then
          v.accumulateEn := '1';
        end if;

        if (r.adderCount = NUM_ACCUMULATIONS_C+1) then
          v.adderEn     := '0';
          v.syncRdEn    := '1';            
        end if;

      end if;
      
      ----------------------------------------------------------------------------------------------
      -- Disable timestamps after iterating through all bsa indicies
      ----------------------------------------------------------------------------------------------
      if r.timestampEn = '1' then
        v.timestampAddr := r.timestampAddr+1;
        if r.timestampAddr = BSA_BUFFERS_G-1 then
          v.timestampEn := '0';
        end if;
      end if;
      
      ----------------------------------------------------------------------------------------------
      -- Synchronization
      -- Wait for synchronized strobe signal, then latch the timing message onto the local clock      
      ----------------------------------------------------------------------------------------------
      if (diagnosticBusSyncValid = '1' and r.accumulateEn = '0' and r.adderEn = '0' and r.syncRdEn = '0') then
         --  Header data
         v.dataSquare := diagnosticBusSync.timingMessage.pulseId(63 downto 16);
         v.diagnosticData(NUM_ACCUMULATIONS_C) :=
           diagnosticBusSync.timingMessage.pulseId(15 downto 0) &
           toSlv(NUM_ACCUMULATIONS_C,16);
         v.diagnosticSevr(NUM_ACCUMULATIONS_C) := "00";
         v.diagnosticFixd(NUM_ACCUMULATIONS_C) := '1';
         --  Channel data
         v.diagnosticData(NUM_ACCUMULATIONS_C-1 downto 0) :=
           diagnosticBusSync.data (NUM_ACCUMULATIONS_C-1 downto 0);
         v.diagnosticSevr(NUM_ACCUMULATIONS_C-1 downto 0) := 
           diagnosticBusSync.sevr (NUM_ACCUMULATIONS_C-1 downto 0);
         v.diagnosticFixd(NUM_ACCUMULATIONS_C-1 downto 0) :=
           diagnosticBusSync.fixed(NUM_ACCUMULATIONS_C-1 downto 0);

         v.excSquare      := '0';
         v.accumulateEn   := '1';
         v.timestampEn    := '1';
         v.timestampAddr  := (others => '0');
         v.adderEn        := '1';
         v.adderCount     := (others => '0');
         v.adderPhase     := (others => '0');
      end if;

      ----------------------------------------------------------------------------------------------        
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

