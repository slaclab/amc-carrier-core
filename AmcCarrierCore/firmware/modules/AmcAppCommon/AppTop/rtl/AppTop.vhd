-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : AppTop.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2016-11-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Application's Top Level
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

entity AppTop is
   generic (
      TPD_G                : time                     := 1 ns;
      SIM_SPEEDUP_G        : boolean                  := false;
      SIMULATION_G         : boolean                  := false;
      JESD_DRP_EN_G        : boolean                  := false;
      JESD_RX_LANE_G       : NaturalArray(1 downto 0) := (others => 0);
      JESD_TX_LANE_G       : NaturalArray(1 downto 0) := (others => 0);
      JESD_RX_POLARITY_G   : Slv7Array(1 downto 0)    := (others => "0000000");
      JESD_TX_POLARITY_G   : Slv7Array(1 downto 0)    := (others => "0000000");
      JESD_REF_SEL_G       : Slv2Array(1 downto 0)    := (others => DEV_CLK2_SEL_C);
      NUM_OF_TRIG_PULSES_G : positive range 1 to 16   := 3;
      DELAY_WIDTH_G        : integer range 1 to 32    := 32;
      PULSE_WIDTH_G        : integer range 1 to 32    := 32;
      AXI_CLK_FREQ_G       : real                     := 156.25E+6;
      AXI_ERROR_RESP_G     : slv(1 downto 0)          := AXI_RESP_DECERR_C);
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      regClk               : out   sl;
      regRst               : out   sl;
      regReadMaster        : in    AxiLiteReadMasterType;
      regReadSlave         : out   AxiLiteReadSlaveType;
      regWriteMaster       : in    AxiLiteWriteMasterType;
      regWriteSlave        : out   AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk            : out   sl;
      timingRst            : out   sl;
      timingBus            : in    TimingBusType;
      timingPhy            : out   TimingPhyType;
      timingPhyClk         : in    sl;
      timingPhyRst         : in    sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : out   sl;
      diagnosticRst        : out   sl;
      diagnosticBus        : out   DiagnosticBusType;
      -- Waveform interface (waveformClk domain)
      waveformClk          : in    sl;
      waveformRst          : in    sl;
      obAppWaveformMasters : out   WaveformMasterArrayType;
      obAppWaveformSlaves  : in    WaveformSlaveArrayType;
      ibAppWaveformMasters : in    WaveformMasterArrayType;
      ibAppWaveformSlaves  : out   WaveformSlaveArrayType;
      -- Backplane Messaging Interface (bpMsgClk domain)
      bpMsgClk             : out   sl;
      bpMsgRst             : out   sl;
      bpMsgBus             : in    BpMsgBusArray(BP_MSG_SIZE_C-1 downto 0);
      -- Application Debug Interface (ref156MHzClk domain)
      obAppDebugMaster     : out   AxiStreamMasterType;
      obAppDebugSlave      : in    AxiStreamSlaveType;
      ibAppDebugMaster     : in    AxiStreamMasterType;
      ibAppDebugSlave      : out   AxiStreamSlaveType;
      -- BSI Interface (bsiClk domain) 
      bsiClk               : out   sl;
      bsiRst               : out   sl;
      bsiBus               : in    BsiBusType;
      -- MPS Concentrator Interface (ref156MHzClk domain)
      mpsObMasters         : in    AxiStreamMasterArray(14 downto 0);
      mpsObSlaves          : out   AxiStreamSlaveArray(14 downto 0);
      -- Reference Clocks and Resets
      recTimingClk         : in    sl;
      recTimingRst         : in    sl;
      ref125MHzClk         : in    sl;
      ref125MHzRst         : in    sl;
      ref156MHzClk         : in    sl;
      ref156MHzRst         : in    sl;
      ref312MHzClk         : in    sl;
      ref312MHzRst         : in    sl;
      ref625MHzClk         : in    sl;
      ref625MHzRst         : in    sl;
      gthFabClk            : in    sl;
      ethPhyReady          : in    sl;
      -----------------------
      -- Application Ports --
      -----------------------
      -- AMC's JESD Ports
      jesdRxP              : in    Slv7Array(1 downto 0);
      jesdRxN              : in    Slv7Array(1 downto 0);
      jesdTxP              : out   Slv7Array(1 downto 0);
      jesdTxN              : out   Slv7Array(1 downto 0);
      jesdClkP             : in    Slv3Array(1 downto 0);
      jesdClkN             : in    Slv3Array(1 downto 0);
      -- AMC's JTAG Ports
      jtagPri              : inout Slv5Array(1 downto 0);
      jtagSec              : inout Slv5Array(1 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP             : inout Slv2Array(1 downto 0);
      fpgaClkN             : inout Slv2Array(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP              : inout Slv4Array(1 downto 0);
      sysRefN              : inout Slv4Array(1 downto 0);
      -- AMC's Sync Ports
      syncInP              : inout Slv4Array(1 downto 0);
      syncInN              : inout Slv4Array(1 downto 0);
      syncOutP             : inout Slv10Array(1 downto 0);
      syncOutN             : inout Slv10Array(1 downto 0);
      -- AMC's Spare Ports
      spareP               : inout Slv16Array(1 downto 0);
      spareN               : inout Slv16Array(1 downto 0);
      -- RTM's Low Speed Ports
      rtmLsP               : inout slv(53 downto 0);
      rtmLsN               : inout slv(53 downto 0);
      -- RTM's High Speed Ports
      rtmHsRxP             : in    sl;
      rtmHsRxN             : in    sl;
      rtmHsTxP             : out   sl;
      rtmHsTxN             : out   sl;
      genClkP              : in    sl;
      genClkN              : in    sl);
end AppTop;

architecture mapping of AppTop is

   constant NUM_AXI_MASTERS_C : natural := 6;

   constant CORE_INDEX_C     : natural := 0;
   constant TIMING_INDEX_C   : natural := 1;
   constant DAQ_MUX0_INDEX_C : natural := 2;
   constant DAQ_MUX1_INDEX_C : natural := 3;
   constant JESD0_INDEX_C    : natural := 4;
   constant JESD1_INDEX_C    : natural := 5;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, x"80000000", 31, 28);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal axilClk : sl;
   signal axilRst : sl;

   signal evrTrig     : AppTopTrigType;
   signal trigCascBay : slv(2 downto 0);
   signal armCascBay  : slv(2 downto 0);
   signal trigHw      : slv(1 downto 0);
   signal userTrig    : slv(1 downto 0);
   signal freezeHw    : slv(1 downto 0);

   signal jesdClk    : slv(1 downto 0);
   signal jesdRst    : slv(1 downto 0);
   signal jesdClk2x  : slv(1 downto 0);
   signal jesdRst2x  : slv(1 downto 0);
   signal jesdSysRef : slv(1 downto 0);
   signal jesdRxSync : slv(1 downto 0);
   signal jesdTxSync : slv(1 downto 0);

   signal adcValids : Slv7Array(1 downto 0);
   signal adcValues : sampleDataVectorArray(1 downto 0, 6 downto 0);

   signal dacValids : Slv7Array(1 downto 0);
   signal dacValues : sampleDataVectorArray(1 downto 0, 6 downto 0);

   signal debugValids : Slv4Array(1 downto 0);
   signal debugValues : sampleDataVectorArray(1 downto 0, 3 downto 0);

   signal dataValids : Slv18Array(1 downto 0);

