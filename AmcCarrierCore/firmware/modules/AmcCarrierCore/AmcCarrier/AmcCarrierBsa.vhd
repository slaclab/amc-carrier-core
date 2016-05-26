-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsa.vhd
-- Author     : Benjamin Reese <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2016-05-26
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;

entity AmcCarrierBsa is
   generic (
      TPD_G                    : time                  := 1 ns;
      FSBL_G                   : boolean               := false;
      APP_TYPE_G               : AppType               := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G         : slv(1 downto 0)       := AXI_RESP_DECERR_C;
      BSA_BUFFERS_G            : integer range 1 to 64 := 64;
      DIAGNOSTIC_OUTPUTS_G     : integer range 1 to 32 := 28;
      DIAGNOSTIC_RAW_STREAMS_G : positive              := 4;
      DIAGNOSTIC_RAW_CONFIGS_G : AxiStreamConfigArray  := (0 => ssiAxiStreamConfig(4),
                                                          1  => ssiAxiStreamConfig(4),
                                                          2  => ssiAxiStreamConfig(4),
                                                          3  => ssiAxiStreamConfig(4)));
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType;
      -- AXI4 Interface (axiClk domain)
      axiClk               : in  sl;
      axiRst               : in  sl;
      axiWriteMaster       : out AxiWriteMasterType;
      axiWriteSlave        : in  AxiWriteSlaveType;
      axiReadMaster        : out AxiReadMasterType;
      axiReadSlave         : in  AxiReadSlaveType;
      -- Ethernet Interface (axilClk domain)
      obBsaMasters         : out AxiStreamMasterArray(3 downto 0);
      obBsaSlaves          : in  AxiStreamSlaveArray(3 downto 0);
      ibBsaMasters         : in  AxiStreamMasterArray(3 downto 0);
      ibBsaSlaves          : out AxiStreamSlaveArray(3 downto 0);
      -- BSA Interface (bsaTimingClk domain)
      -- Unused
      bsaTimingClk         : in  sl;
      bsaTimingRst         : in  sl;
      bsaTimingBus         : in  TimingBusType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Diagnostic Interface
      diagnosticClk        : in  sl;
      diagnosticRst        : in  sl;
      diagnosticBus        : in  DiagnosticBusType;
      diagnosticRawClks    : in  slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawRsts    : in  slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawMasters : in  AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawSlaves  : out AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawCtrl    : out AxiStreamCtrlArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0));

end AmcCarrierBsa;

architecture mapping of AmcCarrierBsa is

   -------------------------------------------------------------------------------------------------
   -- AXI Lite
   -------------------------------------------------------------------------------------------------
   constant AXIL_MASTERS_C : integer := 2;

   constant BSA_BUFFER_AXIL_C     : integer := 0;
   constant RAW_DIAGNOSTIC_AXIL_C : integer := 1;

   constant AXIL_CROSSBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_MASTERS_C-1 downto 0) :=
      genAxiLiteConfig(AXIL_MASTERS_C, BSA_ADDR_C, 20, 16);

   signal mAxilWriteMaster : AxiLiteWriteMasterType;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal mAxilReadMaster  : AxiLiteReadMasterType;
   signal mAxilReadSlave   : AxiLiteReadSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);



   signal diagAxisMaster : AxiStreamMasterType;
   signal diagAxisSlave  : AxiStreamSlaveType;

   -------------------------------------------------------------------------------------------------
   -- AXI4
   -------------------------------------------------------------------------------------------------
   constant DIAG_AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 33,
      DATA_BYTES_C => 16,  -- needs to be 64 bits wide or 2kbyte BSA buffer bursts get split
      ID_BITS_C    => 1,
      LEN_BITS_C   => 8);

   -- Bsa buffer write word size should be configurable
   constant BSA_AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 33,
      DATA_BYTES_C => 16,  -- needs to be 64 bits wide or 2kbyte BSA buffer bursts get split
      ID_BITS_C    => 1,
      LEN_BITS_C   => 8);

   -- Mem read word size is 32 bits
   constant MEM_AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 33,
      DATA_BYTES_C => 4,
      ID_BITS_C    => 1,
      LEN_BITS_C   => 8);


   -- AXI busses to interconnect
   signal bsaAxiWriteMaster  : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal bsaAxiWriteSlave   : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal bsaAxiReadSlave    : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
   signal memAxiReadMaster   : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal memAxiReadSlave    : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
   signal memAxiWriteMaster  : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal memAxiWriteSlave   : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal diagAxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal diagAxiWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal diagAxiReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal diagAxiReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

