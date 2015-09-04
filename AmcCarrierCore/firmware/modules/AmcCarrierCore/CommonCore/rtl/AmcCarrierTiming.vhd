-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
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
use work.AxiLitePkg.all;
use work.LclsTimingPkg.all;

entity AmcCarrierTiming is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- AXI-Lite Interface
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      -- Timing Interface 
      refTimingClk   : out sl;
      timingClk      : in  sl;
      timingRst      : in  sl;
      timingData     : out LclsTimingDataType;
      ----------------
      -- Core Ports --
      ----------------   
      -- LCLS Timing Ports
      -- timingRxP      : in  sl;
      -- timingRxN      : in  sl;
      -- timingTxP      : out sl;
      -- timingTxN      : out sl;
      -- timingClkInP   : in  sl;
      -- timingClkInN   : in  sl;
      timingClkOutP  : out sl;
      timingClkOutN  : out sl;
      timingClkSel   : out sl);    
end AmcCarrierTiming;

architecture mapping of AmcCarrierTiming is

   signal timingClock : sl;
   signal timingReset : sl;

begin

   -- Drive the external CLK MUX to standalone or dual timing mode
   timingClkSel <= '0';

   -- Send a copy of the timing clock to the AMC's clock cleaner
   ClkOutBufDiff_Inst : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => timingClock,
         clkOutP => timingClkOutP,
         clkOutN => timingClkOutN);  

   refTimingClk <= '0';
   timingData   <= LCLS_TIMING_DATA_INIT_C;

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axiClk,
         axiClkRst      => axiRst,
         axiReadMaster  => axiReadMaster,
         axiReadSlave   => axiReadSlave,
         axiWriteMaster => axiWriteMaster,
         axiWriteSlave  => axiWriteSlave);         


end mapping;
