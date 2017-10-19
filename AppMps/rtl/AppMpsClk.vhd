-------------------------------------------------------------------------------
-- File       : AppMpsClk.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2017-10-19
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

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsClk is
   generic (
      TPD_G         : time    := 1 ns;
      MPS_SLOT_G    : boolean := false;
      SIM_SPEEDUP_G : boolean := false);
   port (
      -- Stable Clock and Reset 
      axilClk      : in  sl;
      axilRst      : in  sl;
      -- MPS Clocks and Resets
      mps125MHzClk : out sl;
      mps125MHzRst : out sl;
      mps312MHzClk : out sl;
      mps312MHzRst : out sl;
      mps625MHzClk : out sl;
      mps625MHzRst : out sl;
      mpsTholdClk  : out sl;
      mpsTholdRst  : out sl;
      mpsPllLocked : out sl;
      mpsPllRst    : in  sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- Backplane MPS Ports
      mpsClkIn     : in  sl;
      mpsClkOut    : out sl);
end AppMpsClk;

architecture mapping of AppMpsClk is

   signal mpsRefClk     : sl;
   signal mpsClk        : sl;
   signal mpsRst        : sl;
   signal mpsReset      : sl;
   signal mpsMmcmClkOut : slv(2 downto 0);
   signal mpsMmcmRstOut : slv(2 downto 0);
   signal locked        : sl;

begin

   U_IBUF : IBUF
      port map (
         I => mpsClkIn,
         O => mpsRefClk);

   mpsClk   <= axilClk when(MPS_SLOT_G) else mpsRefClk;
   mpsRst   <= axilRst when(MPS_SLOT_G) else '0';
   mpsReset <= mpsRst or mpsPllRst;

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
         CLKOUT0_DIVIDE_F_G => 2.0,     -- 625 MHz = 1.25 GHz/2.0
         CLKOUT0_RST_HOLD_G => 4,
         CLKOUT1_DIVIDE_G   => 4,       -- 312.5 MHz = 1.25 GHz/4
         CLKOUT2_DIVIDE_G   => 10)      -- 125 MHz = 1.25 GHz/10
      port map(
         -- Clock Input
         clkIn  => mpsClk,
         rstIn  => mpsReset,
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
         clk     => axilClk,
         dataIn  => locked,
         dataOut => mpsPllLocked);

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

   U_PLL : entity work.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G    => 6.4,      -- 156.25 MHz
         DIVCLK_DIVIDE_G   => 1,        -- 156.25 MHz/1
         CLKFBOUT_MULT_G   => 4,        -- 625 MHz = 156.25 MHz x 4
         CLKOUT0_DIVIDE_G  => 10)       -- 62.5 MHz = 625 MHz/10
      port map(
         -- Clock Input
         clkIn     => axilClk,
         rstIn     => axilRst,
         -- Clock Outputs
         clkOut(0) => mpsTholdClk,      -- Stable clock for register access
         -- Reset Outputs
         rstOut(0) => mpsTholdRst);

end mapping;
