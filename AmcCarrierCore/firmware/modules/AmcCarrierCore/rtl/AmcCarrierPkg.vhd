-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2015-09-14
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

package AmcCarrierPkg is
   ---------------------------------------------------
   -- MPS: Configurations, Constants and Records Types
   ---------------------------------------------------
   constant MPS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(2);

   constant MPS_BCM_TYPE_C : slv(4 downto 0) := "10000";  -- Type = 0x10
   constant MPS_BCM_LEN_C  : positive        := 1;        -- This number is still TBD

   constant MPS_BLEN_TYPE_C : slv(4 downto 0) := "10001";  -- Type = 0x11
   constant MPS_BLEN_LEN_C  : positive        := 1;        -- This number is still TBD

   constant MPS_BPM_TYPE_C : slv(4 downto 0) := "10010";  -- Type = 0x12
   constant MPS_BPM_LEN_C  : positive        := 1;        -- This number is still TBD

   constant MPS_LLRF_TYPE_C : slv(4 downto 0) := "10011";  -- Type = 0x13
   constant MPS_LLRF_LEN_C  : positive        := 1;        -- This number is still TBD

   constant MPS_NULL_TYPE_C : slv(4 downto 0) := "11111";  -- Type = 0x1F
   constant MPS_NULL_LEN_C  : positive        := 1;

   ---------------------------------------------------
   -- BSI: Configurations, Constants and Records Types
   ---------------------------------------------------
   constant BSI_MAC_SIZE_C : natural := 4;

   type BsiDataType is record
      slotNumber : slv(7 downto 0);
      crateId    : slv(15 downto 0);
      macAddress : Slv48Array(BSI_MAC_SIZE_C-1 downto 1);  --  big-Endian format 
   end record;
   
   constant BSI_DATA_INIT_C : BsiDataType := (
      slotNumber => x"00",
      crateId    => x"0000",
      macAddress => (others => (others => '0')));

end AmcCarrierPkg;
