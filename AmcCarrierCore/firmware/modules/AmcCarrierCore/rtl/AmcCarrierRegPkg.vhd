-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierRegPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2015-09-18
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

package AmcCarrierRegPkg is

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
   constant XAUI_ADDR_C       : slv(31 downto 0) := x"09000000";
   constant DDR_ADDR_C        : slv(31 downto 0) := x"0A000000";
   constant MPS_ADDR_C        : slv(31 downto 0) := x"0B000000";
   constant APP_ADDR_C        : slv(31 downto 0) := x"80000000";

end AmcCarrierRegPkg;
