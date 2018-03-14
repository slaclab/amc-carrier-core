-------------------------------------------------------------------------------
-- File       : AppMps.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2018-03-14
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
use work.AppMpsPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierSysRegPkg.all;
use work.TimingPkg.all;

entity AppMps is
   generic (
      TPD_G        : time    := 1 ns;
      SIMULATION_G : boolean := false;
      MPS_SLOT_G   : boolean := false;
      APP_TYPE_G   : AppType := APP_NULL_TYPE_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      mpsCoreReg      : out MpsCoreRegType;
      -- -- System Status
      -- bsiBus          : in  BsiBusType;     -- axilClk domain
      -- ethLinkUp       : in  sl;             -- axilClk domain
      -- timingClk       : in  sl;
      -- timingRst       : in  sl;
      -- timingBus       : in  TimingBusType;  -- timingClk domain  
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
   constant SALT_INDEX_C      : natural := 0;
   constant ENCODER_INDEX_C   : natural := 1;

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

   signal encWriteMaster : AxiLiteWriteMasterType;
   signal encWriteSlave  : AxiLiteWriteSlaveType;
   signal encReadMaster  : AxiLiteReadMasterType;
   signal encReadSlave   : AxiLiteReadSlaveType;

   signal mps125MHzClk : sl;
   signal mps125MHzRst : sl;
   signal mps312MHzClk : sl;
   signal mps312MHzRst : sl;
   signal mps625MHzClk : sl;
   signal mps625MHzRst : sl;
   signal mpsTholdClk  : sl;
   signal mpsTholdRst  : sl;
   signal mpsPllLocked : sl;
   signal mpsPllRst    : sl;

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
         SIM_SPEEDUP_G => SIMULATION_G)
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
         mpsTholdClk  => mpsTholdClk,
         mpsTholdRst  => mpsTholdRst,
         mpsPllLocked => mpsPllLocked,
         mpsPllRst    => mpsPllRst,
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

   ----------------------------
   -- Encoder Logic
   ----------------------------
   U_MpsCoreAsync : entity work.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         COMMON_CLK_G    => false,
         NUM_ADDR_BITS_G => 16)  -- Note encReadMaster/encWriteMaster upper 16-bits of address set to zero
      port map (
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMasters(ENCODER_INDEX_C),
         sAxiReadSlave   => axilReadSlaves(ENCODER_INDEX_C),
         sAxiWriteMaster => axilWriteMasters(ENCODER_INDEX_C),
         sAxiWriteSlave  => axilWriteSlaves(ENCODER_INDEX_C),
         mAxiClk         => mpsTholdClk,
         mAxiClkRst      => mpsTholdRst,
         mAxiReadMaster  => encReadMaster,
         mAxiReadSlave   => encReadSlave,
         mAxiWriteMaster => encWriteMaster,
         mAxiWriteSlave  => encWriteSlave);

   U_AppMpsEncoder : entity work.AppMpsEncoder
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => (others => '0'),  -- Only lower 16-bits of address are passed through the AxiLiteAsync
         APP_TYPE_G      => APP_TYPE_G)
      port map (
         axilClk         => mpsTholdClk,
         axilRst         => mpsTholdRst,
         axilReadMaster  => encReadMaster,
         axilReadSlave   => encReadSlave,
         axilWriteMaster => encWriteMaster,
         axilWriteSlave  => encWriteSlave,
         mpsMaster       => mpsMaster,
         mpsSlave        => mpsSlave,
         diagnosticClk   => diagnosticClk,
         diagnosticRst   => diagnosticRst,
         mpsCoreReg      => mpsCoreReg,
         diagnosticBus   => diagnosticBus);

   ---------------------------------         
   -- MPS Backplane SALT Transceiver
   ---------------------------------         
   U_Salt : entity work.AppMpsSalt
      generic map (
         TPD_G        => TPD_G,
         SIMULATION_G => SIMULATION_G,
         APP_TYPE_G   => APP_TYPE_G,
         MPS_SLOT_G   => MPS_SLOT_G)
      port map (
         -- SALT Reference clocks
         mps125MHzClk    => mps125MHzClk,
         mps125MHzRst    => mps125MHzRst,
         mps312MHzClk    => mps312MHzClk,
         mps312MHzRst    => mps312MHzRst,
         mps625MHzClk    => mps625MHzClk,
         mps625MHzRst    => mps625MHzRst,
         mpsPllLocked    => mpsPllLocked,
         mpsPllRst       => mpsPllRst,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SALT_INDEX_C),
         axilReadSlave   => axilReadSlaves(SALT_INDEX_C),
         axilWriteMaster => axilWriteMasters(SALT_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SALT_INDEX_C),
         -- MPS Interface
         mpsIbClk        => mpsTholdClk,
         mpsIbRst        => mpsTholdRst,
         mpsIbMaster     => mpsMaster,
         mpsIbSlave      => mpsSlave,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk   => diagnosticClk,
         diagnosticRst   => diagnosticRst,
         diagnosticBus   => diagnosticBus,
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

