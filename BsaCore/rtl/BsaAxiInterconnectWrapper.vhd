-------------------------------------------------------------------------------
-- File       : BsaAxiInterconnectWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-10
-- Last update: 2016-07-13
-------------------------------------------------------------------------------
-- Description: Wrapper around AxiInterconnect Xilinx IP Core.
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiPkg.all;

entity BsaAxiInterconnectWrapper is
   port (
      axiClk           : in  sl;
      axiRst           : in  sl;
      sAxiWriteMasters : in  AxiWriteMasterArray(3 downto 0) := (others => AXI_WRITE_MASTER_INIT_C);
      sAxiWriteSlaves  : out AxiWriteSlaveArray(3 downto 0) := (others => AXI_WRITE_SLAVE_INIT_C);
      sAxiReadMasters  : in  AxiReadMasterArray(3 downto 0) := (others => AXI_READ_MASTER_INIT_C);
      sAxiReadSlaves   : out AxiReadSlaveArray(3 downto 0) := (others => AXI_READ_SLAVE_INIT_C);
      mAxiWriteMasters : out AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
      mAxiWriteSlaves  : in  AxiWriteSlaveType := AXI_WRITE_SLAVE_INIT_C;
      mAxiReadMasters  : out AxiReadMasterType := AXI_READ_MASTER_INIT_C;
      mAxiReadSlaves   : in  AxiReadSlaveType := AXI_READ_SLAVE_INIT_C);

end entity BsaAxiInterconnectWrapper;

