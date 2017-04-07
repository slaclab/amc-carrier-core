-------------------------------------------------------------------------------
-- File       : AppTopTrig.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2017-03-06
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.AppTopPkg.all;
use work.EthMacPkg.all;

entity AppTopTrig is
   generic (
      TPD_G              : time                   := 1 ns;
      MR_LCLS_APP_G      : boolean                := true;
      AXIL_BASE_ADDR_G   : slv(31 downto 0)       := (others => '0');
      AXI_ERROR_RESP_G   : slv(1 downto 0)        := AXI_RESP_SLVERR_C;
      TRIG_SIZE_G        : positive range 1 to 16 := 3;    -- Unused
      TRIG_DELAY_WIDTH_G : positive range 1 to 32 := 32;   -- Unused
      TRIG_PULSE_WIDTH_G : positive range 1 to 32 := 32);  -- Unused
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Application Debug Interface (axilClk domain)
      sAxisMaster     : in  AxiStreamMasterType;
      sAxisSlave      : out AxiStreamSlaveType;
      mAxisMaster     : out AxiStreamMasterType;
      mAxisSlave      : in  AxiStreamSlaveType;
      -- Timing Interface
      recClk          : in  sl;
      recRst          : in  sl;
      timingBus_i     : in  TimingBusType;
      -- Trigger pulse outputs 
      evrTrig         : out AppTopTrigType);
end AppTopTrig;

architecture mapping of AppTopTrig is

   constant APP_STREAM_ROUTES_C : Slv8Array(1 downto 0) := (
      0 => "--------",  -- AppCore Message: TDEST = ANY
      1 => "--------");  -- EVR IRQ Message: TDEST = forced to [0xFF:0xF0] at EvrV1CoreIrqCtrl

   constant NUM_AXI_MASTERS_C : natural := ite(MR_LCLS_APP_G, 3, 1);

   constant TRIG_CORE_INDEX_C : natural := 0;
   constant EVR_CORE_INDEX_C  : natural := 1;
   constant EVR_ISR_INDEX_C   : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXIL_BASE_ADDR_G, 28, 24);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal mAxilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal mAxilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;
   signal mAxilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;

   signal evrIrqMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal evrIrqSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

   signal irqActive : sl;
   signal irqEnable : sl;
   signal irqReq    : sl;

   signal rxLinkUp : sl;
   signal rxError  : sl;
   signal rxData   : slv(15 downto 0);
   signal rxDataK  : slv(1 downto 0);

   signal trig : Slv16Array(1 downto 0) := (others => x"0000");

