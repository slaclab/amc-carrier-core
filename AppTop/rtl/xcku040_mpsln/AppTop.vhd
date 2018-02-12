-------------------------------------------------------------------------------
-- File       : AppTop.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2018-02-12
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
use work.AppMpsPkg.all;

entity AppTop is
   generic (
      -- General Generics
      TPD_G                : time                      := 1 ns;
      SIM_SPEEDUP_G        : boolean                   := false;
      SIMULATION_G         : boolean                   := false;
      MR_LCLS_APP_G        : boolean                   := true;
      TIMING_BUS_DOMAIN_G  : string                    := "REC_CLK";  -- "AXIL"
      -- JESD Generics
      JESD_DRP_EN_G        : boolean                   := false;
      JESD_RX_LANE_G       : NaturalArray(1 downto 0)  := (others => 0);
      JESD_TX_LANE_G       : NaturalArray(1 downto 0)  := (others => 0);
      JESD_RX_POLARITY_G   : Slv5Array(1 downto 0)     := (others => "00000");
      JESD_TX_POLARITY_G   : Slv5Array(1 downto 0)     := (others => "00000");
      JESD_RX_ROUTES_G     : AppTopJesdRouteArray      := (others => JESD_ROUTES_INIT_C);
      JESD_TX_ROUTES_G     : AppTopJesdRouteArray      := (others => JESD_ROUTES_INIT_C);
      JESD_REF_SEL_G       : Slv2Array(1 downto 0)     := (others => DEV_CLK2_SEL_C);
      JESD_USR_DIV_G       : natural                   := 4;
      -- Signal Generator Generics
      SIG_GEN_SIZE_G       : NaturalArray(1 downto 0)  := (others => 0);
      SIG_GEN_ADDR_WIDTH_G : PositiveArray(1 downto 0) := (others => 9);
      SIG_GEN_LANE_MODE_G  : Slv7Array(1 downto 0)     := (others => "0000000");
      SIG_GEN_RAM_CLK_G    : Slv7Array(1 downto 0)     := (others => "0000000");
      -- Triggering Generics
      TRIG_SIZE_G          : positive range 1 to 16    := 3;
      TRIG_DELAY_WIDTH_G   : integer range 1 to 32     := 32;
      TRIG_PULSE_WIDTH_G   : integer range 1 to 32     := 32);
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (axilClk domain)
      axilClk              : in    sl;
      axilRst              : in    sl;
      axilReadMaster       : in    AxiLiteReadMasterType;
      axilReadSlave        : out   AxiLiteReadSlaveType;
      axilWriteMaster      : in    AxiLiteWriteMasterType;
      axilWriteSlave       : out   AxiLiteWriteSlaveType;
      mpsCoreReg           : in    MpsCoreRegType;
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
      -- Backplane Messaging Interface  (axilClk domain)
      obBpMsgClientMaster  : out   AxiStreamMasterType;
      obBpMsgClientSlave   : in    AxiStreamSlaveType;
      ibBpMsgClientMaster  : in    AxiStreamMasterType;
      ibBpMsgClientSlave   : out   AxiStreamSlaveType;
      obBpMsgServerMaster  : out   AxiStreamMasterType;
      obBpMsgServerSlave   : in    AxiStreamSlaveType;
      ibBpMsgServerMaster  : in    AxiStreamMasterType;
      ibBpMsgServerSlave   : out   AxiStreamSlaveType;
      -- Application Debug Interface (axilClk domain)
      obAppDebugMaster     : out   AxiStreamMasterType;
      obAppDebugSlave      : in    AxiStreamSlaveType;
      ibAppDebugMaster     : in    AxiStreamMasterType;
      ibAppDebugSlave      : out   AxiStreamSlaveType;
      -- MPS Concentrator Interface (axilClk domain)
      mpsObMasters         : in    AxiStreamMasterArray(14 downto 0);
      mpsObSlaves          : out   AxiStreamSlaveArray(14 downto 0);
      -- Reference Clocks and Resets
      recTimingClk         : in    sl;
      recTimingRst         : in    sl;
      gthFabClk            : in    sl;
      -- Misc. Interface (axilClk domain)
      ipmiBsi              : in    BsiBusType;
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
      -- RTM's Clock Reference 
      genClkP              : in    sl;
      genClkN              : in    sl);
end AppTop;

