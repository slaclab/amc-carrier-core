-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-08-04
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
use work.AxiLitePkg.all;
use work.LclsTimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierCore is
   generic (
      TPD_G               : time    := 1 ns;
      STANDALONE_TIMING_G : boolean := true;    -- true = LCLS-I timing only
      EXT_MEM_G           : boolean := true;
      SIM_SPEEDUP_G       : boolean := false;
      FSBL_G              : boolean := false);  -- true = First Stage Boot loader, false = Normal Operation
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      -- Address Range = [0x80000000:0xFFFFFFFF]
      regClk            : in    sl;
      regRst            : in    sl;
      regAxiReadMaster  : out   AxiLiteReadMasterType;
      regAxiReadSlave   : in    AxiLiteReadSlaveType;
      regAxiWriteMaster : out   AxiLiteWriteMasterType;
      regAxiWriteSlave  : in    AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk         : in    sl;
      timingRst         : in    sl;
      timingData        : out   LclsTimingDataType;
      -- Diagnostic Snapshot (debugClk domain)
      debugClk          : in    sl;
      debugRst          : in    sl;
      debugIbMaster     : in    AxiStreamMasterType;
      debugIbSlave      : out   AxiStreamSlaveType;
      -- Beam Synchronization (bsaClk domain)
      bsaClk            : in    sl;
      bsaRst            : in    sl;
      bsaIbMaster       : in    AxiStreamMasterType;
      bsaIbSlave        : out   AxiStreamSlaveType;
      -- Support Reference Clocks and Resets
      refTimingClk      : out   sl;
      ref100MHzClk      : out   sl;
      ref100MHzRst      : out   sl;
      ref125MHzClk      : out   sl;
      ref125MHzRst      : out   sl;
      ref156MHzClk      : out   sl;
      ref156MHzRst      : out   sl;
      ref200MHzClk      : out   sl;
      ref200MHzRst      : out   sl;
      ref250MHzClk      : out   sl;
      ref250MHzRst      : out   sl;
      ----------------
      -- Core Ports --
      ----------------
      -- Common Fabricate Clock
      fabClkP           : in    sl;
      fabClkN           : in    sl;
      -- XAUI Ports
      xauiRxP           : in    slv(3 downto 0);
      xauiRxN           : in    slv(3 downto 0);
      xauiTxP           : out   slv(3 downto 0);
      xauiTxN           : out   slv(3 downto 0);
      xauiClkP          : in    sl;
      xauiClkN          : in    sl;
      -- LCLS Timing Ports
      -- timingRxP         : in    sl;
      -- timingRxN         : in    sl;
      -- timingTxP         : out   sl;
      -- timingTxN         : out   sl;
      -- timingClkInP      : in    sl;
      -- timingClkInN      : in    sl;
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
      -- ddrAlertL         : in    sl;
      -- ddrPg             : in    sl;
      ddrPwrEnL         : out   sl;
      ddrScl            : inout sl;
      ddrSda            : inout sl;
      -- SYSMON Ports
      vPIn              : in    sl;
      vNIn              : in    sl);      
end AmcCarrierCore;

architecture mapping of AmcCarrierCore is

   signal axiClk   : sl;
   signal axiRst   : sl;
   signal memReady : sl;
   signal memError : sl;

   signal axiReadMaster  : AxiLiteReadMasterArray(1 downto 0);
   signal axiReadSlave   : AxiLiteReadSlaveArray(1 downto 0);
   signal axiWriteMaster : AxiLiteWriteMasterArray(1 downto 0);
   signal axiWriteSlave  : AxiLiteWriteSlaveArray(1 downto 0);

   signal timingAxiReadMaster  : AxiLiteReadMasterType;
   signal timingAxiReadSlave   : AxiLiteReadSlaveType;
   signal timingAxiWriteMaster : AxiLiteWriteMasterType;
   signal timingAxiWriteSlave  : AxiLiteWriteSlaveType;

   signal xauiAxiReadMaster  : AxiLiteReadMasterType;
   signal xauiAxiReadSlave   : AxiLiteReadSlaveType;
   signal xauiAxiWriteMaster : AxiLiteWriteMasterType;
   signal xauiAxiWriteSlave  : AxiLiteWriteSlaveType;

   signal ddrAxiReadMaster  : AxiLiteReadMasterType;
   signal ddrAxiReadSlave   : AxiLiteReadSlaveType;
   signal ddrAxiWriteMaster : AxiLiteWriteMasterType;
   signal ddrAxiWriteSlave  : AxiLiteWriteSlaveType;

   signal obDdrMaster : AxiStreamMasterType;
   signal obDdrSlave  : AxiStreamSlaveType;
   signal ibDdrMaster : AxiStreamMasterType;
   signal ibDdrSlave  : AxiStreamSlaveType;

   signal obPromMaster : AxiStreamMasterType;
   signal obPromSlave  : AxiStreamSlaveType;
   signal ibPromMaster : AxiStreamMasterType;
   signal ibPromSlave  : AxiStreamSlaveType;

