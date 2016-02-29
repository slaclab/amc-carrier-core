-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierSrpV1Wrapper.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-28
-- Last update: 2016-02-28
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
use work.IpV4EnginePkg.all;

entity AmcCarrierSrpV1Wrapper is
   generic (
      TPD_G      : time     := 1 ns;
      IOC_SIZE_G : positive := 1);
   port (
      axilClk           : in  sl;
      axilRst           : in  sl;
      -- UDP Interface Interface
      obServerMasters   : in  AxiStreamMasterArray(IOC_SIZE_G-1 downto 0);
      obServerSlaves    : out AxiStreamSlaveArray(IOC_SIZE_G-1 downto 0);
      ibServerMasters   : out AxiStreamMasterArray(IOC_SIZE_G-1 downto 0);
      ibServerSlaves    : in  AxiStreamSlaveArray(IOC_SIZE_G-1 downto 0);
      -- Master AXI-Lite Interface
      mAxilReadMasters  : out AxiLiteReadMasterArray(0 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(0 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(0 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(0 downto 0));
end AmcCarrierSrpV1Wrapper;

architecture mapping of AmcCarrierSrpV1Wrapper is

   signal obServerMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal obServerSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal ibServerMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal ibServerSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

begin

   U_AxiStreamMux : entity work.AxiStreamMux
      generic map (
         TPD_G        => TPD_G,
         NUM_SLAVES_G => IOC_SIZE_G)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMasters => obServerMasters,
         sAxisSlaves  => obServerSlaves,
         -- Master
         mAxisMaster  => obServerMaster,
         mAxisSlave   => obServerSlave); 

   -- Placeholder for future SRPv1 module
   mAxilReadMasters(0)  <= AXI_LITE_READ_MASTER_INIT_C;
   mAxilWriteMasters(0) <= AXI_LITE_WRITE_MASTER_INIT_C;

   U_AxiStreamDeMux : entity work.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => IOC_SIZE_G)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slaves
         sAxisMaster  => ibServerMaster,
         sAxisSlave   => ibServerSlave,
         -- Master
         mAxisMasters => ibServerMasters,
         mAxisSlaves  => ibServerSlaves);             

end mapping;
