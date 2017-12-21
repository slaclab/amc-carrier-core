-------------------------------------------------------------------------------
-- File       : AppMpsRegBase.vhd
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

entity AppMpsRegBase is
   generic (
      TPD_G            : time             := 1 ns;
      APP_TYPE_G       : AppType          := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      APP_CONFIG_G     : MpsAppConfigType := MPS_APP_CONFIG_INIT_C);
   port (
      -- MPS message monitoring
      mpsMessage      : in  MpsMessageType;
      -- MPS Configuration Registers
      mpsCore         : out MpsCoreRegType;
      beamDestMask    : out slv(15 downto 0);
      altDestMask     : out slv(15 downto 0);
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end AppMpsRegBase;

architecture mapping of AppMpsRegBase is

   type RegType is record
      mpsCore        : MpsCoreRegType;
      beamDestMask   : slv(15 downto 0);
      altDestMask    : slv(15 downto 0);
      mpsMessage     : MpsMessageType;
      mpsCount       : slv(31 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsCore        => MPS_CORE_REG_INIT_C,
      beamDestMask   => (others => '0'),
      altDestMask    => (others => '0'),
      mpsMessage     => MPS_MESSAGE_INIT_C,
      mpsCount       => (others => '0'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, mpsMessage, r) is
      variable v     : RegType;
      variable regEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- MPS message tracking
      if mpsMessage.valid = '1' then
         v.mpsMessage := mpsMessage;
         v.mpsCount   := r.mpsCount + 1;
      end if;

      -- Determine the transaction type
      axiSlaveWaitTxn(regEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Top level registers
      axiSlaveRegister(regEp, x"0000", 0, v.mpsCore.mpsAppId);
      axiSlaveRegister(regEp, x"0000", 16, v.mpsCore.mpsEnable);
      axiSlaveRegister(regEp, x"0000", 17, v.mpsCore.lcls1Mode);
      axiSlaveRegister(regEp, x"0000", 24, v.mpsCore.mpsVersion);

      axiSlaveRegisterR(regEp, x"0004", 0, toSlv(APP_CONFIG_G.BYTE_COUNT_C, 8));
      axiSlaveRegisterR(regEp, x"0004", 8, ite(APP_CONFIG_G.DIGITAL_EN_C, '1', '0'));

      axiSlaveRegister(regEp, x"0008", 0, v.beamDestMask);
      axiSlaveRegister(regEp, x"0008", 16, v.altDestMask);

      axiSlaveRegisterR(regEp, x"0010", 0, r.mpsCount);

      axiSlaveRegisterR(regEp, x"0014", 0, r.mpsMessage.appId(9 downto 0));
      axiSlaveRegisterR(regEp, x"0014", 10, r.mpsMessage.lcls);
      axiSlaveRegisterR(regEp, x"0014", 16, r.mpsMessage.timeStamp);

      axiSlaveRegisterR(regEp, x"0018", 0, r.mpsMessage.message(0));
      axiSlaveRegisterR(regEp, x"0018", 8, r.mpsMessage.message(1));
      axiSlaveRegisterR(regEp, x"0018", 16, r.mpsMessage.message(2));
      axiSlaveRegisterR(regEp, x"0018", 24, r.mpsMessage.message(3));

      axiSlaveRegisterR(regEp, x"001C", 0, r.mpsMessage.message(4));
      axiSlaveRegisterR(regEp, x"001C", 8, r.mpsMessage.message(5));

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
      mpsCore        <= r.mpsCore;
      beamDestMask   <= r.beamDestMask;
      altDestMask    <= r.altDestMask;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