architecture rtl of BsaAxiInterconnectWrapper is

   component BsaAxiInterconnect
      port (
         INTERCONNECT_ACLK    : in  std_logic;
         INTERCONNECT_ARESETN : in  std_logic;
         S00_AXI_ARESET_OUT_N : out std_logic;
         S00_AXI_ACLK         : in  std_logic;
         S00_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S00_AXI_AWADDR       : in  std_logic_vector(32 downto 0);
         S00_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_AWLOCK       : in  std_logic;
         S00_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_AWVALID      : in  std_logic;
         S00_AXI_AWREADY      : out std_logic;
         S00_AXI_WDATA        : in  std_logic_vector(31 downto 0);
         S00_AXI_WSTRB        : in  std_logic_vector(3 downto 0);
         S00_AXI_WLAST        : in  std_logic;
         S00_AXI_WVALID       : in  std_logic;
         S00_AXI_WREADY       : out std_logic;
         S00_AXI_BID          : out std_logic_vector(0 downto 0);
         S00_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_BVALID       : out std_logic;
         S00_AXI_BREADY       : in  std_logic;
         S00_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S00_AXI_ARADDR       : in  std_logic_vector(32 downto 0);
         S00_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_ARLOCK       : in  std_logic;
         S00_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_ARVALID      : in  std_logic;
         S00_AXI_ARREADY      : out std_logic;
         S00_AXI_RID          : out std_logic_vector(0 downto 0);
         S00_AXI_RDATA        : out std_logic_vector(31 downto 0);
         S00_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_RLAST        : out std_logic;
         S00_AXI_RVALID       : out std_logic;
         S00_AXI_RREADY       : in  std_logic;
         S01_AXI_ARESET_OUT_N : out std_logic;
         S01_AXI_ACLK         : in  std_logic;
         S01_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S01_AXI_AWADDR       : in  std_logic_vector(32 downto 0);
         S01_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S01_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S01_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S01_AXI_AWLOCK       : in  std_logic;
         S01_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S01_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S01_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S01_AXI_AWVALID      : in  std_logic;
         S01_AXI_AWREADY      : out std_logic;
         S01_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S01_AXI_WSTRB        : in  std_logic_vector(15 downto 0);
         S01_AXI_WLAST        : in  std_logic;
         S01_AXI_WVALID       : in  std_logic;
         S01_AXI_WREADY       : out std_logic;
         S01_AXI_BID          : out std_logic_vector(0 downto 0);
         S01_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S01_AXI_BVALID       : out std_logic;
         S01_AXI_BREADY       : in  std_logic;
         S01_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S01_AXI_ARADDR       : in  std_logic_vector(32 downto 0);
         S01_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S01_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S01_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S01_AXI_ARLOCK       : in  std_logic;
         S01_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S01_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S01_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S01_AXI_ARVALID      : in  std_logic;
         S01_AXI_ARREADY      : out std_logic;
         S01_AXI_RID          : out std_logic_vector(0 downto 0);
         S01_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S01_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S01_AXI_RLAST        : out std_logic;
         S01_AXI_RVALID       : out std_logic;
         S01_AXI_RREADY       : in  std_logic;
         S02_AXI_ARESET_OUT_N : out std_logic;
         S02_AXI_ACLK         : in  std_logic;
         S02_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S02_AXI_AWADDR       : in  std_logic_vector(32 downto 0);
         S02_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S02_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S02_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S02_AXI_AWLOCK       : in  std_logic;
         S02_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S02_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S02_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S02_AXI_AWVALID      : in  std_logic;
         S02_AXI_AWREADY      : out std_logic;
         S02_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S02_AXI_WSTRB        : in  std_logic_vector(15 downto 0);
         S02_AXI_WLAST        : in  std_logic;
         S02_AXI_WVALID       : in  std_logic;
         S02_AXI_WREADY       : out std_logic;
         S02_AXI_BID          : out std_logic_vector(0 downto 0);
         S02_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S02_AXI_BVALID       : out std_logic;
         S02_AXI_BREADY       : in  std_logic;
         S02_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S02_AXI_ARADDR       : in  std_logic_vector(32 downto 0);
         S02_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S02_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S02_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S02_AXI_ARLOCK       : in  std_logic;
         S02_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S02_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S02_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S02_AXI_ARVALID      : in  std_logic;
         S02_AXI_ARREADY      : out std_logic;
         S02_AXI_RID          : out std_logic_vector(0 downto 0);
         S02_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S02_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S02_AXI_RLAST        : out std_logic;
         S02_AXI_RVALID       : out std_logic;
         S02_AXI_RREADY       : in  std_logic;
         S03_AXI_ARESET_OUT_N : out std_logic;
         S03_AXI_ACLK         : in  std_logic;
         S03_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S03_AXI_AWADDR       : in  std_logic_vector(32 downto 0);
         S03_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S03_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S03_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S03_AXI_AWLOCK       : in  std_logic;
         S03_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S03_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S03_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S03_AXI_AWVALID      : in  std_logic;
         S03_AXI_AWREADY      : out std_logic;
         S03_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S03_AXI_WSTRB        : in  std_logic_vector(15 downto 0);
         S03_AXI_WLAST        : in  std_logic;
         S03_AXI_WVALID       : in  std_logic;
         S03_AXI_WREADY       : out std_logic;
         S03_AXI_BID          : out std_logic_vector(0 downto 0);
         S03_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S03_AXI_BVALID       : out std_logic;
         S03_AXI_BREADY       : in  std_logic;
         S03_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S03_AXI_ARADDR       : in  std_logic_vector(32 downto 0);
         S03_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S03_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S03_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S03_AXI_ARLOCK       : in  std_logic;
         S03_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S03_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S03_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S03_AXI_ARVALID      : in  std_logic;
         S03_AXI_ARREADY      : out std_logic;
         S03_AXI_RID          : out std_logic_vector(0 downto 0);
         S03_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S03_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S03_AXI_RLAST        : out std_logic;
         S03_AXI_RVALID       : out std_logic;
         S03_AXI_RREADY       : in  std_logic;
         M00_AXI_ARESET_OUT_N : out std_logic;
         M00_AXI_ACLK         : in  std_logic;
         M00_AXI_AWID         : out std_logic_vector(3 downto 0);
         M00_AXI_AWADDR       : out std_logic_vector(32 downto 0);
         M00_AXI_AWLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_AWSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_AWBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_AWLOCK       : out std_logic;
         M00_AXI_AWCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_AWPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_AWQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_AWVALID      : out std_logic;
         M00_AXI_AWREADY      : in  std_logic;
         M00_AXI_WDATA        : out std_logic_vector(511 downto 0);
         M00_AXI_WSTRB        : out std_logic_vector(63 downto 0);
         M00_AXI_WLAST        : out std_logic;
         M00_AXI_WVALID       : out std_logic;
         M00_AXI_WREADY       : in  std_logic;
         M00_AXI_BID          : in  std_logic_vector(3 downto 0);
         M00_AXI_BRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_BVALID       : in  std_logic;
         M00_AXI_BREADY       : out std_logic;
         M00_AXI_ARID         : out std_logic_vector(3 downto 0);
         M00_AXI_ARADDR       : out std_logic_vector(32 downto 0);
         M00_AXI_ARLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_ARSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_ARBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_ARLOCK       : out std_logic;
         M00_AXI_ARCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_ARPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_ARQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_ARVALID      : out std_logic;
         M00_AXI_ARREADY      : in  std_logic;
         M00_AXI_RID          : in  std_logic_vector(3 downto 0);
         M00_AXI_RDATA        : in  std_logic_vector(511 downto 0);
         M00_AXI_RRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_RLAST        : in  std_logic;
         M00_AXI_RVALID       : in  std_logic;
         M00_AXI_RREADY       : out std_logic
         );
   end component;

   signal axiRstL : sl;

