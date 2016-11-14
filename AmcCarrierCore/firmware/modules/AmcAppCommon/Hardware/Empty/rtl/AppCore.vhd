-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : AppCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2016-11-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Application Core's Top Level
--
-- Note: Common-to-Application interface defined in HPS ESD: LCLSII-2.7-ES-0536
--
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 AMC Carrier Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 AMC Carrier Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.jesd204bpkg.all;
use work.AppTopPkg.all;

entity AppCore is
   generic (
      TPD_G            : time             := 1 ns;
      SIM_SPEEDUP_G    : boolean          := false;
      SIMULATION_G     : boolean          := false;
      AXI_CLK_FREQ_G   : real             := 156.25E+6;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := x"80000000";
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);      
   port (
      -- Clocks and resets   
      jesdClk          : in    slv(1 downto 0);
      jesdRst          : in    slv(1 downto 0);
      jesdClk2x        : in    slv(1 downto 0);
      jesdRst2x        : in    slv(1 downto 0);
      -- DaqMux/Trig Interface (recTimingClk domain) 
      freezeHw         : out   slv(1 downto 0);
      evrTrig          : in    AppTopTrigType;
      userTrig         : out   slv(1 downto 0);
      -- JESD SYNC Interface (jesdClk[1:0] domain)
      jesdSysRef       : out   slv(1 downto 0);
      jesdRxSync       : in    slv(1 downto 0);
      jesdTxSync       : out   slv(1 downto 0);
      -- ADC/DAC/Debug Interface (jesdClk[1:0] domain)
      adcValids        : in    Slv7Array(1 downto 0);
      adcValues        : in    sampleDataVectorArray(1 downto 0, 6 downto 0);
      dacValids        : out   Slv7Array(1 downto 0);
      dacValues        : out   sampleDataVectorArray(1 downto 0, 6 downto 0);
      debugValids      : out   Slv4Array(1 downto 0);
      debugValues      : out   sampleDataVectorArray(1 downto 0, 3 downto 0);
      -- AXI-Lite Interface (axilClk domain) [0x8FFFFFFF:0x80000000]
      axilClk          : in    sl;
      axilRst          : in    sl;
      axilReadMaster   : in    AxiLiteReadMasterType;
      axilReadSlave    : out   AxiLiteReadSlaveType;
      axilWriteMaster  : in    AxiLiteWriteMasterType;
      axilWriteSlave   : out   AxiLiteWriteSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Timing Interface (recTimingClk domain) 
      timingBus        : in    TimingBusType;
      timingPhy        : out   TimingPhyType;
      timingPhyClk     : in    sl;
      timingPhyRst     : in    sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk    : out   sl;
      diagnosticRst    : out   sl;
      diagnosticBus    : out   DiagnosticBusType;
      -- Backplane Messaging Interface (bpMsgClk domain)
      bpMsgClk         : out   sl;
      bpMsgRst         : out   sl;
      bpMsgBus         : in    BpMsgBusArray(BP_MSG_SIZE_C-1 downto 0);
      -- Application Debug Interface (ref156MHzClk domain)
      obAppDebugMaster : out   AxiStreamMasterType;
      obAppDebugSlave  : in    AxiStreamSlaveType;
      ibAppDebugMaster : in    AxiStreamMasterType;
      ibAppDebugSlave  : out   AxiStreamSlaveType;
      -- BSI Interface (bsiClk domain) 
      bsiClk           : out   sl;
      bsiRst           : out   sl;
      bsiBus           : in    BsiBusType;
      -- MPS Concentrator Interface (ref156MHzClk domain)
      mpsObMasters     : in    AxiStreamMasterArray(14 downto 0);
      mpsObSlaves      : out   AxiStreamSlaveArray(14 downto 0);
      -- Reference Clocks and Resets
      recTimingClk     : in    sl;
      recTimingRst     : in    sl;
      ref125MHzClk     : in    sl;
      ref125MHzRst     : in    sl;
      ref156MHzClk     : in    sl;
      ref156MHzRst     : in    sl;
      ref312MHzClk     : in    sl;
      ref312MHzRst     : in    sl;
      ref625MHzClk     : in    sl;
      ref625MHzRst     : in    sl;
      gthFabClk        : in    sl;
      ethPhyReady      : in    sl;
      -----------------------
      -- Application Ports --
      -----------------------
      -- AMC's JTAG Ports
      jtagPri          : inout Slv5Array(1 downto 0);
      jtagSec          : inout Slv5Array(1 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP         : inout Slv2Array(1 downto 0);
      fpgaClkN         : inout Slv2Array(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP          : inout Slv4Array(1 downto 0);
      sysRefN          : inout Slv4Array(1 downto 0);
      -- AMC's Sync Ports
      syncInP          : inout Slv10Array(1 downto 0);
      syncInN          : inout Slv10Array(1 downto 0);
      syncOutP         : inout Slv4Array(1 downto 0);
      syncOutN         : inout Slv4Array(1 downto 0);
      -- AMC's Spare Ports
      spareP           : inout Slv16Array(1 downto 0);
      spareN           : inout Slv16Array(1 downto 0);
      -- RTM's Low Speed Ports
      rtmLsP           : inout slv(53 downto 0);
      rtmLsN           : inout slv(53 downto 0);
      -- RTM's High Speed Ports
      rtmHsRxP         : in    sl;
      rtmHsRxN         : in    sl;
      rtmHsTxP         : out   sl;
      rtmHsTxN         : out   sl;
      genClkP          : in    sl;
      genClkN          : in    sl);
end AppCore;

architecture mapping of AppCore is

begin
   
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Bus
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

   freezeHw    <= (others => '0');
   userTrig    <= (others => '0');
   jesdSysRef  <= (others => '0');
   jesdTxSync  <= (others => '0');
   dacValids   <= (others => (others => '0'));
   dacValues   <= (others => (others => x"0000_0000"));
   debugValids <= (others => (others => '0'));
   debugValues <= (others => (others => x"0000_0000"));
   timingPhy   <= TIMING_PHY_INIT_C;

   diagnosticClk    <= '0';
   diagnosticRst    <= '0';
   diagnosticBus    <= DIAGNOSTIC_BUS_INIT_C;
   bpMsgClk         <= '0';
   bpMsgRst         <= '0';
   obAppDebugMaster <= AXI_STREAM_MASTER_INIT_C;
   ibAppDebugSlave  <= AXI_STREAM_SLAVE_FORCE_C;
   bsiClk           <= '0';
   bsiRst           <= '0';
   mpsObSlaves      <= (others => AXI_STREAM_SLAVE_FORCE_C);
   
end mapping;
