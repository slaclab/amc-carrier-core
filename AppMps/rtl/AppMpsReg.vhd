-------------------------------------------------------------------------------
-- File       : AppMpsReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
-- Last update: 2017-04-13
-------------------------------------------------------------------------------
-- Description: 
-- See https://docs.google.com/spreadsheets/d/1BwDq9yZhAhpwpiJvPs6E53W_D4USY0Zc7HhFdv3SpEA/edit?usp=sharing
-- for associated spreadsheet
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
use work.AxiLitePkg.all;
use work.AmcCarrierPkg.all;
use work.AppMpsPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsReg is
   generic (
      TPD_G            : time             := 1 ns;
      APP_TYPE_G       : AppType          := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      APP_CONFIG_G     : MpsAppConfigType := MPS_APP_CONFIG_INIT_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- MPS Configuration Registers
      mpsAppRegisters : out MpsAppRegType);

end AppMpsReg;

architecture mapping of AppMpsReg is

   type RegType is record
      mpsReg         : MpsAppRegType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsReg         => MPS_APP_REG_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v     : RegType;
      variable regEp : AxiLiteEndPointType;
      variable chan  : natural;
      variable thold : natural;
      variable base  : natural;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Top level registers
      axiSlaveRegister(regEp, x"0000", 0, v.mpsReg.mpsAppId);
      axiSlaveRegister(regEp, x"0000", 16, v.mpsReg.mpsEnable);
      axiSlaveRegister(regEp, x"0000", 17, v.mpsReg.lcls1Mode);
      axiSlaveRegister(regEp, x"0000", 24, v.mpsReg.kickDetMode);

--      axiSlaveRegisterR(regEp, x"0004", 0, toSlv(APP_CONFIG_G.BYTE_COUNT_C,8); -- missing toSlv fuction
--      axiSlaveRegisterR(regEp, x"0004", 8, toSlv(APP_CONFIG_G.DIGITAL_EN_C,1); -- missing toSlv fuction

      axiSlaveRegister(regEp, x"0008", 0, v.mpsReg.beamDestMask);
      axiSlaveRegister(regEp, x"0008", 16, v.mpsReg.altDestMask);

      -- Chan 0 = 0x8000, Chan 1 = 0x8200, Chan 3 = 0x8400 ... Chan 23 = 0xAE00
      for chan in 0 to (MPS_CHAN_COUNT_C-1) loop
         if APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C > 0 then
            base := 32768 + (chan * 512);

            -- Offset base + 0x0
--            axiSlaveRegisterR(regEp, toSlv(base, 16),  0, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C,8); -- missing toSlv fuction
--            axiSlaveRegisterR(regEp, toSlv(base, 16),  8, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(chan).IDLE_EN_C,1); -- missing toSlv fuction
--            axiSlaveRegisterR(regEp, toSlv(base, 16),  9, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(chan).ALT_EN_C,1); -- missing toSlv fuction
--            axiSlaveRegisterR(regEp, toSlv(base, 16), 10, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(chan).LCLS1_EN_C,1); -- missing toSlv fuction
--            axiSlaveRegisterR(regEp, toSlv(base, 16), 16, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(chan).BYTE_MAP_C,8); -- missing toSlv fuction

            -- Offset base + 0x10, 0x14, 0x18
            if APP_CONFIG_G.CHAN_CONFIG_C(chan).LCLS1_EN_C then
               axiSlaveRegister(regEp, toSlv(base + 16, 16), 0, v.mpsReg.mpsChanReg(chan).lcls1Thold.minTholdEn);
               axiSlaveRegister(regEp, toSlv(base + 16, 16), 1, v.mpsReg.mpsChanReg(chan).lcls1Thold.maxTholdEn);
               axiSlaveRegister(regEp, toSlv(base + 20, 16), 0, v.mpsReg.mpsChanReg(chan).lcls1Thold.minThold);
               axiSlaveRegister(regEp, toSlv(base + 24, 16), 0, v.mpsReg.mpsChanReg(chan).lcls1Thold.maxThold);
            end if;

            -- Offset base + 0x20, 0x24, 0x28
            if APP_CONFIG_G.CHAN_CONFIG_C(chan).IDLE_EN_C then
               axiSlaveRegister(regEp, toSlv(base + 32, 16), 0, v.mpsReg.mpsChanReg(chan).idleThold.minTholdEn);
               axiSlaveRegister(regEp, toSlv(base + 32, 16), 1, v.mpsReg.mpsChanReg(chan).idleThold.maxTholdEn);
               axiSlaveRegister(regEp, toSlv(base + 36, 16), 0, v.mpsReg.mpsChanReg(chan).idleThold.minThold);
               axiSlaveRegister(regEp, toSlv(base + 40, 16), 0, v.mpsReg.mpsChanReg(chan).idleThold.maxThold);
            end if;

            for thold in 0 to (APP_CONFIG_G.CHAN_CONFIG_C(chan).THOLD_COUNT_C-1) loop

               -- standard: thold 0 = base + 0x100, thold 1 = base + 0x110, thold 7 = base + 0x170
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 0, 16), 0, v.mpsReg.mpsChanReg(chan).stdTholds(thold).minTholdEn);
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 0, 16), 1, v.mpsReg.mpsChanReg(chan).stdTholds(thold).maxTholdEn);
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 4, 16), 0, v.mpsReg.mpsChanReg(chan).stdTholds(thold).minThold);
               axiSlaveRegister(regEp, toSlv(base + (thold*16) + 8, 16), 0, v.mpsReg.mpsChanReg(chan).stdTholds(thold).maxThold);

               -- alt: thold 0 = base + 0x180, thold 1 = base + 0x190, thold 7 = base + 0x1F0
               if APP_CONFIG_G.CHAN_CONFIG_C(chan).ALT_EN_C then
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 0, 16), 0, v.mpsReg.mpsChanReg(chan).altTholds(thold).minTholdEn);
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 0, 16), 1, v.mpsReg.mpsChanReg(chan).altTholds(thold).maxTholdEn);
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 4, 16), 0, v.mpsReg.mpsChanReg(chan).altTholds(thold).minThold);
                  axiSlaveRegister(regEp, toSlv(base + 128 + (thold*16) + 8, 16), 0, v.mpsReg.mpsChanReg(chan).altTholds(thold).maxThold);
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
