-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-09-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
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
      TPD_G               : time                := 1 ns;
      SIM_SPEEDUP_G       : boolean             := false;
      STANDALONE_TIMING_G : boolean             := false;  -- true = LCLS-I timing only
      MPS_SLOT_G          : boolean             := false;  -- true = MPS message concentrator (Slot#2 only)
      FSBL_G              : boolean             := false;  -- false = Normal Operation, true = First Stage Boot loader
      DIAGNOSTIC_SIZE_G   : positive            := 1;
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
      timingData        : out   TimingDataType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk     : in    sl;
      diagnosticRst     : in    sl;
      diagnosticMessage : in    Slv32Array(31 downto 0);
      diagnosticMasters : in    AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves  : out   AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      -- MPS Interface (mpsClk domain)
      mpsClk            : in    sl;
      mpsRst            : in    sl;
      mpsIbMaster       : in    AxiStreamMasterType;
      mpsIbSlave        : out   AxiStreamSlaveType;
      mpsObMasters      : out   AxiStreamMasterArray(14 downto 1);
      mpsObSlaves       : in    AxiStreamSlaveArray(14 downto 1);
      -- BSI Interface (bsiClk domain) 
      bsiClk            : in    sl;
      bsiRst            : in    sl;
      bsiData           : out   BsiDataType;
      -- Reference Clocks and Resets
      refTimingClk      : out   sl;
      refTimingRst      : out   sl;
      ref125MHzClk      : out   sl;
      ref125MHzRst      : out   sl;
      ref156MHzClk      : out   sl;
      ref156MHzRst      : out   sl;
      ref312MHzClk      : out   sl;
      ref312MHzRst      : out   sl;
      ref625MHzClk      : out   sl;
      ref625MHzRst      : out   sl;
      ----------------
      -- Core Ports --
      ----------------
      -- Common Fabricate Clock
      fabClkP           : in    sl;
      fabClkN           : in    sl;
      -- Backplane Ethernet Ports
      xauiRxP           : in    slv(3 downto 0);
      xauiRxN           : in    slv(3 downto 0);
      xauiTxP           : out   slv(3 downto 0);
      xauiTxN           : out   slv(3 downto 0);
      xauiClkP          : in    sl;
      xauiClkN          : in    sl;
      -- Backplane MPS Ports
      mpsClkIn          : in    sl;
      mpsClkOut         : out   sl;
      mpsBusRxP         : in    slv(14 downto 1);
      mpsBusRxN         : in    slv(14 downto 1);
      mpsBusTxP         : out   slv(14 downto 1);
      mpsBusTxN         : out   slv(14 downto 1);
      mpsTxP            : out   sl;
      mpsTxN            : out   sl;
      -- LCLS Timing Ports
      timingRxP         : in    sl;
      timingRxN         : in    sl;
      timingTxP         : out   sl;
      timingTxN         : out   sl;
      timingClkInP      : in    sl;
      timingClkInN      : in    sl;
      timingClkOutP     : out   sl;
      timingClkOutN     : out   sl;
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
end AmcCarrierCore;

architecture mapping of AmcCarrierCore is

   constant AXI_ERROR_RESP_C : slv(1 downto 0) := AXI_RESP_DECERR_C;

   signal mps125MHzClk : sl;
   signal mps125MHzRst : sl;
   signal mps312MHzClk : sl;
   signal mps312MHzRst : sl;
   signal mps625MHzClk : sl;
   signal mps625MHzRst : sl;

   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

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

   signal mpsReadMaster  : AxiLiteReadMasterType;
   signal mpsReadSlave   : AxiLiteReadSlaveType;
   signal mpsWriteMaster : AxiLiteWriteMasterType;
   signal mpsWriteSlave  : AxiLiteWriteSlaveType;

   signal obBsaMaster : AxiStreamMasterType;
   signal obBsaSlave  : AxiStreamSlaveType;
   signal ibBsaMaster : AxiStreamMasterType;
   signal ibBsaSlave  : AxiStreamSlaveType;

   signal obPromMaster : AxiStreamMasterType;
   signal obPromSlave  : AxiStreamSlaveType;
   signal ibPromMaster : AxiStreamMasterType;
   signal ibPromSlave  : AxiStreamSlaveType;

   signal localMac : slv(47 downto 0);
   signal localIp  : slv(31 downto 0);

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

   ------------------------------------
   -- 10 GigE XAUI Module (ATCA ZONE 2)
   ------------------------------------
   U_Xaui : entity work.AmcCarrierXaui
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C)
      port map (
         -- Local Configuration
         localMac         => localMac,
         localIp          => localIp,
         -- Master AXI-Lite Interface
         mAxilReadMaster  => axilReadMaster,
         mAxilReadSlave   => axilReadSlave,
         mAxilWriteMaster => axilWriteMaster,
         mAxilWriteSlave  => axilWriteSlave,
         -- AXI-Lite Interface
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => xauiReadMaster,
         axilReadSlave    => xauiReadSlave,
         axilWriteMaster  => xauiWriteMaster,
         axilWriteSlave   => xauiWriteSlave,
         -- BSA Ethernet Client Interface
         obBsaMaster      => obBsaMaster,
         obBsaSlave       => obBsaSlave,
         ibBsaMaster      => ibBsaMaster,
         ibBsaSlave       => ibBsaSlave,
         -- Boot Prom AXI Streaming Interface
         obPromMaster     => obPromMaster,
         obPromSlave      => obPromSlave,
         ibPromMaster     => ibPromMaster,
         ibPromSlave      => ibPromSlave,
         ----------------
         -- Core Ports --
         ----------------   
         -- XAUI Ports
         xauiRxP          => xauiRxP,
         xauiRxN          => xauiRxN,
         xauiTxP          => xauiTxP,
         xauiTxN          => xauiTxN,
         xauiClkP         => xauiClkP,
         xauiClkN         => xauiClkN);    

   ----------------------------------   
   -- Register Address Mapping Module
   ----------------------------------   
   U_RegMap : entity work.AmcCarrierRegMapping
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         FSBL_G           => FSBL_G)
      port map (
         -- Primary AXI-Lite Interface
         axilClk           => axilClk,
         axilRst           => axilRst,
         sAxilReadMaster   => axilReadMaster,
         sAxilReadSlave    => axilReadSlave,
         sAxilWriteMaster  => axilWriteMaster,
         sAxilWriteSlave   => axilWriteSlave,
         -- Timing AXI-Lite Interface
         timingReadMaster  => timingReadMaster,
         timingReadSlave   => timingReadSlave,
         timingWriteMaster => timingWriteMaster,
         timingWriteSlave  => timingWriteSlave,
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
         -- Boot Prom AXI Streaming Interface
         obPromMaster      => obPromMaster,
         obPromSlave       => obPromSlave,
         ibPromMaster      => ibPromMaster,
         ibPromSlave       => ibPromSlave,
         -- Local Configuration
         localMac          => localMac,
         localIp           => localIp,
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
         bsiData           => bsiData,
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
         AXI_ERROR_RESP_G    => AXI_ERROR_RESP_C,
         STANDALONE_TIMING_G => STANDALONE_TIMING_G,
         DIAGNOSTIC_SIZE_G   => DIAGNOSTIC_SIZE_G,
         DIAGNOSTIC_CONFIG_G => DIAGNOSTIC_CONFIG_G)
      port map (
         -- AXI-Lite Interface
         axilClk           => axilClk,
         axilRst           => axilRst,
         axilReadMaster    => timingReadMaster,
         axilReadSlave     => timingReadSlave,
         axilWriteMaster   => timingWriteMaster,
         axilWriteSlave    => timingWriteSlave,
         -- AXI4 Interface
         axiClk            => axiClk,
         axiRst            => axiRst,
         axiWriteMaster    => axiWriteMaster,
         axiWriteSlave     => axiWriteSlave,
         axiReadMaster     => axiReadMaster,
         axiReadSlave      => axiReadSlave,
         -- BSA Ethernet Client Interface (axilClk domain)
         obBsaMaster       => obBsaMaster,
         obBsaSlave        => obBsaSlave,
         ibBsaMaster       => ibBsaMaster,
         ibBsaSlave        => ibBsaSlave,
         ----------------------
         -- Top Level Interface
         ----------------------         
         -- Timing Interface 
         refTimingClk      => refTimingClk,
         refTimingRst      => refTimingRst,
         timingClk         => timingClk,
         timingRst         => timingRst,
         timingData        => timingData,
         -- Diagnostic Interface
         diagnosticClk     => diagnosticClk,
         diagnosticRst     => diagnosticRst,
         diagnosticMessage => diagnosticMessage,
         diagnosticMasters => diagnosticMasters,
         diagnosticSlaves  => diagnosticSlaves,
         ----------------
         -- Core Ports --
         ----------------   
         -- LCLS Timing Ports
         timingRxP         => timingRxP,
         timingRxN         => timingRxN,
         timingTxP         => timingTxP,
         timingTxN         => timingTxN,
         timingClkInP      => timingClkInP,
         timingClkInN      => timingClkInN,
         timingClkOutP     => timingClkOutP,
         timingClkOutN     => timingClkOutN,
         timingClkSel      => timingClkSel);  

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

   -----------
   -- MPS Core
   -----------
   U_Mps : entity work.AmcCarrierMps
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         MPS_SLOT_G       => MPS_SLOT_G)
      port map (
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
         ----------------------
         -- Top Level Interface
         ----------------------
         -- MPS Interface
         mpsClk          => mpsClk,
         mpsRst          => mpsRst,
         mpsIbMaster     => mpsIbMaster,
         mpsIbSlave      => mpsIbSlave,
         mpsObMasters    => mpsObMasters,
         mpsObSlaves     => mpsObSlaves,
         ----------------
         -- Core Ports --
         ----------------
         -- Backplane MPS Ports
         mpsBusRxP       => mpsBusRxP,
         mpsBusRxN       => mpsBusRxN,
         mpsBusTxP       => mpsBusTxP,
         mpsBusTxN       => mpsBusTxN,
         mpsTxP          => mpsTxP,
         mpsTxN          => mpsTxN);   

end mapping;
