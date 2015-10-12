-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2015-10-08
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

use work.TimingPkg.all;

package AmcCarrierPkg is

   -----------------------------------------------------------
   -- Application: Configurations, Constants and Records Types
   -----------------------------------------------------------
   subtype AppType is slv(6 downto 0);  -- Max. Size is 7-bits

   constant APP_NULL_TYPE_C     : AppType := toSlv(0, AppType'length);
   constant APP_TIME_GEN_TYPE_C : AppType := toSlv(1, AppType'length);
   constant APP_MPS_LINK_TYPE_C : AppType := toSlv(2, AppType'length);
   constant APP_MPS_APP_TYPE_C  : AppType := toSlv(3, AppType'length);
   constant APP_PLIC_TYPE_C     : AppType := toSlv(4, AppType'length);
   constant APP_PIC_TYPE_C      : AppType := toSlv(5, AppType'length);
   constant APP_BCM_TYPE_C      : AppType := toSlv(6, AppType'length);
   constant APP_BLEN_TYPE_C     : AppType := toSlv(7, AppType'length);
   constant APP_BPM_TYPE_C      : AppType := toSlv(8, AppType'length);
   constant APP_LLRF_TYPE_C     : AppType := toSlv(9, AppType'length);

   constant APP_REG_BASE_ADDR_C : slv(31 downto 0) := x"80000000";

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

   type FfbBusType is record
      valid     : sl;
      testMode  : sl;
      app       : AppType;
      appId     : slv(15 downto 0);
      timeStamp : slv(63 downto 0);
      message   : Slv32Array(31 downto 0);
   end record;
   type FfbBusArray is array (natural range <>) of FfbBusType;
   constant FFB_BUS_INIT_C : FfbBusType := (
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

   type DiagnosticBusType is record
      strobe        : sl;
      data          : Slv32Array(31 downto 0);
      timingMessage : TimingMessageType;
   end record;
   
  constant DIAGNOSTIC_BUS_BITS_C : integer := 1 + 32*32 + TIMING_MESSAGE_BITS_C;

   function toSlv (b             : DiagnosticBusType) return slv;
   function toDiagnosticBus (vec : slv) return DiagnosticBusType;

end package AmcCarrierPkg;

package body AmcCarrierPkg is

   function getMpsChCnt (appType : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      case appType is
         when APP_PLIC_TYPE_C => retVar := 0;  -- TBD value
         when APP_PIC_TYPE_C  => retVar := 0;  -- TBD value
         when APP_BCM_TYPE_C  => retVar := 0;  -- TBD value
         when APP_BLEN_TYPE_C => retVar := 0;  -- TBD value
         when APP_BPM_TYPE_C  => retVar := 0;  -- TBD value
         when APP_LLRF_TYPE_C => retVar := 0;  -- TBD value
         when others          => retVar := 0;
      end case;
      return retVar;
   end function;

   function getMpsThresholdCnt (appType : AppType) return natural is
      variable retVar : natural range 0 to 256;
   begin
      case appType is
         when APP_PLIC_TYPE_C => retVar := 0;  -- TBD value
         when APP_PIC_TYPE_C  => retVar := 0;  -- TBD value
         when APP_BCM_TYPE_C  => retVar := 0;  -- TBD value
         when APP_BLEN_TYPE_C => retVar := 0;  -- TBD value
         when APP_BPM_TYPE_C  => retVar := 0;  -- TBD value
         when APP_LLRF_TYPE_C => retVar := 0;  -- TBD value
         when others          => retVar := 0;
      end case;
      return retVar;
   end function;

   function getFfbChCnt (appType : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      case appType is
         when APP_PLIC_TYPE_C => retVar := 0;  -- TBD value
         when APP_PIC_TYPE_C  => retVar := 0;  -- TBD value
         when APP_BCM_TYPE_C  => retVar := 0;  -- TBD value
         when APP_BLEN_TYPE_C => retVar := 0;  -- TBD value
         when APP_BPM_TYPE_C  => retVar := 0;  -- TBD value
         when APP_LLRF_TYPE_C => retVar := 0;  -- TBD value
         when others          => retVar := 0;
      end case;
      return retVar;
   end function;
   
   function toSlv (b : DiagnosticBusType) return slv is
      variable vector : slv(DIAGNOSTIC_BUS_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer := 0;
   begin
      vector(TIMING_MESSAGE_BITS_C-1 downto 0) := toSlv(b.timingMessage);
      i                                        := TIMING_MESSAGE_BITS_C;
      for j in 0 to 31 loop
         assignSlv(i, vector, b.data(j));
      end loop;
      assignSlv(i, vector, b.strobe);
      return vector;
   end function;

   function toDiagnosticBus (vec : slv) return DiagnosticBusType is
      variable b : DiagnosticBusType;
      variable i       : integer := 0;
   begin
      b.timingMessage := toTimingMessageType(vec(TIMING_MESSAGE_BITS_C-1 downto 0));
      i := TIMING_MESSAGE_BITS_C;
      for j in 0 to 31 loop
         assignRecord(i, vec, b.data(j));
      end loop;
      assignRecord(i, vec, b.strobe);
      return b;
   end function;
   
end package body AmcCarrierPkg;
