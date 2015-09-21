-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2015-09-21
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

   constant AXI_CLK_FREQ_C : real := 156.25E+6;  -- In units of HZ

   -----------------------------------------------------------
   -- Application: Configurations, Constants and Records Types
   -----------------------------------------------------------
   subtype AppType is slv(4 downto 0);
   constant APP_MPS_DIN_TYPE_C : AppType := toSlv(0, AppType'length);   -- Type =  0 = 0x00
   constant APP_PLIC_TYPE_C    : AppType := toSlv(1, AppType'length);   -- Type =  1 = 0x01
   constant APP_PIC_TYPE_C     : AppType := toSlv(2, AppType'length);   -- Type =  2 = 0x02
   constant APP_BCM_TYPE_C     : AppType := toSlv(16, AppType'length);  -- Type = 16 = 0x10
   constant APP_BLEN_TYPE_C    : AppType := toSlv(17, AppType'length);  -- Type = 17 = 0x11
   constant APP_BPM_TYPE_C     : AppType := toSlv(18, AppType'length);  -- Type = 18 = 0x12
   constant APP_LLRF_TYPE_C    : AppType := toSlv(19, AppType'length);  -- Type = 19 = 0x13
   constant APP_NULL_TYPE_C    : AppType := toSlv(31, AppType'length);  -- Type = 31 = 0x1F

   ---------------------------------------------------
   -- MPS: Configurations, Constants and Records Types
   ---------------------------------------------------   
   constant MPS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(2);

   function getMpsChCnt(appType        : AppType) return natural;
   function getMpsThresholdCnt(appType : AppType) return natural;

   -------------------------------------------------------------      
   -- Fast Feedback: Configurations, Constants and Records Types
   -------------------------------------------------------------      
   function getFfbChCnt(appType : AppType) return natural;

   type FfbDataType is record
      valid     : sl;
      testMode  : sl;
      app       : AppType;
      appId     : slv(15 downto 0);
      timeStamp : slv(63 downto 0);
      message   : Slv32Array(31 downto 0);
   end record;
   type FfbDataArray is array (natural range <>) of FfbDataType;
   constant FFB_DATA_INIT_C : FfbDataType := (
      valid     => '0',
      testMode  => '0',
      app       => (others => '0'),
      appId     => (others => '0'),
      timeStamp => (others => '0'),
      message   => (others => (others => '0')));   

   ---------------------------------------------------
   -- BSI: Configurations, Constants and Records Types
   ---------------------------------------------------
   constant BSI_MAC_SIZE_C : natural := 4;

   type BsiDataType is record
      slotNumber : slv(7 downto 0);
      crateId    : slv(15 downto 0);
      macAddress : Slv48Array(BSI_MAC_SIZE_C-1 downto 1);  --  big-Endian format 
   end record;
   type BsiDataArray is array (natural range <>) of BsiDataType;
   constant BSI_DATA_INIT_C : BsiDataType := (
      slotNumber => x"00",
      crateId    => x"0000",
      macAddress => (others => (others => '0')));

end package AmcCarrierPkg;

package body AmcCarrierPkg is

   function getMpsChCnt (appType : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      case appType is
         when APP_MPS_DIN_TYPE_C => retVar := 0;  -- TBD value
         when APP_PLIC_TYPE_C    => retVar := 0;  -- TBD value
         when APP_PIC_TYPE_C     => retVar := 0;  -- TBD value
         when APP_BCM_TYPE_C     => retVar := 0;  -- TBD value
         when APP_BLEN_TYPE_C    => retVar := 0;  -- TBD value
         when APP_BPM_TYPE_C     => retVar := 0;  -- TBD value
         when APP_LLRF_TYPE_C    => retVar := 0;  -- TBD value
         when others             => retVar := 0;
      end case;
      return retVar;
   end function;

   function getMpsThresholdCnt (appType : AppType) return natural is
      variable retVar : natural range 0 to 256;
   begin
      case appType is
         when APP_MPS_DIN_TYPE_C => retVar := 0;  -- TBD value
         when APP_PLIC_TYPE_C    => retVar := 0;  -- TBD value
         when APP_PIC_TYPE_C     => retVar := 0;  -- TBD value
         when APP_BCM_TYPE_C     => retVar := 0;  -- TBD value
         when APP_BLEN_TYPE_C    => retVar := 0;  -- TBD value
         when APP_BPM_TYPE_C     => retVar := 0;  -- TBD value
         when APP_LLRF_TYPE_C    => retVar := 0;  -- TBD value
         when others             => retVar := 0;
      end case;
      return retVar;
   end function;

   function getFfbChCnt (appType : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      case appType is
         when APP_MPS_DIN_TYPE_C => retVar := 0;  -- TBD value
         when APP_PLIC_TYPE_C    => retVar := 0;  -- TBD value
         when APP_PIC_TYPE_C     => retVar := 0;  -- TBD value
         when APP_BCM_TYPE_C     => retVar := 0;  -- TBD value
         when APP_BLEN_TYPE_C    => retVar := 0;  -- TBD value
         when APP_BPM_TYPE_C     => retVar := 0;  -- TBD value
         when APP_LLRF_TYPE_C    => retVar := 0;  -- TBD value
         when others             => retVar := 0;
      end case;
      return retVar;
   end function;
   
end package body AmcCarrierPkg;
