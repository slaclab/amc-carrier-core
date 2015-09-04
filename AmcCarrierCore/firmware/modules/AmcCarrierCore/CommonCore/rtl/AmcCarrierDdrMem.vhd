-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierDdrMem.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-08-06
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
use work.AxiLitePkg.all;
use work.AxiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierDdrMem is
   generic (
      TPD_G         : time    := 1 ns;
      EXT_MEM_G     : boolean := true;
      FSBL_G        : boolean := false;
      SIM_SPEEDUP_G : boolean := false);
   port (
      -- AXI-Lite Interface
      axiClk             : in    sl;
      axiRst             : in    sl;
      axiLiteReadMaster  : in    AxiLiteReadMasterType;
      axiLiteReadSlave   : out   AxiLiteReadSlaveType;
      axiLiteWriteMaster : in    AxiLiteWriteMasterType;
      axiLiteWriteSlave  : out   AxiLiteWriteSlaveType;
      memReady           : out   sl;
      memError           : out   sl;
      -- Diagnostic Snapshot
      debugClk           : in    sl;
      debugRst           : in    sl;
      debugIbMaster      : in    AxiStreamMasterType;
      debugIbSlave       : out   AxiStreamSlaveType;
      -- Beam Synchronization (BSA)
      bsaClk             : in    sl;
      bsaRst             : in    sl;
      bsaIbMaster        : in    AxiStreamMasterType;
      bsaIbSlave         : out   AxiStreamSlaveType;
      -- AXI Streaming Interface to Ethernet
      obDdrMaster        : out   AxiStreamMasterType;
      obDdrSlave         : in    AxiStreamSlaveType;
      ibDdrMaster        : in    AxiStreamMasterType;
      ibDdrSlave         : out   AxiStreamSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- DDR3L SO-DIMM Ports
      ddrClkP            : in    sl;
      ddrClkN            : in    sl;
      ddrDm              : out   slv(7 downto 0);
      ddrDqsP            : inout slv(7 downto 0);
      ddrDqsN            : inout slv(7 downto 0);
      ddrDq              : inout slv(63 downto 0);
      ddrA               : out   slv(15 downto 0);
      ddrBa              : out   slv(2 downto 0);
      ddrCsL             : out   slv(1 downto 0);
      ddrOdt             : out   slv(1 downto 0);
      ddrCke             : out   slv(1 downto 0);
      ddrCkP             : out   slv(1 downto 0);
      ddrCkN             : out   slv(1 downto 0);
      ddrWeL             : out   sl;
      ddrRasL            : out   sl;
      ddrCasL            : out   sl;
      ddrRstL            : out   sl);
end AmcCarrierDdrMem;

