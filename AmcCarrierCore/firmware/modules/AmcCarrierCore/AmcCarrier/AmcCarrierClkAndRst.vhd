-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierClkAndRst.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2016-02-25
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

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierClkAndRst is
   generic (
      TPD_G         : time    := 1 ns;
      MPS_SLOT_G    : boolean := false;
      SIM_SPEEDUP_G : boolean := false);
   port (
      -- Reference Clocks and Resets
      ref125MHzClk : out sl;
      ref125MHzRst : out sl;
      ref156MHzClk : out sl;
      ref156MHzRst : out sl;
      ref312MHzClk : out sl;
      ref312MHzRst : out sl;
      ref625MHzClk : out sl;
      ref625MHzRst : out sl;
      gthFabClk    : out sl;
      -- AXI-Lite Clocks and Resets
      axilClk      : out sl;
      axilRst      : out sl;
      -- MPS Clocks and Resets
      mps125MHzClk : out sl;
      mps125MHzRst : out sl;
      mps312MHzClk : out sl;
      mps312MHzRst : out sl;
      mps625MHzClk : out sl;
      mps625MHzRst : out sl;
      mpsPllLocked : out sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- Common Fabricate Clock
      fabClkP      : in  sl;
      fabClkN      : in  sl;
      -- Backplane MPS Ports
      mpsClkIn     : in  sl;
      mpsClkOut    : out sl);
end AmcCarrierClkAndRst;

architecture mapping of AmcCarrierClkAndRst is

   signal gtClk         : sl;
   signal fabClk        : sl;
   signal fabRst        : sl;
   signal fabMmcmClkOut : sl;
   signal fabMmcmRstOut : sl;

   signal mpsRefClk     : sl;
   signal mpsClk        : sl;
   signal mpsRst        : sl;
   signal mpsMmcmClkOut : slv(2 downto 0);
   signal mpsMmcmRstOut : slv(2 downto 0);
   signal locked        : sl;


begin

   IBUFDS_GTE3_Inst : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => fabClkP,
         IB    => fabClkN,
         CEB   => '0',
         ODIV2 => gtClk,
         O     => gthFabClk);

   BUFG_GT_Inst : BUFG_GT
      port map (
         I       => gtClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => fabClk);

   PwrUpRst_Inst : entity work.PwrUpRst
      generic map(
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map(
         clk    => fabClk,
         rstOut => fabRst);

   U_ClkManagerAxiLite : entity work.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => true,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         BANDWIDTH_G       => "OPTIMIZED",
         CLKIN_PERIOD_G    => 6.4,
         DIVCLK_DIVIDE_G   => 1,
         CLKFBOUT_MULT_G   => 4,
         CLKOUT0_DIVIDE_G  => 4)
      port map(
         -- Clock Input
         clkIn     => fabClk,
         rstIn     => fabRst,
         -- Clock Outputs
         clkOut(0) => fabMmcmClkOut,
         -- Reset Outputs
         rstOut(0) => fabMmcmRstOut);

   axilClk <= fabMmcmClkOut;
   axilRst <= fabMmcmRstOut;

   ref156MHzClk <= fabMmcmClkOut;
   ref156MHzRst <= fabMmcmRstOut;

   U_IBUF : IBUF
      port map (
         I => mpsClkIn,
         O => mpsRefClk);

   mpsClk <= fabClk when(MPS_SLOT_G) else mpsRefClk;
   mpsRst <= fabRst when(MPS_SLOT_G) else '0';

   U_ClkManagerMps : entity work.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => ite(MPS_SLOT_G, false, true),
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 3,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => ite(MPS_SLOT_G, 6.4, 8.0),
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => ite(MPS_SLOT_G, 8.0, 10.0),  -- 1.25 GHz
         CLKOUT0_DIVIDE_F_G => 2.0,                         -- 625 MHz = 1.25 GHz/2.0
         CLKOUT0_RST_HOLD_G => 4,
         CLKOUT1_DIVIDE_G   => 4,                           -- 312.5 MHz = 1.25 GHz/4
         CLKOUT2_DIVIDE_G   => 10)                          -- 125 MHz = 1.25 GHz/10
      port map(
         -- Clock Input
         clkIn  => mpsClk,
         rstIn  => mpsRst,
         -- Clock Outputs
         clkOut => mpsMmcmClkOut,
         -- Reset Outputs
         rstOut => mpsMmcmRstOut,
         -- Locked Status
         locked => locked);

   Sync_locked : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => fabMmcmClkOut,
         dataIn  => locked,
         dataOut => mpsPllLocked);            

   ref125MHzClk <= mpsMmcmClkOut(2);
   ref125MHzRst <= mpsMmcmRstOut(2);

   ref312MHzClk <= mpsMmcmClkOut(1);
   ref312MHzRst <= mpsMmcmRstOut(1);

   ref625MHzClk <= mpsMmcmClkOut(0);
   ref625MHzRst <= mpsMmcmRstOut(0);

   mps125MHzClk <= mpsMmcmClkOut(2);
   mps125MHzRst <= mpsMmcmRstOut(2);

   mps312MHzClk <= mpsMmcmClkOut(1);
   mps312MHzRst <= mpsMmcmRstOut(1);

   mps625MHzClk <= mpsMmcmClkOut(0);
   mps625MHzRst <= mpsMmcmRstOut(0);

   U_ClkOutBufSingle : entity work.ClkOutBufSingle
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         outEnL => ite(MPS_SLOT_G, '0', '1'),
         clkIn  => mpsMmcmClkOut(2),
         clkOut => mpsClkOut);

end mapping;
