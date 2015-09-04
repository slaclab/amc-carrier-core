-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsFastPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-15
-- Last update: 2015-06-16
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

package MpsFastPkg is

   constant MPS_FAST_COMMA_10B_C : Slv10Array(1 downto 0) := ("1010000011", "0101111100");  -- K28.5, 0xBC
   constant MPS_FAST_COMMA_8B_C  : slv(7 downto 0)        := "10111100";  -- K28.5, 0xBC
   constant MPS_FAST_DATAK_C     : slv(3 downto 0)        := "1000";

end package;
