-------------------------------------------------------------------------------
-- File       : AppMpsClk.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2018-08-09
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

   signal clkFbIn  : sl;
   signal clkFbOut : sl;
   signal clkout0  : sl;
   signal clkout1  : sl;

begin

   U_IBUF : IBUF
      port map (
         I => mpsClkIn,
         O => mpsRefClk);

   GEN_MPS_SLOT : if (MPS_SLOT_G = true) generate

      mpsClk <= axilClk;
      mpsRst <= axilRst;

      U_ClkOutBufSingle : entity work.ClkOutBufSingle
         generic map(
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn  => mpsMmcmClkOut(2),
            clkOut => mpsClkOut);

   end generate;

   GEN_APP_SLOT : if (MPS_SLOT_G = false) generate

      U_Bufg : BUFG
         port map (
            I => mpsRefClk,
            O => mpsClk);
      mpsRst    <= '0';
      mpsClkOut <= '0';

   end generate;

   mpsReset <= mpsRst or mpsPllRst;

   U_MpsSerdesPll : PLLE3_ADV
      generic map (
         STARTUP_WAIT       => "FALSE",
         CLKIN_PERIOD       => ite(MPS_SLOT_G, 6.4, 8.0),
         DIVCLK_DIVIDE      => 1,
         CLKFBOUT_MULT      => ite(MPS_SLOT_G, 8, 10),  -- 1.25 GHz
         CLKOUT0_DIVIDE     => 2,       -- 625 MHz = 1.25 GHz/2
         CLKOUT1_DIVIDE     => 10,      -- 125 MHz = 1.25 GHz/10
         CLKOUT0_PHASE      => 0.0,
         CLKOUT1_PHASE      => 0.0,
         CLKOUT0_DUTY_CYCLE => 0.5,
         CLKOUT1_DUTY_CYCLE => 0.5)
      port map (
         DCLK        => axilClk,
         DRDY        => open,
         DEN         => '0',
         DWE         => '0',
         DADDR       => (others => '0'),
         DI          => (others => '0'),
         DO          => open,
         PWRDWN      => '0',
         RST         => mpsReset,
         CLKIN       => mpsClk,
         CLKOUTPHYEN => '0',
         CLKFBOUT    => clkFbOut,
         CLKFBIN     => clkFbIn,
         LOCKED      => locked,
         CLKOUT0     => clkout0,
         CLKOUT1     => clkout1);

   U_Bufg : BUFG
      port map (
         I => clkFbOut,
         O => clkFbIn);

   U_Bufg625 : BUFG
      port map (
         I => clkout0,
         O => mpsMmcmClkOut(0));

   U_Rst625 : entity work.RstSync
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1')
      port map (
         clk      => mpsMmcmClkOut(0),
         asyncRst => locked,
         syncRst  => mpsMmcmRstOut(0));

   ------------------------------------------------------------------------------------------------------
   -- 312.5 MHz is the OSERDESE3's CLKDIV port
   -- Refer to "Figure 3-49: Sub-Optimal to Optimal Clocking Topologies for OSERDESE3" in UG949 (v2018.2)
   ------------------------------------------------------------------------------------------------------
   U_Bufg312 : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)            -- 312.5 MHz = 625 MHz/2
      port map (
         I   => clkout0,                -- 625 MHz
         CE  => '1',
         CLR => '0',
         O   => mpsMmcmClkOut(1));      -- 312.5 MHz

   U_Rst312 : entity work.RstSync
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1')
      port map (
         clk      => mpsMmcmClkOut(1),
         asyncRst => locked,
         syncRst  => mpsMmcmRstOut(1));

   U_Bufg125 : BUFG
      port map (
         I => clkout1,
         O => mpsMmcmClkOut(2));

   U_Rst125 : entity work.RstSync
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1')
      port map (
         clk      => mpsMmcmClkOut(2),
         asyncRst => locked,
         syncRst  => mpsMmcmRstOut(2));

   mps625MHzClk <= mpsMmcmClkOut(0);
   mps625MHzRst <= mpsMmcmRstOut(0);

   mps312MHzClk <= mpsMmcmClkOut(1);
   mps312MHzRst <= mpsMmcmRstOut(1);

   mps125MHzClk <= mpsMmcmClkOut(2);
   mps125MHzRst <= mpsMmcmRstOut(2);

   Sync_locked : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => locked,
         dataOut => mpsPllLocked);

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
         CLKFBOUT_MULT_G   => 8,        -- 1.25 GHz = 156.25 MHz x 8
         CLKOUT0_DIVIDE_G  => 20)       -- 62.5 MHz = 1.25 GHz/20
      port map(
         -- Clock Input
         clkIn     => axilClk,
         rstIn     => axilRst,
         -- Clock Outputs
         clkOut(0) => mpsTholdClk,      -- Stable clock for register access
         -- Reset Outputs
         rstOut(0) => mpsTholdRst);

end mapping;
