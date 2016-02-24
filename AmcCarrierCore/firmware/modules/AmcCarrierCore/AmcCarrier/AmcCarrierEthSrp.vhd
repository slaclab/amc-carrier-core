-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthSrp.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
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
use work.AmcCarrierPkg.all;

entity AmcCarrierEthSrp is
   generic (
      TPD_G            : time             := 1 ns;
      RSSI_G           : boolean          := false;
      TIMEOUT_G        : real             := 1.0E-3;  -- In units of seconds   
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));   
   port (
      -- Slave AXI-Lite Interface
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- Interface to UDP Server engines
      obServerMasters   : in  AxiStreamMasterArray(3 downto 0);
      obServerSlaves    : out AxiStreamSlaveArray(3 downto 0);
      ibServerMasters   : out AxiStreamMasterArray(3 downto 0);
      ibServerSlaves    : in  AxiStreamSlaveArray(3 downto 0);
      -- Master AXI-Lite Interface
      mAxilReadMasters  : out AxiLiteReadMasterArray(0 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(0 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(0 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(0 downto 0));      
end AmcCarrierEthSrp;

architecture mapping of AmcCarrierEthSrp is


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
      ---------------------
      -- AXI-Lite Interface
      ---------------------
      U_SRP : entity work.AmcCarrierSrpV0Wrapper
         generic map (
            -- Simulation Generics
            TPD_G      => TPD_G,
            IOC_SIZE_G => 4)
         port map (
            axilClk           => axilClk,
            axilRst           => axilRst,
            -- UDP Interface Interface
            obServerMasters   => obServerMasters,
            obServerSlaves    => obServerSlaves,
            ibServerMasters   => ibServerMasters,
            ibServerSlaves    => ibServerSlaves,
            -- Master AXI-Lite Interface
            mAxilReadMasters  => mAxilReadMasters,
            mAxilReadSlaves   => mAxilReadSlaves,
            mAxilWriteMasters => mAxilWriteMasters,
            mAxilWriteSlaves  => mAxilWriteSlaves);
   end generate;

   GEN_RSSI : if (RSSI_G = true) generate
      -- Place holder for future code
      obServerSlaves    <= (others => AXI_STREAM_SLAVE_FORCE_C);
      ibServerMasters   <= (others => AXI_STREAM_MASTER_INIT_C);
      mAxilReadMasters  <= (others => AXI_LITE_READ_MASTER_INIT_C);
      mAxilWriteMasters <= (others => AXI_LITE_WRITE_MASTER_INIT_C);
   end generate;
   
end mapping;
