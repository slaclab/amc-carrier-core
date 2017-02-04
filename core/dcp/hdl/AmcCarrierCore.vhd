-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2017-02-03
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

entity AmcCarrierCore is
   generic (
      TPD_G             : time    := 1 ns;
      SIM_SPEEDUP_G     : boolean := false;  -- false = Normal Operation, true = simulation
      DISABLE_BSA_G     : boolean := false;  -- false = includes BSA engine, true = doesn't build the BSA engine
      TIME_GEN_APP_G    : boolean := false;  -- false = normal application, true = timing generator application
      TIME_GEN_EXTREF_G : boolean := false;  -- false = normal application, true = timing generator using external reference
      FSBL_G            : boolean := false);  -- false = Normal Operation, true = First Stage Boot loader
   port (
      ----------------------
      -- Core Ports to Application
      ----------------------
      -- AXI-Lite Interface (ref156MHzClk domain)
      -- Address Range = [0x80000000:0xFFFFFFFF]
      regReadMaster        : out   AxiLiteReadMasterType;
      regReadSlave         : in    AxiLiteReadSlaveType;
      regWriteMaster       : out   AxiLiteWriteMasterType;
      regWriteSlave        : in    AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk            : in    sl;
      timingRst            : in    sl;
      timingBus            : out   TimingBusType;
      timingPhy            : in    TimingPhyType           := TIMING_PHY_INIT_C;  -- Input for timing generator only
      timingPhyClk         : out   sl;
      timingPhyRst         : out   sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : in    sl;
      diagnosticRst        : in    sl;
      diagnosticBus        : in    DiagnosticBusType;
      --  Waveform interface (waveformClk domain)
      waveformClk          : out   sl;
      waveformRst          : out   sl;
      obAppWaveformMasters : in    WaveformMasterArrayType := WAVEFORM_MASTER_ARRAY_INIT_C;
      obAppWaveformSlaves  : out   WaveformSlaveArrayType;
      ibAppWaveformMasters : out   WaveformMasterArrayType;
      ibAppWaveformSlaves  : in    WaveformSlaveArrayType  := WAVEFORM_SLAVE_ARRAY_INIT_C;
      -- Backplane Messaging Interface  (ref156MHzClk domain)
      obBpMsgClientMaster  : in    AxiStreamMasterType     := AXI_STREAM_MASTER_INIT_C;
      obBpMsgClientSlave   : out   AxiStreamSlaveType;
      ibBpMsgClientMaster  : out   AxiStreamMasterType;
      ibBpMsgClientSlave   : in    AxiStreamSlaveType      := AXI_STREAM_SLAVE_FORCE_C;
      obBpMsgServerMaster  : in    AxiStreamMasterType     := AXI_STREAM_MASTER_INIT_C;
      obBpMsgServerSlave   : out   AxiStreamSlaveType;
      ibBpMsgServerMaster  : out   AxiStreamMasterType;
      ibBpMsgServerSlave   : in    AxiStreamSlaveType      := AXI_STREAM_SLAVE_FORCE_C;
      -- Application Debug Interface (ref156MHzClk domain)
      obAppDebugMaster     : in    AxiStreamMasterType     := AXI_STREAM_MASTER_INIT_C;
      obAppDebugSlave      : out   AxiStreamSlaveType;
      ibAppDebugMaster     : out   AxiStreamMasterType;
      ibAppDebugSlave      : in    AxiStreamSlaveType      := AXI_STREAM_SLAVE_FORCE_C;
      -- BSI Interface  (ref156MHzClk domain)
      bsiBus               : out   BsiBusType;
      ethPhyReady          : out   sl;
      -- Reference Clocks and Resets
      recTimingClk         : out   sl;
      recTimingRst         : out   sl;
      ref156MHzClk         : out   sl;
      ref156MHzRst         : out   sl;
      gthFabClk            : out   sl;
      -----------------
      --  MPS Interface
      -----------------
      mpsReadMaster        : out   AxiLiteReadMasterType;
      mpsReadSlave         : in    AxiLiteReadSlaveType;
      mpsWriteMaster       : out   AxiLiteWriteMasterType;
      mpsWriteSlave        : in    AxiLiteWriteSlaveType;
      -----------------------
      --  Top Level Interface
      -----------------------
      -- Common Fabricate Clock
      fabClkP              : in    sl;
      fabClkN              : in    sl;
      -- Backplane Ethernet Ports
      xauiRxP              : in    slv(3 downto 0);
      xauiRxN              : in    slv(3 downto 0);
      xauiTxP              : out   slv(3 downto 0);
      xauiTxN              : out   slv(3 downto 0);
      xauiClkP             : in    sl;
      xauiClkN             : in    sl;
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
end AmcCarrierCore;

architecture mapping of AmcCarrierCore is

   constant AXI_ERROR_RESP_C : slv(1 downto 0) := AXI_RESP_DECERR_C;

   signal axilClk          : sl;
   signal axilRst          : sl;
   signal axilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);

   signal axiClk         : sl;
   signal axiRst         : sl;
   signal axiWriteMaster : AxiWriteMasterType;
   signal axiWriteSlave  : AxiWriteSlaveType;
   signal axiReadMaster  : AxiReadMasterType;
   signal axiReadSlave   : AxiReadSlaveType;

   signal timingReadMaster  : AxiLiteReadMasterType;
   signal timingReadSlave   : AxiLiteReadSlaveType;
   signal timingWriteMaster : AxiLiteWriteMasterType;
   signal timingWriteSlave  : AxiLiteWriteSlaveType;

   signal bsaReadMaster  : AxiLiteReadMasterType;
   signal bsaReadSlave   : AxiLiteReadSlaveType;
   signal bsaWriteMaster : AxiLiteWriteMasterType;
   signal bsaWriteSlave  : AxiLiteWriteSlaveType;

   signal xauiReadMaster  : AxiLiteReadMasterType;
   signal xauiReadSlave   : AxiLiteReadSlaveType;
   signal xauiWriteMaster : AxiLiteWriteMasterType;
   signal xauiWriteSlave  : AxiLiteWriteSlaveType;

   signal ddrReadMaster  : AxiLiteReadMasterType;
   signal ddrReadSlave   : AxiLiteReadSlaveType;
   signal ddrWriteMaster : AxiLiteWriteMasterType;
   signal ddrWriteSlave  : AxiLiteWriteSlaveType;
   signal ddrMemReady    : sl;
   signal ddrMemError    : sl;

   signal obBsaMasters : AxiStreamMasterArray(3 downto 0);
   signal obBsaSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal ibBsaMasters : AxiStreamMasterArray(3 downto 0);
   signal ibBsaSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal localMac  : slv(47 downto 0);
   signal localIp   : slv(31 downto 0);
   signal ethLinkUp : sl;
   signal gtClk     : sl;
   signal fabClk    : sl;
   signal fabRst    : sl;

