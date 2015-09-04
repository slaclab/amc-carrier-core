-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierInit.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-07-10
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
use work.AxiLitePkg.all;

entity AmcCarrierInit is
   generic (
      TPD_G  : time    := 1 ns;
      FSBL_G : boolean := false);       -- true = First Stage Boot loader
   port (
      axiClk          : in  sl;
      axiRst          : in  sl;
      -- Master AXI-Lite Interface
      mAxiReadMaster  : out AxiLiteReadMasterType;
      mAxiReadSlave   : in  AxiLiteReadSlaveType;
      mAxiWriteMaster : out AxiLiteWriteMasterType;
      mAxiWriteSlave  : in  AxiLiteWriteSlaveType);
end AmcCarrierInit;

architecture mapping of AmcCarrierInit is

begin

   -- Place holder for future development
   mAxiReadMaster  <= AXI_LITE_READ_MASTER_INIT_C;
   mAxiWriteMaster <= AXI_LITE_WRITE_MASTER_INIT_C;
   
end mapping;
