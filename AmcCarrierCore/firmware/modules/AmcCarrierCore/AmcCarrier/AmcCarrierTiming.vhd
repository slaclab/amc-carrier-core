-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2016-03-21
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierTiming is
   generic (
      TPD_G            : time            := 1 ns;
      APP_TYPE_G       : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C;
      RX_CLK_MMCM_G    : boolean         := false;
      TIMING_MODE_G    : boolean         := false);  -- true = LCLS-I timing only
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType;
      -- BSA Interface (bsaTimingClk domain)
      bsaTimingClk     : out sl;
      bsaTimingRst     : out sl;
      bsaTimingBus     : out TimingBusType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Timing Interface 
      recTimingClk     : out sl;
      recTimingRst     : out sl;
      appTimingClk     : in  sl;
      appTimingRst     : in  sl;
      appTimingBus     : out TimingBusType;
      appTimingPhy     : in  TimingPhyType;          -- Input for timing generator only
      appTimingPhyClk  : out sl;
      appTimingPhyRst  : out sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- LCLS Timing Ports
      timingRxP        : in  sl;
      timingRxN        : in  sl;
      timingTxP        : out sl;
      timingTxN        : out sl;
      timingRefClkInP  : in  sl;
      timingRefClkInN  : in  sl;
      timingRecClkOutP : out sl;
      timingRecClkOutN : out sl;
      timingClkSel     : out sl);
end AmcCarrierTiming;

architecture mapping of AmcCarrierTiming is

   constant TIME_GEN_APP : boolean := (APP_TYPE_G = APP_TIME_GEN_TYPE_C or APP_TYPE_G = APP_EXTREF_GEN_TYPE_C);
     
   signal timingRefClk     : sl;
   signal timingRecClkGt   : sl;
   signal timingRecClk     : sl;

   -- Rx ports
   signal rxReset        : sl;
   signal rxUsrClkActive : sl;
   signal rxCdrStable    : sl;
   signal rxResetDone    : sl;
   signal rxUsrClk       : sl;
   signal rxData         : slv(15 downto 0);
   signal rxDataK        : slv(1 downto 0);
   signal rxDispErr      : slv(1 downto 0);
   signal rxDecErr       : slv(1 downto 0);
   signal txReset        : sl;
   signal txUsrClk       : sl;
   signal txUsrRst       : sl;
   signal txUsrClkActive : sl;
   signal txResetDone    : sl;
   signal timingPhy      : TimingPhyType;
   signal coreTimingPhy  : TimingPhyType;
   signal loopback       : slv(2 downto 0);
   signal rxPolarity     : sl;
   signal refclksel      : slv(2 downto 0);
   signal appBus         : TimingBusType;

begin

   recTimingClk <= timingRecClk;
   recTimingRst <= not(rxResetDone);
   bsaTimingClk <= timingRecClk;
   bsaTimingRst <= not(rxResetDone);

   TIMING_GEN_CLK : if TIME_GEN_APP generate
      timingPhy <= appTimingPhy;
   end generate TIMING_GEN_CLK;

   NOT_TIMING_GEN_CLK : if not TIME_GEN_APP generate
      timingPhy <= coreTimingPhy;
   end generate NOT_TIMING_GEN_CLK;

   bsaTimingBus <= TIMING_BUS_INIT_C;

   txUsrRst        <= not(txResetDone);
   appTimingPhyClk <= txUsrClk;
   appTimingPhyRst <= txUsrRst;
   txUsrClkActive  <= '1';
   txReset         <= '0';
