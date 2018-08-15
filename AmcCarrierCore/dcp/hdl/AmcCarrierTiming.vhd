-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2018-03-16
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.EthMacPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierSysRegPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierTiming is
   generic (
      TPD_G             : time     := 1 ns;
      TIME_GEN_APP_G    : boolean  := false;
      TIME_GEN_EXTREF_G : boolean  := false;
      CORE_TRIGGERS_G   : positive := 16;
      TRIG_PIPE_G       : natural  := 0;
      STREAM_L1_G       : boolean  := true;
      RX_CLK_MMCM_G     : boolean  := false);
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType;
      -- Timing ETH MSG Interface (axilClk domain)
      ibTimingEthMsgMaster : in  AxiStreamMasterType;
      ibTimingEthMsgSlave  : out AxiStreamSlaveType;
      obTimingEthMsgMaster : out AxiStreamMasterType;
      obTimingEthMsgSlave  : in  AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Timing Interface 
      recTimingClk         : out sl;
      recTimingRst         : out sl;
      appTimingClk         : in  sl;
      appTimingRst         : in  sl;
      appTimingBus         : out TimingBusType;
      appTimingPhy         : in  TimingPhyType;  -- Input for timing generator only
      appTimingPhyClk      : out sl;
      appTimingPhyRst      : out sl;
      appTimingRefClk      : out sl;
      appTimingRefClkDiv2  : out sl;
      appTimingTrig        : out TimingTrigType;
      ----------------
      -- Core Ports --
      ----------------   
      -- LCLS Timing Ports
      timingRxP            : in  sl;
      timingRxN            : in  sl;
      timingTxP            : out sl;
      timingTxN            : out sl;
      timingRefClkInP      : in  sl;
      timingRefClkInN      : in  sl;
      timingRecClkOutP     : out sl;
      timingRecClkOutN     : out sl;
      timingClkSel         : out sl);
end AmcCarrierTiming;

architecture mapping of AmcCarrierTiming is

   constant AXIL_CORE_INDEX_C  : integer := 0;
   constant AXIL_GTH_INDEX_C   : integer := 1;
   constant AXIL_TRIG_INDEX_C  : integer := 2;
   constant NUM_AXIL_MASTERS_C : integer := ite(CORE_TRIGGERS_G > 0, 3, 2);

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(2 downto 0) := (
      0               => (
         baseAddr     => (TIMING_ADDR_C+x"00000000"),
         addrBits     => 18,
         connectivity => x"FFFF"),
      1               => (
         baseAddr     => (TIMING_ADDR_C+x"00800000"),
         addrBits     => 23,
         connectivity => x"FFFF"),
      2               => (
         baseAddr     => (TIMING_ADDR_C+x"00040000"),
         addrBits     => 18,
         connectivity => X"FFFF"));

   signal timingRefClk     : sl;
   signal timingRefDiv2    : sl;
   signal timingRefClkDiv2 : sl;
   signal timingRecClkGt   : sl;
   signal timingRecClk     : sl;
   signal timingClockSel   : sl;

   -- Rx ports
   signal rxReset        : sl;
   signal rxUsrClkActive : sl;
   signal rxCdrStable    : sl;
   signal rxStatus       : TimingPhyStatusType;
   signal rxControl      : TimingPhyControlType;
   signal rxUsrClk       : sl;
   signal rxData         : slv(15 downto 0);
   signal rxDataK        : slv(1 downto 0);
   signal rxDispErr      : slv(1 downto 0);
   signal rxDecErr       : slv(1 downto 0);
   signal txUsrClk       : sl;
   signal txUsrRst       : sl;
   signal txUsrClkActive : sl;
   signal txStatus       : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal timingPhy      : TimingPhyType;
   signal coreTimingPhy  : TimingPhyType;
   signal loopback       : slv(2 downto 0);
   signal refclksel      : slv(2 downto 0);
   signal appBus         : TimingBusType;
   signal appExptBus     : ExptBusType;
   signal appTimingMode  : sl;
   signal timingStrobe   : sl;
   signal timingValid    : sl;

   signal axilWriteMasters : AxiLiteWriteMasterArray(2 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (2 downto 0) := (others => AXI_LITE_WRITE_SLAVE_INIT_C);
   signal axilReadMasters  : AxiLiteReadMasterArray (2 downto 0) := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray (2 downto 0)  := (others => AXI_LITE_READ_SLAVE_INIT_C);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C(NUM_AXIL_MASTERS_C-1 downto 0))
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters(NUM_AXIL_MASTERS_C-1 downto 0),
         mAxiWriteSlaves     => axilWriteSlaves (NUM_AXIL_MASTERS_C-1 downto 0),
         mAxiReadMasters     => axilReadMasters (NUM_AXIL_MASTERS_C-1 downto 0),
         mAxiReadSlaves      => axilReadSlaves (NUM_AXIL_MASTERS_C-1 downto 0));

   recTimingClk <= timingRecClk;
   recTimingRst <= not(rxStatus.resetDone);

   TIMING_GEN_CLK : if (TIME_GEN_APP_G = true) generate
      timingPhy <= appTimingPhy;
   end generate TIMING_GEN_CLK;

   NOT_TIMING_GEN_CLK : if (TIME_GEN_APP_G = false) generate
      timingPhy <= coreTimingPhy;
   end generate NOT_TIMING_GEN_CLK;

   txUsrRst        <= not(txStatus.resetDone);
   appTimingPhyClk <= txUsrClk;
   appTimingPhyRst <= txUsrRst;
   txUsrClkActive  <= '1';
