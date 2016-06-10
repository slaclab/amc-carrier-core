-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : DebugAmcAdcDdrFifo.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
--              Uros Legat <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-12
-- Last update: 2015-11-02
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
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.Pgp2bPkg.all;

entity DebugAmcAdcDdrFifo is

   generic (
      TPD_G                 : time                := 1 ns;
      L_AXI_G               : positive            := 2;
      INPUT_AXI_CONFIG_G    : AxiStreamConfigType := ssiAxiStreamConfig(4);
      OUTPUT_AXI_CONFIG_G   : AxiStreamConfigType := ssiAxiStreamConfig(2);
      INTERNAL_AXI_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16)
      );
   port (
      sAxisClk       : in  sl;
      sAxisRst       : in  sl;
      sAxisMaster    : in  AxiStreamMasterArray(L_AXI_G-1 downto 0);
      sAxisSlave     : out AxiStreamSlaveArray(L_AXI_G-1 downto 0);
      sAxisCtrl      : out AxiStreamCtrlArray(L_AXI_G-1 downto 0);
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiWriteMaster : out AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
      axiWriteSlave  : in  AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
      axiReadMaster  : out AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
      axiReadSlave   : in  AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
      mAxisClk       : in  sl;
      mAxisRst       : in  sl;
      mAxisMaster    : out AxiStreamMasterArray(L_AXI_G-1 downto 0);
      mAxisSlave     : in  AxiStreamSlaveArray(L_AXI_G-1 downto 0));

end entity DebugAmcAdcDdrFifo;

architecture rtl of DebugAmcAdcDdrFifo is
   
   signal axiRstL : sl;

   signal idle : slv(L_AXI_G-1 downto 0);
   signal full : slv(L_AXI_G-1 downto 0);

   -- Mux in 
   signal muxInAxisMaster : AxiStreamMasterArray(L_AXI_G-1 downto 0);
   signal muxInAxisSlave  : AxiStreamSlaveArray(L_AXI_G-1 downto 0);

   -- Mux out    
   signal muxOutAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal muxOutAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- Demux in 
   signal demuxInAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal demuxInAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- Demux out
   signal demuxOutAxisMaster : AxiStreamMasterArray(L_AXI_G-1 downto 0);
   signal demuxOutAxisSlave  : AxiStreamSlaveArray(L_AXI_G-1 downto 0);

   -- Add SOF 
   signal sofOutAxisMaster : AxiStreamMasterArray(L_AXI_G-1 downto 0);
   signal sofOutAxisSlave  : AxiStreamSlaveArray(L_AXI_G-1 downto 0);
   signal sofOutAxisCtrl   : AxiStreamCtrlArray(L_AXI_G-1 downto 0);

   component debugaxistreamddrfifo
      port (
         aclk                     : in  std_logic;
         aresetn                  : in  std_logic;
         s_axis_tvalid            : in  std_logic;
         s_axis_tready            : out std_logic;
         s_axis_tdata             : in  std_logic_vector(127 downto 0);
         s_axis_tstrb             : in  std_logic_vector(15 downto 0);
         s_axis_tkeep             : in  std_logic_vector(15 downto 0);
         s_axis_tlast             : in  std_logic;
         s_axis_tid               : in  std_logic_vector(0 downto 0);
         s_axis_tdest             : in  std_logic_vector(0 downto 0);
         m_axis_tvalid            : out std_logic;
         m_axis_tready            : in  std_logic;
         m_axis_tdata             : out std_logic_vector(127 downto 0);
         m_axis_tstrb             : out std_logic_vector(15 downto 0);
         m_axis_tkeep             : out std_logic_vector(15 downto 0);
         m_axis_tlast             : out std_logic;
         m_axis_tid               : out std_logic_vector(0 downto 0);
         m_axis_tdest             : out std_logic_vector(0 downto 0);
         m_axi_awid               : out std_logic_vector(0 downto 0);
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
         m_axi_bid                : in  std_logic_vector(0 downto 0);
         m_axi_bresp              : in  std_logic_vector(1 downto 0);
         m_axi_buser              : in  std_logic_vector(0 downto 0);
         m_axi_bvalid             : in  std_logic;
         m_axi_bready             : out std_logic;
         m_axi_arid               : out std_logic_vector(0 downto 0);
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
         m_axi_rid                : in  std_logic_vector(0 downto 0);
         m_axi_rdata              : in  std_logic_vector(127 downto 0);
         m_axi_rresp              : in  std_logic_vector(1 downto 0);
         m_axi_rlast              : in  std_logic;
         m_axi_ruser              : in  std_logic_vector(0 downto 0);
         m_axi_rvalid             : in  std_logic;
         m_axi_rready             : out std_logic;
         vfifo_mm2s_channel_full  : in  std_logic_vector(1 downto 0);
         vfifo_s2mm_channel_full  : out std_logic_vector(1 downto 0);
         vfifo_mm2s_channel_empty : out std_logic_vector(1 downto 0);
         vfifo_idle               : out std_logic_vector(1 downto 0)
         );
   end component;