begin

   --------------------------
   -- Clock and reset mapping
   --------------------------
   axilClk   <= ref156MHzClk;
   axilRst   <= ref156MHzRst;
   regClk    <= axilClk;
   regRst    <= axilRst;
   timingClk <= recTimingClk;
   timingRst <= recTimingRst;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => regWriteMaster,
         sAxiWriteSlaves(0)  => regWriteSlave,
         sAxiReadMasters(0)  => regReadMaster,
         sAxiReadSlaves(0)   => regReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ---------------
   -- Trigger Core
   ---------------
   U_Trig : entity work.AppTopTrig
      generic map (
         TPD_G                => TPD_G,
         AXIL_BASE_ADDR_G     => AXI_CONFIG_C(TIMING_INDEX_C).baseAddr,
         AXI_ERROR_RESP_G     => AXI_ERROR_RESP_G,
         NUM_OF_TRIG_PULSES_G => NUM_OF_TRIG_PULSES_G,
         DELAY_WIDTH_G        => DELAY_WIDTH_G,
         PULSE_WIDTH_G        => PULSE_WIDTH_G)         
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave   => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TIMING_INDEX_C),
         -- Timing Interface
         recClk          => recTimingClk,
         recRst          => recTimingRst,
         timingBus_i     => timingBus,
         -- Trigger pulse outputs (recClk domain)
         evrTrig         => evrTrig);

   ---------------
   -- DAQ MUX Core
   ---------------            
   trigCascBay(2) <= trigCascBay(0);    -- to make cross and use generate
   armCascBay(2)  <= armCascBay(0);     -- to make cross and use generate

   U_DaqMux : for i in 1 downto 0 generate
      
      trigHw(i) <= evrTrig.trigPulse(0) or userTrig(i);

      ------------------
      -- DAQ MUXV2 Module
      ------------------
      U_DaqMuxV2 : entity work.DaqMuxV2
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            N_DATA_IN_G      => 18,
            N_DATA_OUT_G     => 4)
         port map (
            -- Clocks and Resets
            axiClk              => axilClk,
            axiRst              => axilRst,
            devClk_i            => jesdClk(i),
            devRst_i            => jesdRst(i),
            -- External DAQ trigger input
            trigHw_i            => trigHw(i),
            -- Cascaded Sw trigger for external connection between modules
            trigCasc_i          => trigCascBay(i+1),
            trigCasc_o          => trigCascBay(i),
            -- Cascaded Arm trigger for external connection between modules 
            armCasc_i           => armCascBay(i+1),
            armCasc_o           => armCascBay(i),
            -- Freeze buffers
            freezeHw_i          => freezeHw(i),
            -- Time-stamp and bsa (if enabled it will be added to start of data)
            timeStamp_i         => evrTrig.timeStamp,
            bsa_i               => evrTrig.bsa,
            dmod_i              => evrTrig.dmod,
            -- AXI-Lite Register Interface
            axilReadMaster      => axilReadMasters(DAQ_MUX0_INDEX_C+i),
            axilReadSlave       => axilReadSlaves(DAQ_MUX0_INDEX_C+i),
            axilWriteMaster     => axilWriteMasters(DAQ_MUX0_INDEX_C+i),
            axilWriteSlave      => axilWriteSlaves(DAQ_MUX0_INDEX_C+i),
            -- Sample data input 
            sampleDataArr_i(0)  => adcValues(i, 0),
            sampleDataArr_i(1)  => adcValues(i, 1),
            sampleDataArr_i(2)  => adcValues(i, 2),
            sampleDataArr_i(3)  => adcValues(i, 3),
            sampleDataArr_i(4)  => adcValues(i, 4),
            sampleDataArr_i(5)  => adcValues(i, 5),
            sampleDataArr_i(6)  => adcValues(i, 6),
            sampleDataArr_i(7)  => dacValues(i, 0),
            sampleDataArr_i(8)  => dacValues(i, 1),
            sampleDataArr_i(9)  => dacValues(i, 2),
            sampleDataArr_i(10) => dacValues(i, 3),
            sampleDataArr_i(11) => dacValues(i, 4),
            sampleDataArr_i(12) => dacValues(i, 5),
            sampleDataArr_i(13) => dacValues(i, 6),
            sampleDataArr_i(14) => debugValues(i, 0),
            sampleDataArr_i(15) => debugValues(i, 1),
            sampleDataArr_i(16) => debugValues(i, 2),
            sampleDataArr_i(17) => debugValues(i, 3),
            dataValidVec_i      => dataValids(i),
            -- Output AXI Streaming Interface (Has to be synced with waveform clk)
            wfClk_i             => waveformClk,
            wfRst_i             => waveformRst,
            rxAxisMasterArr_o   => obAppWaveformMasters(i),
            rxAxisSlaveArr_i(0) => obAppWaveformSlaves(i)(0).slave,
            rxAxisSlaveArr_i(1) => obAppWaveformSlaves(i)(1).slave,
            rxAxisSlaveArr_i(2) => obAppWaveformSlaves(i)(2).slave,
            rxAxisSlaveArr_i(3) => obAppWaveformSlaves(i)(3).slave,
            rxAxisCtrlArr_i(0)  => obAppWaveformSlaves(i)(0).ctrl,
            rxAxisCtrlArr_i(1)  => obAppWaveformSlaves(i)(1).ctrl,
            rxAxisCtrlArr_i(2)  => obAppWaveformSlaves(i)(2).ctrl,
            rxAxisCtrlArr_i(3)  => obAppWaveformSlaves(i)(3).ctrl);

      dataValids(i) <= debugValids(i) & dacValids(i) & adcValids(i);

   end generate U_DaqMux;

   ------------
   -- JESD Core
   ------------
   U_Jesd : for i in 1 downto 0 generate
      U_JesdCore : entity work.AppTopJesd
         generic map (
            TPD_G              => TPD_G,
            SIM_SPEEDUP_G      => SIM_SPEEDUP_G,
            SIMULATION_G       => SIMULATION_G,
            AXI_BASE_ADDR_G    => AXI_CONFIG_C(JESD0_INDEX_C+i).baseAddr,
            AXI_ERROR_RESP_G   => AXI_ERROR_RESP_G,
            JESD_DRP_EN_G      => JESD_DRP_EN_G,
            JESD_RX_LANE_G     => JESD_RX_LANE_G(i),
            JESD_TX_LANE_G     => JESD_TX_LANE_G(i),
            JESD_RX_POLARITY_G => JESD_RX_POLARITY_G(i),
            JESD_TX_POLARITY_G => JESD_TX_POLARITY_G(i),
            JESD_REF_SEL_G     => JESD_REF_SEL_G(i))         
         port map (
            -- Clock/reset/SYNC
            jesdClk         => jesdClk(i),
            jesdRst         => jesdRst(i),
            jesdClk2x       => jesdClk2x(i),
            jesdRst2x       => jesdRst2x(i),
            jesdSysRef      => jesdSysRef(i),
            jesdRxSync      => jesdRxSync(i),
            jesdTxSync      => jesdTxSync(i),
            -- ADC Interface
            adcValids       => adcValids(i),
            adcValues(0)    => adcValues(i, 0),
            adcValues(1)    => adcValues(i, 1),
            adcValues(2)    => adcValues(i, 2),
            adcValues(3)    => adcValues(i, 3),
            adcValues(4)    => adcValues(i, 4),
            adcValues(5)    => adcValues(i, 5),
            adcValues(6)    => adcValues(i, 6),
            -- DAC Interface
            dacValids       => dacValids(i),
            dacValues(0)    => dacValues(i, 0),
            dacValues(1)    => dacValues(i, 1),
            dacValues(2)    => dacValues(i, 2),
            dacValues(3)    => dacValues(i, 3),
            dacValues(4)    => dacValues(i, 4),
            dacValues(5)    => dacValues(i, 5),
            dacValues(6)    => dacValues(i, 6),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(JESD0_INDEX_C+i),
            axilReadSlave   => axilReadSlaves(JESD0_INDEX_C+i),
            axilWriteMaster => axilWriteMasters(JESD0_INDEX_C+i),
            axilWriteSlave  => axilWriteSlaves(JESD0_INDEX_C+i),
            -----------------------
            -- Application Ports --
            -----------------------
            -- AMC's JESD Ports
            jesdRxP         => jesdRxP(i),
            jesdRxN         => jesdRxN(i),
            jesdTxP         => jesdTxP(i),
            jesdTxN         => jesdTxN(i),
            jesdClkP        => jesdClkP(i),
            jesdClkN        => jesdClkN(i));
   end generate U_Jesd;

   -------------------
   -- Application Core
   -------------------
   U_AppCore : entity work.AppCore
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         SIMULATION_G     => SIMULATION_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(CORE_INDEX_C).baseAddr,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)           
      port map (
         -- Clocks and resets   
         jesdClk          => jesdClk,
         jesdRst          => jesdRst,
         jesdClk2x        => jesdClk2x,
         jesdRst2x        => jesdRst2x,
         -- DaqMux/Trig Interface,
         freezeHw         => freezeHw,
         evrTrig          => evrTrig,
         userTrig         => userTrig,
         -- JESD SYNC Interface
         jesdSysRef       => jesdSysRef,
         jesdRxSync       => jesdRxSync,
         jesdTxSync       => jesdTxSync,
         -- ADC/DAC/Debug Interface
         adcValids        => adcValids,
         adcValues        => adcValues,
         dacValids        => dacValids,
         dacValues        => dacValues,
         debugValids      => debugValids,
         debugValues      => debugValues,
         -- AXI-Lite Interface
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(CORE_INDEX_C),
         axilReadSlave    => axilReadSlaves(CORE_INDEX_C),
         axilWriteMaster  => axilWriteMasters(CORE_INDEX_C),
         axilWriteSlave   => axilWriteSlaves(CORE_INDEX_C),
         ----------------------
         -- Top Level Interface
         ----------------------
         -- Timing Interface (recTimingClk domain)          
         timingBus        => timingBus,
         timingPhy        => timingPhy,
         timingPhyClk     => timingPhyClk,
         timingPhyRst     => timingPhyRst,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk    => diagnosticClk,
         diagnosticRst    => diagnosticRst,
         diagnosticBus    => diagnosticBus,
         -- Backplane Messaging Interface (bpMsgClk domain)
         bpMsgClk         => bpMsgClk,
         bpMsgRst         => bpMsgRst,
         bpMsgBus         => bpMsgBus,
         -- Application Debug Interface (ref156MHzClk domain)
         obAppDebugMaster => obAppDebugMaster,
         obAppDebugSlave  => obAppDebugSlave,
         ibAppDebugMaster => ibAppDebugMaster,
         ibAppDebugSlave  => ibAppDebugSlave,
         -- BSI Interface (bsiClk domain) 
         bsiClk           => bsiClk,
         bsiRst           => bsiRst,
         bsiBus           => bsiBus,
         -- MPS Concentrator Interface (ref156MHzClk domain)
         mpsObMasters     => mpsObMasters,
         mpsObSlaves      => mpsObSlaves,
         -- Reference Clocks and Resets
         recTimingClk     => recTimingClk,
         recTimingRst     => recTimingRst,
         ref125MHzClk     => ref125MHzClk,
         ref125MHzRst     => ref125MHzRst,
         ref156MHzClk     => ref156MHzClk,
         ref156MHzRst     => ref156MHzRst,
         ref312MHzClk     => ref312MHzClk,
         ref312MHzRst     => ref312MHzRst,
         ref625MHzClk     => ref625MHzClk,
         ref625MHzRst     => ref625MHzRst,
         gthFabClk        => gthFabClk,
         ethPhyReady      => ethPhyReady,
         -----------------------
         -- Application Ports --
         -----------------------
         -- AMC's JTAG Ports
         jtagPri          => jtagPri,
         jtagSec          => jtagSec,
         -- AMC's FPGA Clock Ports
         fpgaClkP         => fpgaClkP,
         fpgaClkN         => fpgaClkN,
         -- AMC's System Reference Ports
         sysRefP          => sysRefP,
         sysRefN          => sysRefN,
         -- AMC's Sync Ports
         syncInP          => syncInP,
         syncInN          => syncInN,
         syncOutP         => syncOutP,
         syncOutN         => syncOutN,
         -- AMC's Spare Ports
         spareP           => spareP,
         spareN           => spareN,
         -- RTM's Low Speed Ports
         rtmLsP           => rtmLsP,
         rtmLsN           => rtmLsN,
         -- RTM's High Speed Ports
         rtmHsRxP         => rtmHsRxP,
         rtmHsRxN         => rtmHsRxN,
         rtmHsTxP         => rtmHsTxP,
         rtmHsTxN         => rtmHsTxN,
         genClkP          => genClkP,
         genClkN          => genClkN);

end mapping;
