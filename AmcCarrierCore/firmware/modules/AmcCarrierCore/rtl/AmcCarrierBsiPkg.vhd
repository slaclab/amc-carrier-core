-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsiPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2015-09-08
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

package AmcCarrierBsiPkg is

   type BsiDataType is record
      -- General ATCA Information
      slot           : slv(3 downto 0);
      -- XAUI Information (ATCA ZONE 2)
      xauiMacAddress : slv(47 downto 0);
      xauiIpAddress  : slv(31 downto 0);
      -- RTM Information
      rtmMacAddress  : slv(47 downto 0);
      rtmIpAddress   : slv(31 downto 0);
   end record;
   
   constant BSI_DATA_INIT_C : BsiDataType := (
      -- General ATCA Information
      slot           => x"1",
      -- XAUI Information
      xauiMacAddress => x"0A0300564400",
      xauiIpAddress  => x"0A02A8C0",
      -- RTM Information
      rtmMacAddress  => x"0B0300564400",
      rtmIpAddress   => x"0B02A8C0");

end AmcCarrierBsiPkg;
