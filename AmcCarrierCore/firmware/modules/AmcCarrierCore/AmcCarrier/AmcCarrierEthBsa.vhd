-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthBsa.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-23
-- Last update: 2016-02-23
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
      TPD_G            : time            := 1 ns;
      RSSI_G           : boolean         := false;
      TIMEOUT_G        : real            := 1.0E-3;  -- In units of seconds   
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
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

begin

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

   GEN_BYPASS : if (RSSI_G = false) generate

      ---------------------------------
      -- BSA Inbound/Outbound Interface
      ---------------------------------
      PACKETIZER_GEN : for i in 2 downto 0 generate
         signal depacketizerMasters : AxiStreamMasterArray(2 downto 0);
         signal depacketizerSlaves  : AxiStreamSlaveArray(2 downto 0);
         signal packetizerMasters   : AxiStreamMasterArray(2 downto 0);
         signal packetizerSlaves    : AxiStreamSlaveArray(2 downto 0);
      begin
         U_AxiStreamFifo_Depacketizer : entity work.AxiStreamFifo
            generic map (
               TPD_G               => TPD_G,
               SLAVE_READY_EN_G    => true,
               BRAM_EN_G           => false,
               GEN_SYNC_FIFO_G     => true,
               FIFO_ADDR_WIDTH_G   => 4,
               SLAVE_AXI_CONFIG_G  => IP_ENGINE_CONFIG_C,
               MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(8))
            port map (
               sAxisClk    => axilClk,                 -- [in]
               sAxisRst    => axilRst,                 -- [in]
               sAxisMaster => obServerMasters(i),      -- [in]
               sAxisSlave  => obServerSlaves(i),       -- [out]
               mAxisClk    => axilClk,                 -- [in]
               mAxisRst    => axilRst,                 -- [in]
               mAxisMaster => depacketizerMasters(i),  -- [out]
               mAxisSlave  => depacketizerSlaves(i));  -- [in]

         U_AxiStreamDepacketizer_1 : entity work.AxiStreamDepacketizer
            generic map (
               TPD_G                => TPD_G,
               INPUT_PIPE_STAGES_G  => 1,
               OUTPUT_PIPE_STAGES_G => 1)
            port map (
               axisClk     => axilClk,                 -- [in]
               axisRst     => axilRst,                 -- [in]
               sAxisMaster => depacketizerMasters(i),  -- [in]
               sAxisSlave  => depacketizerSlaves(i),   -- [out]
               mAxisMaster => ibBsaMasters(i),         -- [out]
               mAxisSlave  => ibBsaSlaves(i));         -- [in]


         U_AxiStreamPacketizer_1 : entity work.AxiStreamPacketizer
            generic map (
               TPD_G                => TPD_G,
               MAX_PACKET_BYTES_C   => 1440,
               INPUT_PIPE_STAGES_G  => 1,
               OUTPUT_PIPE_STAGES_G => 1)
            port map (
               axisClk     => axilClk,               -- [in]
               axisRst     => axilRst,               -- [in]
               sAxisMaster => obBsaMasters(i),       -- [in]
               sAxisSlave  => obBsaSlaves(i),        -- [out]
               mAxisMaster => packetizerMasters(i),  -- [out]
               mAxisSlave  => packetizerSlaves(i));  -- [in]

         U_AxiStreamFifo_Packetizer : entity work.AxiStreamFifo
            generic map (
               TPD_G               => TPD_G,
               SLAVE_READY_EN_G    => true,
               BRAM_EN_G           => false,
               GEN_SYNC_FIFO_G     => true,
               FIFO_ADDR_WIDTH_G   => 4,
               SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(8),
               MASTER_AXI_CONFIG_G => IP_ENGINE_CONFIG_C)
            port map (
               sAxisClk    => axilClk,               -- [in]
               sAxisRst    => axilRst,               -- [in]
               sAxisMaster => packetizerMasters(i),  -- [in]
               sAxisSlave  => packetizerSlaves(i),   -- [out]
               mAxisClk    => axilClk,               -- [in]
               mAxisRst    => axilRst,               -- [in]
               mAxisMaster => ibServerMasters(i),    -- [out]
               mAxisSlave  => ibServerSlaves(i));    -- [in]

      end generate PACKETIZER_GEN;
   end generate;

   GEN_RSSI : if (RSSI_G = true) generate
      -- Place holder for future code
      obBsaSlaves     <= (others => AXI_STREAM_SLAVE_FORCE_C);
      ibBsaMasters    <= (others => AXI_STREAM_MASTER_INIT_C);
      obServerSlaves  <= (others => AXI_STREAM_SLAVE_FORCE_C);
      ibServerMasters <= (others => AXI_STREAM_MASTER_INIT_C);
   end generate;
   
end mapping;
