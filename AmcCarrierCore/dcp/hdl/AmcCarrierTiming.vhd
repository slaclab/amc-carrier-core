-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2018-01-09
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
use work.AmcCarrierPkg.all;
use work.AmcCarrierSysRegPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierTiming is
   generic (
      TPD_G             : time            := 1 ns;
      TIME_GEN_APP_G    : boolean         := false;
      TIME_GEN_EXTREF_G : boolean         := false;
      AXI_ERROR_RESP_G  : slv(1 downto 0) := AXI_RESP_DECERR_C;
      RX_CLK_MMCM_G     : boolean         := false);
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk             : in  sl;
      axilRst             : in  sl;
      axilReadMaster      : in  AxiLiteReadMasterType;
      axilReadSlave       : out AxiLiteReadSlaveType;
      axilWriteMaster     : in  AxiLiteWriteMasterType;
      axilWriteSlave      : out AxiLiteWriteSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Timing Interface 
      recTimingClk        : out sl;
      recTimingRst        : out sl;
      appTimingClk        : in  sl;
      appTimingRst        : in  sl;
      appTimingBus        : out TimingBusType;
      appTimingPhy        : in  TimingPhyType;  -- Input for timing generator only
      appTimingPhyClk     : out sl;
      appTimingPhyRst     : out sl;
      appTimingRefClk     : out sl;
      appTimingRefClkDiv2 : out sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- LCLS Timing Ports
      timingRxP           : in  sl;
      timingRxN           : in  sl;
      timingTxP           : out sl;
      timingTxN           : out sl;
      timingRefClkInP     : in  sl;
      timingRefClkInN     : in  sl;
      timingRecClkOutP    : out sl;
      timingRecClkOutN    : out sl;
      timingClkSel        : out sl);
end AmcCarrierTiming;

architecture mapping of AmcCarrierTiming is

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := (
      0               => (
         baseAddr     => (TIMING_ADDR_C+x"00000000"),
         addrBits     => 23,
         connectivity => x"FFFF"),
      1               => (
         baseAddr     => (TIMING_ADDR_C+x"00800000"),
         addrBits     => 23,
         connectivity => x"FFFF"));

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
   signal gtRxData       : slv(15 downto 0);
   signal gtRxDataK      : slv(1 downto 0);
   signal gtRxDispErr    : slv(1 downto 0);
   signal gtRxDecErr     : slv(1 downto 0);
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

   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 2,
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
   TimingGthCoreWrapper_1 : entity work.TimingGthCoreWrapper
      generic map (
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => AXI_CROSSBAR_MASTERS_CONFIG_C(1).baseAddr,
         EXTREF_G         => TIME_GEN_EXTREF_G)
      port map (
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1),
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
         AXIL_BASE_ADDR_G  => AXI_CROSSBAR_MASTERS_CONFIG_C(0).baseAddr,
         AXIL_ERROR_RESP_G => AXI_RESP_DECERR_C)
      port map (
         gtTxUsrClk      => txUsrClk,
         gtTxUsrRst      => txUsrRst,
         gtRxRecClk      => timingRecClk,
         gtRxData        => gtRxData,
         gtRxDataK       => gtRxDataK,
         gtRxDispErr     => gtRxDispErr,
         gtRxDecErr      => gtRxDecErr,
         gtRxControl     => rxControl,
         gtRxStatus      => rxStatus,
         gtLoopback      => loopback,
         appTimingClk    => appTimingClk,
         appTimingRst    => appTimingRst,
         appTimingBus    => appBus,
         timingPhy       => coreTimingPhy,
         timingClkSel    => timingClockSel,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   process(timingRecClk)
   begin
      if rising_edge(timingRecClk) then
         -- Help meet timing
         rxData    <= gtRxData    after TPD_G;
         rxDataK   <= gtRxDataK   after TPD_G;
         rxDispErr <= gtRxDispErr after TPD_G;
         rxDecErr  <= gtRxDecErr  after TPD_G;
      end if;
   end process;

   process(appTimingClk)
   begin
      if rising_edge(appTimingClk) then
         appTimingBus.strobe <= appBus.strobe after TPD_G;  -- Pipeline for register replication during impl_1
         appTimingBus.valid  <= appBus.valid  after TPD_G;  -- Pipeline for register replication during impl_1
      end if;
   end process;
   -- No pipelining: message, V1, and V2 only updated during strobe's HIGH cycle
   appTimingBus.message <= appBus.message;
   appTimingBus.stream  <= appBus.stream;
   appTimingBus.v1      <= appBus.v1;
   appTimingBus.v2      <= appBus.v2;

   U_timingClkSel : OBUF
      port map (
         I => timingClockSel,
         O => timingClkSel);


end mapping;
