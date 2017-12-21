-------------------------------------------------------------------------------
-- File       : AppMpsRegAppCh.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
-- Last update: 2017-12-21
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

entity AppMpsRegAppCh is
   generic (
      TPD_G            : time             := 1 ns;
      CHAN_G           : natural          := 0;
      APP_TYPE_G       : AppType          := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      APP_CONFIG_G     : MpsAppConfigType := MPS_APP_CONFIG_INIT_C);
   port (
      -- MPS Configuration Registers
      mpsChanReg      : out MpsChanRegType;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end AppMpsRegAppCh;

architecture mapping of AppMpsRegAppCh is

   type RegType is record
      mpsChanReg     : MpsChanRegType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsChanReg     => MPS_CHAN_REG_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v     : RegType;
      variable regEp : AxiLiteEndPointType;
      variable thold : natural;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      if APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).THOLD_COUNT_C > 0 then

         -- Offset 0x0
         axiSlaveRegisterR(regEp, toSlv(0, 9), 0, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).THOLD_COUNT_C, 8));

         if APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).IDLE_EN_C then
            axiSlaveRegister(regEp, toSlv(0, 9), 8, v.mpsChanReg.idleEn);
         else
            axiSlaveRegisterR(regEp, toSlv(0, 9), 8, '0');
         end if;

         axiSlaveRegisterR(regEp, toSlv(0, 9), 9, ite(APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).ALT_EN_C, '1', '0'));
         axiSlaveRegisterR(regEp, toSlv(0, 9), 10, ite(APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).LCLS1_EN_C, '1', '0'));
         axiSlaveRegisterR(regEp, toSlv(0, 9), 16, toSlv(APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).BYTE_MAP_C, 8));

         -- Offset 0x10, 0x14, 0x18
         if APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).LCLS1_EN_C then
            axiSlaveRegister(regEp, toSlv(16, 9), 0, v.mpsChanReg.lcls1Thold.minTholdEn);
            axiSlaveRegister(regEp, toSlv(16, 9), 1, v.mpsChanReg.lcls1Thold.maxTholdEn);
            axiSlaveRegister(regEp, toSlv(20, 9), 0, v.mpsChanReg.lcls1Thold.minThold);
            axiSlaveRegister(regEp, toSlv(24, 9), 0, v.mpsChanReg.lcls1Thold.maxThold);
         end if;

         -- Offset 0x20, 0x24, 0x28
         if APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).IDLE_EN_C then
            axiSlaveRegister(regEp, toSlv(32, 9), 0, v.mpsChanReg.idleThold.minTholdEn);
            axiSlaveRegister(regEp, toSlv(32, 9), 1, v.mpsChanReg.idleThold.maxTholdEn);
            axiSlaveRegister(regEp, toSlv(36, 9), 0, v.mpsChanReg.idleThold.minThold);
            axiSlaveRegister(regEp, toSlv(40, 9), 0, v.mpsChanReg.idleThold.maxThold);
         end if;

         for thold in 0 to (APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).THOLD_COUNT_C-1) loop

            -- standard: thold 0 = 0x100, thold 1 = 0x110, thold 7 = 0x170
            axiSlaveRegister(regEp, toSlv(256 + (thold*16) + 0, 9), 0, v.mpsChanReg.stdTholds(thold).minTholdEn);
            axiSlaveRegister(regEp, toSlv(256 + (thold*16) + 0, 9), 1, v.mpsChanReg.stdTholds(thold).maxTholdEn);
            axiSlaveRegister(regEp, toSlv(256 + (thold*16) + 4, 9), 0, v.mpsChanReg.stdTholds(thold).minThold);
            axiSlaveRegister(regEp, toSlv(256 + (thold*16) + 8, 9), 0, v.mpsChanReg.stdTholds(thold).maxThold);

            -- alt: thold 0 = 0x180, thold 1 = 0x190, thold 7 = 0x1F0
            if APP_CONFIG_G.CHAN_CONFIG_C(CHAN_G).ALT_EN_C then
               axiSlaveRegister(regEp, toSlv(384 + (thold*16) + 0, 9), 0, v.mpsChanReg.altTholds(thold).minTholdEn);
               axiSlaveRegister(regEp, toSlv(384 + (thold*16) + 0, 9), 1, v.mpsChanReg.altTholds(thold).maxTholdEn);
               axiSlaveRegister(regEp, toSlv(384 + (thold*16) + 4, 9), 0, v.mpsChanReg.altTholds(thold).minThold);
               axiSlaveRegister(regEp, toSlv(384 + (thold*16) + 8, 9), 0, v.mpsChanReg.altTholds(thold).maxThold);
            end if;
         end loop;
      end if;

      -- Closeout the transaction
      axiSlaveDefault(regEp, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      mpsChanReg     <= r.mpsChanReg;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
