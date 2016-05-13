-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthBpMsg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2016-05-12
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.UdpEnginePkg.all;
use work.IpV4EnginePkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierEthBpMsg is
   generic (
      TPD_G            : time             := 1 ns;
      RSSI_G           : boolean          := false;
      TIMEOUT_G        : real             := 1.0E-3;  -- In units of seconds   
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Interface to UDP Server engines
      obServerMasters : in  AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
      obServerSlaves  : out AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);
      ibServerMasters : out AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
      ibServerSlaves  : in  AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);
      -- Interface to UDP Client engines
      obClientMasters : in  AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
      obClientSlaves  : out AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);
      ibClientMasters : out AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
      ibClientSlaves  : in  AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);
      -- Backplane Messaging Interface
      bpMsgMasters    : in  AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
      bpMsgSlaves     : out AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Backplane Messaging Interface (bpMsgClk domain)
      bpMsgClk        : in  sl;
      bpMsgRst        : in  sl;
      bpMsgBus        : out BpMsgBusArray(BP_MSG_SIZE_C-1 downto 0));
end AmcCarrierEthBpMsg;

architecture mapping of AmcCarrierEthBpMsg is

   function AxiLiteConfig return AxiLiteCrossbarMasterConfigArray is
      variable retConf : AxiLiteCrossbarMasterConfigArray((2*BP_MSG_SIZE_C)-1 downto 0);
      variable addr    : slv(31 downto 0);
   begin
      addr := AXI_BASE_ADDR_G;
      for i in (2*BP_MSG_SIZE_C)-1 downto 0 loop
         addr(14 downto 10)      := toSlv(i, 5);
         retConf(i).baseAddr     := addr;
         retConf(i).addrBits     := 10;
         retConf(i).connectivity := x"FFFF";
      end loop;
      return retConf;
   end function;

   signal axilWriteMasters : AxiLiteWriteMasterArray((2*BP_MSG_SIZE_C)-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray((2*BP_MSG_SIZE_C)-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray((2*BP_MSG_SIZE_C)-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray((2*BP_MSG_SIZE_C)-1 downto 0);

   signal msgMasters : AxiStreamMasterArray(BP_MSG_SIZE_C-1 downto 0);
   signal msgSlaves  : AxiStreamSlaveArray(BP_MSG_SIZE_C-1 downto 0);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => (2*BP_MSG_SIZE_C),
         MASTERS_CONFIG_G   => AxiLiteConfig)
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

   GEN_BP_MSG :
   for i in (BP_MSG_SIZE_C-1) downto 0 generate

      GEN_BYPASS : if (RSSI_G = false) generate

         ibServerMasters(i) <= bpMsgMasters(i);
         bpMsgSlaves(i)     <= ibServerSlaves(i);
         obServerSlaves(i)  <= AXI_STREAM_SLAVE_FORCE_C;
         msgMasters(i)      <= obClientMasters(i);
         obClientSlaves(i)  <= msgSlaves(i);
         ibClientMasters(i) <= AXI_STREAM_MASTER_INIT_C;

         U_AxiLiteEmpty0 : entity work.AxiLiteEmpty
            generic map (
               TPD_G            => TPD_G,
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
            port map (
               axiClk         => axilClk,
               axiClkRst      => axilRst,
               axiReadMaster  => axilReadMasters((2*i)+0),
               axiReadSlave   => axilReadSlaves((2*i)+0),
               axiWriteMaster => axilWriteMasters((2*i)+0),
               axiWriteSlave  => axilWriteSlaves((2*i)+0));

         U_AxiLiteEmpty1 : entity work.AxiLiteEmpty
            generic map (
               TPD_G            => TPD_G,
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
            port map (
               axiClk         => axilClk,
               axiClkRst      => axilRst,
               axiReadMaster  => axilReadMasters((2*i)+1),
               axiReadSlave   => axilReadSlaves((2*i)+1),
               axiWriteMaster => axilWriteMasters((2*i)+1),
               axiWriteSlave  => axilWriteSlaves((2*i)+1));

      end generate;

      GEN_RSSI : if (RSSI_G = true) generate
         ---------------------
         -- RSSI Server Module
         ---------------------
         U_RssiServer : entity work.RssiCoreWrapper
            generic map (
               TPD_G                    => TPD_G,
               CLK_FREQUENCY_G          => AXI_CLK_FREQ_C,
               TIMEOUT_UNIT_G           => TIMEOUT_G,
               SERVER_G                 => true,
               RETRANSMIT_ENABLE_G      => true,
               WINDOW_ADDR_SIZE_G       => 1,
               MAX_NUM_OUTS_SEG_G       => (2**1),
               PIPE_STAGES_G            => 1,
               APP_INPUT_AXIS_CONFIG_G  => IP_ENGINE_CONFIG_C,
               APP_OUTPUT_AXIS_CONFIG_G => IP_ENGINE_CONFIG_C,
               TSP_INPUT_AXIS_CONFIG_G  => IP_ENGINE_CONFIG_C,
               TSP_OUTPUT_AXIS_CONFIG_G => IP_ENGINE_CONFIG_C,
               INIT_SEQ_N_G             => 16#80#)
            port map (
               clk_i                => axilClk,
               rst_i                => axilRst,
               -- Application Layer Interface
               sAppAxisMasters_i(0) => bpMsgMasters(i),
               sAppAxisSlaves_o(0)  => bpMsgSlaves(i),
               mAppAxisMasters_o(0) => open,
               mAppAxisSlaves_i(0)  => AXI_STREAM_SLAVE_FORCE_C,
               -- Transport Layer Interface
               sTspAxisMaster_i     => obServerMasters(i),
               sTspAxisSlave_o      => obServerSlaves(i),
               mTspAxisMaster_o     => ibServerMasters(i),
               mTspAxisSlave_i      => ibServerSlaves(i),
               -- AXI-Lite Interface
               axiClk_i             => axilClk,
               axiRst_i             => axilRst,
               axilReadMaster       => axilReadMasters((2*i)+0),
               axilReadSlave        => axilReadSlaves((2*i)+0),
               axilWriteMaster      => axilWriteMasters((2*i)+0),
               axilWriteSlave       => axilWriteSlaves((2*i)+0));

         ---------------------
         -- RSSI Client Module
         ---------------------
         U_RssiClient : entity work.RssiCoreWrapper
            generic map (
               TPD_G                    => TPD_G,
               CLK_FREQUENCY_G          => AXI_CLK_FREQ_C,
               TIMEOUT_UNIT_G           => TIMEOUT_G,
               SERVER_G                 => false,
               RETRANSMIT_ENABLE_G      => true,
               WINDOW_ADDR_SIZE_G       => 1,
               MAX_NUM_OUTS_SEG_G       => (2**1),
               PIPE_STAGES_G            => 1,
               APP_INPUT_AXIS_CONFIG_G  => IP_ENGINE_CONFIG_C,
               APP_OUTPUT_AXIS_CONFIG_G => IP_ENGINE_CONFIG_C,
               TSP_INPUT_AXIS_CONFIG_G  => IP_ENGINE_CONFIG_C,
               TSP_OUTPUT_AXIS_CONFIG_G => IP_ENGINE_CONFIG_C,
               INIT_SEQ_N_G             => 16#20#)
            port map (
               clk_i                => axilClk,
               rst_i                => axilRst,
               -- Application Layer Interface
               sAppAxisMasters_i(0) => AXI_STREAM_MASTER_INIT_C,
               sAppAxisSlaves_o(0)  => open,
               mAppAxisMasters_o(0) => msgMasters(i),
               mAppAxisSlaves_i(0)  => msgSlaves(i),
               -- Transport Layer Interface
               sTspAxisMaster_i     => obClientMasters(i),
               sTspAxisSlave_o      => obClientSlaves(i),
               mTspAxisMaster_o     => ibClientMasters(i),
               mTspAxisSlave_i      => ibClientSlaves(i),
               -- AXI-Lite Interface
               axiClk_i             => axilClk,
               axiRst_i             => axilRst,
               axilReadMaster       => axilReadMasters((2*i)+1),
               axilReadSlave        => axilReadSlaves((2*i)+1),
               axilWriteMaster      => axilWriteMasters((2*i)+1),
               axilWriteSlave       => axilWriteSlaves((2*i)+1));
      end generate;

      -----------------------
      -- BP Messenger Network
      -----------------------
      U_BpMsg : entity work.AmcCarrierBpMsgIb
         generic map (
            TPD_G => TPD_G)
         port map (
            -- Clock and reset
            clk            => axilClk,
            rst            => axilRst,
            obServerMaster => msgMasters(i),
            obServerSlave  => msgSlaves(i),
            ----------------------
            -- Top Level Interface
            ----------------------
            -- Backplane Messaging Interface (bpMsgClk domain)
            bpMsgClk       => bpMsgClk,
            bpMsgRst       => bpMsgRst,
            bpMsgBus       => bpMsgBus(i));

   end generate GEN_BP_MSG;

end mapping;
