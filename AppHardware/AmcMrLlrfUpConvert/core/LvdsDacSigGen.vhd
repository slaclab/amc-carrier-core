-------------------------------------------------------------------------------
-- File       : LvdsDacSigGen.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2017-04-19
-------------------------------------------------------------------------------
-- Description: Signal generator top module.
--     Arbitrary signal generator
--     Module has its own AxiLite register interface and access to AXI lite and 
--     AXIlite RAM module for signal definition,
--     Adjustable period s_periodSize,
--     Polarity can be bitwise reversed s_polarityMask. 
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

entity LvdsDacSigGen is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C;
      ADDR_WIDTH_G     : positive         := 10);
   port (
      -- devClk2x Reference
      devClk2x_i      : in  sl;
      devRst2x_i      : in  sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DAC Interface (devClk_i domain)
      -- Note: 2x 16-bit samples per 32-bit word
      --       32-bit is little-endian & none byte-swapped
      devClk_i        : in  sl;
      devRst_i        : in  sl;
      extData_i       : in  slv(31 downto 0);
      -- Delay control (devClk_i domain)
      load_o          : out slv(15 downto 0);
      tapDelaySet_o   : out Slv9Array(15 downto 0);
      tapDelayStat_i  : in  Slv9Array(15 downto 0);
      -- Sample data output 
      sampleData_o    : out Slv2Array(15 downto 0));
end LvdsDacSigGen;

architecture mapping of LvdsDacSigGen is

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant DAC_AXIL_INDEX_C : natural := 0;
   constant LANE_INDEX_C     : natural := 1;

   constant DAC_ADDR_C  : slv(31 downto 0) := (x"0000_0000"+ AXI_BASE_ADDR_G);  -- Signal generator register address
   constant LANE_ADDR_C : slv(31 downto 0) := (x"0001_0000"+ AXI_BASE_ADDR_G);  -- Signal generator RAM address

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DAC_AXIL_INDEX_C => (
         baseAddr      => DAC_ADDR_C,
         addrBits      => 12,
         connectivity  => X"0001"),
      LANE_INDEX_C     => (
         baseAddr      => LANE_ADDR_C,
         addrBits      => 12,
         connectivity  => X"0001"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal s_laneEn       : sl;
   signal s_periodSize   : slv(ADDR_WIDTH_G-1 downto 0);
   signal s_polarityMask : slv(15 downto 0);
   signal s_sampleData   : Slv2Array(15 downto 0);

begin

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   ---------------------------------
   -- DAQ control register interface
   ---------------------------------
   U_REG : entity work.LvdsDacRegItf
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         ADDR_WIDTH_G     => ADDR_WIDTH_G)
      port map (
         -- devClk2x Reference (devClk2x_i domain)
         devClk2x_i      => devClk2x_i,
         devRst2x_i      => devRst2x_i,
         periodSize_o    => s_periodSize,
         -- AXI-Lite Interface (axilClk_i domain)
         axilClk_i       => axilClk,
         axilRst_i       => axilRst,
         axilReadMaster  => locAxilReadMasters(DAC_AXIL_INDEX_C),
         axilReadSlave   => locAxilReadSlaves(DAC_AXIL_INDEX_C),
         axilWriteMaster => locAxilWriteMasters(DAC_AXIL_INDEX_C),
         axilWriteSlave  => locAxilWriteSlaves(DAC_AXIL_INDEX_C),
         -- Control generation  (devClk_i domain)  
         devClk_i        => devClk_i,
         devRst_i        => devRst_i,
         enable_o        => s_laneEn,
         polarityMask_o  => s_polarityMask,
         -- Delay control (devClk_i domain)
         load_o          => load_o,
         tapDelaySet_o   => tapDelaySet_o,
         tapDelayStat_i  => tapDelayStat_i);

   -------------------------
   -- Signal generator lanes
   -------------------------
   U_LANE : entity work.LvdsDacLane
      generic map (
         TPD_G        => TPD_G,
         ADDR_WIDTH_G => ADDR_WIDTH_G)
      port map (
         -- devClk2x Reference
         devClk2x_i      => devClk2x_i,
         devRst2x_i      => devRst2x_i,
         -- AXI-Lite Interface (axilClk_i domain)
         axilClk_i       => axilClk,
         axilRst_i       => axilRst,
         axilReadMaster  => locAxilReadMasters(LANE_INDEX_C),
         axilReadSlave   => locAxilReadSlaves(LANE_INDEX_C),
         axilWriteMaster => locAxilWriteMasters(LANE_INDEX_C),
         axilWriteSlave  => locAxilWriteSlaves(LANE_INDEX_C),
         -- DAC Interface (devClk_i domain)
         -- Note: 2x 16-bit samples per 32-bit word
         --       32-bit is little-endian & none byte-swapped
         devClk_i        => devClk_i,
         devRst_i        => devRst_i,
         extData_i       => extData_i,
         -- Control generation  (devClk_i domain)      
         enable_i        => s_laneEn,
         periodSize_i    => s_periodSize,
         -- Parallel data out  (devClk_i domain)
         sampleData_o    => s_sampleData);

   ------------------------------
   -- Fixed polarity via bit mask
   ------------------------------
   GEN_VEC :
   for i in 15 downto 0 generate
      sampleData_o(i)(0) <= s_sampleData(i)(0) xor s_polarityMask(i);
      sampleData_o(i)(1) <= s_sampleData(i)(1) xor s_polarityMask(i);
   end generate GEN_VEC;

end mapping;
