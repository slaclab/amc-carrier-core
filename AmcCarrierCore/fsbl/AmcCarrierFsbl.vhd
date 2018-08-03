-------------------------------------------------------------------------------
-- File       : AmcCarrierFsbl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2018-08-03
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

entity AmcCarrierFsbl is
   generic (
      TPD_G : time := 1 ns);
   port (
      -----------------------
      -- Core Ports to AppTop
      -----------------------
      -- Timing Interface (timingClk domain) 
      timingClk            : in    sl;
      timingRst            : in    sl;
      timingBusIntf        : out   TimingBusType;
      timingPhy            : in    TimingPhyType;
      timingPhyClk         : out   sl;
      timingPhyRst         : out   sl;
      timingRefClk         : out   sl;
      timingRefClkDiv2     : out   sl;
      timingTrig           : out   TimingTrigType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : in    sl;
      diagnosticRst        : in    sl;
      diagnosticBus        : in    DiagnosticBusType;
      --  Waveform Capture Interface (waveformClk domain)
      waveformClk          : out   sl;
      waveformRst          : out   sl;
      obAppWaveformMasters : in    WaveformMasterArrayType;
      obAppWaveformSlaves  : out   WaveformSlaveArrayType;
      ibAppWaveformMasters : out   WaveformMasterArrayType;
      ibAppWaveformSlaves  : in    WaveformSlaveArrayType;
      -- Backplane Messaging Interface  (ref156MHzClk domain)
      obBpMsgClientMaster  : in    AxiStreamMasterType;
      obBpMsgClientSlave   : out   AxiStreamSlaveType;
      ibBpMsgClientMaster  : out   AxiStreamMasterType;
      ibBpMsgClientSlave   : in    AxiStreamSlaveType;
      obBpMsgServerMaster  : in    AxiStreamMasterType;
      obBpMsgServerSlave   : out   AxiStreamSlaveType;
      ibBpMsgServerMaster  : out   AxiStreamMasterType;
      ibBpMsgServerSlave   : in    AxiStreamSlaveType;
      -- Application Debug Interface (ref156MHzClk domain)
      obAppDebugMaster     : in    AxiStreamMasterType;
      obAppDebugSlave      : out   AxiStreamSlaveType;
      ibAppDebugMaster     : out   AxiStreamMasterType;
      ibAppDebugSlave      : in    AxiStreamSlaveType;
      -- Reference Clocks and Resets
      recTimingClk         : out   sl;
      recTimingRst         : out   sl;
      ref156MHzClk         : out   sl;
      ref156MHzRst         : out   sl;
      gthFabClk            : out   sl;
      ------------------------         
      -- Core Ports to Wrapper
      ------------------------         
      -- AXI-Lite Master bus
      axilReadMasters      : out   AxiLiteReadMasterArray(1 downto 0);
      axilReadSlaves       : in    AxiLiteReadSlaveArray(1 downto 0);
      axilWriteMasters     : out   AxiLiteWriteMasterArray(1 downto 0);
      axilWriteSlaves      : in    AxiLiteWriteSlaveArray(1 downto 0);
      --  ETH Interface
      ethReadMaster        : in    AxiLiteReadMasterType;
      ethReadSlave         : out   AxiLiteReadSlaveType;
      ethWriteMaster       : in    AxiLiteWriteMasterType;
      ethWriteSlave        : out   AxiLiteWriteSlaveType;
      localMac             : in    slv(47 downto 0);
      localIp              : in    slv(31 downto 0);
      ethLinkUp            : out   sl;
      --  MPS Interface
      timingReadMaster     : in    AxiLiteReadMasterType;
      timingReadSlave      : out   AxiLiteReadSlaveType;
      timingWriteMaster    : in    AxiLiteWriteMasterType;
      timingWriteSlave     : out   AxiLiteWriteSlaveType;
      --  BSA Interface
      bsaReadMaster        : in    AxiLiteReadMasterType;
      bsaReadSlave         : out   AxiLiteReadSlaveType;
      bsaWriteMaster       : in    AxiLiteWriteMasterType;
      bsaWriteSlave        : out   AxiLiteWriteSlaveType;
      --  DDR Interface
      ddrReadMaster        : in    AxiLiteReadMasterType;
      ddrReadSlave         : out   AxiLiteReadSlaveType;
      ddrWriteMaster       : in    AxiLiteWriteMasterType;
      ddrWriteSlave        : out   AxiLiteWriteSlaveType;
      ddrMemReady          : out   sl;
      ddrMemError          : out   sl;
      -----------------------
      --  Top Level Interface
      -----------------------
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
      -- Secondary AMC Auxiliary Power Enable Port
      enAuxPwrL            : out   sl;
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
      ddrPwrEnL            : out   sl);
end AmcCarrierFsbl;

architecture mapping of AmcCarrierFsbl is

   constant AXI_ERROR_RESP_C : slv(1 downto 0) := AXI_RESP_DECERR_C;

   signal axiWriteMaster : AxiWriteMasterType;
   signal axiWriteSlave  : AxiWriteSlaveType;
   signal axiReadMaster  : AxiReadMasterType;
   signal axiReadSlave   : AxiReadSlaveType;

   signal obBsaMasters : AxiStreamMasterArray(3 downto 0);
   signal obBsaSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal ibBsaMasters : AxiStreamMasterArray(3 downto 0);
   signal ibBsaSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal obTimingEthMsgMaster  : AxiStreamMasterType;
   signal obTimingEthMsgSlave   : AxiStreamSlaveType;
   signal ibTimingEthMsgMaster  : AxiStreamMasterType;
   signal ibTimingEthMsgSlave   : AxiStreamSlaveType;
   signal intTimingEthMsgMaster : AxiStreamMasterType;
   signal intTimingEthMsgSlave  : AxiStreamSlaveType;

   signal gtClk   : sl;
   signal fabClk  : sl;
   signal fabRst  : sl;
   signal axiClk  : sl;
   signal axiRst  : sl;
   signal reset   : sl;
   signal axilClk : sl;
   signal axilRst : sl;
   signal auxPwrL : sl;

