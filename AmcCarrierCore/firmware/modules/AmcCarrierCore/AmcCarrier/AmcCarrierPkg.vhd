-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierPkg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2016-08-30
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

use work.TimingPkg.all;

package AmcCarrierPkg is

   ----------------
   -- Revision Log:
   ----------------
   -- 04/15/2016 (0x00000001): Initial Build
   -- 04/19/2016 (0x00000002): Added ETH status to BSI interface
   -- 04/19/2016 (0x00000003): Added 10 second WDT to ETH Link Up
   -- 04/19/2016 (0x00000004): In AmcCarrierEth, separating the RSSI's memory access and data paths 
   --                          from the ASYNC messaging and register access as a work around until 
   --                          AXIS packetizer (A.K.A. "chunker") supports interleaving of TDEST frames 
   -- 04/19/2016 (0x00000005): In AmcCarrierRegPkg, defaulting MPS Link node's XBAR configurations to XBAR_TIME_GEN_C 
   -- 04/21/2016 (0x00000006): Increased gtTxDiffCtrl from 0.95 Vppd to 1.08 Vppd
   -- 04/21/2016 (0x00000007): Added Ethernet Uptime counter in the BSI interface
   -- 07/08/2016 (0x00000008): Updated the I2C device configurations
   constant AMC_CARRIER_CORE_VERSION_C : slv(31 downto 0) := x"00000008";

   constant TIMING_MODE_186MHZ_C : boolean := true;  -- true = LCLS-II timing
   constant TIMING_MODE_119MHZ_C : boolean := ite(TIMING_MODE_186MHZ_C, false, true);

   constant AXI_CLK_FREQ_C   : real := 156.25E+6;                        -- In units of Hz
   constant AXI_CLK_PERIOD_C : real := getRealDiv(1.0, AXI_CLK_FREQ_C);  -- In units of seconds   

   -----------------------------------------------------------
   -- Application: Configurations, Constants and Records Types
   -----------------------------------------------------------
   subtype AppType is slv(6 downto 0);  -- Max. Size is 7-bits

   constant APP_NULL_TYPE_C           : AppType := toSlv(0, AppType'length);
   constant APP_TIME_GEN_TYPE_C       : AppType := toSlv(1, AppType'length);  --Timing Generator with local reference
   constant APP_BCM_TYPE_C            : AppType := toSlv(2, AppType'length);
   constant APP_BLEN_TYPE_C           : AppType := toSlv(3, AppType'length);
   constant APP_BPM_TYPE_C            : AppType := toSlv(4, AppType'length);
   constant APP_LLRF_TYPE_C           : AppType := toSlv(5, AppType'length);
   constant APP_EXTREF_GEN_TYPE_C     : AppType := toSlv(6, AppType'length);  --Timing Generator with external reference
   constant APP_MPS_APP_TYPE_C        : AppType := toSlv(123, AppType'length);  -- MPS Application Node
   constant APP_MPS_DIGITAL_TYPE_C    : AppType := toSlv(124, AppType'length);  -- MPS Link Node, RTM and AMC digital inputs
   constant APP_MPS_LINK_AIN_TYPE_C   : AppType := toSlv(125, AppType'length);  -- MPS Link Node, Dual Analog AMC cards
   constant APP_MPS_LINK_DIN_TYPE_C   : AppType := toSlv(126, AppType'length);  -- MPS Link Node, Dual Digital AMC cards
   constant APP_MPS_LINK_MIXED_TYPE_C : AppType := toSlv(127, AppType'length);  -- MPS Link Node, Mixed Signal (1x Analog and 1x Digital AMC cards)

   constant APP_REG_BASE_ADDR_C : slv(31 downto 0) := x"80000000";

   -------------------------------------------------------------------------------------------------
   -- Ethernet stream configurations
   -------------------------------------------------------------------------------------------------
   constant ETH_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8);  -- Use 8 tDest bits

   -- BSA stream indicies
   constant BSA_MEM_AXIS_INDEX_C             : integer := 0;
   constant BSA_BSA_STATUS_AXIS_INDEX_C      : integer := 1;
   constant BSA_WAVEFORM_STATUS_AXIS_INDEX_C : integer := 2;
   constant BSA_WAVEFORM_DATA_AXIS_INDEX_C   : integer := 3;

   -------------------------------------------------------------------------------------------------
   -- BSA configuration
   -------------------------------------------------------------------------------------------------
   constant BSA_BUFFERS_C            : integer := 64;
   constant BSA_DIAGNOSTIC_OUTPUTS_C : integer := 28;
   constant BSA_STREAM_BYTE_WIDTH_C  : integer := 8;
   constant BSA_BURST_BYTES_C        : integer := 2048;  -- Bytes in each burst of BSA data


   constant WAVEFORM_STREAMS_C     : integer             := 8;
   constant WAVEFORM_AXIS_CONFIG_C : AxiStreamConfigType :=
      ssiAxiStreamConfig(4, TKEEP_FIXED_C, TUSER_FIRST_LAST_C, 0, 3);  -- No tdest bits, 3 tUser bits

   constant WAVEFORM_TRIGGER_BIT_C : integer := 2;

   subtype WaveformMasterType is AxiStreamMasterArray(3 downto 0);
   type WaveformMasterArrayType is array (1 downto 0) of WaveformMasterType;

   constant WAVEFORM_MASTER_ARRAY_INIT_C : WaveformMasterArrayType := (others => (others => AXI_STREAM_MASTER_INIT_C));   
   
   type WaveformSlaveRecType is record
      slave : AxiStreamSlaveType;
      ctrl  : AxiStreamCtrlType;
   end record;
   type WaveformSlaveType is array (3 downto 0) of WaveformSlaveRecType;
   type WaveformSlaveArrayType is array (1 downto 0) of WaveformSlaveType;

   constant WAVEFORM_SLAVE_REC_INIT_C : WaveformSlaveRecType := (
      slave => AXI_STREAM_SLAVE_INIT_C,
      ctrl  => AXI_STREAM_CTRL_INIT_C);
   constant WAVEFORM_SLAVE_ARRAY_INIT_C : WaveformSlaveArrayType := (others => (others => WAVEFORM_SLAVE_REC_INIT_C));


   ---------------------------------------------------
   -- MPS: Configurations, Constants and Records Types
   ---------------------------------------------------   
   constant MPS_CONFIG_C          : AxiStreamConfigType := ssiAxiStreamConfig(2);
   constant MPS_MITIGATION_BITS_C : integer             := 114;
   constant MPS_MESSAGE_BITS_C    : integer             := 298;

   function getMpsChCnt(app        : AppType) return natural;
   function getMpsThresholdCnt(app : AppType) return natural;

   type MpsMitigationMsgType is record
      strobe    : sl;                      -- valid
      latchDiag : sl;                      -- latch the beam diagnostics with 'tag'
      tag       : slv(15 downto 0);
      class     : Slv4Array(15 downto 0);  -- power class limits for each of 16 destinations
      permit    : Slv2Array(15 downto 0);  -- Permit level for each of 16 destinations
   end record;

   constant MPS_MITIGATION_MSG_INIT_C : MpsMitigationMsgType := (
      strobe    => '0',
      latchDiag => '0',
      tag       => (others => '0'),
      class     => (others => (others => '0')),
      permit    => (others => (others => '0')));

   function toSlv (m                : MpsMitigationMsgType) return slv;
   function toMpsMitigationMsg (vec : slv) return MpsMitigationMsgType;

   type MpsMessageType is record
      valid     : sl;
      timeStamp : slv(15 downto 0);
      testMode  : sl;
      appId     : slv(15 downto 0);
      appType   : AppType;
      message   : Slv8Array(31 downto 0);
      msgSize   : slv(7 downto 0);      -- In units of Bytes
   end record;

   type MpsMessageArray is array (natural range <>) of MpsMessageType;

   constant MPS_MESSAGE_INIT_C : MpsMessageType := (
      valid     => '0',
      timeStamp => (others => '0'),
      testMode  => '0',
      appId     => (others => '0'),
      appType   => (others => '0'),
      message   => (others => (others => '0')),
      msgSize   => (others => '0'));

   function toSlv (m          : MpsMessageType) return slv;
   function toMpsMessage (vec : slv) return MpsMessageType;

   ---------------------------------------------------------------------------      
   -- Backplane Messaging Network: Configurations, Constants and Records Types
   ---------------------------------------------------------------------------    
   constant BP_MSG_SIZE_C     : natural := 2;
   function getBpMsgChCnt(app : AppType) return natural;

   type BpMsgBusType is record
      valid     : sl;
      testMode  : sl;
      app       : AppType;
      appId     : slv(15 downto 0);
      timeStamp : slv(63 downto 0);
      message   : Slv32Array(31 downto 0);
   end record;
   type BpMsgBusArray is array (natural range <>) of BpMsgBusType;
   constant BP_MSG_BUS_INIT_C : BpMsgBusType := (
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

   type BsiBusType is record
      slotNumber : slv(7 downto 0);
      crateId    : slv(15 downto 0);
      macAddress : Slv48Array(BSI_MAC_SIZE_C-1 downto 1);  --  big-Endian format 
   end record;
   constant BSI_BUS_INIT_C : BsiBusType := (
      slotNumber => x"00",
      crateId    => x"0000",
      macAddress => (others => (others => '0')));

   type DiagnosticBusType is record
      strobe        : sl;
      data          : Slv32Array(31 downto 0);
      timingMessage : TimingMessageType;
   end record;
   type DiagnosticBusArray is array (natural range <>) of DiagnosticBusType;
   constant DIAGNOSTIC_BUS_INIT_C : DiagnosticBusType := (
      strobe        => '0',
      data          => (others => (others => '0')),
      timingMessage => TIMING_MESSAGE_INIT_C);

   constant DIAGNOSTIC_BUS_BITS_C : integer := 1 + 32*32 + TIMING_MESSAGE_BITS_C;

   function toSlv (b             : DiagnosticBusType) return slv;
   function toDiagnosticBus (vec : slv) return DiagnosticBusType;

end package AmcCarrierPkg;

package body AmcCarrierPkg is

   function getMpsChCnt (app : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      if (app = APP_BCM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BLEN_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BPM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_LLRF_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_MPS_APP_TYPE_C) then
         retVar := 24;                  -- 6 channels * 4 integrations, RTH 01/27/2016
      elsif (app = APP_MPS_DIGITAL_TYPE_C) then
         retVar := 12;                  -- 96 bits., RTH 01/27/2016
      elsif (app = APP_MPS_LINK_AIN_TYPE_C) then
         retVar := 24;                  -- 6 channels * 4 integrations, RTH 01/27/2016
      elsif (app = APP_MPS_LINK_DIN_TYPE_C) then
         retVar := 0;                   -- 0 channels, RTH 01/27/2016
      elsif (app = APP_MPS_LINK_MIXED_TYPE_C) then
         retVar := 12;                  -- 3 channels * 4 integrations, RTH 01/27/2016
      else
         retVar := 0;
      end if;
      return retVar;
   end function;

   function getMpsThresholdCnt (app : AppType) return natural is
      variable retVar : natural range 0 to 256;
   begin
      if (app = APP_BCM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BLEN_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BPM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_LLRF_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_MPS_APP_TYPE_C) then
         retVar := 16;                  -- 16, RTH 01/27/2016
      elsif (app = APP_MPS_DIGITAL_TYPE_C) then
         retVar := 0;                   -- None, RTH 01/27/2016
      elsif (app = APP_MPS_LINK_AIN_TYPE_C) then
         retVar := 16;                  -- 16, RTH 01/27/2016
      elsif (app = APP_MPS_LINK_DIN_TYPE_C) then
         retVar := 0;                   -- None, RTH 01/27/2016
      elsif (app = APP_MPS_LINK_MIXED_TYPE_C) then
         retVar := 16;                  -- 16, RTH 01/27/2016
      else
         retVar := 0;
      end if;
      return retVar;
   end function;

   function getBpMsgChCnt (app : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      if (app = APP_BCM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BLEN_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BPM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_LLRF_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_MPS_DIGITAL_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_MPS_LINK_AIN_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_MPS_LINK_DIN_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_MPS_LINK_MIXED_TYPE_C) then
         retVar := 0;                   -- TBD value
      else
         retVar := 0;
      end if;
      return retVar;
   end function;

   function toSlv (b : DiagnosticBusType) return slv is
      variable vector : slv(DIAGNOSTIC_BUS_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
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
      variable i : integer := 0;
   begin
      b.timingMessage := toTimingMessageType(vec(TIMING_MESSAGE_BITS_C-1 downto 0));
      i               := TIMING_MESSAGE_BITS_C;
      for j in 0 to 31 loop
         assignRecord(i, vec, b.data(j));
      end loop;
      assignRecord(i, vec, b.strobe);
      return b;
   end function;

   function toSlv (m : MpsMitigationMsgType) return slv is
      variable vector : slv(MPS_MITIGATION_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
   begin
      assignSlv(i, vector, m.strobe);
      assignSlv(i, vector, m.latchDiag);
      assignSlv(i, vector, m.tag);

      for j in 0 to 15 loop
         assignslv(i, vector, m.class(j));
      end loop;

      for j in 0 to 15 loop
         assignslv(i, vector, m.permit(j));
      end loop;

      return vector;
   end function;

   function toMpsMitigationMsg (vec : slv) return MpsMitigationMsgType is
      variable m : MpsMitigationMsgType;
      variable i : integer := 0;
   begin
      assignrecord(i, vec, m.strobe);
      assignrecord(i, vec, m.latchDiag);
      assignrecord(i, vec, m.tag);

      for j in 0 to 15 loop
         assignrecord(i, vec, m.class(j));
      end loop;

      for j in 0 to 15 loop
         assignrecord(i, vec, m.permit(j));
      end loop;

      return m;
   end function;

   function toSlv (m : MpsMessageType) return slv is
      variable vector : slv(MPS_MESSAGE_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                            := 0;
   begin
      assignSlv(i, vector, m.valid);
      assignSlv(i, vector, m.timeStamp);
      assignSlv(i, vector, m.testMode);
      assignSlv(i, vector, m.appId);

      for j in 0 to 31 loop
         assignSlv(i, vector, m.message(j));
      end loop;

      assignSlv(i, vector, m.msgSize);
      return vector;
   end function;

   function toMpsMessage (vec : slv) return MpsMessageType is
      variable m : MpsMessageType;
      variable i : integer := 0;
   begin
      assignRecord(i, vec, m.valid);
      assignRecord(i, vec, m.timeStamp);
      assignRecord(i, vec, m.testMode);
      assignRecord(i, vec, m.appId);

      for j in 0 to 31 loop
         assignRecord(i, vec, m.message(j));
      end loop;

      assignRecord(i, vec, m.msgSize);
      return m;
   end function;

end package body AmcCarrierPkg;
