-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierSysMon.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-09
-- Last update: 2015-07-10
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

entity AmcCarrierSysMon is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- SYSMON Ports
      vPIn             : in  sl;
      vNIn             : in  sl;
      -- AXI-Lite Register Interface
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      -- Clocks and Resets
      axiClk         : in  sl;
      axiRst         : in  sl);
end entity AmcCarrierSysMon;

architecture mapping of AmcCarrierSysMon is

   component SysMonCore
      port (
         s_axi_aclk    : in  std_logic;
         s_axi_aresetn : in  std_logic;
         s_axi_awaddr  : in  std_logic_vector(12 downto 0);
         s_axi_awvalid : in  std_logic;
         s_axi_awready : out std_logic;
         s_axi_wdata   : in  std_logic_vector(31 downto 0);
         s_axi_wstrb   : in  std_logic_vector(3 downto 0);
         s_axi_wvalid  : in  std_logic;
         s_axi_wready  : out std_logic;
         s_axi_bresp   : out std_logic_vector(1 downto 0);
         s_axi_bvalid  : out std_logic;
         s_axi_bready  : in  std_logic;
         s_axi_araddr  : in  std_logic_vector(12 downto 0);
         s_axi_arvalid : in  std_logic;
         s_axi_arready : out std_logic;
         s_axi_rdata   : out std_logic_vector(31 downto 0);
         s_axi_rresp   : out std_logic_vector(1 downto 0);
         s_axi_rvalid  : out std_logic;
         s_axi_rready  : in  std_logic;
         ip2intc_irpt  : out std_logic;
         vp            : in  std_logic;
         vn            : in  std_logic;
         channel_out   : out std_logic_vector(5 downto 0);
         eoc_out       : out std_logic;
         alarm_out     : out std_logic;
         eos_out       : out std_logic;
         busy_out      : out std_logic);
   end component;

   signal axiRstL : sl;

begin

   axiRstL <= not axiRst;

   SysMonCore_Inst : SysMonCore
      port map (
         s_axi_aclk    => axiClk,
         s_axi_aresetn => axiRstL,
         s_axi_awaddr  => axiWriteMaster.awaddr(12 downto 0),
         s_axi_awvalid => axiWriteMaster.awvalid,
         s_axi_awready => axiWriteSlave.awready,
         s_axi_wdata   => axiWriteMaster.wdata,
         s_axi_wstrb   => axiWriteMaster.wstrb,
         s_axi_wvalid  => axiWriteMaster.wvalid,
         s_axi_wready  => axiWriteSlave.wready,
         s_axi_bresp   => axiWriteSlave.bresp,
         s_axi_bvalid  => axiWriteSlave.bvalid,
         s_axi_bready  => axiWriteMaster.bready,
         s_axi_araddr  => axiReadMaster.araddr(12 downto 0),
         s_axi_arvalid => axiReadMaster.arvalid,
         s_axi_arready => axiReadSlave.arready,
         s_axi_rdata   => axiReadSlave.rdata,
         s_axi_rresp   => axiReadSlave.rresp,
         s_axi_rvalid  => axiReadSlave.rvalid,
         s_axi_rready  => axiReadMaster.rready,
         ip2intc_irpt  => open,
         vp            => vPIn,
         vn            => vNIn,
         channel_out   => open,
         eoc_out       => open,
         alarm_out     => open,
         eos_out       => open,
         busy_out      => open);  

end architecture mapping;
