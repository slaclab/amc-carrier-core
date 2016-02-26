-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaRawDiagnostic.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
--              Uros Legat <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-12
-- Last update: 2016-02-26
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
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.SsiPkg.all;

entity BsaRawDiagnostic is

   generic (
      TPD_G                    : time                  := 1 ns;
      DIAGNOSTIC_RAW_STREAMS_G : positive range 1 to 8 := 1;
      DIAGNOSTIC_RAW_CONFIGS_G : AxiStreamConfigArray  := (0 => ssiAxiStreamConfig(4));
      OUTPUT_CONFIG_G          : AxiStreamConfigType   := ssiAxiStreamConfig(16)
      );
   port (
      diagnosticRawClks    : in  slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawRsts    : in  slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawMasters : in  AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawSlaves  : out AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawCtrl    : out AxiStreamCtrlArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      axiClk               : in  sl;
      axiRst               : in  sl;
      axiWriteMaster       : out AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
      axiWriteSlave        : in  AxiWriteSlaveType := AXI_WRITE_SLAVE_INIT_C;
      axiReadMaster        : out AxiReadMasterType := AXI_READ_MASTER_INIT_C;
      axiReadSlave         : in  AxiReadSlaveType := AXI_READ_SLAVE_INIT_C;
      bufClk               : in  sl;
      bufRst               : in  sl;
      bufMaster            : out AxiStreamMasterType;
      bufSlave             : in  AxiStreamSlaveType);

end entity BsaRawDiagnostic;

architecture rtl of BsaRawDiagnostic is

   constant INTERNAL_AXI_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => 3,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   signal axiRstL : sl;

   signal idle : slv(7 downto 0);
   signal full : slv(7 downto 0);

   -- Mux in 
   signal muxInAxisMaster : AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
   signal muxInAxisSlave  : AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);

   -- Mux out    
   signal muxOutAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal muxOutAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- SOF IO
   signal vFifoOutAxisMaster  : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal vFifoOutAxisSlave   : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal sofInAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal sofInAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal sofOutAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal sofOutAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal sofOutAxisCtrl   : AxiStreamCtrlType   := AXI_STREAM_CTRL_INIT_C;

   component AxiStreamDdrFifo
      port (
         aclk                     : in  std_logic;
         aresetn                  : in  std_logic;
         s_axis_tvalid            : in  std_logic;
         s_axis_tready            : out std_logic;
         s_axis_tdata             : in  std_logic_vector(127 downto 0);
         s_axis_tstrb             : in  std_logic_vector(15 downto 0);
         s_axis_tkeep             : in  std_logic_vector(15 downto 0);
         s_axis_tlast             : in  std_logic;
         s_axis_tid               : in  std_logic_vector(2 downto 0);
         s_axis_tdest             : in  std_logic_vector(2 downto 0);
         m_axis_tvalid            : out std_logic;
         m_axis_tready            : in  std_logic;
         m_axis_tdata             : out std_logic_vector(127 downto 0);
         m_axis_tstrb             : out std_logic_vector(15 downto 0);
         m_axis_tkeep             : out std_logic_vector(15 downto 0);
         m_axis_tlast             : out std_logic;
         m_axis_tid               : out std_logic_vector(2 downto 0);
         m_axis_tdest             : out std_logic_vector(2 downto 0);
         m_axi_awid               : out std_logic_vector(2 downto 0);
         m_axi_awaddr             : out std_logic_vector(31 downto 0);
         m_axi_awlen              : out std_logic_vector(7 downto 0);
         m_axi_awsize             : out std_logic_vector(2 downto 0);
         m_axi_awburst            : out std_logic_vector(1 downto 0);
         m_axi_awlock             : out std_logic_vector(0 downto 0);
         m_axi_awcache            : out std_logic_vector(3 downto 0);
         m_axi_awprot             : out std_logic_vector(2 downto 0);
         m_axi_awqos              : out std_logic_vector(3 downto 0);
         m_axi_awregion           : out std_logic_vector(3 downto 0);
         m_axi_awuser             : out std_logic_vector(0 downto 0);
         m_axi_awvalid            : out std_logic;
         m_axi_awready            : in  std_logic;
         m_axi_wdata              : out std_logic_vector(127 downto 0);
         m_axi_wstrb              : out std_logic_vector(15 downto 0);
         m_axi_wlast              : out std_logic;
         m_axi_wuser              : out std_logic_vector(0 downto 0);
         m_axi_wvalid             : out std_logic;
         m_axi_wready             : in  std_logic;
         m_axi_bid                : in  std_logic_vector(2 downto 0);
         m_axi_bresp              : in  std_logic_vector(1 downto 0);
         m_axi_buser              : in  std_logic_vector(0 downto 0);
         m_axi_bvalid             : in  std_logic;
         m_axi_bready             : out std_logic;
         m_axi_arid               : out std_logic_vector(2 downto 0);
         m_axi_araddr             : out std_logic_vector(31 downto 0);
         m_axi_arlen              : out std_logic_vector(7 downto 0);
         m_axi_arsize             : out std_logic_vector(2 downto 0);
         m_axi_arburst            : out std_logic_vector(1 downto 0);
         m_axi_arlock             : out std_logic_vector(0 downto 0);
         m_axi_arcache            : out std_logic_vector(3 downto 0);
         m_axi_arprot             : out std_logic_vector(2 downto 0);
         m_axi_arqos              : out std_logic_vector(3 downto 0);
         m_axi_arregion           : out std_logic_vector(3 downto 0);
         m_axi_aruser             : out std_logic_vector(0 downto 0);
         m_axi_arvalid            : out std_logic;
         m_axi_arready            : in  std_logic;
         m_axi_rid                : in  std_logic_vector(2 downto 0);
         m_axi_rdata              : in  std_logic_vector(127 downto 0);
         m_axi_rresp              : in  std_logic_vector(1 downto 0);
         m_axi_rlast              : in  std_logic;
         m_axi_ruser              : in  std_logic_vector(0 downto 0);
         m_axi_rvalid             : in  std_logic;
         m_axi_rready             : out std_logic;
         vfifo_mm2s_channel_full  : in  std_logic_vector(7 downto 0);
         vfifo_s2mm_channel_full  : out std_logic_vector(7 downto 0);
         vfifo_mm2s_channel_empty : out std_logic_vector(7 downto 0);
         vfifo_idle               : out std_logic_vector(7 downto 0)
         );
   end component;

