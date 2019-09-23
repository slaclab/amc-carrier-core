-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsa.vhd
-- Author     : Benjamin Reese <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2019-09-12
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
use work.AmcCarrierSysRegPkg.all;

entity AmcCarrierBsa is
   generic (
      TPD_G                  : time                   := 1 ns;
      FSBL_G                 : boolean                := false;
      DISABLE_BSA_G          : boolean                := false;
      DISABLE_BLD_G          : boolean                := false;
      DISABLE_DDR_SRP_G      : boolean                := false;
      WAVEFORM_NUM_LANES_G   : positive range 1 to 4  := 4;  -- Number of Waveform lanes per DaqMuxV2
      WAVEFORM_TDATA_BYTES_G : positive range 4 to 16 := 4);  -- Waveform stream's tData width (in units of bytes)      
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- AXI4 Interface (axiClk domain)
      axiClk          : in  sl;
      axiRst          : in  sl;
      axiWriteMaster  : out AxiWriteMasterType;
      axiWriteSlave   : in  AxiWriteSlaveType;
      axiReadMaster   : out AxiReadMasterType;
      axiReadSlave    : in  AxiReadSlaveType;
      -- Ethernet Interface (axilClk domain)
      obBsaMasters    : out AxiStreamMasterArray(3 downto 0);
      obBsaSlaves     : in  AxiStreamSlaveArray(3 downto 0);
      ibBsaMasters    : in  AxiStreamMasterArray(3 downto 0);
      ibBsaSlaves     : out AxiStreamSlaveArray(3 downto 0);
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- BSA Diagnostic Interface
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;

      -- Waveform interface
      waveformClk          : in  sl;
      waveformRst          : in  sl;
      obAppWaveformMasters : in  WaveformMasterArrayType;
      obAppWaveformSlaves  : out WaveformSlaveArrayType;

      -- Timing ETH MSG Interface (axilClk domain)
      ibEthMsgMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      ibEthMsgSlave  : out AxiStreamSlaveType;
      obEthMsgMaster : out AxiStreamMasterType;
      obEthMsgSlave  : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C);


end AmcCarrierBsa;

