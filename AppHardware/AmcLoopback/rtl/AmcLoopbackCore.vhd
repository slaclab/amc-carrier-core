-------------------------------------------------------------------------------
-- File       : AmcLoopbackCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-06
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_04_CXX
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
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcLoopbackCore is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Loopback Interface
      loopbackIn      : in    slv(23 downto 0);
      loopbackOut     : out   slv(23 downto 0);
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
end AmcLoopbackCore;

architecture mapping of AmcLoopbackCore is

begin

   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

   PRI_SYNCOUT :
   for i in 4 downto 0 generate
      LB_OUT : OBUFDS
         port map (
            I  => loopbackIn(i+0),
            O  => syncOutP((2*i)+0),
            OB => syncOutN((2*i)+0));
      LB_IN : IBUFDS
         port map (
            I  => syncOutP((2*i)+1),
            IB => syncOutN((2*i)+1),
            O  => loopbackOut(i+0));
   end generate PRI_SYNCOUT;

   SPARE :
   for i in 7 downto 0 generate
      LB_OUT : OBUFDS
         port map (
            I  => loopbackIn(i+5),
            O  => spareP((2*i)+0),
            OB => spareN((2*i)+0));
      LB_IN : IBUFDS
         port map (
            I  => spareP((2*i)+1),
            IB => spareN((2*i)+1),
            O  => loopbackOut(i+5));
   end generate SPARE;

   PRI_REF_SYNC :
   for i in 3 downto 0 generate
      LB_OUT : OBUFDS
         port map (
            I  => loopbackIn(i+13),
            O  => sysRefP(i),
            OB => sysRefN(i));
      LB_IN : IBUFDS
         port map (
            I  => syncInP(i),
            IB => syncInN(i),
            O  => loopbackOut(i+13));
   end generate PRI_REF_SYNC;

   LB_OUT : OBUFDS
      port map (
         I  => loopbackIn(17),
         O  => fpgaClkP(0),
         OB => fpgaClkN(0));
   LB_IN : IBUFDS
      port map (
         I  => fpgaClkP(1),
         IB => fpgaClkN(1),
         O  => loopbackOut(17));

   JTAG :
   for i in 4 downto 0 generate
      jtagPri(i)        <= loopbackIn(i+18);
      loopbackOut(i+18) <= jtagSec(i);
   end generate JTAG;

   -- Internal loopback
   loopbackOut(23) <= loopbackIn(23);

end mapping;