architecture mapping of AppTop is

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant CORE_INDEX_C     : natural := 0;
   constant TIMING_INDEX_C   : natural := 1;
   constant DAQ_MUX0_INDEX_C : natural := 2;
   constant DAQ_MUX1_INDEX_C : natural := 3;
   constant JESD0_INDEX_C    : natural := 4;
   constant JESD1_INDEX_C    : natural := 5;
   constant SIG_GEN0_INDEX_C : natural := 6;
   constant SIG_GEN1_INDEX_C : natural := 7;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, x"80000000", 31, 28);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal evrTrig     : AppTopTrigType;
   signal trigCascBay : slv(2 downto 0);
   signal armCascBay  : slv(2 downto 0);
   signal trigHw      : slv(1 downto 0);
   signal freezeHw    : slv(1 downto 0);

   signal jesdClk    : slv(1 downto 0);
   signal jesdRst    : slv(1 downto 0);
   signal jesdUsrClk : slv(1 downto 0);
   signal jesdUsrRst : slv(1 downto 0);
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
   signal linkReady  : Slv18Array(1 downto 0);

   signal dacSigCtrl   : DacSigCtrlArray(1 downto 0);
   signal dacSigStatus : DacSigStatusArray(1 downto 0);
   signal dacSigValids : Slv7Array(1 downto 0);
   signal dacSigValues : sampleDataVectorArray(1 downto 0, 6 downto 0);

   signal obAppDbgMaster : AxiStreamMasterType;
   signal obAppDbgSlave  : AxiStreamSlaveType;

   signal intRxP : Slv5Array(1 downto 0);
   signal intRxN : Slv5Array(1 downto 0);
   signal intTxP : Slv5Array(1 downto 0);
   signal intTxN : Slv5Array(1 downto 0);

