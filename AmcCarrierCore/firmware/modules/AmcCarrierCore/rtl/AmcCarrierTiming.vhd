-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-09-28
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

library unisim;
use unisim.vcomponents.all;


entity AmcCarrierTiming is
   generic (
      TPD_G               : time            := 1 ns;
      APP_TYPE_G          : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G    : slv(1 downto 0) := AXI_RESP_DECERR_C;
      STANDALONE_TIMING_G : boolean         := false);  -- true = LCLS-I timing only
   port (
      -- AXI-Lite Interface
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Timing Interface 
      recTimingClk     : out sl;
      recTimingRst     : out sl;
      timingClk     : in  sl;
      timingRst     : in  sl;
      timingData    : out TimingDataType;
      timingPhy        : in  TimingPhyType;             -- Input for timing generator only
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
   signal rxPolarity     : sl;
   signal rxOutClk       : sl;
   signal txReset        : sl;
   signal txUsrClk       : sl;
   signal txUsrClkActive : sl;
   signal txResetDone    : sl;
   signal txData         : slv(15 downto 0);
   signal txDataK        : slv(1 downto 0);
   signal txOutClk       : sl;
   signal loopback       : slv(2 downto 0);


begin

   -------------------------------------------------------------------------------------------------
   -- Clock Buffers
   -------------------------------------------------------------------------------------------------
   TIMING_REFCLK_IBUFDS_GTE3 : IBUFDS_GTE3
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
         CLR     => '0',
         CEMASK  => '1',
         CLRMASK => '1',
         DIV     => "000",
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
         rxData         => rxData,
         rxDataK        => rxDataK,
         rxDispErr      => rxDispErr,
         rxDecErr       => rxDecErr,
         rxPolarity     => rxPolarity,
         rxOutClk       => rxOutClk,
         txReset        => txReset,
         txUsrClk       => txUsrClk,
         txUsrClkActive => txUsrClkActive,
         txResetDone    => txResetDone,
         txData         => txData,
         txDataK        => txDataK,
         txOutClk       => txOutClk,
         loopback       => loopback);

   -- Run recovered clock through bufg_gt
   TIMING_RECCLK_BUFG_GT : BUFG_GT
      port map (
         I       => rxOutClk,
         CE      => '1',
         CLR     => '0',
         CEMASK  => '1',
         CLRMASK => '1',
         DIV     => "000",
         O       => timingRecClkG);

   -- Loop back tx clk though BUFG_GT too. Maybe just drive 0 instead?
--    TIMING_RECCLK_BUFG_GT : BUFG_GT
--       port map (
--          I       => txOutClk,
--          CE      => '1',
--          CLR     => '0',
--          CEMASK  => '1',
--          CLRMASK => '1',
--          DIV     => "000",
--          O       => txUsrClk);


   ------------------------------------------------------------------------------------------------
   -- Pass recovered clock through MMCM (maybe unnecessary?)
   ------------------------------------------------------------------------------------------------


   recTimingRst <= '0';

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

   -------------------------------------------------------------------------------------------------
   -- AxiLiteCrossbar
   -------------------------------------------------------------------------------------------------
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

   ------------------------------------------------------------------------------------------------
   -- Timing Core
   -- Decode timing message from GTH and distribute to system
   ------------------------------------------------------------------------------------------------



end mapping;
