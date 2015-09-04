-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : LclsTimingPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-09
-- Last update: 2015-07-10
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

package LclsTimingPkg is

   -- LCLS-I Timing Data Type
   type LclsV1TimingDataType is record
      linkUp : sl;
   end record;
   constant LCLS_V1_TIMING_DATA_INIT_C : LclsV1TimingDataType := (
      linkUp => '0'); 

   -- LCLS-II Timing Data Type
   type LclsV2TimingDataType is record
      linkUp : sl;
   end record;
   constant LCLS_V2_TIMING_DATA_INIT_C : LclsV2TimingDataType := (
      linkUp => '0');      

   type LclsTimingDataType is record
      v1 : LclsV1TimingDataType;
      v2 : LclsV2TimingDataType;
   end record;
   constant LCLS_TIMING_DATA_INIT_C : LclsTimingDataType := (
      v1 => LCLS_V1_TIMING_DATA_INIT_C,
      v2 => LCLS_V2_TIMING_DATA_INIT_C);       

end package;