begin

   -- Input fifos
   AXIS_IN_FIFOS : for I in L_AXI_G-1 downto 0 generate
      AxiStreamFifo : entity work.AxiStreamFifo
         generic map (
            TPD_G => TPD_G,

            SLAVE_READY_EN_G => true,
            VALID_THOLD_G    => 1,
            BRAM_EN_G        => true,
            XIL_DEVICE_G     => "ULTRASCALE",

            USE_BUILT_IN_G      => false,
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 11,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 1,   --2**(AXIS_FIFO_ADDR_WIDTH_G-1),

            SLAVE_AXI_CONFIG_G  => INPUT_AXI_CONFIG_G,     -- 32-bit
            MASTER_AXI_CONFIG_G => INTERNAL_AXI_CONFIG_G)  -- 128-bit
         port map (
            sAxisClk    => sAxisClk,
            sAxisRst    => sAxisRst,
            sAxisMaster => sAxisMaster(I),
            sAxisSlave  => sAxisSlave(I),
            sAxisCtrl   => open,  -- Control port assigned by DDR fifo with delay but shows if error occured
            mAxisClk    => axiClk,
            mAxisRst    => axiRst,
            mAxisMaster => muxInAxisMaster(I),
            mAxisSlave  => muxInAxisSlave(I));
   end generate AXIS_IN_FIFOS;

   -- Mux of two streams
   AxiStreamMux_INST : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => 2,
         PIPE_STAGES_G  => 1,
         TDEST_HIGH_G   => 7,
         TDEST_LOW_G    => 0,
         TDEST_ROUTES_G => (0 => "--------",1 => "--------"),
         MODE_G         => "ROUTED")
      port map (
         sAxisMasters => muxInAxisMaster,
         sAxisSlaves  => muxInAxisSlave,
         mAxisMaster  => muxOutAxisMaster,
         mAxisSlave   => muxOutAxisSlave,
         axisClk      => axiClk,
         axisRst      => axiRst);

   -- Coregen-ed DDR Stream FIFO
   axiRstL <= not axiRst;
   AxiStreamDdrFifo_1 : entity work.DebugAxiStreamDdrFifo
      port map (
         aclk    => axiClk,
         aresetn => axiRstL,

         -- MUX IN
         s_axis_tvalid => muxOutAxisMaster.tValid,  -- tUser gets dropped
         s_axis_tready => muxOutAxisSlave.tReady,
         s_axis_tdata  => muxOutAxisMaster.tData,
         s_axis_tstrb  => (others => '1'),
         s_axis_tkeep  => (others => '1'),
         s_axis_tlast  => muxOutAxisMaster.tLast,
         s_axis_tid    => (others => '0'),
         s_axis_tdest  => muxOutAxisMaster.tDest(0 downto 0),

         -- DEMUX OUT         
         m_axis_tvalid => demuxInAxisMaster.tValid,
         m_axis_tready => demuxInAxisSlave.tReady,
         m_axis_tdata  => demuxInAxisMaster.tData,
         m_axis_tstrb  => open,
         m_axis_tkeep  => open,
         m_axis_tlast  => demuxInAxisMaster.tLast,
         m_axis_tid    => open,
         m_axis_tdest  => demuxInAxisMaster.tDest(0 downto 0),


         m_axi_awid(0)              => axiWriteMaster.awid(0),
         m_axi_awaddr               => axiWriteMaster.awaddr(31 downto 0),
         m_axi_awlen                => axiWriteMaster.awlen,
         m_axi_awsize               => axiWriteMaster.awsize,
         m_axi_awburst              => axiWriteMaster.awburst,
         m_axi_awlock               => axiWriteMaster.awlock(0 downto 0),
         m_axi_awcache              => axiWriteMaster.awcache,
         m_axi_awprot               => axiWriteMaster.awprot,
         m_axi_awqos                => axiWriteMaster.awqos,
         m_axi_awregion             => axiWriteMaster.awregion,
         m_axi_awuser               => open,
         m_axi_awvalid              => axiWriteMaster.awvalid,
         m_axi_awready              => axiWriteSlave.awready,
         m_axi_wdata                => axiWriteMaster.wdata(127 downto 0),
         m_axi_wstrb                => axiWriteMaster.wstrb(15 downto 0),
         m_axi_wlast                => axiWriteMaster.wlast,
         m_axi_wuser                => open,
         m_axi_wvalid               => axiWriteMaster.wvalid,
         m_axi_wready               => axiWriteSlave.wready,
         m_axi_bid(0)               => axiWriteSlave.bid(0),
         m_axi_bresp                => axiWriteSlave.bresp,
         m_axi_buser                => (others => '0'),
         m_axi_bvalid               => axiWriteSlave.bvalid,
         m_axi_bready               => axiWriteMaster.bready,
         m_axi_arid(0)              => axiReadMaster.arid(0),
         m_axi_araddr               => axiReadMaster.araddr(31 downto 0),
         m_axi_arlen                => axiReadMaster.arlen,
         m_axi_arsize               => axiReadMaster.arsize,
         m_axi_arburst              => axiReadMaster.arburst,
         m_axi_arlock               => axiReadMaster.arlock(0 downto 0),
         m_axi_arcache              => axiReadMaster.arcache,
         m_axi_arprot               => axiReadMaster.arprot,
         m_axi_arqos                => axiReadMaster.arqos,
         m_axi_arregion             => axiReadMaster.arregion,
         m_axi_aruser               => open,
         m_axi_arvalid              => axiReadMaster.arvalid,
         m_axi_arready              => axiReadSlave.arready,
         m_axi_rid(0)               => axiReadSlave.rid(0),
         m_axi_rdata                => axiReadSlave.rdata(127 downto 0),
         m_axi_rresp                => axiReadSlave.rresp,
         m_axi_rlast                => axiReadSlave.rlast,
         m_axi_ruser                => (others => '0'),
         m_axi_rvalid               => axiReadSlave.rvalid,
         m_axi_rready               => axiReadMaster.rready,
         vfifo_mm2s_channel_full(0) => sofOutAxisCtrl(0).pause,
         vfifo_mm2s_channel_full(1) => sofOutAxisCtrl(1).pause,
         vfifo_s2mm_channel_full    => full,
         vfifo_mm2s_channel_empty   => open,
         vfifo_idle                 => idle);

   -------------------------------------------------------------------------------------------------
   -- Synchronize back to the sAxis clock domain
   -------------------------------------------------------------------------------------------------
   SYNCS : for I in L_AXI_G-1 downto 0 generate
      Synchronizer_1 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => sAxisClk,
            rst     => sAxisRst,
            dataIn  => idle(I),
            dataOut => sAxisCtrl(I).idle);

      Synchronizer_2 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => sAxisClk,
            rst     => sAxisRst,
            dataIn  => full(I),
            dataOut => sAxisCtrl(I).pause);

      -- Put overflow to '0'
      sAxisCtrl(I).overflow <= '0';
      
   end generate SYNCS;


   -- Demux streams
   AxiStreamDeMux_INST : entity work.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 2,
         MODE_G        => "INDEXED",
         TDEST_HIGH_G  => 7,
         TDEST_LOW_G   => 0
         )
      port map (
         axisClk      => axiClk,
         axisRst      => axiRst,
         sAxisMaster  => demuxInAxisMaster,
         sAxisSlave   => demuxInAxisSlave,
         mAxisMasters => demuxOutAxisMaster,
         mAxisSlaves  => demuxOutAxisSlave);


   SOF_GEN : for I in L_AXI_G-1 downto 0 generate
      SsiInsertSof_1 : entity work.SsiInsertSof
         generic map (
            TPD_G               => TPD_G,
--         TUSER_MASK_G        => TUSER_MASK_G,
            COMMON_CLK_G        => true,
            SLAVE_FIFO_G        => true,
            MASTER_FIFO_G       => true,
            INSERT_USER_HDR_G   => true,
            SLAVE_AXI_CONFIG_G  => INTERNAL_AXI_CONFIG_G,
            MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(4))
         port map (
            sAxisClk               => axiClk,
            sAxisRst               => axiRst,
            sAxisMaster            => demuxOutAxisMaster(I),
            sAxisSlave             => demuxOutAxisSlave(I),
            mAxisClk               => axiClk,
            mAxisRst               => axiRst,
            mUserHdr(7 downto 0)   => demuxOutAxisMaster(I).tDest,
            mUserHdr(127 downto 8) => (119 downto 0 => '0'),
            mAxisMaster            => sofOutAxisMaster(I),
            mAxisSlave             => sofOutAxisSlave(I));
   end generate SOF_GEN;

   -- Output fifos
   AXIS_OUT_FIFOS : for I in L_AXI_G-1 downto 0 generate
      AxiStreamFifo : entity work.AxiStreamFifo
         generic map (
            TPD_G               => TPD_G,
            --INT_PIPE_STAGES_G   => INT_PIPE_STAGES_G,
            PIPE_STAGES_G       => 2,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 1,
            BRAM_EN_G           => true,
            USE_BUILT_IN_G      => false,
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 13,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => (2**13)-2048,  --2**(AXIS_FIFO_ADDR_WIDTH_G-1),
            --            CASCADE_PAUSE_SEL_G => CASCADE_PAUSE_SEL_G,
            SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(4),
            MASTER_AXI_CONFIG_G => OUTPUT_AXI_CONFIG_G)
         port map (
            sAxisClk    => axiClk,
            sAxisRst    => axiRst,
            sAxisMaster => sofOutAxisMaster(I),
            sAxisSlave  => sofOutAxisSlave(I),
            sAxisCtrl   => sofOutAxisCtrl(I),
            mAxisClk    => mAxisClk,
            mAxisRst    => mAxisRst,
            mAxisMaster => mAxisMaster(I),
            mAxisSlave  => mAxisSlave(I));
   end generate AXIS_OUT_FIFOS;

end architecture rtl;
