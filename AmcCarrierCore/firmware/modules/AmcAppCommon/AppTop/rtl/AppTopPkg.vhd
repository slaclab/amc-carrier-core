-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AppTopPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2016-11-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 AMC Carrier Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 AMC Carrier Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;

package AppTopPkg is

   constant DEV_CLK0_SEL_C : slv(1 downto 0) := toSLv(0, 2);
   constant DEV_CLK1_SEL_C : slv(1 downto 0) := toSLv(1, 2);
   constant DEV_CLK2_SEL_C : slv(1 downto 0) := toSLv(2, 2);
   constant DEV_CLK3_SEL_C : slv(1 downto 0) := toSLv(3, 2);  -- KU060 only

   type AppTopTrigType is record
      trigPulse : slv(15 downto 0);
      timeStamp : slv(63 downto 0);
      pulseId   : slv(31 downto 0);
      bsa       : slv(127 downto 0);
      dmod      : slv(191 downto 0);
   end record;

   type DacSigCtrlType is record
      start : sl;
   end record;
   type DacSigCtrlArray is array (natural range <>) of DacSigCtrlType;
   constant DAC_SIG_CTRL_INIT_C : DacSigCtrlType := (
      start => '0');

   type DacSigStatusType is record
      running : sl;
   end record;
   type DacSigStatusArray is array (natural range <>) of DacSigStatusType;
   constant DAC_SIG_STATUS_INIT_C : DacSigStatusType := (
      running => '0');      

end package AppTopPkg;

