-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierEthSrp.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2016-03-16
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

entity AmcCarrierEthSrp is
   generic (
      TPD_G            : time             := 1 ns;
      RSSI_G           : boolean          := false;
      SRP_VERSION_G    : natural          := 0;
      IOC_SIZE_G       : positive         := 4;
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
      obServerMasters   : in  AxiStreamMasterArray(IOC_SIZE_G-1 downto 0);
      obServerSlaves    : out AxiStreamSlaveArray(IOC_SIZE_G-1 downto 0);
      ibServerMasters   : out AxiStreamMasterArray(IOC_SIZE_G-1 downto 0);
      ibServerSlaves    : in  AxiStreamSlaveArray(IOC_SIZE_G-1 downto 0);
      -- Master AXI-Lite Interface
      mAxilReadMasters  : out AxiLiteReadMasterArray(0 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(0 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(0 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(0 downto 0));      
end AmcCarrierEthSrp;

architecture mapping of AmcCarrierEthSrp is

   function AxiLiteConfig return AxiLiteCrossbarMasterConfigArray is
      variable retConf : AxiLiteCrossbarMasterConfigArray(IOC_SIZE_G-1 downto 0);
      variable addr    : slv(31 downto 0);
   begin
      addr := AXI_BASE_ADDR_G;
      for i in (IOC_SIZE_G-1) downto 0 loop
         addr(14 downto 10)      := toSlv(i, 5);
         retConf(i).baseAddr     := addr;
         retConf(i).addrBits     := 10;
         retConf(i).connectivity := x"0001";
      end loop;
      return retConf;
   end function;

   signal axilWriteMasters : AxiLiteWriteMasterArray(IOC_SIZE_G-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(IOC_SIZE_G-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(IOC_SIZE_G-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(IOC_SIZE_G-1 downto 0);

   signal obMasters : AxiStreamMasterArray(IOC_SIZE_G-1 downto 0);
   signal obSlaves  : AxiStreamSlaveArray(IOC_SIZE_G-1 downto 0);
   signal ibMasters : AxiStreamMasterArray(IOC_SIZE_G-1 downto 0);
   signal ibSlaves  : AxiStreamSlaveArray(IOC_SIZE_G-1 downto 0);
   
begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => IOC_SIZE_G,
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

   GEN_SRP :
   for i in (IOC_SIZE_G-1) downto 0 generate
      
      GEN_BYPASS : if ((RSSI_G = false) or (i = 0)) generate
         
         obMasters(i)       <= obServerMasters(i);
         obServerSlaves(i)  <= obSlaves(i);
         ibServerMasters(i) <= ibMasters(i);
         ibSlaves(i)        <= ibServerSlaves(i);

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

      GEN_RSSI : if ((RSSI_G = true) and (i /= 0)) generate
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
               sAppAxisMaster_i => obMasters(i),
               sAppAxisSlave_o  => obSlaves(i),
               mAppAxisMaster_o => ibMasters(i),
               mAppAxisSlave_i  => ibSlaves(i),
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
      
   end generate GEN_SRP;

   GEN_SRPv0 : if (SRP_VERSION_G = 0) generate
      U_SRPv0 : entity work.AmcCarrierSrpV0Wrapper
         generic map (
            TPD_G      => TPD_G,
            IOC_SIZE_G => IOC_SIZE_G)
         port map (
            axilClk           => axilClk,
            axilRst           => axilRst,
            -- UDP Interface Interface
            obServerMasters   => obMasters,
            obServerSlaves    => obSlaves,
            ibServerMasters   => ibMasters,
            ibServerSlaves    => ibSlaves,
            -- Master AXI-Lite Interface
            mAxilReadMasters  => mAxilReadMasters,
            mAxilReadSlaves   => mAxilReadSlaves,
            mAxilWriteMasters => mAxilWriteMasters,
            mAxilWriteSlaves  => mAxilWriteSlaves);   
   end generate;

   GEN_SRPv1 : if (SRP_VERSION_G = 1) generate
      U_SRPv1 : entity work.AmcCarrierSrpV1Wrapper
         generic map (
            TPD_G      => TPD_G,
            IOC_SIZE_G => IOC_SIZE_G)
         port map (
            axilClk           => axilClk,
            axilRst           => axilRst,
            -- UDP Interface Interface
            obServerMasters   => obMasters,
            obServerSlaves    => obSlaves,
            ibServerMasters   => ibMasters,
            ibServerSlaves    => ibSlaves,
            -- Master AXI-Lite Interface
            mAxilReadMasters  => mAxilReadMasters,
            mAxilReadSlaves   => mAxilReadSlaves,
            mAxilWriteMasters => mAxilWriteMasters,
            mAxilWriteSlaves  => mAxilWriteSlaves);   
   end generate;
   
end mapping;
