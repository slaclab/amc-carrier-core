-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaBufferControl.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2016-02-08
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing BSA Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Timing BSA Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.AxiDmaPkg.all;

use work.TextUtilPkg.all;

use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;
use work.TimingPkg.all;

entity BsaBufferControl2 is

   generic (
      TPD_G                   : time                      := 1 ns;
      BSA_BUFFERS_G           : natural range 1 to 64     := 64;
      BSA_ACCUM_FLOAT_G       : boolean                   := true;
      BSA_STREAM_BYTE_WIDTH_G : integer range 4 to 128    := 4;
      DIAGNOSTIC_OUTPUTS_G    : integer range 1 to 32     := 28;
      DDR_BURST_BYTES_G       : integer range 128 to 4096 := 2048;
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

      -- AXI4 Interface for DDR 
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiWriteMaster : out AxiWriteMasterType;
      axiWriteSlave  : in  AxiWriteSlaveType);

end entity BsaBufferControl2;

architecture rtl of BsaBufferControl2 is

   constant AXIL_MASTERS_C : integer := 6;

   constant LOCAL_AXIL_C     : integer := 0;
   constant START_AXIL_C     : integer := 1;
   constant END_AXIL_C       : integer := 2;
   constant FIRST_AXIL_C     : integer := 3;
   constant LAST_AXIL_C      : integer := 4;
--   constant NEXT_AXIL_C      : integer := 5;
   constant TIMESTAMP_AXIL_C : integer := 5;

   -- AxiLite bus gets synchronized to axi4 clk
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);

   constant BSA_ADDR_BITS_C : integer := log2(BSA_BUFFERS_G);

   component BsaConvFpCore
      port (
         aclk                 : in  sl;
         s_axis_a_tvalid      : in  sl;
         s_axis_a_tdata       : in  slv(31 downto 0);
         m_axis_result_tvalid : out sl;
         m_axis_result_tdata  : out slv(31 downto 0)
         );
   end component;

   constant AXI_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => BSA_STREAM_BYTE_WIDTH_G,
      TDEST_BITS_C  => BSA_ADDR_BITS_C,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => ite(BSA_STREAM_BYTE_WIDTH_G = 4, TKEEP_FIXED_C, TKEEP_COMP_C),
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   constant DDR_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXI_CONFIG_G.DATA_BYTES_C,
      TDEST_BITS_C  => BSA_ADDR_BITS_C,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => ite(AXI_CONFIG_G.DATA_BYTES_C = 4, TKEEP_FIXED_C, TKEEP_COMP_C),
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

--    constant AXI_CONFIG_C : AxiConfigType := (
--       ADDR_WIDTH_C => 33,
--       DATA_BYTES_C => DDR_DATA_BYTE_WIDTH_G,
--       ID_BITS_C    => 1,
--       LEN_BITS_C   => 8);

   constant INT_AXIS_COUNT_C : integer := 8;  --integer(ceil(real(BSA_BUFFERS_G)/8.0));
   constant TDEST_ROUTES_C    : Slv8Array(INT_AXIS_COUNT_C-1 downto 0) := (others => "--------")

   signal bsaAxisMasters : AxiStreamMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal bsaAxisSlaves  : AxiStreamSlaveArray(BSA_BUFFERS_G-1 downto 0);
   signal intAxisMasters : AxiStreamMasterArray(INT_AXIS_COUNT_C-1 downto 0);
   signal intAxisSlaves  : AxiStreamSlaveArray(INT_AXIS_COUNT_C-1 downto 0);
   signal lastAxisMaster : AxiStreamMasterType;
   signal lastAxisSlave  : AxiStreamSlaveType;
   signal ddrAxisMaster  : AxiStreamMasterType;
   signal ddrAxisSlave   : AxiStreamSlaveType;

   -- Each accumulator maintains 4 header words + diagnostic output accumulations
   constant NUM_ACCUMULATIONS_C      : integer := DIAGNOSTIC_OUTPUTS_G + 4;
   constant BSA_BUFFER_ENTRY_BYTES_C : integer := NUM_ACCUMULATIONS_C * 4;

   type AxiStateType is (WAIT_TVALID_S, LATCH_POINTERS_S, WAIT_DMA_DONE_S, BSA_INIT_S);

   type RegType is record
      -- Just register the whole timing message
      strobe          : sl;
      timingMessage   : TimingMessageType;
      diagnosticData  : Slv32Array(NUM_ACCUMULATIONS_C - 1 downto 0);
      bsaInitAxil     : slv(63 downto 0);
      bsaCompleteAxil : slv(63 downto 0);
      bsaCompleteTmp : slv(63 downto 0);      

      ramAddr32 : sl;

      wrBsaAddr      : slv(log2(BSA_BUFFERS_G)-1 downto 0);
      rdBsaAddr      : slv(log2(BSA_BUFFERS_G)-1 downto 0);
      bsaAddrTemp    : slv(log2(BSA_BUFFERS_G)-1 downto 0);
      clearBsaBuffer : sl;
      addrRamWe     : sl;
