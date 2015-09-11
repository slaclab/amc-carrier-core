-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEmptyApp.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2015-09-11
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
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierEmptyApp is
   generic (
      TPD_G               : time                := 1 ns;
      AXI_ERROR_RESP_G    : slv(1 downto 0)     := AXI_RESP_DECERR_C;
      SIM_SPEEDUP_G       : boolean             := false;
      DIAGNOSTIC_SIZE_G   : positive            := 1;
      DIAGNOSTIC_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(4));      
   port (
      -----------------------
      -- Application Ports --
      -----------------------
      -- -- AMC's JESD Ports
      -- jesdRxP       : in    Slv7Array(1 downto 0);
      -- jesdRxN       : in    Slv7Array(1 downto 0);
      -- jesdTxP       : out   Slv7Array(1 downto 0);
      -- jesdTxN       : out   Slv7Array(1 downto 0);
      -- jesdClkP      : in    Slv3Array(1 downto 0);
      -- jesdClkN      : in    Slv3Array(1 downto 0);
      -- -- AMC's JTAG Ports
      -- jtagPri       : inout Slv5Array(1 downto 0);
      -- jtagSec       : inout Slv5Array(1 downto 0);
      -- -- AMC's FPGA Clock Ports
      -- fpgaClkP      : inout Slv2Array(1 downto 0);
      -- fpgaClkN      : inout Slv2Array(1 downto 0);
      -- -- AMC's System Reference Ports
      -- sysRefP       : inout Slv4Array(1 downto 0);
      -- sysRefN       : inout Slv4Array(1 downto 0);
      -- -- AMC's Sync Ports
      -- syncInP       : inout Slv10Array(1 downto 0);
      -- syncInN       : inout Slv10Array(1 downto 0);
      -- syncOutP      : inout Slv4Array(1 downto 0);
      -- syncOutN      : inout Slv4Array(1 downto 0);
      -- -- AMC's Spare Ports
      -- spareP        : inout Slv16Array(1 downto 0);
      -- spareN        : inout Slv16Array(1 downto 0);    
      -- -- RTM's Low Speed Ports
      -- rtmLsP        : inout slv(53 downto 0);
      -- rtmLsN        : inout slv(53 downto 0);
      -- -- RTM's High Speed Ports
      -- rtmHsRxP      : in    sl;
      -- rtmHsRxN      : in    sl;
      -- rtmHsTxP      : out   sl;
      -- rtmHsTxN      : out   sl;
      -- genClkP       : in    sl;
      -- genClkN       : in    sl;   
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      regClk            : out sl;
      regRst            : out sl;
      regReadMaster     : in  AxiLiteReadMasterType;
      regReadSlave      : out AxiLiteReadSlaveType;
      regWriteMaster    : in  AxiLiteWriteMasterType;
      regWriteSlave     : out AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk         : out sl;
      timingRst         : out sl;
      timingData        : in  LclsTimingDataType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk     : out sl;
      diagnosticRst     : out sl;
      diagnosticMessage : out Slv32Array(31 downto 0);
      diagnosticMasters : out AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves  : in  AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      -- MPS Interface (mpsClk domain)
      mpsClk            : out sl;
      mpsRst            : out sl;
      mpsIbMaster       : out AxiStreamMasterType;
      mpsIbSlave        : in  AxiStreamSlaveType;
      mpsObMasters      : in  AxiStreamMasterArray(14 downto 1);
      mpsObSlaves       : out AxiStreamSlaveArray(14 downto 1);
      -- BSI Interface (bsiClk domain) 
      bsiClk            : out sl;
      bsiRst            : out sl;
      bsiData           : in  BsiDataType;
      -- Support Reference Clocks and Resets
      refTimingClk      : in  sl;
      refTimingRst      : in  sl;
      ref156MHzClk      : in  sl;
      ref156MHzRst      : in  sl);
end AmcCarrierEmptyApp;

architecture mapping of AmcCarrierEmptyApp is

   signal sysClk : sl;
   signal sysRst : sl;

begin

   sysClk <= ref156MHzClk;
   sysRst <= ref156MHzRst;

   regClk <= sysClk;
   regRst <= sysRst;

   timingClk <= sysClk;
   timingRst <= sysRst;

   diagnosticClk     <= sysClk;
   diagnosticRst     <= sysRst;
   diagnosticMessage <= (others => x"00000000");
   diagnosticMasters <= (others => AXI_STREAM_MASTER_INIT_C);

   mpsClk      <= sysClk;
   mpsRst      <= sysRst;
   mpsIbMaster <= AXI_STREAM_MASTER_INIT_C;
   mpsObSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);

   bsiClk <= sysClk;
   bsiRst <= sysRst;

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => sysClk,
         axiClkRst      => sysRst,
         axiReadMaster  => regReadMaster,
         axiReadSlave   => regReadSlave,
         axiWriteMaster => regWriteMaster,
         axiWriteSlave  => regWriteSlave);

end mapping;