begin

   --------------------------
   -- Clock and reset mapping
   --------------------------
   timingClk <= recTimingClk when(TIMING_BUS_DOMAIN_G = "REC_CLK") else axilClk;
   timingRst <= recTimingRst when(TIMING_BUS_DOMAIN_G = "REC_CLK") else axilRst;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ---------------
   -- Trigger Core
   ---------------
   U_Trig : entity work.AppTopTrig
      generic map (
         TPD_G              => TPD_G,
         MR_LCLS_APP_G      => MR_LCLS_APP_G,
         AXIL_BASE_ADDR_G   => AXI_CONFIG_C(TIMING_INDEX_C).baseAddr,
         TRIG_SIZE_G        => TRIG_SIZE_G,
         TRIG_DELAY_WIDTH_G => TRIG_DELAY_WIDTH_G,
         TRIG_PULSE_WIDTH_G => TRIG_PULSE_WIDTH_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave   => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TIMING_INDEX_C),
         -- Application Debug Interface (axilClk domain)
         sAxisMaster     => obAppDbgMaster,
         sAxisSlave      => obAppDbgSlave,
         mAxisMaster     => obAppDebugMaster,
         mAxisSlave      => obAppDebugSlave,
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

   U_AmcBay : for i in 1 downto 0 generate

      ------------------
      -- DAQ MUXV2 Module
      ------------------
      U_DaqMuxV2 : entity work.DaqMuxV2
         generic map (
            TPD_G            => TPD_G,
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
            sampleValidVec_i    => dataValids(i),
            linkReadyVec_i      => linkReady(i),
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
      linkReady(i)  <= x"F" & dacValids(i) & adcValids(i);

      ------------
      -- JESD Core
      ------------
      U_JesdCore : entity work.AppTopJesd
         generic map (
            TPD_G              => TPD_G,
            SIM_SPEEDUP_G      => SIM_SPEEDUP_G,
            SIMULATION_G       => SIMULATION_G,
            AXI_BASE_ADDR_G    => AXI_CONFIG_C(JESD0_INDEX_C+i).baseAddr,
            JESD_DRP_EN_G      => JESD_DRP_EN_G,
            JESD_RX_LANE_G     => JESD_RX_LANE_G(i),
            JESD_TX_LANE_G     => JESD_TX_LANE_G(i),
            JESD_RX_POLARITY_G => JESD_RX_POLARITY_G(i),
            JESD_TX_POLARITY_G => JESD_TX_POLARITY_G(i),
            JESD_RX_ROUTES_G   => JESD_RX_ROUTES_G(i),
            JESD_TX_ROUTES_G   => JESD_TX_ROUTES_G(i),
            JESD_REF_SEL_G     => JESD_REF_SEL_G(i),
            JESD_USR_DIV_G     => JESD_USR_DIV_G)
         port map (
            -- Clock/reset/SYNC
            jesdClk         => jesdClk(i),
            jesdRst         => jesdRst(i),
            jesdClk2x       => jesdClk2x(i),
            jesdRst2x       => jesdRst2x(i),
            jesdUsrClk      => jesdUsrClk(i),
            jesdUsrRst      => jesdUsrRst(i),
            jesdSysRef      => jesdSysRef(i),
            jesdRxSync      => jesdRxSync(i),
            jesdTxSync      => jesdTxSync(i),
            -- ADC Interface
            adcValids       => adcValids(i)(4 downto 0),
            adcValues(0)    => adcValues(i, 0),
            adcValues(1)    => adcValues(i, 1),
            adcValues(2)    => adcValues(i, 2),
            adcValues(3)    => adcValues(i, 3),
            adcValues(4)    => adcValues(i, 4),
            -- DAC Interface
            dacValids       => dacValids(i)(4 downto 0),
            dacValues(0)    => dacValues(i, 0),
            dacValues(1)    => dacValues(i, 1),
            dacValues(2)    => dacValues(i, 2),
            dacValues(3)    => dacValues(i, 3),
            dacValues(4)    => dacValues(i, 4),
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
            jesdRxP         => intRxP(i),
            jesdRxN         => intRxN(i),
            jesdTxP         => intTxP(i),
            jesdTxN         => intTxN(i),
            jesdClkP        => jesdClkP(i),
            jesdClkN        => jesdClkN(i));

      adcValids(i)(6 downto 5) <= (others=>'0');
      adcValues(i,6) <= (others=>'0');
      adcValues(i,5) <= (others=>'0');

      intRxP(i) <= jesdRxP(i)(4 downto 0);
      intRxN(i) <= jesdRxN(i)(4 downto 0);

      jesdTxP(i)(4 downto 0) <= intTxP(i);
      jesdTxN(i)(4 downto 0) <= intTxN(i);

      U_DacSigGen : entity work.DacSigGen
         generic map (
            TPD_G                => TPD_G,
            AXI_BASE_ADDR_G      => AXI_CONFIG_C(SIG_GEN0_INDEX_C+i).baseAddr,
            SIG_GEN_SIZE_G       => SIG_GEN_SIZE_G(i),
            SIG_GEN_ADDR_WIDTH_G => SIG_GEN_ADDR_WIDTH_G(i),
            SIG_GEN_LANE_MODE_G  => SIG_GEN_LANE_MODE_G(i),
            SIG_GEN_RAM_CLK_G    => SIG_GEN_RAM_CLK_G(i))
         port map (
            -- DAC Signal Generator Interface
            jesdClk         => jesdClk(i),
            jesdRst         => jesdRst(i),
            jesdClk2x       => jesdClk2x(i),
            jesdRst2x       => jesdRst2x(i),
            dacSigCtrl      => dacSigCtrl(i),
            dacSigStatus    => dacSigStatus(i),
            dacSigValids    => dacSigValids(i),
            dacSigValues(0) => dacSigValues(i, 0),
            dacSigValues(1) => dacSigValues(i, 1),
            dacSigValues(2) => dacSigValues(i, 2),
            dacSigValues(3) => dacSigValues(i, 3),
            dacSigValues(4) => dacSigValues(i, 4),
            dacSigValues(5) => dacSigValues(i, 5),
            dacSigValues(6) => dacSigValues(i, 6),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(SIG_GEN0_INDEX_C+i),
            axilReadSlave   => axilReadSlaves(SIG_GEN0_INDEX_C+i),
            axilWriteMaster => axilWriteMasters(SIG_GEN0_INDEX_C+i),
            axilWriteSlave  => axilWriteSlaves(SIG_GEN0_INDEX_C+i));

   end generate U_AmcBay;

   -------------------
   -- Application Core
   -------------------
   U_AppCore : entity work.AppCore
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         SIMULATION_G     => SIMULATION_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(CORE_INDEX_C).baseAddr,
         JESD_USR_DIV_G   => JESD_USR_DIV_G)
      port map (
         -- Clocks and resets   
         jesdClk             => jesdClk,
         jesdRst             => jesdRst,
         jesdClk2x           => jesdClk2x,
         jesdRst2x           => jesdRst2x,
         jesdUsrClk          => jesdUsrClk,
         jesdUsrRst          => jesdUsrRst,
         -- DaqMux/Trig Interface (timingClk domain) 
         freezeHw            => freezeHw,
         evrTrig             => evrTrig,
         trigHw              => trigHw,
         trigCascBay         => trigCascBay(1 downto 0),
         -- JESD SYNC Interface (jesdClk[1:0] domain)
         jesdSysRef          => jesdSysRef,
         jesdRxSync          => jesdRxSync,
         jesdTxSync          => jesdTxSync,
         -- ADC/DAC/Debug Interface (jesdClk[1:0] domain)
         adcValids           => adcValids,
         adcValues           => adcValues,
         dacValids           => dacValids,
         dacValues           => dacValues,
         debugValids         => debugValids,
         debugValues         => debugValues,
         -- DAC Signal Generator Interface
         -- If SIG_GEN_LANE_MODE_G = '0', (jesdClk[1:0] domain)
         -- If SIG_GEN_LANE_MODE_G = '1', (jesdClk2x[1:0] domain)
         dacSigCtrl          => dacSigCtrl,
         dacSigStatus        => dacSigStatus,
         dacSigValids        => dacSigValids,
         dacSigValues        => dacSigValues,
         -- AXI-Lite Interface (axilClk domain) 
         axilClk             => axilClk,
         axilRst             => axilRst,
         axilReadMaster      => axilReadMasters(CORE_INDEX_C),
         axilReadSlave       => axilReadSlaves(CORE_INDEX_C),
         axilWriteMaster     => axilWriteMasters(CORE_INDEX_C),
         axilWriteSlave      => axilWriteSlaves(CORE_INDEX_C),
         mpsCoreReg          => mpsCoreReg,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- Timing Interface (timingClk domain)   
         timingClk           => recTimingClk,
         timingRst           => recTimingRst,
         timingBus           => timingBus,
         timingPhy           => timingPhy,
         timingPhyClk        => timingPhyClk,
         timingPhyRst        => timingPhyRst,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk       => diagnosticClk,
         diagnosticRst       => diagnosticRst,
         diagnosticBus       => diagnosticBus,
         -- Backplane Messaging Interface  (axilClk domain)
         obBpMsgClientMaster => obBpMsgClientMaster,
         obBpMsgClientSlave  => obBpMsgClientSlave,
         ibBpMsgClientMaster => ibBpMsgClientMaster,
         ibBpMsgClientSlave  => ibBpMsgClientSlave,
         obBpMsgServerMaster => obBpMsgServerMaster,
         obBpMsgServerSlave  => obBpMsgServerSlave,
         ibBpMsgServerMaster => ibBpMsgServerMaster,
         ibBpMsgServerSlave  => ibBpMsgServerSlave,
         -- Application Debug Interface (axilClk domain)
         obAppDebugMaster    => obAppDbgMaster,
         obAppDebugSlave     => obAppDbgSlave,
         ibAppDebugMaster    => ibAppDebugMaster,
         ibAppDebugSlave     => ibAppDebugSlave,
         -- MPS Concentrator Interface (axilClk domain)
         mpsObMasters        => mpsObMasters,
         mpsObSlaves         => mpsObSlaves,
         -- Misc. Interface
         ipmiBsi             => ipmiBsi,
         gthFabClk           => gthFabClk,
         ethPhyReady         => ethPhyReady,
         -----------------------
         -- Application Ports --
         -----------------------
         -- AMC's JTAG Ports
         jtagPri             => jtagPri,
         jtagSec             => jtagSec,
         -- AMC's FPGA Clock Ports
         fpgaClkP            => fpgaClkP,
         fpgaClkN            => fpgaClkN,
         -- AMC's System Reference Ports
         sysRefP             => sysRefP,
         sysRefN             => sysRefN,
         -- AMC's Sync Ports
         syncInP             => syncInP,
         syncInN             => syncInN,
         syncOutP            => syncOutP,
         syncOutN            => syncOutN,
         -- AMC's Spare Ports
         spareP              => spareP,
         spareN              => spareN,
         -- RTM's Low Speed Ports
         rtmLsP              => rtmLsP,
         rtmLsN              => rtmLsN,
         -- RTM's High Speed Ports
         rtmHsRxP(0)         => rtmHsRxP,
         rtmHsRxP(1)         => jesdRxP(0)(5),
         rtmHsRxP(2)         => jesdRxP(0)(6),
         rtmHsRxP(3)         => jesdRxP(1)(5),
         rtmHsRxP(4)         => jesdRxP(1)(6),
         rtmHsRxN(0)         => rtmHsRxN,
         rtmHsRxN(1)         => jesdRxN(0)(5),
         rtmHsRxN(2)         => jesdRxN(0)(6),
         rtmHsRxN(3)         => jesdRxN(1)(5),
         rtmHsRxN(4)         => jesdRxN(1)(6),
         rtmHsTxP(0)         => rtmHsTxP,
         rtmHsTxP(1)         => jesdTxP(0)(5),
         rtmHsTxP(2)         => jesdTxP(0)(6),
         rtmHsTxP(3)         => jesdTxP(1)(5),
         rtmHsTxP(4)         => jesdTxP(1)(6),
         rtmHsTxN(0)         => rtmHsTxN,
         rtmHsTxN(1)         => jesdTxN(0)(5),
         rtmHsTxN(2)         => jesdTxN(0)(6),
         rtmHsTxN(3)         => jesdTxN(1)(5),
         rtmHsTxN(4)         => jesdTxN(1)(6),
         -- RTM's Clock Reference 
         genClkP             => genClkP,
         genClkN             => genClkN);

end mapping;
