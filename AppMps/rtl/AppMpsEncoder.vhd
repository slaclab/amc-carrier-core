-------------------------------------------------------------------------------
-- File       : AppMpsEncoder.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2016-05-26
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Note: Do not forget to configure the ATCA crate to drive the clock from the slot#2 MPS link node
-- For the 7-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
-- For the 16-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
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
use work.TimingPkg.all;

entity AppMpsEncoder is
   generic (
      TPD_G            : time             := 1 ns;
      MPS_SLOT_G       : boolean         := false;
      APP_TYPE_G       : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));      
   port (
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;   
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Configurations 
      enable          : in  sl;
      testMode        : in  sl;
      bsiBus          : in  BsiBusType;
      -- MPS Interface
      mpsMaster       : out AxiStreamMasterType;
      mpsSlave        : in  AxiStreamSlaveType);   
end AppMpsEncoder;

architecture mapping of AppMpsEncoder is

   signal timeStrb  : sl;
   signal timeStamp : slv(63 downto 0);
   signal message   : Slv32Array(31 downto 0);

begin

   ------------------------------------ 
   -- Time Stamp Synchronization Module
   ------------------------------------ 
   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 64)
      port map (
         -- Asynchronous Reset
         rst    => diagnosticRst,
         -- Write Ports (wr_clk domain)
         wr_clk => diagnosticClk,
         wr_en  => diagnosticBus.strobe,
         din    => diagnosticBus.timingMessage.timeStamp,
         -- Read Ports (rd_clk domain)
         rd_clk => axilClk,
         valid  => timeStrb,
         dout   => timeStamp);

   --------------------------------- 
   -- Message Synchronization Module
   --------------------------------- 
   GEN_VEC :
   for i in 31 downto 0 generate

      U_SyncFifo : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 32)
         port map (
            -- Asynchronous Reset
            rst    => diagnosticRst,
            -- Write Ports (wr_clk domain)
            wr_clk => diagnosticClk,
            wr_en  => diagnosticBus.strobe,
            din    => diagnosticBus.data(i),
            -- Read Ports (rd_clk domain)
            rd_clk => axilClk,
            dout   => message(i));

   end generate GEN_VEC;

   -- Placeholder for future code
   mpsMaster <= AXI_STREAM_MASTER_INIT_C;
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

end mapping;
