-------------------------------------------------------------------------------
-- Title      : TimingPkg
-------------------------------------------------------------------------------
-- File       : TimingPkg.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-01
-- Last update: 2015-09-02
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

package TimingPkg is

   constant D_102_C : slv(7 downto 0) := "01001010";  -- D10.2, 0x4A
   constant D_215_C : slv(7 downto 0) := "10110101";  -- D21.5, 0xB5
   constant K_COM_C : slv(7 downto 0) := "10111100";  -- K28.5, 0xBC
   constant K_SOF_C : slv(7 downto 0) := "11110111";  -- K23.7, 0xF7
   constant K_EOF_C : slv(7 downto 0) := "11111101";  -- K29.7, 0xFD

   constant TIMING_MSG_BITS_C  : integer := 1136;
   constant TIMING_MSG_WORDS_C : integer := TIMING_MSG_BITS_C/16;


   type TimingMsgType is record
      version         : slv(63 downto 0);
      pulseId         : slv(63 downto 0);
      timeStamp       : slv(63 downto 0);
      fixedRates      : slv(9 downto 0);
      acRates         : slv(5 downto 0);
      acTimeSlot      : slv(2 downto 0);
      acTimeSlotPhase : slv(11 downto 0);
      resync          : sl;
      beamRequest     : slv(31 downto 0);
      syncStatus      : sl;
      bcsFault        : slv(5 downto 0);
      mpsValid        : sl;
      mpsLimits       : slv16Array(0 to 4);
      historyActive   : sl;
      calibrationGap  : sl;
      bsaInit         : slv(63 downto 0);
      bsaActive       : slv(63 downto 0);
      bsaAvgDone      : slv(63 downto 0);
      bsaDone         : slv(63 downto 0);
      experiment      : slv32Array(0 to 8);
      patternAddress  : slv(15 downto 0);
      pattern         : Slv16Array(0 to 7);
      crc        : slv(31 downto 0);
   end record;

   constant TIMING_MSG_INIT_C : TimingMsgType := (
      version         => (others => '0'),
      pulseId         => (others => '0'),
      timeStamp       => (others => '0'),
      fixedRates      => (others => '0'),
      acRates         => (others => '0'),
      acTimeSlot      => (others => '0'),
      acTimeSlotPhase => (others => '0'),
      resync          => '0',
      beamRequest     => (others => '0'),
      syncStatus      => '0',
      bcsFault        => (others => '0'),
      mpsValid        => '0',
      mpsLimits       => (others => (others => '0')),
      historyActive   => '0',
      calibrationGap  => '0',
      bsaInit         => (others => '0'),
      bsaActive       => (others => '0'),
      bsaAvgDone      => (others => '0'),
      bsaDone         => (others => '0'),
      experiment      => (others => (others => '0')),
      patternAddress  => (others => '0'),
      pattern         => (others => (others => '0')),
      crc        => (others => '0'));



   function toSlv(msg              : TimingMsgType) return slv;
   function toTimingMsgType(vector : slv) return TimingMsgType;


end package TimingPkg;

package body TimingPkg is


   -------------------------------------------------------------------------------------------------
   -- Convert a timing message record into a big long SLV
   -------------------------------------------------------------------------------------------------
   function toSlv (msg : TimingMsgType) return slv
   is
      variable vector : slv(TIMING_MSG_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                           := 0;
   begin
      assignSlv(i, vector, msg.version);
      assignSlv(i, vector, msg.pulseId);
      assignSlv(i, vector, msg.timeStamp);
      assignSlv(i, vector, msg.fixedRates);
      assignSlv(i, vector, msg.acRates);
      assignSlv(i, vector, msg.acTimeSlot);
      assignSlv(i, vector, msg.acTimeSlotPhase);
      assignSlv(i, vector, msg.resync);
      assignSlv(i, vector, msg.beamRequest);
      assignSlv(i, vector, msg.syncStatus);
      assignSlv(i, vector, msg.bcsFault);
      assignSlv(i, vector, msg.mpsValid);
      assignSlv(i, vector, "00000000");        -- 8 unused bits
      for j in msg.mpsLimits'range loop
         assignSlv(i, vector, msg.mpsLimits(j));
      end loop;
      assignSlv(i, vector, msg.historyActive);
      assignSlv(i, vector, msg.calibrationGap);
      assignSlv(i, vector, "00000000000000");  -- 14 unused bits
      assignSlv(i, vector, X"000000000000");   -- 3 unused words
      assignSlv(i, vector, msg.bsaInit);
      assignSlv(i, vector, msg.bsaActive);
      assignSlv(i, vector, msg.bsaAvgDone);
      assignSlv(i, vector, msg.bsaDone);
      for j in msg.experiment'range loop
         assignSlv(i, vector, msg.experiment(j));
      end loop;
      assignSlv(i, vector, msg.patternAddress);
      for j in msg.pattern'range loop
         assignSlv(i, vector, msg.pattern(j));
      end loop;
      assignSlv(i, vector, msg.crc);
      return vector;
   end function;

   -------------------------------------------------------------------------------------------------
   -- Convert an SLV into a timing record
   -------------------------------------------------------------------------------------------------
   function toTimingMsgType (vector : slv) return TimingMsgType
   is
      variable msg : TimingMsgType;
      variable i   : integer := 0;
   begin
      assignRecord(i, vector, msg.version);
      assignRecord(i, vector, msg.pulseId);
      assignRecord(i, vector, msg.timeStamp);
      assignRecord(i, vector, msg.fixedRates);
      assignRecord(i, vector, msg.acRates);
      assignRecord(i, vector, msg.acTimeSlot);
      assignRecord(i, vector, msg.acTimeSlotPhase);
      assignRecord(i, vector, msg.resync);
      assignRecord(i, vector, msg.beamRequest);
      assignRecord(i, vector, msg.syncStatus);
      assignRecord(i, vector, msg.bcsFault);
      assignRecord(i, vector, msg.mpsValid);
      i := i+ 8;                        -- 8 unused bits
      for j in msg.mpsLimits'range loop
         assignRecord(i, vector, msg.mpsLimits(j));
      end loop;
      assignRecord(i, vector, msg.historyActive);
      assignRecord(i, vector, msg.calibrationGap);
      i := i+ 14;                       -- 14 unused bits of word
      i := i+ (16*3);                   -- 3 unused words
      assignRecord(i, vector, msg.bsaInit);
      assignRecord(i, vector, msg.bsaActive);
      assignRecord(i, vector, msg.bsaAvgDone);
      assignRecord(i, vector, msg.bsaDone);
      for j in msg.experiment'range loop
         assignRecord(i, vector, msg.experiment(j));
      end loop;
      assignRecord(i, vector, msg.patternAddress);
      for j in msg.pattern'range loop
         assignRecord(i, vector, msg.pattern(j));
      end loop;
      assignRecord(i, vector, msg.crc);
      return msg;
   end function;


end package body TimingPkg;
