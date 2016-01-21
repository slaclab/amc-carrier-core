-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsAndFfb.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2016-01-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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
use work.AmcCarrierRegPkg.all;
use work.TimingPkg.all;

entity AmcCarrierMpsAndFfb is
   generic (
      TPD_G            : time            := 1 ns;
      APP_TYPE_G       : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C;
      MPS_SLOT_G       : boolean         := false);
   port (
      -- Local Configuration
      localAppId      : in  slv(15 downto 0);
      -- SALT Reference clocks
      mps125MHzClk    : in  sl;
      mps125MHzRst    : in  sl;
      mps312MHzClk    : in  sl;
      mps312MHzRst    : in  sl;
      mps625MHzClk    : in  sl;
      mps625MHzRst    : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- FFB Outbound Interface
      ffbObMaster     : out AxiStreamMasterType;
      ffbObSlave      : in  AxiStreamSlaveType;
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
      mpsBusRxP       : in  slv(14 downto 1);
      mpsBusRxN       : in  slv(14 downto 1);
      mpsBusTxP       : out slv(14 downto 1);
      mpsBusTxN       : out slv(14 downto 1);
      mpsTxP          : out sl;
      mpsTxN          : out sl);
end AmcCarrierMpsAndFfb;

architecture mapping of AmcCarrierMpsAndFfb is

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant MPS_RAM_INDEX_C : natural := 0;
   constant MPS_PHY_INDEX_C : natural := 1;

   constant MPS_RAM_ADDR_C : slv(31 downto 0) := (MPS_ADDR_C + x"00000000");
   constant MPS_PHY_ADDR_C : slv(31 downto 0) := (MPS_ADDR_C + x"00010000");

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      MPS_RAM_INDEX_C => (
         baseAddr     => MPS_RAM_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      MPS_PHY_INDEX_C => (
         baseAddr     => MPS_PHY_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"));

   signal writeMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal writeSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal timeStrb          : sl;
   signal timeStamp         : slv(63 downto 0);
   signal message           : Slv32Array(31 downto 0);
   signal timeStrbRate      : slv(31 downto 0);
   signal diagnosticClkFreq : slv(31 downto 0);
   signal mpsTestMode       : sl;
   signal mpsEnable         : sl;
   signal ffbTestMode       : sl;
   signal ffbEnable         : sl;

   signal mpsMaster : AxiStreamMasterType;
   signal mpsSlave  : AxiStreamSlaveType;

begin

   ------------------------------------ 
   -- Time Stamp Synchronization Module
   ------------------------------------ 
   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 64)
      port map (
         -- Asynchronous Reset
         rst    => diagnosticRst,
         -- Write Ports (wr_clk domain)
         wr_clk => diagnosticClk,
         wr_en  => diagnosticBus.strobe,
         din    => diagnosticBus.timingMessage.timeStamp,
         -- Read Ports (rd_clk domain)
         rd_clk => axilClk,
         valid  => timeStrb,
         dout   => timeStamp);

   --------------------------------- 
   -- Message Synchronization Module
   --------------------------------- 
   GEN_VEC :
   for i in 31 downto 0 generate

      U_SyncFifo : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 32)
         port map (
            -- Asynchronous Reset
            rst    => diagnosticRst,
            -- Write Ports (wr_clk domain)
            wr_clk => diagnosticClk,
            wr_en  => diagnosticBus.strobe,
            din    => diagnosticBus.data(i),
            -- Read Ports (rd_clk domain)
            rd_clk => axilClk,
            dout   => message(i));

   end generate GEN_VEC;

   -------------------------------     
   -- Measure the time strobe rate
   -------------------------------     
   U_SyncTrigRate : entity work.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => true,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_C,  -- units of Hz
         REFRESH_RATE_G => 1.0,             -- units of Hz
         CNT_WIDTH_G    => 32)              -- Counters' width
      port map (
         -- Trigger Input (locClk domain)
         trigIn      => timeStrb,
         -- Trigger Rate Output (locClk domain)
         trigRateOut => timeStrbRate,
         -- Clocks
         locClk      => axilClk,
         refClk      => axilClk);

   -----------------------------------------            
   -- Measure the diagnostic Clock frequency
   -----------------------------------------            
   U_SyncClockFreq : entity work.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_C,  -- units of Hz
         REFRESH_RATE_G => 1.0,             -- units of Hz
         CNT_WIDTH_G    => 32)              -- Counters' width
      port map (
         -- Frequency Measurement and Monitoring Outputs (locClk domain)
         freqOut => diagnosticClkFreq,
         -- Clocks
         clkIn   => diagnosticClk,
         locClk  => axilClk,
         refClk  => axilClk);

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
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
         mAxiWriteMasters    => writeMasters,
         mAxiWriteSlaves     => writeSlaves,
         mAxiReadMasters     => readMasters,
         mAxiReadSlaves      => readSlaves);

   --------------------------
   -- FFB: Outbound Messenger
   --------------------------
   U_FfbMsg : entity work.AmcCarrierFfbObMsg
      generic map (
         TPD_G      => TPD_G,
         APP_TYPE_G => APP_TYPE_G)
      port map (
         -- Clock and reset
         clk       => axilClk,
         rst       => axilRst,
         -- Inbound Message Value
         enable    => ffbEnable,
         message   => message,
         timeStrb  => timeStrb,
         timeStamp => timeStamp,
         testMode  => ffbTestMode,
         appId     => localAppId,
         -- FFB Interface
         ffbMaster => ffbObMaster,
         ffbSlave  => ffbObSlave);

   --------------------------
   -- MPS: Outbound Messenger
   --------------------------
   U_MpsMsg : entity work.AmcCarrierMpsMsg
      generic map (
         TPD_G            => TPD_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => MPS_RAM_ADDR_C)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => readMasters(MPS_RAM_INDEX_C),
         axilReadSlave   => readSlaves(MPS_RAM_INDEX_C),
         axilWriteMaster => writeMasters(MPS_RAM_INDEX_C),
         axilWriteSlave  => writeSlaves(MPS_RAM_INDEX_C),
         -- Inbound Message Value
         enable          => mpsEnable,
         message         => message,
         timeStrb        => timeStrb,
         timeStamp       => timeStamp(15 downto 0),
         testMode        => mpsTestMode,
         appId           => localAppId,
         -- MPS Interface
         mpsMaster       => mpsMaster,
         mpsSlave        => mpsSlave);

   ---------------------------------         
   -- MPS Backplane SALT Transceiver
   ---------------------------------         
   U_Salt : entity work.AmcCarrierMpsSalt
      generic map (
         TPD_G            => TPD_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         MPS_SLOT_G       => MPS_SLOT_G)
      port map (
         -- SALT Reference clocks
         mps125MHzClk      => mps125MHzClk,
         mps125MHzRst      => mps125MHzRst,
         mps312MHzClk      => mps312MHzClk,
         mps312MHzRst      => mps312MHzRst,
         mps625MHzClk      => mps625MHzClk,
         mps625MHzRst      => mps625MHzRst,
         -- AXI-Lite Interface
         axilClk           => axilClk,
         axilRst           => axilRst,
         axilReadMaster    => readMasters(MPS_PHY_INDEX_C),
         axilReadSlave     => readSlaves(MPS_PHY_INDEX_C),
         axilWriteMaster   => writeMasters(MPS_PHY_INDEX_C),
         axilWriteSlave    => writeSlaves(MPS_PHY_INDEX_C),
         -- MPS/FFB configuration/status signals
         appId             => localAppId,
         mpsEnable         => mpsEnable,
         mpsTestMode       => mpsTestMode,
         ffbEnable         => ffbEnable,
         ffbTestMode       => ffbTestMode,
         timeStrbRate      => timeStrbRate,
         diagnosticClkFreq => diagnosticClkFreq,
         -- MPS Interface
         mpsIbMaster       => mpsMaster,
         mpsIbSlave        => mpsSlave,
         ----------------------
         -- Top Level Interface
         ----------------------
         -- MPS Interface
         mpsObMasters      => mpsObMasters,
         mpsObSlaves       => mpsObSlaves,
         ----------------
         -- Core Ports --
         ----------------
         -- Backplane MPS Ports
         mpsBusRxP         => mpsBusRxP,
         mpsBusRxN         => mpsBusRxN,
         mpsBusTxP         => mpsBusTxP,
         mpsBusTxN         => mpsBusTxN,
         mpsTxP            => mpsTxP,
         mpsTxN            => mpsTxN);

end mapping;
