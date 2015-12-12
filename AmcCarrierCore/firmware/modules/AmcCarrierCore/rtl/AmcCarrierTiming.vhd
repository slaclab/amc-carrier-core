-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-11-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
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
      TPD_G               : time            := 1 ns;
      APP_TYPE_G          : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G    : slv(1 downto 0) := AXI_RESP_DECERR_C;
      STANDALONE_TIMING_G : boolean         := false);  -- true = LCLS-I timing only
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
      appTimingPhy     : in  TimingPhyType;             -- Input for timing generator only
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

   signal timingRefClk     : sl;
   signal timingRefClkG    : sl;
   signal timingRefClkDiv2 : sl;

   signal timingRecClkG : sl;


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
   signal rxOutClk       : sl;
   signal txReset        : sl;
   signal txUsrClk       : sl;
   signal txUsrRst       : sl;
   signal txUsrClkActive : sl;
   signal txResetDone    : sl;
   signal timingPhy      : TimingPhyType;
   signal coreTimingPhy  : TimingPhyType;
   signal txOutClk       : sl;
   signal loopback       : slv(2 downto 0);
   signal rxPolarity     : sl;

begin

   recTimingClk     <= timingRecClkG;
   recTimingRst     <= not(rxResetDone);
   bsaTimingClk     <= timingRecClkG;
   bsaTimingRst     <= not(rxResetDone);

   TIMING_GEN_CLK: if APP_TYPE_G = APP_TIME_GEN_TYPE_C generate
     timingPhy      <= appTimingPhy;
   end generate TIMING_GEN_CLK;

   NOT_TIMING_GEN_CLK: if APP_TYPE_G /= APP_TIME_GEN_TYPE_C generate
     timingPhy      <= coreTimingPhy;
   end generate NOT_TIMING_GEN_CLK;
   
   bsaTimingBus     <= TIMING_BUS_INIT_C;

   loopback         <= "000";

   txUsrRst         <= not(txResetDone);
   appTimingPhyClk  <= txUsrClk;
   appTimingPhyRst  <= txUsrRst;
   txUsrClkActive   <= '1';
   txReset          <= '0';
   rxUsrClk         <= timingRecClkG;
   rxUsrClkActive   <= '1';
   
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
         ODIV2 => timingRefClkDiv2,     -- Frequency the same as jesdRefClk
         O     => timingRefClk);

   TIMING_REFCLK_BUFG_GT : BUFG_GT
      port map (
         I       => timingRefClkDiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide-by-1
         O       => timingRefClkG);

   -------------------------------------------------------------------------------------------------
   -- GTH Timing Receiver
   -------------------------------------------------------------------------------------------------
   TimingGthCoreWrapper_1 : entity work.TimingGthCoreWrapper
      generic map (
         TPD_G => TPD_G)
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
         rxOutClk       => rxOutClk,
         txInhibit      => '0',
         txPolarity     => timingPhy.polarity,
         txReset        => txReset,
         txUsrClk       => txUsrClk,
         txUsrClkActive => txUsrClkActive,
         txResetDone    => txResetDone,
         txData         => timingPhy.data,
         txDataK        => timingPhy.dataK,
         txOutClk       => txOutClk,
         loopback       => loopback);

   -- Run recovered clock through bufg_gt
   TIMING_RECCLK_BUFG_GT : BUFG_GT
      port map (
         I       => rxOutClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide-by-1
         O       => timingRecClkG);

-- Loop back tx clk though BUFG_GT too. Maybe just drive 0 instead?
   TIMING_TXCLK_BUFG_GT : BUFG_GT
      port map (
         I       => txOutClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "001",           -- Divide-by-2
         O       => txUsrClk);


   ------------------------------------------------------------------------------------------------
   -- Pass recovered clock through MMCM (maybe unnecessary?)
   ------------------------------------------------------------------------------------------------

   -- Drive the external CLK MUX to standalone or dual timing mode
   timingClkSel <= ite(STANDALONE_TIMING_G, '1', '0');

   -- Send a copy of the timing clock to the AMC's clock cleaner
   ClkOutBufDiff_Inst : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => timingRecClkG,
         clkOutP => timingRecClkOutP,
         clkOutN => timingRecClkOutN);

   ------------------------------------------------------------------------------------------------
   -- Timing Core
   -- Decode timing message from GTH and distribute to system
   ------------------------------------------------------------------------------------------------
   TimingCore_1: entity work.TimingCore
     generic map (
       TPD_G             => TPD_G,
       TPGEN_G           => ite(APP_TYPE_G=APP_TIME_GEN_TYPE_C,true,false),
       AXIL_BASE_ADDR_G  => TIMING_ADDR_C,
       AXIL_ERROR_RESP_G => AXI_RESP_DECERR_C)
     port map (
       gtTxUsrClk      => txUsrClk,
       gtTxUsrRst      => txUsrRst,
       gtRxRecClk      => timingRecClkG,
       gtRxData        => rxData,
       gtRxDataK       => rxDataK,
       gtRxDispErr     => rxDispErr,
       gtRxDecErr      => rxDecErr,
       gtRxReset       => rxReset,
       gtRxResetDone   => rxResetDone,
       gtRxPolarity    => rxPolarity,
       appTimingClk    => appTimingClk,
       appTimingRst    => appTimingRst,
       appTimingBus    => appTimingBus,
       timingPhy       => coreTimingPhy,
       axilClk         => axilClk,
       axilRst         => axilRst,
       axilReadMaster  => axilReadMaster,
       axilReadSlave   => axilReadSlave,
       axilWriteMaster => axilWriteMaster,
       axilWriteSlave  => axilWriteSlave);

end mapping;
