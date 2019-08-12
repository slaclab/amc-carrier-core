-------------------------------------------------------------------------------
-- File       : AmcCarrierRssiObFifo.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Adds a "store + forwarding" FIFO and throttling of the RSSI TSP outbound interface
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
use work.EthMacPkg.all;

entity AmcCarrierRssiObFifo is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- RSSI Interface
      obRssiTspMaster : in  AxiStreamMasterType;
      obRssiTspSlave  : out AxiStreamSlaveType;
      -- Interface to UDP Server engine
      ibServerMaster  : out AxiStreamMasterType;
      ibServerSlave   : in  AxiStreamSlaveType);
end AmcCarrierRssiObFifo;

architecture mapping of AmcCarrierRssiObFifo is

   constant AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => EMAC_AXIS_CONFIG_C.TSTRB_EN_C,
      TDATA_BYTES_C => 2,  -- 2Bytes x 156.25 MHz x 8b/B = 2.5 Gb/s throttle 
      TDEST_BITS_C  => EMAC_AXIS_CONFIG_C.TDEST_BITS_C,
      TID_BITS_C    => EMAC_AXIS_CONFIG_C.TID_BITS_C,
      TKEEP_MODE_C  => EMAC_AXIS_CONFIG_C.TKEEP_MODE_C,
      TUSER_BITS_C  => EMAC_AXIS_CONFIG_C.TUSER_BITS_C,
      TUSER_MODE_C  => EMAC_AXIS_CONFIG_C.TUSER_MODE_C);

   signal chokeMaster : AxiStreamMasterType;
   signal chokeSlave  : AxiStreamSlaveType;

begin

   U_Choke : entity work.AxiStreamResize
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         READY_EN_G          => true,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => EMAC_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_C)
      port map (
         -- Clock and reset
         axisClk     => axilClk,
         axisRst     => axilRst,
         -- Slave Port
         sAxisMaster => obRssiTspMaster,
         sAxisSlave  => obRssiTspSlave,
         -- Master Port
         mAxisMaster => chokeMaster,
         mAxisSlave  => chokeSlave);

   U_Burst_Fifo : entity work.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 0,      -- 0 = "store and forward"
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => true,
         INT_WIDTH_SELECT_G  => "CUSTOM",  -- Force internal width
         INT_DATA_WIDTH_G    => 16,     -- 128-bit         
         FIFO_ADDR_WIDTH_G   => 10,  -- 16kB/FIFO = 128-bits x 1024 entries         
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => chokeMaster,
         sAxisSlave  => chokeSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => ibServerMaster,
         mAxisSlave  => ibServerSlave);

end mapping;
