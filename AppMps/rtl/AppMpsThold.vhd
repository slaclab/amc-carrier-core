-------------------------------------------------------------------------------
-- File       : AppMpsThold.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
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
use work.AxiLitePkg.all;
use work.AppMpsPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsThold is
   generic (
      TPD_G            : time             := 1 ns;
      APP_CONFIG_G     : MpsAppConfigType := MPS_APP_CONFIG_INIT);
   port (
      -- Clock & Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- MPS Configuration Registers
      mpsAppRegisters : in  MpsAppRegType;
      -- Inputs
      diagnosticBus   : in  DiagnosticBusType;   
      selectIdle      : in  sl;
      selectAlt       : in  sl;
      -- MPS Message
      mpsMessage      : out MpsMessageType);

end AppMpsThold;

architecture mapping of AppMpsThold is

   type RegType is record
      mpsMessage : MpsMessageType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsMessage => MPS_MESSAGE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   procedure compareTholds (thold   : in MpsChanTholdType, 
                            config  : in MpsChanConfigType,
                            bitPos  : in integer,
                            mpsMsg  : inout MpsMessageType ) is

      variable signedVal : signed(31 downto 0);
      variable signedMax : signed(31 downto 0);
      variable signedMin : signed(31 downto 0);
   begin
      signedVal = signed(value);
      signedMin = signed(thold.minThold);
      signedMax = signed(thold.maxThold);
      ret       = false;

      if (thold.maxTholdEn = '1' and signedVal > signedMax) or 
         (thold.minTholdEn = '1' and signedVal > signedMin) then

         mpsMsg.message(config.BYTE_MAP_C)(bitPos) := '1';

      end if;
   end compreTholds;

begin

   comb : process (diagnosticBus, r) is
      variable v      : RegType;
      variable chan   : integer;
      variable thold  : integer;
   begin
      -- Latch the current value
      v := r;

      -- Init and setup MPS message
      v.mpsMessage                   := MPS_MESSAGE_INIT_C;
      v.mpsMessage.lcls              := mpsAppRegisters.lcls1Mode;
      v.mpsMessage.inputType         := '1';
      v.mpsMessage.timeStamp         := diagnosticBus.timingMessage.timeStamp(15 downto 0);
      v.mpsMessage.appId(9 downto 0) := mpsAppRegisters.mpsAppId;
      v.mpsMessage.msgSize           := toSlv(APP_CONFIG_G.BYTE_COUNT_C,8);

      -- Process each enabled channel
      for chan in 0 to (MPS_CHAN_COUNT_C-1) loop
         if APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C > 0 then
   
            -- LCLS1 Mode
            if APP_CONFIG_G.CHAN_CONFIG_C(chan).LCLS1_EN_C and mpsAppRegisters.lcls1Mode = '1' then
               compareTholds (mpsAppRegister.lcls1Thold, APP_CONFIG_G.CHAN_CONFIG_C(chan), 0, v.mpsMessagee);
               
            -- LCLS2 with no beam
            elsif APP_CONFIG_G.CHAN_CONFIG_C(chan).IDLE_EN_C and selectIdle = '1' then
               compareTholds (mpsAppRegister.idleThold, APP_CONFIG_G.CHAN_CONFIG_C(chan), 7, v.mpsMessagee);

            -- Multiple thresholds
            else
               for thold in 0 to (APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop
                  if APP_CONFIG_G.CHAN_CONFIG_C(chan).ALT_EN_C and selectAlt = '1' then
                     compareTholds (mpsAppRegister.altThold, APP_CONFIG_G.CHAN_CONFIG_C(chan), thold, v.mpsMessagee);
                  else
                     compareTholds (mpsAppRegister.stdThold, APP_CONFIG_G.CHAN_CONFIG_C(chan), thold, v.mpsMessagee);
                  end if;
               end loop;
            end if;
         end if;
      end loop;

      -- Generate message
      v.mpsMessage.valid := diagnosticBus.strobe,
      
      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      mpsMessage <= r.mpsMessage;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
