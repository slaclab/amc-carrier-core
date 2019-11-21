-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;

package AppTopPkg is

   type AppTopJesdRouteType is array (4 downto 0) of natural;
   type AppTopJesdRouteArray is array (1 downto 0) of AppTopJesdRouteType;

   constant DEV_CLK0_SEL_C : slv(1 downto 0) := toSLv(0, 2);
   constant DEV_CLK1_SEL_C : slv(1 downto 0) := toSLv(1, 2);
   constant DEV_CLK2_SEL_C : slv(1 downto 0) := toSLv(2, 2);
   constant DEV_CLK3_SEL_C : slv(1 downto 0) := toSLv(3, 2);  -- KU060 only

   constant DAC_SIG_WIDTH_C : positive := 7;

   constant JESD_ROUTES_INIT_C : AppTopJesdRouteType := (
      0 => 0,
      1 => 1,
      2 => 2,
      3 => 3,
      4 => 4);

   constant JESD_CH0_CH1_SWAP_C : AppTopJesdRouteType := (
      0 => 1,  -- Swap CH0 and CH1 to match the front panel labels
      1 => 0,  -- Swap CH0 and CH1 to match the front panel labels
      2 => 2,
      3 => 3,
      4 => 4);

   type DacSigCtrlType is record
      start : slv(4 downto 0);
   end record;
   type DacSigCtrlArray is array (natural range <>) of DacSigCtrlType;
   constant DAC_SIG_CTRL_INIT_C : DacSigCtrlType := (
      start => (others => '0'));

   type DacSigStatusType is record
      sow     : slv(4 downto 0);  -- Start of waveform strobe (running = '1' and RAM Address = 0x0)   
      running : slv(4 downto 0);
   end record;
   type DacSigStatusArray is array (natural range <>) of DacSigStatusType;
   constant DAC_SIG_STATUS_INIT_C : DacSigStatusType := (
      sow     => (others => '0'),
      running => (others => '0'));

end package AppTopPkg;
