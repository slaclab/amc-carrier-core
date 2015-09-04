-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierDdrMem.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-09-04
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
use work.AxiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierDdrMem is
   generic (
      TPD_G         : time    := 1 ns;
      FSBL_G        : boolean := false;
      SIM_SPEEDUP_G : boolean := false);
   port (
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      memReady        : out   sl;
      memError        : out   sl;
      -- AXI4 Interface
      axiClk          : out   sl;
      axiRst          : out   sl;
      axiWriteMaster  : in    AxiWriteMasterType;
      axiWriteSlave   : out   AxiWriteSlaveType;
      axiReadMaster   : in    AxiReadMasterType;
      axiReadSlave    : out   AxiReadSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- DDR3L SO-DIMM Ports
      ddrClkP         : in    sl;
      ddrClkN         : in    sl;
      ddrDm           : out   slv(7 downto 0);
      ddrDqsP         : inout slv(7 downto 0);
      ddrDqsN         : inout slv(7 downto 0);
      ddrDq           : inout slv(63 downto 0);
      ddrA            : out   slv(15 downto 0);
      ddrBa           : out   slv(2 downto 0);
      ddrCsL          : out   slv(1 downto 0);
      ddrOdt          : out   slv(1 downto 0);
      ddrCke          : out   slv(1 downto 0);
      ddrCkP          : out   slv(1 downto 0);
      ddrCkN          : out   slv(1 downto 0);
      ddrWeL          : out   sl;
      ddrRasL         : out   sl;
      ddrCasL         : out   sl;
      ddrRstL         : out   sl);
end AmcCarrierDdrMem;

architecture mapping of AmcCarrierDdrMem is

   constant AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 33,
      DATA_BYTES_C => 64,
      ID_BITS_C    => 4);

   constant START_ADDR_C : slv(AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   constant STOP_ADDR_C  : slv(AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');

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

   axiClk <= ddrClk;
   axiRst <= ddrRst;

   IBUFDS_Inst : IBUFDS
      port map (
         I  => ddrClkP,
         IB => ddrClkN,
         O  => refClock);                 

   BUFG_Inst : BUFG
      port map (
         I => refClock,
         O => refClkBufg);     

   axiRstL <= not(axilRst);

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
         sys_rst                 => axilRst); 

   FSBL_GEN : if (FSBL_G = true) generate
      
      U_AxiMemTester : entity work.AxiMemTester
         generic map (
            TPD_G        => TPD_G,
            START_ADDR_G => START_ADDR_C,
            STOP_ADDR_G  => ite(SIM_SPEEDUP_G, toSlv(8191, AXI_CONFIG_C.ADDR_WIDTH_C), STOP_ADDR_C),
            AXI_CONFIG_G => AXI_CONFIG_C)
         port map (
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave,
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            memReady        => memReady,
            memError        => memError,
            -- DDR Memory Interface
            axiClk          => ddrClk,
            axiRst          => ddrRst,
            start           => ddrCalDone,
            axiWriteMaster  => ddrWriteMaster,
            axiWriteSlave   => ddrWriteSlave,
            axiReadMaster   => ddrReadMaster,
            axiReadSlave    => ddrReadSlave);

      -- Terminate the buses
      axiWriteSlave <= AXI_WRITE_SLAVE_INIT_C;
      axiReadSlave  <= AXI_READ_SLAVE_INIT_C;
      
   end generate;

   NORMAL_GEN : if (FSBL_G = false) generate
      
      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G => TPD_G)
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave);   

      U_RstSync : entity work.RstSync
         generic map (
            TPD_G          => TPD_G,
            OUT_POLARITY_G => '0')
         port map (
            clk      => axilClk,
            asyncRst => ddrRst,
            syncRst  => memReady);     

      memError <= '0';

      -- Map the AXI4 buses
      ddrWriteMaster <= axiWriteMaster;
      axiWriteSlave  <= ddrWriteSlave;
      ddrReadMaster  <= axiReadMaster;
      axiReadSlave   <= ddrReadSlave;
      
   end generate;
   
end mapping;
