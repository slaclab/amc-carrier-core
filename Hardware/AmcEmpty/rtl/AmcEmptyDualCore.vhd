-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcEmptyDualCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-06
-- Last update: 2017-02-06
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
use work.AxiLitePkg.all;

entity AmcEmptyDualCore is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------
      -- AMC's JTAG Ports
      jtagPri         : inout Slv5Array(1 downto 0);
      jtagSec         : inout Slv5Array(1 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP        : inout Slv2Array(1 downto 0);
      fpgaClkN        : inout Slv2Array(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP         : inout Slv4Array(1 downto 0);
      sysRefN         : inout Slv4Array(1 downto 0);
      -- AMC's Sync Ports
      syncInP         : inout Slv4Array(1 downto 0);
      syncInN         : inout Slv4Array(1 downto 0);
      syncOutP        : inout Slv10Array(1 downto 0);
      syncOutN        : inout Slv10Array(1 downto 0);
      -- AMC's Spare Ports
      spareP          : inout Slv16Array(1 downto 0);
      spareN          : inout Slv16Array(1 downto 0));
end AmcEmptyDualCore;

architecture mapping of AmcEmptyDualCore is

begin

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

   -----------
   -- AMC Core
   -----------
   GEN_AMC : for i in 1 downto 0 generate
      U_AMC : entity work.AmcEmptyCore
         generic map (
            TPD_G => TPD_G)
         port map(
            -- AXI-Lite Interface
            axilClk         => '0',
            axilRst         => '0',
            axilReadMaster  => AXI_LITE_READ_MASTER_INIT_C,
            axilReadSlave   => open,
            axilWriteMaster => AXI_LITE_WRITE_MASTER_INIT_C,
            axilWriteSlave  => open,
            -----------------------
            -- Application Ports --
            -----------------------
            -- AMC's JTAG Ports
            jtagPri         => jtagPri(i),
            jtagSec         => jtagSec(i),
            -- AMC's FPGA Clock Ports
            fpgaClkP        => fpgaClkP(i),
            fpgaClkN        => fpgaClkN(i),
            -- AMC's System Reference Ports
            sysRefP         => sysRefP(i),
            sysRefN         => sysRefN(i),
            -- AMC's Sync Ports
            syncInP         => syncInP(i),
            syncInN         => syncInN(i),
            syncOutP        => syncOutP(i),
            syncOutN        => syncOutN(i),
            -- AMC's Spare Ports
            spareP          => spareP(i),
            spareN          => spareN(i));
   end generate GEN_AMC;

end mapping;
