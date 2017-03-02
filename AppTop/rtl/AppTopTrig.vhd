-------------------------------------------------------------------------------
-- File       : AppTopTrig.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2017-03-01
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BAM Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 BAM Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.AppTopPkg.all;

entity AppTopTrig is
   generic (
      TPD_G              : time                   := 1 ns;
      AXIL_BASE_ADDR_G   : slv(31 downto 0)       := (others => '0');
      AXI_ERROR_RESP_G   : slv(1 downto 0)        := AXI_RESP_SLVERR_C;
      TRIG_SIZE_G        : positive range 1 to 16 := 3;
      TRIG_DELAY_WIDTH_G : positive range 1 to 32 := 32;
      TRIG_PULSE_WIDTH_G : positive range 1 to 32 := 32);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Application Debug Interface (axilClk domain)
      sAxisMaster     : in  AxiStreamMasterType;
      sAxisSlave      : out AxiStreamSlaveType;
      mAxisMaster     : out AxiStreamMasterType;
      mAxisSlave      : in  AxiStreamSlaveType;
      -- Timing Interface
      recClk          : in  sl;
      recRst          : in  sl;
      timingBus_i     : in  TimingBusType;
      -- Trigger pulse outputs 
      evrTrig         : out AppTopTrigType);
end AppTopTrig;

architecture mapping of AppTopTrig is

   constant APP_STREAM_ROUTES_C : Slv8Array(1 downto 0) := (
      0 => "--------",  -- AppCore Message: TDEST = ANY
      1 => "1111----"); -- Timing  Message: TDEST = [0xFF:0xF0]

   signal timeMsgMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal timeMsgSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

begin

   TERM_UNUSED : if (TRIG_SIZE_G /= 16) generate
      evrTrig.trigPulse(15 downto TRIG_SIZE_G) <= (others => '0');
   end generate;

   -------------------------------
   -- LCLS-I Timing/Trigger Module
   -------------------------------
   U_Timing : entity work.LclsMrTimingCore
      generic map (
         TPD_G                => TPD_G,
         AXIL_BASE_ADDR_G     => AXIL_BASE_ADDR_G,
         AXI_ERROR_RESP_G     => AXI_ERROR_RESP_G,
         NUM_OF_TRIG_PULSES_G => TRIG_SIZE_G,
         DELAY_WIDTH_G        => TRIG_DELAY_WIDTH_G,
         PULSE_WIDTH_G        => TRIG_PULSE_WIDTH_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- Timing Interface
         recClk          => recClk,
         recRst          => recRst,
         timingBus_i     => timingBus_i,
         -- Trigger pulse outputs 
         trigPulse_o     => evrTrig.trigPulse(TRIG_SIZE_G-1 downto 0),
         timeStamp_o     => evrTrig.timeStamp,
         pulseId_o       => evrTrig.pulseId,
         bsa_o           => evrTrig.bsa,
         dmod_o          => evrTrig.dmod);

   U_AxiStreamMux : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => 2,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => APP_STREAM_ROUTES_C,
         PIPE_STAGES_G  => 1)
      port map (
         -- Clock and reset
         axisClk         => axilClk,
         axisRst         => axilRst,
         -- Slaves
         sAxisMasters(0) => sAxisMaster,
         sAxisMasters(1) => timeMsgMaster,
         sAxisSlaves(0)  => sAxisSlave,
         sAxisSlaves(1)  => timeMsgSlave,
         -- Master
         mAxisMaster     => mAxisMaster,
         mAxisSlave      => mAxisSlave);

end mapping;
