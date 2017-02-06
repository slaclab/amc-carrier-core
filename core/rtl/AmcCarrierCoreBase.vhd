-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierCoreBase.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-02-04
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
      TPD_G             : time    := 1 ns;
      SIM_SPEEDUP_G     : boolean := false;  -- false = Normal Operation, true = simulation
      APP_TYPE_G        : AppType;
      MPS_SLOT_G        : boolean := false);  -- false = Normal Operation, true = MPS message concentrator (Slot#2 only)
   port (
      -----------------------
      -- Core Ports to AppTop
      -----------------------
      -- AXI-Lite Interface (axilClk domain)
      -- Address Range = [0x80000000:0xFFFFFFFF]
      axilClk               : out sl;
      axilRst               : out sl;      
      axilReadMaster        : out AxiLiteReadMasterType;
      axilReadSlave         : in  AxiLiteReadSlaveType;
      axilWriteMaster       : out AxiLiteWriteMasterType;
      axilWriteSlave        : in  AxiLiteWriteSlaveType;      
      -- Timing Interface (timingClk domain) 
      timingClk            : in  sl;
      timingRst            : in  sl;
      timingBus            : out TimingBusType;
      timingPhy            : in  TimingPhyType                    := TIMING_PHY_INIT_C;  -- Input for timing generator only
      timingPhyClk         : out sl;
      timingPhyRst         : out sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : in  sl;
      diagnosticRst        : in  sl;
      diagnosticBus        : in  DiagnosticBusType;
      --  Waveform Capture interface (waveformClk domain)
      waveformClk          : out sl;
      waveformRst          : out sl;
      obAppWaveformMasters : in  WaveformMasterArrayType:= WAVEFORM_MASTER_ARRAY_INIT_C;
      obAppWaveformSlaves  : out WaveformSlaveArrayType;
      ibAppWaveformMasters : out WaveformMasterArrayType;
      ibAppWaveformSlaves  : in  WaveformSlaveArrayType := WAVEFORM_SLAVE_ARRAY_INIT_C;
      -- Backplane Messaging Interface  (axilClk domain)
      obBpMsgClientMaster  : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      obBpMsgClientSlave   : out AxiStreamSlaveType;
      ibBpMsgClientMaster  : out AxiStreamMasterType;
      ibBpMsgClientSlave   : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      obBpMsgServerMaster  : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      obBpMsgServerSlave   : out AxiStreamSlaveType;
      ibBpMsgServerMaster  : out AxiStreamMasterType;
      ibBpMsgServerSlave   : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      -- Application Debug Interface (axilClk domain)
      obAppDebugMaster     : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      obAppDebugSlave      : out AxiStreamSlaveType;
      ibAppDebugMaster     : out AxiStreamMasterType;
      ibAppDebugSlave      : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      -- MPS Concentrator Interface (axilClk domain)
      mpsObMasters         : out AxiStreamMasterArray(14 downto 0);
      mpsObSlaves          : in  AxiStreamSlaveArray(14 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      -- Reference Clocks and Resets
      recTimingClk         : out sl;
      recTimingRst         : out sl;
      gthFabClk            : out sl;
      -- Misc. Interface (axilClk domain)
      ipmiBsi              : out BsiBusType;
      ethPhyReady          : out sl;
      ----------------
      --  Top Level Interface to IO
      ----------------
      -- Common Fabricate Clock
      fabClkP          : in    sl;
      fabClkN          : in    sl;
      -- Backplane Ethernet Ports
      xauiRxP          : in    slv(3 downto 0);
      xauiRxN          : in    slv(3 downto 0);
      xauiTxP          : out   slv(3 downto 0);
      xauiTxN          : out   slv(3 downto 0);
      xauiClkP         : in    sl;
      xauiClkN         : in    sl;
      -- Backplane MPS Ports
      mpsClkIn         : in    sl;
      mpsClkOut        : out   sl;
      mpsBusRxP        : in    slv(14 downto 1);
      mpsBusRxN        : in    slv(14 downto 1);
      mpsTxP           : out   sl;
      mpsTxN           : out   sl;
      -- LCLS Timing Ports
      timingRxP        : in    sl;
      timingRxN        : in    sl;
      timingTxP        : out   sl;
      timingTxN        : out   sl;
      timingRefClkInP  : in    sl;
      timingRefClkInN  : in    sl;
      timingRecClkOutP : out   sl;
      timingRecClkOutN : out   sl;
      timingClkSel     : out   sl;
      timingClkScl     : inout sl;
      timingClkSda     : inout sl;
      -- Crossbar Ports
      xBarSin          : out   slv(1 downto 0);
      xBarSout         : out   slv(1 downto 0);
      xBarConfig       : out   sl;
      xBarLoad         : out   sl;
      -- Secondary AMC Auxiliary Power Enable Port
      enAuxPwrL        : out   sl;
      -- IPMC Ports
      ipmcScl          : inout sl;
      ipmcSda          : inout sl;
      -- Configuration PROM Ports
      calScl           : inout sl;
      calSda           : inout sl;
      -- DDR3L SO-DIMM Ports
      ddrClkP          : in    sl;
      ddrClkN          : in    sl;
      ddrDm            : out   slv(7 downto 0);
      ddrDqsP          : inout slv(7 downto 0);
      ddrDqsN          : inout slv(7 downto 0);
      ddrDq            : inout slv(63 downto 0);
      ddrA             : out   slv(15 downto 0);
      ddrBa            : out   slv(2 downto 0);
      ddrCsL           : out   slv(1 downto 0);
      ddrOdt           : out   slv(1 downto 0);
      ddrCke           : out   slv(1 downto 0);
      ddrCkP           : out   slv(1 downto 0);
      ddrCkN           : out   slv(1 downto 0);
      ddrWeL           : out   sl;
      ddrRasL          : out   sl;
      ddrCasL          : out   sl;
      ddrRstL          : out   sl;
      ddrAlertL        : in    sl;
      ddrPg            : in    sl;
      ddrPwrEnL        : out   sl;
      ddrScl           : inout sl;
      ddrSda           : inout sl;
      -- SYSMON Ports
      vPIn             : in    sl;
      vNIn             : in    sl);
end AmcCarrierCoreBase;

architecture mapping of AmcCarrierCoreBase is

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
   signal ethLinkUp       : sl;
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
   
   signal ref156MHzClk      : sl;
   signal ref156MHzRst      : sl;   
   signal bsiBus      : BsiBusType;
   
begin

   axilClk     <= ref156MHzClk;
   axilRst     <= ref156MHzRst;
   ipmiBsi     <= bsiBus;
   ethPhyReady <= ethLinkUp;

   ----------------------------------   
   -- Register Address Mapping Module
   ----------------------------------   
   U_SysReg : entity work.AmcCarrierSysReg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         APP_TYPE_G       => APP_TYPE_G,
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
         ethReadMaster    => ethReadMaster,
         ethReadSlave     => ethReadSlave,
         ethWriteMaster   => ethWriteMaster,
         ethWriteSlave    => ethWriteSlave,
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
         -- IPMI Status and Configurations
         bsiBus          => bsiBus,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk   => diagnosticClk,
         diagnosticRst   => diagnosticRst,
         diagnosticBus   => diagnosticBus,
         -- MPS Interface
         mpsObMasters    => mpsObMasters,
         mpsObSlaves     => mpsObSlaves,
         ----------------
         -- Core Ports --
         ----------------
         -- Backplane MPS Ports
         mpsClkIn     => mpsClkIn,
         mpsClkOut    => mpsClkOut,         
         mpsBusRxP       => mpsBusRxP,
         mpsBusRxN       => mpsBusRxN,
         mpsTxP          => mpsTxP,
         mpsTxN          => mpsTxN);

   ---------------------------
   -- AMC Carrier Core Release
   ---------------------------         
U_Core: entity work.AmcCarrierCore
  port map (
    timingClk => timingClk,
    timingRst => timingRst,
    \timingBus[strobe]\ => timingBus.strobe,
    \timingBus[valid]\ => timingBus.valid,
    \timingBus[message][version]\ => timingBus.message.version,
    \timingBus[message][pulseId]\ => timingBus.message.pulseId,
    \timingBus[message][timeStamp]\ => timingBus.message.timeStamp,
    \timingBus[message][fixedRates]\ => timingBus.message.fixedRates,
    \timingBus[message][acRates]\ => timingBus.message.acRates,
    \timingBus[message][acTimeSlot]\ => timingBus.message.acTimeSlot,
    \timingBus[message][acTimeSlotPhase]\ => timingBus.message.acTimeSlotPhase,
    \timingBus[message][resync]\ => timingBus.message.resync,
    \timingBus[message][beamRequest]\ => timingBus.message.beamRequest,
    \timingBus[message][beamEnergy][0]\ => timingBus.message.beamEnergy(0),
    \timingBus[message][beamEnergy][1]\ => timingBus.message.beamEnergy(1),
    \timingBus[message][beamEnergy][2]\ => timingBus.message.beamEnergy(2),
    \timingBus[message][beamEnergy][3]\ => timingBus.message.beamEnergy(3),
    \timingBus[message][syncStatus]\ => timingBus.message.syncStatus,
    \timingBus[message][calibrationGap]\ => timingBus.message.calibrationGap,
    \timingBus[message][bcsFault]\ => timingBus.message.bcsFault,
    \timingBus[message][mpsLimit]\ => timingBus.message.mpsLimit,
    \timingBus[message][mpsClass][0]\ => timingBus.message.mpsClass(0),
    \timingBus[message][mpsClass][1]\ => timingBus.message.mpsClass(1),
    \timingBus[message][mpsClass][2]\ => timingBus.message.mpsClass(2),
    \timingBus[message][mpsClass][3]\ => timingBus.message.mpsClass(3),
    \timingBus[message][mpsClass][4]\ => timingBus.message.mpsClass(4),
    \timingBus[message][mpsClass][5]\ => timingBus.message.mpsClass(5),
    \timingBus[message][mpsClass][6]\ => timingBus.message.mpsClass(6),
    \timingBus[message][mpsClass][7]\ => timingBus.message.mpsClass(7),
    \timingBus[message][mpsClass][8]\ => timingBus.message.mpsClass(8),
    \timingBus[message][mpsClass][9]\ => timingBus.message.mpsClass(9),
    \timingBus[message][mpsClass][10]\ => timingBus.message.mpsClass(10),
    \timingBus[message][mpsClass][11]\ => timingBus.message.mpsClass(11),
    \timingBus[message][mpsClass][12]\ => timingBus.message.mpsClass(12),
    \timingBus[message][mpsClass][13]\ => timingBus.message.mpsClass(13),
    \timingBus[message][mpsClass][14]\ => timingBus.message.mpsClass(14),
    \timingBus[message][mpsClass][15]\ => timingBus.message.mpsClass(15),
    \timingBus[message][bsaInit]\ => timingBus.message.bsaInit,
    \timingBus[message][bsaActive]\ => timingBus.message.bsaActive,
    \timingBus[message][bsaAvgDone]\ => timingBus.message.bsaAvgDone,
    \timingBus[message][bsaDone]\ => timingBus.message.bsaDone,
    \timingBus[message][control][0]\ => timingBus.message.control(0),
    \timingBus[message][control][1]\ => timingBus.message.control(1),
    \timingBus[message][control][2]\ => timingBus.message.control(2),
    \timingBus[message][control][3]\ => timingBus.message.control(3),
    \timingBus[message][control][4]\ => timingBus.message.control(4),
    \timingBus[message][control][5]\ => timingBus.message.control(5),
    \timingBus[message][control][6]\ => timingBus.message.control(6),
    \timingBus[message][control][7]\ => timingBus.message.control(7),
    \timingBus[message][control][8]\ => timingBus.message.control(8),
    \timingBus[message][control][9]\ => timingBus.message.control(9),
    \timingBus[message][control][10]\ => timingBus.message.control(10),
    \timingBus[message][control][11]\ => timingBus.message.control(11),
    \timingBus[message][control][12]\ => timingBus.message.control(12),
    \timingBus[message][control][13]\ => timingBus.message.control(13),
    \timingBus[message][control][14]\ => timingBus.message.control(14),
    \timingBus[message][control][15]\ => timingBus.message.control(15),
    \timingBus[message][control][16]\ => timingBus.message.control(16),
    \timingBus[message][control][17]\ => timingBus.message.control(17),
    \timingBus[stream][pulseId]\ => timingBus.stream.pulseId,
    \timingBus[stream][eventCodes]\ => timingBus.stream.eventCodes,
    \timingBus[stream][dbuff][dtype]\ => timingBus.stream.dbuff.dtype,
    \timingBus[stream][dbuff][version]\ => timingBus.stream.dbuff.version,
    \timingBus[stream][dbuff][dmod]\ => timingBus.stream.dbuff.dmod,
    \timingBus[stream][dbuff][epicsTime]\ => timingBus.stream.dbuff.epicsTime,
    \timingBus[stream][dbuff][edefAvgDn]\ => timingBus.stream.dbuff.edefAvgDn,
    \timingBus[stream][dbuff][edefMinor]\ => timingBus.stream.dbuff.edefMinor,
    \timingBus[stream][dbuff][edefMajor]\ => timingBus.stream.dbuff.edefMajor,
    \timingBus[stream][dbuff][edefInit]\ => timingBus.stream.dbuff.edefInit,
    \timingBus[v1][linkUp]\ => timingBus.v1.linkUp,
    \timingBus[v2][linkUp]\ => timingBus.v2.linkUp,
    \timingPhy[dataK]\ => timingPhy.dataK,
    \timingPhy[data]\ => timingPhy.data,
    \timingPhy[control][reset]\ => timingPhy.control.reset,
    \timingPhy[control][inhibit]\ => timingPhy.control.inhibit,
    \timingPhy[control][polarity]\ => timingPhy.control.polarity,
    \timingPhy[control][bufferByRst]\ => timingPhy.control.bufferByRst,
    \timingPhy[control][pllReset]\ => timingPhy.control.pllReset,
    timingPhyClk => timingPhyClk,
    timingPhyRst => timingPhyRst,
    diagnosticClk => diagnosticClk,
    diagnosticRst => diagnosticRst,
    \diagnosticBus[strobe]\ => diagnosticBus.strobe,
    \diagnosticBus[data][31]\ => diagnosticBus.data(31),
    \diagnosticBus[data][30]\ => diagnosticBus.data(30),
    \diagnosticBus[data][29]\ => diagnosticBus.data(29),
    \diagnosticBus[data][28]\ => diagnosticBus.data(28),
    \diagnosticBus[data][27]\ => diagnosticBus.data(27),
    \diagnosticBus[data][26]\ => diagnosticBus.data(26),
    \diagnosticBus[data][25]\ => diagnosticBus.data(25),
    \diagnosticBus[data][24]\ => diagnosticBus.data(24),
    \diagnosticBus[data][23]\ => diagnosticBus.data(23),
    \diagnosticBus[data][22]\ => diagnosticBus.data(22),
    \diagnosticBus[data][21]\ => diagnosticBus.data(21),
    \diagnosticBus[data][20]\ => diagnosticBus.data(20),
    \diagnosticBus[data][19]\ => diagnosticBus.data(19),
    \diagnosticBus[data][18]\ => diagnosticBus.data(18),
    \diagnosticBus[data][17]\ => diagnosticBus.data(17),
    \diagnosticBus[data][16]\ => diagnosticBus.data(16),
    \diagnosticBus[data][15]\ => diagnosticBus.data(15),
    \diagnosticBus[data][14]\ => diagnosticBus.data(14),
    \diagnosticBus[data][13]\ => diagnosticBus.data(13),
    \diagnosticBus[data][12]\ => diagnosticBus.data(12),
    \diagnosticBus[data][11]\ => diagnosticBus.data(11),
    \diagnosticBus[data][10]\ => diagnosticBus.data(10),
    \diagnosticBus[data][9]\ => diagnosticBus.data(9),
    \diagnosticBus[data][8]\ => diagnosticBus.data(8),
    \diagnosticBus[data][7]\ => diagnosticBus.data(7),
    \diagnosticBus[data][6]\ => diagnosticBus.data(6),
    \diagnosticBus[data][5]\ => diagnosticBus.data(5),
    \diagnosticBus[data][4]\ => diagnosticBus.data(4),
    \diagnosticBus[data][3]\ => diagnosticBus.data(3),
    \diagnosticBus[data][2]\ => diagnosticBus.data(2),
    \diagnosticBus[data][1]\ => diagnosticBus.data(1),
    \diagnosticBus[data][0]\ => diagnosticBus.data(0),
    \diagnosticBus[timingMessage][version]\ => diagnosticBus.timingMessage.version,
    \diagnosticBus[timingMessage][pulseId]\ => diagnosticBus.timingMessage.pulseId,
    \diagnosticBus[timingMessage][timeStamp]\ => diagnosticBus.timingMessage.timeStamp,
    \diagnosticBus[timingMessage][fixedRates]\ => diagnosticBus.timingMessage.fixedRates,
    \diagnosticBus[timingMessage][acRates]\ => diagnosticBus.timingMessage.acRates,
    \diagnosticBus[timingMessage][acTimeSlot]\ => diagnosticBus.timingMessage.acTimeSlot,
    \diagnosticBus[timingMessage][acTimeSlotPhase]\ => diagnosticBus.timingMessage.acTimeSlotPhase,
    \diagnosticBus[timingMessage][resync]\ => diagnosticBus.timingMessage.resync,
    \diagnosticBus[timingMessage][beamRequest]\ => diagnosticBus.timingMessage.beamRequest,
    \diagnosticBus[timingMessage][beamEnergy][0]\ => diagnosticBus.timingMessage.beamEnergy(0),
    \diagnosticBus[timingMessage][beamEnergy][1]\ => diagnosticBus.timingMessage.beamEnergy(1),
    \diagnosticBus[timingMessage][beamEnergy][2]\ => diagnosticBus.timingMessage.beamEnergy(2),
    \diagnosticBus[timingMessage][beamEnergy][3]\ => diagnosticBus.timingMessage.beamEnergy(3),
    \diagnosticBus[timingMessage][syncStatus]\ => diagnosticBus.timingMessage.syncStatus,
    \diagnosticBus[timingMessage][calibrationGap]\ => diagnosticBus.timingMessage.calibrationGap,
    \diagnosticBus[timingMessage][bcsFault]\ => diagnosticBus.timingMessage.bcsFault,
    \diagnosticBus[timingMessage][mpsLimit]\ => diagnosticBus.timingMessage.mpsLimit,
    \diagnosticBus[timingMessage][mpsClass][0]\ => diagnosticBus.timingMessage.mpsClass(0),
    \diagnosticBus[timingMessage][mpsClass][1]\ => diagnosticBus.timingMessage.mpsClass(1),
    \diagnosticBus[timingMessage][mpsClass][2]\ => diagnosticBus.timingMessage.mpsClass(2),
    \diagnosticBus[timingMessage][mpsClass][3]\ => diagnosticBus.timingMessage.mpsClass(3),
    \diagnosticBus[timingMessage][mpsClass][4]\ => diagnosticBus.timingMessage.mpsClass(4),
    \diagnosticBus[timingMessage][mpsClass][5]\ => diagnosticBus.timingMessage.mpsClass(5),
    \diagnosticBus[timingMessage][mpsClass][6]\ => diagnosticBus.timingMessage.mpsClass(6),
    \diagnosticBus[timingMessage][mpsClass][7]\ => diagnosticBus.timingMessage.mpsClass(7),
    \diagnosticBus[timingMessage][mpsClass][8]\ => diagnosticBus.timingMessage.mpsClass(8),
    \diagnosticBus[timingMessage][mpsClass][9]\ => diagnosticBus.timingMessage.mpsClass(9),
    \diagnosticBus[timingMessage][mpsClass][10]\ => diagnosticBus.timingMessage.mpsClass(10),
    \diagnosticBus[timingMessage][mpsClass][11]\ => diagnosticBus.timingMessage.mpsClass(11),
    \diagnosticBus[timingMessage][mpsClass][12]\ => diagnosticBus.timingMessage.mpsClass(12),
    \diagnosticBus[timingMessage][mpsClass][13]\ => diagnosticBus.timingMessage.mpsClass(13),
    \diagnosticBus[timingMessage][mpsClass][14]\ => diagnosticBus.timingMessage.mpsClass(14),
    \diagnosticBus[timingMessage][mpsClass][15]\ => diagnosticBus.timingMessage.mpsClass(15),
    \diagnosticBus[timingMessage][bsaInit]\ => diagnosticBus.timingMessage.bsaInit,
    \diagnosticBus[timingMessage][bsaActive]\ => diagnosticBus.timingMessage.bsaActive,
    \diagnosticBus[timingMessage][bsaAvgDone]\ => diagnosticBus.timingMessage.bsaAvgDone,
    \diagnosticBus[timingMessage][bsaDone]\ => diagnosticBus.timingMessage.bsaDone,
    \diagnosticBus[timingMessage][control][0]\ => diagnosticBus.timingMessage.control(0),
    \diagnosticBus[timingMessage][control][1]\ => diagnosticBus.timingMessage.control(1),
    \diagnosticBus[timingMessage][control][2]\ => diagnosticBus.timingMessage.control(2),
    \diagnosticBus[timingMessage][control][3]\ => diagnosticBus.timingMessage.control(3),
    \diagnosticBus[timingMessage][control][4]\ => diagnosticBus.timingMessage.control(4),
    \diagnosticBus[timingMessage][control][5]\ => diagnosticBus.timingMessage.control(5),
    \diagnosticBus[timingMessage][control][6]\ => diagnosticBus.timingMessage.control(6),
    \diagnosticBus[timingMessage][control][7]\ => diagnosticBus.timingMessage.control(7),
    \diagnosticBus[timingMessage][control][8]\ => diagnosticBus.timingMessage.control(8),
    \diagnosticBus[timingMessage][control][9]\ => diagnosticBus.timingMessage.control(9),
    \diagnosticBus[timingMessage][control][10]\ => diagnosticBus.timingMessage.control(10),
    \diagnosticBus[timingMessage][control][11]\ => diagnosticBus.timingMessage.control(11),
    \diagnosticBus[timingMessage][control][12]\ => diagnosticBus.timingMessage.control(12),
    \diagnosticBus[timingMessage][control][13]\ => diagnosticBus.timingMessage.control(13),
    \diagnosticBus[timingMessage][control][14]\ => diagnosticBus.timingMessage.control(14),
    \diagnosticBus[timingMessage][control][15]\ => diagnosticBus.timingMessage.control(15),
    \diagnosticBus[timingMessage][control][16]\ => diagnosticBus.timingMessage.control(16),
    \diagnosticBus[timingMessage][control][17]\ => diagnosticBus.timingMessage.control(17),
    waveformClk => waveformClk,
    waveformRst => waveformRst,
    \obAppWaveformMasters[1][3][tValid]\ => obAppWaveformMasters(1)(3).tValid,
    \obAppWaveformMasters[1][3][tData]\ => obAppWaveformMasters(1)(3).tData,
    \obAppWaveformMasters[1][3][tStrb]\ => obAppWaveformMasters(1)(3).tStrb,
    \obAppWaveformMasters[1][3][tKeep]\ => obAppWaveformMasters(1)(3).tKeep,
    \obAppWaveformMasters[1][3][tLast]\ => obAppWaveformMasters(1)(3).tLast,
    \obAppWaveformMasters[1][3][tDest]\ => obAppWaveformMasters(1)(3).tDest,
    \obAppWaveformMasters[1][3][tId]\ => obAppWaveformMasters(1)(3).tId,
    \obAppWaveformMasters[1][3][tUser]\ => obAppWaveformMasters(1)(3).tUser,
    \obAppWaveformMasters[1][2][tValid]\ => obAppWaveformMasters(1)(2).tValid,
    \obAppWaveformMasters[1][2][tData]\ => obAppWaveformMasters(1)(2).tData,
    \obAppWaveformMasters[1][2][tStrb]\ => obAppWaveformMasters(1)(2).tStrb,
    \obAppWaveformMasters[1][2][tKeep]\ => obAppWaveformMasters(1)(2).tKeep,
    \obAppWaveformMasters[1][2][tLast]\ => obAppWaveformMasters(1)(2).tLast,
    \obAppWaveformMasters[1][2][tDest]\ => obAppWaveformMasters(1)(2).tDest,
    \obAppWaveformMasters[1][2][tId]\ => obAppWaveformMasters(1)(2).tId,
    \obAppWaveformMasters[1][2][tUser]\ => obAppWaveformMasters(1)(2).tUser,
    \obAppWaveformMasters[1][1][tValid]\ => obAppWaveformMasters(1)(1).tValid,
    \obAppWaveformMasters[1][1][tData]\ => obAppWaveformMasters(1)(1).tData,
    \obAppWaveformMasters[1][1][tStrb]\ => obAppWaveformMasters(1)(1).tStrb,
    \obAppWaveformMasters[1][1][tKeep]\ => obAppWaveformMasters(1)(1).tKeep,
    \obAppWaveformMasters[1][1][tLast]\ => obAppWaveformMasters(1)(1).tLast,
    \obAppWaveformMasters[1][1][tDest]\ => obAppWaveformMasters(1)(1).tDest,
    \obAppWaveformMasters[1][1][tId]\ => obAppWaveformMasters(1)(1).tId,
    \obAppWaveformMasters[1][1][tUser]\ => obAppWaveformMasters(1)(1).tUser,
    \obAppWaveformMasters[1][0][tValid]\ => obAppWaveformMasters(1)(0).tValid,
    \obAppWaveformMasters[1][0][tData]\ => obAppWaveformMasters(1)(0).tData,
    \obAppWaveformMasters[1][0][tStrb]\ => obAppWaveformMasters(1)(0).tStrb,
    \obAppWaveformMasters[1][0][tKeep]\ => obAppWaveformMasters(1)(0).tKeep,
    \obAppWaveformMasters[1][0][tLast]\ => obAppWaveformMasters(1)(0).tLast,
    \obAppWaveformMasters[1][0][tDest]\ => obAppWaveformMasters(1)(0).tDest,
    \obAppWaveformMasters[1][0][tId]\ => obAppWaveformMasters(1)(0).tId,
    \obAppWaveformMasters[1][0][tUser]\ => obAppWaveformMasters(1)(0).tUser,
    \obAppWaveformMasters[0][3][tValid]\ => obAppWaveformMasters(0)(3).tValid,
    \obAppWaveformMasters[0][3][tData]\ => obAppWaveformMasters(0)(3).tData,
    \obAppWaveformMasters[0][3][tStrb]\ => obAppWaveformMasters(0)(3).tStrb,
    \obAppWaveformMasters[0][3][tKeep]\ => obAppWaveformMasters(0)(3).tKeep,
    \obAppWaveformMasters[0][3][tLast]\ => obAppWaveformMasters(0)(3).tLast,
    \obAppWaveformMasters[0][3][tDest]\ => obAppWaveformMasters(0)(3).tDest,
    \obAppWaveformMasters[0][3][tId]\ => obAppWaveformMasters(0)(3).tId,
    \obAppWaveformMasters[0][3][tUser]\ => obAppWaveformMasters(0)(3).tUser,
    \obAppWaveformMasters[0][2][tValid]\ => obAppWaveformMasters(0)(2).tValid,
    \obAppWaveformMasters[0][2][tData]\ => obAppWaveformMasters(0)(2).tData,
    \obAppWaveformMasters[0][2][tStrb]\ => obAppWaveformMasters(0)(2).tStrb,
    \obAppWaveformMasters[0][2][tKeep]\ => obAppWaveformMasters(0)(2).tKeep,
    \obAppWaveformMasters[0][2][tLast]\ => obAppWaveformMasters(0)(2).tLast,
    \obAppWaveformMasters[0][2][tDest]\ => obAppWaveformMasters(0)(2).tDest,
    \obAppWaveformMasters[0][2][tId]\ => obAppWaveformMasters(0)(2).tId,
    \obAppWaveformMasters[0][2][tUser]\ => obAppWaveformMasters(0)(2).tUser,
    \obAppWaveformMasters[0][1][tValid]\ => obAppWaveformMasters(0)(1).tValid,
    \obAppWaveformMasters[0][1][tData]\ => obAppWaveformMasters(0)(1).tData,
    \obAppWaveformMasters[0][1][tStrb]\ => obAppWaveformMasters(0)(1).tStrb,
    \obAppWaveformMasters[0][1][tKeep]\ => obAppWaveformMasters(0)(1).tKeep,
    \obAppWaveformMasters[0][1][tLast]\ => obAppWaveformMasters(0)(1).tLast,
    \obAppWaveformMasters[0][1][tDest]\ => obAppWaveformMasters(0)(1).tDest,
    \obAppWaveformMasters[0][1][tId]\ => obAppWaveformMasters(0)(1).tId,
    \obAppWaveformMasters[0][1][tUser]\ => obAppWaveformMasters(0)(1).tUser,
    \obAppWaveformMasters[0][0][tValid]\ => obAppWaveformMasters(0)(0).tValid,
    \obAppWaveformMasters[0][0][tData]\ => obAppWaveformMasters(0)(0).tData,
    \obAppWaveformMasters[0][0][tStrb]\ => obAppWaveformMasters(0)(0).tStrb,
    \obAppWaveformMasters[0][0][tKeep]\ => obAppWaveformMasters(0)(0).tKeep,
    \obAppWaveformMasters[0][0][tLast]\ => obAppWaveformMasters(0)(0).tLast,
    \obAppWaveformMasters[0][0][tDest]\ => obAppWaveformMasters(0)(0).tDest,
    \obAppWaveformMasters[0][0][tId]\ => obAppWaveformMasters(0)(0).tId,
    \obAppWaveformMasters[0][0][tUser]\ => obAppWaveformMasters(0)(0).tUser,
    \obAppWaveformSlaves[1][3][slave][tReady]\ => obAppWaveformSlaves(1)(3).slave.tReady,
    \obAppWaveformSlaves[1][3][ctrl][pause]\ => obAppWaveformSlaves(1)(3).ctrl.pause,
    \obAppWaveformSlaves[1][3][ctrl][overflow]\ => obAppWaveformSlaves(1)(3).ctrl.overflow,
    \obAppWaveformSlaves[1][3][ctrl][idle]\ => obAppWaveformSlaves(1)(3).ctrl.idle,
    \obAppWaveformSlaves[1][2][slave][tReady]\ => obAppWaveformSlaves(1)(2).slave.tReady,
    \obAppWaveformSlaves[1][2][ctrl][pause]\ => obAppWaveformSlaves(1)(2).ctrl.pause,
    \obAppWaveformSlaves[1][2][ctrl][overflow]\ => obAppWaveformSlaves(1)(2).ctrl.overflow,
    \obAppWaveformSlaves[1][2][ctrl][idle]\ => obAppWaveformSlaves(1)(2).ctrl.idle,
    \obAppWaveformSlaves[1][1][slave][tReady]\ => obAppWaveformSlaves(1)(1).slave.tReady,
    \obAppWaveformSlaves[1][1][ctrl][pause]\ => obAppWaveformSlaves(1)(1).ctrl.pause,
    \obAppWaveformSlaves[1][1][ctrl][overflow]\ => obAppWaveformSlaves(1)(1).ctrl.overflow,
    \obAppWaveformSlaves[1][1][ctrl][idle]\ => obAppWaveformSlaves(1)(1).ctrl.idle,
    \obAppWaveformSlaves[1][0][slave][tReady]\ => obAppWaveformSlaves(1)(0).slave.tReady,
    \obAppWaveformSlaves[1][0][ctrl][pause]\ => obAppWaveformSlaves(1)(0).ctrl.pause,
    \obAppWaveformSlaves[1][0][ctrl][overflow]\ => obAppWaveformSlaves(1)(0).ctrl.overflow,
    \obAppWaveformSlaves[1][0][ctrl][idle]\ => obAppWaveformSlaves(1)(0).ctrl.idle,
    \obAppWaveformSlaves[0][3][slave][tReady]\ => obAppWaveformSlaves(0)(3).slave.tReady,
    \obAppWaveformSlaves[0][3][ctrl][pause]\ => obAppWaveformSlaves(0)(3).ctrl.pause,
    \obAppWaveformSlaves[0][3][ctrl][overflow]\ => obAppWaveformSlaves(0)(3).ctrl.overflow,
    \obAppWaveformSlaves[0][3][ctrl][idle]\ => obAppWaveformSlaves(0)(3).ctrl.idle,
    \obAppWaveformSlaves[0][2][slave][tReady]\ => obAppWaveformSlaves(0)(2).slave.tReady,
    \obAppWaveformSlaves[0][2][ctrl][pause]\ => obAppWaveformSlaves(0)(2).ctrl.pause,
    \obAppWaveformSlaves[0][2][ctrl][overflow]\ => obAppWaveformSlaves(0)(2).ctrl.overflow,
    \obAppWaveformSlaves[0][2][ctrl][idle]\ => obAppWaveformSlaves(0)(2).ctrl.idle,
    \obAppWaveformSlaves[0][1][slave][tReady]\ => obAppWaveformSlaves(0)(1).slave.tReady,
    \obAppWaveformSlaves[0][1][ctrl][pause]\ => obAppWaveformSlaves(0)(1).ctrl.pause,
    \obAppWaveformSlaves[0][1][ctrl][overflow]\ => obAppWaveformSlaves(0)(1).ctrl.overflow,
    \obAppWaveformSlaves[0][1][ctrl][idle]\ => obAppWaveformSlaves(0)(1).ctrl.idle,
    \obAppWaveformSlaves[0][0][slave][tReady]\ => obAppWaveformSlaves(0)(0).slave.tReady,
    \obAppWaveformSlaves[0][0][ctrl][pause]\ => obAppWaveformSlaves(0)(0).ctrl.pause,
    \obAppWaveformSlaves[0][0][ctrl][overflow]\ => obAppWaveformSlaves(0)(0).ctrl.overflow,
    \obAppWaveformSlaves[0][0][ctrl][idle]\ => obAppWaveformSlaves(0)(0).ctrl.idle,
    \ibAppWaveformMasters[1][3][tValid]\ => ibAppWaveformMasters(1)(3).tValid,
    \ibAppWaveformMasters[1][3][tData]\ => ibAppWaveformMasters(1)(3).tData,
    \ibAppWaveformMasters[1][3][tStrb]\ => ibAppWaveformMasters(1)(3).tStrb,
    \ibAppWaveformMasters[1][3][tKeep]\ => ibAppWaveformMasters(1)(3).tKeep,
    \ibAppWaveformMasters[1][3][tLast]\ => ibAppWaveformMasters(1)(3).tLast,
    \ibAppWaveformMasters[1][3][tDest]\ => ibAppWaveformMasters(1)(3).tDest,
    \ibAppWaveformMasters[1][3][tId]\ => ibAppWaveformMasters(1)(3).tId,
    \ibAppWaveformMasters[1][3][tUser]\ => ibAppWaveformMasters(1)(3).tUser,
    \ibAppWaveformMasters[1][2][tValid]\ => ibAppWaveformMasters(1)(2).tValid,
    \ibAppWaveformMasters[1][2][tData]\ => ibAppWaveformMasters(1)(2).tData,
    \ibAppWaveformMasters[1][2][tStrb]\ => ibAppWaveformMasters(1)(2).tStrb,
    \ibAppWaveformMasters[1][2][tKeep]\ => ibAppWaveformMasters(1)(2).tKeep,
    \ibAppWaveformMasters[1][2][tLast]\ => ibAppWaveformMasters(1)(2).tLast,
    \ibAppWaveformMasters[1][2][tDest]\ => ibAppWaveformMasters(1)(2).tDest,
    \ibAppWaveformMasters[1][2][tId]\ => ibAppWaveformMasters(1)(2).tId,
    \ibAppWaveformMasters[1][2][tUser]\ => ibAppWaveformMasters(1)(2).tUser,
    \ibAppWaveformMasters[1][1][tValid]\ => ibAppWaveformMasters(1)(1).tValid,
    \ibAppWaveformMasters[1][1][tData]\ => ibAppWaveformMasters(1)(1).tData,
    \ibAppWaveformMasters[1][1][tStrb]\ => ibAppWaveformMasters(1)(1).tStrb,
    \ibAppWaveformMasters[1][1][tKeep]\ => ibAppWaveformMasters(1)(1).tKeep,
    \ibAppWaveformMasters[1][1][tLast]\ => ibAppWaveformMasters(1)(1).tLast,
    \ibAppWaveformMasters[1][1][tDest]\ => ibAppWaveformMasters(1)(1).tDest,
    \ibAppWaveformMasters[1][1][tId]\ => ibAppWaveformMasters(1)(1).tId,
    \ibAppWaveformMasters[1][1][tUser]\ => ibAppWaveformMasters(1)(1).tUser,
    \ibAppWaveformMasters[1][0][tValid]\ => ibAppWaveformMasters(1)(0).tValid,
    \ibAppWaveformMasters[1][0][tData]\ => ibAppWaveformMasters(1)(0).tData,
    \ibAppWaveformMasters[1][0][tStrb]\ => ibAppWaveformMasters(1)(0).tStrb,
    \ibAppWaveformMasters[1][0][tKeep]\ => ibAppWaveformMasters(1)(0).tKeep,
    \ibAppWaveformMasters[1][0][tLast]\ => ibAppWaveformMasters(1)(0).tLast,
    \ibAppWaveformMasters[1][0][tDest]\ => ibAppWaveformMasters(1)(0).tDest,
    \ibAppWaveformMasters[1][0][tId]\ => ibAppWaveformMasters(1)(0).tId,
    \ibAppWaveformMasters[1][0][tUser]\ => ibAppWaveformMasters(1)(0).tUser,
    \ibAppWaveformMasters[0][3][tValid]\ => ibAppWaveformMasters(0)(3).tValid,
    \ibAppWaveformMasters[0][3][tData]\ => ibAppWaveformMasters(0)(3).tData,
    \ibAppWaveformMasters[0][3][tStrb]\ => ibAppWaveformMasters(0)(3).tStrb,
    \ibAppWaveformMasters[0][3][tKeep]\ => ibAppWaveformMasters(0)(3).tKeep,
    \ibAppWaveformMasters[0][3][tLast]\ => ibAppWaveformMasters(0)(3).tLast,
    \ibAppWaveformMasters[0][3][tDest]\ => ibAppWaveformMasters(0)(3).tDest,
    \ibAppWaveformMasters[0][3][tId]\ => ibAppWaveformMasters(0)(3).tId,
    \ibAppWaveformMasters[0][3][tUser]\ => ibAppWaveformMasters(0)(3).tUser,
    \ibAppWaveformMasters[0][2][tValid]\ => ibAppWaveformMasters(0)(2).tValid,
    \ibAppWaveformMasters[0][2][tData]\ => ibAppWaveformMasters(0)(2).tData,
    \ibAppWaveformMasters[0][2][tStrb]\ => ibAppWaveformMasters(0)(2).tStrb,
    \ibAppWaveformMasters[0][2][tKeep]\ => ibAppWaveformMasters(0)(2).tKeep,
    \ibAppWaveformMasters[0][2][tLast]\ => ibAppWaveformMasters(0)(2).tLast,
    \ibAppWaveformMasters[0][2][tDest]\ => ibAppWaveformMasters(0)(2).tDest,
    \ibAppWaveformMasters[0][2][tId]\ => ibAppWaveformMasters(0)(2).tId,
    \ibAppWaveformMasters[0][2][tUser]\ => ibAppWaveformMasters(0)(2).tUser,
    \ibAppWaveformMasters[0][1][tValid]\ => ibAppWaveformMasters(0)(1).tValid,
    \ibAppWaveformMasters[0][1][tData]\ => ibAppWaveformMasters(0)(1).tData,
    \ibAppWaveformMasters[0][1][tStrb]\ => ibAppWaveformMasters(0)(1).tStrb,
    \ibAppWaveformMasters[0][1][tKeep]\ => ibAppWaveformMasters(0)(1).tKeep,
    \ibAppWaveformMasters[0][1][tLast]\ => ibAppWaveformMasters(0)(1).tLast,
    \ibAppWaveformMasters[0][1][tDest]\ => ibAppWaveformMasters(0)(1).tDest,
    \ibAppWaveformMasters[0][1][tId]\ => ibAppWaveformMasters(0)(1).tId,
    \ibAppWaveformMasters[0][1][tUser]\ => ibAppWaveformMasters(0)(1).tUser,
    \ibAppWaveformMasters[0][0][tValid]\ => ibAppWaveformMasters(0)(0).tValid,
    \ibAppWaveformMasters[0][0][tData]\ => ibAppWaveformMasters(0)(0).tData,
    \ibAppWaveformMasters[0][0][tStrb]\ => ibAppWaveformMasters(0)(0).tStrb,
    \ibAppWaveformMasters[0][0][tKeep]\ => ibAppWaveformMasters(0)(0).tKeep,
    \ibAppWaveformMasters[0][0][tLast]\ => ibAppWaveformMasters(0)(0).tLast,
    \ibAppWaveformMasters[0][0][tDest]\ => ibAppWaveformMasters(0)(0).tDest,
    \ibAppWaveformMasters[0][0][tId]\ => ibAppWaveformMasters(0)(0).tId,
    \ibAppWaveformMasters[0][0][tUser]\ => ibAppWaveformMasters(0)(0).tUser,
    \ibAppWaveformSlaves[1][3][slave][tReady]\ => ibAppWaveformSlaves(1)(3).slave.tReady,
    \ibAppWaveformSlaves[1][3][ctrl][pause]\ => ibAppWaveformSlaves(1)(3).ctrl.pause,
    \ibAppWaveformSlaves[1][3][ctrl][overflow]\ => ibAppWaveformSlaves(1)(3).ctrl.overflow,
    \ibAppWaveformSlaves[1][3][ctrl][idle]\ => ibAppWaveformSlaves(1)(3).ctrl.idle,
    \ibAppWaveformSlaves[1][2][slave][tReady]\ => ibAppWaveformSlaves(1)(2).slave.tReady,
    \ibAppWaveformSlaves[1][2][ctrl][pause]\ => ibAppWaveformSlaves(1)(2).ctrl.pause,
    \ibAppWaveformSlaves[1][2][ctrl][overflow]\ => ibAppWaveformSlaves(1)(2).ctrl.overflow,
    \ibAppWaveformSlaves[1][2][ctrl][idle]\ => ibAppWaveformSlaves(1)(2).ctrl.idle,
    \ibAppWaveformSlaves[1][1][slave][tReady]\ => ibAppWaveformSlaves(1)(1).slave.tReady,
    \ibAppWaveformSlaves[1][1][ctrl][pause]\ => ibAppWaveformSlaves(1)(1).ctrl.pause,
    \ibAppWaveformSlaves[1][1][ctrl][overflow]\ => ibAppWaveformSlaves(1)(1).ctrl.overflow,
    \ibAppWaveformSlaves[1][1][ctrl][idle]\ => ibAppWaveformSlaves(1)(1).ctrl.idle,
    \ibAppWaveformSlaves[1][0][slave][tReady]\ => ibAppWaveformSlaves(1)(0).slave.tReady,
    \ibAppWaveformSlaves[1][0][ctrl][pause]\ => ibAppWaveformSlaves(1)(0).ctrl.pause,
    \ibAppWaveformSlaves[1][0][ctrl][overflow]\ => ibAppWaveformSlaves(1)(0).ctrl.overflow,
    \ibAppWaveformSlaves[1][0][ctrl][idle]\ => ibAppWaveformSlaves(1)(0).ctrl.idle,
    \ibAppWaveformSlaves[0][3][slave][tReady]\ => ibAppWaveformSlaves(0)(3).slave.tReady,
    \ibAppWaveformSlaves[0][3][ctrl][pause]\ => ibAppWaveformSlaves(0)(3).ctrl.pause,
    \ibAppWaveformSlaves[0][3][ctrl][overflow]\ => ibAppWaveformSlaves(0)(3).ctrl.overflow,
    \ibAppWaveformSlaves[0][3][ctrl][idle]\ => ibAppWaveformSlaves(0)(3).ctrl.idle,
    \ibAppWaveformSlaves[0][2][slave][tReady]\ => ibAppWaveformSlaves(0)(2).slave.tReady,
    \ibAppWaveformSlaves[0][2][ctrl][pause]\ => ibAppWaveformSlaves(0)(2).ctrl.pause,
    \ibAppWaveformSlaves[0][2][ctrl][overflow]\ => ibAppWaveformSlaves(0)(2).ctrl.overflow,
    \ibAppWaveformSlaves[0][2][ctrl][idle]\ => ibAppWaveformSlaves(0)(2).ctrl.idle,
    \ibAppWaveformSlaves[0][1][slave][tReady]\ => ibAppWaveformSlaves(0)(1).slave.tReady,
    \ibAppWaveformSlaves[0][1][ctrl][pause]\ => ibAppWaveformSlaves(0)(1).ctrl.pause,
    \ibAppWaveformSlaves[0][1][ctrl][overflow]\ => ibAppWaveformSlaves(0)(1).ctrl.overflow,
    \ibAppWaveformSlaves[0][1][ctrl][idle]\ => ibAppWaveformSlaves(0)(1).ctrl.idle,
    \ibAppWaveformSlaves[0][0][slave][tReady]\ => ibAppWaveformSlaves(0)(0).slave.tReady,
    \ibAppWaveformSlaves[0][0][ctrl][pause]\ => ibAppWaveformSlaves(0)(0).ctrl.pause,
    \ibAppWaveformSlaves[0][0][ctrl][overflow]\ => ibAppWaveformSlaves(0)(0).ctrl.overflow,
    \ibAppWaveformSlaves[0][0][ctrl][idle]\ => ibAppWaveformSlaves(0)(0).ctrl.idle,
    \obBpMsgClientMaster[tValid]\ => obBpMsgClientMaster.tValid,
    \obBpMsgClientMaster[tData]\ => obBpMsgClientMaster.tData,
    \obBpMsgClientMaster[tStrb]\ => obBpMsgClientMaster.tStrb,
    \obBpMsgClientMaster[tKeep]\ => obBpMsgClientMaster.tKeep,
    \obBpMsgClientMaster[tLast]\ => obBpMsgClientMaster.tLast,
    \obBpMsgClientMaster[tDest]\ => obBpMsgClientMaster.tDest,
    \obBpMsgClientMaster[tId]\ => obBpMsgClientMaster.tId,
    \obBpMsgClientMaster[tUser]\ => obBpMsgClientMaster.tUser,
    \obBpMsgClientSlave[tReady]\ => obBpMsgClientSlave.tReady,
    \ibBpMsgClientMaster[tValid]\ => ibBpMsgClientMaster.tValid,
    \ibBpMsgClientMaster[tData]\ => ibBpMsgClientMaster.tData,
    \ibBpMsgClientMaster[tStrb]\ => ibBpMsgClientMaster.tStrb,
    \ibBpMsgClientMaster[tKeep]\ => ibBpMsgClientMaster.tKeep,
    \ibBpMsgClientMaster[tLast]\ => ibBpMsgClientMaster.tLast,
    \ibBpMsgClientMaster[tDest]\ => ibBpMsgClientMaster.tDest,
    \ibBpMsgClientMaster[tId]\ => ibBpMsgClientMaster.tId,
    \ibBpMsgClientMaster[tUser]\ => ibBpMsgClientMaster.tUser,
    \ibBpMsgClientSlave[tReady]\ => ibBpMsgClientSlave.tReady,
    \obBpMsgServerMaster[tValid]\ => obBpMsgServerMaster.tValid,
    \obBpMsgServerMaster[tData]\ => obBpMsgServerMaster.tData,
    \obBpMsgServerMaster[tStrb]\ => obBpMsgServerMaster.tStrb,
    \obBpMsgServerMaster[tKeep]\ => obBpMsgServerMaster.tKeep,
    \obBpMsgServerMaster[tLast]\ => obBpMsgServerMaster.tLast,
    \obBpMsgServerMaster[tDest]\ => obBpMsgServerMaster.tDest,
    \obBpMsgServerMaster[tId]\ => obBpMsgServerMaster.tId,
    \obBpMsgServerMaster[tUser]\ => obBpMsgServerMaster.tUser,
    \obBpMsgServerSlave[tReady]\ => obBpMsgServerSlave.tReady,
    \ibBpMsgServerMaster[tValid]\ => ibBpMsgServerMaster.tValid,
    \ibBpMsgServerMaster[tData]\ => ibBpMsgServerMaster.tData,
    \ibBpMsgServerMaster[tStrb]\ => ibBpMsgServerMaster.tStrb,
    \ibBpMsgServerMaster[tKeep]\ => ibBpMsgServerMaster.tKeep,
    \ibBpMsgServerMaster[tLast]\ => ibBpMsgServerMaster.tLast,
    \ibBpMsgServerMaster[tDest]\ => ibBpMsgServerMaster.tDest,
    \ibBpMsgServerMaster[tId]\ => ibBpMsgServerMaster.tId,
    \ibBpMsgServerMaster[tUser]\ => ibBpMsgServerMaster.tUser,
    \ibBpMsgServerSlave[tReady]\ => ibBpMsgServerSlave.tReady,
    \obAppDebugMaster[tValid]\ => obAppDebugMaster.tValid,
    \obAppDebugMaster[tData]\ => obAppDebugMaster.tData,
    \obAppDebugMaster[tStrb]\ => obAppDebugMaster.tStrb,
    \obAppDebugMaster[tKeep]\ => obAppDebugMaster.tKeep,
    \obAppDebugMaster[tLast]\ => obAppDebugMaster.tLast,
    \obAppDebugMaster[tDest]\ => obAppDebugMaster.tDest,
    \obAppDebugMaster[tId]\ => obAppDebugMaster.tId,
    \obAppDebugMaster[tUser]\ => obAppDebugMaster.tUser,
    \obAppDebugSlave[tReady]\ => obAppDebugSlave.tReady,
    \ibAppDebugMaster[tValid]\ => ibAppDebugMaster.tValid,
    \ibAppDebugMaster[tData]\ => ibAppDebugMaster.tData,
    \ibAppDebugMaster[tStrb]\ => ibAppDebugMaster.tStrb,
    \ibAppDebugMaster[tKeep]\ => ibAppDebugMaster.tKeep,
    \ibAppDebugMaster[tLast]\ => ibAppDebugMaster.tLast,
    \ibAppDebugMaster[tDest]\ => ibAppDebugMaster.tDest,
    \ibAppDebugMaster[tId]\ => ibAppDebugMaster.tId,
    \ibAppDebugMaster[tUser]\ => ibAppDebugMaster.tUser,
    \ibAppDebugSlave[tReady]\ => ibAppDebugSlave.tReady,
    recTimingClk => recTimingClk,
    recTimingRst => recTimingRst,
    ref156MHzClk => ref156MHzClk,
    ref156MHzRst => ref156MHzRst,
    gthFabClk => gthFabClk,
    \axilReadMasters[1][araddr]\ => axilReadMasters(1).araddr,
    \axilReadMasters[1][arprot]\ => axilReadMasters(1).arprot,
    \axilReadMasters[1][arvalid]\ => axilReadMasters(1).arvalid,
    \axilReadMasters[1][rready]\ => axilReadMasters(1).rready,
    \axilReadMasters[0][araddr]\ => axilReadMasters(0).araddr,
    \axilReadMasters[0][arprot]\ => axilReadMasters(0).arprot,
    \axilReadMasters[0][arvalid]\ => axilReadMasters(0).arvalid,
    \axilReadMasters[0][rready]\ => axilReadMasters(0).rready,
    \axilReadSlaves[1][arready]\ => axilReadSlaves(1).arready,
    \axilReadSlaves[1][rdata]\ => axilReadSlaves(1).rdata,
    \axilReadSlaves[1][rresp]\ => axilReadSlaves(1).rresp,
    \axilReadSlaves[1][rvalid]\ => axilReadSlaves(1).rvalid,
    \axilReadSlaves[0][arready]\ => axilReadSlaves(0).arready,
    \axilReadSlaves[0][rdata]\ => axilReadSlaves(0).rdata,
    \axilReadSlaves[0][rresp]\ => axilReadSlaves(0).rresp,
    \axilReadSlaves[0][rvalid]\ => axilReadSlaves(0).rvalid,
    \axilWriteMasters[1][awaddr]\ => axilWriteMasters(1).awaddr,
    \axilWriteMasters[1][awprot]\ => axilWriteMasters(1).awprot,
    \axilWriteMasters[1][awvalid]\ => axilWriteMasters(1).awvalid,
    \axilWriteMasters[1][wdata]\ => axilWriteMasters(1).wdata,
    \axilWriteMasters[1][wstrb]\ => axilWriteMasters(1).wstrb,
    \axilWriteMasters[1][wvalid]\ => axilWriteMasters(1).wvalid,
    \axilWriteMasters[1][bready]\ => axilWriteMasters(1).bready,
    \axilWriteMasters[0][awaddr]\ => axilWriteMasters(0).awaddr,
    \axilWriteMasters[0][awprot]\ => axilWriteMasters(0).awprot,
    \axilWriteMasters[0][awvalid]\ => axilWriteMasters(0).awvalid,
    \axilWriteMasters[0][wdata]\ => axilWriteMasters(0).wdata,
    \axilWriteMasters[0][wstrb]\ => axilWriteMasters(0).wstrb,
    \axilWriteMasters[0][wvalid]\ => axilWriteMasters(0).wvalid,
    \axilWriteMasters[0][bready]\ => axilWriteMasters(0).bready,
    \axilWriteSlaves[1][awready]\ => axilWriteSlaves(1).awready,
    \axilWriteSlaves[1][wready]\ => axilWriteSlaves(1).wready,
    \axilWriteSlaves[1][bresp]\ => axilWriteSlaves(1).bresp,
    \axilWriteSlaves[1][bvalid]\ => axilWriteSlaves(1).bvalid,
    \axilWriteSlaves[0][awready]\ => axilWriteSlaves(0).awready,
    \axilWriteSlaves[0][wready]\ => axilWriteSlaves(0).wready,
    \axilWriteSlaves[0][bresp]\ => axilWriteSlaves(0).bresp,
    \axilWriteSlaves[0][bvalid]\ => axilWriteSlaves(0).bvalid,
    \ethReadMaster[araddr]\ => ethReadMaster.araddr,
    \ethReadMaster[arprot]\ => ethReadMaster.arprot,
    \ethReadMaster[arvalid]\ => ethReadMaster.arvalid,
    \ethReadMaster[rready]\ => ethReadMaster.rready,
    \ethReadSlave[arready]\ => ethReadSlave.arready,
    \ethReadSlave[rdata]\ => ethReadSlave.rdata,
    \ethReadSlave[rresp]\ => ethReadSlave.rresp,
    \ethReadSlave[rvalid]\ => ethReadSlave.rvalid,
    \ethWriteMaster[awaddr]\ => ethWriteMaster.awaddr,
    \ethWriteMaster[awprot]\ => ethWriteMaster.awprot,
    \ethWriteMaster[awvalid]\ => ethWriteMaster.awvalid,
    \ethWriteMaster[wdata]\ => ethWriteMaster.wdata,
    \ethWriteMaster[wstrb]\ => ethWriteMaster.wstrb,
    \ethWriteMaster[wvalid]\ => ethWriteMaster.wvalid,
    \ethWriteMaster[bready]\ => ethWriteMaster.bready,
    \ethWriteSlave[awready]\ => ethWriteSlave.awready,
    \ethWriteSlave[wready]\ => ethWriteSlave.wready,
    \ethWriteSlave[bresp]\ => ethWriteSlave.bresp,
    \ethWriteSlave[bvalid]\ => ethWriteSlave.bvalid,
    localMac => localMac,
    localIp => localIp,
    ethLinkUp => ethLinkUp,
    \timingReadMaster[araddr]\ => timingReadMaster.araddr,
    \timingReadMaster[arprot]\ => timingReadMaster.arprot,
    \timingReadMaster[arvalid]\ => timingReadMaster.arvalid,
    \timingReadMaster[rready]\ => timingReadMaster.rready,
    \timingReadSlave[arready]\ => timingReadSlave.arready,
    \timingReadSlave[rdata]\ => timingReadSlave.rdata,
    \timingReadSlave[rresp]\ => timingReadSlave.rresp,
    \timingReadSlave[rvalid]\ => timingReadSlave.rvalid,
    \timingWriteMaster[awaddr]\ => timingWriteMaster.awaddr,
    \timingWriteMaster[awprot]\ => timingWriteMaster.awprot,
    \timingWriteMaster[awvalid]\ => timingWriteMaster.awvalid,
    \timingWriteMaster[wdata]\ => timingWriteMaster.wdata,
    \timingWriteMaster[wstrb]\ => timingWriteMaster.wstrb,
    \timingWriteMaster[wvalid]\ => timingWriteMaster.wvalid,
    \timingWriteMaster[bready]\ => timingWriteMaster.bready,
    \timingWriteSlave[awready]\ => timingWriteSlave.awready,
    \timingWriteSlave[wready]\ => timingWriteSlave.wready,
    \timingWriteSlave[bresp]\ => timingWriteSlave.bresp,
    \timingWriteSlave[bvalid]\ => timingWriteSlave.bvalid,
    \bsaReadMaster[araddr]\ => bsaReadMaster.araddr,
    \bsaReadMaster[arprot]\ => bsaReadMaster.arprot,
    \bsaReadMaster[arvalid]\ => bsaReadMaster.arvalid,
    \bsaReadMaster[rready]\ => bsaReadMaster.rready,
    \bsaReadSlave[arready]\ => bsaReadSlave.arready,
    \bsaReadSlave[rdata]\ => bsaReadSlave.rdata,
    \bsaReadSlave[rresp]\ => bsaReadSlave.rresp,
    \bsaReadSlave[rvalid]\ => bsaReadSlave.rvalid,
    \bsaWriteMaster[awaddr]\ => bsaWriteMaster.awaddr,
    \bsaWriteMaster[awprot]\ => bsaWriteMaster.awprot,
    \bsaWriteMaster[awvalid]\ => bsaWriteMaster.awvalid,
    \bsaWriteMaster[wdata]\ => bsaWriteMaster.wdata,
    \bsaWriteMaster[wstrb]\ => bsaWriteMaster.wstrb,
    \bsaWriteMaster[wvalid]\ => bsaWriteMaster.wvalid,
    \bsaWriteMaster[bready]\ => bsaWriteMaster.bready,
    \bsaWriteSlave[awready]\ => bsaWriteSlave.awready,
    \bsaWriteSlave[wready]\ => bsaWriteSlave.wready,
    \bsaWriteSlave[bresp]\ => bsaWriteSlave.bresp,
    \bsaWriteSlave[bvalid]\ => bsaWriteSlave.bvalid,
    \ddrReadMaster[araddr]\ => ddrReadMaster.araddr,
    \ddrReadMaster[arprot]\ => ddrReadMaster.arprot,
    \ddrReadMaster[arvalid]\ => ddrReadMaster.arvalid,
    \ddrReadMaster[rready]\ => ddrReadMaster.rready,
    \ddrReadSlave[arready]\ => ddrReadSlave.arready,
    \ddrReadSlave[rdata]\ => ddrReadSlave.rdata,
    \ddrReadSlave[rresp]\ => ddrReadSlave.rresp,
    \ddrReadSlave[rvalid]\ => ddrReadSlave.rvalid,
    \ddrWriteMaster[awaddr]\ => ddrWriteMaster.awaddr,
    \ddrWriteMaster[awprot]\ => ddrWriteMaster.awprot,
    \ddrWriteMaster[awvalid]\ => ddrWriteMaster.awvalid,
    \ddrWriteMaster[wdata]\ => ddrWriteMaster.wdata,
    \ddrWriteMaster[wstrb]\ => ddrWriteMaster.wstrb,
    \ddrWriteMaster[wvalid]\ => ddrWriteMaster.wvalid,
    \ddrWriteMaster[bready]\ => ddrWriteMaster.bready,
    \ddrWriteSlave[awready]\ => ddrWriteSlave.awready,
    \ddrWriteSlave[wready]\ => ddrWriteSlave.wready,
    \ddrWriteSlave[bresp]\ => ddrWriteSlave.bresp,
    \ddrWriteSlave[bvalid]\ => ddrWriteSlave.bvalid,
    ddrMemReady => ddrMemReady,
    ddrMemError => ddrMemError,
    fabClkP => fabClkP,
    fabClkN => fabClkN,
    xauiRxP => xauiRxP,
    xauiRxN => xauiRxN,
    xauiTxP => xauiTxP,
    xauiTxN => xauiTxN,
    xauiClkP => xauiClkP,
    xauiClkN => xauiClkN,
    timingRxP => timingRxP,
    timingRxN => timingRxN,
    timingTxP => timingTxP,
    timingTxN => timingTxN,
    timingRefClkInP => timingRefClkInP,
    timingRefClkInN => timingRefClkInN,
    timingRecClkOutP => timingRecClkOutP,
    timingRecClkOutN => timingRecClkOutN,
    timingClkSel => timingClkSel,
    enAuxPwrL => enAuxPwrL,
    ddrClkP => ddrClkP,
    ddrClkN => ddrClkN,
    ddrDm => ddrDm,
    ddrDqsP => ddrDqsP,
    ddrDqsN => ddrDqsN,
    ddrDq => ddrDq,
    ddrA => ddrA,
    ddrBa => ddrBa,
    ddrCsL => ddrCsL,
    ddrOdt => ddrOdt,
    ddrCke => ddrCke,
    ddrCkP => ddrCkP,
    ddrCkN => ddrCkN,
    ddrWeL => ddrWeL,
    ddrRasL => ddrRasL,
    ddrCasL => ddrCasL,
    ddrRstL => ddrRstL,
    ddrAlertL => ddrAlertL,
    ddrPg => ddrPg,
    ddrPwrEnL => ddrPwrEnL);

end mapping;