begin

   -- Secondary AMC's Auxiliary Power (Default to allows active for the time being)
   -- Note: Install R1063 if you want the FPGA to control AUX power
   enAuxPwrL <= '0';

   -- DDR is always powered
   ddrPwrEnL <= '0';

   --------------------------------
   -- Common Clock and Reset Module
   -------------------------------- 
   U_ClkAndRst : entity work.AmcCarrierClkAndRst
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map (
         axiClk       => axiClk,
         axiRst       => axiRst,
         ref100MHzClk => ref100MHzClk,
         ref100MHzRst => ref100MHzRst,
         ref125MHzClk => ref125MHzClk,
         ref125MHzRst => ref125MHzRst,
         ref156MHzClk => ref156MHzClk,
         ref156MHzRst => ref156MHzRst,
         ref200MHzClk => ref200MHzClk,
         ref200MHzRst => ref200MHzRst,
         ref250MHzClk => ref250MHzClk,
         ref250MHzRst => ref250MHzRst,
         ----------------
         -- Core Ports --
         ----------------   
         -- Common Fabricate Clock
         fabClkP      => fabClkP,
         fabClkN      => fabClkN);

   -----------------------------------         
   -- Initialization Controller Module
   -----------------------------------         
   U_Init : entity work.AmcCarrierInit
      generic map (
         TPD_G  => TPD_G,
         FSBL_G => FSBL_G)
      port map (
         axiClk          => axiClk,
         axiRst          => axiRst,
         -- Master AXI-Lite Interface
         mAxiReadMaster  => axiReadMaster(1),
         mAxiReadSlave   => axiReadSlave(1),
         mAxiWriteMaster => axiWriteMaster(1),
         mAxiWriteSlave  => axiWriteSlave(1));         

   ------------------------------------
   -- 10 GigE XAUI Module (ATCA ZONE 2)
   ------------------------------------
   U_Xaui : entity work.AmcCarrierXaui
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk             => axiClk,
         axiRst             => axiRst,
         -- Master AXI-Lite Interface
         mAxiReadMaster     => axiReadMaster(0),
         mAxiReadSlave      => axiReadSlave(0),
         mAxiWriteMaster    => axiWriteMaster(0),
         mAxiWriteSlave     => axiWriteSlave(0),
         -- XAUI AXI-Lite Interface
         xauiAxiReadMaster  => xauiAxiReadMaster,
         xauiAxiReadSlave   => xauiAxiReadSlave,
         xauiAxiWriteMaster => xauiAxiWriteMaster,
         xauiAxiWriteSlave  => xauiAxiWriteSlave,
         -- DDR AXI Streaming Interface
         obDdrMaster        => obDdrMaster,
         obDdrSlave         => obDdrSlave,
         ibDdrMaster        => ibDdrMaster,
         ibDdrSlave         => ibDdrSlave,
         -- Boot Prom AXI Streaming Interface (Optional)
         obPromMaster       => obPromMaster,
         obPromSlave        => obPromSlave,
         ibPromMaster       => ibPromMaster,
         ibPromSlave        => ibPromSlave,
         ----------------
         -- Core Ports --
         ----------------   
         -- XAUI Ports
         xauiRxP            => xauiRxP,
         xauiRxN            => xauiRxN,
         xauiTxP            => xauiTxP,
         xauiTxN            => xauiTxN,
         xauiClkP           => xauiClkP,
         xauiClkN           => xauiClkN);    

   -----------------------------------   
   -- Register Address Mapping Module
   -----------------------------------   
   U_RegMap : entity work.AmcCarrierRegMapping
      generic map (
         TPD_G  => TPD_G,
         FSBL_G => FSBL_G)
      port map (
         -- Primary AXI-Lite Interface
         axiClk               => axiClk,
         axiRst               => axiRst,
         sAxiReadMaster       => axiReadMaster,
         sAxiReadSlave        => axiReadSlave,
         sAxiWriteMaster      => axiWriteMaster,
         sAxiWriteSlave       => axiWriteSlave,
         -- Timing AXI-Lite Interface
         timingAxiReadMaster  => timingAxiReadMaster,
         timingAxiReadSlave   => timingAxiReadSlave,
         timingAxiWriteMaster => timingAxiWriteMaster,
         timingAxiWriteSlave  => timingAxiWriteSlave,
         -- XAUI AXI-Lite Interface
         xauiAxiReadMaster    => xauiAxiReadMaster,
         xauiAxiReadSlave     => xauiAxiReadSlave,
         xauiAxiWriteMaster   => xauiAxiWriteMaster,
         xauiAxiWriteSlave    => xauiAxiWriteSlave,
         -- DDR AXI-Lite Interface
         ddrAxiReadMaster     => ddrAxiReadMaster,
         ddrAxiReadSlave      => ddrAxiReadSlave,
         ddrAxiWriteMaster    => ddrAxiWriteMaster,
         ddrAxiWriteSlave     => ddrAxiWriteSlave,
         -- Application AXI-Lite Interface
         regClk               => regClk,
         regRst               => regRst,
         regAxiReadMaster     => regAxiReadMaster,
         regAxiReadSlave      => regAxiReadSlave,
         regAxiWriteMaster    => regAxiWriteMaster,
         regAxiWriteSlave     => regAxiWriteSlave,
         -- Boot Prom AXI Streaming Interface (Optional)
         obPromMaster         => obPromMaster,
         obPromSlave          => obPromSlave,
         ibPromMaster         => ibPromMaster,
         ibPromSlave          => ibPromSlave,
         ----------------
         -- Core Ports --
         ----------------   
         -- Crossbar Ports
         xBarSin              => xBarSin,
         xBarSout             => xBarSout,
         xBarConfig           => xBarConfig,
         xBarLoad             => xBarLoad,
         -- IPMC Ports
         ipmcScl              => ipmcScl,
         ipmcSda              => ipmcSda,
         -- Configuration PROM Ports
         calScl               => calScl,
         calSda               => calSda,
         -- Clock Cleaner Ports
         timingClkScl         => timingClkScl,
         timingClkSda         => timingClkSda,
         -- DDR3L SO-DIMM Ports
         ddrScl               => ddrScl,
         ddrSda               => ddrSda,
         -- SYSMON Ports
         vPIn                 => vPIn,
         vNIn                 => vNIn);          

   --------------
   -- Timing Core
   --------------
   U_Timing : entity work.AmcCarrierTiming
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Interface
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => timingAxiReadMaster,
         axiReadSlave   => timingAxiReadSlave,
         axiWriteMaster => timingAxiWriteMaster,
         axiWriteSlave  => timingAxiWriteSlave,
         -- Timing Interface 
         refTimingClk   => refTimingClk,
         timingClk      => timingClk,
         timingRst      => timingRst,
         timingData     => timingData,
         ----------------
         -- Core Ports --
         ----------------   
         -- LCLS Timing Ports
         -- timingRxP      => timingRxP,
         -- timingRxN      => timingRxN,
         -- timingTxP      => timingTxP,
         -- timingTxN      => timingTxN,
         -- timingClkInP   => timingClkInP,
         -- timingClkInN   => timingClkInN,
         timingClkOutP  => timingClkOutP,
         timingClkOutN  => timingClkOutN,
         timingClkSel   => timingClkSel);  

   ------------------
   -- DDR Memory Core
   ------------------
   U_DdrMem : entity work.AmcCarrierDdrMem
      generic map (
         TPD_G         => TPD_G,
         EXT_MEM_G     => EXT_MEM_G,
         FSBL_G        => FSBL_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map (
         -- AXI-Lite Interface
         axiClk             => axiClk,
         axiRst             => axiRst,
         axiLiteReadMaster  => ddrAxiReadMaster,
         axiLiteReadSlave   => ddrAxiReadSlave,
         axiLiteWriteMaster => ddrAxiWriteMaster,
         axiLiteWriteSlave  => ddrAxiWriteSlave,
         memReady           => memReady,
         memError           => memError,
         -- Diagnostic Snapshot
         debugClk           => debugClk,
         debugRst           => debugRst,
         debugIbMaster      => debugIbMaster,
         debugIbSlave       => debugIbSlave,
         -- Beam Synchronization (BSA)
         bsaClk             => bsaClk,
         bsaRst             => bsaRst,
         bsaIbMaster        => bsaIbMaster,
         bsaIbSlave         => bsaIbSlave,
         -- AXI Streaming Interface to Ethernet
         obDdrMaster        => obDdrMaster,
         obDdrSlave         => obDdrSlave,
         ibDdrMaster        => ibDdrMaster,
         ibDdrSlave         => ibDdrSlave,
         ----------------
         -- Core Ports --
         ----------------   
         -- DDR3L SO-DIMM Ports
         ddrClkP            => ddrClkP,
         ddrClkN            => ddrClkN,
         ddrDqsP            => ddrDqsP,
         ddrDqsN            => ddrDqsN,
         ddrDm              => ddrDm,
         ddrDq              => ddrDq,
         ddrA               => ddrA,
         ddrBa              => ddrBa,
         ddrCsL             => ddrCsL,
         ddrOdt             => ddrOdt,
         ddrCke             => ddrCke,
         ddrCkP             => ddrCkP,
         ddrCkN             => ddrCkN,
         ddrWeL             => ddrWeL,
         ddrRasL            => ddrRasL,
         ddrCasL            => ddrCasL,
         ddrRstL            => ddrRstL);

end mapping;