--       lastRamWe      : sl;
--       nextRamWe      : sl;
      firstAddr      : slv(31 downto 0);
      lastAddr       : slv(31 downto 0);
--      nextAddr       : slv(31 downto 0);
      startAddr      : slv(31 downto 0);
      endAddr        : slv(31 downto 0);

      timestampEn  : sl;
      accumulateEn : sl;
      setEn        : sl;
      lastEn       : sl;
      adderCount   : slv(5 downto 0);

      state  : AxiStateType;
      dmaReq : AxiWriteDmaReqType;

      axilWriteSlave : AxiLiteWriteSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      strobe          => '0',
      timingMessage   => TIMING_MESSAGE_INIT_C,
      diagnosticData  => (others => (others => '0')),
      bsaInitAxil     => (others => '0'),
      bsaCompleteAxil => (others => '0'),
      bsaCompleteTmp => (others => '0'),      
      ramAddr32       => '0',
      wrBsaAddr       => (others => '0'),
      rdBsaAddr       => (others => '0'),
      bsaAddrTemp     => (others => '0'),
      clearBsaBuffer  => '0',
      addrRamWe      => '0',
--       lastRamWe       => '0',
--       nextRamWe       => '0',
      firstAddr       => (others => '0'),
      lastAddr        => (others => '0'),
--      nextAddr        => (others => '0'),
      startAddr       => (others => '0'),
      endAddr         => (others => '0'),
      timestampEn     => '0',
      setEn           => '0',
      lastEn          => '0',
      accumulateEn    => '0',
      adderCount      => (others => '0'),
      state           => WAIT_TVALID_S,
      dmaReq          => AXI_WRITE_DMA_REQ_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal diagnosticStrobeSync : sl;
   signal diagnosticFpValid    : slv(DIAGNOSTIC_OUTPUTS_G downto 0);
   signal diagnosticFpData     : Slv32Array(DIAGNOSTIC_OUTPUTS_G downto 0);

   signal startRamDout   : slv(31 downto 0);
   signal endRamDout     : slv(31 downto 0);
   signal firstRamDout   : slv(31 downto 0);
   signal lastRamDout    : slv(31 downto 0);
   signal timeStampRamWe : sl;

   signal dmaAck : AxiWriteDmaAckType;

