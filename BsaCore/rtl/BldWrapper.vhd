-----------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : BldWrapper.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-25
-- Last update: 2022-11-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 Timing Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;

entity BldWrapper is

   generic ( NUM_EDEFS_G : integer := 1 ); -- Num of EDEFs in stream
   port (
      -- Diagnostic data interface
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;
      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Timing ETH MSG Interface (axilClk domain)
      ibEthMsgMaster  : in  AxiStreamMasterType;
      ibEthMsgSlave   : out AxiStreamSlaveType ;
      obEthMsgMaster  : out AxiStreamMasterType;
      obEthMsgSlave   : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_INIT_C );

end entity BldWrapper;

architecture rtl of BldWrapper is

begin

  U_Bsss : entity amc_carrier_core.BldAxiStream
    generic map ( SVC_START_G  => 48,
                  NUM_EDEFS_G  => NUM_EDEFS_G,
                  BATCH_G      => true )
    port map (
      -- Diagnostic data interface
      diagnosticClk   => diagnosticClk,
      diagnosticRst   => diagnosticRst,
      diagnosticBus   => diagnosticBus,
      -- AXI Lite interface
      axilClk         => axilClk,
      axilRst         => axilRst,
      axilReadMaster  => axilReadMaster,
      axilReadSlave   => axilReadSlave,
      axilWriteMaster => axilWriteMaster,
      axilWriteSlave  => axilWriteSlave,
      -- Timing ETH MSG Interface (axilClk domain)
      ibEthMsgMaster  => ibEthMsgMaster,
      ibEthMsgSlave   => ibEthMsgSlave,
      obEthMsgMaster  => obEthMsgMaster,
      obEthMsgSlave   => obEthMsgSlave );
end rtl;