architecture mapping of AmcCarrierDdrMem is

   component MigCore
      port (
         c0_init_calib_complete  : out   std_logic;
         c0_sys_clk_i            : in    std_logic;
         c0_ddr3_addr            : out   std_logic_vector(15 downto 0);
         c0_ddr3_ba              : out   std_logic_vector(2 downto 0);
         c0_ddr3_cas_n           : out   std_logic;
         c0_ddr3_cke             : out   std_logic_vector(1 downto 0);
         c0_ddr3_ck_n            : out   std_logic_vector(1 downto 0);
         c0_ddr3_ck_p            : out   std_logic_vector(1 downto 0);
         c0_ddr3_cs_n            : out   std_logic_vector(1 downto 0);
         c0_ddr3_dm              : out   std_logic_vector(7 downto 0);
         c0_ddr3_dq              : inout std_logic_vector(63 downto 0);
         c0_ddr3_dqs_n           : inout std_logic_vector(7 downto 0);
         c0_ddr3_dqs_p           : inout std_logic_vector(7 downto 0);
         c0_ddr3_odt             : out   std_logic_vector(1 downto 0);
         c0_ddr3_ras_n           : out   std_logic;
         c0_ddr3_reset_n         : out   std_logic;
         c0_ddr3_we_n            : out   std_logic;
         c0_ddr3_ui_clk          : out   std_logic;
         c0_ddr3_ui_clk_sync_rst : out   std_logic;
         c0_ddr3_aresetn         : in    std_logic;
         c0_ddr3_s_axi_awid      : in    std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_awaddr    : in    std_logic_vector(32 downto 0);
         c0_ddr3_s_axi_awlen     : in    std_logic_vector(7 downto 0);
         c0_ddr3_s_axi_awsize    : in    std_logic_vector(2 downto 0);
         c0_ddr3_s_axi_awburst   : in    std_logic_vector(1 downto 0);
         c0_ddr3_s_axi_awlock    : in    std_logic_vector(0 downto 0);
         c0_ddr3_s_axi_awcache   : in    std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_awprot    : in    std_logic_vector(2 downto 0);
         c0_ddr3_s_axi_awqos     : in    std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_awvalid   : in    std_logic;
         c0_ddr3_s_axi_awready   : out   std_logic;
         c0_ddr3_s_axi_wdata     : in    std_logic_vector(511 downto 0);
         c0_ddr3_s_axi_wstrb     : in    std_logic_vector(63 downto 0);
         c0_ddr3_s_axi_wlast     : in    std_logic;
         c0_ddr3_s_axi_wvalid    : in    std_logic;
         c0_ddr3_s_axi_wready    : out   std_logic;
         c0_ddr3_s_axi_bready    : in    std_logic;
         c0_ddr3_s_axi_bid       : out   std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_bresp     : out   std_logic_vector(1 downto 0);
         c0_ddr3_s_axi_bvalid    : out   std_logic;
         c0_ddr3_s_axi_arid      : in    std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_araddr    : in    std_logic_vector(32 downto 0);
         c0_ddr3_s_axi_arlen     : in    std_logic_vector(7 downto 0);
         c0_ddr3_s_axi_arsize    : in    std_logic_vector(2 downto 0);
         c0_ddr3_s_axi_arburst   : in    std_logic_vector(1 downto 0);
         c0_ddr3_s_axi_arlock    : in    std_logic_vector(0 downto 0);
         c0_ddr3_s_axi_arcache   : in    std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_arprot    : in    std_logic_vector(2 downto 0);
         c0_ddr3_s_axi_arqos     : in    std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_arvalid   : in    std_logic;
         c0_ddr3_s_axi_arready   : out   std_logic;
         c0_ddr3_s_axi_rready    : in    std_logic;
         c0_ddr3_s_axi_rlast     : out   std_logic;
         c0_ddr3_s_axi_rvalid    : out   std_logic;
         c0_ddr3_s_axi_rresp     : out   std_logic_vector(1 downto 0);
         c0_ddr3_s_axi_rid       : out   std_logic_vector(3 downto 0);
         c0_ddr3_s_axi_rdata     : out   std_logic_vector(511 downto 0);
         sys_rst                 : in    std_logic);
   end component;

   component MigBramCore
      port (
         s_axi_aclk    : in  std_logic;
         s_axi_aresetn : in  std_logic;
         s_axi_awaddr  : in  std_logic_vector(19 downto 0);
         s_axi_awlen   : in  std_logic_vector(7 downto 0);
         s_axi_awsize  : in  std_logic_vector(2 downto 0);
         s_axi_awburst : in  std_logic_vector(1 downto 0);
         s_axi_awlock  : in  std_logic;
         s_axi_awcache : in  std_logic_vector(3 downto 0);
         s_axi_awprot  : in  std_logic_vector(2 downto 0);
         s_axi_awvalid : in  std_logic;
         s_axi_awready : out std_logic;
         s_axi_wdata   : in  std_logic_vector(511 downto 0);
         s_axi_wstrb   : in  std_logic_vector(63 downto 0);
         s_axi_wlast   : in  std_logic;
         s_axi_wvalid  : in  std_logic;
         s_axi_wready  : out std_logic;
         s_axi_bresp   : out std_logic_vector(1 downto 0);
         s_axi_bvalid  : out std_logic;
         s_axi_bready  : in  std_logic;
         s_axi_araddr  : in  std_logic_vector(19 downto 0);
         s_axi_arlen   : in  std_logic_vector(7 downto 0);
         s_axi_arsize  : in  std_logic_vector(2 downto 0);
         s_axi_arburst : in  std_logic_vector(1 downto 0);
         s_axi_arlock  : in  std_logic;
         s_axi_arcache : in  std_logic_vector(3 downto 0);
         s_axi_arprot  : in  std_logic_vector(2 downto 0);
         s_axi_arvalid : in  std_logic;
         s_axi_arready : out std_logic;
         s_axi_rdata   : out std_logic_vector(511 downto 0);
         s_axi_rresp   : out std_logic_vector(1 downto 0);
         s_axi_rlast   : out std_logic;
         s_axi_rvalid  : out std_logic;
         s_axi_rready  : in  std_logic);
   end component;

   signal ddrWriteMaster : AxiWriteMasterType;
   signal ddrWriteSlave  : AxiWriteSlaveType;
   signal ddrReadMaster  : AxiReadMasterType;
   signal ddrReadSlave   : AxiReadSlaveType;

   signal ddrClk     : sl;
   signal ddrRst     : sl;
   signal axiRstL    : sl;
   signal ddrCalDone : sl;
   signal refClock   : sl;
   signal refClkBufg : sl;
   signal awlock     : sl;
   signal arlock     : sl;

   attribute KEEP_HIERARCHY                : string;
   attribute KEEP_HIERARCHY of IBUFDS_Inst : label is "TRUE";
   attribute KEEP_HIERARCHY of BUFG_Inst   : label is "TRUE";
   
