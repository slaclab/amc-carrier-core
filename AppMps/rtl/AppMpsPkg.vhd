-------------------------------------------------------------------------------
-- File       : AppMpsPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-08
-- Last update: 2016-12-05
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
use work.AmcCarrierPkg.all;

package AppMpsPkg is

   ---------------------------------------------------
   -- MPS: Configurations, Constants and Records Types
   ---------------------------------------------------   
   constant MPS_CONFIG_C          : AxiStreamConfigType := ssiAxiStreamConfig(2);
   constant MPS_MITIGATION_BITS_C : integer             := 98;
   constant MPS_MESSAGE_BITS_C    : integer             := 298;

   function getMpsChCnt(app        : AppType) return natural;
   function getMpsThresholdCnt(app : AppType) return natural;

   type MpsMitigationMsgType is record
      strobe    : sl;                      -- valid
      latchDiag : sl;                      -- latch the beam diagnostics with 'tag' 
      tag       : slv(15 downto 0);      
      timeStamp : slv(15 downto 0);
      class     : Slv4Array(15 downto 0);  -- power class limits for each of 16 destinations
   end record;

   constant MPS_MITIGATION_MSG_INIT_C : MpsMitigationMsgType := (
      strobe    => '0',
      latchDiag => '0',
      tag       => (others => '0'),      
      timeStamp => (others => '0'),
      class     => (others => (others => '0')));

   function toSlv (m                : MpsMitigationMsgType) return slv;
   function toMpsMitigationMsg (vec : slv) return MpsMitigationMsgType;

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

end package AppMpsPkg;

package body AppMpsPkg is

   function getMpsChCnt (app : AppType) return natural is
      variable retVar : natural range 0 to 32;
   begin
      if (app = APP_BCM_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BLEN_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BPM_STRIPLINE_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BPM_CAVITY_TYPE_C) then
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
      elsif (app = APP_BPM_STRIPLINE_TYPE_C) then
         retVar := 0;                   -- TBD value
      elsif (app = APP_BPM_CAVITY_TYPE_C) then
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
