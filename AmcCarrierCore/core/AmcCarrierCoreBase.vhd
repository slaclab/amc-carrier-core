-------------------------------------------------------------------------------
-- File       : AmcCarrierCoreBase.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-06-22
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierCoreBase is
   generic (
      TPD_G         : time    := 1 ns;
      BUILD_INFO_G  : BuildInfoType;
      SIM_SPEEDUP_G : boolean := false;  -- false = Normal Operation, true = simulation
      APP_TYPE_G    : AppType;
      MPS_SLOT_G    : boolean := false);  -- false = Normal Operation, true = MPS message concentrator (Slot#2 only)
   port (
      -----------------------
      -- Core Ports to AppTop
      -----------------------
      -- AXI-Lite Interface (axilClk domain)
      -- Address Range = [0x80000000:0xFFFFFFFF]
      axilClk              : out   sl;
      axilRst              : out   sl;
      axilReadMaster       : out   AxiLiteReadMasterType;
      axilReadSlave        : in    AxiLiteReadSlaveType;
      axilWriteMaster      : out   AxiLiteWriteMasterType;
      axilWriteSlave       : in    AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk            : in    sl;
      timingRst            : in    sl;
      timingBus            : out   TimingBusType;
      timingPhy            : in    TimingPhyType                    := TIMING_PHY_INIT_C;  -- Input for timing generator only
      timingPhyClk         : out   sl;
      timingPhyRst         : out   sl;
      timingRefClk         : out   sl;
      timingRefClkDiv2     : out   sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : in    sl;
      diagnosticRst        : in    sl;
      diagnosticBus        : in    DiagnosticBusType;
      mpsCoreReg           : out   MpsCoreRegType;
      --  Waveform Capture interface (waveformClk domain)
      waveformClk          : out   sl;
      waveformRst          : out   sl;
      obAppWaveformMasters : in    WaveformMasterArrayType          := WAVEFORM_MASTER_ARRAY_INIT_C;
      obAppWaveformSlaves  : out   WaveformSlaveArrayType;
      ibAppWaveformMasters : out   WaveformMasterArrayType;
      ibAppWaveformSlaves  : in    WaveformSlaveArrayType           := WAVEFORM_SLAVE_ARRAY_INIT_C;
      -- Backplane Messaging Interface  (axilClk domain)
      obBpMsgClientMaster  : in    AxiStreamMasterType              := AXI_STREAM_MASTER_INIT_C;
      obBpMsgClientSlave   : out   AxiStreamSlaveType;
      ibBpMsgClientMaster  : out   AxiStreamMasterType;
      ibBpMsgClientSlave   : in    AxiStreamSlaveType               := AXI_STREAM_SLAVE_FORCE_C;
      obBpMsgServerMaster  : in    AxiStreamMasterType              := AXI_STREAM_MASTER_INIT_C;
      obBpMsgServerSlave   : out   AxiStreamSlaveType;
      ibBpMsgServerMaster  : out   AxiStreamMasterType;
      ibBpMsgServerSlave   : in    AxiStreamSlaveType               := AXI_STREAM_SLAVE_FORCE_C;
      -- Application Debug Interface (axilClk domain)
      obAppDebugMaster     : in    AxiStreamMasterType              := AXI_STREAM_MASTER_INIT_C;
      obAppDebugSlave      : out   AxiStreamSlaveType;
      ibAppDebugMaster     : out   AxiStreamMasterType;
      ibAppDebugSlave      : in    AxiStreamSlaveType               := AXI_STREAM_SLAVE_FORCE_C;
      -- MPS Concentrator Interface (axilClk domain)
      mpsObMasters         : out   AxiStreamMasterArray(14 downto 0);
      mpsObSlaves          : in    AxiStreamSlaveArray(14 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      -- Reference Clocks and Resets
      recTimingClk         : out   sl;
      recTimingRst         : out   sl;
      gthFabClk            : out   sl;
      -- Misc. Interface (axilClk domain)
      ipmiBsi              : out   BsiBusType;
      ethPhyReady          : out   sl;
      ----------------
      --  Top Level Interface to IO
      ----------------
      -- Common Fabricate Clock
      fabClkP              : in    sl;
      fabClkN              : in    sl;
      -- Ethernet Ports
      ethRxP               : in    slv(3 downto 0);
      ethRxN               : in    slv(3 downto 0);
      ethTxP               : out   slv(3 downto 0);
      ethTxN               : out   slv(3 downto 0);
      ethClkP              : in    sl;
      ethClkN              : in    sl;
      -- Backplane MPS Ports
      mpsClkIn             : in    sl;
      mpsClkOut            : out   sl;
      mpsBusRxP            : in    slv(14 downto 1);
      mpsBusRxN            : in    slv(14 downto 1);
      mpsTxP               : out   sl;
      mpsTxN               : out   sl;
      -- LCLS Timing Ports
      timingRxP            : in    sl;
      timingRxN            : in    sl;
      timingTxP            : out   sl;
      timingTxN            : out   sl;
      timingRefClkInP      : in    sl;
      timingRefClkInN      : in    sl;
      timingRecClkOutP     : out   sl;
      timingRecClkOutN     : out   sl;
      timingClkSel         : out   sl;
      timingClkScl         : inout sl;
      timingClkSda         : inout sl;
      -- Crossbar Ports
      xBarSin              : out   slv(1 downto 0);
      xBarSout             : out   slv(1 downto 0);
      xBarConfig           : out   sl;
      xBarLoad             : out   sl;
      -- Secondary AMC Auxiliary Power Enable Port
      enAuxPwrL            : out   sl;
      -- IPMC Ports
      ipmcScl              : inout sl;
      ipmcSda              : inout sl;
      -- Configuration PROM Ports
      calScl               : inout sl;
      calSda               : inout sl;
      -- DDR3L SO-DIMM Ports
      ddrClkP              : in    sl;
      ddrClkN              : in    sl;
      ddrDm                : out   slv(7 downto 0);
      ddrDqsP              : inout slv(7 downto 0);
      ddrDqsN              : inout slv(7 downto 0);
      ddrDq                : inout slv(63 downto 0);
      ddrA                 : out   slv(15 downto 0);
      ddrBa                : out   slv(2 downto 0);
      ddrCsL               : out   slv(1 downto 0);
      ddrOdt               : out   slv(1 downto 0);
      ddrCke               : out   slv(1 downto 0);
      ddrCkP               : out   slv(1 downto 0);
      ddrCkN               : out   slv(1 downto 0);
      ddrWeL               : out   sl;
      ddrRasL              : out   sl;
      ddrCasL              : out   sl;
      ddrRstL              : out   sl;
      ddrAlertL            : in    sl;
      ddrPg                : in    sl;
      ddrPwrEnL            : out   sl;
      ddrScl               : inout sl;
      ddrSda               : inout sl;
      -- SYSMON Ports
      vPIn                 : in    sl;
      vNIn                 : in    sl);
end AmcCarrierCoreBase;

architecture mapping of AmcCarrierCoreBase is


   component AmcCarrierCore
      port (
         timingClk                                        : in    std_logic;
         timingRst                                        : in    std_logic;
         \timingBusIntf[strobe]\                          : out   std_logic;
         \timingBusIntf[valid]\                           : out   std_logic;
         \timingBusIntf[message][version]\                : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][pulseId]\                : out   std_logic_vector (63 downto 0);
         \timingBusIntf[message][timeStamp]\              : out   std_logic_vector (63 downto 0);
         \timingBusIntf[message][fixedRates]\             : out   std_logic_vector (9 downto 0);
         \timingBusIntf[message][acRates]\                : out   std_logic_vector (5 downto 0);
         \timingBusIntf[message][acTimeSlot]\             : out   std_logic_vector (2 downto 0);
         \timingBusIntf[message][acTimeSlotPhase]\        : out   std_logic_vector (11 downto 0);
         \timingBusIntf[message][resync]\                 : out   std_logic;
         \timingBusIntf[message][beamRequest]\            : out   std_logic_vector (31 downto 0);
         \timingBusIntf[message][beamEnergy][0]\          : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][beamEnergy][1]\          : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][beamEnergy][2]\          : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][beamEnergy][3]\          : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][photonWavelen][0]\       : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][photonWavelen][1]\       : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][syncStatus]\             : out   std_logic;
         \timingBusIntf[message][mpsValid]\               : out   std_logic;
         \timingBusIntf[message][bcsFault]\               : out   std_logic_vector (0 to 0);
         \timingBusIntf[message][mpsLimit]\               : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][mpsClass][0]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][1]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][2]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][3]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][4]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][5]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][6]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][7]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][8]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][9]\            : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][10]\           : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][11]\           : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][12]\           : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][13]\           : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][14]\           : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][mpsClass][15]\           : out   std_logic_vector (3 downto 0);
         \timingBusIntf[message][bsaInit]\                : out   std_logic_vector (63 downto 0);
         \timingBusIntf[message][bsaActive]\              : out   std_logic_vector (63 downto 0);
         \timingBusIntf[message][bsaAvgDone]\             : out   std_logic_vector (63 downto 0);
         \timingBusIntf[message][bsaDone]\                : out   std_logic_vector (63 downto 0);
         \timingBusIntf[message][control][0]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][1]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][2]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][3]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][4]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][5]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][6]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][7]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][8]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][9]\             : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][10]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][11]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][12]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][13]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][14]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][15]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][16]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[message][control][17]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[stream][pulseId]\                 : out   std_logic_vector (31 downto 0);
         \timingBusIntf[stream][eventCodes]\              : out   std_logic_vector (255 downto 0);
         \timingBusIntf[stream][dbuff][dtype]\            : out   std_logic_vector (15 downto 0);
         \timingBusIntf[stream][dbuff][version]\          : out   std_logic_vector (15 downto 0);
         \timingBusIntf[stream][dbuff][dmod]\             : out   std_logic_vector (191 downto 0);
         \timingBusIntf[stream][dbuff][epicsTime]\        : out   std_logic_vector (63 downto 0);
         \timingBusIntf[stream][dbuff][edefAvgDn]\        : out   std_logic_vector (31 downto 0);
         \timingBusIntf[stream][dbuff][edefMinor]\        : out   std_logic_vector (31 downto 0);
         \timingBusIntf[stream][dbuff][edefMajor]\        : out   std_logic_vector (31 downto 0);
         \timingBusIntf[stream][dbuff][edefInit]\         : out   std_logic_vector (31 downto 0);
         \timingBusIntf[v1][linkUp]\                      : out   std_logic;
         \timingBusIntf[v1][gtRxData]\                    : out   std_logic_vector (15 downto 0);
         \timingBusIntf[v1][gtRxDataK]\                   : out   std_logic_vector (1 downto 0);
         \timingBusIntf[v1][gtRxDispErr]\                 : out   std_logic_vector (1 downto 0);
         \timingBusIntf[v1][gtRxDecErr]\                  : out   std_logic_vector (1 downto 0);
         \timingBusIntf[v2][linkUp]\                      : out   std_logic;
         \timingPhy[dataK]\                               : in    std_logic_vector (1 downto 0);
         \timingPhy[data]\                                : in    std_logic_vector (15 downto 0);
         \timingPhy[control][reset]\                      : in    std_logic;
         \timingPhy[control][inhibit]\                    : in    std_logic;
         \timingPhy[control][polarity]\                   : in    std_logic;
         \timingPhy[control][bufferByRst]\                : in    std_logic;
         \timingPhy[control][pllReset]\                   : in    std_logic;
         timingPhyClk                                     : out   std_logic;
         timingPhyRst                                     : out   std_logic;
         timingRefClk                                     : out   std_logic;
         timingRefClkDiv2                                 : out   std_logic;
         diagnosticClk                                    : in    std_logic;
         diagnosticRst                                    : in    std_logic;
         \diagnosticBus[strobe]\                          : in    std_logic;
         \diagnosticBus[data][31]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][30]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][29]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][28]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][27]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][26]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][25]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][24]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][23]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][22]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][21]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][20]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][19]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][18]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][17]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][16]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][15]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][14]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][13]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][12]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][11]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][10]\                        : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][9]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][8]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][7]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][6]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][5]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][4]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][3]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][2]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][1]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[data][0]\                         : in    std_logic_vector (31 downto 0);
         \diagnosticBus[sevr][31]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][30]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][29]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][28]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][27]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][26]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][25]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][24]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][23]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][22]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][21]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][20]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][19]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][18]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][17]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][16]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][15]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][14]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][13]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][12]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][11]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][10]\                        : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][9]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][8]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][7]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][6]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][5]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][4]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][3]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][2]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][1]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[sevr][0]\                         : in    std_logic_vector (1 downto 0);
         \diagnosticBus[fixed]\                           : in    std_logic_vector (31 downto 0);
         \diagnosticBus[mpsIgnore]\                       : in    std_logic_vector (31 downto 0);
         \diagnosticBus[timingMessage][version]\          : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][pulseId]\          : in    std_logic_vector (63 downto 0);
         \diagnosticBus[timingMessage][timeStamp]\        : in    std_logic_vector (63 downto 0);
         \diagnosticBus[timingMessage][fixedRates]\       : in    std_logic_vector (9 downto 0);
         \diagnosticBus[timingMessage][acRates]\          : in    std_logic_vector (5 downto 0);
         \diagnosticBus[timingMessage][acTimeSlot]\       : in    std_logic_vector (2 downto 0);
         \diagnosticBus[timingMessage][acTimeSlotPhase]\  : in    std_logic_vector (11 downto 0);
         \diagnosticBus[timingMessage][resync]\           : in    std_logic;
         \diagnosticBus[timingMessage][beamRequest]\      : in    std_logic_vector (31 downto 0);
         \diagnosticBus[timingMessage][beamEnergy][0]\    : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][beamEnergy][1]\    : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][beamEnergy][2]\    : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][beamEnergy][3]\    : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][photonWavelen][0]\ : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][photonWavelen][1]\ : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][syncStatus]\       : in    std_logic;
         \diagnosticBus[timingMessage][mpsValid]\         : in    std_logic;
         \diagnosticBus[timingMessage][bcsFault]\         : in    std_logic_vector (0 to 0);
         \diagnosticBus[timingMessage][mpsLimit]\         : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][mpsClass][0]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][1]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][2]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][3]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][4]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][5]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][6]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][7]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][8]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][9]\      : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][10]\     : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][11]\     : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][12]\     : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][13]\     : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][14]\     : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][mpsClass][15]\     : in    std_logic_vector (3 downto 0);
         \diagnosticBus[timingMessage][bsaInit]\          : in    std_logic_vector (63 downto 0);
         \diagnosticBus[timingMessage][bsaActive]\        : in    std_logic_vector (63 downto 0);
         \diagnosticBus[timingMessage][bsaAvgDone]\       : in    std_logic_vector (63 downto 0);
         \diagnosticBus[timingMessage][bsaDone]\          : in    std_logic_vector (63 downto 0);
         \diagnosticBus[timingMessage][control][0]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][1]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][2]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][3]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][4]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][5]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][6]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][7]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][8]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][9]\       : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][10]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][11]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][12]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][13]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][14]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][15]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][16]\      : in    std_logic_vector (15 downto 0);
         \diagnosticBus[timingMessage][control][17]\      : in    std_logic_vector (15 downto 0);
         waveformClk                                      : out   std_logic;
         waveformRst                                      : out   std_logic;
         \obAppWaveformMasters[1][3][tValid]\             : in    std_logic;
         \obAppWaveformMasters[1][3][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][3][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][3][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][3][tLast]\              : in    std_logic;
         \obAppWaveformMasters[1][3][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][3][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][3][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][2][tValid]\             : in    std_logic;
         \obAppWaveformMasters[1][2][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][2][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][2][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][2][tLast]\              : in    std_logic;
         \obAppWaveformMasters[1][2][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][2][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][2][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][1][tValid]\             : in    std_logic;
         \obAppWaveformMasters[1][1][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][1][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][1][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][1][tLast]\              : in    std_logic;
         \obAppWaveformMasters[1][1][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][1][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][1][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][0][tValid]\             : in    std_logic;
         \obAppWaveformMasters[1][0][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[1][0][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][0][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[1][0][tLast]\              : in    std_logic;
         \obAppWaveformMasters[1][0][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][0][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[1][0][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][3][tValid]\             : in    std_logic;
         \obAppWaveformMasters[0][3][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][3][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][3][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][3][tLast]\              : in    std_logic;
         \obAppWaveformMasters[0][3][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][3][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][3][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][2][tValid]\             : in    std_logic;
         \obAppWaveformMasters[0][2][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][2][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][2][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][2][tLast]\              : in    std_logic;
         \obAppWaveformMasters[0][2][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][2][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][2][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][1][tValid]\             : in    std_logic;
         \obAppWaveformMasters[0][1][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][1][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][1][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][1][tLast]\              : in    std_logic;
         \obAppWaveformMasters[0][1][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][1][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][1][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][0][tValid]\             : in    std_logic;
         \obAppWaveformMasters[0][0][tData]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformMasters[0][0][tStrb]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][0][tKeep]\              : in    std_logic_vector (15 downto 0);
         \obAppWaveformMasters[0][0][tLast]\              : in    std_logic;
         \obAppWaveformMasters[0][0][tDest]\              : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][0][tId]\                : in    std_logic_vector (7 downto 0);
         \obAppWaveformMasters[0][0][tUser]\              : in    std_logic_vector (127 downto 0);
         \obAppWaveformSlaves[1][3][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[1][3][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[1][3][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[1][3][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[1][2][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[1][2][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[1][2][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[1][2][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[1][1][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[1][1][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[1][1][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[1][1][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[1][0][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[1][0][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[1][0][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[1][0][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[0][3][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[0][3][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[0][3][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[0][3][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[0][2][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[0][2][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[0][2][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[0][2][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[0][1][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[0][1][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[0][1][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[0][1][ctrl][idle]\          : out   std_logic;
         \obAppWaveformSlaves[0][0][slave][tReady]\       : out   std_logic;
         \obAppWaveformSlaves[0][0][ctrl][pause]\         : out   std_logic;
         \obAppWaveformSlaves[0][0][ctrl][overflow]\      : out   std_logic;
         \obAppWaveformSlaves[0][0][ctrl][idle]\          : out   std_logic;
         \ibAppWaveformMasters[1][3][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[1][3][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][3][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][3][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][3][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[1][3][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][3][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][3][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][2][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[1][2][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][2][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][2][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][2][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[1][2][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][2][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][2][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][1][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[1][1][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][1][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][1][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][1][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[1][1][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][1][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][1][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][0][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[1][0][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[1][0][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][0][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[1][0][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[1][0][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][0][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[1][0][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][3][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[0][3][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][3][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][3][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][3][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[0][3][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][3][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][3][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][2][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[0][2][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][2][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][2][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][2][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[0][2][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][2][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][2][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][1][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[0][1][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][1][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][1][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][1][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[0][1][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][1][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][1][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][0][tValid]\             : out   std_logic;
         \ibAppWaveformMasters[0][0][tData]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformMasters[0][0][tStrb]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][0][tKeep]\              : out   std_logic_vector (15 downto 0);
         \ibAppWaveformMasters[0][0][tLast]\              : out   std_logic;
         \ibAppWaveformMasters[0][0][tDest]\              : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][0][tId]\                : out   std_logic_vector (7 downto 0);
         \ibAppWaveformMasters[0][0][tUser]\              : out   std_logic_vector (127 downto 0);
         \ibAppWaveformSlaves[1][3][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[1][3][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[1][3][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[1][3][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[1][2][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[1][2][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[1][2][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[1][2][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[1][1][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[1][1][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[1][1][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[1][1][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[1][0][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[1][0][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[1][0][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[1][0][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[0][3][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[0][3][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[0][3][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[0][3][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[0][2][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[0][2][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[0][2][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[0][2][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[0][1][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[0][1][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[0][1][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[0][1][ctrl][idle]\          : in    std_logic;
         \ibAppWaveformSlaves[0][0][slave][tReady]\       : in    std_logic;
         \ibAppWaveformSlaves[0][0][ctrl][pause]\         : in    std_logic;
         \ibAppWaveformSlaves[0][0][ctrl][overflow]\      : in    std_logic;
         \ibAppWaveformSlaves[0][0][ctrl][idle]\          : in    std_logic;
         \obBpMsgClientMaster[tValid]\                    : in    std_logic;
         \obBpMsgClientMaster[tData]\                     : in    std_logic_vector (127 downto 0);
         \obBpMsgClientMaster[tStrb]\                     : in    std_logic_vector (15 downto 0);
         \obBpMsgClientMaster[tKeep]\                     : in    std_logic_vector (15 downto 0);
         \obBpMsgClientMaster[tLast]\                     : in    std_logic;
         \obBpMsgClientMaster[tDest]\                     : in    std_logic_vector (7 downto 0);
         \obBpMsgClientMaster[tId]\                       : in    std_logic_vector (7 downto 0);
         \obBpMsgClientMaster[tUser]\                     : in    std_logic_vector (127 downto 0);
         \obBpMsgClientSlave[tReady]\                     : out   std_logic;
         \ibBpMsgClientMaster[tValid]\                    : out   std_logic;
         \ibBpMsgClientMaster[tData]\                     : out   std_logic_vector (127 downto 0);
         \ibBpMsgClientMaster[tStrb]\                     : out   std_logic_vector (15 downto 0);
         \ibBpMsgClientMaster[tKeep]\                     : out   std_logic_vector (15 downto 0);
         \ibBpMsgClientMaster[tLast]\                     : out   std_logic;
         \ibBpMsgClientMaster[tDest]\                     : out   std_logic_vector (7 downto 0);
         \ibBpMsgClientMaster[tId]\                       : out   std_logic_vector (7 downto 0);
         \ibBpMsgClientMaster[tUser]\                     : out   std_logic_vector (127 downto 0);
         \ibBpMsgClientSlave[tReady]\                     : in    std_logic;
         \obBpMsgServerMaster[tValid]\                    : in    std_logic;
         \obBpMsgServerMaster[tData]\                     : in    std_logic_vector (127 downto 0);
         \obBpMsgServerMaster[tStrb]\                     : in    std_logic_vector (15 downto 0);
         \obBpMsgServerMaster[tKeep]\                     : in    std_logic_vector (15 downto 0);
         \obBpMsgServerMaster[tLast]\                     : in    std_logic;
         \obBpMsgServerMaster[tDest]\                     : in    std_logic_vector (7 downto 0);
         \obBpMsgServerMaster[tId]\                       : in    std_logic_vector (7 downto 0);
         \obBpMsgServerMaster[tUser]\                     : in    std_logic_vector (127 downto 0);
         \obBpMsgServerSlave[tReady]\                     : out   std_logic;
         \ibBpMsgServerMaster[tValid]\                    : out   std_logic;
         \ibBpMsgServerMaster[tData]\                     : out   std_logic_vector (127 downto 0);
         \ibBpMsgServerMaster[tStrb]\                     : out   std_logic_vector (15 downto 0);
         \ibBpMsgServerMaster[tKeep]\                     : out   std_logic_vector (15 downto 0);
         \ibBpMsgServerMaster[tLast]\                     : out   std_logic;
         \ibBpMsgServerMaster[tDest]\                     : out   std_logic_vector (7 downto 0);
         \ibBpMsgServerMaster[tId]\                       : out   std_logic_vector (7 downto 0);
         \ibBpMsgServerMaster[tUser]\                     : out   std_logic_vector (127 downto 0);
         \ibBpMsgServerSlave[tReady]\                     : in    std_logic;
         \obAppDebugMaster[tValid]\                       : in    std_logic;
         \obAppDebugMaster[tData]\                        : in    std_logic_vector (127 downto 0);
         \obAppDebugMaster[tStrb]\                        : in    std_logic_vector (15 downto 0);
         \obAppDebugMaster[tKeep]\                        : in    std_logic_vector (15 downto 0);
         \obAppDebugMaster[tLast]\                        : in    std_logic;
         \obAppDebugMaster[tDest]\                        : in    std_logic_vector (7 downto 0);
         \obAppDebugMaster[tId]\                          : in    std_logic_vector (7 downto 0);
         \obAppDebugMaster[tUser]\                        : in    std_logic_vector (127 downto 0);
         \obAppDebugSlave[tReady]\                        : out   std_logic;
         \ibAppDebugMaster[tValid]\                       : out   std_logic;
         \ibAppDebugMaster[tData]\                        : out   std_logic_vector (127 downto 0);
         \ibAppDebugMaster[tStrb]\                        : out   std_logic_vector (15 downto 0);
         \ibAppDebugMaster[tKeep]\                        : out   std_logic_vector (15 downto 0);
         \ibAppDebugMaster[tLast]\                        : out   std_logic;
         \ibAppDebugMaster[tDest]\                        : out   std_logic_vector (7 downto 0);
         \ibAppDebugMaster[tId]\                          : out   std_logic_vector (7 downto 0);
         \ibAppDebugMaster[tUser]\                        : out   std_logic_vector (127 downto 0);
         \ibAppDebugSlave[tReady]\                        : in    std_logic;
         recTimingClk                                     : out   std_logic;
         recTimingRst                                     : out   std_logic;
         ref156MHzClk                                     : out   std_logic;
         ref156MHzRst                                     : out   std_logic;
         gthFabClk                                        : out   std_logic;
         \axilReadMasters[1][araddr]\                     : out   std_logic_vector (31 downto 0);
         \axilReadMasters[1][arprot]\                     : out   std_logic_vector (2 downto 0);
         \axilReadMasters[1][arvalid]\                    : out   std_logic;
         \axilReadMasters[1][rready]\                     : out   std_logic;
         \axilReadMasters[0][araddr]\                     : out   std_logic_vector (31 downto 0);
         \axilReadMasters[0][arprot]\                     : out   std_logic_vector (2 downto 0);
         \axilReadMasters[0][arvalid]\                    : out   std_logic;
         \axilReadMasters[0][rready]\                     : out   std_logic;
         \axilReadSlaves[1][arready]\                     : in    std_logic;
         \axilReadSlaves[1][rdata]\                       : in    std_logic_vector (31 downto 0);
         \axilReadSlaves[1][rresp]\                       : in    std_logic_vector (1 downto 0);
         \axilReadSlaves[1][rvalid]\                      : in    std_logic;
         \axilReadSlaves[0][arready]\                     : in    std_logic;
         \axilReadSlaves[0][rdata]\                       : in    std_logic_vector (31 downto 0);
         \axilReadSlaves[0][rresp]\                       : in    std_logic_vector (1 downto 0);
         \axilReadSlaves[0][rvalid]\                      : in    std_logic;
         \axilWriteMasters[1][awaddr]\                    : out   std_logic_vector (31 downto 0);
         \axilWriteMasters[1][awprot]\                    : out   std_logic_vector (2 downto 0);
         \axilWriteMasters[1][awvalid]\                   : out   std_logic;
         \axilWriteMasters[1][wdata]\                     : out   std_logic_vector (31 downto 0);
         \axilWriteMasters[1][wstrb]\                     : out   std_logic_vector (3 downto 0);
         \axilWriteMasters[1][wvalid]\                    : out   std_logic;
         \axilWriteMasters[1][bready]\                    : out   std_logic;
         \axilWriteMasters[0][awaddr]\                    : out   std_logic_vector (31 downto 0);
         \axilWriteMasters[0][awprot]\                    : out   std_logic_vector (2 downto 0);
         \axilWriteMasters[0][awvalid]\                   : out   std_logic;
         \axilWriteMasters[0][wdata]\                     : out   std_logic_vector (31 downto 0);
         \axilWriteMasters[0][wstrb]\                     : out   std_logic_vector (3 downto 0);
         \axilWriteMasters[0][wvalid]\                    : out   std_logic;
         \axilWriteMasters[0][bready]\                    : out   std_logic;
         \axilWriteSlaves[1][awready]\                    : in    std_logic;
         \axilWriteSlaves[1][wready]\                     : in    std_logic;
         \axilWriteSlaves[1][bresp]\                      : in    std_logic_vector (1 downto 0);
         \axilWriteSlaves[1][bvalid]\                     : in    std_logic;
         \axilWriteSlaves[0][awready]\                    : in    std_logic;
         \axilWriteSlaves[0][wready]\                     : in    std_logic;
         \axilWriteSlaves[0][bresp]\                      : in    std_logic_vector (1 downto 0);
         \axilWriteSlaves[0][bvalid]\                     : in    std_logic;
         \ethReadMaster[araddr]\                          : in    std_logic_vector (31 downto 0);
         \ethReadMaster[arprot]\                          : in    std_logic_vector (2 downto 0);
         \ethReadMaster[arvalid]\                         : in    std_logic;
         \ethReadMaster[rready]\                          : in    std_logic;
         \ethReadSlave[arready]\                          : out   std_logic;
         \ethReadSlave[rdata]\                            : out   std_logic_vector (31 downto 0);
         \ethReadSlave[rresp]\                            : out   std_logic_vector (1 downto 0);
         \ethReadSlave[rvalid]\                           : out   std_logic;
         \ethWriteMaster[awaddr]\                         : in    std_logic_vector (31 downto 0);
         \ethWriteMaster[awprot]\                         : in    std_logic_vector (2 downto 0);
         \ethWriteMaster[awvalid]\                        : in    std_logic;
         \ethWriteMaster[wdata]\                          : in    std_logic_vector (31 downto 0);
         \ethWriteMaster[wstrb]\                          : in    std_logic_vector (3 downto 0);
         \ethWriteMaster[wvalid]\                         : in    std_logic;
         \ethWriteMaster[bready]\                         : in    std_logic;
         \ethWriteSlave[awready]\                         : out   std_logic;
         \ethWriteSlave[wready]\                          : out   std_logic;
         \ethWriteSlave[bresp]\                           : out   std_logic_vector (1 downto 0);
         \ethWriteSlave[bvalid]\                          : out   std_logic;
         localMac                                         : in    std_logic_vector (47 downto 0);
         localIp                                          : in    std_logic_vector (31 downto 0);
         ethLinkUp                                        : out   std_logic;
         \timingReadMaster[araddr]\                       : in    std_logic_vector (31 downto 0);
         \timingReadMaster[arprot]\                       : in    std_logic_vector (2 downto 0);
         \timingReadMaster[arvalid]\                      : in    std_logic;
         \timingReadMaster[rready]\                       : in    std_logic;
         \timingReadSlave[arready]\                       : out   std_logic;
         \timingReadSlave[rdata]\                         : out   std_logic_vector (31 downto 0);
         \timingReadSlave[rresp]\                         : out   std_logic_vector (1 downto 0);
         \timingReadSlave[rvalid]\                        : out   std_logic;
         \timingWriteMaster[awaddr]\                      : in    std_logic_vector (31 downto 0);
         \timingWriteMaster[awprot]\                      : in    std_logic_vector (2 downto 0);
         \timingWriteMaster[awvalid]\                     : in    std_logic;
         \timingWriteMaster[wdata]\                       : in    std_logic_vector (31 downto 0);
         \timingWriteMaster[wstrb]\                       : in    std_logic_vector (3 downto 0);
         \timingWriteMaster[wvalid]\                      : in    std_logic;
         \timingWriteMaster[bready]\                      : in    std_logic;
         \timingWriteSlave[awready]\                      : out   std_logic;
         \timingWriteSlave[wready]\                       : out   std_logic;
         \timingWriteSlave[bresp]\                        : out   std_logic_vector (1 downto 0);
         \timingWriteSlave[bvalid]\                       : out   std_logic;
         \bsaReadMaster[araddr]\                          : in    std_logic_vector (31 downto 0);
         \bsaReadMaster[arprot]\                          : in    std_logic_vector (2 downto 0);
         \bsaReadMaster[arvalid]\                         : in    std_logic;
         \bsaReadMaster[rready]\                          : in    std_logic;
         \bsaReadSlave[arready]\                          : out   std_logic;
         \bsaReadSlave[rdata]\                            : out   std_logic_vector (31 downto 0);
         \bsaReadSlave[rresp]\                            : out   std_logic_vector (1 downto 0);
         \bsaReadSlave[rvalid]\                           : out   std_logic;
         \bsaWriteMaster[awaddr]\                         : in    std_logic_vector (31 downto 0);
         \bsaWriteMaster[awprot]\                         : in    std_logic_vector (2 downto 0);
         \bsaWriteMaster[awvalid]\                        : in    std_logic;
         \bsaWriteMaster[wdata]\                          : in    std_logic_vector (31 downto 0);
         \bsaWriteMaster[wstrb]\                          : in    std_logic_vector (3 downto 0);
         \bsaWriteMaster[wvalid]\                         : in    std_logic;
         \bsaWriteMaster[bready]\                         : in    std_logic;
         \bsaWriteSlave[awready]\                         : out   std_logic;
         \bsaWriteSlave[wready]\                          : out   std_logic;
         \bsaWriteSlave[bresp]\                           : out   std_logic_vector (1 downto 0);
         \bsaWriteSlave[bvalid]\                          : out   std_logic;
         \ddrReadMaster[araddr]\                          : in    std_logic_vector (31 downto 0);
         \ddrReadMaster[arprot]\                          : in    std_logic_vector (2 downto 0);
         \ddrReadMaster[arvalid]\                         : in    std_logic;
         \ddrReadMaster[rready]\                          : in    std_logic;
         \ddrReadSlave[arready]\                          : out   std_logic;
         \ddrReadSlave[rdata]\                            : out   std_logic_vector (31 downto 0);
         \ddrReadSlave[rresp]\                            : out   std_logic_vector (1 downto 0);
         \ddrReadSlave[rvalid]\                           : out   std_logic;
         \ddrWriteMaster[awaddr]\                         : in    std_logic_vector (31 downto 0);
         \ddrWriteMaster[awprot]\                         : in    std_logic_vector (2 downto 0);
         \ddrWriteMaster[awvalid]\                        : in    std_logic;
         \ddrWriteMaster[wdata]\                          : in    std_logic_vector (31 downto 0);
         \ddrWriteMaster[wstrb]\                          : in    std_logic_vector (3 downto 0);
         \ddrWriteMaster[wvalid]\                         : in    std_logic;
         \ddrWriteMaster[bready]\                         : in    std_logic;
         \ddrWriteSlave[awready]\                         : out   std_logic;
         \ddrWriteSlave[wready]\                          : out   std_logic;
         \ddrWriteSlave[bresp]\                           : out   std_logic_vector (1 downto 0);
         \ddrWriteSlave[bvalid]\                          : out   std_logic;
         ddrMemReady                                      : out   std_logic;
         ddrMemError                                      : out   std_logic;
         fabClkP                                          : in    std_logic;
         fabClkN                                          : in    std_logic;
         ethRxP                                           : in    std_logic_vector (3 downto 0);
         ethRxN                                           : in    std_logic_vector (3 downto 0);
         ethTxP                                           : out   std_logic_vector (3 downto 0);
         ethTxN                                           : out   std_logic_vector (3 downto 0);
         ethClkP                                          : in    std_logic;
         ethClkN                                          : in    std_logic;
         timingRxP                                        : in    std_logic;
         timingRxN                                        : in    std_logic;
         timingTxP                                        : out   std_logic;
         timingTxN                                        : out   std_logic;
         timingRefClkInP                                  : in    std_logic;
         timingRefClkInN                                  : in    std_logic;
         timingRecClkOutP                                 : out   std_logic;
         timingRecClkOutN                                 : out   std_logic;
         timingClkSel                                     : out   std_logic;
         enAuxPwrL                                        : out   std_logic;
         ddrClkP                                          : in    std_logic;
         ddrClkN                                          : in    std_logic;
         ddrDm                                            : out   std_logic_vector (7 downto 0);
         ddrDqsP                                          : inout std_logic_vector (7 downto 0);
         ddrDqsN                                          : inout std_logic_vector (7 downto 0);
         ddrDq                                            : inout std_logic_vector (63 downto 0);
         ddrA                                             : out   std_logic_vector (15 downto 0);
         ddrBa                                            : out   std_logic_vector (2 downto 0);
         ddrCsL                                           : out   std_logic_vector (1 downto 0);
         ddrOdt                                           : out   std_logic_vector (1 downto 0);
         ddrCke                                           : out   std_logic_vector (1 downto 0);
         ddrCkP                                           : out   std_logic_vector (1 downto 0);
         ddrCkN                                           : out   std_logic_vector (1 downto 0);
         ddrWeL                                           : out   std_logic;
         ddrRasL                                          : out   std_logic;
         ddrCasL                                          : out   std_logic;
         ddrRstL                                          : out   std_logic;
         ddrAlertL                                        : in    std_logic;
         ddrPg                                            : in    std_logic;
         ddrPwrEnL                                        : out   std_logic
         );
   end component;
   attribute SYN_BLACK_BOX                       : boolean;
   attribute SYN_BLACK_BOX of AmcCarrierCore     : component is true;
   attribute BLACK_BOX_PAD_PIN                   : string;
   attribute BLACK_BOX_PAD_PIN of AmcCarrierCore : component is "timingClk,timingRst,\timingBusIntf[strobe]\,\timingBusIntf[valid]\,\timingBusIntf[message][version]\[15:0],\timingBusIntf[message][pulseId]\[63:0],\timingBusIntf[message][timeStamp]\[63:0],\timingBusIntf[message][fixedRates]\[9:0],\timingBusIntf[message][acRates]\[5:0],\timingBusIntf[message][acTimeSlot]\[2:0],\timingBusIntf[message][acTimeSlotPhase]\[11:0],\timingBusIntf[message][resync]\,\timingBusIntf[message][beamRequest]\[31:0],\timingBusIntf[message][beamEnergy][0]\[15:0],\timingBusIntf[message][beamEnergy][1]\[15:0],\timingBusIntf[message][beamEnergy][2]\[15:0],\timingBusIntf[message][beamEnergy][3]\[15:0],\timingBusIntf[message][photonWavelen][0]\[15:0],\timingBusIntf[message][photonWavelen][1]\[15:0],\timingBusIntf[message][syncStatus]\,\timingBusIntf[message][mpsValid]\,\timingBusIntf[message][bcsFault]\[0:0],\timingBusIntf[message][mpsLimit]\[15:0],\timingBusIntf[message][mpsClass][0]\[3:0],\timingBusIntf[message][mpsClass][1]\[3:0],\timingBusIntf[message][mpsClass][2]\[3:0],\timingBusIntf[message][mpsClass][3]\[3:0],\timingBusIntf[message][mpsClass][4]\[3:0],\timingBusIntf[message][mpsClass][5]\[3:0],\timingBusIntf[message][mpsClass][6]\[3:0],\timingBusIntf[message][mpsClass][7]\[3:0],\timingBusIntf[message][mpsClass][8]\[3:0],\timingBusIntf[message][mpsClass][9]\[3:0],\timingBusIntf[message][mpsClass][10]\[3:0],\timingBusIntf[message][mpsClass][11]\[3:0],\timingBusIntf[message][mpsClass][12]\[3:0],\timingBusIntf[message][mpsClass][13]\[3:0],\timingBusIntf[message][mpsClass][14]\[3:0],\timingBusIntf[message][mpsClass][15]\[3:0],\timingBusIntf[message][bsaInit]\[63:0],\timingBusIntf[message][bsaActive]\[63:0],\timingBusIntf[message][bsaAvgDone]\[63:0],\timingBusIntf[message][bsaDone]\[63:0],\timingBusIntf[message][control][0]\[15:0],\timingBusIntf[message][control][1]\[15:0],\timingBusIntf[message][control][2]\[15:0],\timingBusIntf[message][control][3]\[15:0],\timingBusIntf[message][control][4]\[15:0],\timingBusIntf[message][control][5]\[15:0],\timingBusIntf[message][control][6]\[15:0],\timingBusIntf[message][control][7]\[15:0],\timingBusIntf[message][control][8]\[15:0],\timingBusIntf[message][control][9]\[15:0],\timingBusIntf[message][control][10]\[15:0],\timingBusIntf[message][control][11]\[15:0],\timingBusIntf[message][control][12]\[15:0],\timingBusIntf[message][control][13]\[15:0],\timingBusIntf[message][control][14]\[15:0],\timingBusIntf[message][control][15]\[15:0],\timingBusIntf[message][control][16]\[15:0],\timingBusIntf[message][control][17]\[15:0],\timingBusIntf[stream][pulseId]\[31:0],\timingBusIntf[stream][eventCodes]\[255:0],\timingBusIntf[stream][dbuff][dtype]\[15:0],\timingBusIntf[stream][dbuff][version]\[15:0],\timingBusIntf[stream][dbuff][dmod]\[191:0],\timingBusIntf[stream][dbuff][epicsTime]\[63:0],\timingBusIntf[stream][dbuff][edefAvgDn]\[31:0],\timingBusIntf[stream][dbuff][edefMinor]\[31:0],\timingBusIntf[stream][dbuff][edefMajor]\[31:0],\timingBusIntf[stream][dbuff][edefInit]\[31:0],\timingBusIntf[v1][linkUp]\,\timingBusIntf[v1][gtRxData]\[15:0],\timingBusIntf[v1][gtRxDataK]\[1:0],\timingBusIntf[v1][gtRxDispErr]\[1:0],\timingBusIntf[v1][gtRxDecErr]\[1:0],\timingBusIntf[v2][linkUp]\,\timingPhy[dataK]\[1:0],\timingPhy[data]\[15:0],\timingPhy[control][reset]\,\timingPhy[control][inhibit]\,\timingPhy[control][polarity]\,\timingPhy[control][bufferByRst]\,\timingPhy[control][pllReset]\,timingPhyClk,timingPhyRst,timingRefClk,timingRefClkDiv2,diagnosticClk,diagnosticRst,\diagnosticBus[strobe]\,\diagnosticBus[data][31]\[31:0],\diagnosticBus[data][30]\[31:0],\diagnosticBus[data][29]\[31:0],\diagnosticBus[data][28]\[31:0],\diagnosticBus[data][27]\[31:0],\diagnosticBus[data][26]\[31:0],\diagnosticBus[data][25]\[31:0],\diagnosticBus[data][24]\[31:0],\diagnosticBus[data][23]\[31:0],\diagnosticBus[data][22]\[31:0],\diagnosticBus[data][21]\[31:0],\diagnosticBus[data][20]\[31:0],\diagnosticBus[data][19]\[31:0],\diagnosticBus[data][18]\[31:0],\diagnosticBus[data][17]\[31:0],\diagnosticBus[data][16]\[31:0],\diagnosticBus[data][15]\[31:0],\diagnosticBus[data][14]\[31:0],\diagnosticBus[data][13]\[31:0],\diagnosticBus[data][12]\[31:0],\diagnosticBus[data][11]\[31:0],\diagnosticBus[data][10]\[31:0],\diagnosticBus[data][9]\[31:0],\diagnosticBus[data][8]\[31:0],\diagnosticBus[data][7]\[31:0],\diagnosticBus[data][6]\[31:0],\diagnosticBus[data][5]\[31:0],\diagnosticBus[data][4]\[31:0],\diagnosticBus[data][3]\[31:0],\diagnosticBus[data][2]\[31:0],\diagnosticBus[data][1]\[31:0],\diagnosticBus[data][0]\[31:0],\diagnosticBus[sevr][31]\[1:0],\diagnosticBus[sevr][30]\[1:0],\diagnosticBus[sevr][29]\[1:0],\diagnosticBus[sevr][28]\[1:0],\diagnosticBus[sevr][27]\[1:0],\diagnosticBus[sevr][26]\[1:0],\diagnosticBus[sevr][25]\[1:0],\diagnosticBus[sevr][24]\[1:0],\diagnosticBus[sevr][23]\[1:0],\diagnosticBus[sevr][22]\[1:0],\diagnosticBus[sevr][21]\[1:0],\diagnosticBus[sevr][20]\[1:0],\diagnosticBus[sevr][19]\[1:0],\diagnosticBus[sevr][18]\[1:0],\diagnosticBus[sevr][17]\[1:0],\diagnosticBus[sevr][16]\[1:0],\diagnosticBus[sevr][15]\[1:0],\diagnosticBus[sevr][14]\[1:0],\diagnosticBus[sevr][13]\[1:0],\diagnosticBus[sevr][12]\[1:0],\diagnosticBus[sevr][11]\[1:0],\diagnosticBus[sevr][10]\[1:0],\diagnosticBus[sevr][9]\[1:0],\diagnosticBus[sevr][8]\[1:0],\diagnosticBus[sevr][7]\[1:0],\diagnosticBus[sevr][6]\[1:0],\diagnosticBus[sevr][5]\[1:0],\diagnosticBus[sevr][4]\[1:0],\diagnosticBus[sevr][3]\[1:0],\diagnosticBus[sevr][2]\[1:0],\diagnosticBus[sevr][1]\[1:0],\diagnosticBus[sevr][0]\[1:0],\diagnosticBus[fixed]\[31:0],\diagnosticBus[mpsIgnore]\[31:0],\diagnosticBus[timingMessage][version]\[15:0],\diagnosticBus[timingMessage][pulseId]\[63:0],\diagnosticBus[timingMessage][timeStamp]\[63:0],\diagnosticBus[timingMessage][fixedRates]\[9:0],\diagnosticBus[timingMessage][acRates]\[5:0],\diagnosticBus[timingMessage][acTimeSlot]\[2:0],\diagnosticBus[timingMessage][acTimeSlotPhase]\[11:0],\diagnosticBus[timingMessage][resync]\,\diagnosticBus[timingMessage][beamRequest]\[31:0],\diagnosticBus[timingMessage][beamEnergy][0]\[15:0],\diagnosticBus[timingMessage][beamEnergy][1]\[15:0],\diagnosticBus[timingMessage][beamEnergy][2]\[15:0],\diagnosticBus[timingMessage][beamEnergy][3]\[15:0],\diagnosticBus[timingMessage][photonWavelen][0]\[15:0],\diagnosticBus[timingMessage][photonWavelen][1]\[15:0],\diagnosticBus[timingMessage][syncStatus]\,\diagnosticBus[timingMessage][mpsValid]\,\diagnosticBus[timingMessage][bcsFault]\[0:0],\diagnosticBus[timingMessage][mpsLimit]\[15:0],\diagnosticBus[timingMessage][mpsClass][0]\[3:0],\diagnosticBus[timingMessage][mpsClass][1]\[3:0],\diagnosticBus[timingMessage][mpsClass][2]\[3:0],\diagnosticBus[timingMessage][mpsClass][3]\[3:0],\diagnosticBus[timingMessage][mpsClass][4]\[3:0],\diagnosticBus[timingMessage][mpsClass][5]\[3:0],\diagnosticBus[timingMessage][mpsClass][6]\[3:0],\diagnosticBus[timingMessage][mpsClass][7]\[3:0],\diagnosticBus[timingMessage][mpsClass][8]\[3:0],\diagnosticBus[timingMessage][mpsClass][9]\[3:0],\diagnosticBus[timingMessage][mpsClass][10]\[3:0],\diagnosticBus[timingMessage][mpsClass][11]\[3:0],\diagnosticBus[timingMessage][mpsClass][12]\[3:0],\diagnosticBus[timingMessage][mpsClass][13]\[3:0],\diagnosticBus[timingMessage][mpsClass][14]\[3:0],\diagnosticBus[timingMessage][mpsClass][15]\[3:0],\diagnosticBus[timingMessage][bsaInit]\[63:0],\diagnosticBus[timingMessage][bsaActive]\[63:0],\diagnosticBus[timingMessage][bsaAvgDone]\[63:0],\diagnosticBus[timingMessage][bsaDone]\[63:0],\diagnosticBus[timingMessage][control][0]\[15:0],\diagnosticBus[timingMessage][control][1]\[15:0],\diagnosticBus[timingMessage][control][2]\[15:0],\diagnosticBus[timingMessage][control][3]\[15:0],\diagnosticBus[timingMessage][control][4]\[15:0],\diagnosticBus[timingMessage][control][5]\[15:0],\diagnosticBus[timingMessage][control][6]\[15:0],\diagnosticBus[timingMessage][control][7]\[15:0],\diagnosticBus[timingMessage][control][8]\[15:0],\diagnosticBus[timingMessage][control][9]\[15:0],\diagnosticBus[timingMessage][control][10]\[15:0],\diagnosticBus[timingMessage][control][11]\[15:0],\diagnosticBus[timingMessage][control][12]\[15:0],\diagnosticBus[timingMessage][control][13]\[15:0],\diagnosticBus[timingMessage][control][14]\[15:0],\diagnosticBus[timingMessage][control][15]\[15:0],\diagnosticBus[timingMessage][control][16]\[15:0],\diagnosticBus[timingMessage][control][17]\[15:0],waveformClk,waveformRst,\obAppWaveformMasters[1][3][tValid]\,\obAppWaveformMasters[1][3][tData]\[127:0],\obAppWaveformMasters[1][3][tStrb]\[15:0],\obAppWaveformMasters[1][3][tKeep]\[15:0],\obAppWaveformMasters[1][3][tLast]\,\obAppWaveformMasters[1][3][tDest]\[7:0],\obAppWaveformMasters[1][3][tId]\[7:0],\obAppWaveformMasters[1][3][tUser]\[127:0],\obAppWaveformMasters[1][2][tValid]\,\obAppWaveformMasters[1][2][tData]\[127:0],\obAppWaveformMasters[1][2][tStrb]\[15:0],\obAppWaveformMasters[1][2][tKeep]\[15:0],\obAppWaveformMasters[1][2][tLast]\,\obAppWaveformMasters[1][2][tDest]\[7:0],\obAppWaveformMasters[1][2][tId]\[7:0],\obAppWaveformMasters[1][2][tUser]\[127:0],\obAppWaveformMasters[1][1][tValid]\,\obAppWaveformMasters[1][1][tData]\[127:0],\obAppWaveformMasters[1][1][tStrb]\[15:0],\obAppWaveformMasters[1][1][tKeep]\[15:0],\obAppWaveformMasters[1][1][tLast]\,\obAppWaveformMasters[1][1][tDest]\[7:0],\obAppWaveformMasters[1][1][tId]\[7:0],\obAppWaveformMasters[1][1][tUser]\[127:0],\obAppWaveformMasters[1][0][tValid]\,\obAppWaveformMasters[1][0][tData]\[127:0],\obAppWaveformMasters[1][0][tStrb]\[15:0],\obAppWaveformMasters[1][0][tKeep]\[15:0],\obAppWaveformMasters[1][0][tLast]\,\obAppWaveformMasters[1][0][tDest]\[7:0],\obAppWaveformMasters[1][0][tId]\[7:0],\obAppWaveformMasters[1][0][tUser]\[127:0],\obAppWaveformMasters[0][3][tValid]\,\obAppWaveformMasters[0][3][tData]\[127:0],\obAppWaveformMasters[0][3][tStrb]\[15:0],\obAppWaveformMasters[0][3][tKeep]\[15:0],\obAppWaveformMasters[0][3][tLast]\,\obAppWaveformMasters[0][3][tDest]\[7:0],\obAppWaveformMasters[0][3][tId]\[7:0],\obAppWaveformMasters[0][3][tUser]\[127:0],\obAppWaveformMasters[0][2][tValid]\,\obAppWaveformMasters[0][2][tData]\[127:0],\obAppWaveformMasters[0][2][tStrb]\[15:0],\obAppWaveformMasters[0][2][tKeep]\[15:0],\obAppWaveformMasters[0][2][tLast]\,\obAppWaveformMasters[0][2][tDest]\[7:0],\obAppWaveformMasters[0][2][tId]\[7:0],\obAppWaveformMasters[0][2][tUser]\[127:0],\obAppWaveformMasters[0][1][tValid]\,\obAppWaveformMasters[0][1][tData]\[127:0],\obAppWaveformMasters[0][1][tStrb]\[15:0],\obAppWaveformMasters[0][1][tKeep]\[15:0],\obAppWaveformMasters[0][1][tLast]\,\obAppWaveformMasters[0][1][tDest]\[7:0],\obAppWaveformMasters[0][1][tId]\[7:0],\obAppWaveformMasters[0][1][tUser]\[127:0],\obAppWaveformMasters[0][0][tValid]\,\obAppWaveformMasters[0][0][tData]\[127:0],\obAppWaveformMasters[0][0][tStrb]\[15:0],\obAppWaveformMasters[0][0][tKeep]\[15:0],\obAppWaveformMasters[0][0][tLast]\,\obAppWaveformMasters[0][0][tDest]\[7:0],\obAppWaveformMasters[0][0][tId]\[7:0],\obAppWaveformMasters[0][0][tUser]\[127:0],\obAppWaveformSlaves[1][3][slave][tReady]\,\obAppWaveformSlaves[1][3][ctrl][pause]\,\obAppWaveformSlaves[1][3][ctrl][overflow]\,\obAppWaveformSlaves[1][3][ctrl][idle]\,\obAppWaveformSlaves[1][2][slave][tReady]\,\obAppWaveformSlaves[1][2][ctrl][pause]\,\obAppWaveformSlaves[1][2][ctrl][overflow]\,\obAppWaveformSlaves[1][2][ctrl][idle]\,\obAppWaveformSlaves[1][1][slave][tReady]\,\obAppWaveformSlaves[1][1][ctrl][pause]\,\obAppWaveformSlaves[1][1][ctrl][overflow]\,\obAppWaveformSlaves[1][1][ctrl][idle]\,\obAppWaveformSlaves[1][0][slave][tReady]\,\obAppWaveformSlaves[1][0][ctrl][pause]\,\obAppWaveformSlaves[1][0][ctrl][overflow]\,\obAppWaveformSlaves[1][0][ctrl][idle]\,\obAppWaveformSlaves[0][3][slave][tReady]\,\obAppWaveformSlaves[0][3][ctrl][pause]\,\obAppWaveformSlaves[0][3][ctrl][overflow]\,\obAppWaveformSlaves[0][3][ctrl][idle]\,\obAppWaveformSlaves[0][2][slave][tReady]\,\obAppWaveformSlaves[0][2][ctrl][pause]\,\obAppWaveformSlaves[0][2][ctrl][overflow]\,\obAppWaveformSlaves[0][2][ctrl][idle]\,\obAppWaveformSlaves[0][1][slave][tReady]\,\obAppWaveformSlaves[0][1][ctrl][pause]\,\obAppWaveformSlaves[0][1][ctrl][overflow]\,\obAppWaveformSlaves[0][1][ctrl][idle]\,\obAppWaveformSlaves[0][0][slave][tReady]\,\obAppWaveformSlaves[0][0][ctrl][pause]\,\obAppWaveformSlaves[0][0][ctrl][overflow]\,\obAppWaveformSlaves[0][0][ctrl][idle]\,\ibAppWaveformMasters[1][3][tValid]\,\ibAppWaveformMasters[1][3][tData]\[127:0],\ibAppWaveformMasters[1][3][tStrb]\[15:0],\ibAppWaveformMasters[1][3][tKeep]\[15:0],\ibAppWaveformMasters[1][3][tLast]\,\ibAppWaveformMasters[1][3][tDest]\[7:0],\ibAppWaveformMasters[1][3][tId]\[7:0],\ibAppWaveformMasters[1][3][tUser]\[127:0],\ibAppWaveformMasters[1][2][tValid]\,\ibAppWaveformMasters[1][2][tData]\[127:0],\ibAppWaveformMasters[1][2][tStrb]\[15:0],\ibAppWaveformMasters[1][2][tKeep]\[15:0],\ibAppWaveformMasters[1][2][tLast]\,\ibAppWaveformMasters[1][2][tDest]\[7:0],\ibAppWaveformMasters[1][2][tId]\[7:0],\ibAppWaveformMasters[1][2][tUser]\[127:0],\ibAppWaveformMasters[1][1][tValid]\,\ibAppWaveformMasters[1][1][tData]\[127:0],\ibAppWaveformMasters[1][1][tStrb]\[15:0],\ibAppWaveformMasters[1][1][tKeep]\[15:0],\ibAppWaveformMasters[1][1][tLast]\,\ibAppWaveformMasters[1][1][tDest]\[7:0],\ibAppWaveformMasters[1][1][tId]\[7:0],\ibAppWaveformMasters[1][1][tUser]\[127:0],\ibAppWaveformMasters[1][0][tValid]\,\ibAppWaveformMasters[1][0][tData]\[127:0],\ibAppWaveformMasters[1][0][tStrb]\[15:0],\ibAppWaveformMasters[1][0][tKeep]\[15:0],\ibAppWaveformMasters[1][0][tLast]\,\ibAppWaveformMasters[1][0][tDest]\[7:0],\ibAppWaveformMasters[1][0][tId]\[7:0],\ibAppWaveformMasters[1][0][tUser]\[127:0],\ibAppWaveformMasters[0][3][tValid]\,\ibAppWaveformMasters[0][3][tData]\[127:0],\ibAppWaveformMasters[0][3][tStrb]\[15:0],\ibAppWaveformMasters[0][3][tKeep]\[15:0],\ibAppWaveformMasters[0][3][tLast]\,\ibAppWaveformMasters[0][3][tDest]\[7:0],\ibAppWaveformMasters[0][3][tId]\[7:0],\ibAppWaveformMasters[0][3][tUser]\[127:0],\ibAppWaveformMasters[0][2][tValid]\,\ibAppWaveformMasters[0][2][tData]\[127:0],\ibAppWaveformMasters[0][2][tStrb]\[15:0],\ibAppWaveformMasters[0][2][tKeep]\[15:0],\ibAppWaveformMasters[0][2][tLast]\,\ibAppWaveformMasters[0][2][tDest]\[7:0],\ibAppWaveformMasters[0][2][tId]\[7:0],\ibAppWaveformMasters[0][2][tUser]\[127:0],\ibAppWaveformMasters[0][1][tValid]\,\ibAppWaveformMasters[0][1][tData]\[127:0],\ibAppWaveformMasters[0][1][tStrb]\[15:0],\ibAppWaveformMasters[0][1][tKeep]\[15:0],\ibAppWaveformMasters[0][1][tLast]\,\ibAppWaveformMasters[0][1][tDest]\[7:0],\ibAppWaveformMasters[0][1][tId]\[7:0],\ibAppWaveformMasters[0][1][tUser]\[127:0],\ibAppWaveformMasters[0][0][tValid]\,\ibAppWaveformMasters[0][0][tData]\[127:0],\ibAppWaveformMasters[0][0][tStrb]\[15:0],\ibAppWaveformMasters[0][0][tKeep]\[15:0],\ibAppWaveformMasters[0][0][tLast]\,\ibAppWaveformMasters[0][0][tDest]\[7:0],\ibAppWaveformMasters[0][0][tId]\[7:0],\ibAppWaveformMasters[0][0][tUser]\[127:0],\ibAppWaveformSlaves[1][3][slave][tReady]\,\ibAppWaveformSlaves[1][3][ctrl][pause]\,\ibAppWaveformSlaves[1][3][ctrl][overflow]\,\ibAppWaveformSlaves[1][3][ctrl][idle]\,\ibAppWaveformSlaves[1][2][slave][tReady]\,\ibAppWaveformSlaves[1][2][ctrl][pause]\,\ibAppWaveformSlaves[1][2][ctrl][overflow]\,\ibAppWaveformSlaves[1][2][ctrl][idle]\,\ibAppWaveformSlaves[1][1][slave][tReady]\,\ibAppWaveformSlaves[1][1][ctrl][pause]\,\ibAppWaveformSlaves[1][1][ctrl][overflow]\,\ibAppWaveformSlaves[1][1][ctrl][idle]\,\ibAppWaveformSlaves[1][0][slave][tReady]\,\ibAppWaveformSlaves[1][0][ctrl][pause]\,\ibAppWaveformSlaves[1][0][ctrl][overflow]\,\ibAppWaveformSlaves[1][0][ctrl][idle]\,\ibAppWaveformSlaves[0][3][slave][tReady]\,\ibAppWaveformSlaves[0][3][ctrl][pause]\,\ibAppWaveformSlaves[0][3][ctrl][overflow]\,\ibAppWaveformSlaves[0][3][ctrl][idle]\,\ibAppWaveformSlaves[0][2][slave][tReady]\,\ibAppWaveformSlaves[0][2][ctrl][pause]\,\ibAppWaveformSlaves[0][2][ctrl][overflow]\,\ibAppWaveformSlaves[0][2][ctrl][idle]\,\ibAppWaveformSlaves[0][1][slave][tReady]\,\ibAppWaveformSlaves[0][1][ctrl][pause]\,\ibAppWaveformSlaves[0][1][ctrl][overflow]\,\ibAppWaveformSlaves[0][1][ctrl][idle]\,\ibAppWaveformSlaves[0][0][slave][tReady]\,\ibAppWaveformSlaves[0][0][ctrl][pause]\,\ibAppWaveformSlaves[0][0][ctrl][overflow]\,\ibAppWaveformSlaves[0][0][ctrl][idle]\,\obBpMsgClientMaster[tValid]\,\obBpMsgClientMaster[tData]\[127:0],\obBpMsgClientMaster[tStrb]\[15:0],\obBpMsgClientMaster[tKeep]\[15:0],\obBpMsgClientMaster[tLast]\,\obBpMsgClientMaster[tDest]\[7:0],\obBpMsgClientMaster[tId]\[7:0],\obBpMsgClientMaster[tUser]\[127:0],\obBpMsgClientSlave[tReady]\,\ibBpMsgClientMaster[tValid]\,\ibBpMsgClientMaster[tData]\[127:0],\ibBpMsgClientMaster[tStrb]\[15:0],\ibBpMsgClientMaster[tKeep]\[15:0],\ibBpMsgClientMaster[tLast]\,\ibBpMsgClientMaster[tDest]\[7:0],\ibBpMsgClientMaster[tId]\[7:0],\ibBpMsgClientMaster[tUser]\[127:0],\ibBpMsgClientSlave[tReady]\,\obBpMsgServerMaster[tValid]\,\obBpMsgServerMaster[tData]\[127:0],\obBpMsgServerMaster[tStrb]\[15:0],\obBpMsgServerMaster[tKeep]\[15:0],\obBpMsgServerMaster[tLast]\,\obBpMsgServerMaster[tDest]\[7:0],\obBpMsgServerMaster[tId]\[7:0],\obBpMsgServerMaster[tUser]\[127:0],\obBpMsgServerSlave[tReady]\,\ibBpMsgServerMaster[tValid]\,\ibBpMsgServerMaster[tData]\[127:0],\ibBpMsgServerMaster[tStrb]\[15:0],\ibBpMsgServerMaster[tKeep]\[15:0],\ibBpMsgServerMaster[tLast]\,\ibBpMsgServerMaster[tDest]\[7:0],\ibBpMsgServerMaster[tId]\[7:0],\ibBpMsgServerMaster[tUser]\[127:0],\ibBpMsgServerSlave[tReady]\,\obAppDebugMaster[tValid]\,\obAppDebugMaster[tData]\[127:0],\obAppDebugMaster[tStrb]\[15:0],\obAppDebugMaster[tKeep]\[15:0],\obAppDebugMaster[tLast]\,\obAppDebugMaster[tDest]\[7:0],\obAppDebugMaster[tId]\[7:0],\obAppDebugMaster[tUser]\[127:0],\obAppDebugSlave[tReady]\,\ibAppDebugMaster[tValid]\,\ibAppDebugMaster[tData]\[127:0],\ibAppDebugMaster[tStrb]\[15:0],\ibAppDebugMaster[tKeep]\[15:0],\ibAppDebugMaster[tLast]\,\ibAppDebugMaster[tDest]\[7:0],\ibAppDebugMaster[tId]\[7:0],\ibAppDebugMaster[tUser]\[127:0],\ibAppDebugSlave[tReady]\,recTimingClk,recTimingRst,ref156MHzClk,ref156MHzRst,gthFabClk,\axilReadMasters[1][araddr]\[31:0],\axilReadMasters[1][arprot]\[2:0],\axilReadMasters[1][arvalid]\,\axilReadMasters[1][rready]\,\axilReadMasters[0][araddr]\[31:0],\axilReadMasters[0][arprot]\[2:0],\axilReadMasters[0][arvalid]\,\axilReadMasters[0][rready]\,\axilReadSlaves[1][arready]\,\axilReadSlaves[1][rdata]\[31:0],\axilReadSlaves[1][rresp]\[1:0],\axilReadSlaves[1][rvalid]\,\axilReadSlaves[0][arready]\,\axilReadSlaves[0][rdata]\[31:0],\axilReadSlaves[0][rresp]\[1:0],\axilReadSlaves[0][rvalid]\,\axilWriteMasters[1][awaddr]\[31:0],\axilWriteMasters[1][awprot]\[2:0],\axilWriteMasters[1][awvalid]\,\axilWriteMasters[1][wdata]\[31:0],\axilWriteMasters[1][wstrb]\[3:0],\axilWriteMasters[1][wvalid]\,\axilWriteMasters[1][bready]\,\axilWriteMasters[0][awaddr]\[31:0],\axilWriteMasters[0][awprot]\[2:0],\axilWriteMasters[0][awvalid]\,\axilWriteMasters[0][wdata]\[31:0],\axilWriteMasters[0][wstrb]\[3:0],\axilWriteMasters[0][wvalid]\,\axilWriteMasters[0][bready]\,\axilWriteSlaves[1][awready]\,\axilWriteSlaves[1][wready]\,\axilWriteSlaves[1][bresp]\[1:0],\axilWriteSlaves[1][bvalid]\,\axilWriteSlaves[0][awready]\,\axilWriteSlaves[0][wready]\,\axilWriteSlaves[0][bresp]\[1:0],\axilWriteSlaves[0][bvalid]\,\ethReadMaster[araddr]\[31:0],\ethReadMaster[arprot]\[2:0],\ethReadMaster[arvalid]\,\ethReadMaster[rready]\,\ethReadSlave[arready]\,\ethReadSlave[rdata]\[31:0],\ethReadSlave[rresp]\[1:0],\ethReadSlave[rvalid]\,\ethWriteMaster[awaddr]\[31:0],\ethWriteMaster[awprot]\[2:0],\ethWriteMaster[awvalid]\,\ethWriteMaster[wdata]\[31:0],\ethWriteMaster[wstrb]\[3:0],\ethWriteMaster[wvalid]\,\ethWriteMaster[bready]\,\ethWriteSlave[awready]\,\ethWriteSlave[wready]\,\ethWriteSlave[bresp]\[1:0],\ethWriteSlave[bvalid]\,localMac[47:0],localIp[31:0],ethLinkUp,\timingReadMaster[araddr]\[31:0],\timingReadMaster[arprot]\[2:0],\timingReadMaster[arvalid]\,\timingReadMaster[rready]\,\timingReadSlave[arready]\,\timingReadSlave[rdata]\[31:0],\timingReadSlave[rresp]\[1:0],\timingReadSlave[rvalid]\,\timingWriteMaster[awaddr]\[31:0],\timingWriteMaster[awprot]\[2:0],\timingWriteMaster[awvalid]\,\timingWriteMaster[wdata]\[31:0],\timingWriteMaster[wstrb]\[3:0],\timingWriteMaster[wvalid]\,\timingWriteMaster[bready]\,\timingWriteSlave[awready]\,\timingWriteSlave[wready]\,\timingWriteSlave[bresp]\[1:0],\timingWriteSlave[bvalid]\,\bsaReadMaster[araddr]\[31:0],\bsaReadMaster[arprot]\[2:0],\bsaReadMaster[arvalid]\,\bsaReadMaster[rready]\,\bsaReadSlave[arready]\,\bsaReadSlave[rdata]\[31:0],\bsaReadSlave[rresp]\[1:0],\bsaReadSlave[rvalid]\,\bsaWriteMaster[awaddr]\[31:0],\bsaWriteMaster[awprot]\[2:0],\bsaWriteMaster[awvalid]\,\bsaWriteMaster[wdata]\[31:0],\bsaWriteMaster[wstrb]\[3:0],\bsaWriteMaster[wvalid]\,\bsaWriteMaster[bready]\,\bsaWriteSlave[awready]\,\bsaWriteSlave[wready]\,\bsaWriteSlave[bresp]\[1:0],\bsaWriteSlave[bvalid]\,\ddrReadMaster[araddr]\[31:0],\ddrReadMaster[arprot]\[2:0],\ddrReadMaster[arvalid]\,\ddrReadMaster[rready]\,\ddrReadSlave[arready]\,\ddrReadSlave[rdata]\[31:0],\ddrReadSlave[rresp]\[1:0],\ddrReadSlave[rvalid]\,\ddrWriteMaster[awaddr]\[31:0],\ddrWriteMaster[awprot]\[2:0],\ddrWriteMaster[awvalid]\,\ddrWriteMaster[wdata]\[31:0],\ddrWriteMaster[wstrb]\[3:0],\ddrWriteMaster[wvalid]\,\ddrWriteMaster[bready]\,\ddrWriteSlave[awready]\,\ddrWriteSlave[wready]\,\ddrWriteSlave[bresp]\[1:0],\ddrWriteSlave[bvalid]\,ddrMemReady,ddrMemError,fabClkP,fabClkN,ethRxP[3:0],ethRxN[3:0],ethTxP[3:0],ethTxN[3:0],ethClkP,ethClkN,timingRxP,timingRxN,timingTxP,timingTxN,timingRefClkInP,timingRefClkInN,timingRecClkOutP,timingRecClkOutN,timingClkSel,enAuxPwrL,ddrClkP,ddrClkN,ddrDm[7:0],ddrDqsP[7:0],ddrDqsN[7:0],ddrDq[63:0],ddrA[15:0],ddrBa[2:0],ddrCsL[1:0],ddrOdt[1:0],ddrCke[1:0],ddrCkP[1:0],ddrCkN[1:0],ddrWeL,ddrRasL,ddrCasL,ddrRstL,ddrAlertL,ddrPg,ddrPwrEnL";

   constant AXI_ERROR_RESP_C : slv(1 downto 0) := AXI_RESP_DECERR_C;

   -- AXI-Lite Master bus
   signal axilReadMasters   : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves    : AxiLiteReadSlaveArray(1 downto 0);
   signal axilWriteMasters  : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves   : AxiLiteWriteSlaveArray(1 downto 0);
   --  ETH Interface
   signal ethReadMaster     : AxiLiteReadMasterType;
   signal ethReadSlave      : AxiLiteReadSlaveType;
   signal ethWriteMaster    : AxiLiteWriteMasterType;
   signal ethWriteSlave     : AxiLiteWriteSlaveType;
   signal localMac          : slv(47 downto 0);
   signal localIp           : slv(31 downto 0);
   signal ethLinkUp         : sl;
   --  Timing Interface
   signal timingReadMaster  : AxiLiteReadMasterType;
   signal timingReadSlave   : AxiLiteReadSlaveType;
   signal timingWriteMaster : AxiLiteWriteMasterType;
   signal timingWriteSlave  : AxiLiteWriteSlaveType;
   --  BSA Interface
   signal bsaReadMaster     : AxiLiteReadMasterType;
   signal bsaReadSlave      : AxiLiteReadSlaveType;
   signal bsaWriteMaster    : AxiLiteWriteMasterType;
   signal bsaWriteSlave     : AxiLiteWriteSlaveType;
   --  DDR Interface
   signal ddrReadMaster     : AxiLiteReadMasterType;
   signal ddrReadSlave      : AxiLiteReadSlaveType;
   signal ddrWriteMaster    : AxiLiteWriteMasterType;
   signal ddrWriteSlave     : AxiLiteWriteSlaveType;
   signal ddrMemReady       : sl;
   signal ddrMemError       : sl;
   --  MPS Interface
   signal mpsReadMaster     : AxiLiteReadMasterType;
   signal mpsReadSlave      : AxiLiteReadSlaveType;
   signal mpsWriteMaster    : AxiLiteWriteMasterType;
   signal mpsWriteSlave     : AxiLiteWriteSlaveType;

   signal ref156MHzClk  : sl;
   signal ref156MHzRst  : sl;
   signal bsiBus        : BsiBusType;
   signal timingBusIntf : TimingBusType;

begin

   axilClk     <= ref156MHzClk;
   axilRst     <= ref156MHzRst;
   ipmiBsi     <= bsiBus;
   ethPhyReady <= ethLinkUp;
   timingBus   <= timingBusIntf;

   ----------------------------------   
   -- Register Address Mapping Module
   ----------------------------------   
   U_SysReg : entity work.AmcCarrierSysReg
      generic map (
         TPD_G            => TPD_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         APP_TYPE_G       => APP_TYPE_G,
         MPS_SLOT_G       => MPS_SLOT_G,
         FSBL_G           => false)
      port map (
         -- Primary AXI-Lite Interface
         axilClk           => ref156MHzClk,
         axilRst           => ref156MHzRst,
         sAxilReadMasters  => axilReadMasters,
         sAxilReadSlaves   => axilReadSlaves,
         sAxilWriteMasters => axilWriteMasters,
         sAxilWriteSlaves  => axilWriteSlaves,
         -- Timing AXI-Lite Interface
         timingReadMaster  => timingReadMaster,
         timingReadSlave   => timingReadSlave,
         timingWriteMaster => timingWriteMaster,
         timingWriteSlave  => timingWriteSlave,
         -- Bsa AXI-Lite Interface
         bsaReadMaster     => bsaReadMaster,
         bsaReadSlave      => bsaReadSlave,
         bsaWriteMaster    => bsaWriteMaster,
         bsaWriteSlave     => bsaWriteSlave,
         -- ETH AXI-Lite Interface
         ethReadMaster     => ethReadMaster,
         ethReadSlave      => ethReadSlave,
         ethWriteMaster    => ethWriteMaster,
         ethWriteSlave     => ethWriteSlave,
         -- DDR PHY AXI-Lite Interface
         ddrReadMaster     => ddrReadMaster,
         ddrReadSlave      => ddrReadSlave,
         ddrWriteMaster    => ddrWriteMaster,
         ddrWriteSlave     => ddrWriteSlave,
         ddrMemReady       => ddrMemReady,
         ddrMemError       => ddrMemError,
         -- MPS PHY AXI-Lite Interface
         mpsReadMaster     => mpsReadMaster,
         mpsReadSlave      => mpsReadSlave,
         mpsWriteMaster    => mpsWriteMaster,
         mpsWriteSlave     => mpsWriteSlave,
         -- Local Configuration
         localMac          => localMac,
         localIp           => localIp,
         ethLinkUp         => ethLinkUp,
         ----------------------
         -- Top Level Interface
         ----------------------              
         -- Application AXI-Lite Interface
         appReadMaster     => axilReadMaster,
         appReadSlave      => axilReadSlave,
         appWriteMaster    => axilWriteMaster,
         appWriteSlave     => axilWriteSlave,
         -- BSI Interface
         bsiBus            => bsiBus,
         ----------------
         -- Core Ports --
         ----------------   
         -- Crossbar Ports
         xBarSin           => xBarSin,
         xBarSout          => xBarSout,
         xBarConfig        => xBarConfig,
         xBarLoad          => xBarLoad,
         -- IPMC Ports
         ipmcScl           => ipmcScl,
         ipmcSda           => ipmcSda,
         -- Configuration PROM Ports
         calScl            => calScl,
         calSda            => calSda,
         -- Clock Cleaner Ports
         timingClkScl      => timingClkScl,
         timingClkSda      => timingClkSda,
         -- DDR3L SO-DIMM Ports
         ddrScl            => ddrScl,
         ddrSda            => ddrSda,
         -- SYSMON Ports
         vPIn              => vPIn,
         vNIn              => vNIn);

   ------------------
   -- Application MPS
   ------------------
   U_AppMps : entity work.AppMps
      generic map (
         TPD_G            => TPD_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         MPS_SLOT_G       => MPS_SLOT_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => ref156MHzClk,
         axilRst         => ref156MHzRst,
         axilReadMaster  => mpsReadMaster,
         axilReadSlave   => mpsReadSlave,
         axilWriteMaster => mpsWriteMaster,
         axilWriteSlave  => mpsWriteSlave,
         -- System Status
         bsiBus          => bsiBus,
         ethLinkUp       => ethLinkUp,
         timingClk       => timingClk,
         timingRst       => timingRst,
         timingBus       => timingBusIntf,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk   => diagnosticClk,
         diagnosticRst   => diagnosticRst,
         mpsCoreReg      => mpsCoreReg,
         diagnosticBus   => diagnosticBus,
         -- MPS Interface
         mpsObMasters    => mpsObMasters,
         mpsObSlaves     => mpsObSlaves,
         ----------------
         -- Core Ports --
         ----------------
         -- Backplane MPS Ports
         mpsClkIn        => mpsClkIn,
         mpsClkOut       => mpsClkOut,
         mpsBusRxP       => mpsBusRxP,
         mpsBusRxN       => mpsBusRxN,
         mpsTxP          => mpsTxP,
         mpsTxN          => mpsTxN);

   ---------------------------
   -- AMC Carrier Core Release
   ---------------------------         
   U_Core : entity work.AmcCarrierCore
      port map (
         timingClk                                        => timingClk,
         timingRst                                        => timingRst,
         \timingBusIntf[strobe]\                          => timingBusIntf.strobe,
         \timingBusIntf[valid]\                           => timingBusIntf.valid,
         \timingBusIntf[message][version]\                => timingBusIntf.message.version,
         \timingBusIntf[message][pulseId]\                => timingBusIntf.message.pulseId,
         \timingBusIntf[message][timeStamp]\              => timingBusIntf.message.timeStamp,
         \timingBusIntf[message][fixedRates]\             => timingBusIntf.message.fixedRates,
         \timingBusIntf[message][acRates]\                => timingBusIntf.message.acRates,
         \timingBusIntf[message][acTimeSlot]\             => timingBusIntf.message.acTimeSlot,
         \timingBusIntf[message][acTimeSlotPhase]\        => timingBusIntf.message.acTimeSlotPhase,
         \timingBusIntf[message][resync]\                 => timingBusIntf.message.resync,
         \timingBusIntf[message][beamRequest]\            => timingBusIntf.message.beamRequest,
         \timingBusIntf[message][beamEnergy][0]\          => timingBusIntf.message.beamEnergy(0),
         \timingBusIntf[message][beamEnergy][1]\          => timingBusIntf.message.beamEnergy(1),
         \timingBusIntf[message][beamEnergy][2]\          => timingBusIntf.message.beamEnergy(2),
         \timingBusIntf[message][beamEnergy][3]\          => timingBusIntf.message.beamEnergy(3),
         \timingBusIntf[message][photonWavelen][0]\       => timingBusIntf.message.photonWavelen(0),
         \timingBusIntf[message][photonWavelen][1]\       => timingBusIntf.message.photonWavelen(1),
         \timingBusIntf[message][syncStatus]\             => timingBusIntf.message.syncStatus,
         \timingBusIntf[message][mpsValid]\               => timingBusIntf.message.mpsValid,
         \timingBusIntf[message][bcsFault]\               => timingBusIntf.message.bcsFault,
         \timingBusIntf[message][mpsLimit]\               => timingBusIntf.message.mpsLimit,
         \timingBusIntf[message][mpsClass][0]\            => timingBusIntf.message.mpsClass(0),
         \timingBusIntf[message][mpsClass][1]\            => timingBusIntf.message.mpsClass(1),
         \timingBusIntf[message][mpsClass][2]\            => timingBusIntf.message.mpsClass(2),
         \timingBusIntf[message][mpsClass][3]\            => timingBusIntf.message.mpsClass(3),
         \timingBusIntf[message][mpsClass][4]\            => timingBusIntf.message.mpsClass(4),
         \timingBusIntf[message][mpsClass][5]\            => timingBusIntf.message.mpsClass(5),
         \timingBusIntf[message][mpsClass][6]\            => timingBusIntf.message.mpsClass(6),
         \timingBusIntf[message][mpsClass][7]\            => timingBusIntf.message.mpsClass(7),
         \timingBusIntf[message][mpsClass][8]\            => timingBusIntf.message.mpsClass(8),
         \timingBusIntf[message][mpsClass][9]\            => timingBusIntf.message.mpsClass(9),
         \timingBusIntf[message][mpsClass][10]\           => timingBusIntf.message.mpsClass(10),
         \timingBusIntf[message][mpsClass][11]\           => timingBusIntf.message.mpsClass(11),
         \timingBusIntf[message][mpsClass][12]\           => timingBusIntf.message.mpsClass(12),
         \timingBusIntf[message][mpsClass][13]\           => timingBusIntf.message.mpsClass(13),
         \timingBusIntf[message][mpsClass][14]\           => timingBusIntf.message.mpsClass(14),
         \timingBusIntf[message][mpsClass][15]\           => timingBusIntf.message.mpsClass(15),
         \timingBusIntf[message][bsaInit]\                => timingBusIntf.message.bsaInit,
         \timingBusIntf[message][bsaActive]\              => timingBusIntf.message.bsaActive,
         \timingBusIntf[message][bsaAvgDone]\             => timingBusIntf.message.bsaAvgDone,
         \timingBusIntf[message][bsaDone]\                => timingBusIntf.message.bsaDone,
         \timingBusIntf[message][control][0]\             => timingBusIntf.message.control(0),
         \timingBusIntf[message][control][1]\             => timingBusIntf.message.control(1),
         \timingBusIntf[message][control][2]\             => timingBusIntf.message.control(2),
         \timingBusIntf[message][control][3]\             => timingBusIntf.message.control(3),
         \timingBusIntf[message][control][4]\             => timingBusIntf.message.control(4),
         \timingBusIntf[message][control][5]\             => timingBusIntf.message.control(5),
         \timingBusIntf[message][control][6]\             => timingBusIntf.message.control(6),
         \timingBusIntf[message][control][7]\             => timingBusIntf.message.control(7),
         \timingBusIntf[message][control][8]\             => timingBusIntf.message.control(8),
         \timingBusIntf[message][control][9]\             => timingBusIntf.message.control(9),
         \timingBusIntf[message][control][10]\            => timingBusIntf.message.control(10),
         \timingBusIntf[message][control][11]\            => timingBusIntf.message.control(11),
         \timingBusIntf[message][control][12]\            => timingBusIntf.message.control(12),
         \timingBusIntf[message][control][13]\            => timingBusIntf.message.control(13),
         \timingBusIntf[message][control][14]\            => timingBusIntf.message.control(14),
         \timingBusIntf[message][control][15]\            => timingBusIntf.message.control(15),
         \timingBusIntf[message][control][16]\            => timingBusIntf.message.control(16),
         \timingBusIntf[message][control][17]\            => timingBusIntf.message.control(17),
         \timingBusIntf[stream][pulseId]\                 => timingBusIntf.stream.pulseId,
         \timingBusIntf[stream][eventCodes]\              => timingBusIntf.stream.eventCodes,
         \timingBusIntf[stream][dbuff][dtype]\            => timingBusIntf.stream.dbuff.dtype,
         \timingBusIntf[stream][dbuff][version]\          => timingBusIntf.stream.dbuff.version,
         \timingBusIntf[stream][dbuff][dmod]\             => timingBusIntf.stream.dbuff.dmod,
         \timingBusIntf[stream][dbuff][epicsTime]\        => timingBusIntf.stream.dbuff.epicsTime,
         \timingBusIntf[stream][dbuff][edefAvgDn]\        => timingBusIntf.stream.dbuff.edefAvgDn,
         \timingBusIntf[stream][dbuff][edefMinor]\        => timingBusIntf.stream.dbuff.edefMinor,
         \timingBusIntf[stream][dbuff][edefMajor]\        => timingBusIntf.stream.dbuff.edefMajor,
         \timingBusIntf[stream][dbuff][edefInit]\         => timingBusIntf.stream.dbuff.edefInit,
         \timingBusIntf[v1][linkUp]\                      => timingBusIntf.v1.linkUp,
         \timingBusIntf[v1][gtRxData]\                    => timingBusIntf.v1.gtRxData,
         \timingBusIntf[v1][gtRxDataK]\                   => timingBusIntf.v1.gtRxDataK,
         \timingBusIntf[v1][gtRxDispErr]\                 => timingBusIntf.v1.gtRxDispErr,
         \timingBusIntf[v1][gtRxDecErr]\                  => timingBusIntf.v1.gtRxDecErr,
         \timingBusIntf[v2][linkUp]\                      => timingBusIntf.v2.linkUp,
         \timingPhy[dataK]\                               => timingPhy.dataK,
         \timingPhy[data]\                                => timingPhy.data,
         \timingPhy[control][reset]\                      => timingPhy.control.reset,
         \timingPhy[control][inhibit]\                    => timingPhy.control.inhibit,
         \timingPhy[control][polarity]\                   => timingPhy.control.polarity,
         \timingPhy[control][bufferByRst]\                => timingPhy.control.bufferByRst,
         \timingPhy[control][pllReset]\                   => timingPhy.control.pllReset,
         timingPhyClk                                     => timingPhyClk,
         timingPhyRst                                     => timingPhyRst,
         timingRefClk                                     => timingRefClk,
         timingRefClkDiv2                                 => timingRefClkDiv2,
         diagnosticClk                                    => diagnosticClk,
         diagnosticRst                                    => diagnosticRst,
         \diagnosticBus[strobe]\                          => diagnosticBus.strobe,
         \diagnosticBus[data][31]\                        => diagnosticBus.data(31),
         \diagnosticBus[data][30]\                        => diagnosticBus.data(30),
         \diagnosticBus[data][29]\                        => diagnosticBus.data(29),
         \diagnosticBus[data][28]\                        => diagnosticBus.data(28),
         \diagnosticBus[data][27]\                        => diagnosticBus.data(27),
         \diagnosticBus[data][26]\                        => diagnosticBus.data(26),
         \diagnosticBus[data][25]\                        => diagnosticBus.data(25),
         \diagnosticBus[data][24]\                        => diagnosticBus.data(24),
         \diagnosticBus[data][23]\                        => diagnosticBus.data(23),
         \diagnosticBus[data][22]\                        => diagnosticBus.data(22),
         \diagnosticBus[data][21]\                        => diagnosticBus.data(21),
         \diagnosticBus[data][20]\                        => diagnosticBus.data(20),
         \diagnosticBus[data][19]\                        => diagnosticBus.data(19),
         \diagnosticBus[data][18]\                        => diagnosticBus.data(18),
         \diagnosticBus[data][17]\                        => diagnosticBus.data(17),
         \diagnosticBus[data][16]\                        => diagnosticBus.data(16),
         \diagnosticBus[data][15]\                        => diagnosticBus.data(15),
         \diagnosticBus[data][14]\                        => diagnosticBus.data(14),
         \diagnosticBus[data][13]\                        => diagnosticBus.data(13),
         \diagnosticBus[data][12]\                        => diagnosticBus.data(12),
         \diagnosticBus[data][11]\                        => diagnosticBus.data(11),
         \diagnosticBus[data][10]\                        => diagnosticBus.data(10),
         \diagnosticBus[data][9]\                         => diagnosticBus.data(9),
         \diagnosticBus[data][8]\                         => diagnosticBus.data(8),
         \diagnosticBus[data][7]\                         => diagnosticBus.data(7),
         \diagnosticBus[data][6]\                         => diagnosticBus.data(6),
         \diagnosticBus[data][5]\                         => diagnosticBus.data(5),
         \diagnosticBus[data][4]\                         => diagnosticBus.data(4),
         \diagnosticBus[data][3]\                         => diagnosticBus.data(3),
         \diagnosticBus[data][2]\                         => diagnosticBus.data(2),
         \diagnosticBus[data][1]\                         => diagnosticBus.data(1),
         \diagnosticBus[data][0]\                         => diagnosticBus.data(0),
         \diagnosticBus[sevr][31]\                        => diagnosticBus.sevr(31),
         \diagnosticBus[sevr][30]\                        => diagnosticBus.sevr(30),
         \diagnosticBus[sevr][29]\                        => diagnosticBus.sevr(29),
         \diagnosticBus[sevr][28]\                        => diagnosticBus.sevr(28),
         \diagnosticBus[sevr][27]\                        => diagnosticBus.sevr(27),
         \diagnosticBus[sevr][26]\                        => diagnosticBus.sevr(26),
         \diagnosticBus[sevr][25]\                        => diagnosticBus.sevr(25),
         \diagnosticBus[sevr][24]\                        => diagnosticBus.sevr(24),
         \diagnosticBus[sevr][23]\                        => diagnosticBus.sevr(23),
         \diagnosticBus[sevr][22]\                        => diagnosticBus.sevr(22),
         \diagnosticBus[sevr][21]\                        => diagnosticBus.sevr(21),
         \diagnosticBus[sevr][20]\                        => diagnosticBus.sevr(20),
         \diagnosticBus[sevr][19]\                        => diagnosticBus.sevr(19),
         \diagnosticBus[sevr][18]\                        => diagnosticBus.sevr(18),
         \diagnosticBus[sevr][17]\                        => diagnosticBus.sevr(17),
         \diagnosticBus[sevr][16]\                        => diagnosticBus.sevr(16),
         \diagnosticBus[sevr][15]\                        => diagnosticBus.sevr(15),
         \diagnosticBus[sevr][14]\                        => diagnosticBus.sevr(14),
         \diagnosticBus[sevr][13]\                        => diagnosticBus.sevr(13),
         \diagnosticBus[sevr][12]\                        => diagnosticBus.sevr(12),
         \diagnosticBus[sevr][11]\                        => diagnosticBus.sevr(11),
         \diagnosticBus[sevr][10]\                        => diagnosticBus.sevr(10),
         \diagnosticBus[sevr][9]\                         => diagnosticBus.sevr(9),
         \diagnosticBus[sevr][8]\                         => diagnosticBus.sevr(8),
         \diagnosticBus[sevr][7]\                         => diagnosticBus.sevr(7),
         \diagnosticBus[sevr][6]\                         => diagnosticBus.sevr(6),
         \diagnosticBus[sevr][5]\                         => diagnosticBus.sevr(5),
         \diagnosticBus[sevr][4]\                         => diagnosticBus.sevr(4),
         \diagnosticBus[sevr][3]\                         => diagnosticBus.sevr(3),
         \diagnosticBus[sevr][2]\                         => diagnosticBus.sevr(2),
         \diagnosticBus[sevr][1]\                         => diagnosticBus.sevr(1),
         \diagnosticBus[sevr][0]\                         => diagnosticBus.sevr(0),
         \diagnosticBus[fixed]\                           => diagnosticBus.fixed,
         \diagnosticBus[mpsIgnore]\                       => diagnosticBus.mpsIgnore,
         \diagnosticBus[timingMessage][version]\          => diagnosticBus.timingMessage.version,
         \diagnosticBus[timingMessage][pulseId]\          => diagnosticBus.timingMessage.pulseId,
         \diagnosticBus[timingMessage][timeStamp]\        => diagnosticBus.timingMessage.timeStamp,
         \diagnosticBus[timingMessage][fixedRates]\       => diagnosticBus.timingMessage.fixedRates,
         \diagnosticBus[timingMessage][acRates]\          => diagnosticBus.timingMessage.acRates,
         \diagnosticBus[timingMessage][acTimeSlot]\       => diagnosticBus.timingMessage.acTimeSlot,
         \diagnosticBus[timingMessage][acTimeSlotPhase]\  => diagnosticBus.timingMessage.acTimeSlotPhase,
         \diagnosticBus[timingMessage][resync]\           => diagnosticBus.timingMessage.resync,
         \diagnosticBus[timingMessage][beamRequest]\      => diagnosticBus.timingMessage.beamRequest,
         \diagnosticBus[timingMessage][beamEnergy][0]\    => diagnosticBus.timingMessage.beamEnergy(0),
         \diagnosticBus[timingMessage][beamEnergy][1]\    => diagnosticBus.timingMessage.beamEnergy(1),
         \diagnosticBus[timingMessage][beamEnergy][2]\    => diagnosticBus.timingMessage.beamEnergy(2),
         \diagnosticBus[timingMessage][beamEnergy][3]\    => diagnosticBus.timingMessage.beamEnergy(3),
         \diagnosticBus[timingMessage][photonWavelen][0]\ => diagnosticBus.timingMessage.photonWavelen(0),
         \diagnosticBus[timingMessage][photonWavelen][1]\ => diagnosticBus.timingMessage.photonWavelen(1),
         \diagnosticBus[timingMessage][syncStatus]\       => diagnosticBus.timingMessage.syncStatus,
         \diagnosticBus[timingMessage][mpsValid]\         => diagnosticBus.timingMessage.mpsValid,
         \diagnosticBus[timingMessage][bcsFault]\         => diagnosticBus.timingMessage.bcsFault,
         \diagnosticBus[timingMessage][mpsLimit]\         => diagnosticBus.timingMessage.mpsLimit,
         \diagnosticBus[timingMessage][mpsClass][0]\      => diagnosticBus.timingMessage.mpsClass(0),
         \diagnosticBus[timingMessage][mpsClass][1]\      => diagnosticBus.timingMessage.mpsClass(1),
         \diagnosticBus[timingMessage][mpsClass][2]\      => diagnosticBus.timingMessage.mpsClass(2),
         \diagnosticBus[timingMessage][mpsClass][3]\      => diagnosticBus.timingMessage.mpsClass(3),
         \diagnosticBus[timingMessage][mpsClass][4]\      => diagnosticBus.timingMessage.mpsClass(4),
         \diagnosticBus[timingMessage][mpsClass][5]\      => diagnosticBus.timingMessage.mpsClass(5),
         \diagnosticBus[timingMessage][mpsClass][6]\      => diagnosticBus.timingMessage.mpsClass(6),
         \diagnosticBus[timingMessage][mpsClass][7]\      => diagnosticBus.timingMessage.mpsClass(7),
         \diagnosticBus[timingMessage][mpsClass][8]\      => diagnosticBus.timingMessage.mpsClass(8),
         \diagnosticBus[timingMessage][mpsClass][9]\      => diagnosticBus.timingMessage.mpsClass(9),
         \diagnosticBus[timingMessage][mpsClass][10]\     => diagnosticBus.timingMessage.mpsClass(10),
         \diagnosticBus[timingMessage][mpsClass][11]\     => diagnosticBus.timingMessage.mpsClass(11),
         \diagnosticBus[timingMessage][mpsClass][12]\     => diagnosticBus.timingMessage.mpsClass(12),
         \diagnosticBus[timingMessage][mpsClass][13]\     => diagnosticBus.timingMessage.mpsClass(13),
         \diagnosticBus[timingMessage][mpsClass][14]\     => diagnosticBus.timingMessage.mpsClass(14),
         \diagnosticBus[timingMessage][mpsClass][15]\     => diagnosticBus.timingMessage.mpsClass(15),
         \diagnosticBus[timingMessage][bsaInit]\          => diagnosticBus.timingMessage.bsaInit,
         \diagnosticBus[timingMessage][bsaActive]\        => diagnosticBus.timingMessage.bsaActive,
         \diagnosticBus[timingMessage][bsaAvgDone]\       => diagnosticBus.timingMessage.bsaAvgDone,
         \diagnosticBus[timingMessage][bsaDone]\          => diagnosticBus.timingMessage.bsaDone,
         \diagnosticBus[timingMessage][control][0]\       => diagnosticBus.timingMessage.control(0),
         \diagnosticBus[timingMessage][control][1]\       => diagnosticBus.timingMessage.control(1),
         \diagnosticBus[timingMessage][control][2]\       => diagnosticBus.timingMessage.control(2),
         \diagnosticBus[timingMessage][control][3]\       => diagnosticBus.timingMessage.control(3),
         \diagnosticBus[timingMessage][control][4]\       => diagnosticBus.timingMessage.control(4),
         \diagnosticBus[timingMessage][control][5]\       => diagnosticBus.timingMessage.control(5),
         \diagnosticBus[timingMessage][control][6]\       => diagnosticBus.timingMessage.control(6),
         \diagnosticBus[timingMessage][control][7]\       => diagnosticBus.timingMessage.control(7),
         \diagnosticBus[timingMessage][control][8]\       => diagnosticBus.timingMessage.control(8),
         \diagnosticBus[timingMessage][control][9]\       => diagnosticBus.timingMessage.control(9),
         \diagnosticBus[timingMessage][control][10]\      => diagnosticBus.timingMessage.control(10),
         \diagnosticBus[timingMessage][control][11]\      => diagnosticBus.timingMessage.control(11),
         \diagnosticBus[timingMessage][control][12]\      => diagnosticBus.timingMessage.control(12),
         \diagnosticBus[timingMessage][control][13]\      => diagnosticBus.timingMessage.control(13),
         \diagnosticBus[timingMessage][control][14]\      => diagnosticBus.timingMessage.control(14),
         \diagnosticBus[timingMessage][control][15]\      => diagnosticBus.timingMessage.control(15),
         \diagnosticBus[timingMessage][control][16]\      => diagnosticBus.timingMessage.control(16),
         \diagnosticBus[timingMessage][control][17]\      => diagnosticBus.timingMessage.control(17),
         waveformClk                                      => waveformClk,
         waveformRst                                      => waveformRst,
         \obAppWaveformMasters[1][3][tValid]\             => obAppWaveformMasters(1)(3).tValid,
         \obAppWaveformMasters[1][3][tData]\              => obAppWaveformMasters(1)(3).tData,
         \obAppWaveformMasters[1][3][tStrb]\              => obAppWaveformMasters(1)(3).tStrb,
         \obAppWaveformMasters[1][3][tKeep]\              => obAppWaveformMasters(1)(3).tKeep,
         \obAppWaveformMasters[1][3][tLast]\              => obAppWaveformMasters(1)(3).tLast,
         \obAppWaveformMasters[1][3][tDest]\              => obAppWaveformMasters(1)(3).tDest,
         \obAppWaveformMasters[1][3][tId]\                => obAppWaveformMasters(1)(3).tId,
         \obAppWaveformMasters[1][3][tUser]\              => obAppWaveformMasters(1)(3).tUser,
         \obAppWaveformMasters[1][2][tValid]\             => obAppWaveformMasters(1)(2).tValid,
         \obAppWaveformMasters[1][2][tData]\              => obAppWaveformMasters(1)(2).tData,
         \obAppWaveformMasters[1][2][tStrb]\              => obAppWaveformMasters(1)(2).tStrb,
         \obAppWaveformMasters[1][2][tKeep]\              => obAppWaveformMasters(1)(2).tKeep,
         \obAppWaveformMasters[1][2][tLast]\              => obAppWaveformMasters(1)(2).tLast,
         \obAppWaveformMasters[1][2][tDest]\              => obAppWaveformMasters(1)(2).tDest,
         \obAppWaveformMasters[1][2][tId]\                => obAppWaveformMasters(1)(2).tId,
         \obAppWaveformMasters[1][2][tUser]\              => obAppWaveformMasters(1)(2).tUser,
         \obAppWaveformMasters[1][1][tValid]\             => obAppWaveformMasters(1)(1).tValid,
         \obAppWaveformMasters[1][1][tData]\              => obAppWaveformMasters(1)(1).tData,
         \obAppWaveformMasters[1][1][tStrb]\              => obAppWaveformMasters(1)(1).tStrb,
         \obAppWaveformMasters[1][1][tKeep]\              => obAppWaveformMasters(1)(1).tKeep,
         \obAppWaveformMasters[1][1][tLast]\              => obAppWaveformMasters(1)(1).tLast,
         \obAppWaveformMasters[1][1][tDest]\              => obAppWaveformMasters(1)(1).tDest,
         \obAppWaveformMasters[1][1][tId]\                => obAppWaveformMasters(1)(1).tId,
         \obAppWaveformMasters[1][1][tUser]\              => obAppWaveformMasters(1)(1).tUser,
         \obAppWaveformMasters[1][0][tValid]\             => obAppWaveformMasters(1)(0).tValid,
         \obAppWaveformMasters[1][0][tData]\              => obAppWaveformMasters(1)(0).tData,
         \obAppWaveformMasters[1][0][tStrb]\              => obAppWaveformMasters(1)(0).tStrb,
         \obAppWaveformMasters[1][0][tKeep]\              => obAppWaveformMasters(1)(0).tKeep,
         \obAppWaveformMasters[1][0][tLast]\              => obAppWaveformMasters(1)(0).tLast,
         \obAppWaveformMasters[1][0][tDest]\              => obAppWaveformMasters(1)(0).tDest,
         \obAppWaveformMasters[1][0][tId]\                => obAppWaveformMasters(1)(0).tId,
         \obAppWaveformMasters[1][0][tUser]\              => obAppWaveformMasters(1)(0).tUser,
         \obAppWaveformMasters[0][3][tValid]\             => obAppWaveformMasters(0)(3).tValid,
         \obAppWaveformMasters[0][3][tData]\              => obAppWaveformMasters(0)(3).tData,
         \obAppWaveformMasters[0][3][tStrb]\              => obAppWaveformMasters(0)(3).tStrb,
         \obAppWaveformMasters[0][3][tKeep]\              => obAppWaveformMasters(0)(3).tKeep,
         \obAppWaveformMasters[0][3][tLast]\              => obAppWaveformMasters(0)(3).tLast,
         \obAppWaveformMasters[0][3][tDest]\              => obAppWaveformMasters(0)(3).tDest,
         \obAppWaveformMasters[0][3][tId]\                => obAppWaveformMasters(0)(3).tId,
         \obAppWaveformMasters[0][3][tUser]\              => obAppWaveformMasters(0)(3).tUser,
         \obAppWaveformMasters[0][2][tValid]\             => obAppWaveformMasters(0)(2).tValid,
         \obAppWaveformMasters[0][2][tData]\              => obAppWaveformMasters(0)(2).tData,
         \obAppWaveformMasters[0][2][tStrb]\              => obAppWaveformMasters(0)(2).tStrb,
         \obAppWaveformMasters[0][2][tKeep]\              => obAppWaveformMasters(0)(2).tKeep,
         \obAppWaveformMasters[0][2][tLast]\              => obAppWaveformMasters(0)(2).tLast,
         \obAppWaveformMasters[0][2][tDest]\              => obAppWaveformMasters(0)(2).tDest,
         \obAppWaveformMasters[0][2][tId]\                => obAppWaveformMasters(0)(2).tId,
         \obAppWaveformMasters[0][2][tUser]\              => obAppWaveformMasters(0)(2).tUser,
         \obAppWaveformMasters[0][1][tValid]\             => obAppWaveformMasters(0)(1).tValid,
         \obAppWaveformMasters[0][1][tData]\              => obAppWaveformMasters(0)(1).tData,
         \obAppWaveformMasters[0][1][tStrb]\              => obAppWaveformMasters(0)(1).tStrb,
         \obAppWaveformMasters[0][1][tKeep]\              => obAppWaveformMasters(0)(1).tKeep,
         \obAppWaveformMasters[0][1][tLast]\              => obAppWaveformMasters(0)(1).tLast,
         \obAppWaveformMasters[0][1][tDest]\              => obAppWaveformMasters(0)(1).tDest,
         \obAppWaveformMasters[0][1][tId]\                => obAppWaveformMasters(0)(1).tId,
         \obAppWaveformMasters[0][1][tUser]\              => obAppWaveformMasters(0)(1).tUser,
         \obAppWaveformMasters[0][0][tValid]\             => obAppWaveformMasters(0)(0).tValid,
         \obAppWaveformMasters[0][0][tData]\              => obAppWaveformMasters(0)(0).tData,
         \obAppWaveformMasters[0][0][tStrb]\              => obAppWaveformMasters(0)(0).tStrb,
         \obAppWaveformMasters[0][0][tKeep]\              => obAppWaveformMasters(0)(0).tKeep,
         \obAppWaveformMasters[0][0][tLast]\              => obAppWaveformMasters(0)(0).tLast,
         \obAppWaveformMasters[0][0][tDest]\              => obAppWaveformMasters(0)(0).tDest,
         \obAppWaveformMasters[0][0][tId]\                => obAppWaveformMasters(0)(0).tId,
         \obAppWaveformMasters[0][0][tUser]\              => obAppWaveformMasters(0)(0).tUser,
         \obAppWaveformSlaves[1][3][slave][tReady]\       => obAppWaveformSlaves(1)(3).slave.tReady,
         \obAppWaveformSlaves[1][3][ctrl][pause]\         => obAppWaveformSlaves(1)(3).ctrl.pause,
         \obAppWaveformSlaves[1][3][ctrl][overflow]\      => obAppWaveformSlaves(1)(3).ctrl.overflow,
         \obAppWaveformSlaves[1][3][ctrl][idle]\          => obAppWaveformSlaves(1)(3).ctrl.idle,
         \obAppWaveformSlaves[1][2][slave][tReady]\       => obAppWaveformSlaves(1)(2).slave.tReady,
         \obAppWaveformSlaves[1][2][ctrl][pause]\         => obAppWaveformSlaves(1)(2).ctrl.pause,
         \obAppWaveformSlaves[1][2][ctrl][overflow]\      => obAppWaveformSlaves(1)(2).ctrl.overflow,
         \obAppWaveformSlaves[1][2][ctrl][idle]\          => obAppWaveformSlaves(1)(2).ctrl.idle,
         \obAppWaveformSlaves[1][1][slave][tReady]\       => obAppWaveformSlaves(1)(1).slave.tReady,
         \obAppWaveformSlaves[1][1][ctrl][pause]\         => obAppWaveformSlaves(1)(1).ctrl.pause,
         \obAppWaveformSlaves[1][1][ctrl][overflow]\      => obAppWaveformSlaves(1)(1).ctrl.overflow,
         \obAppWaveformSlaves[1][1][ctrl][idle]\          => obAppWaveformSlaves(1)(1).ctrl.idle,
         \obAppWaveformSlaves[1][0][slave][tReady]\       => obAppWaveformSlaves(1)(0).slave.tReady,
         \obAppWaveformSlaves[1][0][ctrl][pause]\         => obAppWaveformSlaves(1)(0).ctrl.pause,
         \obAppWaveformSlaves[1][0][ctrl][overflow]\      => obAppWaveformSlaves(1)(0).ctrl.overflow,
         \obAppWaveformSlaves[1][0][ctrl][idle]\          => obAppWaveformSlaves(1)(0).ctrl.idle,
         \obAppWaveformSlaves[0][3][slave][tReady]\       => obAppWaveformSlaves(0)(3).slave.tReady,
         \obAppWaveformSlaves[0][3][ctrl][pause]\         => obAppWaveformSlaves(0)(3).ctrl.pause,
         \obAppWaveformSlaves[0][3][ctrl][overflow]\      => obAppWaveformSlaves(0)(3).ctrl.overflow,
         \obAppWaveformSlaves[0][3][ctrl][idle]\          => obAppWaveformSlaves(0)(3).ctrl.idle,
         \obAppWaveformSlaves[0][2][slave][tReady]\       => obAppWaveformSlaves(0)(2).slave.tReady,
         \obAppWaveformSlaves[0][2][ctrl][pause]\         => obAppWaveformSlaves(0)(2).ctrl.pause,
         \obAppWaveformSlaves[0][2][ctrl][overflow]\      => obAppWaveformSlaves(0)(2).ctrl.overflow,
         \obAppWaveformSlaves[0][2][ctrl][idle]\          => obAppWaveformSlaves(0)(2).ctrl.idle,
         \obAppWaveformSlaves[0][1][slave][tReady]\       => obAppWaveformSlaves(0)(1).slave.tReady,
         \obAppWaveformSlaves[0][1][ctrl][pause]\         => obAppWaveformSlaves(0)(1).ctrl.pause,
         \obAppWaveformSlaves[0][1][ctrl][overflow]\      => obAppWaveformSlaves(0)(1).ctrl.overflow,
         \obAppWaveformSlaves[0][1][ctrl][idle]\          => obAppWaveformSlaves(0)(1).ctrl.idle,
         \obAppWaveformSlaves[0][0][slave][tReady]\       => obAppWaveformSlaves(0)(0).slave.tReady,
         \obAppWaveformSlaves[0][0][ctrl][pause]\         => obAppWaveformSlaves(0)(0).ctrl.pause,
         \obAppWaveformSlaves[0][0][ctrl][overflow]\      => obAppWaveformSlaves(0)(0).ctrl.overflow,
         \obAppWaveformSlaves[0][0][ctrl][idle]\          => obAppWaveformSlaves(0)(0).ctrl.idle,
         \ibAppWaveformMasters[1][3][tValid]\             => ibAppWaveformMasters(1)(3).tValid,
         \ibAppWaveformMasters[1][3][tData]\              => ibAppWaveformMasters(1)(3).tData,
         \ibAppWaveformMasters[1][3][tStrb]\              => ibAppWaveformMasters(1)(3).tStrb,
         \ibAppWaveformMasters[1][3][tKeep]\              => ibAppWaveformMasters(1)(3).tKeep,
         \ibAppWaveformMasters[1][3][tLast]\              => ibAppWaveformMasters(1)(3).tLast,
         \ibAppWaveformMasters[1][3][tDest]\              => ibAppWaveformMasters(1)(3).tDest,
         \ibAppWaveformMasters[1][3][tId]\                => ibAppWaveformMasters(1)(3).tId,
         \ibAppWaveformMasters[1][3][tUser]\              => ibAppWaveformMasters(1)(3).tUser,
         \ibAppWaveformMasters[1][2][tValid]\             => ibAppWaveformMasters(1)(2).tValid,
         \ibAppWaveformMasters[1][2][tData]\              => ibAppWaveformMasters(1)(2).tData,
         \ibAppWaveformMasters[1][2][tStrb]\              => ibAppWaveformMasters(1)(2).tStrb,
         \ibAppWaveformMasters[1][2][tKeep]\              => ibAppWaveformMasters(1)(2).tKeep,
         \ibAppWaveformMasters[1][2][tLast]\              => ibAppWaveformMasters(1)(2).tLast,
         \ibAppWaveformMasters[1][2][tDest]\              => ibAppWaveformMasters(1)(2).tDest,
         \ibAppWaveformMasters[1][2][tId]\                => ibAppWaveformMasters(1)(2).tId,
         \ibAppWaveformMasters[1][2][tUser]\              => ibAppWaveformMasters(1)(2).tUser,
         \ibAppWaveformMasters[1][1][tValid]\             => ibAppWaveformMasters(1)(1).tValid,
         \ibAppWaveformMasters[1][1][tData]\              => ibAppWaveformMasters(1)(1).tData,
         \ibAppWaveformMasters[1][1][tStrb]\              => ibAppWaveformMasters(1)(1).tStrb,
         \ibAppWaveformMasters[1][1][tKeep]\              => ibAppWaveformMasters(1)(1).tKeep,
         \ibAppWaveformMasters[1][1][tLast]\              => ibAppWaveformMasters(1)(1).tLast,
         \ibAppWaveformMasters[1][1][tDest]\              => ibAppWaveformMasters(1)(1).tDest,
         \ibAppWaveformMasters[1][1][tId]\                => ibAppWaveformMasters(1)(1).tId,
         \ibAppWaveformMasters[1][1][tUser]\              => ibAppWaveformMasters(1)(1).tUser,
         \ibAppWaveformMasters[1][0][tValid]\             => ibAppWaveformMasters(1)(0).tValid,
         \ibAppWaveformMasters[1][0][tData]\              => ibAppWaveformMasters(1)(0).tData,
         \ibAppWaveformMasters[1][0][tStrb]\              => ibAppWaveformMasters(1)(0).tStrb,
         \ibAppWaveformMasters[1][0][tKeep]\              => ibAppWaveformMasters(1)(0).tKeep,
         \ibAppWaveformMasters[1][0][tLast]\              => ibAppWaveformMasters(1)(0).tLast,
         \ibAppWaveformMasters[1][0][tDest]\              => ibAppWaveformMasters(1)(0).tDest,
         \ibAppWaveformMasters[1][0][tId]\                => ibAppWaveformMasters(1)(0).tId,
         \ibAppWaveformMasters[1][0][tUser]\              => ibAppWaveformMasters(1)(0).tUser,
         \ibAppWaveformMasters[0][3][tValid]\             => ibAppWaveformMasters(0)(3).tValid,
         \ibAppWaveformMasters[0][3][tData]\              => ibAppWaveformMasters(0)(3).tData,
         \ibAppWaveformMasters[0][3][tStrb]\              => ibAppWaveformMasters(0)(3).tStrb,
         \ibAppWaveformMasters[0][3][tKeep]\              => ibAppWaveformMasters(0)(3).tKeep,
         \ibAppWaveformMasters[0][3][tLast]\              => ibAppWaveformMasters(0)(3).tLast,
         \ibAppWaveformMasters[0][3][tDest]\              => ibAppWaveformMasters(0)(3).tDest,
         \ibAppWaveformMasters[0][3][tId]\                => ibAppWaveformMasters(0)(3).tId,
         \ibAppWaveformMasters[0][3][tUser]\              => ibAppWaveformMasters(0)(3).tUser,
         \ibAppWaveformMasters[0][2][tValid]\             => ibAppWaveformMasters(0)(2).tValid,
         \ibAppWaveformMasters[0][2][tData]\              => ibAppWaveformMasters(0)(2).tData,
         \ibAppWaveformMasters[0][2][tStrb]\              => ibAppWaveformMasters(0)(2).tStrb,
         \ibAppWaveformMasters[0][2][tKeep]\              => ibAppWaveformMasters(0)(2).tKeep,
         \ibAppWaveformMasters[0][2][tLast]\              => ibAppWaveformMasters(0)(2).tLast,
         \ibAppWaveformMasters[0][2][tDest]\              => ibAppWaveformMasters(0)(2).tDest,
         \ibAppWaveformMasters[0][2][tId]\                => ibAppWaveformMasters(0)(2).tId,
         \ibAppWaveformMasters[0][2][tUser]\              => ibAppWaveformMasters(0)(2).tUser,
         \ibAppWaveformMasters[0][1][tValid]\             => ibAppWaveformMasters(0)(1).tValid,
         \ibAppWaveformMasters[0][1][tData]\              => ibAppWaveformMasters(0)(1).tData,
         \ibAppWaveformMasters[0][1][tStrb]\              => ibAppWaveformMasters(0)(1).tStrb,
         \ibAppWaveformMasters[0][1][tKeep]\              => ibAppWaveformMasters(0)(1).tKeep,
         \ibAppWaveformMasters[0][1][tLast]\              => ibAppWaveformMasters(0)(1).tLast,
         \ibAppWaveformMasters[0][1][tDest]\              => ibAppWaveformMasters(0)(1).tDest,
         \ibAppWaveformMasters[0][1][tId]\                => ibAppWaveformMasters(0)(1).tId,
         \ibAppWaveformMasters[0][1][tUser]\              => ibAppWaveformMasters(0)(1).tUser,
         \ibAppWaveformMasters[0][0][tValid]\             => ibAppWaveformMasters(0)(0).tValid,
         \ibAppWaveformMasters[0][0][tData]\              => ibAppWaveformMasters(0)(0).tData,
         \ibAppWaveformMasters[0][0][tStrb]\              => ibAppWaveformMasters(0)(0).tStrb,
         \ibAppWaveformMasters[0][0][tKeep]\              => ibAppWaveformMasters(0)(0).tKeep,
         \ibAppWaveformMasters[0][0][tLast]\              => ibAppWaveformMasters(0)(0).tLast,
         \ibAppWaveformMasters[0][0][tDest]\              => ibAppWaveformMasters(0)(0).tDest,
         \ibAppWaveformMasters[0][0][tId]\                => ibAppWaveformMasters(0)(0).tId,
         \ibAppWaveformMasters[0][0][tUser]\              => ibAppWaveformMasters(0)(0).tUser,
         \ibAppWaveformSlaves[1][3][slave][tReady]\       => ibAppWaveformSlaves(1)(3).slave.tReady,
         \ibAppWaveformSlaves[1][3][ctrl][pause]\         => ibAppWaveformSlaves(1)(3).ctrl.pause,
         \ibAppWaveformSlaves[1][3][ctrl][overflow]\      => ibAppWaveformSlaves(1)(3).ctrl.overflow,
         \ibAppWaveformSlaves[1][3][ctrl][idle]\          => ibAppWaveformSlaves(1)(3).ctrl.idle,
         \ibAppWaveformSlaves[1][2][slave][tReady]\       => ibAppWaveformSlaves(1)(2).slave.tReady,
         \ibAppWaveformSlaves[1][2][ctrl][pause]\         => ibAppWaveformSlaves(1)(2).ctrl.pause,
         \ibAppWaveformSlaves[1][2][ctrl][overflow]\      => ibAppWaveformSlaves(1)(2).ctrl.overflow,
         \ibAppWaveformSlaves[1][2][ctrl][idle]\          => ibAppWaveformSlaves(1)(2).ctrl.idle,
         \ibAppWaveformSlaves[1][1][slave][tReady]\       => ibAppWaveformSlaves(1)(1).slave.tReady,
         \ibAppWaveformSlaves[1][1][ctrl][pause]\         => ibAppWaveformSlaves(1)(1).ctrl.pause,
         \ibAppWaveformSlaves[1][1][ctrl][overflow]\      => ibAppWaveformSlaves(1)(1).ctrl.overflow,
         \ibAppWaveformSlaves[1][1][ctrl][idle]\          => ibAppWaveformSlaves(1)(1).ctrl.idle,
         \ibAppWaveformSlaves[1][0][slave][tReady]\       => ibAppWaveformSlaves(1)(0).slave.tReady,
         \ibAppWaveformSlaves[1][0][ctrl][pause]\         => ibAppWaveformSlaves(1)(0).ctrl.pause,
         \ibAppWaveformSlaves[1][0][ctrl][overflow]\      => ibAppWaveformSlaves(1)(0).ctrl.overflow,
         \ibAppWaveformSlaves[1][0][ctrl][idle]\          => ibAppWaveformSlaves(1)(0).ctrl.idle,
         \ibAppWaveformSlaves[0][3][slave][tReady]\       => ibAppWaveformSlaves(0)(3).slave.tReady,
         \ibAppWaveformSlaves[0][3][ctrl][pause]\         => ibAppWaveformSlaves(0)(3).ctrl.pause,
         \ibAppWaveformSlaves[0][3][ctrl][overflow]\      => ibAppWaveformSlaves(0)(3).ctrl.overflow,
         \ibAppWaveformSlaves[0][3][ctrl][idle]\          => ibAppWaveformSlaves(0)(3).ctrl.idle,
         \ibAppWaveformSlaves[0][2][slave][tReady]\       => ibAppWaveformSlaves(0)(2).slave.tReady,
         \ibAppWaveformSlaves[0][2][ctrl][pause]\         => ibAppWaveformSlaves(0)(2).ctrl.pause,
         \ibAppWaveformSlaves[0][2][ctrl][overflow]\      => ibAppWaveformSlaves(0)(2).ctrl.overflow,
         \ibAppWaveformSlaves[0][2][ctrl][idle]\          => ibAppWaveformSlaves(0)(2).ctrl.idle,
         \ibAppWaveformSlaves[0][1][slave][tReady]\       => ibAppWaveformSlaves(0)(1).slave.tReady,
         \ibAppWaveformSlaves[0][1][ctrl][pause]\         => ibAppWaveformSlaves(0)(1).ctrl.pause,
         \ibAppWaveformSlaves[0][1][ctrl][overflow]\      => ibAppWaveformSlaves(0)(1).ctrl.overflow,
         \ibAppWaveformSlaves[0][1][ctrl][idle]\          => ibAppWaveformSlaves(0)(1).ctrl.idle,
         \ibAppWaveformSlaves[0][0][slave][tReady]\       => ibAppWaveformSlaves(0)(0).slave.tReady,
         \ibAppWaveformSlaves[0][0][ctrl][pause]\         => ibAppWaveformSlaves(0)(0).ctrl.pause,
         \ibAppWaveformSlaves[0][0][ctrl][overflow]\      => ibAppWaveformSlaves(0)(0).ctrl.overflow,
         \ibAppWaveformSlaves[0][0][ctrl][idle]\          => ibAppWaveformSlaves(0)(0).ctrl.idle,
         \obBpMsgClientMaster[tValid]\                    => obBpMsgClientMaster.tValid,
         \obBpMsgClientMaster[tData]\                     => obBpMsgClientMaster.tData,
         \obBpMsgClientMaster[tStrb]\                     => obBpMsgClientMaster.tStrb,
         \obBpMsgClientMaster[tKeep]\                     => obBpMsgClientMaster.tKeep,
         \obBpMsgClientMaster[tLast]\                     => obBpMsgClientMaster.tLast,
         \obBpMsgClientMaster[tDest]\                     => obBpMsgClientMaster.tDest,
         \obBpMsgClientMaster[tId]\                       => obBpMsgClientMaster.tId,
         \obBpMsgClientMaster[tUser]\                     => obBpMsgClientMaster.tUser,
         \obBpMsgClientSlave[tReady]\                     => obBpMsgClientSlave.tReady,
         \ibBpMsgClientMaster[tValid]\                    => ibBpMsgClientMaster.tValid,
         \ibBpMsgClientMaster[tData]\                     => ibBpMsgClientMaster.tData,
         \ibBpMsgClientMaster[tStrb]\                     => ibBpMsgClientMaster.tStrb,
         \ibBpMsgClientMaster[tKeep]\                     => ibBpMsgClientMaster.tKeep,
         \ibBpMsgClientMaster[tLast]\                     => ibBpMsgClientMaster.tLast,
         \ibBpMsgClientMaster[tDest]\                     => ibBpMsgClientMaster.tDest,
         \ibBpMsgClientMaster[tId]\                       => ibBpMsgClientMaster.tId,
         \ibBpMsgClientMaster[tUser]\                     => ibBpMsgClientMaster.tUser,
         \ibBpMsgClientSlave[tReady]\                     => ibBpMsgClientSlave.tReady,
         \obBpMsgServerMaster[tValid]\                    => obBpMsgServerMaster.tValid,
         \obBpMsgServerMaster[tData]\                     => obBpMsgServerMaster.tData,
         \obBpMsgServerMaster[tStrb]\                     => obBpMsgServerMaster.tStrb,
         \obBpMsgServerMaster[tKeep]\                     => obBpMsgServerMaster.tKeep,
         \obBpMsgServerMaster[tLast]\                     => obBpMsgServerMaster.tLast,
         \obBpMsgServerMaster[tDest]\                     => obBpMsgServerMaster.tDest,
         \obBpMsgServerMaster[tId]\                       => obBpMsgServerMaster.tId,
         \obBpMsgServerMaster[tUser]\                     => obBpMsgServerMaster.tUser,
         \obBpMsgServerSlave[tReady]\                     => obBpMsgServerSlave.tReady,
         \ibBpMsgServerMaster[tValid]\                    => ibBpMsgServerMaster.tValid,
         \ibBpMsgServerMaster[tData]\                     => ibBpMsgServerMaster.tData,
         \ibBpMsgServerMaster[tStrb]\                     => ibBpMsgServerMaster.tStrb,
         \ibBpMsgServerMaster[tKeep]\                     => ibBpMsgServerMaster.tKeep,
         \ibBpMsgServerMaster[tLast]\                     => ibBpMsgServerMaster.tLast,
         \ibBpMsgServerMaster[tDest]\                     => ibBpMsgServerMaster.tDest,
         \ibBpMsgServerMaster[tId]\                       => ibBpMsgServerMaster.tId,
         \ibBpMsgServerMaster[tUser]\                     => ibBpMsgServerMaster.tUser,
         \ibBpMsgServerSlave[tReady]\                     => ibBpMsgServerSlave.tReady,
         \obAppDebugMaster[tValid]\                       => obAppDebugMaster.tValid,
         \obAppDebugMaster[tData]\                        => obAppDebugMaster.tData,
         \obAppDebugMaster[tStrb]\                        => obAppDebugMaster.tStrb,
         \obAppDebugMaster[tKeep]\                        => obAppDebugMaster.tKeep,
         \obAppDebugMaster[tLast]\                        => obAppDebugMaster.tLast,
         \obAppDebugMaster[tDest]\                        => obAppDebugMaster.tDest,
         \obAppDebugMaster[tId]\                          => obAppDebugMaster.tId,
         \obAppDebugMaster[tUser]\                        => obAppDebugMaster.tUser,
         \obAppDebugSlave[tReady]\                        => obAppDebugSlave.tReady,
         \ibAppDebugMaster[tValid]\                       => ibAppDebugMaster.tValid,
         \ibAppDebugMaster[tData]\                        => ibAppDebugMaster.tData,
         \ibAppDebugMaster[tStrb]\                        => ibAppDebugMaster.tStrb,
         \ibAppDebugMaster[tKeep]\                        => ibAppDebugMaster.tKeep,
         \ibAppDebugMaster[tLast]\                        => ibAppDebugMaster.tLast,
         \ibAppDebugMaster[tDest]\                        => ibAppDebugMaster.tDest,
         \ibAppDebugMaster[tId]\                          => ibAppDebugMaster.tId,
         \ibAppDebugMaster[tUser]\                        => ibAppDebugMaster.tUser,
         \ibAppDebugSlave[tReady]\                        => ibAppDebugSlave.tReady,
         recTimingClk                                     => recTimingClk,
         recTimingRst                                     => recTimingRst,
         ref156MHzClk                                     => ref156MHzClk,
         ref156MHzRst                                     => ref156MHzRst,
         gthFabClk                                        => gthFabClk,
         \axilReadMasters[1][araddr]\                     => axilReadMasters(1).araddr,
         \axilReadMasters[1][arprot]\                     => axilReadMasters(1).arprot,
         \axilReadMasters[1][arvalid]\                    => axilReadMasters(1).arvalid,
         \axilReadMasters[1][rready]\                     => axilReadMasters(1).rready,
         \axilReadMasters[0][araddr]\                     => axilReadMasters(0).araddr,
         \axilReadMasters[0][arprot]\                     => axilReadMasters(0).arprot,
         \axilReadMasters[0][arvalid]\                    => axilReadMasters(0).arvalid,
         \axilReadMasters[0][rready]\                     => axilReadMasters(0).rready,
         \axilReadSlaves[1][arready]\                     => axilReadSlaves(1).arready,
         \axilReadSlaves[1][rdata]\                       => axilReadSlaves(1).rdata,
         \axilReadSlaves[1][rresp]\                       => axilReadSlaves(1).rresp,
         \axilReadSlaves[1][rvalid]\                      => axilReadSlaves(1).rvalid,
         \axilReadSlaves[0][arready]\                     => axilReadSlaves(0).arready,
         \axilReadSlaves[0][rdata]\                       => axilReadSlaves(0).rdata,
         \axilReadSlaves[0][rresp]\                       => axilReadSlaves(0).rresp,
         \axilReadSlaves[0][rvalid]\                      => axilReadSlaves(0).rvalid,
         \axilWriteMasters[1][awaddr]\                    => axilWriteMasters(1).awaddr,
         \axilWriteMasters[1][awprot]\                    => axilWriteMasters(1).awprot,
         \axilWriteMasters[1][awvalid]\                   => axilWriteMasters(1).awvalid,
         \axilWriteMasters[1][wdata]\                     => axilWriteMasters(1).wdata,
         \axilWriteMasters[1][wstrb]\                     => axilWriteMasters(1).wstrb,
         \axilWriteMasters[1][wvalid]\                    => axilWriteMasters(1).wvalid,
         \axilWriteMasters[1][bready]\                    => axilWriteMasters(1).bready,
         \axilWriteMasters[0][awaddr]\                    => axilWriteMasters(0).awaddr,
         \axilWriteMasters[0][awprot]\                    => axilWriteMasters(0).awprot,
         \axilWriteMasters[0][awvalid]\                   => axilWriteMasters(0).awvalid,
         \axilWriteMasters[0][wdata]\                     => axilWriteMasters(0).wdata,
         \axilWriteMasters[0][wstrb]\                     => axilWriteMasters(0).wstrb,
         \axilWriteMasters[0][wvalid]\                    => axilWriteMasters(0).wvalid,
         \axilWriteMasters[0][bready]\                    => axilWriteMasters(0).bready,
         \axilWriteSlaves[1][awready]\                    => axilWriteSlaves(1).awready,
         \axilWriteSlaves[1][wready]\                     => axilWriteSlaves(1).wready,
         \axilWriteSlaves[1][bresp]\                      => axilWriteSlaves(1).bresp,
         \axilWriteSlaves[1][bvalid]\                     => axilWriteSlaves(1).bvalid,
         \axilWriteSlaves[0][awready]\                    => axilWriteSlaves(0).awready,
         \axilWriteSlaves[0][wready]\                     => axilWriteSlaves(0).wready,
         \axilWriteSlaves[0][bresp]\                      => axilWriteSlaves(0).bresp,
         \axilWriteSlaves[0][bvalid]\                     => axilWriteSlaves(0).bvalid,
         \ethReadMaster[araddr]\                          => ethReadMaster.araddr,
         \ethReadMaster[arprot]\                          => ethReadMaster.arprot,
         \ethReadMaster[arvalid]\                         => ethReadMaster.arvalid,
         \ethReadMaster[rready]\                          => ethReadMaster.rready,
         \ethReadSlave[arready]\                          => ethReadSlave.arready,
         \ethReadSlave[rdata]\                            => ethReadSlave.rdata,
         \ethReadSlave[rresp]\                            => ethReadSlave.rresp,
         \ethReadSlave[rvalid]\                           => ethReadSlave.rvalid,
         \ethWriteMaster[awaddr]\                         => ethWriteMaster.awaddr,
         \ethWriteMaster[awprot]\                         => ethWriteMaster.awprot,
         \ethWriteMaster[awvalid]\                        => ethWriteMaster.awvalid,
         \ethWriteMaster[wdata]\                          => ethWriteMaster.wdata,
         \ethWriteMaster[wstrb]\                          => ethWriteMaster.wstrb,
         \ethWriteMaster[wvalid]\                         => ethWriteMaster.wvalid,
         \ethWriteMaster[bready]\                         => ethWriteMaster.bready,
         \ethWriteSlave[awready]\                         => ethWriteSlave.awready,
         \ethWriteSlave[wready]\                          => ethWriteSlave.wready,
         \ethWriteSlave[bresp]\                           => ethWriteSlave.bresp,
         \ethWriteSlave[bvalid]\                          => ethWriteSlave.bvalid,
         localMac                                         => localMac,
         localIp                                          => localIp,
         ethLinkUp                                        => ethLinkUp,
         \timingReadMaster[araddr]\                       => timingReadMaster.araddr,
         \timingReadMaster[arprot]\                       => timingReadMaster.arprot,
         \timingReadMaster[arvalid]\                      => timingReadMaster.arvalid,
         \timingReadMaster[rready]\                       => timingReadMaster.rready,
         \timingReadSlave[arready]\                       => timingReadSlave.arready,
         \timingReadSlave[rdata]\                         => timingReadSlave.rdata,
         \timingReadSlave[rresp]\                         => timingReadSlave.rresp,
         \timingReadSlave[rvalid]\                        => timingReadSlave.rvalid,
         \timingWriteMaster[awaddr]\                      => timingWriteMaster.awaddr,
         \timingWriteMaster[awprot]\                      => timingWriteMaster.awprot,
         \timingWriteMaster[awvalid]\                     => timingWriteMaster.awvalid,
         \timingWriteMaster[wdata]\                       => timingWriteMaster.wdata,
         \timingWriteMaster[wstrb]\                       => timingWriteMaster.wstrb,
         \timingWriteMaster[wvalid]\                      => timingWriteMaster.wvalid,
         \timingWriteMaster[bready]\                      => timingWriteMaster.bready,
         \timingWriteSlave[awready]\                      => timingWriteSlave.awready,
         \timingWriteSlave[wready]\                       => timingWriteSlave.wready,
         \timingWriteSlave[bresp]\                        => timingWriteSlave.bresp,
         \timingWriteSlave[bvalid]\                       => timingWriteSlave.bvalid,
         \bsaReadMaster[araddr]\                          => bsaReadMaster.araddr,
         \bsaReadMaster[arprot]\                          => bsaReadMaster.arprot,
         \bsaReadMaster[arvalid]\                         => bsaReadMaster.arvalid,
         \bsaReadMaster[rready]\                          => bsaReadMaster.rready,
         \bsaReadSlave[arready]\                          => bsaReadSlave.arready,
         \bsaReadSlave[rdata]\                            => bsaReadSlave.rdata,
         \bsaReadSlave[rresp]\                            => bsaReadSlave.rresp,
         \bsaReadSlave[rvalid]\                           => bsaReadSlave.rvalid,
         \bsaWriteMaster[awaddr]\                         => bsaWriteMaster.awaddr,
         \bsaWriteMaster[awprot]\                         => bsaWriteMaster.awprot,
         \bsaWriteMaster[awvalid]\                        => bsaWriteMaster.awvalid,
         \bsaWriteMaster[wdata]\                          => bsaWriteMaster.wdata,
         \bsaWriteMaster[wstrb]\                          => bsaWriteMaster.wstrb,
         \bsaWriteMaster[wvalid]\                         => bsaWriteMaster.wvalid,
         \bsaWriteMaster[bready]\                         => bsaWriteMaster.bready,
         \bsaWriteSlave[awready]\                         => bsaWriteSlave.awready,
         \bsaWriteSlave[wready]\                          => bsaWriteSlave.wready,
         \bsaWriteSlave[bresp]\                           => bsaWriteSlave.bresp,
         \bsaWriteSlave[bvalid]\                          => bsaWriteSlave.bvalid,
         \ddrReadMaster[araddr]\                          => ddrReadMaster.araddr,
         \ddrReadMaster[arprot]\                          => ddrReadMaster.arprot,
         \ddrReadMaster[arvalid]\                         => ddrReadMaster.arvalid,
         \ddrReadMaster[rready]\                          => ddrReadMaster.rready,
         \ddrReadSlave[arready]\                          => ddrReadSlave.arready,
         \ddrReadSlave[rdata]\                            => ddrReadSlave.rdata,
         \ddrReadSlave[rresp]\                            => ddrReadSlave.rresp,
         \ddrReadSlave[rvalid]\                           => ddrReadSlave.rvalid,
         \ddrWriteMaster[awaddr]\                         => ddrWriteMaster.awaddr,
         \ddrWriteMaster[awprot]\                         => ddrWriteMaster.awprot,
         \ddrWriteMaster[awvalid]\                        => ddrWriteMaster.awvalid,
         \ddrWriteMaster[wdata]\                          => ddrWriteMaster.wdata,
         \ddrWriteMaster[wstrb]\                          => ddrWriteMaster.wstrb,
         \ddrWriteMaster[wvalid]\                         => ddrWriteMaster.wvalid,
         \ddrWriteMaster[bready]\                         => ddrWriteMaster.bready,
         \ddrWriteSlave[awready]\                         => ddrWriteSlave.awready,
         \ddrWriteSlave[wready]\                          => ddrWriteSlave.wready,
         \ddrWriteSlave[bresp]\                           => ddrWriteSlave.bresp,
         \ddrWriteSlave[bvalid]\                          => ddrWriteSlave.bvalid,
         ddrMemReady                                      => ddrMemReady,
         ddrMemError                                      => ddrMemError,
         fabClkP                                          => fabClkP,
         fabClkN                                          => fabClkN,
         ethRxP                                           => ethRxP,
         ethRxN                                           => ethRxN,
         ethTxP                                           => ethTxP,
         ethTxN                                           => ethTxN,
         ethClkP                                          => ethClkP,
         ethClkN                                          => ethClkN,
         timingRxP                                        => timingRxP,
         timingRxN                                        => timingRxN,
         timingTxP                                        => timingTxP,
         timingTxN                                        => timingTxN,
         timingRefClkInP                                  => timingRefClkInP,
         timingRefClkInN                                  => timingRefClkInN,
         timingRecClkOutP                                 => timingRecClkOutP,
         timingRecClkOutN                                 => timingRecClkOutN,
         timingClkSel                                     => timingClkSel,
         enAuxPwrL                                        => enAuxPwrL,
         ddrClkP                                          => ddrClkP,
         ddrClkN                                          => ddrClkN,
         ddrDm                                            => ddrDm,
         ddrDqsP                                          => ddrDqsP,
         ddrDqsN                                          => ddrDqsN,
         ddrDq                                            => ddrDq,
         ddrA                                             => ddrA,
         ddrBa                                            => ddrBa,
         ddrCsL                                           => ddrCsL,
         ddrOdt                                           => ddrOdt,
         ddrCke                                           => ddrCke,
         ddrCkP                                           => ddrCkP,
         ddrCkN                                           => ddrCkN,
         ddrWeL                                           => ddrWeL,
         ddrRasL                                          => ddrRasL,
         ddrCasL                                          => ddrCasL,
         ddrRstL                                          => ddrRstL,
         ddrAlertL                                        => ddrAlertL,
         ddrPg                                            => ddrPg,
         ddrPwrEnL                                        => ddrPwrEnL);

end mapping;
