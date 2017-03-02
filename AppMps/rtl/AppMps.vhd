-------------------------------------------------------------------------------
-- File       : AppMps.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2017-02-04
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Note: Do not forget to configure the ATCA crate to drive the clock from the slot#2 MPS link node
-- For the 7-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
-- For the 16-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierSysRegPkg.all;
use work.TimingPkg.all;

entity AppMps is
   generic (
      TPD_G            : time            := 1 ns;
      SIM_SPEEDUP_G    : boolean         := false;
      MPS_SLOT_G       : boolean         := false;
      APP_TYPE_G       : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- IPMI Status and Configurations
      bsiBus          : in  BsiBusType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;
      -- MPS Interface
      mpsObMasters    : out AxiStreamMasterArray(14 downto 0);
      mpsObSlaves     : in  AxiStreamSlaveArray(14 downto 0);
      ----------------
      -- Core Ports --
      ----------------
      -- Backplane MPS Ports
      mpsClkIn        : in  sl;
      mpsClkOut       : out sl;
      mpsBusRxP       : in  slv(14 downto 1);
      mpsBusRxN       : in  slv(14 downto 1);
      mpsTxP          : out sl;
      mpsTxN          : out sl);
end AppMps;

architecture mapping of AppMps is

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant SALT_INDEX_C    : natural := 0;
   constant ENCODER_INDEX_C : natural := 1;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      SALT_INDEX_C    => (
         baseAddr     => (MPS_ADDR_C + x"00000000"),
         addrBits     => 16,
         connectivity => X"FFFF"),
      ENCODER_INDEX_C => (
         baseAddr     => (MPS_ADDR_C + x"00010000"),
         addrBits     => 16,
         connectivity => X"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal mps125MHzClk : sl;
   signal mps125MHzRst : sl;
   signal mps312MHzClk : sl;
   signal mps312MHzRst : sl;
   signal mps625MHzClk : sl;
   signal mps625MHzRst : sl;
   signal mpsPllLocked : sl;

   signal mpsTestMode : sl;
   signal mpsEnable   : sl;

   signal mpsMaster : AxiStreamMasterType;
   signal mpsSlave  : AxiStreamSlaveType;

begin

   ------------------------------
   -- Backplane Clocks and Resets
   ------------------------------
   U_Clk : entity work.AppMpsClk
      generic map (
         TPD_G         => TPD_G,
         MPS_SLOT_G    => MPS_SLOT_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map (
         -- Stable Clock and Reset 
         axilClk      => axilClk,
         axilRst      => axilRst,
         -- MPS Clocks and Resets
         mps125MHzClk => mps125MHzClk,
         mps125MHzRst => mps125MHzRst,
         mps312MHzClk => mps312MHzClk,
         mps312MHzRst => mps312MHzRst,
         mps625MHzClk => mps625MHzClk,
         mps625MHzRst => mps625MHzRst,
         mpsPllLocked => mpsPllLocked,
         ----------------
         -- Core Ports --
         ----------------   
         -- Backplane MPS Ports
         mpsClkIn     => mpsClkIn,
         mpsClkOut    => mpsClkOut);

   ---------------------
   -- AXI-Lite: Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ----------------------
   -- MPS Message Encoder
   ----------------------
   U_AppMpsEncoder : entity work.AppMpsEncoder
      generic map (
         TPD_G            => TPD_G,
         MPS_SLOT_G       => MPS_SLOT_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CROSSBAR_MASTERS_CONFIG_C(ENCODER_INDEX_C).baseAddr)
      port map (
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk   => diagnosticClk,
         diagnosticRst   => diagnosticRst,
         diagnosticBus   => diagnosticBus,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(ENCODER_INDEX_C),
         axilReadSlave   => axilReadSlaves(ENCODER_INDEX_C),
         axilWriteMaster => axilWriteMasters(ENCODER_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(ENCODER_INDEX_C),
         -- Inbound Message Value
         enable          => mpsEnable,
         testMode        => mpsTestMode,
         bsiBus          => bsiBus,
         -- MPS Interface
         mpsMaster       => mpsMaster,
         mpsSlave        => mpsSlave);

   ---------------------------------         
   -- MPS Backplane SALT Transceiver
   ---------------------------------         
   U_Salt : entity work.AppMpsSalt
      generic map (
         TPD_G            => TPD_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         MPS_SLOT_G       => MPS_SLOT_G)
      port map (
         -- SALT Reference clocks
         mps125MHzClk    => mps125MHzClk,
         mps125MHzRst    => mps125MHzRst,
         mps312MHzClk    => mps312MHzClk,
         mps312MHzRst    => mps312MHzRst,
         mps625MHzClk    => mps625MHzClk,
         mps625MHzRst    => mps625MHzRst,
         mpsPllLocked    => mpsPllLocked,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SALT_INDEX_C),
         axilReadSlave   => axilReadSlaves(SALT_INDEX_C),
         axilWriteMaster => axilWriteMasters(SALT_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SALT_INDEX_C),
         -- MPS/BP_MSG configuration/status signals
         mpsEnable       => mpsEnable,
         mpsTestMode     => mpsTestMode,
         -- MPS Interface
         mpsIbMaster     => mpsMaster,
         mpsIbSlave      => mpsSlave,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- MPS Interface
         mpsObMasters    => mpsObMasters,
         mpsObSlaves     => mpsObSlaves,
         ----------------
         -- Core Ports --
         ----------------
         -- Backplane MPS Ports
         mpsBusRxP       => mpsBusRxP,
         mpsBusRxN       => mpsBusRxN,
         mpsTxP          => mpsTxP,
         mpsTxN          => mpsTxN);

end mapping;
