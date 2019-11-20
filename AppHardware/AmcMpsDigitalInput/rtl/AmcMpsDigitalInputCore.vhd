-------------------------------------------------------------------------------
-- File       : AmcMpsDigitalInputCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-06
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_06_CXX
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

entity AmcMpsDigitalInputCore is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- MPS Digital Inputs
      amcMpsDin       : out   slv(31 downto 0);
      -- MISC. Digital I/O
      lemoDin         : out   slv(1 downto 0);
      lemoDout        : in    slv(1 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl                     := '0';
      axilRst         : in    sl                     := '0';
      axilReadMaster  : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- AMC's JTAG Ports
      jtagPri         : inout slv(4 downto 0);
      jtagSec         : inout slv(4 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP        : inout slv(1 downto 0);
      fpgaClkN        : inout slv(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP         : inout slv(3 downto 0);
      sysRefN         : inout slv(3 downto 0);
      -- AMC's Sync Ports
      syncInP         : inout slv(3 downto 0);
      syncInN         : inout slv(3 downto 0);
      syncOutP        : inout slv(9 downto 0);
      syncOutN        : inout slv(9 downto 0);
      -- AMC's Spare Ports
      spareP          : inout slv(15 downto 0);
      spareN          : inout slv(15 downto 0));
end AmcMpsDigitalInputCore;

architecture mapping of AmcMpsDigitalInputCore is

begin

   lemoDin(0) <= jtagSec(0);
   lemoDin(1) <= jtagSec(1);

   jtagPri(0) <= lemoDout(0);
   jtagPri(1) <= lemoDout(1);

   GEN_VEC :
   for i in 15 downto 0 generate
      amcMpsDin(i+0)  <= spareP(i);
      amcMpsDin(i+16) <= spareN(i);
   end generate GEN_VEC;

   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

end mapping;
