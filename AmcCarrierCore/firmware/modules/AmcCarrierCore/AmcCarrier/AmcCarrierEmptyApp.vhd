-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEmptyApp.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2016-04-28
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Application's Top Level
-- 
-- Note: Common-to-Application interface defined in HPS ESD: LCLSII-2.7-ES-0536
--
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierEmptyApp is
   generic (
      TPD_G                    : time                 := 1 ns;
      SIM_SPEEDUP_G            : boolean              := false;
      AXI_ERROR_RESP_G         : slv(1 downto 0)      := AXI_RESP_DECERR_C;
      DIAGNOSTIC_RAW_STREAMS_G : positive             := 4;
      DIAGNOSTIC_RAW_CONFIGS_G : AxiStreamConfigArray := (0 => ssiAxiStreamConfig(4),
                                                          1 => ssiAxiStreamConfig(4),
                                                          2 => ssiAxiStreamConfig(4),
                                                          3 => ssiAxiStreamConfig(4)));
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
      regClk               : out sl;
      regRst               : out sl;
      regReadMaster        : in  AxiLiteReadMasterType;
      regReadSlave         : out AxiLiteReadSlaveType;
      regWriteMaster       : in  AxiLiteWriteMasterType;
      regWriteSlave        : out AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain) 
      timingClk            : out sl;
      timingRst            : out sl;
      timingBus            : in  TimingBusType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : out sl;
      diagnosticRst        : out sl;
      diagnosticBus        : out DiagnosticBusType;
      -- Raw Diagnostic Interface (diagnosticRawClks domains)
      diagnosticRawClks    : out slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawRsts    : out slv(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawMasters : out AxiStreamMasterArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawSlaves  : in  AxiStreamSlaveArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      diagnosticRawCtrl    : in  AxiStreamCtrlArray(DIAGNOSTIC_RAW_STREAMS_G-1 downto 0);
      -- Support Reference Clocks and Resets
      recTimingClk         : in  sl;
      recTimingRst         : in  sl;
      ref156MHzClk         : in  sl;
      ref156MHzRst         : in  sl);
end AmcCarrierEmptyApp;

architecture top_level_app of AmcCarrierEmptyApp is

   signal clk : sl;
   signal rst : sl;

   constant AXIL_MASTERS_C : integer := DIAGNOSTIC_RAW_STREAMS_G;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);

begin

   clk                         <= ref156MHzClk;
   rst                         <= ref156MHzRst;
   regClk                      <= clk;
   regRst                      <= rst;
   timingClk                   <= clk;
   timingRst                   <= rst;
   diagnosticClk               <= clk;
   diagnosticRst               <= rst;
   diagnosticBus.strobe        <= timingBus.strobe;
   diagnosticBus.timingMessage <= timingBus.message;
   diagnosticBus.data          <= (others => x"3F800000");  -- 1.0

   diagnosticRawClks <= (others => clk);
   diagnosticRawRsts <= (others => rst);

   U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTERS_C,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         MASTERS_CONFIG_G   => genAxiLiteConfig(DIAGNOSTIC_RAW_STREAMS_G, APP_REG_BASE_ADDR_C, 16, 12),
         DEBUG_G            => true)
      port map (
         axiClk              => clk,                  -- [in]
         axiClkRst           => rst,                  -- [in]
         sAxiWriteMasters(0) => regWriteMaster,       -- [in]
         sAxiWriteSlaves(0)  => regWriteSlave,        -- [out]
         sAxiReadMasters(0)  => regReadMaster,        -- [in]
         sAxiReadSlaves(0)   => regReadSlave,         -- [out]
         mAxiWriteMasters    => locAxilWriteMasters,  -- [out]
         mAxiWriteSlaves     => locAxilWriteSlaves,   -- [in]
         mAxiReadMasters     => locAxilReadMasters,   -- [out]
         mAxiReadSlaves      => locAxilReadSlaves);   -- [in]

   PRBS_GEN : for i in DIAGNOSTIC_RAW_STREAMS_G-1 downto 0 generate
      U_SsiPrbsTx_1 : entity work.SsiPrbsTx
         generic map (
            TPD_G                      => TPD_G,
            AXI_ERROR_RESP_G           => AXI_ERROR_RESP_G,
            BRAM_EN_G                  => false,
            USE_BUILT_IN_G             => false,
            GEN_SYNC_FIFO_G            => true,
            FIFO_ADDR_WIDTH_G          => 4,
            FIFO_PAUSE_THRESH_G        => 2**4-1,
            MASTER_AXI_STREAM_CONFIG_G => DIAGNOSTIC_RAW_CONFIGS_G(i),
            MASTER_AXI_PIPE_STAGES_G   => 0)
         port map (
            mAxisClk        => clk,                      -- [in]
            mAxisRst        => rst,                      -- [in]
            mAxisMaster     => diagnosticRawMasters(i),  -- [out]
            mAxisSlave      => diagnosticRawSlaves(i),   -- [in]
            locClk          => clk,                      -- [in]
            locRst          => rst,                      -- [in]
--          trig            => trig,             -- [in]
--          packetLength    => packetLength,     -- [in]
--          forceEofe       => forceEofe,        -- [in]
            busy            => open,                     -- [out]
--          tDest           => tDest,            -- [in]
--          tId             => tId,              -- [in]
            axilReadMaster  => locAxilReadMasters(i),    -- [in]
            axilReadSlave   => locAxilReadSlaves(i),     -- [out]
            axilWriteMaster => locAxilWriteMasters(i),   -- [in]
            axilWriteSlave  => locAxilWriteSlaves(i));   -- [out]
   end generate PRBS_GEN;

end top_level_app;