begin

   axiRstL <= not axiRst;

   U_BsaAxiInterconnect : BsaAxiInterconnect
      port map (
         INTERCONNECT_ACLK    => axiClk,
         INTERCONNECT_ARESETN => axiRstL,
         -- Port 0
         S00_AXI_ARESET_OUT_N => open,
         S00_AXI_ACLK         => axiClk,
         S00_AXI_AWID         => sAxiWriteMasters(0).AWID(0 downto 0),
         S00_AXI_AWADDR       => sAxiWriteMasters(0).AWADDR(32 downto 0),
         S00_AXI_AWLEN        => sAxiWriteMasters(0).AWLEN(7 downto 0),
         S00_AXI_AWSIZE       => sAxiWriteMasters(0).AWSIZE(2 downto 0),
         S00_AXI_AWBURST      => sAxiWriteMasters(0).AWBURST(1 downto 0),
         S00_AXI_AWLOCK       => sAxiWriteMasters(0).AWLOCK(0),
         S00_AXI_AWCACHE      => sAxiWriteMasters(0).AWCACHE(3 downto 0),
         S00_AXI_AWPROT       => sAxiWriteMasters(0).AWPROT(2 downto 0),
         S00_AXI_AWQOS        => sAxiWriteMasters(0).AWQOS(3 downto 0),
         S00_AXI_AWVALID      => sAxiWriteMasters(0).AWVALID,
         S00_AXI_AWREADY      => sAxiWriteSlaves(0).AWREADY,
         S00_AXI_WDATA        => sAxiWriteMasters(0).WDATA(31 downto 0),
         S00_AXI_WSTRB        => sAxiWriteMasters(0).WSTRB(3 downto 0),
         S00_AXI_WLAST        => sAxiWriteMasters(0).WLAST,
         S00_AXI_WVALID       => sAxiWriteMasters(0).WVALID,
         S00_AXI_WREADY       => sAxiWriteSlaves(0).WREADY,
         S00_AXI_BID          => sAxiWriteSlaves(0).BID(0 downto 0),
         S00_AXI_BRESP        => sAxiWriteSlaves(0).BRESP(1 downto 0),
         S00_AXI_BVALID       => sAxiWriteSlaves(0).BVALID,
         S00_AXI_BREADY       => sAxiWriteMasters(0).BREADY,
         S00_AXI_ARID         => sAxiReadMasters(0).ARID(0 downto 0),
         S00_AXI_ARADDR       => sAxiReadMasters(0).ARADDR(32 downto 0),
         S00_AXI_ARLEN        => sAxiReadMasters(0).ARLEN(7 downto 0),
         S00_AXI_ARSIZE       => sAxiReadMasters(0).ARSIZE(2 downto 0),
         S00_AXI_ARBURST      => sAxiReadMasters(0).ARBURST(1 downto 0),
         S00_AXI_ARLOCK       => sAxiReadMasters(0).ARLOCK(0),
         S00_AXI_ARCACHE      => sAxiReadMasters(0).ARCACHE(3 downto 0),
         S00_AXI_ARPROT       => sAxiReadMasters(0).ARPROT(2 downto 0),
         S00_AXI_ARQOS        => sAxiReadMasters(0).ARQOS(3 downto 0),
         S00_AXI_ARVALID      => sAxiReadMasters(0).ARVALID,
         S00_AXI_ARREADY      => sAxiReadSlaves(0).ARREADY,
         S00_AXI_RID          => sAxiReadSlaves(0).RID(0 downto 0),
         S00_AXI_RDATA        => sAxiReadSlaves(0).RDATA(31 downto 0),
         S00_AXI_RRESP        => sAxiReadSlaves(0).RRESP(1 downto 0),
         S00_AXI_RLAST        => sAxiReadSlaves(0).RLAST,
         S00_AXI_RVALID       => sAxiReadSlaves(0).RVALID,
         S00_AXI_RREADY       => sAxiReadMasters(0).RREADY,
         -- Port 1
         S01_AXI_ARESET_OUT_N => open,
         S01_AXI_ACLK         => axiClk,
         S01_AXI_AWID         => sAxiWriteMasters(1).AWID(0 downto 0),
         S01_AXI_AWADDR       => sAxiWriteMasters(1).AWADDR(32 downto 0),
         S01_AXI_AWLEN        => sAxiWriteMasters(1).AWLEN(7 downto 0),
         S01_AXI_AWSIZE       => sAxiWriteMasters(1).AWSIZE(2 downto 0),
         S01_AXI_AWBURST      => sAxiWriteMasters(1).AWBURST(1 downto 0),
         S01_AXI_AWLOCK       => sAxiWriteMasters(1).AWLOCK(0),
         S01_AXI_AWCACHE      => sAxiWriteMasters(1).AWCACHE(3 downto 0),
         S01_AXI_AWPROT       => sAxiWriteMasters(1).AWPROT(2 downto 0),
         S01_AXI_AWQOS        => sAxiWriteMasters(1).AWQOS(3 downto 0),
         S01_AXI_AWVALID      => sAxiWriteMasters(1).AWVALID,
         S01_AXI_AWREADY      => sAxiWriteSlaves(1).AWREADY,
         S01_AXI_WDATA        => sAxiWriteMasters(1).WDATA(127 downto 0),
         S01_AXI_WSTRB        => sAxiWriteMasters(1).WSTRB(15 downto 0),
         S01_AXI_WLAST        => sAxiWriteMasters(1).WLAST,
         S01_AXI_WVALID       => sAxiWriteMasters(1).WVALID,
         S01_AXI_WREADY       => sAxiWriteSlaves(1).WREADY,
         S01_AXI_BID          => sAxiWriteSlaves(1).BID(0 downto 0),
         S01_AXI_BRESP        => sAxiWriteSlaves(1).BRESP(1 downto 0),
         S01_AXI_BVALID       => sAxiWriteSlaves(1).BVALID,
         S01_AXI_BREADY       => sAxiWriteMasters(1).BREADY,
         S01_AXI_ARID         => sAxiReadMasters(1).ARID(0 downto 0),
         S01_AXI_ARADDR       => sAxiReadMasters(1).ARADDR(32 downto 0),
         S01_AXI_ARLEN        => sAxiReadMasters(1).ARLEN(7 downto 0),
         S01_AXI_ARSIZE       => sAxiReadMasters(1).ARSIZE(2 downto 0),
         S01_AXI_ARBURST      => sAxiReadMasters(1).ARBURST(1 downto 0),
         S01_AXI_ARLOCK       => sAxiReadMasters(1).ARLOCK(0),
         S01_AXI_ARCACHE      => sAxiReadMasters(1).ARCACHE(3 downto 0),
         S01_AXI_ARPROT       => sAxiReadMasters(1).ARPROT(2 downto 0),
         S01_AXI_ARQOS        => sAxiReadMasters(1).ARQOS(3 downto 0),
         S01_AXI_ARVALID      => sAxiReadMasters(1).ARVALID,
         S01_AXI_ARREADY      => sAxiReadSlaves(1).ARREADY,
         S01_AXI_RID          => sAxiReadSlaves(1).RID(0 downto 0),
         S01_AXI_RDATA        => sAxiReadSlaves(1).RDATA(127 downto 0),
         S01_AXI_RRESP        => sAxiReadSlaves(1).RRESP(1 downto 0),
         S01_AXI_RLAST        => sAxiReadSlaves(1).RLAST,
         S01_AXI_RVALID       => sAxiReadSlaves(1).RVALID,
         S01_AXI_RREADY       => sAxiReadMasters(1).RREADY,
         -- Port 2
         S02_AXI_ARESET_OUT_N => open,
         S02_AXI_ACLK         => axiClk,
         S02_AXI_AWID         => sAxiWriteMasters(2).AWID(0 downto 0),
         S02_AXI_AWADDR       => sAxiWriteMasters(2).AWADDR(32 downto 0),
         S02_AXI_AWLEN        => sAxiWriteMasters(2).AWLEN(7 downto 0),
         S02_AXI_AWSIZE       => sAxiWriteMasters(2).AWSIZE(2 downto 0),
         S02_AXI_AWBURST      => sAxiWriteMasters(2).AWBURST(1 downto 0),
         S02_AXI_AWLOCK       => sAxiWriteMasters(2).AWLOCK(0),
         S02_AXI_AWCACHE      => sAxiWriteMasters(2).AWCACHE(3 downto 0),
         S02_AXI_AWPROT       => sAxiWriteMasters(2).AWPROT(2 downto 0),
         S02_AXI_AWQOS        => sAxiWriteMasters(2).AWQOS(3 downto 0),
         S02_AXI_AWVALID      => sAxiWriteMasters(2).AWVALID,
         S02_AXI_AWREADY      => sAxiWriteSlaves(2).AWREADY,
         S02_AXI_WDATA        => sAxiWriteMasters(2).WDATA(127 downto 0),
         S02_AXI_WSTRB        => sAxiWriteMasters(2).WSTRB(15 downto 0),
         S02_AXI_WLAST        => sAxiWriteMasters(2).WLAST,
         S02_AXI_WVALID       => sAxiWriteMasters(2).WVALID,
         S02_AXI_WREADY       => sAxiWriteSlaves(2).WREADY,
         S02_AXI_BID          => sAxiWriteSlaves(2).BID(0 downto 0),
         S02_AXI_BRESP        => sAxiWriteSlaves(2).BRESP(1 downto 0),
         S02_AXI_BVALID       => sAxiWriteSlaves(2).BVALID,
         S02_AXI_BREADY       => sAxiWriteMasters(2).BREADY,
         S02_AXI_ARID         => sAxiReadMasters(2).ARID(0 downto 0),
         S02_AXI_ARADDR       => sAxiReadMasters(2).ARADDR(32 downto 0),
         S02_AXI_ARLEN        => sAxiReadMasters(2).ARLEN(7 downto 0),
         S02_AXI_ARSIZE       => sAxiReadMasters(2).ARSIZE(2 downto 0),
         S02_AXI_ARBURST      => sAxiReadMasters(2).ARBURST(1 downto 0),
         S02_AXI_ARLOCK       => sAxiReadMasters(2).ARLOCK(0),
         S02_AXI_ARCACHE      => sAxiReadMasters(2).ARCACHE(3 downto 0),
         S02_AXI_ARPROT       => sAxiReadMasters(2).ARPROT(2 downto 0),
         S02_AXI_ARQOS        => sAxiReadMasters(2).ARQOS(3 downto 0),
         S02_AXI_ARVALID      => sAxiReadMasters(2).ARVALID,
         S02_AXI_ARREADY      => sAxiReadSlaves(2).ARREADY,
         S02_AXI_RID          => sAxiReadSlaves(2).RID(0 downto 0),
         S02_AXI_RDATA        => sAxiReadSlaves(2).RDATA(127 downto 0),
         S02_AXI_RRESP        => sAxiReadSlaves(2).RRESP(1 downto 0),
         S02_AXI_RLAST        => sAxiReadSlaves(2).RLAST,
         S02_AXI_RVALID       => sAxiReadSlaves(2).RVALID,
         S02_AXI_RREADY       => sAxiReadMasters(2).RREADY,
         -- Port 3
         S03_AXI_ARESET_OUT_N => open,
         S03_AXI_ACLK         => axiClk,
         S03_AXI_AWID         => sAxiWriteMasters(3).AWID(0 downto 0),
         S03_AXI_AWADDR       => sAxiWriteMasters(3).AWADDR(32 downto 0),
         S03_AXI_AWLEN        => sAxiWriteMasters(3).AWLEN(7 downto 0),
         S03_AXI_AWSIZE       => sAxiWriteMasters(3).AWSIZE(2 downto 0),
         S03_AXI_AWBURST      => sAxiWriteMasters(3).AWBURST(1 downto 0),
         S03_AXI_AWLOCK       => sAxiWriteMasters(3).AWLOCK(0),
         S03_AXI_AWCACHE      => sAxiWriteMasters(3).AWCACHE(3 downto 0),
         S03_AXI_AWPROT       => sAxiWriteMasters(3).AWPROT(2 downto 0),
         S03_AXI_AWQOS        => sAxiWriteMasters(3).AWQOS(3 downto 0),
         S03_AXI_AWVALID      => sAxiWriteMasters(3).AWVALID,
         S03_AXI_AWREADY      => sAxiWriteSlaves(3).AWREADY,
         S03_AXI_WDATA        => sAxiWriteMasters(3).WDATA(127 downto 0),
         S03_AXI_WSTRB        => sAxiWriteMasters(3).WSTRB(15 downto 0),
         S03_AXI_WLAST        => sAxiWriteMasters(3).WLAST,
         S03_AXI_WVALID       => sAxiWriteMasters(3).WVALID,
         S03_AXI_WREADY       => sAxiWriteSlaves(3).WREADY,
         S03_AXI_BID          => sAxiWriteSlaves(3).BID(0 downto 0),
         S03_AXI_BRESP        => sAxiWriteSlaves(3).BRESP(1 downto 0),
         S03_AXI_BVALID       => sAxiWriteSlaves(3).BVALID,
         S03_AXI_BREADY       => sAxiWriteMasters(3).BREADY,
         S03_AXI_ARID         => sAxiReadMasters(3).ARID(0 downto 0),
         S03_AXI_ARADDR       => sAxiReadMasters(3).ARADDR(32 downto 0),
         S03_AXI_ARLEN        => sAxiReadMasters(3).ARLEN(7 downto 0),
         S03_AXI_ARSIZE       => sAxiReadMasters(3).ARSIZE(2 downto 0),
         S03_AXI_ARBURST      => sAxiReadMasters(3).ARBURST(1 downto 0),
         S03_AXI_ARLOCK       => sAxiReadMasters(3).ARLOCK(0),
         S03_AXI_ARCACHE      => sAxiReadMasters(3).ARCACHE(3 downto 0),
         S03_AXI_ARPROT       => sAxiReadMasters(3).ARPROT(2 downto 0),
         S03_AXI_ARQOS        => sAxiReadMasters(3).ARQOS(3 downto 0),
         S03_AXI_ARVALID      => sAxiReadMasters(3).ARVALID,
         S03_AXI_ARREADY      => sAxiReadSlaves(3).ARREADY,
         S03_AXI_RID          => sAxiReadSlaves(3).RID(0 downto 0),
         S03_AXI_RDATA        => sAxiReadSlaves(3).RDATA(127 downto 0),
         S03_AXI_RRESP        => sAxiReadSlaves(3).RRESP(1 downto 0),
         S03_AXI_RLAST        => sAxiReadSlaves(3).RLAST,
         S03_AXI_RVALID       => sAxiReadSlaves(3).RVALID,
         S03_AXI_RREADY       => sAxiReadMasters(3).RREADY,
         
         -- MIG DDR Port
         M00_AXI_ARESET_OUT_N => open,
         M00_AXI_ACLK         => axiClk,
         M00_AXI_AWID         => mAxiWriteMasters.AWID(3 downto 0),
         M00_AXI_AWADDR       => mAxiWriteMasters.AWADDR(32 downto 0),
         M00_AXI_AWLEN        => mAxiWriteMasters.AWLEN(7 downto 0),
         M00_AXI_AWSIZE       => mAxiWriteMasters.AWSIZE(2 downto 0),
         M00_AXI_AWBURST      => mAxiWriteMasters.AWBURST(1 downto 0),
         M00_AXI_AWLOCK       => mAxiWriteMasters.AWLOCK(0),
         M00_AXI_AWCACHE      => mAxiWriteMasters.AWCACHE(3 downto 0),
         M00_AXI_AWPROT       => mAxiWriteMasters.AWPROT(2 downto 0),
         M00_AXI_AWQOS        => mAxiWriteMasters.AWQOS(3 downto 0),
         M00_AXI_AWVALID      => mAxiWriteMasters.AWVALID,
         M00_AXI_AWREADY      => mAxiWriteSlaves.AWREADY,
         M00_AXI_WDATA        => mAxiWriteMasters.WDATA(511 downto 0),
         M00_AXI_WSTRB        => mAxiWriteMasters.WSTRB(63 downto 0),
         M00_AXI_WLAST        => mAxiWriteMasters.WLAST,
         M00_AXI_WVALID       => mAxiWriteMasters.WVALID,
         M00_AXI_WREADY       => mAxiWriteSlaves.WREADY,
         M00_AXI_BID          => mAxiWriteSlaves.BID(3 downto 0),
         M00_AXI_BRESP        => mAxiWriteSlaves.BRESP(1 downto 0),
         M00_AXI_BVALID       => mAxiWriteSlaves.BVALID,
         M00_AXI_BREADY       => mAxiWriteMasters.BREADY,
         M00_AXI_ARID         => mAxiReadMasters.ARID(3 downto 0),
         M00_AXI_ARADDR       => mAxiReadMasters.ARADDR(32 downto 0),
         M00_AXI_ARLEN        => mAxiReadMasters.ARLEN(7 downto 0),
         M00_AXI_ARSIZE       => mAxiReadMasters.ARSIZE(2 downto 0),
         M00_AXI_ARBURST      => mAxiReadMasters.ARBURST(1 downto 0),
         M00_AXI_ARLOCK       => mAxiReadMasters.ARLOCK(0),
         M00_AXI_ARCACHE      => mAxiReadMasters.ARCACHE(3 downto 0),
         M00_AXI_ARPROT       => mAxiReadMasters.ARPROT(2 downto 0),
         M00_AXI_ARQOS        => mAxiReadMasters.ARQOS(3 downto 0),
         M00_AXI_ARVALID      => mAxiReadMasters.ARVALID,
         M00_AXI_ARREADY      => mAxiReadSlaves.ARREADY,
         M00_AXI_RID          => mAxiReadSlaves.RID(3 downto 0),
         M00_AXI_RDATA        => mAxiReadSlaves.RDATA(511 downto 0),
         M00_AXI_RRESP        => mAxiReadSlaves.RRESP(1 downto 0),
         M00_AXI_RLAST        => mAxiReadSlaves.RLAST,
         M00_AXI_RVALID       => mAxiReadSlaves.RVALID,
         M00_AXI_RREADY       => mAxiReadMasters.RREADY);


end architecture rtl;