begin

   -- Synchronize Axi-Lite bus to axiClk (ddrClk)
   AxiLiteAsync_1 : entity work.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         NUM_ADDR_BITS_G => 32,
         PIPE_STAGES_G   => 1)
      port map (
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         mAxiClk         => axiClk,
         mAxiClkRst      => axiRst,
         mAxiReadMaster  => syncAxilReadMaster,
         mAxiReadSlave   => syncAxilReadSlave,
         mAxiWriteMaster => syncAxilWriteMaster,
         mAxiWriteSlave  => syncAxilWriteSlave);

   U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTERS_C,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         MASTERS_CONFIG_G   => genAxiLiteConfig(AXIL_MASTERS_C, BSA_ADDR_C, 16, 12),  -- Up to 64 bsa Buffers
         DEBUG_G            => true)
      port map (
         axiClk              => axiClk,                                              -- [in]
         axiClkRst           => axiRst,                                              -- [in]
         sAxiWriteMasters(0) => syncAxilWriteMaster,                                 -- [in]
         sAxiWriteSlaves(0)  => syncAxilWriteSlave,                                  -- [out]
         sAxiReadMasters(0)  => syncAxilReadMaster,                                  -- [in]
         sAxiReadSlaves(0)   => syncAxilReadSlave,                                   -- [out]
         mAxiWriteMasters    => locAxilWriteMasters,                                 -- [out]
         mAxiWriteSlaves     => locAxilWriteSlaves,                                  -- [in]
         mAxiReadMasters     => locAxilReadMasters,                                  -- [out]
         mAxiReadSlaves      => locAxilReadSlaves);                                  -- [in]

   -------------------------------------------------------------------------------------------------
   -- AXI RAMs store buffer information
   -------------------------------------------------------------------------------------------------
   -- Start Addresses
   U_AxiDualPortRam_Start : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => true,
         SYS_WR_EN_G  => false,
         ADDR_WIDTH_G => BSA_ADDR_BITS_C,
         DATA_WIDTH_G => 32)
      port map (
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => locAxilReadMasters(START_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(START_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(START_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(START_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         addr           => r.rdBsaAddr,
         dout           => startRamDout);

   -- End Addresses
   U_AxiDualPortRam_End : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => true,
         SYS_WR_EN_G  => false,
         ADDR_WIDTH_G => BSA_ADDR_BITS_C,
         DATA_WIDTH_G => 32)
      port map (
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => locAxilReadMasters(END_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(END_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(END_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(END_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         addr           => r.rdBsaAddr,
         dout           => endRamDout);

   -- First Addresses
   U_AxiDualPortRam_First : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => false,
         SYS_WR_EN_G  => true,
         ADDR_WIDTH_G => BSA_ADDR_BITS_C,
         DATA_WIDTH_G => 32)
      port map (
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => locAxilReadMasters(FIRST_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(FIRST_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(FIRST_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(FIRST_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         we             => r.addrRamWe,
         addr           => r.wrBsaAddr,
         din            => r.firstAddr,
         dout           => firstRamDout);

   -- Last Addresses
   U_AxiDualPortRam_Last : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => false,
         SYS_WR_EN_G  => true,
         ADDR_WIDTH_G => BSA_ADDR_BITS_C,
         DATA_WIDTH_G => 32)
      port map (
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => locAxilReadMasters(LAST_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(LAST_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(LAST_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(LAST_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         we             => r.addrRamWe,
         addr           => r.wrBsaAddr,
         din            => r.lastAddr,
         dout           => lastRamDout);

   -- Next Addresses
--    U_AxiDualPortRam_Next : entity work.AxiDualPortRam
--       generic map (
--          TPD_G        => TPD_G,
--          BRAM_EN_G    => false,
--          REG_EN_G     => false,
--          AXI_WR_EN_G  => false,
--          SYS_WR_EN_G  => true,
--          ADDR_WIDTH_G => BSA_ADDR_BITS_C,
--          DATA_WIDTH_G => 32)
--       port map (
--          axiClk         => axiClk,
--          axiRst         => axiRst,
--          axiReadMaster  => locAxilReadMasters(NEXT_AXIL_C),
--          axiReadSlave   => locAxilReadSlaves(NEXT_AXIL_C),
--          axiWriteMaster => locAxilWriteMasters(NEXT_AXIL_C),
--          axiWriteSlave  => locAxilWriteSlaves(NEXT_AXIL_C),
--          clk            => axiClk,
--          rst            => axiRst,
--          we             => r.nextRamWe,
--          addr           => r.wrBsaAddr,
--          din            => r.nextAddr,
--          dout           => nextRamDout);

   -- Store timestamps during accumulate phase since we are already iterating over
   timestampRamWe <= r.timestampEn and r.timingMessage.bsaInit(conv_integer(r.adderCount));
   U_AxiDualPortRam_TimeStamps : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => false,
         SYS_WR_EN_G  => true,
         ADDR_WIDTH_G => BSA_ADDR_BITS_C,
         DATA_WIDTH_G => 64)
      port map (
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => locAxilReadMasters(TIMESTAMP_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(TIMESTAMP_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(TIMESTAMP_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(TIMESTAMP_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         we             => timeStampRamWe,
         addr           => r.adderCount(BSA_ADDR_BITS_C-1 downto 0),
         din            => r.timingMessage.timeStamp,
         dout           => open);


   -------------------------------------------------------------------------------------------------
   -- Synchronize diagnostic bus to local clock
   -------------------------------------------------------------------------------------------------
   SynchronizerFifo_1 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         DATA_WIDTH_G => 1)
      port map (
         rst    => diagnosticRst,
         wr_clk => diagnosticClk,
         wr_en  => diagnosticBus.strobe,
         din    => "1",
         rd_clk => axiClk,
         valid  => diagnosticStrobeSync);

   -------------------------------------------------------------------------------------------------
   -- Convert synchronized diagnostic bus to floating point
   -------------------------------------------------------------------------------------------------
   FP_CONV_GEN : if (BSA_ACCUM_FLOAT_G) generate
      DIAGNOSTIC_FP_CONV : for i in DIAGNOSTIC_OUTPUTS_G downto 0 generate
         U_BsaConvFpCore_1 : entity work.BsaConvFpCore
            port map (
               aclk                 => axiClk,                 -- [in]
               s_axis_a_tvalid      => r.strobe,               -- [in]
               s_axis_a_tdata       => r.diagnosticData(i+3),  -- [in]
               m_axis_result_tvalid => diagnosticFpValid(i),   -- [out]
               m_axis_result_tdata  => diagnosticFpData(i));   -- [out]
      end generate DIAGNOSTIC_FP_CONV;
   end generate FP_CONV_GEN;

   SIGNED_CONV_GEN : if (not BSA_ACCUM_FLOAT_G) generate
      diagnosticFpValid <= (others => r.strobe);
      diagnosticFpData  <= r.diagnosticData(NUM_ACCUMULATIONS_C-1 downto 3);
   end generate SIGNED_CONV_GEN;

   -------------------------------------------------------------------------------------------------
   -- One accumulator per BSA buffer
   -------------------------------------------------------------------------------------------------
   BsaAccumulator_GEN : for i in BSA_BUFFERS_G-1 downto 0 generate
      U_BsaAccumulator_1 : entity work.BsaAccumulator
         generic map (
            TPD_G               => TPD_G,
            BSA_NUMBER_G        => i,
            BSA_ACCUM_FLOAT_G   => BSA_ACCUM_FLOAT_G,
            NUM_ACCUMULATIONS_G => NUM_ACCUMULATIONS_C,
            FRAME_SIZE_BYTES_G  => DDR_BURST_BYTES_G,
            AXIS_CONFIG_G       => AXI_STREAM_CONFIG_C)
         port map (
            clk            => axiClk,                         -- [in]
            rst            => axiRst,                         -- [in]
            bsaInit        => r.timingMessage.bsaInit(i),     -- [in]
            bsaActive      => r.timingMessage.bsaActive(i),   -- [in]
            bsaAvgDone     => r.timingMessage.bsaAvgDone(i),  -- [in]
            bsaDone        => r.timingMessage.bsaDone(i),     -- [in]
            diagnosticData => r.diagnosticData(0),            -- [in]
            accumulateEn   => r.accumulateEn,                 -- [in]
            setEn          => r.setEn,                        -- [in]
            lastEn         => r.lastEn,                       -- [in]
            axisMaster     => bsaAxisMasters(i),              -- [out]
            axisSlave      => bsaAxisSlaves(i));              -- [in]
   end generate;

   -------------------------------------------------------------------------------------------------
   -- Multiplex the AXI stream outputs from all the bsa buffers down to a single stream
   -------------------------------------------------------------------------------------------------
   AxiStreamMux_GEN : for i in INT_AXIS_COUNT_C-1 downto 0 generate
      U_AxiStreamMux_1 : entity work.AxiStreamMux
         generic map (
            TPD_G          => TPD_G,
            NUM_SLAVES_G   => 8,
            PIPE_STAGES_G  => 1,
            TDEST_HIGH_G   => 7,
            TDEST_LOW_G    => 0,
            TDEST_ROUTES_G => TDEST_ROUTES_C,
            MODE_G         => "ROUTED")
         port map (
            sAxisMasters => bsaAxisMasters(i*8+8-1 downto i*8),  -- [in]
            sAxisSlaves  => bsaAxisSlaves(i*8+8-1 downto i*8),   -- [out]
            mAxisMaster  => intAxisMasters(i),                   -- [out]
            mAxisSlave   => intAxisSlaves(i),                    -- [in]
            axisClk      => axiClk,                              -- [in]
            axisRst      => axiRst);                             -- [in]
   end generate;

   U_AxiStreamMux_2 : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => INT_AXIS_COUNT_C,
         PIPE_STAGES_G  => 0,
         TDEST_HIGH_G   => 7,
         TDEST_LOW_G    => 0,
         TDEST_ROUTES_G => TDEST_ROUTES_C,
         MODE_G         => "ROUTED")
      port map (
         sAxisMasters => intAxisMasters,  -- [in]
         sAxisSlaves  => intAxisSlaves,   -- [out]
         mAxisMaster  => lastAxisMaster,  -- [out]
         mAxisSlave   => lastAxisSlave,   -- [in]
         axisClk      => axiClk,          -- [in]
         axisRst      => axiRst);         -- [in]

   U_AxiStreamFifo_1 : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 0,
         PIPE_STAGES_G       => 0,
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
         SLAVE_AXI_CONFIG_G  => AXI_STREAM_CONFIG_C,
         MASTER_AXI_CONFIG_G => DDR_STREAM_CONFIG_C)
      port map (
         sAxisClk    => axiClk,          -- [in]
         sAxisRst    => axiRst,          -- [in]
         sAxisMaster => lastAxisMaster,  -- [in]
         sAxisSlave  => lastAxisSlave,   -- [out]
         sAxisCtrl   => open,
         mAxisClk    => axiClk,          -- [in]
         mAxisRst    => axiRst,          -- [in]
         mAxisMaster => ddrAxisMaster,   -- [out]
         mAxisSlave  => ddrAxisSlave);   -- [in]

   U_AxiStreamDmaWrite_1 : entity work.AxiStreamDmaWrite
      generic map (
         TPD_G          => TPD_G,
         AXI_READY_EN_G => true,
         AXIS_CONFIG_G  => DDR_STREAM_CONFIG_C,
         AXI_CONFIG_G   => AXI_CONFIG_G,
         AXI_BURST_G    => "01",            -- INCR
         AXI_CACHE_G    => "1111")          -- Cacheable
      port map (
         axiClk         => axiClk,          -- [in]
         axiRst         => axiRst,          -- [in]
         dmaReq         => r.dmaReq,        -- [in]
         dmaAck         => dmaAck,          -- [out]
         axisMaster     => ddrAxisMaster,   -- [in]
         axisSlave      => ddrAxisSlave,    -- [out]
         axiWriteMaster => axiWriteMaster,  -- [out]
         axiWriteSlave  => axiWriteSlave);  -- [in]


   -------------------------------------------------------------------------------------------------
   -- Accumulation sequencing, DMA ring buffer, and AXI-Lite logic
   -------------------------------------------------------------------------------------------------
   comb : process (axiRst, ddrAxisMaster, diagnosticBus, diagnosticFpData, diagnosticFpValid, diagnosticStrobeSync, dmaAck, endRamDout, firstRamDout, lastRamDout, locAxilReadMasters,
                   locAxilWriteMasters, r, startRamDout) is
      variable v         : RegType;
      variable b         : integer range 0 to BSA_BUFFERS_G-1;
      variable axiStatus : AxiLiteStatusType;

   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- Synchronization
      -- Wait for synchronized strobe signal, then latch the timing message onto the local clock      
      ----------------------------------------------------------------------------------------------
      v.strobe := '0';
      if (diagnosticStrobeSync = '1') then
         v.strobe                                         := '1';
         v.timingMessage                                  := diagnosticBus.timingMessage;
         v.diagnosticData(NUM_ACCUMULATIONS_C-1 downto 4) := diagnosticBus.data(DIAGNOSTIC_OUTPUTS_G-1 downto 0);
         v.diagnosticData(3)                              := X"00000001";                      -- 1.0 (for number of accumulations)
         v.diagnosticData(2)                              := toSlv(DIAGNOSTIC_OUTPUTS_G, 32);  --Make this based on app constants
         v.diagnosticData(1)                              := diagnosticBus.timingMessage.pulseId(63 downto 32);
         v.diagnosticData(0)                              := diagnosticBus.timingMessage.pulseId(31 downto 0);
      end if;

      ----------------------------------------------------------------------------------------------
      -- Counter is freerunning. Reset at start of new message
      ----------------------------------------------------------------------------------------------
      v.adderCount := r.adderCount + 1;
      v.lastEn     := '0';

      ----------------------------------------------------------------------------------------------
      -- Wiat for FP conversion of diagnostic data
      ----------------------------------------------------------------------------------------------
      if (diagnosticFpValid(0) = '1') then
         v.timestampEn                                    := '1';
         v.accumulateEn                                   := '1';
         v.setEn                                          := '1';
         v.adderCount                                     := (others => '0');
         v.diagnosticData(NUM_ACCUMULATIONS_C-1 downto 3) := diagnosticFpData;

         v.bsaCompleteTmp := r.bsaCompleteTmp or r.timingMessage.bsaDone;
         v.bsaInitAxil     := r.bsaInitAxil or r.timingMessage.bsaInit;

      end if;

      ----------------------------------------------------------------------------------------------
      -- Accumulation stage - shift new diagnostic data through the accumulators
      ----------------------------------------------------------------------------------------------
      if (r.accumulateEn = '1') then
         v.diagnosticData(NUM_ACCUMULATIONS_C-1)          := X"00000000";
         v.diagnosticData(NUM_ACCUMULATIONS_C-2 downto 0) := r.diagnosticData(NUM_ACCUMULATIONS_C-1 downto 1);

         -- Stop when done with all buffers
         v.adderCount := r.adderCount + 1;
         if (r.adderCount = 2) then
            v.setEn := '0';
         end if;
         if (r.adderCount = NUM_ACCUMULATIONS_C-2) then
            v.lastEn := '1';
         end if;
         if (r.adderCount = NUM_ACCUMULATIONS_C-1) then
            v.accumulateEn := '0';
         end if;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Disable timestamps after iterating through all bsa indicies
      ----------------------------------------------------------------------------------------------
      if (r.adderCount = 63) then
         v.timestampEn := '0';
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI4 Stage - Read entries from FIFO and write to RAM on AXI4 bus
      ----------------------------------------------------------------------------------------------
      v.addrRamWe      := '0';
--       v.firstRamWe     := '0';
--       v.lastRamWe      := '0';
      v.dmaReq.maxSize := toSlv(DDR_BURST_BYTES_G, 32);
      v.clearBsaBuffer := '0';

      case (r.state) is
         when WAIT_TVALID_S =>
            -- Only final burst before readout can be short, so no need to worry about next
            -- burst wrapping awkwardly. Whole thing will be reset after readout.
            -- Don't do anything if in the middle of a buffer address clear
            if (ddrAxisMaster.tvalid = '1') then
               v.wrBsaAddr := ddrAxisMaster.tdest(BSA_ADDR_BITS_C-1 downto 0);
               v.rdBsaAddr := ddrAxisMaster.tdest(BSA_ADDR_BITS_C-1 downto 0);
               v.state     := LATCH_POINTERS_S;
            end if;

            -- Don't allow dma req to start if a buffer neads to be init
            if (r.timestampEn = '1' and r.timingMessage.bsaInit(conv_integer(r.adderCount)) = '1') then
--               print("bsaInit in WAIT_TVALID_S: " & str(conv_integer(r.adderCount)));
               v.clearBsaBuffer := '1';
               v.rdBsaAddr      := r.adderCount;
               v.wrBsaAddr      := r.rdBsaAddr;
               v.state          := WAIT_TVALID_S;
            end if;

         when LATCH_POINTERS_S =>
            -- Latch pointers
            v.startAddr := startRamDout;
            v.endAddr   := endRamDout;
            v.firstAddr := firstRamDout;
            v.lastAddr  := lastRamDout;
--            v.nextAddr  := nextRamDout;

            v.dmaReq.address(31 downto 0) := lastRamDout;
            v.dmaReq.address(32)          := r.ramAddr32;
            v.dmaReq.request              := '1';
            v.state                       := WAIT_DMA_DONE_S;

            -- Init request might interrupt things
            if (r.timestampEn = '1' and r.timingMessage.bsaInit(conv_integer(r.adderCount)) = '1') then
--               print("bsaInit in LATCH_POINTERS_S: " & str(conv_integer(r.adderCount)));
               v.clearBsaBuffer := '1';
               v.rdBsaAddr      := r.adderCount;
               v.wrBsaAddr      := r.adderCount;
               v.bsaAddrTemp    := r.rdBsaAddr;
               v.state          := BSA_INIT_S;
            end if;

         when BSA_INIT_S =>
            if (r.timestampEn = '1' and r.timingMessage.bsaInit(conv_integer(r.adderCount)) = '1') then
--               print("bsaInit in BSA_INIT_S: " & str(conv_integer(r.adderCount)));
               v.clearBsaBuffer := '1';
               v.rdBsaAddr      := r.adderCount;
               v.wrBsaAddr      := r.rdBsaAddr;
               v.state          := BSA_INIT_S;
            else
               v.rdBsaAddr := r.bsaAddrTemp;
               v.wrBsaAddr := r.bsaAddrTemp;
               v.state     := LATCH_POINTERS_S;
            end if;


         when WAIT_DMA_DONE_S =>
            -- Must check that BSA buffer not being cleared so as not to step on the addresses
            if (r.timestampEn = '1' and r.timingMessage.bsaInit(conv_integer(r.adderCount)) = '1') then
--               print("bsaInit in WAIT_DMA_DONE_S: " & str(conv_integer(r.adderCount)));
               v.clearBsaBuffer := '1';
               v.rdBsaAddr      := r.adderCount;
               v.wrBsaAddr      := r.adderCount;
               v.bsaAddrTemp    := r.rdBsaAddr;
               v.state          := BSA_INIT_S;

            elsif (dmaAck.done = '1') then
               v.dmaReq.request := '0';

               if (r.bsaCompleteTmp(conv_integer(r.rdBsaAddr)) = '1') then
                  v.bsaCompleteAxil(conv_integer(r.rdBsaAddr)) := '1';
                  v.bsaCompleteTmp(conv_integer(r.rdBsaAddr)) := '0';                  
               end if;

               v.addrRamWe := '1';

               v.lastAddr := r.lastAddr + dmaAck.size;
               if (v.lastAddr = r.endAddr) then
                  v.lastAddr := r.startAddr;
               end if;

               if (v.lastAddr = r.firstAddr) then
                  v.firstAddr := r.firstAddr + BSA_BUFFER_ENTRY_BYTES_C;
               end if;

               v.state := WAIT_TVALID_S;
            end if;
      end case;

      if (r.clearBsaBuffer = '1') then
--         v.nextAddr   := startRamDout;
         v.firstAddr  := startRamDout;
         v.lastAddr   := startRamDout;
         v.addrRamWe  := '1';
--          v.firstRamWe := '1';
--          v.lastRamWe  := '1';
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI-Lite bus for register access
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(locAxilWriteMasters(0), locAxilReadMasters(0), v.axilWriteSlave, v.axilReadSlave, axiStatus);

      --   Special logic for clear on read status registers
      if (axiStatus.readEnable = '1') then
         v.axilReadSlave.rdata := (others => '0');
         case (locAxilReadMasters(0).araddr(7 downto 0)) is
            when X"00" =>
               v.axilReadSlave.rdata      := r.bsaInitAxil(31 downto 0);
               v.bsaInitAxil(31 downto 0) := (others => '0');
            when X"04" =>
               v.axilReadSlave.rdata       := r.bsaInitAxil(63 downto 32);
               v.bsaInitAxil(63 downto 32) := (others => '0');
            when X"08" =>
               v.axilReadSlave.rdata          := r.bsaCompleteAxil(31 downto 0);
               v.bsaCompleteAxil(31 downto 0) := (others => '0');
            when X"0C" =>
               v.axilReadSlave.rdata           := r.bsaCompleteAxil(63 downto 32);
               v.bsaCompleteAxil(63 downto 32) := (others => '0');
            when X"10" =>
               v.axilReadSlave.rdata(0) := r.ramAddr32;
            when others => null;
         end case;
         axiSlaveReadResponse(v.axilReadSlave, AXI_RESP_OK_C);
      end if;

      if (axiStatus.writeEnable = '1') then
         if (locAxilWriteMasters(0).awaddr(7 downto 0) = X"10") then
            v.ramAddr32 := locAxilWriteMasters(0).wdata(0);
--          elsif (locAxilWriteMasters(0).awaddr(7 downto 0) = X"14") then
--             v.bsaAddr        := locAxilWriteMasters(0).wdata(BSA_ADDR_BITS_C-1 downto 0);
--             v.clearBsaBuffer := '1';
--             if (r.state = WAIT_TVALID_S) then
--                v.state := WAIT_TVALID_S;  -- Override state machine to to clear
--             end if;
         end if;
         axiSlaveWriteResponse(v.axilWriteSlave, AXI_RESP_OK_C);
      end if;






      ----------------------------------------------------------------------------------------------
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      locAxilWriteSlaves(0) <= r.axilWriteSlave;
      locAxilReadSlaves(0)  <= r.axilReadSlave;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

