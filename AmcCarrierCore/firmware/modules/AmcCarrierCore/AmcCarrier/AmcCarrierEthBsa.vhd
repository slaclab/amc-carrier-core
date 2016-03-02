-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthBsa.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-23
-- Last update: 2016-03-02
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

entity AmcCarrierEthBsa is
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
      -- BSA Ethernet Interface
      obBsaMasters    : in  AxiStreamMasterArray(2 downto 0);
      obBsaSlaves     : out AxiStreamSlaveArray(2 downto 0);
      ibBsaMasters    : out AxiStreamMasterArray(2 downto 0);
      ibBsaSlaves     : in  AxiStreamSlaveArray(2 downto 0);
      -- Interface to UDP Server engines
      obServerMasters : in  AxiStreamMasterArray(2 downto 0);
      obServerSlaves  : out AxiStreamSlaveArray(2 downto 0);
      ibServerMasters : out AxiStreamMasterArray(2 downto 0);
      ibServerSlaves  : in  AxiStreamSlaveArray(2 downto 0));   
end AmcCarrierEthBsa;

architecture mapping of AmcCarrierEthBsa is

   function AxiLiteConfig return AxiLiteCrossbarMasterConfigArray is
      variable retConf : AxiLiteCrossbarMasterConfigArray(2 downto 0);
      variable addr    : slv(31 downto 0);
   begin
      addr := AXI_BASE_ADDR_G;
      for i in 2 downto 0 loop
         addr(14 downto 10)      := toSlv(i, 5);
         retConf(i).baseAddr     := addr;
         retConf(i).addrBits     := 10;
         retConf(i).connectivity := x"0001";
      end loop;
      return retConf;
   end function;

   signal axilWriteMasters : AxiLiteWriteMasterArray(2 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(2 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(2 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(2 downto 0);

   signal depacketizerMasters : AxiStreamMasterArray(2 downto 0);
   signal depacketizerSlaves  : AxiStreamSlaveArray(2 downto 0);
   signal packetizerMasters   : AxiStreamMasterArray(2 downto 0);
   signal packetizerSlaves    : AxiStreamSlaveArray(2 downto 0);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 3,
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

   GEN_BSA : for i in 2 downto 0 generate

      GEN_BYPASS : if (RSSI_G = false) generate
         
         U_AxiStreamFifo_Depacketizer : entity work.AxiStreamFifo
            generic map (
               TPD_G               => TPD_G,
               SLAVE_READY_EN_G    => true,
               BRAM_EN_G           => false,
               GEN_SYNC_FIFO_G     => true,
               FIFO_ADDR_WIDTH_G   => 4,
               PIPE_STAGES_G       => 1,
               SLAVE_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
               MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(8))
            port map (
               sAxisClk    => axilClk,
               sAxisRst    => axilRst,
               sAxisMaster => obServerMasters(i),
               sAxisSlave  => obServerSlaves(i),
               mAxisClk    => axilClk,
               mAxisRst    => axilRst,
               mAxisMaster => depacketizerMasters(i),
               mAxisSlave  => depacketizerSlaves(i));  

         U_AxiStreamDepacketizer_1 : entity work.AxiStreamDepacketizer
            generic map (
               TPD_G                => TPD_G,
               INPUT_PIPE_STAGES_G  => 1,
               OUTPUT_PIPE_STAGES_G => 1)
            port map (
               axisClk     => axilClk,
               axisRst     => axilRst,
               sAxisMaster => depacketizerMasters(i),
               sAxisSlave  => depacketizerSlaves(i),
               mAxisMaster => ibBsaMasters(i),
               mAxisSlave  => ibBsaSlaves(i));         

         U_AxiStreamPacketizer_1 : entity work.AxiStreamPacketizer
            generic map (
               TPD_G                => TPD_G,
               MAX_PACKET_BYTES_G   => 1440,
               INPUT_PIPE_STAGES_G  => 1,
               OUTPUT_PIPE_STAGES_G => 1)
            port map (
               axisClk     => axilClk,
               axisRst     => axilRst,
               sAxisMaster => obBsaMasters(i),
               sAxisSlave  => obBsaSlaves(i),
               mAxisMaster => packetizerMasters(i),
               mAxisSlave  => packetizerSlaves(i));  

         U_AxiStreamFifo_Packetizer : entity work.AxiStreamFifo
            generic map (
               TPD_G               => TPD_G,
               SLAVE_READY_EN_G    => true,
               BRAM_EN_G           => false,
               GEN_SYNC_FIFO_G     => true,
               FIFO_ADDR_WIDTH_G   => 4,
               PIPE_STAGES_G       => 1,
               SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(8),
               MASTER_AXI_CONFIG_G => IP_ENGINE_CONFIG_C)
            port map (
               sAxisClk    => axilClk,
               sAxisRst    => axilRst,
               sAxisMaster => packetizerMasters(i),
               sAxisSlave  => packetizerSlaves(i),
               mAxisClk    => axilClk,
               mAxisRst    => axilRst,
               mAxisMaster => ibServerMasters(i),
               mAxisSlave  => ibServerSlaves(i));    

         U_AxiLiteEmpty : entity work.AxiLiteEmpty
            generic map (
               TPD_G            => TPD_G,
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
            port map (
               axiClk         => axilClk,
               axiClkRst      => axilRst,
               axiReadMaster  => axilReadMasters(i),
               axiReadSlave   => axilReadSlaves(i),
               axiWriteMaster => axilWriteMasters(i),
               axiWriteSlave  => axilWriteSlaves(i));                 

      end generate;

      GEN_RSSI : if (RSSI_G = true) generate
         ---------------------
         -- RSSI Server Module
         ---------------------
         U_RssiServer : entity work.RssiCoreWrapper
            generic map (
               TPD_G                   => TPD_G,
               CLK_FREQUENCY_G         => AXI_CLK_FREQ_C,
               TIMEOUT_UNIT_G          => TIMEOUT_G,
               SERVER_G                => true,
               RETRANSMIT_ENABLE_G     => true,
               WINDOW_ADDR_SIZE_G      => 3,
               PIPE_STAGES_G           => 1,
               APP_INPUT_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
               APP_OUTPUT_AXI_CONFIG_G => IP_ENGINE_CONFIG_C,
               TSP_INPUT_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
               TSP_OUTPUT_AXI_CONFIG_G => IP_ENGINE_CONFIG_C,
               INIT_SEQ_N_G            => 16#80#)
            port map (
               clk_i            => axilClk,
               rst_i            => axilRst,
               -- Application Layer Interface
               sAppAxisMaster_i => obBsaMasters(i),
               sAppAxisSlave_o  => obBsaSlaves(i),
               mAppAxisMaster_o => ibBsaMasters(i),
               mAppAxisSlave_i  => ibBsaSlaves(i),
               -- Transport Layer Interface
               sTspAxisMaster_i => obServerMasters(i),
               sTspAxisSlave_o  => obServerSlaves(i),
               mTspAxisMaster_o => ibServerMasters(i),
               mTspAxisSlave_i  => ibServerSlaves(i),
               -- AXI-Lite Interface
               axiClk_i         => axilClk,
               axiRst_i         => axilRst,
               axilReadMaster   => axilReadMasters(i),
               axilReadSlave    => axilReadSlaves(i),
               axilWriteMaster  => axilWriteMasters(i),
               axilWriteSlave   => axilWriteSlaves(i));   
      end generate;
      
   end generate GEN_BSA;
   
end mapping;
