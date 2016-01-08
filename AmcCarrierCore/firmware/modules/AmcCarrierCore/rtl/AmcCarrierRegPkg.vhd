-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierRegPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2015-10-02
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
use work.AmcCarrierPkg.all;

package AmcCarrierRegPkg is

   constant AXI_CLK_FREQ_C   : real := 156.25E+6;                        -- In units of Hz
   constant AXI_CLK_PERIOD_C : real := getRealDiv(1.0, AXI_CLK_FREQ_C);  -- In units of seconds

   ---------------------------------------------
   -- Register Mapping: 1st Layer base addresses
   ---------------------------------------------
   constant VERSION_ADDR_C    : slv(31 downto 0) := x"00000000";
   constant SYSMON_ADDR_C     : slv(31 downto 0) := x"01000000";
   constant BOOT_MEM_ADDR_C   : slv(31 downto 0) := x"02000000";
   constant XBAR_ADDR_C       : slv(31 downto 0) := x"03000000";
   constant CONFIG_I2C_ADDR_C : slv(31 downto 0) := x"04000000";
   constant CLK_I2C_ADDR_C    : slv(31 downto 0) := x"05000000";
   constant DDR_I2C_ADDR_C    : slv(31 downto 0) := x"06000000";
   constant IPMC_ADDR_C       : slv(31 downto 0) := x"07000000";
   constant TIMING_ADDR_C     : slv(31 downto 0) := x"08000000";
   constant BSA_ADDR_C        : slv(31 downto 0) := X"09000000";
   constant XAUI_ADDR_C       : slv(31 downto 0) := x"0A000000";
   constant DDR_ADDR_C        : slv(31 downto 0) := x"0B000000";
   constant MPS_ADDR_C        : slv(31 downto 0) := x"0C000000";
   constant APP_ADDR_C        : slv(31 downto 0) := x"80000000";
   
   constant XBAR_TIME_GEN_C : Slv2Array(3 downto 0) := (
      3 => "01",                        -- OUT[3] = IN[1], DIST1 = FPGA
      2 => "01",                        -- OUT[2] = IN[1], DIST0 = FPGA
      1 => "01",                        -- OUT[1] = IN[1], FPGA  = FPGA (loopback)
      0 => "01");                       -- OUT[0] = IN[1], RTM0  = FPGA

   constant XBAR_MPS_II_LINK_C : Slv2Array(3 downto 0) := (
      3 => "11",                        -- OUT[3] = IN[3], DIST1 = RTM1 (LCLS-II)
      2 => "11",                        -- OUT[2] = IN[3], DIST0 = RTM1 (LCLS-II)
      1 => "11",                        -- OUT[1] = IN[3], FPGA  = RTM1 (LCLS-II)
      0 => "00");                       -- OUT[0] = IN[0], RTM0  = RTM0 (loopback)

   constant XBAR_MPS_I_LINK_C : Slv2Array(3 downto 0) := (
      3 => "00",                        -- OUT[3] = IN[0], DIST1 = RTM0 (LCLS-I)
      2 => "00",                        -- OUT[2] = IN[0], DIST0 = RTM0 (LCLS-I)
      1 => "00",                        -- OUT[1] = IN[0], FPGA  = RTM0 (LCLS-I)
      0 => "00");                       -- OUT[0] = IN[0], RTM0  = RTM0 (loopback)      

   constant XBAR_APP_NODE_C : Slv2Array(3 downto 0) := (
      3 => "01",                        -- OUT[3] = IN[1], DIST1 = FPGA
      2 => "01",                        -- OUT[2] = IN[1], DIST0 = FPGA
      1 => "10",                        -- OUT[1] = IN[2], FPGA  = Backplane timing
      0 => "00");                       -- OUT[0] = IN[0], RTM0  = RTM0 (loopback)      

   function xbarDefault(appType : AppType; sel : boolean) return Slv2Array;

end package AmcCarrierRegPkg;

package body AmcCarrierRegPkg is

   function xbarDefault (appType : AppType; sel : boolean) return Slv2Array is
      variable retVar : Slv2Array(3 downto 0);
   begin
      case appType is
         -- Check for Timing Generator Node
         when APP_TIME_GEN_TYPE_C =>
            retVar := XBAR_TIME_GEN_C;
         -- Check for MPS Link Node
         when APP_MPS_LINK_TYPE_C =>
            if sel then
               retVar := XBAR_MPS_I_LINK_C;
            else
               retVar := XBAR_MPS_II_LINK_C;
            end if;
         -- Else Application Node
         when others =>
            retVar := XBAR_APP_NODE_C;
      end case;
      return retVar;
   end function;

end package body AmcCarrierRegPkg;
