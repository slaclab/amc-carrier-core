-------------------------------------------------------------------------------
-- File       : AppMpsReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
-- Last update: 2018-03-14
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use work.AmcCarrierPkg.all;
use work.AppMpsPkg.all;

entity AppMpsReg is
   generic (
      TPD_G           : time             := 1 ns;
      APP_TYPE_G      : AppType          := APP_NULL_TYPE_C;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0');
      APP_CONFIG_G    : MpsAppConfigType := MPS_APP_CONFIG_INIT_C);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- MPS message monitoring
      mpsMessage      : in  MpsMessageType;
      mpsMsgDrop      : in  sl;
      -- MPS Configuration Registers
      mpsAppRegisters : out MpsAppRegType);
end AppMpsReg;

architecture mapping of AppMpsReg is

   constant XBAR0_CONFIG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := (
      0               => (
         baseAddr     => AXI_BASE_ADDR_G,
         addrBits     => 12,
         connectivity => X"FFFF"),
      1               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_8000"),
         addrBits     => 15,
         connectivity => X"FFFF"));

   signal axilReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0);

   constant XBAR1_CONFIG_C : AxiLiteCrossbarMasterConfigArray(MPS_CHAN_COUNT_C-1 downto 0) := genAxiLiteConfig(MPS_CHAN_COUNT_C, (AXI_BASE_ADDR_G + x"0000_8000"), 15, 9);

   signal chanWriteMasters : AxiLiteWriteMasterArray(MPS_CHAN_COUNT_C-1 downto 0);
   signal chanWriteSlaves  : AxiLiteWriteSlaveArray(MPS_CHAN_COUNT_C-1 downto 0);
   signal chanReadMasters  : AxiLiteReadMasterArray(MPS_CHAN_COUNT_C-1 downto 0);
   signal chanReadSlaves   : AxiLiteReadSlaveArray(MPS_CHAN_COUNT_C-1 downto 0);

begin

   U_XBAR_0 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,  -- Always return OK because AppMpsThr.yaml doesn't support dynamic application types (specifically APP_NULL_TYPE_C) yet
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 2,
         MASTERS_CONFIG_G   => XBAR0_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   U_BaseReg : entity work.AppMpsRegBase
      generic map (
         TPD_G        => TPD_G,
         APP_TYPE_G   => APP_TYPE_G,
         APP_CONFIG_G => APP_CONFIG_G)
      port map (
         -- MPS message monitoring
         mpsMessage      => mpsMessage,
         mpsMsgDrop      => mpsMsgDrop,
         -- MPS Configuration Registers
         mpsCore         => mpsAppRegisters.mpsCore,
         beamDestMask    => mpsAppRegisters.beamDestMask,
         altDestMask     => mpsAppRegisters.altDestMask,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   U_XBAR_1 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,  -- Always return OK because AppMpsThr.yaml doesn't support dynamic application types (specifically APP_NULL_TYPE_C) yet
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => MPS_CHAN_COUNT_C,
         MASTERS_CONFIG_G   => XBAR1_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMasters(1),
         sAxiWriteSlaves(0)  => axilWriteSlaves(1),
         sAxiReadMasters(0)  => axilReadMasters(1),
         sAxiReadSlaves(0)   => axilReadSlaves(1),
         mAxiWriteMasters    => chanWriteMasters,
         mAxiWriteSlaves     => chanWriteSlaves,
         mAxiReadMasters     => chanReadMasters,
         mAxiReadSlaves      => chanReadSlaves);

   GEN_VEC : for i in MPS_CHAN_COUNT_C-1 downto 0 generate

      U_ChanReg : entity work.AppMpsRegAppCh
         generic map (
            TPD_G         => TPD_G,
            CHAN_CONFIG_G => APP_CONFIG_G.CHAN_CONFIG_C(i))
         port map (
            -- MPS Configuration Registers
            mpsChanReg      => mpsAppRegisters.mpsChanReg(i),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => chanReadMasters(i),
            axilReadSlave   => chanReadSlaves(i),
            axilWriteMaster => chanWriteMasters(i),
            axilWriteSlave  => chanWriteSlaves(i));

   end generate GEN_VEC;

end mapping;
