-------------------------------------------------------------------------------
-- Title      : Signal Generator for LVDS DAC
-------------------------------------------------------------------------------
-- File       : LvdsDacSigGen.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Signal generator top module.
--     Arbitrary signal generator
--     Module has its own AxiLite register interface and access to AXI lite and 
--     AXIlite RAM module for signal definition,
--     Adjustable period s_periodSize,
--     Polarity can be bitwise reversed s_polarityMask. 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 LLRF Development'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 LLRF Development', including this file, 
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
      TPD_G : time := 1 ns;
      --
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C;
      ADDR_WIDTH_G : integer range 1 to (2**24) := 12;
      DATA_WIDTH_G : integer range 1 to 32      := 16
   );
   port (
     
      -- Register itf Clocks and Resets
      axiClk         : in  sl;
      axiRst         : in  sl;
     
      -- devClk 2x - DAC sampling rate
      devClk2x_i     : in  sl;
      devRst2x_i     : in  sl;
      
      -- devClk - DAC sampling rate/2 (External data rate)
      devClk_i   : in  sl;
      devRst_i   : in  sl;
      
      -- External sample data input 
      -- 2 samples per c-c
      -- Should be little-endian none byte-swapped
      extData_i  : in  slv((2*DATA_WIDTH_G)-1 downto 0);
       
      -- AXI-Lite Register Interface
      axilReadMaster  : in   AxiLiteReadMasterType;
      axilReadSlave   : out  AxiLiteReadSlaveType;
      axilWriteMaster : in   AxiLiteWriteMasterType;
      axilWriteSlave  : out  AxiLiteWriteSlaveType;
      
      -- LVDS out delay control
      load_o         : out slv(DATA_WIDTH_G-1 downto 0);
      tapDelaySet_o  : out Slv9Array(DATA_WIDTH_G-1 downto 0);   
      tapDelayStat_i : in  Slv9Array(DATA_WIDTH_G-1 downto 0);      
      
      -- Sample data output 
      sampleData_o   : out Slv(DATA_WIDTH_G-1 downto 0)
   );
end LvdsDacSigGen;

architecture rtl of LvdsDacSigGen is
 
 -- Internal signals

   -- Generator signals 
   signal s_laneEn       : sl;
   signal s_underflow    : sl;
   signal s_overflow     : sl;   
   signal s_periodSize   : slv(ADDR_WIDTH_G-1 downto 0);
   signal s_polarityMask : slv(DATA_WIDTH_G-1 downto 0);
   signal s_sampleData   : slv(DATA_WIDTH_G-1 downto 0);   
   -------------------------------------------------------------------------------------------------
   -- AXI Lite Config and Signals
   -------------------------------------------------------------------------------------------------
   
   constant NUM_AXI_MASTERS_C : natural := 2;
   
   constant DAC_AXIL_INDEX_C       : natural   := 0;
   constant LANE_INDEX_C           : natural   := 1;

   constant DAC_ADDR_C   : slv(31 downto 0)   := X"0000_0000"+ AXI_BASE_ADDR_G; -- Signal generator register address
   constant LANE_ADDR_C  : slv(31 downto 0)   := X"0001_0000"+ AXI_BASE_ADDR_G; -- Signal generator RAM address

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DAC_AXIL_INDEX_C => (
         baseAddr          => DAC_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C    => (
         baseAddr          => LANE_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"));
         
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
--
begin
 
   -----------------------------------------------------------
   -- AXI lite
   ----------------------------------------------------------- 

   -- DAC Axi Crossbar
   DACAxiCrossbar : entity work.AxiLiteCrossbar
   generic map (
      TPD_G              => TPD_G,
      NUM_SLAVE_SLOTS_G  => 1,
      NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
      MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
   port map (
      axiClk              => axiClk,
      axiClkRst           => axiRst,
      sAxiWriteMasters(0) => axilWriteMaster,
      sAxiWriteSlaves(0)  => axilWriteSlave,
      sAxiReadMasters(0)  => axilReadMaster,
      sAxiReadSlaves(0)   => axilReadSlave,   
      mAxiWriteMasters    => locAxilWriteMasters,
      mAxiWriteSlaves     => locAxilWriteSlaves,
      mAxiReadMasters     => locAxilReadMasters,
      mAxiReadSlaves      => locAxilReadSlaves);

   -- DAQ control register interface
   AxiLiteGenRegItf_INST: entity work.LvdsDacRegItf
   generic map (
      TPD_G            => TPD_G,
      AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
      ADDR_WIDTH_G     => ADDR_WIDTH_G,
      DATA_WIDTH_G     => DATA_WIDTH_G
   )
   port map (
      axiClk_i        => axiClk,
      axiRst_i        => axiRst,   
      devClk_i        => devClk2x_i,
      devRst_i        => devRst2x_i,
      axilReadMaster  => locAxilReadMasters(DAC_AXIL_INDEX_C),
      axilReadSlave   => locAxilReadSlaves(DAC_AXIL_INDEX_C),
      axilWriteMaster => locAxilWriteMasters(DAC_AXIL_INDEX_C),
      axilWriteSlave  => locAxilWriteSlaves(DAC_AXIL_INDEX_C),
      enable_o        => s_laneEn,
      periodSize_o    => s_periodSize,
      polarityMask_o  => s_polarityMask,
      load_o          => load_o,      
      tapDelaySet_o   => tapDelaySet_o, 
      tapDelayStat_i  => tapDelayStat_i,
      overflow_i      => s_overflow,
      underflow_i     => s_underflow);

   -----------------------------------------------------------
   -- Signal generator lanes
   ----------------------------------------------------------- 
   SigGenLane_INST: entity work.LvdsDacLane
   generic map (
      TPD_G        => TPD_G,
      ADDR_WIDTH_G => ADDR_WIDTH_G,
      DATA_WIDTH_G => DATA_WIDTH_G)
   port map (
      enable_i        => s_laneEn,
      devClk2x_i      => devClk2x_i,
      devRst2x_i      => devRst2x_i,
      devClk_i        => devClk_i,
      devRst_i        => devRst_i,      
      extData_i       => extData_i,
      overflow_o      => s_overflow,
      underflow_o     => s_underflow,

      axiClk_i        => axiClk,
      axiRst_i        => axiRst,            
      axilReadMaster  => locAxilReadMasters(LANE_INDEX_C), 
      axilReadSlave   => locAxilReadSlaves(LANE_INDEX_C),  
      axilWriteMaster => locAxilWriteMasters(LANE_INDEX_C),
      axilWriteSlave  => locAxilWriteSlaves(LANE_INDEX_C), 
      periodSize_i    => s_periodSize,
      sampleData_o    => s_sampleData
      );
   -----------------------------------------------------
   -- Reverse polarity on masked bits
   sampleData_o <= s_sampleData xor s_polarityMask;
   -----------------------------------------------------
end rtl;