--   txReset         <= rxReset;
--    rxUsrClk        <= timingRecClkG;
--    rxUsrClkActive  <= '1';

   -------------------------------------------------------------------------------------------------
   -- Clock Buffers
   -------------------------------------------------------------------------------------------------
   TIMING_REFCLK_IBUFDS_GTE3 : entity work.AmcCarrierIbufGt
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "01",  -- 2'b01: ODIV2 = Divide-by-2 version of O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => timingRefClkInP,
         IB    => timingRefClkInN,
         CEB   => '0',
         ODIV2 => timingRefDiv2,
         O     => timingRefClk);

   U_BUFG_GT_DIV2 : BUFG_GT
      port map (
         I       => timingRefDiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => timingRefClkDiv2);

   appTimingRefClk     <= timingRefClk;
   appTimingRefClkDiv2 <= timingRefClkDiv2;

   -------------------------------------------------------------------------------------------------
   -- GTH Timing Receiver
   -------------------------------------------------------------------------------------------------
   TimingGthCoreWrapper_1 : entity work.TimingGtCoreWrapper
      generic map (
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => AXI_CROSSBAR_MASTERS_CONFIG_C(AXIL_GTH_INDEX_C).baseAddr,
         EXTREF_G         => TIME_GEN_EXTREF_G)
      port map (
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (AXIL_GTH_INDEX_C),
         axilReadSlave   => axilReadSlaves (AXIL_GTH_INDEX_C),
         axilWriteMaster => axilWriteMasters(AXIL_GTH_INDEX_C),
         axilWriteSlave  => axilWriteSlaves (AXIL_GTH_INDEX_C),
         stableClk       => axilClk,
         gtRefClk        => timingRefClk,
         gtRefClkDiv2    => timingRefClkDiv2,
         gtRxP           => timingRxP,
         gtRxN           => timingRxN,
         gtTxP           => timingTxP,
         gtTxN           => timingTxN,
         rxControl       => rxControl,
         rxStatus        => rxStatus,
         rxUsrClkActive  => rxUsrClkActive,
         rxCdrStable     => rxCdrStable,
         rxUsrClk        => rxUsrClk,
         rxData          => rxData,
         rxDataK         => rxDataK,
         rxDispErr       => rxDispErr,
         rxDecErr        => rxDecErr,
         rxOutClk        => timingRecClkGt,
         txControl       => timingPhy.control,
         txStatus        => txStatus,
         txUsrClk        => txUsrClk,
         txUsrClkActive  => txUsrClkActive,
         txData          => timingPhy.data,
         txDataK         => timingPhy.dataK,
         txOutClk        => txUsrClk,
         loopback        => loopback);

   ------------------------------------------------------------------------------------------------
   -- Pass recovered clock through MMCM (maybe unnecessary?)
   ------------------------------------------------------------------------------------------------
   RX_CLK_MMCM_GEN : if (RX_CLK_MMCM_G) generate
      U_ClockManager : entity work.ClockManagerUltraScale
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => "MMCM",
            INPUT_BUFG_G       => false,
            FB_BUFG_G          => true,
            RST_IN_POLARITY_G  => '0',
            NUM_CLOCKS_G       => 1,
            -- MMCM attributes
            BANDWIDTH_G        => "OPTIMIZED",
            CLKIN_PERIOD_G     => 5.355,
            DIVCLK_DIVIDE_G    => 1,
            CLKFBOUT_MULT_F_G  => 6.500,
            CLKOUT0_DIVIDE_F_G => 6.500)
         port map(
            clkIn     => timingRecClkGt,
            rstIn     => rxStatus.resetDone,
            clkOut(0) => timingRecClk,
            rstOut(0) => open,
            locked    => rxUsrClkActive);
   end generate RX_CLK_MMCM_GEN;

   NO_RX_CLK_MMCM_GEN : if (not RX_CLK_MMCM_G) generate
      timingRecClk   <= timingRecClkGt;
      rxUsrClkActive <= '1';
   end generate NO_RX_CLK_MMCM_GEN;

   rxUsrClk <= timingRecClk;

   -- Send a copy of the timing clock to the AMC's clock cleaner
   ClkOutBufDiff_Inst : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => timingRecClk,
         clkOutP => timingRecClkOutP,
         clkOutN => timingRecClkOutN);

   ------------------------------------------------------------------------------------------------
   -- Timing Core
   -- Decode timing message from GTH and distribute to system
   ------------------------------------------------------------------------------------------------
   TimingCore_1 : entity work.TimingCore
      generic map (
         TPD_G             => TPD_G,
         TPGEN_G           => TIME_GEN_APP_G,
         STREAM_L1_G       => STREAM_L1_G,
         ETHMSG_AXIS_CFG_G => EMAC_AXIS_CONFIG_C,
         AXIL_BASE_ADDR_G  => AXI_CROSSBAR_MASTERS_CONFIG_C(AXIL_CORE_INDEX_C).baseAddr,
         AXIL_ERROR_RESP_G => AXI_RESP_DECERR_C)
      port map (
         gtTxUsrClk      => txUsrClk,
         gtTxUsrRst      => txUsrRst,
         gtRxRecClk      => timingRecClk,
         gtRxData        => rxData,
         gtRxDataK       => rxDataK,
         gtRxDispErr     => rxDispErr,
         gtRxDecErr      => rxDecErr,
         gtRxControl     => rxControl,
         gtRxStatus      => rxStatus,
         gtLoopback      => loopback,
         appTimingClk    => appTimingClk,
         appTimingRst    => appTimingRst,
         appTimingMode   => appTimingMode,
         appTimingBus    => appBus,
         exptBus         => appExptBus,
         timingPhy       => coreTimingPhy,
         timingClkSel    => timingClockSel,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (AXIL_CORE_INDEX_C),
         axilReadSlave   => axilReadSlaves (AXIL_CORE_INDEX_C),
         axilWriteMaster => axilWriteMasters(AXIL_CORE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves (AXIL_CORE_INDEX_C),
         obEthMsgMaster  => obTimingEthMsgMaster,
         obEthMsgSlave   => obTimingEthMsgSlave,
         ibEthMsgMaster  => ibTimingEthMsgMaster,
         ibEthMsgSlave   => ibTimingEthMsgSlave);

   process(appTimingClk)
   begin
      if rising_edge(appTimingClk) then
         timingStrobe <= appBus.strobe after TPD_G;  -- Pipeline for register replication during impl_1
         timingValid  <= appBus.valid  after TPD_G;  -- Pipeline for register replication during impl_1
      end if;
   end process;

   -- No pipelining: message, V1, and V2 only updated during strobe's HIGH cycle
   process(appBus, timingStrobe, timingValid)
      variable v : TimingBusType;
   begin
      v        := appBus;
      v.strobe := timingStrobe;
      v.valid  := timingValid;
      appTimingBus <= v;
   end process;

   -- Declaring the primitive because it's DCP output
   U_timingClkSel : OBUF
      port map (
         I => timingClockSel,
         O => timingClkSel);

   -----------------
   --  Core Triggers
   -----------------
   GEN_CORETRIG : if CORE_TRIGGERS_G > 0 generate
      U_CoreTrig : entity work.EvrV2CoreTriggers
         generic map (
            TPD_G           => TPD_G,
            NCHANNELS_G     => CORE_TRIGGERS_G,
            NTRIGGERS_G     => CORE_TRIGGERS_G,
            TRIG_DEPTH_G    => 19,      -- bitSize(125MHz/360Hz)
            TRIG_PIPE_G     => TRIG_PIPE_G,
            COMMON_CLK_G    => false,
            AXIL_BASEADDR_G => AXI_CROSSBAR_MASTERS_CONFIG_C(AXIL_TRIG_INDEX_C).baseAddr)
         port map (
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilWriteMaster => axilWriteMasters(AXIL_TRIG_INDEX_C),
            axilWriteSlave  => axilWriteSlaves (AXIL_TRIG_INDEX_C),
            axilReadMaster  => axilReadMasters (AXIL_TRIG_INDEX_C),
            axilReadSlave   => axilReadSlaves (AXIL_TRIG_INDEX_C),
            evrClk          => appTimingClk,
            evrRst          => appTimingRst,
            evrBus          => appBus,
            exptBus         => appExptBus,
            trigOut         => appTimingTrig,
            evrModeSel      => appTimingMode);
   end generate;

end mapping;
