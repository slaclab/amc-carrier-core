-----------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.EthMacPkg.all;
use surf.SsiPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;
use amc_carrier_core.BsasPkg.all;

entity BsasWrapper is

   generic (
      TPD_G       : time    := 1 ns;
      NUM_EDEFS_G : integer := 1;   -- Index of EDEF
      BASE_ADDR_G : slv(31 downto 0) := x"00000000" );
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
      ibEthMsgSlave   : out AxiStreamSlaveType;
      obEthMsgMaster  : out AxiStreamMasterType;
      obEthMsgSlave   : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_INIT_C);

end entity BsasWrapper;

architecture rtl of BsasWrapper is

   signal sAxisMasters : AxiStreamMasterArray(NUM_EDEFS_G downto 0);
   signal sAxisSlaves  : AxiStreamSlaveArray (NUM_EDEFS_G downto 0);

   constant CROSSBAR_CONFIG : AxiLiteCrossbarMasterConfigArray(NUM_EDEFS_G-1 downto 0) :=
     genAxiLiteConfig(NUM_EDEFS_G,BASE_ADDR_G,16,11);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_EDEFS_G-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (NUM_EDEFS_G-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray (NUM_EDEFS_G-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray  (NUM_EDEFS_G-1 downto 0);

begin

   sAxisMasters(0) <= ibEthMsgMaster;
   ibEthMsgSlave   <= sAxisSlaves(0);

   U_AxiLiteXbar : entity surf.AxiLiteCrossbar
     generic map (
       NUM_SLAVE_SLOTS_G  => 1,
       NUM_MASTER_SLOTS_G => CROSSBAR_CONFIG'length,
       MASTERS_CONFIG_G   => CROSSBAR_CONFIG )
     port map (
       axiClk              => axilClk,
       axiClkRst           => axilRst,
       sAxiWriteMasters(0) => axilWriteMaster,
       sAxiWriteSlaves (0) => axilWriteSlave,
       sAxiReadMasters (0) => axilReadMaster,
       sAxiReadSlaves  (0) => axilReadSlave,
       mAxiWriteMasters    => axilWriteMasters,
       mAxiWriteSlaves     => axilWriteSlaves,
       mAxiReadMasters     => axilReadMasters,
       mAxiReadSlaves      => axilReadSlaves );

   GEN_EDEF : for i in 0 to NUM_EDEFS_G-1 generate
     U_BSAS : entity amc_carrier_core.BsasModule
       generic map (
         TPD_G       => TPD_G,
         SVC_G       => i,
         BASE_ADDR_G => CROSSBAR_CONFIG(i).baseAddr )
       port map (
         -- Diagnostic data interface
         diagnosticClk   => diagnosticClk,
         diagnosticRst   => diagnosticRst,
         diagnosticBus   => diagnosticBus,
         -- AXI Lite interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (i),
         axilReadSlave   => axilReadSlaves  (i),
         axilWriteMaster => axilWriteMasters(i),
         axilWriteSlave  => axilWriteSlaves (i),
         -- Timing ETH MSG Interface (axilClk domain)
         obEthMsgMaster  => sAxisMasters(i),
         obEthMsgSlave   => sAxisSlaves (i) );
   end generate;

   sAxisMasters(NUM_EDEFS_G) <= ibEthMsgMaster;
   ibEthMsgSlave             <= sAxisSlaves(NUM_EDEFS_G);
   
   U_Mux : entity surf.AxiStreamMux
     generic map ( NUM_SLAVES_G => NUM_EDEFS_G+1 )
     port map ( axisClk      => axilClk,
                axisRst      => axilRst,
                sAxisMasters => sAxisMasters,
                sAxisSlaves  => sAxisSlaves,
                mAxisMaster  => obEthMsgMaster,
                mAxisSlave   => obEthMsgSlave );

end rtl;