architecture mapping of AmcCarrierBsa is

   constant ROUTE0_C : slv(7 downto 0) :=
      slvAll(7-log2(WaveformMasterType'length), '0') &
      '0' &
      slvAll(log2(WaveformMasterType'length), '-');

   constant ROUTE1_C : slv(7 downto 0) :=
      slvAll(7-log2(WaveformMasterType'length), '0') &
      '1' &
      slvAll(log2(WaveformMasterType'length), '-');



   -------------------------------------------------------------------------------------------------
   -- AXI Lite
   -------------------------------------------------------------------------------------------------
   constant AXIL_MASTERS_C : integer := ite(DISABLE_BLD_G, 3, 4);

   constant BSA_BUFFER_AXIL_C : integer := 0;
   constant WAVEFORM_0_AXIL_C : integer := 1;
   constant WAVEFORM_1_AXIL_C : integer := 2;
   constant BLD_AXIL_C        : integer := 3;

   constant AXIL_CROSSBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_MASTERS_C-1 downto 0) :=
      genAxiLiteConfig(AXIL_MASTERS_C, BSA_ADDR_C, 20, 16);

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);


   -------------------------------------------------------------------------------------------------
   -- Axi Streams
   -------------------------------------------------------------------------------------------------
   signal waveformStatusMasters : AxiStreamMasterArray(1 downto 0);
   signal waveformStatusSlaves  : AxiStreamSlaveArray(1 downto 0);
   signal waveformDataMasters   : AxiStreamMasterArray(1 downto 0);
   signal waveformDataSlaves    : AxiStreamSlaveArray(1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AXI4
   -------------------------------------------------------------------------------------------------
   constant WAVEFORM_AXI_CONFIG_C : AxiConfigType := (
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
   signal bsaAxiWriteMaster       : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal bsaAxiWriteSlave        : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal bsaAxiReadSlave         : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
   signal memAxiReadMaster        : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal memAxiReadSlave         : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
   signal memAxiWriteMaster       : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal memAxiWriteSlave        : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal waveform0AxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal waveform0AxiWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal waveform0AxiReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal waveform0AxiReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
   signal waveform1AxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal waveform1AxiWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal waveform1AxiReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal waveform1AxiReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

   signal intEthMsgMaster : AxiStreamMasterType;
   signal intEthMsgSlave  : AxiStreamSlaveType;

begin

   -- FSBL build has no BSA logic.
   FSBL_GEN : if (FSBL_G) generate
      axilReadSlave       <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
      axilWriteSlave      <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;
      axiWriteMaster      <= AXI_WRITE_MASTER_INIT_C;
      axiReadMaster       <= AXI_READ_MASTER_INIT_C;
      obBsaMasters        <= (others => AXI_STREAM_MASTER_INIT_C);
      ibBsaSlaves         <= (others => AXI_STREAM_SLAVE_INIT_C);
      obAppWaveformSlaves <= WAVEFORM_SLAVE_ARRAY_INIT_C;
   end generate FSBL_GEN;

   BSA_GEN : if (FSBL_G = false) generate

      U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
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

      ------------------------------------------------------------------------------------------------
      -- Waveform Engine
      -- Create circular buffers in DDR Ram for dianostic data
      -- Async messages don't need to convert to wider bus width as long as they are only a single txn
      -- Packetizer will handle any width if it's a single txn frame.
      ------------------------------------------------------------------------------------------------
      ibBsaSlaves(BSA_WAVEFORM_STATUS_AXIS_INDEX_C) <= AXI_STREAM_SLAVE_FORCE_C;  -- Upstream only.
      ibBsaSlaves(BSA_WAVEFORM_DATA_AXIS_INDEX_C)   <= AXI_STREAM_SLAVE_FORCE_C;  -- Upstream only
      BsaWaveformEngine_0 : entity work.BsaWaveformEngine
         generic map (
            TPD_G                  => TPD_G,
            WAVEFORM_NUM_LANES_G   => WAVEFORM_NUM_LANES_G,
            WAVEFORM_TDATA_BYTES_G => WAVEFORM_TDATA_BYTES_G,
            AXIL_BASE_ADDR_G       => AXIL_CROSSBAR_CONFIG_C(WAVEFORM_0_AXIL_C).baseAddr,
            AXI_CONFIG_G           => WAVEFORM_AXI_CONFIG_C)
         port map (
            waveformClk       => waveformClk,
            waveformRst       => waveformRst,
            ibWaveformMasters => obAppWaveformMasters(0),   -- [in]
            ibWaveformSlaves  => obAppWaveformSlaves(0),    -- [out]
            axilClk           => axilClk,                   -- [in]
            axilRst           => axilRst,                   -- [in]
            axilWriteMaster   => locAxilWriteMasters(WAVEFORM_0_AXIL_C),  -- [out]
            axilWriteSlave    => locAxilWriteSlaves(WAVEFORM_0_AXIL_C),  -- [in]
            axilReadMaster    => locAxilReadMasters(WAVEFORM_0_AXIL_C),  -- [out]
            axilReadSlave     => locAxilReadSlaves(WAVEFORM_0_AXIL_C),  -- [in]
            axisStatusClk     => axilClk,                   -- [in]
            axisStatusRst     => axilRst,                   -- [in]
            axisStatusMaster  => waveformStatusMasters(0),  -- [out]
            axisStatusSlave   => waveformStatusSlaves(0),   -- [in]
            axisDataClk       => axilClk,                   -- [in]
            axisDataRst       => axilRst,                   -- [in]
            axisDataMaster    => waveformDataMasters(0),    -- [out]
            axisDataSlave     => waveformDataSlaves(0),     -- [in]
            axiClk            => axiClk,                    -- [in]
            axiRst            => axiRst,                    -- [in]
            axiWriteMaster    => waveform0AxiWriteMaster,   -- [out]
            axiWriteSlave     => waveform0AxiWriteSlave,    -- [in]
            axiReadMaster     => waveform0AxiReadMaster,    -- [out]
            axiReadSlave      => waveform0AxiReadSlave);    -- [in]

      BsaWaveformEngine_1 : entity work.BsaWaveformEngine
         generic map (
            TPD_G                  => TPD_G,
            WAVEFORM_NUM_LANES_G   => WAVEFORM_NUM_LANES_G,
            WAVEFORM_TDATA_BYTES_G => WAVEFORM_TDATA_BYTES_G,
            AXIL_BASE_ADDR_G       => AXIL_CROSSBAR_CONFIG_C(WAVEFORM_1_AXIL_C).baseAddr,
            AXI_CONFIG_G           => WAVEFORM_AXI_CONFIG_C)
         port map (
            waveformClk       => waveformClk,
            waveformRst       => waveformRst,
            ibWaveformMasters => obAppWaveformMasters(1),   -- [in]
            ibWaveformSlaves  => obAppWaveformSlaves(1),    -- [out]
            axilClk           => axilClk,                   -- [in]
            axilRst           => axilRst,                   -- [in]
            axilWriteMaster   => locAxilWriteMasters(WAVEFORM_1_AXIL_C),  -- [out]
            axilWriteSlave    => locAxilWriteSlaves(WAVEFORM_1_AXIL_C),  -- [in]
            axilReadMaster    => locAxilReadMasters(WAVEFORM_1_AXIL_C),  -- [out]
            axilReadSlave     => locAxilReadSlaves(WAVEFORM_1_AXIL_C),  -- [in]
            axisStatusClk     => axilClk,                   -- [in]
            axisStatusRst     => axilRst,                   -- [in]
            axisStatusMaster  => waveformStatusMasters(1),  -- [out]
            axisStatusSlave   => waveformStatusSlaves(1),   -- [in]
            axisDataClk       => axilClk,                   -- [in]
            axisDataRst       => axilRst,                   -- [in]
            axisDataMaster    => waveformDataMasters(1),    -- [out]
            axisDataSlave     => waveformDataSlaves(1),     -- [in]
            axiClk            => axiClk,                    -- [in]
            axiRst            => axiRst,                    -- [in]
            axiWriteMaster    => waveform1AxiWriteMaster,   -- [out]
            axiWriteSlave     => waveform1AxiWriteSlave,    -- [in]
            axiReadMaster     => waveform1AxiReadMaster,    -- [out]
            axiReadSlave      => waveform1AxiReadSlave);    -- [in]

      U_AxiStreamMux_WaveformStatus : entity work.AxiStreamMux
         generic map (
            TPD_G          => TPD_G,
            NUM_SLAVES_G   => 2,
            MODE_G         => "ROUTED",
            TDEST_ROUTES_G => (
               0           => ROUTE0_C,
               1           => ROUTE1_C),
            PIPE_STAGES_G  => 1,
            TDEST_LOW_G    => 0)
         port map (
            sAxisMasters => waveformStatusMasters,  -- [in]
            sAxisSlaves  => waveformStatusSlaves,   -- [out]
            mAxisMaster  => obBsaMasters(BSA_WAVEFORM_STATUS_AXIS_INDEX_C),  -- [out]
            mAxisSlave   => obBsaSlaves(BSA_WAVEFORM_STATUS_AXIS_INDEX_C),  -- [in]
            axisClk      => axilClk,    -- [in]
            axisRst      => axilRst);   -- [in]

      U_AxiStreamMux_WaveformData : entity work.AxiStreamMux
         generic map (
            TPD_G          => TPD_G,
            NUM_SLAVES_G   => 2,
            MODE_G         => "ROUTED",
            TDEST_ROUTES_G => (
               0           => ROUTE0_C,
               1           => ROUTE1_C),
            PIPE_STAGES_G  => 1,
            TDEST_LOW_G    => 0)
         port map (
            sAxisMasters => waveformDataMasters,  -- [in]
            sAxisSlaves  => waveformDataSlaves,   -- [out]
            mAxisMaster  => obBsaMasters(BSA_WAVEFORM_DATA_AXIS_INDEX_C),  -- [out]
            mAxisSlave   => obBsaSlaves(BSA_WAVEFORM_DATA_AXIS_INDEX_C),  -- [in]
            axisClk      => axilClk,    -- [in]
            axisRst      => axilRst);   -- [in]

      -------------------------------------------------------------------------------------------------
      -- BSA buffers
      -------------------------------------------------------------------------------------------------
      ibBsaSlaves(BSA_BSA_STATUS_AXIS_INDEX_C) <= AXI_STREAM_SLAVE_FORCE_C;
      BSA_EN_GEN : if (DISABLE_BSA_G = false) generate
         BsaBufferControl_1 : entity work.BsaBufferControl
            generic map (
               TPD_G                   => TPD_G,
               AXIL_BASE_ADDR_G        => AXIL_CROSSBAR_CONFIG_C(BSA_BUFFER_AXIL_C).baseAddr,
               BSA_BUFFERS_G           => BSA_BUFFERS_C,
               BSA_STREAM_BYTE_WIDTH_G => BSA_STREAM_BYTE_WIDTH_C,
               DIAGNOSTIC_OUTPUTS_G    => BSA_DIAGNOSTIC_OUTPUTS_C,
               BSA_BURST_BYTES_G       => BSA_BURST_BYTES_C,  -- explore 4096
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
      end generate BSA_EN_GEN;

      BSA_DISABLE_GEN : if (DISABLE_BSA_G) generate
         locAxilReadSlaves(BSA_BUFFER_AXIL_C)      <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
         locAxilWriteSlaves(BSA_BUFFER_AXIL_C)     <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;
         bsaAxiWriteMaster                         <= AXI_WRITE_MASTER_INIT_C;
         obBsaMasters(BSA_BSA_STATUS_AXIS_INDEX_C) <= AXI_STREAM_MASTER_INIT_C;
      end generate BSA_DISABLE_GEN;

--      -----------------------------------------------------------------------------------------------
--      -- Mem Read engine
--      -----------------------------------------------------------------------------------------------
      GEN_EN_SRP : if (DISABLE_DDR_SRP_G = false) generate
         U_SrpV3Axi_1 : entity work.SrpV3Axi
            generic map (
               TPD_G               => TPD_G,
               PIPE_STAGES_G       => 1,
               FIFO_PAUSE_THRESH_G => 128,
               TX_VALID_THOLD_G    => 256,  -- Pre-cache threshold set 256 out of 512 (prevent holding the ETH link during AXI-lite transactions)
               SLAVE_READY_EN_G    => true,
               GEN_SYNC_FIFO_G     => false,
               AXI_CLK_FREQ_G      => 200.0E+6,
               AXI_CONFIG_G        => MEM_AXI_CONFIG_C,
               --          AXI_BURST_G         => AXI_BURST_G,
               --          AXI_CACHE_G         => AXI_CACHE_G,
               ACK_WAIT_BVALID_G   => false,
               AXI_STREAM_CONFIG_G => AXIS_8BYTE_CONFIG_C,
               UNALIGNED_ACCESS_G  => false,
               BYTE_ACCESS_G       => false,
               WRITE_EN_G          => true,
               READ_EN_G           => true)
            port map (
               sAxisClk       => axilClk,   -- [in]
               sAxisRst       => axilRst,   -- [in]
               sAxisMaster    => ibBsaMasters(BSA_MEM_AXIS_INDEX_C),  -- [in]
               sAxisSlave     => ibBsaSlaves(BSA_MEM_AXIS_INDEX_C),   -- [out]
               sAxisCtrl      => open,  -- [out]
               mAxisClk       => axilClk,   -- [in]
               mAxisRst       => axilRst,   -- [in]
               mAxisMaster    => obBsaMasters(BSA_MEM_AXIS_INDEX_C),  -- [out]
               mAxisSlave     => obBsaSlaves(BSA_MEM_AXIS_INDEX_C),   -- [in]
               axiClk         => axiClk,    -- [in]
               axiRst         => axiRst,    -- [in]
               axiWriteMaster => memAxiWriteMaster,                   -- [out]
               axiWriteSlave  => memAxiWriteSlave,                    -- [in]
               axiReadMaster  => memAxiReadMaster,                    -- [out]
               axiReadSlave   => memAxiReadSlave);                    -- [in]
      end generate GEN_EN_SRP;

      GEN_DIS_SRP : if (DISABLE_DDR_SRP_G = true) generate
         ibBsaSlaves(BSA_MEM_AXIS_INDEX_C)  <= AXI_STREAM_SLAVE_FORCE_C;
         obBsaMasters(BSA_MEM_AXIS_INDEX_C) <= AXI_STREAM_MASTER_INIT_C;
         memAxiWriteMaster                  <= AXI_WRITE_MASTER_INIT_C;
         memAxiReadMaster                   <= AXI_READ_MASTER_INIT_C;
      end generate GEN_DIS_SRP;

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
            sAxiWriteMasters(2) => waveform0AxiWriteMaster,  -- [in]
            sAxiWriteMasters(3) => waveform1AxiWriteMaster,  -- [in]            
            sAxiWriteSlaves(0)  => memAxiWriteSlave,        -- [out]
            sAxiWriteSlaves(1)  => bsaAxiWriteSlave,        -- [out]
            sAxiWriteSlaves(2)  => waveform0AxiWriteSlave,  -- [out]
            sAxiWriteSlaves(3)  => waveform1AxiWriteSlave,  -- [out]            
            sAxiReadMasters(0)  => memAxiReadMaster,        -- [in]
            sAxiReadMasters(1)  => AXI_READ_MASTER_INIT_C,  -- [in]         
            sAxiReadMasters(2)  => waveform0AxiReadMaster,  -- [in]
            sAxiReadMasters(3)  => waveform1AxiReadMaster,  -- [in]
            sAxiReadSlaves(0)   => memAxiReadSlave,         -- [out]
            sAxiReadSlaves(1)   => bsaAxiReadSlave,         -- [out]         
            sAxiReadSlaves(2)   => waveform0AxiReadSlave,   -- [out]         
            sAxiReadSlaves(3)   => waveform1AxiReadSlave,   -- [out]         
            mAxiWriteMasters    => axiWriteMaster,          -- [out]
            mAxiWriteSlaves     => axiWriteSlave,           -- [in]
            mAxiReadMasters     => axiReadMaster,           -- [out]
            mAxiReadSlaves      => axiReadSlave);           -- [in]

   end generate BSA_GEN;

   BLD_ENABLE_GEN : if not DISABLE_BLD_G generate
      U_BLD : entity work.BldAxiStream
         generic map (
            TPD_G => TPD_G)
         port map (
            -- Diagnostic data interface
            diagnosticClk   => diagnosticClk,
            diagnosticRst   => diagnosticRst,
            diagnosticBus   => diagnosticBus,
            -- AXI Lite interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => locAxilReadMasters (BLD_AXIL_C),
            axilReadSlave   => locAxilReadSlaves (BLD_AXIL_C),
            axilWriteMaster => locAxilWriteMasters(BLD_AXIL_C),
            axilWriteSlave  => locAxilWriteSlaves (BLD_AXIL_C),
            -- Timing ETH MSG Interface (axilClk domain)
            ibEthMsgMaster  => ibEthMsgMaster,
            ibEthMsgSlave   => ibEthMsgSlave,
            obEthMsgMaster  => obEthMsgMaster,
            obEthMsgSlave   => obEthMsgSlave);
   end generate;

   BLD_DISABLE_GEN : if DISABLE_BLD_G generate
      obEthMsgMaster <= ibEthMsgMaster;
      ibEthMsgSlave  <= obEthMsgSlave;
   end generate;

end mapping;