begin

   -- Input fifos
   -- These should probably be 4k deep for best throughput
   AXIS_IN_FIFOS : for i in DIAGNOSTIC_RAW_STREAMS_G-1 downto 0 generate
      AxiStreamFifo : entity work.AxiStreamFifo
         generic map (
            TPD_G => TPD_G,

            SLAVE_READY_EN_G => true,
            VALID_THOLD_G    => 1,
            BRAM_EN_G        => false,
            XIL_DEVICE_G     => "ULTRASCALE",

            USE_BUILT_IN_G      => false,
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 4,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 1,   --2**(AXIS_FIFO_ADDR_WIDTH_G-1),

            SLAVE_AXI_CONFIG_G  => DIAGNOSTIC_RAW_CONFIGS_G(i),
            MASTER_AXI_CONFIG_G => INTERNAL_AXI_CONFIG_C)  -- 128-bit
         port map (
            sAxisClk    => diagnosticRawClks(i),
            sAxisRst    => diagnosticRawRsts(i),
            sAxisMaster => diagnosticRawMasters(i),
            sAxisSlave  => diagnosticRawSlaves(i),
            sAxisCtrl   => open,                           -- Control port assigned by DDR fifo with delay but shows if error occured
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

   -- Coregen-ed DDR Stream FIFO
   axiRstL <= not axiRst;
   AxiStreamDdrFifo_1 : AxiStreamDdrFifo
      port map (
         aclk    => axiClk,
         aresetn => axiRstL,

         -- MUX IN
         s_axis_tvalid => muxOutAxisMaster.tValid,  -- tUser gets dropped
         s_axis_tready => muxOutAxisSlave.tReady,
         s_axis_tdata  => muxOutAxisMaster.tData,
         s_axis_tstrb  => (others => '1'),
         s_axis_tkeep  => muxOutAxisMaster.tKeep,
         s_axis_tlast  => muxOutAxisMaster.tLast,
         s_axis_tid    => muxOutAxisMaster.tid(2 downto 0),
         s_axis_tdest  => muxOutAxisMaster.tDest(2 downto 0),

         -- DEMUX OUT         
         m_axis_tvalid => vFifoOutAxisMaster.tValid,
         m_axis_tready => vFifoOutAxisSlave.tReady,
         m_axis_tdata  => vFifoOutAxisMaster.tData,
         m_axis_tstrb  => open,
         m_axis_tkeep  => vFifoOutAxisMaster.tKeep,
         m_axis_tlast  => vFifoOutAxisMaster.tLast,
         m_axis_tid    => vFifoOutAxisMaster.tId(2 downto 0),
         m_axis_tdest  => vFifoOutAxisMaster.tDest(2 downto 0),

         m_axi_awid     => open,
         m_axi_awaddr   => axiWriteMaster.awaddr(31 downto 0),
         m_axi_awlen    => axiWriteMaster.awlen,
         m_axi_awsize   => axiWriteMaster.awsize,
         m_axi_awburst  => axiWriteMaster.awburst,
         m_axi_awlock   => axiWriteMaster.awlock(0 downto 0),
         m_axi_awcache  => axiWriteMaster.awcache,
         m_axi_awprot   => axiWriteMaster.awprot,
         m_axi_awqos    => axiWriteMaster.awqos,
         m_axi_awregion => axiWriteMaster.awregion,
         m_axi_awuser   => open,
         m_axi_awvalid  => axiWriteMaster.awvalid,
         m_axi_awready  => axiWriteSlave.awready,
         m_axi_wdata    => axiWriteMaster.wdata(127 downto 0),
         m_axi_wstrb    => axiWriteMaster.wstrb(15 downto 0),
         m_axi_wlast    => axiWriteMaster.wlast,
         m_axi_wuser    => open,
         m_axi_wvalid   => axiWriteMaster.wvalid,
         m_axi_wready   => axiWriteSlave.wready,
         m_axi_bid      => (others => '0'),
         m_axi_bresp    => axiWriteSlave.bresp,
         m_axi_buser    => (others => '0'),
         m_axi_bvalid   => axiWriteSlave.bvalid,
         m_axi_bready   => axiWriteMaster.bready,
         m_axi_arid     => open,
         m_axi_araddr   => axiReadMaster.araddr(31 downto 0),
         m_axi_arlen    => axiReadMaster.arlen,
         m_axi_arsize   => axiReadMaster.arsize,
         m_axi_arburst  => axiReadMaster.arburst,
         m_axi_arlock   => axiReadMaster.arlock(0 downto 0),
         m_axi_arcache  => axiReadMaster.arcache,
         m_axi_arprot   => axiReadMaster.arprot,
         m_axi_arqos    => axiReadMaster.arqos,
         m_axi_arregion => axiReadMaster.arregion,
         m_axi_aruser   => open,
         m_axi_arvalid  => axiReadMaster.arvalid,
         m_axi_arready  => axiReadSlave.arready,
         m_axi_rid      => (others => '0'),
         m_axi_rdata    => axiReadSlave.rdata(127 downto 0),
         m_axi_rresp    => axiReadSlave.rresp,
         m_axi_rlast    => axiReadSlave.rlast,
         m_axi_ruser    => (others => '0'),
         m_axi_rvalid   => axiReadSlave.rvalid,
         m_axi_rready   => axiReadMaster.rready,

         vfifo_mm2s_channel_full(7)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(6)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(5)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(4)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(3)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(2)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(1)  => sofOutAxisCtrl.pause,
         vfifo_mm2s_channel_full(0)  => sofOutAxisCtrl.pause,         
         vfifo_s2mm_channel_full  => full,
         vfifo_mm2s_channel_empty => open,
         vfifo_idle               => idle);

   -------------------------------------------------------------------------------------------------
   -- Synchronize flow control back to the sAxis clock domain
   -------------------------------------------------------------------------------------------------
   SYNCS : for i in DIAGNOSTIC_RAW_STREAMS_G-1 downto 0 generate
      Synchronizer_1 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => diagnosticRawClks(i),
            rst     => diagnosticRawRsts(i),
            dataIn  => idle(i),
            dataOut => diagnosticRawCtrl(i).idle);

      Synchronizer_2 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => diagnosticRawClks(i),
            rst     => diagnosticRawRsts(i),
            dataIn  => full(i),
            dataOut => diagnosticRawCtrl(i).pause);

      -- Put overflow to '0'
      diagnosticRawCtrl(i).overflow <= '0';

   end generate SYNCS;

   -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   -- Add SOF to frames
   -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


   -- Output fifo
   AxiStreamFifo : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         --INT_PIPE_STAGES_G   => INT_PIPE_STAGES_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 7,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1,      --2**(AXIS_FIFO_ADDR_WIDTH_G-1),
         --            CASCADE_PAUSE_SEL_G => CASCADE_PAUSE_SEL_G,
         SLAVE_AXI_CONFIG_G  => INTERNAL_AXI_CONFIG_C,
         MASTER_AXI_CONFIG_G => OUTPUT_CONFIG_G)
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => vFifoOutAxisMaster,
         sAxisSlave  => vFifoOutAxisSlave,
         mAxisClk    => bufClk,
         mAxisRst    => bufRst,
         mAxisMaster => sofInAxisMaster,
         mAxisSlave  => sofInAxisSlave);

   SsiInsertSof_1 : entity work.SsiInsertSof
      generic map (
         TPD_G               => TPD_G,
--         TUSER_MASK_G        => TUSER_MASK_G,
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         INSERT_USER_HDR_G   => false,
         SLAVE_AXI_CONFIG_G  => INTERNAL_AXI_CONFIG_C,
         MASTER_AXI_CONFIG_G => INTERNAL_AXI_CONFIG_C)
      port map (
         sAxisClk               => bufClk,
         sAxisRst               => bufRst,
         sAxisMaster            => sofInAxisMaster,
         sAxisSlave             => sofInAxisSlave,
         mAxisClk               => bufClk,
         mAxisRst               => bufRst,
         mUserHdr(7 downto 0)   => sofInAxisMaster.tDest,
         mUserHdr(127 downto 8) => (119 downto 0 => '0'),
         mAxisMaster            => sofOutAxisMaster,
         mAxisSlave             => sofOutAxisSlave);

   U_AxiStreamPipeline_1: entity work.AxiStreamPipeline
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 1)
      port map (
         axisClk     => bufClk,        -- [in]
         axisRst     => bufRst,        -- [in]
         sAxisMaster => sofOutAxisMaster,    -- [in]
         sAxisSlave  => sofOutAxisSlave,     -- [out]
         mAxisMaster => bufMaster,    -- [out]
         mAxisSlave  => bufSlave);    -- [in]

end architecture rtl;
