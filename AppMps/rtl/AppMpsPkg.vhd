-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;

package AppMpsPkg is

   ---------------------------------------------------
   -- MPS: Configurations and Constants
   ---------------------------------------------------
   constant MPS_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(2);
   constant MPS_CHAN_COUNT_C  : integer             := 24;
   --type SlvMaxChanArray is array (natural range <>) of slv(MPS_CHAN_COUNT_C/4 -1 downto 0);  --one extra

   ---------------------------------------------------
   -- Mitigation message record
   ---------------------------------------------------
   constant MPS_MITIGATION_BITS_C : integer := 98;

   type MpsMitigationMsgType is record
      strobe    : sl;                   -- valid
      latchDiag : sl;  -- latch the beam diagnostics with 'tag'
      tag       : slv(15 downto 0);
      timeStamp : slv(15 downto 0);
      class     : Slv4Array(15 downto 0);  -- power class limits for each of 16 destinations
   end record;

   type MpsMitigationMsgArray is array (natural range <>) of MpsMitigationMsgType;

   constant MPS_MITIGATION_MSG_INIT_C : MpsMitigationMsgType := (
      strobe    => '0',
      latchDiag => '0',
      tag       => (others => '0'),
      timeStamp => (others => '0'),
      class     => (others => (others => '0')));

   function toSlv (m                : MpsMitigationMsgType) return slv;
   function toMpsMitigationMsg (vec : slv) return MpsMitigationMsgType;

   ---------------------------------------------------
   -- Update message
   ---------------------------------------------------
   constant MPS_MESSAGE_BITS_C : integer := 303;

   type MpsMessageType is record
      valid     : sl;
      version   : slv(4 downto 0);  -- Message version (wrong version is detected by MpsAppTimeout)
      lcls      : sl;                   -- '0' LCLS-II, '1' LCLS-I
      inputType : sl;                   -- '0' Digital, '1' Analog
      timeStamp : slv(15 downto 0);
      appId     : slv(15 downto 0);
      message   : Slv8Array(MPS_CHAN_COUNT_C-1 downto 0);
      msgSize   : slv(7 downto 0);      -- In units of Bytes
   end record;

   type MpsMessageArray is array (natural range <>) of MpsMessageType;

   constant MPS_MESSAGE_INIT_C : MpsMessageType := (
      valid     => '0',
      version   => (others => '0'),
      lcls      => '0',
      inputType => '0',
      timeStamp => (others => '0'),
      appId     => (others => '0'),
      message   => (others => (others => '0')),
      msgSize   => (others => '0'));

   function toSlv (m          : MpsMessageType) return slv;
   function toMpsMessage (vec : slv) return MpsMessageType;

   function mpsMessageInit (msgSize : integer) return MpsMessageType;

   ---------------------------------------------------
   -- MPS Channel Configuration Constants
   ---------------------------------------------------
   type MpsChanConfigType is record
      THOLD_COUNT_C : integer range 0 to 8;
      LCLS1_EN_C    : boolean;
      IDLE_EN_C     : boolean;
      ALT_EN_C      : boolean;
      BYTE_MAP_C    : integer range 0 to MPS_CHAN_COUNT_C-1;
   end record;

   type MpsChanConfigArray is array (natural range <>) of MpsChanConfigType;

   constant MPS_CHAN_CONFIG_INIT_C : MpsChanConfigType := (
      THOLD_COUNT_C => 0,
      LCLS1_EN_C    => false,
      IDLE_EN_C     => false,
      ALT_EN_C      => false,
      BYTE_MAP_C    => 0);

   ---------------------------------------------------
   -- MPS App Configuration Constants
   ---------------------------------------------------
   type MpsAppConfigType is record
      DIGITAL_EN_C  : boolean;          -- APP is digital
      BYTE_COUNT_C  : integer range 0 to MPS_CHAN_COUNT_C;  -- MPS message bytes max
      LCLS1_COUNT_C : integer range 0 to MPS_CHAN_COUNT_C;  -- MPS message bytes for LCLS1
      LCLS2_COUNT_C : integer range 0 to MPS_CHAN_COUNT_C;  -- MPS message bytes for LCLS1
      CHAN_CONFIG_C : MpsChanConfigArray(MPS_CHAN_COUNT_C-1 downto 0);
   end record;

   constant MPS_APP_CONFIG_INIT_C : MpsAppConfigType := (
      DIGITAL_EN_C  => false,
      BYTE_COUNT_C  => 0,
      LCLS1_COUNT_C => 0,
      LCLS2_COUNT_C => 0,
      CHAN_CONFIG_C => (others => MPS_CHAN_CONFIG_INIT_C));

   ---------------------------------------------------
   -- MPS Channel Thold Registers
   ---------------------------------------------------
   type MpsChanTholdType is record
      minTholdEn : sl;
      maxTholdEn : sl;
      minThold   : slv(31 downto 0);
      maxThold   : slv(31 downto 0);
   end record;

   type MpsChanTholdArray is array (natural range <>) of MpsChanTholdType;

   constant MPS_CHAN_THOLD_INIT_C : MpsChanTholdType := (
      minTholdEn => '0',
      maxTholdEn => '0',
      minThold   => (others => '0'),
      maxThold   => (others => '0'));

   ---------------------------------------------------
   -- MPS Channel Registers
   ---------------------------------------------------
   type MpsChanRegType is record
      stdTholds  : MpsChanTholdArray(7 downto 0);
      lcls1Thold : MpsChanTholdType;
      idleThold  : MpsChanTholdType;
      idleEn     : sl;
      altTholds  : MpsChanTholdArray(7 downto 0);
   end record;

   type MpsChanRegArray is array (natural range <>) of MpsChanRegType;

   constant MPS_CHAN_REG_INIT_C : MpsChanRegType := (
      stdTholds  => (others => MPS_CHAN_THOLD_INIT_C),
      lcls1Thold => MPS_CHAN_THOLD_INIT_C,
      idleThold  => MPS_CHAN_THOLD_INIT_C,
      idleEn     => '0',
      altTholds  => (others => MPS_CHAN_THOLD_INIT_C));

   ---------------------------------------------------
   -- MPS Core Registers
   ---------------------------------------------------
   constant MPS_CORE_REG_BITS_C : integer := 17;

   type MpsCoreRegType is record
      mpsEnable  : sl;
      mpsAppId   : slv(9 downto 0);
      mpsVersion : slv(4 downto 0);
      lcls1Mode  : sl;
   end record;

   type MpsCoreRegArray is array (natural range <>) of MpsCoreRegType;

   constant MPS_CORE_REG_INIT_C : MpsCoreRegType := (
      mpsEnable  => '0',
      mpsAppId   => (others => '0'),
      mpsVersion => (others => '0'),
      lcls1Mode  => '0');

   function toSlv (m          : MpsCoreRegType) return slv;
   function toMpsCoreReg (vec : slv) return MpsCoreRegType;

   ---------------------------------------------------
   -- MPS Application Registers
   ---------------------------------------------------
   type MpsAppRegType is record
      mpsCore      : MpsCoreRegType;
      beamDestMask : slv(15 downto 0);
      altDestMask  : slv(15 downto 0);
      mpsChanReg   : MpsChanRegArray(MPS_CHAN_COUNT_C-1 downto 0);
   end record;

   type MpsAppRegArray is array (natural range <>) of MpsAppRegType;

   constant MPS_APP_REG_INIT_C : MpsAppRegType := (
      mpsCore      => MPS_CORE_REG_INIT_C,
      beamDestMask => (others => '0'),
      altDestMask  => (others => '0'),
      mpsChanReg   => (others => MPS_CHAN_REG_INIT_C));

   ---------------------------------------------------
   -- MPS Select Data
   ---------------------------------------------------
   type MpsSelectType is record
      valid      : sl;
      timeStamp  : slv(15 downto 0);
      selectIdle : sl;
      selectAlt  : sl;
      digitalBus : slv(63 downto 0);
      mpsError   : slv(MPS_CHAN_COUNT_C-1 downto 0);
      mpsIgnore  : slv(MPS_CHAN_COUNT_C-1 downto 0);
      chanData   : Slv32Array(MPS_CHAN_COUNT_C-1 downto 0);
   end record;

   constant MPS_SELECT_INIT_C : MpsSelectType := (
      valid      => '0',
      timeStamp  => (others => '0'),
      selectIdle => '0',
      selectAlt  => '0',
      digitalBus => (others => '0'),
      mpsError   => (others => '0'),
      mpsIgnore  => (others => '0'),
      chanData   => (others => (others => '0')));

   ---------------------------------------------------
   -- MPS Configuration Function
   ---------------------------------------------------
   function getMpsAppConfig (app : AppType) return MpsAppConfigType;

