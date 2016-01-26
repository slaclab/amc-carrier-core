-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEmptyApp.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2015-10-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Application's Top Level
-- 
-- Note: Common-to-Application interface defined here (see URL below)
--       https://confluence.slac.stanford.edu/x/rLyMCw
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
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierEmptyApp is
   generic (
      TPD_G               : time                := 1 ns;
      SIM_SPEEDUP_G       : boolean             := false;
      AXI_ERROR_RESP_G    : slv(1 downto 0)     := AXI_RESP_DECERR_C;
      DIAGNOSTIC_SIZE_G   : positive            := 1;
      DIAGNOSTIC_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(4));
   port (
      -----------------------
      -- Application Ports --
      -----------------------
      -- -- AMC's JESD Ports
      -- jesdRxP       : in    Slv7Array(1 downto 0);
      -- jesdRxN       : in    Slv7Array(1 downto 0);
      -- jesdTxP       : out   Slv7Array(1 downto 0);
      -- jesdTxN       : out   Slv7Array(1 downto 0);
      -- jesdClkP      : in    Slv3Array(1 downto 0);
      -- jesdClkN      : in    Slv3Array(1 downto 0);
      -- -- AMC's JTAG Ports
      -- jtagPri       : inout Slv5Array(1 downto 0);
      -- jtagSec       : inout Slv5Array(1 downto 0);
      -- -- AMC's FPGA Clock Ports
      -- fpgaClkP      : inout Slv2Array(1 downto 0);
      -- fpgaClkN      : inout Slv2Array(1 downto 0);
      -- -- AMC's System Reference Ports
      -- sysRefP       : inout Slv4Array(1 downto 0);
      -- sysRefN       : inout Slv4Array(1 downto 0);
      -- -- AMC's Sync Ports
      -- syncInP       : inout Slv10Array(1 downto 0);
      -- syncInN       : inout Slv10Array(1 downto 0);
      -- syncOutP      : inout Slv4Array(1 downto 0);
      -- syncOutN      : inout Slv4Array(1 downto 0);
      -- -- AMC's Spare Ports
      -- spareP        : inout Slv16Array(1 downto 0);
      -- spareN        : inout Slv16Array(1 downto 0);    
      -- -- RTM's Low Speed Ports
      -- rtmLsP        : inout slv(53 downto 0);
      -- rtmLsN        : inout slv(53 downto 0);
      -- -- RTM's High Speed Ports
      -- rtmHsRxP      : in    sl;
      -- rtmHsRxN      : in    sl;
      -- rtmHsTxP      : out   sl;
      -- rtmHsTxN      : out   sl;
      -- genClkP       : in    sl;
      -- genClkN       : in    sl;   
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      regClk            : out sl;
      regRst            : out sl;
      regReadMaster     : in  AxiLiteReadMasterType;
      regReadSlave      : out AxiLiteReadSlaveType;
      regWriteMaster    : in  AxiLiteWriteMasterType;
      regWriteSlave     : out AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk         : out sl;
      timingRst         : out sl;
      timingBus         : in  TimingBusType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk     : out sl;
      diagnosticRst     : out sl;
      diagnosticBus     : out DiagnosticBusType;
      diagnosticMasters : out AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves  : in  AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      -- Support Reference Clocks and Resets
      recTimingClk      : in  sl;
      recTimingRst      : in  sl;
      ref156MHzClk      : in  sl;
      ref156MHzRst      : in  sl);
end AmcCarrierEmptyApp;

architecture top_level_app of AmcCarrierEmptyApp is

   signal clk : sl;
   signal rst : sl;

begin

   clk                         <= ref156MHzClk;
   rst                         <= ref156MHzRst;
   timingClk                   <= clk;
   timingRst                   <= rst;
   diagnosticClk               <= clk;
   diagnosticRst               <= rst;
   diagnosticBus.strobe        <= timingBus.strobe;
   diagnosticBus.timingMessage <= timingBus.message;
   diagnosticBus.data          <= (others => x"3F800000");  -- 1.0
   diagnosticMasters           <= (others => AXI_STREAM_MASTER_INIT_C);

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => clk,
         axiClkRst      => rst,
         axiReadMaster  => regReadMaster,
         axiReadSlave   => regReadSlave,
         axiWriteMaster => regWriteMaster,
         axiWriteSlave  => regWriteSlave);

end top_level_app;