begin

   -- Secondary AMC's Auxiliary Power (Default to allows active for the time being)
   -- Note: Install R1063 if you want the FPGA to control AUX power
   U_enAuxPwrL : OBUF
      port map (
         I => auxPwrL,
         O => enAuxPwrL);

   auxPwrL <= '0';

   ref156MHzClk <= axilClk;
   ref156MHzRst <= axilRst;

   waveformClk <= axiClk;
   waveformRst <= axiRst;

   --------------------------------
   -- Common Clock and Reset Module
   -------------------------------- 
   U_IBUFDS : entity work.AmcCarrierIbufGt
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
         SIM_SPEEDUP_G => false)
      port map(
         clk    => fabClk,
         rstOut => fabRst);

   U_AmcCorePll : entity work.ClockManagerUltraScale
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
         CLKFBOUT_MULT_G   => 8,
         CLKOUT0_DIVIDE_G  => 8)
      port map(
         -- Clock Input
         clkIn     => fabClk,
         rstIn     => fabRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => reset);

   -- Forcing BUFG for reset that's used everywhere      
   U_BUFG : BUFG
      port map (
         I => reset,
         O => axilRst);

   ------------------
   -- Ethernet Module
   ------------------
   U_Eth : entity work.AmcCarrierEthFsbl
      generic map (
         TPD_G => TPD_G)
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
         axilReadMaster      => ethReadMaster,
         axilReadSlave       => ethReadSlave,
         axilWriteMaster     => ethWriteMaster,
         axilWriteSlave      => ethWriteSlave,
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
         -- ETH Ports
         ethRxP              => ethRxP,
         ethRxN              => ethRxN,
         ethTxP              => ethTxP,
         ethTxN              => ethTxN,
         rtmHsRxP            => rtmHsRxP,
         rtmHsRxN            => rtmHsRxN,
         rtmHsTxP            => rtmHsTxP,
         rtmHsTxN            => rtmHsTxN,
         ethClkP             => ethClkP,
         ethClkN             => ethClkN);

   --------------
   -- Timing Core
   --------------
   U_Timing : entity work.AmcCarrierTiming
      generic map (
         TPD_G             => TPD_G,
         TIME_GEN_APP_G    => false,
         TIME_GEN_EXTREF_G => false)
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk              => axilClk,
         axilRst              => axilRst,
         axilReadMaster       => timingReadMaster,
         axilReadSlave        => timingReadSlave,
         axilWriteMaster      => timingWriteMaster,
         axilWriteSlave       => timingWriteSlave,
         -- Timing ETH MSG Interface (axilClk domain)
         obTimingEthMsgMaster => intTimingEthMsgMaster,
         obTimingEthMsgSlave  => intTimingEthMsgSlave,
         ibTimingEthMsgMaster => ibTimingEthMsgMaster,
         ibTimingEthMsgSlave  => ibTimingEthMsgSlave,
         ----------------------
         -- Top Level Interface
         ----------------------         
         -- Timing Interface 
         recTimingClk         => recTimingClk,
         recTimingRst         => recTimingRst,
         appTimingClk         => timingClk,
         appTimingRst         => timingRst,
         appTimingBus         => timingBusIntf,
         appTimingTrig        => timingTrig,
         appTimingPhy         => timingPhy,
         appTimingPhyClk      => timingPhyClk,
         appTimingPhyRst      => timingPhyRst,
         appTimingRefClk      => timingRefClk,
         appTimingRefClkDiv2  => timingRefClkDiv2,
         ----------------
         -- Core Ports --
         ----------------   
         -- LCLS Timing Ports
         timingRxP            => timingRxP,
         timingRxN            => timingRxN,
         timingTxP            => timingTxP,
         timingTxN            => timingTxN,
         timingRefClkInP      => timingRefClkInP,
         timingRefClkInN      => timingRefClkInN,
         timingRecClkOutP     => timingRecClkOutP,
         timingRecClkOutN     => timingRecClkOutN,
         timingClkSel         => timingClkSel);

   --------------
   -- BSA Core
   --------------
   U_Bsa : entity work.AmcCarrierBsa
      generic map (
         TPD_G                  => TPD_G,
         FSBL_G                 => true,
         DISABLE_BSA_G          => true,
         WAVEFORM_TDATA_BYTES_G => 4)
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
         waveformRst          => axiRst,
         obAppWaveformMasters => obAppWaveformMasters,
         obAppWaveformSlaves  => obAppWaveformSlaves,
         -- Timing ETH MSG Interface (axilClk domain)
         ibEthMsgMaster       => intTimingEthMsgMaster,
         ibEthMsgSlave        => intTimingEthMsgSlave,
         obEthMsgMaster       => obTimingEthMsgMaster,
         obEthMsgSlave        => obTimingEthMsgSlave);

   ------------------
   -- DDR Memory Core
   ------------------
   U_DdrMem : entity work.AmcCarrierDdrMem
      generic map (
         TPD_G         => TPD_G,
         FSBL_G        => true,
         SIM_SPEEDUP_G => false)
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