begin

   IBUFDS_Inst : IBUFDS
      port map (
         I  => ddrClkP,
         IB => ddrClkN,
         O  => refClock);                 

   BUFG_Inst : BUFG
      port map (
         I => refClock,
         O => refClkBufg);     

   axiRstL <= not(axiRst);

   EXT_MEM : if (EXT_MEM_G = true) generate
      MigCore_Inst : MigCore
         port map (
            c0_init_calib_complete  => ddrCalDone,
            c0_sys_clk_i            => refClkBufg,
            c0_ddr3_addr            => ddrA,
            c0_ddr3_ba              => ddrBa,
            c0_ddr3_cas_n           => ddrCasL,
            c0_ddr3_cke             => ddrCke,
            c0_ddr3_ck_n            => ddrCkN,
            c0_ddr3_ck_p            => ddrCkP,
            c0_ddr3_cs_n            => ddrCsL,
            c0_ddr3_dm              => ddrDm,
            c0_ddr3_dq              => ddrDq,
            c0_ddr3_dqs_n           => ddrDqsN,
            c0_ddr3_dqs_p           => ddrDqsP,
            c0_ddr3_odt             => ddrOdt,
            c0_ddr3_ras_n           => ddrRasL,
            c0_ddr3_reset_n         => ddrRstL,
            c0_ddr3_we_n            => ddrWeL,
            c0_ddr3_ui_clk          => ddrClk,
            c0_ddr3_ui_clk_sync_rst => ddrRst,
            c0_ddr3_aresetn         => axiRstL,
            c0_ddr3_s_axi_awid      => ddrWriteMaster.awid(3 downto 0),
            c0_ddr3_s_axi_awaddr    => ddrWriteMaster.awaddr(32 downto 0),
            c0_ddr3_s_axi_awlen     => ddrWriteMaster.awlen(7 downto 0),
            c0_ddr3_s_axi_awsize    => ddrWriteMaster.awsize(2 downto 0),
            c0_ddr3_s_axi_awburst   => ddrWriteMaster.awburst(1 downto 0),
            c0_ddr3_s_axi_awlock    => ddrWriteMaster.awlock(0 downto 0),
            c0_ddr3_s_axi_awcache   => ddrWriteMaster.awcache(3 downto 0),
            c0_ddr3_s_axi_awprot    => ddrWriteMaster.awprot(2 downto 0),
            c0_ddr3_s_axi_awqos     => ddrWriteMaster.awqos(3 downto 0),
            c0_ddr3_s_axi_awvalid   => ddrWriteMaster.awvalid,
            c0_ddr3_s_axi_awready   => ddrWriteSlave.awready,
            c0_ddr3_s_axi_wdata     => ddrWriteMaster.wdata(511 downto 0),
            c0_ddr3_s_axi_wstrb     => ddrWriteMaster.wstrb(63 downto 0),
            c0_ddr3_s_axi_wlast     => ddrWriteMaster.wlast,
            c0_ddr3_s_axi_wvalid    => ddrWriteMaster.wvalid,
            c0_ddr3_s_axi_wready    => ddrWriteSlave.wready,
            c0_ddr3_s_axi_bready    => ddrWriteMaster.bready,
            c0_ddr3_s_axi_bid       => ddrWriteSlave.bid(3 downto 0),
            c0_ddr3_s_axi_bresp     => ddrWriteSlave.bresp(1 downto 0),
            c0_ddr3_s_axi_bvalid    => ddrWriteSlave.bvalid,
            c0_ddr3_s_axi_arid      => ddrReadMaster.arid(3 downto 0),
            c0_ddr3_s_axi_araddr    => ddrReadMaster.araddr(32 downto 0),
            c0_ddr3_s_axi_arlen     => ddrReadMaster.arlen(7 downto 0),
            c0_ddr3_s_axi_arsize    => ddrReadMaster.arsize(2 downto 0),
            c0_ddr3_s_axi_arburst   => ddrReadMaster.arburst(1 downto 0),
            c0_ddr3_s_axi_arlock    => ddrReadMaster.arlock(0 downto 0),
            c0_ddr3_s_axi_arcache   => ddrReadMaster.arcache(3 downto 0),
            c0_ddr3_s_axi_arprot    => ddrReadMaster.arprot(2 downto 0),
            c0_ddr3_s_axi_arqos     => ddrReadMaster.arqos(3 downto 0),
            c0_ddr3_s_axi_arvalid   => ddrReadMaster.arvalid,
            c0_ddr3_s_axi_arready   => ddrReadSlave.arready,
            c0_ddr3_s_axi_rready    => ddrReadMaster.rready,
            c0_ddr3_s_axi_rlast     => ddrReadSlave.rlast,
            c0_ddr3_s_axi_rvalid    => ddrReadSlave.rvalid,
            c0_ddr3_s_axi_rresp     => ddrReadSlave.rresp(1 downto 0),
            c0_ddr3_s_axi_rid       => ddrReadSlave.rid(3 downto 0),
            c0_ddr3_s_axi_rdata     => ddrReadSlave.rdata(511 downto 0),
            sys_rst                 => axiRst); 
   end generate;

   INT_MEM : if (EXT_MEM_G = false) generate
      
      ddrDm   <= (others => '0');
      ddrA    <= (others => '0');
      ddrBa   <= (others => '0');
      ddrCsL  <= (others => '1');
      ddrOdt  <= (others => '0');
      ddrCke  <= (others => '0');
      ddrWeL  <= '1';
      ddrRasL <= '1';
      ddrCasL <= '1';
      ddrRstL <= '0';

      OBUFDS_0 : OBUFDS
         port map (
            I  => '0',
            O  => ddrCkP(0),
            OB => ddrCkN(0));

      OBUFDS_1 : OBUFDS
         port map (
            I  => '0',
            O  => ddrCkP(1),
            OB => ddrCkN(1));     

      GEN_VEC :
      for i in 7 downto 0 generate
         
         IOBUFDS_Inst : IOBUFDS
            port map (
               T   => '1',
               I   => '0',
               IO  => ddrDqsP(i),
               IOB => ddrDqsN(i),
               O   => open);   

      end generate GEN_VEC;

      MigBramCore_Inst : MigBramCore
         port map (
            s_axi_aclk    => axiClk,
            s_axi_aresetn => axiRstL,
            s_axi_awaddr  => ddrWriteMaster.awaddr(19 downto 0),
            s_axi_awlen   => ddrWriteMaster.awlen(7 downto 0),
            s_axi_awsize  => ddrWriteMaster.awsize(2 downto 0),
            s_axi_awburst => ddrWriteMaster.awburst(1 downto 0),
            s_axi_awlock  => awlock,
            s_axi_awcache => ddrWriteMaster.awcache(3 downto 0),
            s_axi_awprot  => ddrWriteMaster.awprot(2 downto 0),
            s_axi_awvalid => ddrWriteMaster.awvalid,
            s_axi_awready => ddrWriteSlave.awready,
            s_axi_wdata   => ddrWriteMaster.wdata(511 downto 0),
            s_axi_wstrb   => ddrWriteMaster.wstrb(63 downto 0),
            s_axi_wlast   => ddrWriteMaster.wlast,
            s_axi_wvalid  => ddrWriteMaster.wvalid,
            s_axi_wready  => ddrWriteSlave.wready,
            s_axi_bresp   => ddrWriteSlave.bresp(1 downto 0),
            s_axi_bvalid  => ddrWriteSlave.bvalid,
            s_axi_bready  => ddrWriteMaster.bready,
            s_axi_araddr  => ddrReadMaster.araddr(19 downto 0),
            s_axi_arlen   => ddrReadMaster.arlen(7 downto 0),
            s_axi_arsize  => ddrReadMaster.arsize(2 downto 0),
            s_axi_arburst => ddrReadMaster.arburst(1 downto 0),
            s_axi_arlock  => arlock,
            s_axi_arcache => ddrReadMaster.arcache(3 downto 0),
            s_axi_arprot  => ddrReadMaster.arprot(2 downto 0),
            s_axi_arvalid => ddrReadMaster.arvalid,
            s_axi_arready => ddrReadSlave.arready,
            s_axi_rdata   => ddrReadSlave.rdata(511 downto 0),
            s_axi_rresp   => ddrReadSlave.rresp(1 downto 0),
            s_axi_rlast   => ddrReadSlave.rlast,
            s_axi_rvalid  => ddrReadSlave.rvalid,
            s_axi_rready  => ddrReadMaster.rready);

      -- awlock     <= ddrWriteMaster.awlock(0 downto 0);
      -- arlock     <= ddrReadMaster.arlock(0 downto 0);   
      awlock <= '0';
      arlock <= '0';

      ddrClk     <= axiClk;
      ddrRst     <= axiRst;
      ddrCalDone <= axiRstL;

   end generate;

   DdrMemCtrl_Inst : entity work.DdrMemCtrl
      generic map (
         TPD_G         => TPD_G,
         FSBL_G        => FSBL_G,
         EXT_MEM_G     => EXT_MEM_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map (
         -- AXI-Lite Interface
         axiClk             => axiClk,
         axiRst             => axiRst,
         axiLiteReadMaster  => axiLiteReadMaster,
         axiLiteReadSlave   => axiLiteReadSlave,
         axiLiteWriteMaster => axiLiteWriteMaster,
         axiLiteWriteSlave  => axiLiteWriteSlave,
         memReady           => memReady,
         memError           => memError,
         -- Diagnostic Snapshot
         debugClk           => debugClk,
         debugRst           => debugRst,
         debugIbMaster      => debugIbMaster,
         debugIbSlave       => debugIbSlave,
         -- Beam Synchronization (BSA)
         bsaClk             => bsaClk,
         bsaRst             => bsaRst,
         bsaIbMaster        => bsaIbMaster,
         bsaIbSlave         => bsaIbSlave,
         -- DDR Memory Interface
         ddrClk             => ddrClk,
         ddrRst             => ddrRst,
         ddrCalDone         => ddrCalDone,
         ddrWriteMaster     => ddrWriteMaster,
         ddrWriteSlave      => ddrWriteSlave,
         ddrReadMaster      => ddrReadMaster,
         ddrReadSlave       => ddrReadSlave,
         -- AXI Streaming Interface to Ethernet
         obDdrMaster        => obDdrMaster,
         obDdrSlave         => obDdrSlave,
         ibDdrMaster        => ibDdrMaster,
         ibDdrSlave         => ibDdrSlave);

end mapping;
