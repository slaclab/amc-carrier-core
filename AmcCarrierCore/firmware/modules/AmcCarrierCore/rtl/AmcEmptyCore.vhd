-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : ApplicationEmptyCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2015-07-14
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

entity ApplicationEmptyCore is
   generic (
      TPD_G : time := 1 ns);
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      regClk            : out sl;
      regRst            : out sl;
      regAxiReadMaster  : in  AxiLiteReadMasterType;
      regAxiReadSlave   : out AxiLiteReadSlaveType;
      regAxiWriteMaster : in  AxiLiteWriteMasterType;
      regAxiWriteSlave  : out AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk         : out sl;
      timingRst         : out sl;
      timingData        : in  LclsTimingDataType;
      -- Diagnostic Snapshot (debugClk domain)
      debugClk          : out sl;
      debugRst          : out sl;
      debugIbMaster     : out AxiStreamMasterType;
      debugIbSlave      : in  AxiStreamSlaveType;
      -- Beam Synchronization (bsaClk domain)
      bsaClk            : out sl;
      bsaRst            : out sl;
      bsaIbMaster       : out AxiStreamMasterType;
      bsaIbSlave        : in  AxiStreamSlaveType;
      -- Support Reference Clocks and Resets
      refTimingClk      : in  sl;
      ref100MHzClk      : in  sl;
      ref100MHzRst      : in  sl;
      ref125MHzClk      : in  sl;
      ref125MHzRst      : in  sl;
      ref156MHzClk      : in  sl;
      ref156MHzRst      : in  sl;
      ref200MHzClk      : in  sl;
      ref200MHzRst      : in  sl;
      ref250MHzClk      : in  sl;
      ref250MHzRst      : in  sl);
end ApplicationEmptyCore;

architecture mapping of ApplicationEmptyCore is

   signal sysClk : sl;
   signal sysRst : sl;

begin

   sysClk <= ref100MHzClk;
   sysRst <= ref100MHzRst;

   regClk <= sysClk;
   regRst <= sysRst;

   timingClk <= sysClk;
   timingRst <= sysRst;

   debugClk      <= sysClk;
   debugRst      <= sysRst;
   debugIbMaster <= AXI_STREAM_MASTER_INIT_C;

   bsaClk      <= sysClk;
   bsaRst      <= sysRst;
   bsaIbMaster <= AXI_STREAM_MASTER_INIT_C;

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => sysClk,
         axiClkRst      => sysRst,
         axiReadMaster  => regAxiReadMaster,
         axiReadSlave   => regAxiReadSlave,
         axiWriteMaster => regAxiWriteMaster,
         axiWriteSlave  => regAxiWriteSlave);

end mapping;