begin

   -- Secondary AMC's Auxiliary Power (Default to allows active for the time being)
   -- Note: Install R1063 if you want the FPGA to control AUX power
   enAuxPwrL <= '0' when(FSBL_G = false) else '1';

   ref156MHzRst <= axilRst;
   ref156MHzClk <= axilClk;
   waveformClk  <= axiClk;
   waveformRst  <= axiRst;
   ethPhyReady  <= ethLinkUp;

   --------------------------------
   -- Common Clock and Reset Module
   -------------------------------- 
   U_IBUFDS : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => fabClkP,
         IB    => fabClkN,
         CEB   => '0',
         ODIV2 => gtClk,
         O     => gthFabClk);

   U_BUFG_GT : BUFG_GT
      port map (
         I       => gtClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => fabClk);

   U_PwrUpRst : entity work.PwrUpRst
      generic map(
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map(
         clk    => fabClk,
         rstOut => fabRst);

   U_Pll : entity work.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => true,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         BANDWIDTH_G       => "OPTIMIZED",
         CLKIN_PERIOD_G    => 6.4,
         DIVCLK_DIVIDE_G   => 1,
         CLKFBOUT_MULT_G   => 4,
         CLKOUT0_DIVIDE_G  => 4)
      port map(
         -- Clock Input
         clkIn     => fabClk,
         rstIn     => fabRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   ------------------
   -- Ethernet Module
   ------------------
   U_Eth : entity work.AmcCarrierEth
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C)
      port map (
         -- Local Configuration
         localMac            => localMac,
         localIp             => localIp,
         ethPhyReady         => ethLinkUp,
         -- Master AXI-Lite Interface
         mAxilReadMasters    => axilReadMasters,
         mAxilReadSlaves     => axilReadSlaves,
         mAxilWriteMasters   => axilWriteMasters,
         mAxilWriteSlaves    => axilWriteSlaves,
         -- AXI-Lite Interface
         axilClk             => axilClk,
         axilRst             => axilRst,
         axilReadMaster      => xauiReadMaster,
         axilReadSlave       => xauiReadSlave,
         axilWriteMaster     => xauiWriteMaster,
         axilWriteSlave      => xauiWriteSlave,
         -- BSA Ethernet Interface
         obBsaMasters        => obBsaMasters,
         obBsaSlaves         => obBsaSlaves,
         ibBsaMasters        => ibBsaMasters,
         ibBsaSlaves         => ibBsaSlaves,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- Application Debug Interface
         obAppDebugMaster    => obAppDebugMaster,
         obAppDebugSlave     => obAppDebugSlave,
         ibAppDebugMaster    => ibAppDebugMaster,
         ibAppDebugSlave     => ibAppDebugSlave,
         -- Backplane Messaging Interface
         obBpMsgClientMaster => obBpMsgClientMaster,
         obBpMsgClientSlave  => obBpMsgClientSlave,
         ibBpMsgClientMaster => ibBpMsgClientMaster,
         ibBpMsgClientSlave  => ibBpMsgClientSlave,
         obBpMsgServerMaster => obBpMsgServerMaster,
         obBpMsgServerSlave  => obBpMsgServerSlave,
         ibBpMsgServerMaster => ibBpMsgServerMaster,
         ibBpMsgServerSlave  => ibBpMsgServerSlave,
         ----------------
         -- Core Ports --
         ----------------   
         -- XAUI Ports
         xauiRxP             => xauiRxP,
         xauiRxN             => xauiRxN,
         xauiTxP             => xauiTxP,
         xauiTxN             => xauiTxN,
         xauiClkP            => xauiClkP,
         xauiClkN            => xauiClkN);

   ----------------------------------   
   -- System Register Address Mapping
   ----------------------------------   
   U_SysReg : entity work.AmcCarrierSysReg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         FSBL_G           => FSBL_G)
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
         -- Bsa AXI-Lite Interface
         bsaReadMaster     => bsaReadMaster,
         bsaReadSlave      => bsaReadSlave,
         bsaWriteMaster    => bsaWriteMaster,
         bsaWriteSlave     => bsaWriteSlave,
         -- XAUI PHY AXI-Lite Interface
         xauiReadMaster    => xauiReadMaster,
         xauiReadSlave     => xauiReadSlave,
         xauiWriteMaster   => xauiWriteMaster,
         xauiWriteSlave    => xauiWriteSlave,
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
         regReadMaster     => regReadMaster,
         regReadSlave      => regReadSlave,
         regWriteMaster    => regWriteMaster,
         regWriteSlave     => regWriteSlave,
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

   --------------
   -- Timing Core
   --------------
   U_Timing : entity work.AmcCarrierTiming
      generic map (
         TPD_G             => TPD_G,
         TIME_GEN_APP_G    => TIME_GEN_APP_G,
         TIME_GEN_EXTREF_G => TIME_GEN_EXTREF_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_C)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => timingReadMaster,
         axilReadSlave    => timingReadSlave,
         axilWriteMaster  => timingWriteMaster,
         axilWriteSlave   => timingWriteSlave,
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
         appTimingPhyClk  => timingPhyClk,
         appTimingPhyRst  => timingPhyRst,
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

   --------------
   -- BSA Core
   --------------
   U_Bsa : entity work.AmcCarrierBsa
      generic map (
         TPD_G            => TPD_G,
         FSBL_G           => FSBL_G,
         DISABLE_BSA_G    => DISABLE_BSA_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk              => axilClk,
         axilRst              => axilRst,
         axilReadMaster       => bsaReadMaster,
         axilReadSlave        => bsaReadSlave,
         axilWriteMaster      => bsaWriteMaster,
         axilWriteSlave       => bsaWriteSlave,
         -- AXI4 Interface (axiClk domain)
         axiClk               => axiClk,
         axiRst               => axiRst,
         axiWriteMaster       => axiWriteMaster,
         axiWriteSlave        => axiWriteSlave,
         axiReadMaster        => axiReadMaster,
         axiReadSlave         => axiReadSlave,
         -- Ethernet Interface (axilClk domain)
         obBsaMasters         => obBsaMasters,
         obBsaSlaves          => obBsaSlaves,
         ibBsaMasters         => ibBsaMasters,
         ibBsaSlaves          => ibBsaSlaves,
         ----------------------
         -- Top Level Interface
         ----------------------         
         -- Diagnostic Interface
         diagnosticClk        => diagnosticClk,
         diagnosticRst        => diagnosticRst,
         diagnosticBus        => diagnosticBus,
         -- Waveform interface (axiClk domain)
         waveformClk          => axiClk,
         waveformRst          => axiClk,
         obAppWaveformMasters => obAppWaveformMasters,
         obAppWaveformSlaves  => obAppWaveformSlaves);

   ------------------
   -- DDR Memory Core
   ------------------
   U_DdrMem : entity work.AmcCarrierDdrMem
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

end mapping;