begin

   process (trig) is
   begin
      for i in 15 downto 0 loop
         evrTrig.trigPulse(i) <= trig(TRIG_CORE_INDEX_C)(i) or trig(EVR_CORE_INDEX_C)(i);
      end loop;
   end process;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteMasters(1) => mAxilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiWriteSlaves(1)  => mAxilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadMasters(1)  => mAxilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         sAxiReadSlaves(1)   => mAxilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -----------------------------
   -- LCLS Timing/Trigger Module
   -----------------------------
   U_Trigging : entity work.LclsTriggerCore
      generic map (
         TPD_G                => TPD_G,
         AXIL_BASE_ADDR_G     => AXI_CONFIG_C(TRIG_CORE_INDEX_C).baseAddr,
         AXI_ERROR_RESP_G     => AXI_ERROR_RESP_G,
         NUM_OF_TRIG_PULSES_G => TRIG_SIZE_G,
         DELAY_WIDTH_G        => TRIG_DELAY_WIDTH_G,
         PULSE_WIDTH_G        => TRIG_PULSE_WIDTH_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(TRIG_CORE_INDEX_C),
         axilReadSlave   => axilReadSlaves(TRIG_CORE_INDEX_C),
         axilWriteMaster => axilWriteMasters(TRIG_CORE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TRIG_CORE_INDEX_C),
         -- Timing Interface
         recClk          => recClk,
         recRst          => recRst,
         timingBus_i     => timingBus_i,
         -- Trigger pulse outputs 
         trigPulse_o     => trig(TRIG_CORE_INDEX_C)(TRIG_SIZE_G-1 downto 0),
         timeStamp_o     => evrTrig.timeStamp,
         pulseId_o       => evrTrig.pulseId,
         bsa_o           => evrTrig.bsa,
         dmod_o          => evrTrig.dmod);

   GEN_EVR : if (MR_LCLS_APP_G = true) generate

      -----------------------------
      -- LCLS Timing/Trigger Module
      -----------------------------         
      U_EvrV1Core : entity work.EvrV1Core
         generic map (
            TPD_G           => TPD_G,
            BUILD_INFO_G    => (others => '0'),
            SYNC_POLARITY_G => '1',
            USE_WSTRB_G     => false,
            ENDIAN_G        => false)
         port map (
            -- AXI-Lite and IRQ Interface
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(EVR_CORE_INDEX_C),
            axiReadSlave   => axilReadSlaves(EVR_CORE_INDEX_C),
            axiWriteMaster => axilWriteMasters(EVR_CORE_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(EVR_CORE_INDEX_C),
            irqActive      => irqActive,
            irqEnable      => irqEnable,
            irqReq         => irqReq,
            -- Trigger and Sync Port
            sync           => '0',
            trigOut        => trig(EVR_CORE_INDEX_C)(11 downto 0),
            -- EVR Interface
            evrClk         => recClk,
            evrRst         => recRst,
            rxLinkUp       => rxLinkUp,
            rxError        => rxError,
            rxData         => rxData,
            rxDataK        => rxDataK);

      ------------------------------------
      -- EvrV1Core's ISR Controller Module
      ------------------------------------         
      U_EvrV1Isr : entity work.EvrV1CoreIsrCtrl
         generic map (
            TPD_G                 => TPD_G,
            DEFAULT_ISR_SEL_G     => '0',    -- '1' = SW, '0' = FW
            TDEST_IRQ_MSG_G       => x"FF",  -- SW ISR only
            TDEST_DATABUF_MSG_G   => x"F5",  -- FW ISR only
            TDEST_PULSE_MSG_G     => x"F4",  -- FW ISR only
            TDEST_EVENT_MSG_G     => x"F3",  -- FW ISR only
            TDEST_HEARTBEAT_MSG_G => x"F2",  -- FW ISR only
            TDEST_FIFOFULL_MSG_G  => x"F1",  -- FW ISR only
            TDEST_VIOLATION_MSG_G => x"F0",  -- FW ISR only
            BRAM_EN_G             => true,
            FIFO_ADDR_WIDTH_G     => 9,
            REM_BASE_ADDR_G       => AXI_CONFIG_C(EVR_CORE_INDEX_C).baseAddr,  -- remote base address offset
            AXI_ERROR_RESP_G      => AXI_ERROR_RESP_G,
            AXIS_CONFIG_G         => EMAC_AXIS_CONFIG_C)
         port map (
            -- AXI-Lite and AXIS Interfaces
            axilClk          => axilClk,
            axilRst          => axilRst,
            axilReadMaster   => axilReadMasters(EVR_ISR_INDEX_C),
            axilReadSlave    => axilReadSlaves(EVR_ISR_INDEX_C),
            axilWriteMaster  => axilWriteMasters(EVR_ISR_INDEX_C),
            axilWriteSlave   => axilWriteSlaves(EVR_ISR_INDEX_C),
            mAxilReadMaster  => mAxilReadMaster,
            mAxilReadSlave   => mAxilReadSlave,
            mAxilWriteMaster => mAxilWriteMaster,
            mAxilWriteSlave  => mAxilWriteSlave,
            mAxisMaster      => evrIrqMaster,
            mAxisSlave       => evrIrqSlave,
            -- IRQ Interface
            irqActive        => irqActive,
            irqEnable        => irqEnable,
            irqReq           => irqReq,
            -- EVR Interface
            evrClk           => recClk,
            evrRst           => recRst,
            gtLinkUp         => timingBus_i.v1.linkUp,
            gtRxData         => timingBus_i.v1.gtRxData,
            gtRxDataK        => timingBus_i.v1.gtRxDataK,
            gtRxDispErr      => timingBus_i.v1.gtRxDispErr,
            gtRxDecErr       => timingBus_i.v1.gtRxDecErr,
            rxLinkUp         => rxLinkUp,
            rxError          => rxError,
            rxData           => rxData,
            rxDataK          => rxDataK);


   -----------
   -- AXIS MUX
   -----------
   U_AxiStreamMux : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => 2,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => APP_STREAM_ROUTES_C,
         PIPE_STAGES_G  => 1)
      port map (
         -- Clock and reset
         axisClk         => axilClk,
         axisRst         => axilRst,
         -- Slaves
         sAxisMasters(0) => sAxisMaster,
         sAxisMasters(1) => evrIrqMaster,
         sAxisSlaves(0)  => sAxisSlave,
         sAxisSlaves(1)  => evrIrqSlave,
         -- Master
         mAxisMaster     => mAxisMaster,
         mAxisSlave      => mAxisSlave);

   end generate;

   NO_GEN_EVR : if (MR_LCLS_APP_G = false) generate

      mAxisMaster <= sAxisMaster;
      sAxisSlave  <= mAxisSlave;

   end generate;

end mapping;
