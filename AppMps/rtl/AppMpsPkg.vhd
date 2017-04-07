-------------------------------------------------------------------------------
-- File       : AppMpsPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
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

package AppMpsPkg is

   ---------------------------------------------------
   -- MPS: Configurations and Constants
   ---------------------------------------------------   
   constant MPS_AXIS_CONFIG_C     : AxiStreamConfigType := ssiAxiStreamConfig(2);
   constant MPS_MITIGATION_BITS_C : integer             := 98;
   constant MPS_MESSAGE_BITS_C    : integer             := 298;
   constant MPS_CHAN_COUNT_C      : integer             := 24;

   ---------------------------------------------------
   -- Mitigation message record
   ---------------------------------------------------   
   type MpsMitigationMsgType is record
      strobe    : sl;                      -- valid
      latchDiag : sl;                      -- latch the beam diagnostics with 'tag' 
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
   type MpsMessageType is record
      valid     : sl;
      lcls      : sl; -- '0' LCLS-II, '1' LCLS-I
      inputType : sl; -- '0' Digital, '1' Analog      
      timeStamp : slv(15 downto 0);
      appId     : slv(15 downto 0);
      message   : Slv8Array(31 downto 0);
      msgSize   : slv(7 downto 0);      -- In units of Bytes
   end record;

   type MpsMessageArray is array (natural range <>) of MpsMessageType;

   constant MPS_MESSAGE_INIT_C : MpsMessageType := (
      valid     => '0',
      lcls      => '0',    
      inputType => '0',      
      timeStamp => (others => '0'),
      appId     => (others => '0'),
      message   => (others => (others => '0')),
      msgSize   => (others => '0'));

   function toSlv (m          : MpsMessageType) return slv;
   function toMpsMessage (vec : slv) return MpsMessageType;

   ---------------------------------------------------
   -- MPS Channel Configuration
   ---------------------------------------------------   
   type MpsChanConfigType is record
      THOLD_COUNT_C  : integer range 0 to 8;
      LCLS1_EN_C     : boolean;
      IDLE_EN_C      : boolean;
      ALT_EN_C       : boolean;
      BYTE_MAP_C     : integer range 0 to MPS_CHAN_COUNT-1;
   end record;

   type MpsChanConfigArray is array (natural range <>) of MpsChanConfigType;

   constant MPS_CHAN_CONFIG_INIT_C : MpsChanConfigType := (
      THOLD_COUNT_C  => 0,
      LCLS1_EN_C     => false,
      IDLE_EN_C      => false,
      ALT_EN_C       => false,
      BYTE_MAP_C     => 0);

   ---------------------------------------------------
   -- MPS App Configuration
   ---------------------------------------------------   
   type MpsAppConfigType is record
      DIGITAL_EN_C   : boolean; -- APP is digital
      BYTE_COUNT_C   : integer range 0 to MPS_CHAN_COUNT-1; -- MPS message bytes
      CHAN_CONFIG_C  : MpsChanConfigArray(MPS_CHAN_COUNT-1 downto 0);
   end record;

   constant MPS_APP_CONFIG_INIT_C : MpsAppConfigType := (
      DIGITAL_EN_C   => false,
      BYTE_COUNT_C   => 0,
      CHAN_CONFIG_C  => (others=>MPS_CHAN_CONFIG_INIT_C));

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
      minTholdEn => 0,
      maxTholdEn => 0,
      minThold   => (others=>'0'),
      maxThold   => (others=>'0'));

   ---------------------------------------------------
   -- MPS Channel Registers
   ---------------------------------------------------   
   type MpsChanRegType is record
      stdTholds    : MpsChanTholdArray(7 downto 0);
      lcls1Thold   : MpsChanTholdType;
      idlehold     : MpsChanTholdType;
      altTholds    : MpsChanTholdArray(7 downto 0);
   end record;

   type MpsChanRegArray is array (natural range <>) of MpsChanRegType;

   constant MPS_CHAN_REG_INIT_C : MpsChanRegType := (
      stdTholds    => (others=>MPS_CHAN_THOLD_INIT_C),
      lcls1Thold   => MPS_CHAN_THOLD_INIT_C;
      idleThold    => MPS_CHAN_THOLD_INIT_C;
      altTholds    => (others=>MPS_CHAN_THOLD_INIT_C));

   ---------------------------------------------------
   -- MPS Application Registers
   ---------------------------------------------------   

   -- Kick detect modes
   constant MPS_KICK_DISABLE : slv(1 downto 0) := "00";
   constant MPS_KICK_SOFT    : slv(1 downto 0) := "01";
   constant MPS_KICK_HARD    : slv(1 downto 0) := "10";
   constant MPS_KICK_OTHER   : slv(1 downto 0) := "11";

   type MpsAppRegType is record
      mpsEnable   : sl;
      mpsAddId    : slv(9 downto 0);
      lcls1Mode   : sl;
      kickDetMode : slv(1 downto 0);
      mpsChanReg  : MpsChanRegArray(MPS_CHAN_COUNT_C downto 0);
   end record;

   type MpsAppRegArray is array (natural range <>) of MpsAppRegType;

   constant MPS_APP_REG_INIT_C : MpsAppRegType := (
      mpsEnable    => 0,
      mpsAddId     => (others=>'0'),
      lcls1Mode    => '0',
      kickDetMode  => (others=>'0'),
      mpsChanReg   => (others=>MPS_CHAN_REG_INIT_C));

end package AppMpsPkg;

package body AppMpsPkg is

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

   function toSlv (m : MpsMessageType) return slv is
      variable vector : slv(MPS_MESSAGE_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                            := 0;
   begin
      assignSlv(i, vector, m.valid);
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

end package body AppMpsPkg;