end package AppMpsPkg;

package body AppMpsPkg is

   ---------------------------------------------------
   -- Mitigation message record
   ---------------------------------------------------
   function toSlv (m : MpsMitigationMsgType) return slv is
      variable vector : slv(MPS_MITIGATION_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
   begin
      assignSlv(i, vector, m.strobe);
      assignSlv(i, vector, m.latchDiag);
      assignSlv(i, vector, m.tag);
      assignSlv(i, vector, m.timeStamp);

      for j in 0 to 15 loop
         assignslv(i, vector, m.class(j));
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
      assignRecord(i, vec, m.timeStamp);

      for j in 0 to 15 loop
         assignrecord(i, vec, m.class(j));
      end loop;

      return m;
   end function;

   ---------------------------------------------------
   -- Update message
   ---------------------------------------------------
   function toSlv (m : MpsMessageType) return slv is
      variable vector : slv(MPS_MESSAGE_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                            := 0;
   begin
      assignSlv(i, vector, m.valid);
      assignSlv(i, vector, m.version);
      assignSlv(i, vector, m.lcls);
      assignSlv(i, vector, m.inputType);
      assignSlv(i, vector, m.msgSize);
      assignSlv(i, vector, m.appId);
      assignSlv(i, vector, m.timeStamp);

      for j in 0 to 31 loop
         assignSlv(i, vector, m.message(j));
      end loop;

      return vector;
   end function;

   function toMpsMessage (vec : slv) return MpsMessageType is
      variable m : MpsMessageType;
      variable i : integer := 0;
   begin
      assignRecord(i, vec, m.valid);
      assignRecord(i, vec, m.version);
      assignRecord(i, vec, m.lcls);
      assignRecord(i, vec, m.inputType);
      assignRecord(i, vec, m.msgSize);
      assignRecord(i, vec, m.appId);
      assignRecord(i, vec, m.timeStamp);

      for j in 0 to 31 loop
         assignRecord(i, vec, m.message(j));
      end loop;

      return m;
   end function;

   function mpsMessageInit (msgSize : integer) return MpsMessageType is
      variable ret : MpsMessageType;
   begin
      ret         := MPS_MESSAGE_INIT_C;
      ret.msgSize := toSlv(msgSize, 8);

      return ret;
   end function;

   ---------------------------------------------------
   -- MPS Core Registers
   ---------------------------------------------------
   function toSlv (m : MpsCoreRegType) return slv is
      variable vector : slv(MPS_CORE_REG_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                             := 0;
   begin

      assignSlv(i, vector, m.mpsEnable);
      assignSlv(i, vector, m.mpsAppId);
      assignSlv(i, vector, m.mpsVersion);
      assignSlv(i, vector, m.lcls1Mode);

      return vector;
   end function;

   function toMpsCoreReg (vec : slv) return MpsCoreRegType is
      variable m : MpsCoreRegType;
      variable i : integer := 0;
   begin

      assignRecord(i, vec, m.mpsEnable);
      assignRecord(i, vec, m.mpsAppId);
      assignRecord(i, vec, m.mpsVersion);
      assignRecord(i, vec, m.lcls1Mode);

      return m;
   end function;

   ---------------------------------------------------
   -- MPS Configuration Function
   ---------------------------------------------------
   -- See https://docs.google.com/spreadsheets/d/1BwDq9yZhAhpwpiJvPs6E53W_D4USY0Zc7HhFdv3SpEA/edit?usp=sharing
   -- for associated spreadsheet
   function getMpsAppConfig (app : AppType) return MpsAppConfigType is
      variable ret : MpsAppConfigType;
   begin
      ret := MPS_APP_CONFIG_INIT_C;

      case app is
         when APP_BPM_STRIPLINE_TYPE_C | APP_BPM_CAVITY_TYPE_C =>
            ret.BYTE_COUNT_C  := 6;
            ret.LCLS1_COUNT_C := 6;
            ret.LCLS2_COUNT_C := 6;

            for i in 0 to 1 loop

               -- Inputs 14 & 15 TMIT DIFFERENCE INSTEAD OF TMIT
               ret.CHAN_CONFIG_C(14+i).THOLD_COUNT_C := 8;
               ret.CHAN_CONFIG_C(14+i).LCLS1_EN_C    := true;
               ret.CHAN_CONFIG_C(14+i).IDLE_EN_C     := true;
               ret.CHAN_CONFIG_C(14+i).ALT_EN_C      := true;
               ret.CHAN_CONFIG_C(14+i).BYTE_MAP_C    := i;  -- amc0 = 0 & amc1 = 1

               -- Inputs 4 & 5 X
               ret.CHAN_CONFIG_C(4+i).THOLD_COUNT_C := 2;
               ret.CHAN_CONFIG_C(4+i).LCLS1_EN_C    := true;
               ret.CHAN_CONFIG_C(4+i).IDLE_EN_C     := true;
               ret.CHAN_CONFIG_C(4+i).ALT_EN_C      := true;
               ret.CHAN_CONFIG_C(4+i).BYTE_MAP_C    := i+2;  -- amc0 = 2 & amc1 = 3

               -- Inputs 6 & 7 Y
               ret.CHAN_CONFIG_C(6+i).THOLD_COUNT_C := 2;
               ret.CHAN_CONFIG_C(6+i).LCLS1_EN_C    := true;
               ret.CHAN_CONFIG_C(6+i).IDLE_EN_C     := true;
               ret.CHAN_CONFIG_C(6+i).ALT_EN_C      := true;
               ret.CHAN_CONFIG_C(6+i).BYTE_MAP_C    := i+4;  -- amc0 = 4 & amc1 = 5

            end loop;

         when APP_BLEN_TYPE_C =>
            -- ret.BYTE_COUNT_C  := 2;
            -- ret.LCLS2_COUNT_C := 2;
            -------------------------------------------------------
            -- https://jira.slac.stanford.edu/browse/ESLMPS-144
            -- Setting to 6byte for mps network latency work around
            -------------------------------------------------------
            ret.BYTE_COUNT_C  := 6;
            ret.LCLS2_COUNT_C := 6;

            -- Input 0
            ret.CHAN_CONFIG_C(0).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(0).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(0).BYTE_MAP_C    := 0;

            -- Input 16
            ret.CHAN_CONFIG_C(16).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(16).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(16).BYTE_MAP_C    := 1;

            -- Input 5
            ret.CHAN_CONFIG_C(5).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(5).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(5).BYTE_MAP_C    := 2;

            -- Input 21
            ret.CHAN_CONFIG_C(21).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(21).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(21).BYTE_MAP_C    := 3;

            -- Input 1
            ret.CHAN_CONFIG_C(1).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(1).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(1).BYTE_MAP_C    := 4;

            -- Input 17
            ret.CHAN_CONFIG_C(17).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(17).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(17).BYTE_MAP_C    := 5;

         when APP_BCM_TYPE_C =>
            -- ret.BYTE_COUNT_C  := 4;
            -- ret.LCLS2_COUNT_C := 4;
            -------------------------------------------------------
            -- https://jira.slac.stanford.edu/browse/ESLMPS-144
            -- Setting to 6byte for mps network latency work around
            -------------------------------------------------------
            ret.BYTE_COUNT_C  := 6;
            ret.LCLS2_COUNT_C := 6;

            -- Input 0
            ret.CHAN_CONFIG_C(0).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(0).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(0).BYTE_MAP_C    := 0;

            -- Input 16
            ret.CHAN_CONFIG_C(16).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(16).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(16).BYTE_MAP_C    := 1;

            -- Input 5
            ret.CHAN_CONFIG_C(5).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(5).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(5).BYTE_MAP_C    := 2;

            -- Input 21
            ret.CHAN_CONFIG_C(21).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(21).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(21).BYTE_MAP_C    := 3;

            -- Input 1
            ret.CHAN_CONFIG_C(1).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(1).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(1).BYTE_MAP_C    := 4;

            -- Input 17
            ret.CHAN_CONFIG_C(17).THOLD_COUNT_C := 8;
            ret.CHAN_CONFIG_C(17).IDLE_EN_C     := true;
            ret.CHAN_CONFIG_C(17).BYTE_MAP_C    := 5;

         when APP_LLRF_TYPE_C =>
            ret.DIGITAL_EN_C  := true;
            -- ret.BYTE_COUNT_C  := 2;
            -- ret.LCLS2_COUNT_C := 2;     -- same as BYTE_COUNT_C
            -------------------------------------------------------
            -- https://jira.slac.stanford.edu/browse/ESLMPS-144
            -- Setting to 6byte for mps network latency work around
            -------------------------------------------------------
            ret.BYTE_COUNT_C  := 6;
            ret.LCLS2_COUNT_C := 6;     -- same as BYTE_COUNT_C

         when APP_MPS_AN_TYPE_C | APP_MPS_LN_TYPE_C =>
            ret.BYTE_COUNT_C  := 12;
            ret.LCLS1_COUNT_C := 12;
            ret.LCLS2_COUNT_C := 12/2;

            for i in 0 to 12 - 1 loop
               ret.CHAN_CONFIG_C(i).THOLD_COUNT_C := 8;
               ret.CHAN_CONFIG_C(i).LCLS1_EN_C    := true;
               ret.CHAN_CONFIG_C(i).BYTE_MAP_C    := i;
               ret.CHAN_CONFIG_C(i).IDLE_EN_C     := true;
            end loop;

         when APP_FWS_TYPE_C =>
            ret.DIGITAL_EN_C  := true;
            -- ret.BYTE_COUNT_C  := 1;
            -- ret.LCLS2_COUNT_C := 1;     -- same as BYTE_COUNT_C
            -------------------------------------------------------
            -- https://jira.slac.stanford.edu/browse/ESLMPS-144
            -- Setting to 6byte for mps network latency work around
            -------------------------------------------------------
            ret.BYTE_COUNT_C  := 6;
            ret.LCLS2_COUNT_C := 6;     -- same as BYTE_COUNT_C

         when others =>
            null;

      end case;

      return ret;
   end function;

end package body AppMpsPkg;
