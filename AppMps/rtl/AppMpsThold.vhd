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
      mpsMessage      : MpsMessageType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsMessage      => MPS_MESSAGE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

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

      valid     : sl;
      message   : Slv8Array(31 downto 0);

      -- Process each enabled channel
      for chan in 0 to (MPS_CHAN_COUNT_C-1) loop
         if APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C > 0 then
   
            -- LCLS1 Mode
            if APP_CONFIG_G.CHAN_CONFIG_C(chan).LCLS1_EN_C and mpsAppRegisters.lcls1Mode = '1' then
               if ( mpsAppRegister.lcls1Thold.maxTholdEn = '1' and 
                    diagnosticBus.data(chan) > mpsAppRegister.lcls1Thold.maxThold ) or
                  ( mpsAppRegister.lcls1Thold.minTholdEn = '1' and 
                    diagnosticBus.data(chan) < mpsAppRegister.lcls1Thold.minThold ) then

                  v.mpsMessage.message(APP_CONFIG_G.CHAN_CONFIG_C(chan).BYTE_MAP_C)(0) := '1';
               end if;

            -- LCLS2 with no beam
            elsif APP_CONFIG_G.CHAN_CONFIG_C(chan).IDLE_EN_C and selectIdle = '1' then
               if ( mpsAppRegister.idleThold.maxTholdEn = '1' and 
                    diagnosticBus.data(chan) > mpsAppRegister.idleThold.maxThold ) or
                  ( mpsAppRegister.idleThold.minTholdEn = '1' and 
                    diagnosticBus.data(chan) < mpsAppRegister.idleThold.minThold ) then

                  v.mpsMessage.message(APP_CONFIG_G.CHAN_CONFIG_C(chan).BYTE_MAP_C)(7) := '1';
               end if;

            -- Multiple thresholds
            else
               for thold in 0 to (APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop



      -- Determine the transaction type
      axiSlaveWaitTxn(regEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);


            for thold in 0 to (APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop

               -- standard: thold 0 = base + 0x100, thold 1 = base + 0x110, thold 7 = base + 0x170
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 0,16), 0, v.mpsReg.mpsChanReg(chan).stdTholds(thold).minTholdEn);
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 0,16), 1, v.mpsReg.mpsChanReg(chan).stdTholds(thold).maxTholdEn);
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 4,16), 0, v.mpsReg.mpsChanReg(chan).stdTholds(thold).minThold);
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 8,16), 0, v.mpsReg.mpsChanReg(chan).stdTholds(thold).maxThold);

               -- alt: thold 0 = base + 0x180, thold 1 = base + 0x190, thold 7 = base + 0x1F0
               if APP_CONFIG_G.CHAN_CONFIG_C(chan).ALT_EN_C then
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 0,16), 0, v.mpsReg.mpsChanReg(chan).altTholds(thold).minTholdEn);
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 0,16), 1, v.mpsReg.mpsChanReg(chan).altTholds(thold).maxTholdEn);
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 4,16), 0, v.mpsReg.mpsChanReg(chan).altTholds(thold).minThold);
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 8,16), 0, v.mpsReg.mpsChanReg(chan).altTholds(thold).maxThold);
               end if;
            end loop;
         end if;
      end loop;
      
      -- Closeout the transaction
      axiSlaveDefault(regEp, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave  <= r.axilWriteSlave;
      axilReadSlave   <= r.axilReadSlave;
      mpsAppRegisters <= r.mpsReg;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