begin

   -- FSBL build has no BSA logic.
   FSBL_GEN : if (FSBL_G) generate
      U_AxiLiteEmpty_1 : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_RESP_OK_C)  -- Don't respond with error
         port map (
            axiClk         => axilClk,          -- [in]
            axiClkRst      => axilRst,          -- [in]
            axiReadMaster  => axilReadMaster,   -- [in]
            axiReadSlave   => axilReadSlave,    -- [out]
            axiWriteMaster => axilWriteMaster,  -- [in]
            axiWriteSlave  => axilWriteSlave);  -- [out]

      axiWriteMaster      <= AXI_WRITE_MASTER_INIT_C;
      axiReadMaster       <= AXI_READ_MASTER_INIT_C;
      obBsaMasters        <= (others => AXI_STREAM_MASTER_INIT_C);
      ibBsaSlaves         <= (others => AXI_STREAM_SLAVE_INIT_C);
      diagnosticRawSlaves <= (others => AXI_STREAM_SLAVE_INIT_C);
      diagnosticRawCtrl   <= (others => AXI_STREAM_CTRL_UNUSED_C);
   end generate FSBL_GEN;

   BSA_GEN : if (FSBL_G = false) generate

      U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            NUM_SLAVE_SLOTS_G  => 2,
            NUM_MASTER_SLOTS_G => AXIL_MASTERS_C,
            DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
            MASTERS_CONFIG_G   => AXIL_CROSSBAR_CONFIG_C,
            DEBUG_G            => true)
         port map (
            axiClk              => axilClk,              -- [in]
            axiClkRst           => axilRst,              -- [in]
            sAxiWriteMasters(0) => axilWriteMaster,      -- [in]
            sAxiWriteMasters(1) => mAxilWriteMaster,     -- [in]
            sAxiWriteSlaves(0)  => axilWriteSlave,       -- [out]
            sAxiWriteSlaves(1)  => mAxilWriteSlave,      -- [out]
            sAxiReadMasters(0)  => axilReadMaster,       -- [in]
            sAxiReadMasters(1)  => mAxilReadMaster,      -- [in]            
            sAxiReadSlaves(0)   => axilReadSlave,        -- [out]
            sAxiReadSlaves(1)   => mAxilReadSlave,       -- [out]            
            mAxiWriteMasters    => locAxilWriteMasters,  -- [out]
            mAxiWriteSlaves     => locAxilWriteSlaves,   -- [in]
            mAxiReadMasters     => locAxilReadMasters,   -- [out]
            mAxiReadSlaves      => locAxilReadSlaves);   -- [in]

      ------------------------------------------------------------------------------------------------
      -- Diagnostic Engine
      -- Create circular buffers in DDR Ram for dianostic data
      -- Async messages don't need to convert to wider bus width as long as they are only a single txn
      -- Packetizer will handle any width if it's a single txn frame.
      ------------------------------------------------------------------------------------------------
      ibBsaSlaves(BSA_DIAG_STATUS_AXIS_INDEX_C) <= AXI_STREAM_SLAVE_FORCE_C;     -- Upstream only.
      ibBsaSlaves(BSA_DIAG_DATA_AXIS_INDEX_C)   <= AXI_STREAM_SLAVE_FORCE_C;     -- Upstream only
      U_BsaRawDiagnostic_1 : entity work.BsaRawDiagnosticRing
         generic map (
            TPD_G                    => TPD_G,
            DIAGNOSTIC_RAW_STREAMS_G => DIAGNOSTIC_RAW_STREAMS_G,
            DIAGNOSTIC_RAW_CONFIGS_G => DIAGNOSTIC_RAW_CONFIGS_G,
            AXIL_BASE_ADDR_G         => AXIL_CROSSBAR_CONFIG_C(RAW_DIAGNOSTIC_AXIL_C).baseAddr,
            AXI_CONFIG_G             => DIAG_AXI_CONFIG_C)
         port map (
            diagnosticRawClks    => diagnosticRawClks,                           -- [in]
            diagnosticRawRsts    => diagnosticRawRsts,                           -- [in]
            diagnosticRawMasters => diagnosticRawMasters,                        -- [in]
            diagnosticRawSlaves  => diagnosticRawSlaves,                         -- [out]
            diagnosticRawCtrl    => diagnosticRawCtrl,                           -- [out]
            axilClk              => axilClk,                                     -- [in]
            axilRst              => axilRst,                                     -- [in]
            axilWriteMaster      => locAxilWriteMasters(RAW_DIAGNOSTIC_AXIL_C),  -- [out]
            axilWriteSlave       => locAxilWriteSlaves(RAW_DIAGNOSTIC_AXIL_C),   -- [in]
            axilReadMaster       => locAxilReadMasters(RAW_DIAGNOSTIC_AXIL_C),   -- [out]
            axilReadSlave        => locAxilReadSlaves(RAW_DIAGNOSTIC_AXIL_C),    -- [in]
            axisStatusClk        => axilClk,                                     -- [in]
            axisStatusRst        => axilRst,                                     -- [in]
            axisStatusMaster     => obBsaMasters(BSA_DIAG_STATUS_AXIS_INDEX_C),  -- [out]
            axisStatusSlave      => obBsaSlaves(BSA_DIAG_STATUS_AXIS_INDEX_C),   -- [in]
            axisDataClk          => axilClk,                                     -- [in]
            axisDataRst          => axilRst,                                     -- [in]
            axisDataMaster       => obBsaMasters(BSA_DIAG_DATA_AXIS_INDEX_C),    -- [out]
            axisDataSlave        => obBsaSlaves(BSA_DIAG_DATA_AXIS_INDEX_C),     -- [in]
            axiClk               => axiClk,                                      -- [in]
            axiRst               => axiRst,                                      -- [in]
            axiWriteMaster       => diagAxiWriteMaster,                          -- [out]
            axiWriteSlave        => diagAxiWriteSlave,                           -- [in]
            axiReadMaster        => diagAxiReadMaster,                           -- [out]
            axiReadSlave         => diagAxiReadSlave);                           -- [in]


      -------------------------------------------------------------------------------------------------
      -- BSA buffers
      -------------------------------------------------------------------------------------------------
      ibBsaSlaves(BSA_BSA_STATUS_AXIS_INDEX_C) <= AXI_STREAM_SLAVE_FORCE_C;
      BsaBufferControl_1 : entity work.BsaBufferControl
         generic map (
            TPD_G                   => TPD_G,
            AXIL_BASE_ADDR_G        => AXIL_CROSSBAR_CONFIG_C(BSA_BUFFER_AXIL_C).baseAddr,
            BSA_BUFFERS_G           => BSA_BUFFERS_G,
            BSA_STREAM_BYTE_WIDTH_G => 8,
            DIAGNOSTIC_OUTPUTS_G    => DIAGNOSTIC_OUTPUTS_G,
            BSA_BURST_BYTES_G       => 2048,  -- explore 4096
            AXI_CONFIG_G            => BSA_AXI_CONFIG_C)
         port map (
            axilClk          => axilClk,
            axilRst          => axilRst,
            axilReadMaster   => locAxilReadMasters(BSA_BUFFER_AXIL_C),
            axilReadSlave    => locAxilReadSlaves(BSA_BUFFER_AXIL_C),
            axilWriteMaster  => locAxilWriteMasters(BSA_BUFFER_AXIL_C),
            axilWriteSlave   => locAxilWriteSlaves(BSA_BUFFER_AXIL_C),
            diagnosticClk    => diagnosticClk,
            diagnosticRst    => diagnosticRst,
            diagnosticBus    => diagnosticBus,
            axisStatusClk    => axilClk,
            axisStatusRst    => axilRst,
            axisStatusMaster => obBsaMasters(BSA_BSA_STATUS_AXIS_INDEX_C),
            axisStatusSlave  => obBsaSlaves(BSA_BSA_STATUS_AXIS_INDEX_C),
            axiClk           => axiClk,
            axiRst           => axiRst,
            axiWriteMaster   => bsaAxiWriteMaster,
            axiWriteSlave    => bsaAxiWriteSlave);

      -----------------------------------------------------------------------------------------------
      -- Mem Read engine
      -----------------------------------------------------------------------------------------------
      U_SrpV3Axi_1 : entity work.SrpV3Axi
         generic map (
            TPD_G               => TPD_G,
            PIPE_STAGES_G       => 1,
            FIFO_PAUSE_THRESH_G => 128,
            SLAVE_READY_EN_G    => true,
            GEN_SYNC_FIFO_G     => false,
            AXI_CLK_FREQ_G      => 200.0E+6,
            AXI_CONFIG_G        => MEM_AXI_CONFIG_C,
--          AXI_BURST_G         => AXI_BURST_G,
--          AXI_CACHE_G         => AXI_CACHE_G,
            ACK_WAIT_BVALID_G   => false,
            AXI_STREAM_CONFIG_G => ETH_AXIS_CONFIG_C,
            UNALIGNED_ACCESS_G  => false,
            BYTE_ACCESS_G       => false,
            WRITE_EN_G          => false,
            READ_EN_G           => true)
         port map (
            sAxisClk       => axilClk,                             -- [in]
            sAxisRst       => axilRst,                             -- [in]
            sAxisMaster    => ibBsaMasters(BSA_MEM_AXIS_INDEX_C),  -- [in]
            sAxisSlave     => ibBsaSlaves(BSA_MEM_AXIS_INDEX_C),   -- [out]
            sAxisCtrl      => open,                                -- [out]
            mAxisClk       => axilClk,                             -- [in]
            mAxisRst       => axilRst,                             -- [in]
            mAxisMaster    => obBsaMasters(BSA_MEM_AXIS_INDEX_C),  -- [out]
            mAxisSlave     => obBsaSlaves(BSA_MEM_AXIS_INDEX_C),   -- [in]
            axiClk         => axiClk,                              -- [in]
            axiRst         => axiRst,                              -- [in]
            axiWriteMaster => memAxiWriteMaster,                   -- [out]
            axiWriteSlave  => memAxiWriteSlave,                    -- [in]
            axiReadMaster  => memAxiReadMaster,                    -- [out]
            axiReadSlave   => memAxiReadSlave);                    -- [in]

      ------------------------------------------------------------------------------------------------
      -- Axi Interconnect
      -- Mux AXI busses, resize to 512 wide data words, buffer bursts
      ------------------------------------------------------------------------------------------------
      U_BsaAxiInterconnectWrapper_1 : entity work.BsaAxiInterconnectWrapper
         port map (
            axiClk              => axiClk,                  -- [in]
            axiRst              => axiRst,                  -- [in]
            sAxiWriteMasters(0) => memAxiWriteMaster,       -- [in]
            sAxiWriteMasters(1) => bsaAxiWriteMaster,       -- [in]
            sAxiWriteMasters(2) => diagAxiWriteMaster,      -- [in]
            sAxiWriteSlaves(0)  => memAxiWriteSlave,        -- [out]
            sAxiWriteSlaves(1)  => bsaAxiWriteSlave,        -- [out]
            sAxiWriteSlaves(2)  => diagAxiWriteSlave,       -- [out]
            sAxiReadMasters(0)  => memAxiReadMaster,        -- [in]
            sAxiReadMasters(1)  => AXI_READ_MASTER_INIT_C,  -- [in]         
            sAxiReadMasters(2)  => diagAxiReadMaster,
            sAxiReadSlaves(0)   => memAxiReadSlave,         -- [out]
            sAxiReadSlaves(1)   => bsaAxiReadSlave,         -- [out]         
            sAxiReadSlaves(2)   => diagAxiReadSlave,
            mAxiWriteMasters    => axiWriteMaster,          -- [out]
            mAxiWriteSlaves     => axiWriteSlave,           -- [in]
            mAxiReadMasters     => axiReadMaster,           -- [out]
            mAxiReadSlaves      => axiReadSlave);           -- [in]

   end generate BSA_GEN;

end mapping;