--   txReset         <= rxReset;
--    rxUsrClk        <= timingRecClkG;
--    rxUsrClkActive  <= '1';

   -------------------------------------------------------------------------------------------------
   -- Clock Buffers
   -------------------------------------------------------------------------------------------------
   TIMING_REFCLK_IBUFDS_GTE3 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "01",    -- 2'b01: ODIV2 = Divide-by-2 version of O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => timingRefClkInP,
         IB    => timingRefClkInN,
         CEB   => '0',
         ODIV2 => open,
         O     => timingRefClk);

   -------------------------------------------------------------------------------------------------
   -- GTH Timing Receiver
   -------------------------------------------------------------------------------------------------
   TimingGthCoreWrapper_1 : entity work.TimingGthCoreWrapper
      generic map (
         TPD_G    => TPD_G,
         EXTREF_G => ite(APP_TYPE_G = APP_EXTREF_GEN_TYPE_C,true,false))
      port map (
         stableClk      => axilClk,
         gtRefClk       => timingRefClk,
         gtRxP          => timingRxP,
         gtRxN          => timingRxN,
         gtTxP          => timingTxP,
         gtTxN          => timingTxN,
         rxReset        => rxReset,
         rxUsrClkActive => rxUsrClkActive,
         rxCdrStable    => rxCdrStable,
         rxResetDone    => rxResetDone,
         rxUsrClk       => rxUsrClk,
         rxPolarity     => rxPolarity,
         rxData         => rxData,
         rxDataK        => rxDataK,
         rxDispErr      => rxDispErr,
         rxDecErr       => rxDecErr,
         rxOutClk       => timingRecClkGt,
         txInhibit      => '0',
         txPolarity     => timingPhy.polarity,
         txReset        => txReset,
         txUsrClk       => txUsrClk,
         txUsrClkActive => txUsrClkActive,
         txResetDone    => txResetDone,
         txData         => timingPhy.data,
         txDataK        => timingPhy.dataK,
         txOutClk       => txUsrClk,
         loopback       => loopback);

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
            CLKFBOUT_MULT_F_G  => 5.375,
            CLKOUT0_DIVIDE_F_G => 5.375)
         port map(
            clkIn     => timingRecClkGt,
            rstIn     => rxResetDone,
            clkOut(0) => timingRecClk,
            rstOut(0) => open,
            locked    => rxUsrClkActive);
   end generate RX_CLK_MMCM_GEN;

   NO_RX_CLK_MMCM_GEN : if (not RX_CLK_MMCM_G) generate
      timingRecClk   <= timingRecClkGt;
      rxUsrClkActive <= '1';
   end generate NO_RX_CLK_MMCM_GEN;

   rxUsrClk <= timingRecClk;

   -- Drive the external CLK MUX to standalone or dual timing mode
   timingClkSel <= ite(TIMING_MODE_G, '1', '0');

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
         TPGEN_G           => TIME_GEN_APP,
         AXIL_BASE_ADDR_G  => TIMING_ADDR_C,
         AXIL_ERROR_RESP_G => AXI_RESP_DECERR_C,
         LCLSV1_G          => TIMING_MODE_119MHZ_C )
      port map (
         gtTxUsrClk      => txUsrClk,
         gtTxUsrRst      => txUsrRst,
         gtRxRecClk      => timingRecClk,
         gtRxData        => rxData,
         gtRxDataK       => rxDataK,
         gtRxDispErr     => rxDispErr,
         gtRxDecErr      => rxDecErr,
         gtRxReset       => rxReset,
         gtRxResetDone   => rxResetDone,
         gtRxPolarity    => rxPolarity,
         gtLoopback      => loopback,
         appTimingClk    => appTimingClk,
         appTimingRst    => appTimingRst,
         appTimingBus    => appBus,
         timingPhy       => coreTimingPhy,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   process(appTimingClk)
   begin
      if rising_edge(appTimingClk) then
         appTimingBus.strobe <= appBus.strobe after TPD_G;  -- Pipeline for register replication during impl_1
      end if;
   end process;
   -- No pipelining: message, V1, and V2 only updated during strobe's HIGH cycle
   appTimingBus.message <= appBus.message;
   appTimingBus.v1      <= appBus.v1;
   appTimingBus.v2      <= appBus.v2;

end mapping;
