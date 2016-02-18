-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : DebugRtmAmcCarrierCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-30
-- Last update: 2016-02-17
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

entity DebugRtmAmcCarrierCore is
   generic (
      TPD_G               : time                := 1 ns;   -- Simulation only parameter
      SIM_SPEEDUP_G       : boolean             := false;  -- Simulation only parameter
      SIMULATION_G        : boolean             := false;  -- Simulation only parameter
      STANDALONE_TIMING_G : boolean             := false;  -- false = Normal Operation, = LCLS-I timing only
      MPS_SLOT_G          : boolean             := false;  -- false = Normal Operation, true = MPS message concentrator (Slot#2 only)
      FSBL_G              : boolean             := false;  -- false = Normal Operation, true = First Stage Boot loader
      APP_TYPE_G          : AppType             := APP_NULL_TYPE_C;
      FFB_CLIENT_SIZE_G   : positive            := 1;
      DIAGNOSTIC_SIZE_G   : positive            := 2;
      DIAGNOSTIC_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(4));
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      -- Address Range = [0x80000000:0xFFFFFFFF]
      regClk            : in    sl;
      regRst            : in    sl;
      regReadMaster     : out   AxiLiteReadMasterType;
      regReadSlave      : in    AxiLiteReadSlaveType;
      regWriteMaster    : out   AxiLiteWriteMasterType;
      regWriteSlave     : in    AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk         : in    sl;
      timingRst         : in    sl;
      timingBus         : out   TimingBusType;
      timingPhy         : in    TimingPhyType                    := TIMING_PHY_INIT_C;  -- Input for timing generator only
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk     : in    sl;
      diagnosticRst     : in    sl;
      diagnosticBus     : in    DiagnosticBusType;
      diagnosticMasters : in    AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves  : out   AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticCtrls   : out   AxiStreamCtrlArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      -- FFB Inbound Interface (ffbClk domain)
      ffbClk            : in    sl                               := '0';
      ffbRst            : in    sl                               := '0';
      ffbBus            : out   FfbBusType;
      -- BSI Interface (bsiClk domain) 
      bsiClk            : in    sl                               := '0';
      bsiRst            : in    sl                               := '0';
      bsiBus            : out   BsiBusType;
      -- MPS Concentrator Interface (ref156MHzClk domain)
      mpsObMasters      : out   AxiStreamMasterArray(14 downto 0);
      mpsObSlaves       : in    AxiStreamSlaveArray(14 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
      -- Reference Clocks and Resets
      recTimingClk      : out   sl;
      recTimingRst      : out   sl;
      ref125MHzClk      : out   sl;
      ref125MHzRst      : out   sl;
      ref156MHzClk      : out   sl;
      ref156MHzRst      : out   sl;
      ref312MHzClk      : out   sl;
      ref312MHzRst      : out   sl;
      ref625MHzClk      : out   sl;
      ref625MHzRst      : out   sl;
      gthFabClk         : out   sl;
      ----------------
      -- Core Ports --
      ----------------
      -- Common Fabricate Clock
      fabClkP           : in    sl;
      fabClkN           : in    sl;
      -- RTM PGP Ports
      rtmPgpRxP         : in    sl;
      rtmPgpRxN         : in    sl;
      rtmPgpTxP         : out   sl;
      rtmPgpTxN         : out   sl;
      rtmPgpClkP        : in    sl;
      rtmPgpClkN        : in    sl;
      -- Backplane MPS Ports
      mpsClkIn          : in    sl;
      mpsClkOut         : out   sl;
      mpsBusRxP         : in    slv(14 downto 1);
      mpsBusRxN         : in    slv(14 downto 1);
      mpsTxP            : out   sl;
      mpsTxN            : out   sl;
      -- LCLS Timing Ports
      timingRxP         : in    sl;
      timingRxN         : in    sl;
      timingTxP         : out   sl;
      timingTxN         : out   sl;
      timingRefClkInP   : in    sl;
      timingRefClkInN   : in    sl;
      timingRecClkOutP  : out   sl;
      timingRecClkOutN  : out   sl;
      timingClkSel      : out   sl;
      timingClkScl      : inout sl;
      timingClkSda      : inout sl;
      -- Crossbar Ports
      xBarSin           : out   slv(1 downto 0);
      xBarSout          : out   slv(1 downto 0);
      xBarConfig        : out   sl;
      xBarLoad          : out   sl;
      -- Secondary AMC Auxiliary Power Enable Port
      enAuxPwrL         : out   sl;
      -- IPMC Ports
      ipmcScl           : inout sl;
      ipmcSda           : inout sl;
      -- Configuration PROM Ports
      calScl            : inout sl;
      calSda            : inout sl;
      -- DDR3L SO-DIMM Ports
      ddrClkP           : in    sl;
      ddrClkN           : in    sl;
      ddrDm             : out   slv(7 downto 0);
      ddrDqsP           : inout slv(7 downto 0);
      ddrDqsN           : inout slv(7 downto 0);
      ddrDq             : inout slv(63 downto 0);
      ddrA              : out   slv(15 downto 0);
      ddrBa             : out   slv(2 downto 0);
      ddrCsL            : out   slv(1 downto 0);
      ddrOdt            : out   slv(1 downto 0);
      ddrCke            : out   slv(1 downto 0);
      ddrCkP            : out   slv(1 downto 0);
      ddrCkN            : out   slv(1 downto 0);
      ddrWeL            : out   sl;
      ddrRasL           : out   sl;
      ddrCasL           : out   sl;
      ddrRstL           : out   sl;
      ddrAlertL         : in    sl;
      ddrPg             : in    sl;
      ddrPwrEnL         : out   sl;
      ddrScl            : inout sl;
      ddrSda            : inout sl;
      -- SYSMON Ports
      vPIn              : in    sl;
      vNIn              : in    sl);
end DebugRtmAmcCarrierCore;

architecture mapping of DebugRtmAmcCarrierCore is

   constant AXI_ERROR_RESP_C : slv(1 downto 0) := AXI_RESP_DECERR_C;

   signal mps125MHzClk : sl;
   signal mps125MHzRst : sl;
   signal mps312MHzClk : sl;
   signal mps312MHzRst : sl;
   signal mps625MHzClk : sl;
   signal mps625MHzRst : sl;

   signal axilClk          : sl;
   signal axilRst          : sl;
   signal axilReadMasters  : AxiLiteReadMasterArray(0 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(0 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(0 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(0 downto 0);

   signal axiClk         : sl;
   signal axiRst         : sl;
   signal axiWriteMaster : AxiWriteMasterType;
   signal axiWriteSlave  : AxiWriteSlaveType;
   signal axiReadMaster  : AxiReadMasterType;
   signal axiReadSlave   : AxiReadSlaveType;

   signal bsaTimingClk : sl;
   signal bsaTimingRst : sl;
   signal bsaTimingBus : TimingBusType;

   signal timingReadMaster  : AxiLiteReadMasterType;
   signal timingReadSlave   : AxiLiteReadSlaveType;
   signal timingWriteMaster : AxiLiteWriteMasterType;
   signal timingWriteSlave  : AxiLiteWriteSlaveType;

   signal bsaReadMaster  : AxiLiteReadMasterType;
   signal bsaReadSlave   : AxiLiteReadSlaveType;
   signal bsaWriteMaster : AxiLiteWriteMasterType;
   signal bsaWriteSlave  : AxiLiteWriteSlaveType;

   signal pgpReadMaster  : AxiLiteReadMasterType;
   signal pgpReadSlave   : AxiLiteReadSlaveType;
   signal pgpWriteMaster : AxiLiteWriteMasterType;
   signal pgpWriteSlave  : AxiLiteWriteSlaveType;

   signal ddrReadMaster  : AxiLiteReadMasterType;
   signal ddrReadSlave   : AxiLiteReadSlaveType;
   signal ddrWriteMaster : AxiLiteWriteMasterType;
   signal ddrWriteSlave  : AxiLiteWriteSlaveType;
   signal ddrMemReady    : sl;
   signal ddrMemError    : sl;

   signal mpsReadMaster  : AxiLiteReadMasterType;
   signal mpsReadSlave   : AxiLiteReadSlaveType;
   signal mpsWriteMaster : AxiLiteWriteMasterType;
   signal mpsWriteSlave  : AxiLiteWriteSlaveType;

   signal ffbObMaster : AxiStreamMasterType;
   signal ffbObSlave  : AxiStreamSlaveType;

   signal localMac   : slv(47 downto 0);
   signal localIp    : slv(31 downto 0);
   signal localAppId : slv(15 downto 0);

   signal masterResetPgp       : sl;
   signal masterResetAxi       : sl;
   signal rstDly               : sl;
   signal resetDDR             : sl;
   signal pgpClk               : sl;
   signal pgpRst               : sl;
   signal bufDiagnosticMasters : AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
   signal bufDiagnosticSlaves  : AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
   
begin

   -- Secondary AMC's Auxiliary Power (Default to allows active for the time being)
   -- Note: Install R1063 if you want the FPGA to control AUX power
   enAuxPwrL <= '0';

   --------------------------------
   -- Common Clock and Reset Module
   -------------------------------- 
   U_ClkAndRst : entity work.AmcCarrierClkAndRst
      generic map (
         TPD_G         => TPD_G,
         MPS_SLOT_G    => MPS_SLOT_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map (
         -- Reference Clocks and Resets
         ref125MHzClk => ref125MHzClk,
         ref125MHzRst => ref125MHzRst,
         ref156MHzClk => ref156MHzClk,
         ref156MHzRst => ref156MHzRst,
         ref312MHzClk => ref312MHzClk,
         ref312MHzRst => ref312MHzRst,
         ref625MHzClk => ref625MHzClk,
         ref625MHzRst => ref625MHzRst,
         gthFabClk    => gthFabClk,
         -- AXI-Lite Clocks and Resets
         axilClk      => axilClk,
         axilRst      => axilRst,
         -- MPS Clocks and Resets
         mps125MHzClk => mps125MHzClk,
         mps125MHzRst => mps125MHzRst,
         mps312MHzClk => mps312MHzClk,
         mps312MHzRst => mps312MHzRst,
         mps625MHzClk => mps625MHzClk,
         mps625MHzRst => mps625MHzRst,
         ----------------
         -- Core Ports --
         ----------------   
         -- Common Fabricate Clock
         fabClkP      => fabClkP,
         fabClkN      => fabClkN,
         -- Backplane MPS Ports
         mpsClkIn     => mpsClkIn,
         mpsClkOut    => mpsClkOut);

   -----------------------
   -- Debug RTM PGP Module
   -----------------------
   U_PGP : entity work.DebugRtmPgpAmcCarrier
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
         SIMULATION_G      => SIMULATION_G,
         DIAGNOSTIC_SIZE_G => DIAGNOSTIC_SIZE_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_C)
      port map (
         -- Master AXI-Lite Interface
         mAxilReadMasters  => axilReadMasters,
         mAxilReadSlaves   => axilReadSlaves,
         mAxilWriteMasters => axilWriteMasters,
         mAxilWriteSlaves  => axilWriteSlaves,
         -- AXI-Lite Interface
         axilClk           => axilClk,
         axilRst           => axilRst,
         axilReadMaster    => pgpReadMaster,
         axilReadSlave     => pgpReadSlave,
         axilWriteMaster   => pgpWriteMaster,
         axilWriteSlave    => pgpWriteSlave,
         -- Outbound FFB Interface
         ffbObMaster       => ffbObMaster,
         ffbObSlave        => ffbObSlave,
         -- Debug AXI stream Interface
         pgpClock          => pgpClk,
         pgpReset          => pgpRst,
         axisTxMasters     => bufDiagnosticMasters,
         axisTxSlaves      => bufDiagnosticSlaves,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- FFB Inbound Interface (ffbClk domain)         
         ffbClk            => ffbClk,
         ffbRst            => ffbRst,
         ffbBus            => ffbBus,
         ----------------
         -- Core Ports --
         ----------------   
         -- RTM PGP Ports
         rtmPgpRxP         => rtmPgpRxP,
         rtmPgpRxN         => rtmPgpRxN,
         rtmPgpTxP         => rtmPgpTxP,
         rtmPgpTxN         => rtmPgpTxN,
         rtmPgpClkP        => rtmPgpClkP,
         rtmPgpClkN        => rtmPgpClkN);

   ----------------------------------   
   -- Register Address Mapping Module
   ----------------------------------   
   U_RegMap : entity work.AmcCarrierRegMapping
      generic map (
         TPD_G               => TPD_G,
         AXI_ERROR_RESP_G    => AXI_ERROR_RESP_C,
         APP_TYPE_G          => APP_TYPE_G,
         STANDALONE_TIMING_G => STANDALONE_TIMING_G,
         FSBL_G              => FSBL_G)
      port map (
         -- Primary AXI-Lite Interface
         axilClk           => axilClk,
         axilRst           => axilRst,
         sAxilReadMasters  => axilReadMasters,
         sAxilReadSlaves   => axilReadSlaves,
         sAxilWriteMasters => axilWriteMasters,
         sAxilWriteSlaves  => axilWriteSlaves,
         -- Timing AXI-Lite Interface
         timingReadMaster  => timingReadMaster,
         timingReadSlave   => timingReadSlave,
         timingWriteMaster => timingWriteMaster,
         timingWriteSlave  => timingWriteSlave,
         -- BSA AXI-Lite Interface
         bsaReadMaster     => bsaReadMaster,
         bsaReadSlave      => bsaReadSlave,
         bsaWriteMaster    => bsaWriteMaster,
         bsaWriteSlave     => bsaWriteSlave,
         -- XAUI PHY AXI-Lite Interface
         xauiReadMaster    => pgpReadMaster,
         xauiReadSlave     => pgpReadSlave,
         xauiWriteMaster   => pgpWriteMaster,
         xauiWriteSlave    => pgpWriteSlave,
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
         localAppId        => localAppId,
         -- Misc.
         debugReset        => masterResetPgp,
         ----------------------
         -- Top Level Interface
         ----------------------              
         -- Application AXI-Lite Interface
         regClk            => regClk,
         regRst            => regRst,
         regReadMaster     => regReadMaster,
         regReadSlave      => regReadSlave,
         regWriteMaster    => regWriteMaster,
         regWriteSlave     => regWriteSlave,
         -- BSI Interface
         bsiClk            => bsiClk,
         bsiRst            => bsiRst,
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

   --------------
   -- Timing Core
   --------------
   U_Timing : entity work.AmcCarrierTiming
      generic map (
         TPD_G               => TPD_G,
         APP_TYPE_G          => APP_TYPE_G,
         AXI_ERROR_RESP_G    => AXI_ERROR_RESP_C,
         STANDALONE_TIMING_G => STANDALONE_TIMING_G)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => timingReadMaster,
         axilReadSlave    => timingReadSlave,
         axilWriteMaster  => timingWriteMaster,
         axilWriteSlave   => timingWriteSlave,
         -- BSA Interface (bsaTimingClk domain)
         bsaTimingClk     => bsaTimingClk,
         bsaTimingRst     => bsaTimingRst,
         bsaTimingBus     => bsaTimingBus,
         ----------------------
         -- Top Level Interface
         ----------------------         
         -- Timing Interface 
         recTimingClk     => recTimingClk,
         recTimingRst     => recTimingRst,
         appTimingClk     => timingClk,
         appTimingRst     => timingRst,
         appTimingBus     => timingBus,
         appTimingPhy     => timingPhy,
         ----------------
         -- Core Ports --
         ----------------   
         -- LCLS Timing Ports
         timingRxP        => timingRxP,
         timingRxN        => timingRxN,
         timingTxP        => timingTxP,
         timingTxN        => timingTxN,
         timingRefClkInP  => timingRefClkInP,
         timingRefClkInN  => timingRefClkInN,
         timingRecClkOutP => timingRecClkOutP,
         timingRecClkOutN => timingRecClkOutN,
         timingClkSel     => timingClkSel);

   ------------------
   -- DDR FIFO Module
   ------------------
   U_AdcDdrFifo : entity work.DebugAmcAdcDdrFifo
      generic map (
         TPD_G              => TPD_G,
         L_AXI_G            => DIAGNOSTIC_SIZE_G,
         INPUT_AXI_CONFIG_G => DIAGNOSTIC_CONFIG_G)
      port map (
         sAxisClk       => diagnosticClk,
         sAxisRst       => diagnosticRst,
         sAxisMaster    => diagnosticMasters,
         sAxisSlave     => diagnosticSlaves,
         sAxisCtrl      => diagnosticCtrls,
         axiClk         => axiClk,
         axiRst         => resetDDR,    -- axiRst
         axiWriteMaster => axiWriteMaster,
         axiWriteSlave  => axiWriteSlave,
         axiReadMaster  => axiReadMaster,
         axiReadSlave   => axiReadSlave,
         mAxisClk       => pgpClk,
         mAxisRst       => pgpRst,
         mAxisMaster    => bufDiagnosticMasters,
         mAxisSlave     => bufDiagnosticSlaves);   

   -- Note: This is a work around. Not to be used in final version nor production! TODO Remove FIX ME ! 
   -- Reset DDR FIFO before requesting next transaction.
   -- Master reset from AxiVersion is used for this purpose.
   U_RstSync : entity work.RstSync
      generic map (
         TPD_G           => TPD_G,
         RELEASE_DELAY_G => 16)
      port map (
         clk      => axiClk,
         asyncRst => masterResetPgp,
         syncRst  => masterResetAxi);

   process(axiClk)
   begin
      if rising_edge(axiClk) then
         rstDly   <= masterResetAxi or axiRst after TPD_G;  -- Register to help with timing
         resetDDR <= rstDly                   after TPD_G;  -- Register to help with timing
      end if;
   end process;

   ------------------
   -- DDR Memory Core
   ------------------
   U_DdrMem : entity work.DebugRtmPgpAmcCarrierDdrMem
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         FSBL_G           => FSBL_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => ddrReadMaster,
         axilReadSlave   => ddrReadSlave,
         axilWriteMaster => ddrWriteMaster,
         axilWriteSlave  => ddrWriteSlave,
         memReady        => ddrMemReady,
         memError        => ddrMemError,
         -- AXI4 Interface
         axiClk          => axiClk,
         axiRst          => axiRst,
         axiWriteMaster  => axiWriteMaster,
         axiWriteSlave   => axiWriteSlave,
         axiReadMaster   => axiReadMaster,
         axiReadSlave    => axiReadSlave,
         ----------------
         -- Core Ports --
         ----------------   
         -- DDR3L SO-DIMM Ports
         ddrClkP         => ddrClkP,
         ddrClkN         => ddrClkN,
         ddrDqsP         => ddrDqsP,
         ddrDqsN         => ddrDqsN,
         ddrDm           => ddrDm,
         ddrDq           => ddrDq,
         ddrA            => ddrA,
         ddrBa           => ddrBa,
         ddrCsL          => ddrCsL,
         ddrOdt          => ddrOdt,
         ddrCke          => ddrCke,
         ddrCkP          => ddrCkP,
         ddrCkN          => ddrCkN,
         ddrWeL          => ddrWeL,
         ddrRasL         => ddrRasL,
         ddrCasL         => ddrCasL,
         ddrRstL         => ddrRstL,
         ddrPwrEnL       => ddrPwrEnL,
         ddrPg           => ddrPg,
         ddrAlertL       => ddrAlertL);

   -------------------
   -- MPS and FFB Core
   -------------------
   U_MpsandFfb : entity work.AmcCarrierMpsAndFfb
      generic map (
         TPD_G            => TPD_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         MPS_SLOT_G       => MPS_SLOT_G)
      port map (
         -- Local Configuration
         localAppId      => localAppId,
         -- MPS Clocks and Resets
         mps125MHzClk    => mps125MHzClk,
         mps125MHzRst    => mps125MHzRst,
         mps312MHzClk    => mps312MHzClk,
         mps312MHzRst    => mps312MHzRst,
         mps625MHzClk    => mps625MHzClk,
         mps625MHzRst    => mps625MHzRst,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => mpsReadMaster,
         axilReadSlave   => mpsReadSlave,
         axilWriteMaster => mpsWriteMaster,
         axilWriteSlave  => mpsWriteSlave,
         -- FFB Interface
         ffbObMaster     => ffbObMaster,
         ffbObSlave      => ffbObSlave,
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
         mpsBusRxP       => mpsBusRxP,
         mpsBusRxN       => mpsBusRxN,
         mpsTxP          => mpsTxP,
         mpsTxN          => mpsTxN);

end mapping;
