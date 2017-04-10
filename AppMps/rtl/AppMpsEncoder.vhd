-------------------------------------------------------------------------------
-- File       : AppMpsEncoder.vhd
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

entity AppMpsEncoder is
   generic (
      TPD_G           : time             := 1 ns;
      APP_TYPE_G      : AppType          := APP_NULL_TYPE_C);
   port (
      -- Clock & Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      mpsMaster       : out AxiStreamMasterType;
      mpsSlave        : in  AxiStreamSlaveType;
      -- Inputs
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType);

end AppMpsEncoder;

architecture mapping of AppMpsEncoder is

   constant APP_CONFIG_C : MpsAppConfigType := getMpsAppConfig(APP_TYPE_G);

   type RegType is record
      mpsMessage : MpsMessageType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsMessage => MPS_MESSAGE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal timeStrb   : sl;
   signal timeStamp  : slv(15 downto 0);
   signal message    : Slv32Array(MPS_CHAN_COUNT_C-1 downto 0) := (others=>(others=>'0'));
   signal syncIdle   : sl;
   signal syncAlt    : sl;
   signal digitalBus : slv(APP_CONFIG_C.BYTE_COUNT_C*8-1 downto 0);
   signal digSync    : slv(APP_CONFIG_C.BYTE_COUNT_C*8-1 downto 0);
   signal mpsReg     : MpsAppRegType;
   signal intDiagBus : DiagnosticBusType;   
   signal selectIdle : sl;
   signal selectAlt  : sl;

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

   --------------------------------- 
   -- Registers
   --------------------------------- 
   U_AppMpsReg: entity work.AppMpsReg 
      generic map (
         TPD_G            => TPD_G,
         APP_TYPE_G       => APP_TYPE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         APP_CONFIG_C     => APP_CONFIG_C )
      port map (
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(ENCODER_INDEX_C),
         axilReadSlave   => axilReadSlaves(ENCODER_INDEX_C),
         axilWriteMaster => axilWriteMasters(ENCODER_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(ENCODER_INDEX_C),
         mpsAppRegisters => mpsReg);

   --------------------------------- 
   -- Pattern decode and threshold select
   --------------------------------- 
   U_AppMpsSelect: entity work.AppMpsSelect 
      generic map (
         TPD_G           => TPD_G,
         APP_TYPE_G      => APP_TYPE_G,
         APP_CONFIG_G    => APP_CONFIG_C)
      port map (
         diagnosticClk     => diagnosticClk,
         diagnosticRst     => diagnosticRst,
         diagnosticBusIn   => diagnosticBus,
         diagnosticBusOut  => diagnosticBusInt,
         selectIdle        => selectIdle,
         selectAlt         => selectAlt,
         digitalBus        => digitalBus,
         mpsReg            => mpsReg);

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
         wr_en  => diagnosticBusInt.strobe,
         din(15 downto 0) => diagnosticBusInt.timingMessage.timeStamp(15 downto 0),
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
   GEN_ANA_EN : if APP_CONFIG_C.DIGITAL_EN_C = false generate
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
               wr_en  => diagnosticBusInt.strobe,
               din    => diagnosticBusInt.data(i),
               -- Read Ports (rd_clk domain)
               rd_clk => axilClk,
               dout   => message(i));
      end generate GEN_VEC;
      digSync <= (others=>'0'); 
   end generate GEN_ANA_EN;

   GEN_DIG_EN : if APP_CONFIG_C.DIGITAL_EN_C = true generate
      U_SyncFifo : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => APP_CONFIG_C.BYTE_COUNT_C*8)
         )
         port map (
            -- Asynchronous Reset
            rst    => diagnosticRst,
            -- Write Ports (wr_clk domain)
            wr_clk => diagnosticClk,
            wr_en  => diagnosticBusInt.strobe,
            din    => digitalBus,
            -- Read Ports (rd_clk domain)
            rd_clk => axilClk,
            dout   => digSync);

      message <= (others=>(others=>'0'));

   end generate GEN_DIG_EN;

   --------------------------------- 
   -- Thresholds
   --------------------------------- 
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
      v.mpsMessage.msgSize           := toSlv(APP_CONFIG_C.BYTE_COUNT_C,8);

      -- Digtal Application
      if APP_CONFIG_C.DIGITAL_EN_C = true then
         v.mpsMessage.inputType  := '0';

         for i in 0 to APP_CONFIG_C.BYTE_COUNT_C-1 loop
            v.mpsMessage.message(i) := digSync(i*8+7  downto  i*8);
         end loop;

      -- Analog Process each enabled channel
      else
         v.mpsMessage.inputType := '1';

         for chan in 0 to (MPS_CHAN_COUNT_C-1) loop
            if APP_CONFIG_C.CHAN_CONFIG_C(chan).THOLD_COUNT_C > 0 then
      
               -- LCLS1 Mode
               if APP_CONFIG_C.CHAN_CONFIG_C(chan).LCLS1_EN_C and mpsAppRegisters.lcls1Mode = '1' then
                  compareTholds (mpsAppRegister.lcls1Thold, 
                                 APP_CONFIG_C.CHAN_CONFIG_C(chan), 
                                 message(chan), 0, v.mpsMessage);
                  
               -- LCLS2 idle table
               elsif APP_CONFIG_C.CHAN_CONFIG_C(chan).IDLE_EN_C and syncIdle = '1' then
                  compareTholds (mpsAppRegister.idleThold, 
                                 APP_CONFIG_C.CHAN_CONFIG_C(chan), 
                                 message(chan), 7, v.mpsMessage);

               -- Multiple thresholds
               else
                  for thold in 0 to (APP_CONFIG_C.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop

                     -- Alternate table
                     if APP_CONFIG_C.CHAN_CONFIG_C(chan).ALT_EN_C and syncAlt = '1' then
                        compareTholds (mpsAppRegister.altThold, 
                                       APP_CONFIG_C.CHAN_CONFIG_C(chan), 
                                       message(chan), thold, v.mpsMessage);

                     -- Standard table
                     else
                        compareTholds (mpsAppRegister.stdThold, 
                                       APP_CONFIG_C.CHAN_CONFIG_C(chan), 
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

   --------------------------------- 
   -- MPS Message Generator
   --------------------------------- 
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

