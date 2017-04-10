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
      TPD_G           : time             := 1 ns;
      APP_CONFIG_G    : MpsAppConfigType := MPS_APP_CONFIG_INIT);
   port (
      -- Clock & Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      mpsAppRegisters : in  MpsAppRegType;
      mpsMaster       : out AxiStreamMasterType;
      mpsSlave        : in  AxiStreamSlaveType;
      -- Inputs
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;   
      digitalBus      : in  slv(63 downto 0);
      selectIdle      : in  sl;
      selectAlt       : in  sl);

end AppMpsThold;

architecture mapping of AppMpsThold is

   type RegType is record
      mpsMessage : MpsMessageType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsMessage => MPS_MESSAGE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal timeStrb  : sl;
   signal timeStamp : slv(15 downto 0);
   signal message   : Slv32Array(31 downto 0) := (others=>(others=>'0'));
   signal syncIdle  : sl;
   signal syncAlt   : sl;
   signal digSync   : slv(63 downto 0);

   procedure compareTholds (thold   : in MpsChanTholdType, 
                            config  : in MpsChanConfigType,
                            value   : in slv,
                            bitPos  : in integer,
                            mpsMsg  : inout MpsMessageType ) is

      variable signedVal : signed(31 downto 0);
      variable signedMax : signed(31 downto 0);
      variable signedMin : signed(31 downto 0);
   begin
      signedVal := signed(value);
      signedMin := signed(thold.minThold);
      signedMax := signed(thold.maxThold);
      ret       := false;

      if (thold.maxTholdEn = '1' and signedVal > signedMax) or 
         (thold.minTholdEn = '1' and signedVal > signedMin) then

         mpsMsg.message(config.BYTE_MAP_C)(bitPos) := '1';

      end if;
   end compreTholds;

begin

   ------------------------------------ 
   -- Time Stamp Synchronization Module
   ------------------------------------ 
   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 18)
      port map (
         -- Asynchronous Reset
         rst    => diagnosticRst,
         -- Write Ports (wr_clk domain)
         wr_clk => diagnosticClk,
         wr_en  => diagnosticBus.strobe,
         din(15 downto 0) => diagnosticBus.timingMessage.timeStamp(15 downto 0),
         din(16)          => selectIdle,
         din(17)          => selectAlt,
         -- Read Ports (rd_clk domain)
         rd_clk            => axilClk,
         valid             => timeStrb,
         dout(15 downto 0) => timeStamp,
         dout(16)          => syncIdle,
         dout(17)          => syncAlt);

   --------------------------------- 
   -- Message Synchronization Module
   --------------------------------- 
   GEN_ANA_EN : if APP_CONFIG_G.DIGITAL_EN_C = false generate
      GEN_VEC : for i in 0 to (MPS_CHAN_COUNT_C-1) generate
         U_SyncFifo : entity work.SynchronizerFifo
            generic map (
               TPD_G        => TPD_G,
               DATA_WIDTH_G => 32)
            port map (
               -- Asynchronous Reset
               rst    => diagnosticRst,
               -- Write Ports (wr_clk domain)
               wr_clk => diagnosticClk,
               wr_en  => diagnosticBus.strobe,
               din    => diagnosticBus.data(i),
               -- Read Ports (rd_clk domain)
               rd_clk => axilClk,
               dout   => message(i));
      end generate GEN_VEC;
      digSync <= (others=>'0'); 
   end generate GEN_ANA_EN;

   GEN_DIG_EN : if APP_CONFIG_G.DIGITAL_EN_C = true generate
      U_SyncFifo : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 63)
         port map (
            -- Asynchronous Reset
            rst    => diagnosticRst,
            -- Write Ports (wr_clk domain)
            wr_clk => diagnosticClk,
            wr_en  => diagnosticBus.strobe,
            din    => digitalBus,
            -- Read Ports (rd_clk domain)
            rd_clk => axilClk,
            dout   => digSync);

      message <= (others=>(others=>'0'));

   end generate GEN_DIG_EN;

   comb : process (timeStrb, timeStamp, message, syncIdle, syncAlt, digSync, r) is
      variable v      : RegType;
      variable chan   : integer;
      variable thold  : integer;
   begin
      -- Latch the current value
      v := r;

      -- Init and setup MPS message
      v.mpsMessage                   := MPS_MESSAGE_INIT_C;
      v.mpsMessage.lcls              := mpsAppRegisters.lcls1Mode;
      v.mpsMessage.timeStamp         := timeStamp;
      v.mpsMessage.appId(9 downto 0) := mpsAppRegisters.mpsAppId;
      v.mpsMessage.msgSize           := toSlv(APP_CONFIG_G.BYTE_COUNT_C,8);

      -- Digtal Application
      if APP_CONFIG_G.DIGITAL_EN_C = true then
         v.mpsMessage.inputType  := '0';
         v.mpsMessage.message(0) := digSync(7  downto  0);
         v.mpsMessage.message(1) := digSync(15 downto  8);
         v.mpsMessage.message(2) := digSync(23 downto 16);
         v.mpsMessage.message(3) := digSync(31 downto 24);

      -- Analog Process each enabled channel
      else
         v.mpsMessage.inputType := '1';

         for chan in 0 to (MPS_CHAN_COUNT_C-1) loop
            if APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C > 0 then
      
               -- LCLS1 Mode
               if APP_CONFIG_G.CHAN_CONFIG_C(chan).LCLS1_EN_C and mpsAppRegisters.lcls1Mode = '1' then
                  compareTholds (mpsAppRegister.lcls1Thold, 
                                 APP_CONFIG_G.CHAN_CONFIG_C(chan), 
                                 message(chan), 0, v.mpsMessage);
                  
               -- LCLS2 idle table
               elsif APP_CONFIG_G.CHAN_CONFIG_C(chan).IDLE_EN_C and syncIdle = '1' then
                  compareTholds (mpsAppRegister.idleThold, 
                                 APP_CONFIG_G.CHAN_CONFIG_C(chan), 
                                 message(chan), 7, v.mpsMessage);

               -- Multiple thresholds
               else
                  for thold in 0 to (APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop

                     -- Alternate table
                     if APP_CONFIG_G.CHAN_CONFIG_C(chan).ALT_EN_C and syncAlt = '1' then
                        compareTholds (mpsAppRegister.altThold, 
                                       APP_CONFIG_G.CHAN_CONFIG_C(chan), 
                                       message(chan), thold, v.mpsMessage);

                     -- Standard table
                     else
                        compareTholds (mpsAppRegister.stdThold, 
                                       APP_CONFIG_G.CHAN_CONFIG_C(chan), 
                                       message(chan), thold, v.mpsMessage);
                     end if;
                  end loop;
               end if;
            end if;
         end loop;
      end if;

      -- Generate message
      v.mpsMessage.valid := timeStrb;
      
      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- MPS Message Generator
   U_MsgGen: entity work.MpsMsgCore
      generic map (
         TPD_G            => TPD_G,
         SIM_ERROR_HALT_G => false)
      port map (
         clk        => axilClk,
         rst        => axilRst,
         mpsMessage => r.mpsMessage,
         mpsMaster  => mpsMaster,
         mpsSlave   => mpsSlave
      );

end mapping;

