-------------------------------------------------------------------------------
-- File       : AmcCarrierCoreFsbl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-12-13
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
use work.AppMpsPkg.all;
use work.AmcCarrierPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierCoreFsbl is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);  -- false = Normal Operation, true = MPS message concentrator (Slot#2 only)      
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
      timingTrig           : out   TimingTrigType;      
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : in    sl;
      diagnosticRst        : in    sl;
      diagnosticBus        : in    DiagnosticBusType;
      mpsCoreReg           : out   MpsCoreRegType;  -- Async, must be synchronized
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
      rtmHsRxP             : in    sl;
      rtmHsRxN             : in    sl;
      rtmHsTxP             : out   sl;
      rtmHsTxN             : out   sl;
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
end AmcCarrierCoreFsbl;

architecture mapping of AmcCarrierCoreFsbl is

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
         APP_TYPE_G       => APP_NULL_TYPE_C,
         MPS_SLOT_G       => false,
         FSBL_G           => true)
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
         APP_TYPE_G       => APP_NULL_TYPE_C,
         MPS_SLOT_G       => false)
      port map (
         -- AXI-Lite Interface
         axilClk         => ref156MHzClk,
         axilRst         => ref156MHzRst,
         axilReadMaster  => mpsReadMaster,
         axilReadSlave   => mpsReadSlave,
         axilWriteMaster => mpsWriteMaster,
         axilWriteSlave  => mpsWriteSlave,
         mpsCoreReg      => mpsCoreReg,
         -- -- System Status
         -- bsiBus          => bsiBus,
         -- ethLinkUp       => ethLinkUp,
         -- timingClk       => timingClk,
         -- timingRst       => timingRst,
         -- timingBus       => timingBusIntf,
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
         mpsClkIn        => mpsClkIn,
         mpsClkOut       => mpsClkOut,
         mpsBusRxP       => mpsBusRxP,
         mpsBusRxN       => mpsBusRxN,
         mpsTxP          => mpsTxP,
         mpsTxN          => mpsTxN);

   -------------------
   -- AMC Carrier Core
   -------------------
   U_Core : entity work.AmcCarrierFsbl
      generic map (
         TPD_G => TPD_G)
      port map (
         -----------------------
         -- Core Ports to AppTop
         -----------------------
         -- Timing Interface (timingClk domain) 
         timingClk            => timingClk,
         timingRst            => timingRst,
         timingBusIntf        => timingBusIntf,
         timingTrig           => timingTrig,
         timingPhy            => timingPhy,
         timingPhyClk         => timingPhyClk,
         timingPhyRst         => timingPhyRst,
         timingRefClk         => timingRefClk,
         timingRefClkDiv2     => timingRefClkDiv2,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk        => diagnosticClk,
         diagnosticRst        => diagnosticRst,
         diagnosticBus        => diagnosticBus,
         --  Waveform Capture Interface (waveformClk domain)
         waveformClk          => waveformClk,
         waveformRst          => waveformRst,
         obAppWaveformMasters => obAppWaveformMasters,
         obAppWaveformSlaves  => obAppWaveformSlaves,
         ibAppWaveformMasters => ibAppWaveformMasters,
         ibAppWaveformSlaves  => ibAppWaveformSlaves,
         -- Backplane Messaging Interface  (ref156MHzClk domain)
         obBpMsgClientMaster  => obBpMsgClientMaster,
         obBpMsgClientSlave   => obBpMsgClientSlave,
         ibBpMsgClientMaster  => ibBpMsgClientMaster,
         ibBpMsgClientSlave   => ibBpMsgClientSlave,
         obBpMsgServerMaster  => obBpMsgServerMaster,
         obBpMsgServerSlave   => obBpMsgServerSlave,
         ibBpMsgServerMaster  => ibBpMsgServerMaster,
         ibBpMsgServerSlave   => ibBpMsgServerSlave,
         -- Application Debug Interface (ref156MHzClk domain)
         obAppDebugMaster     => obAppDebugMaster,
         obAppDebugSlave      => obAppDebugSlave,
         ibAppDebugMaster     => ibAppDebugMaster,
         ibAppDebugSlave      => ibAppDebugSlave,
         -- Reference Clocks and Resets
         recTimingClk         => recTimingClk,
         recTimingRst         => recTimingRst,
         ref156MHzClk         => ref156MHzClk,
         ref156MHzRst         => ref156MHzRst,
         gthFabClk            => gthFabClk,
         ------------------------         
         -- Core Ports to Wrapper
         ------------------------         
         -- AXI-Lite Master bus
         axilReadMasters      => axilReadMasters,
         axilReadSlaves       => axilReadSlaves,
         axilWriteMasters     => axilWriteMasters,
         axilWriteSlaves      => axilWriteSlaves,
         --  ETH Interface
         ethReadMaster        => ethReadMaster,
         ethReadSlave         => ethReadSlave,
         ethWriteMaster       => ethWriteMaster,
         ethWriteSlave        => ethWriteSlave,
         localMac             => localMac,
         localIp              => localIp,
         ethLinkUp            => ethLinkUp,
         --  MPS Interface
         timingReadMaster     => timingReadMaster,
         timingReadSlave      => timingReadSlave,
         timingWriteMaster    => timingWriteMaster,
         timingWriteSlave     => timingWriteSlave,
         --  BSA Interface
         bsaReadMaster        => bsaReadMaster,
         bsaReadSlave         => bsaReadSlave,
         bsaWriteMaster       => bsaWriteMaster,
         bsaWriteSlave        => bsaWriteSlave,
         --  DDR Interface
         ddrReadMaster        => ddrReadMaster,
         ddrReadSlave         => ddrReadSlave,
         ddrWriteMaster       => ddrWriteMaster,
         ddrWriteSlave        => ddrWriteSlave,
         ddrMemReady          => ddrMemReady,
         ddrMemError          => ddrMemError,
         -----------------------
         --  Top Level Interface
         -----------------------
         -- Common Fabricate Clock
         fabClkP              => fabClkP,
         fabClkN              => fabClkN,
         -- Ethernet Ports
         ethRxP               => ethRxP,
         ethRxN               => ethRxN,
         ethTxP               => ethTxP,
         ethTxN               => ethTxN,
         rtmHsRxP             => rtmHsRxP,
         rtmHsRxN             => rtmHsRxN,
         rtmHsTxP             => rtmHsTxP,
         rtmHsTxN             => rtmHsTxN,
         ethClkP              => ethClkP,
         ethClkN              => ethClkN,
         -- LCLS Timing Ports
         timingRxP            => timingRxP,
         timingRxN            => timingRxN,
         timingTxP            => timingTxP,
         timingTxN            => timingTxN,
         timingRefClkInP      => timingRefClkInP,
         timingRefClkInN      => timingRefClkInN,
         timingRecClkOutP     => timingRecClkOutP,
         timingRecClkOutN     => timingRecClkOutN,
         timingClkSel         => timingClkSel,
         -- Secondary AMC Auxiliary Power Enable Port
         enAuxPwrL            => enAuxPwrL,
         -- DDR3L SO-DIMM Ports
         ddrClkP              => ddrClkP,
         ddrClkN              => ddrClkN,
         ddrDqsP              => ddrDqsP,
         ddrDqsN              => ddrDqsN,
         ddrDm                => ddrDm,
         ddrDq                => ddrDq,
         ddrA                 => ddrA,
         ddrBa                => ddrBa,
         ddrCsL               => ddrCsL,
         ddrOdt               => ddrOdt,
         ddrCke               => ddrCke,
         ddrCkP               => ddrCkP,
         ddrCkN               => ddrCkN,
         ddrWeL               => ddrWeL,
         ddrRasL              => ddrRasL,
         ddrCasL              => ddrCasL,
         ddrRstL              => ddrRstL,
         ddrPwrEnL            => ddrPwrEnL,
         ddrPg                => ddrPg,
         ddrAlertL            => ddrAlertL);

end mapping;
