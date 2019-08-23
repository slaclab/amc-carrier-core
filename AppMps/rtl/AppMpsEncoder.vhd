-------------------------------------------------------------------------------
-- File       : AppMpsEncoder.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
-- Last update: 2018-03-14
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.AppMpsPkg.all;
use work.AmcCarrierPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsEncoder is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0');
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
      mpsCoreReg      : out MpsCoreRegType;
      -- Inputs
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType);

end AppMpsEncoder;

architecture mapping of AppMpsEncoder is

   constant APP_CONFIG_C : MpsAppConfigType := getMpsAppConfig(APP_TYPE_G);

   type RegType is record
      tholdMem   : Slv4VectorArray(MPS_CHAN_COUNT_C-1 downto 0, 7 downto 0);
      mpsMessage : MpsMessageType;
   end record;

   constant REG_INIT_C : RegType := (
      tholdMem   => (others => (others => (others => '0'))),
      mpsMessage => mpsMessageInit(APP_CONFIG_C.BYTE_COUNT_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal mpsSelect : MpsSelectType;

   procedure compareTholds (thold       : in    MpsChanTholdType;
                            config      : in    MpsChanConfigType;
                            value       : in    slv;
                            ignore      : in    sl;
                            bitPos      : in    integer;
                            tholdMemIn  : in    slv;
                            tholdMemOut : inout slv;
                            message     : inout Slv8Array) is

      variable signedVal : signed(31 downto 0);
      variable signedMax : signed(31 downto 0);
      variable signedMin : signed(31 downto 0);
   begin
      signedVal := signed(value);
      signedMin := signed(thold.minThold);
      signedMax := signed(thold.maxThold);

      -- Threshold is exceeded. Set current bit and set 4 bit counter
      if ignore = '0' and ((thold.maxTholdEn = '1' and signedVal > signedMax) or
                           (thold.minTholdEn = '1' and signedVal < signedMin)) then

         tholdMemOut                        := (others => '1');
         message(config.BYTE_MAP_C)(bitPos) := '1';

      -- Threhold was exceeded within the last 15 clocks
      elsif tholdMemIn /= 0 then
         tholdMemOut                        := tholdMemIn - 1;
         message(config.BYTE_MAP_C)(bitPos) := '1';
      end if;
   end procedure;

   procedure digitalBit (value       : in    sl;
                         bitPos      : in    integer;
                         tholdMemIn  : in    slv;
                         tholdMemOut : inout slv;
                         message     : inout Slv8Array) is

   begin

      -- Bit is set
      if value = '1' then
         tholdMemOut        := (others => '1');
         message(0)(bitPos) := '1';

      -- Bit was set within the last 15 clocks
      elsif tholdMemIn /= 0 then
         tholdMemOut        := tholdMemIn - 1;
         message(0)(bitPos) := '1';
      end if;
   end procedure;

   signal mpsReg     : MpsAppRegType;
   signal mpsMsgDrop : sl;

--   attribute MARK_DEBUG : string;
--   attribute MARK_DEBUG of r         : signal is "TRUE";
--   attribute MARK_DEBUG of mpsMaster : signal is "TRUE";
--   attribute MARK_DEBUG of mpsSlave  : signal is "TRUE";

begin

   -- Output core reg
   mpsCoreReg <= mpsReg.mpsCore;

   --------------------------------- 
   -- Registers
   --------------------------------- 
   U_AppMpsReg : entity work.AppMpsReg
      generic map (
         TPD_G           => TPD_G,
         APP_TYPE_G      => APP_TYPE_G,
         AXI_BASE_ADDR_G => AXI_BASE_ADDR_G,
         APP_CONFIG_G    => APP_CONFIG_C)
      port map (
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         mpsMessage      => r.mpsMessage,
         mpsMsgDrop      => mpsMsgDrop,
         mpsAppRegisters => mpsReg);

   --------------------------------- 
   -- Pattern decode and threshold select
   --------------------------------- 
   U_AppMpsSelect : entity work.AppMpsSelect
      generic map (
         TPD_G        => TPD_G,
         APP_TYPE_G   => APP_TYPE_G,
         APP_CONFIG_G => APP_CONFIG_C)
      port map (
         diagnosticClk => diagnosticClk,
         diagnosticRst => diagnosticRst,
         diagnosticBus => diagnosticBus,
         axilClk       => axilClk,
         axilRst       => axilRst,
         mpsReg        => mpsReg,
         mpsSelect     => mpsSelect);

   --------------------------------- 
   -- Thresholds
   --------------------------------- 
   comb : process (axilRst, mpsReg, mpsSelect, r) is
      variable v       : RegType;
      variable chan    : integer;
      variable thold   : integer;
      variable msgData : Slv8Array(APP_CONFIG_C.BYTE_COUNT_C-1 downto 0);
   begin
      -- Latch the current value
      v := r;

      if mpsReg.mpsCore.lcls1Mode = '1' then
         v.mpsMessage := mpsMessageInit(APP_CONFIG_C.LCLS1_COUNT_C);
      else 
         v.mpsMessage := mpsMessageInit(APP_CONFIG_C.LCLS2_COUNT_C);
      end if;

      -- Init and setup MPS message
      v.mpsMessage.version   := mpsReg.mpsCore.mpsVersion;
      v.mpsMessage.lcls      := mpsReg.mpsCore.lcls1Mode;
      v.mpsMessage.timeStamp := mpsSelect.timeStamp;
      v.mpsMessage.appId     := resize(mpsReg.mpsCore.mpsAppId, 16);
      v.mpsMessage.valid     := mpsSelect.valid and mpsReg.mpsCore.mpsEnable;

      -- Init message data
      msgData := (others => (others => '0'));

      -- Digtal Application
      if APP_CONFIG_C.DIGITAL_EN_C = true then
         v.mpsMessage.inputType := '0';

         for b in 0 to 7 loop
            digitalBit (mpsSelect.digitalBus(b), b, r.tholdMem(0, b), v.tholdMem(0, b), msgData);
         end loop;

      -- Analog Process each enabled channel
      else
         v.mpsMessage.inputType := '1';

         for chan in 0 to (MPS_CHAN_COUNT_C-1) loop

            -- Threshold is enabled and mps channel is not ignored
            if APP_CONFIG_C.CHAN_CONFIG_C(chan).THOLD_COUNT_C > 0 then

               -- Channel is marked in error, set all bits
               if mpsSelect.mpsError(chan) = '1' then
                  for i in 0 to 7 loop
                     msgData(APP_CONFIG_C.CHAN_CONFIG_C(chan).BYTE_MAP_C)(i) := '1';
                     v.tholdMem(chan, 0)                                     := (others => '1');
                  end loop;

               -- LCLS1 Mode
               elsif APP_CONFIG_C.CHAN_CONFIG_C(chan).LCLS1_EN_C and mpsReg.mpsCore.lcls1Mode = '1' then
                  compareTholds (mpsReg.mpsChanReg(chan).lcls1Thold,
                                 APP_CONFIG_C.CHAN_CONFIG_C(chan),
                                 mpsSelect.chanData(chan), mpsSelect.mpsIgnore(chan), 
                                 0, r.tholdMem(chan, 0), v.tholdMem(chan, 0), msgData);

               -- LCLS2 idle table
               elsif APP_CONFIG_C.CHAN_CONFIG_C(chan).IDLE_EN_C and mpsReg.mpsChanReg(chan).idleEn = '1' and mpsSelect.selectIdle = '1' then
                  compareTholds (mpsReg.mpsChanReg(chan).idleThold,
                                 APP_CONFIG_C.CHAN_CONFIG_C(chan),
                                 mpsSelect.chanData(chan), mpsSelect.mpsIgnore(chan), 
                                 7, r.tholdMem(chan, 7), v.tholdMem(chan, 7), msgData);

               -- Multiple thresholds
               else
                  for thold in 0 to (APP_CONFIG_C.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop

                     -- Alternate table
                     if APP_CONFIG_C.CHAN_CONFIG_C(chan).ALT_EN_C and mpsSelect.selectAlt = '1' then
                        compareTholds (mpsReg.mpsChanReg(chan).altTholds(thold),
                                       APP_CONFIG_C.CHAN_CONFIG_C(chan),
                                       mpsSelect.chanData(chan), mpsSelect.mpsIgnore(chan), 
                                       thold, r.tholdMem(chan, thold), v.tholdMem(chan, thold), msgData);

                     -- Standard table
                     else
                        compareTholds (mpsReg.mpsChanReg(chan).stdTholds(thold),
                                       APP_CONFIG_C.CHAN_CONFIG_C(chan),
                                       mpsSelect.chanData(chan), mpsSelect.mpsIgnore(chan), 
                                       thold, r.tholdMem(chan, thold), v.tholdMem(chan, thold), msgData);
                     end if;
                  end loop;
               end if;
            end if;
         end loop;
      end if;

      -- Update message data
      v.mpsMessage.message(APP_CONFIG_C.BYTE_COUNT_C-1 downto 0) := msgData;

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
   U_MsgGen : entity work.MpsMsgCore
      generic map (
         TPD_G            => TPD_G,
         SIM_ERROR_HALT_G => false)
      port map (
         clk        => axilClk,
         rst        => axilRst,
         mpsMessage => r.mpsMessage,
         mpsMsgDrop => mpsMsgDrop,
         mpsMaster  => mpsMaster,
         mpsSlave   => mpsSlave);

end mapping;

