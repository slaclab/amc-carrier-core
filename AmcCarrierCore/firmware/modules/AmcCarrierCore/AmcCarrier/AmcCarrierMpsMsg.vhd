-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsMsg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2016-05-26
-- Platform   : 
-- Standard   : VHDL'93/02
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierMpsMsg is
   generic (
      TPD_G            : time             := 1 ns;
      SIM_ERROR_HALT_G : boolean          := false;
      APP_TYPE_G       : AppType          := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));      
   port (
      -- AXI-Lite Interface: [AXI_BASE_ADDR_G+0x00000000:AXI_BASE_ADDR_G+0x00007FFF]
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Inbound Message Value
      enable          : in  sl;
      message         : in  Slv32Array(31 downto 0);
      timeStrb        : in  sl;
      timeStamp       : in  slv(15 downto 0);
      testMode        : in  sl;
      appId           : in  slv(15 downto 0);
      -- MPS Interface
      mpsMaster       : out AxiStreamMasterType;
      mpsSlave        : in  AxiStreamSlaveType);   
end AmcCarrierMpsMsg;

architecture mapping of AmcCarrierMpsMsg is

   constant MPS_CHANNELS_C    : natural range 0 to 32  := getMpsChCnt(APP_TYPE_G);
   constant MPS_THRESHOLD_C   : natural range 0 to 256 := getMpsThresholdCnt(APP_TYPE_G);
   constant NUM_AXI_MASTERS_C : natural                := ite((MPS_CHANNELS_C = 0), 1, MPS_CHANNELS_C);

   function genConfig (baseAddr : slv(31 downto 0)) return AxiLiteCrossbarMasterConfigArray is
      variable retVar : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0);
      variable i      : natural;
   begin
      for i in NUM_AXI_MASTERS_C-1 downto 0 loop
         retVar(i).baseAddr     := baseAddr + toSlv((i*1024), 32);
         retVar(i).addrBits     := 10;
         retVar(i).connectivity := X"FFFF";
      end loop;
      return retVar;
   end function;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genConfig(AXI_BASE_ADDR_G);

   signal ramWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal ibValid    : sl;
   signal obValid    : slv(31 downto 0);
   signal obValue    : Slv8Array(31 downto 0);
   signal mpsMessage : MpsMessageType;

begin

   ibValid <= timeStrb and enable;

   DONT_SYNTH : if (MPS_CHANNELS_C = 0) generate

      obValid <= (others => '0');
      obValue <= (others => (others => '0'));

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_RESP_OK_C)  -- Don't respond with error
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave);

   end generate;

   MPS_SYNTH : if (MPS_CHANNELS_C /= 0) generate

      U_XBAR : entity work.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
            MASTERS_CONFIG_G   => AXI_CONFIG_C)
         port map (
            axiClk              => axilClk,
            axiClkRst           => axilRst,
            sAxiWriteMasters(0) => axilWriteMaster,
            sAxiWriteSlaves(0)  => axilWriteSlave,
            sAxiReadMasters(0)  => axilReadMaster,
            sAxiReadSlaves(0)   => axilReadSlave,
            mAxiWriteMasters    => ramWriteMasters,
            mAxiWriteSlaves     => ramWriteSlaves,
            mAxiReadMasters     => ramReadMasters,
            mAxiReadSlaves      => ramReadSlaves);  

      GEN_VEC :
      for i in NUM_AXI_MASTERS_C-1 downto 0 generate
         
         U_Encoder : entity work.AmcCarrierMpsEncoder
            generic map (
               TPD_G            => TPD_G,
               MPS_THRESHOLD_G  => MPS_THRESHOLD_C,
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
               AXI_BASE_ADDR_G  => AXI_CONFIG_C(i).baseAddr)
            port map (
               -- AXI-Lite Interface
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => ramReadMasters(i),
               axilReadSlave   => ramReadSlaves(i),
               axilWriteMaster => ramWriteMasters(i),
               axilWriteSlave  => ramWriteSlaves(i),
               -- Inbound Message Value
               ibValid         => ibValid,
               ibValue         => message(i),
               -- Outbound Encode MPS Value
               obValid         => obValid(i),
               obValue         => obValue(i));

      end generate GEN_VEC;
      
   end generate;

   U_MsgCore : entity work.AmcCarrierMpsMsgCore
      generic map (
         TPD_G            => TPD_G,
         SIM_ERROR_HALT_G => SIM_ERROR_HALT_G,
         APP_TYPE_G       => APP_TYPE_G)
      port map (
         clk        => axilClk,
         rst        => axilRst,
         -- Inbound Message Value
         mpsMessage => mpsMessage,
         -- Outbound MPS Interface
         mpsMaster  => mpsMaster,
         mpsSlave   => mpsSlave);  

   mpsMessage.valid     <= obValid(0);
   mpsMessage.timeStamp <= timeStamp;
   mpsMessage.testMode  <= testMode;
   mpsMessage.appId     <= appId;
   mpsMessage.message   <= obValue;
   mpsMessage.msgSize   <= toSlv(MPS_CHANNELS_C, 8);

end mapping;
