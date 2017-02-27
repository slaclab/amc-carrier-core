-------------------------------------------------------------------------------
-- File       : RtmRfInterlockCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-17
-- Last update: 2017-02-27
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_19_CXX
------------------------------------------------------------------------------
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmRfInterlockCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      -- Recovered EVR clock
      recClk          : in  sl;
      recRst          : in  sl;
      -- Timing triggers
      dataTrig        : in  sl;
      -- AXI-Lite
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- High speed ADC status data (data rate is 6x recClk DDR)
      hsAdcBeamIP     : in  sl;
      hsAdcBeamIN     : in  sl;
      hsAdcBeamVP     : in  sl;
      hsAdcBeamVN     : in  sl;
      hsAdcFwdPwrP    : in  sl;
      hsAdcFwdPwrN    : in  sl;
      hsAdcReflPwrP   : in  sl;
      hsAdcReflPwrN   : in  sl;
      hsAdcFrameClkP  : in  sl;
      hsAdcFrameClkN  : in  sl;
      hsAdcDataClkP   : in  sl;
      hsAdcDataClkN   : in  sl;
      hsAdcClkP       : out sl;
      hsAdcClkN       : out sl;
      hsAdcTest       : out sl;
      -- Thresholds SPI
      klyThrCs        : out sl;
      modThrCs        : out sl;
      potSck          : out sl;
      potSdi          : out sl;
      -- Low Speed ADC SPI
      adcCnv          : out sl;
      adcSck          : out sl;
      adcSdi          : out sl;
      adcSdo          : in  sl;
      -- CPLD SPI
      cpldCsb         : out sl;
      cpldSck         : out sl;
      cpldSdi         : out sl;
      cpldSdo         : in  sl;
      -- SLED and MODE
      detuneSled      : out sl;
      tuneSled        : out sl;
      mode            : out sl;
      bypassMode      : out sl;
      rfOff           : in  sl;
      fault           : in  sl;
      faultClear      : out sl);
end RtmRfInterlockCore;

architecture mapping of RtmRfInterlockCore is

   constant BUFFER_WIDTH_C : natural := 32;

   constant BUFFER_ADDR_SIZE_C : natural := 9;  -- 512 samples after trigger 
   constant NUM_AXI_MASTERS_C  : natural := 7;

   constant CPLD_INDEX_C    : natural := 0;
   constant THR_KLY_INDEX_C : natural := 1;
   constant THR_MOD_INDEX_C : natural := 2;
   constant THR_ADC_INDEX_C : natural := 3;
   constant RTM_REG_INDEX_C : natural := 4;
   constant BUF0_INDEX_C    : natural := 5;
   constant BUF1_INDEX_C    : natural := 6;

   constant CPLD_ADDRESS_C      : slv(31 downto 0) := x"0000_0000" + AXIL_BASE_ADDR_G;
   constant THR_KLY_BASE_ADDR_C : slv(31 downto 0) := x"0000_0400" + AXIL_BASE_ADDR_G;
   constant THR_MOD_BASE_ADDR_C : slv(31 downto 0) := x"0000_0800" + AXIL_BASE_ADDR_G;
   constant THR_ADC_BASE_ADDR_C : slv(31 downto 0) := x"0000_0C00" + AXIL_BASE_ADDR_G;
   constant RTM_REG_BASE_ADDR_C : slv(31 downto 0) := x"0000_1000" + AXIL_BASE_ADDR_G;
   constant BUF0_BASE_ADDR_C    : slv(31 downto 0) := x"0000_2000" + AXIL_BASE_ADDR_G;
   constant BUF1_BASE_ADDR_C    : slv(31 downto 0) := x"0000_3000" + AXIL_BASE_ADDR_G;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      CPLD_INDEX_C    => (
         baseAddr     => CPLD_ADDRESS_C,
         addrBits     => 10,
         connectivity => x"FFFF"),
      THR_KLY_INDEX_C => (
         baseAddr     => THR_KLY_BASE_ADDR_C,
         addrBits     => 10,
         connectivity => x"FFFF"),
      THR_MOD_INDEX_C => (
         baseAddr     => THR_MOD_BASE_ADDR_C,
         addrBits     => 10,
         connectivity => x"FFFF"),
      THR_ADC_INDEX_C => (
         baseAddr     => THR_ADC_BASE_ADDR_C,
         addrBits     => 10,
         connectivity => x"FFFF"),
      RTM_REG_INDEX_C => (
         baseAddr     => RTM_REG_BASE_ADDR_C,
         addrBits     => 10,
         connectivity => x"FFFF"),
      BUF0_INDEX_C    => (
         baseAddr     => BUF0_BASE_ADDR_C,
         addrBits     => 12,
         connectivity => x"FFFF"),
      BUF1_INDEX_C    => (
         baseAddr     => BUF1_BASE_ADDR_C,
         addrBits     => 12,
         connectivity => x"FFFF"));

   signal writeMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal writeSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   -- Fast ADC data
   signal s_recClkDiv2     : sl;
   signal s_recRstDiv2     : sl;
   signal s_hsAdcdataAsync : slv(47 downto 0);
   signal s_hsAdcdataSync  : slv(47 downto 0);
   signal s_hsAdcValid     : sl;
   signal s_ringClr        : sl;
   signal s_ringWrEn       : sl;
   signal s_bufferData     : Slv32Array(1 downto 0);

   -- SW Register access signals
   signal s_faultClearExt : sl;         -- Extended Rising edge pulse
   signal s_softClear     : sl;
   signal s_softTrig      : sl;
   signal s_hsAdcLocked   : sl;
   signal s_curDelay      : Slv9Array(4 downto 0);
   signal s_setDelay      : Slv9Array(4 downto 0);
   signal s_setValid      : sl;

   -- Threshold SET
   signal s_sclkVec : slv(1 downto 0);
   signal s_doutVec : slv(1 downto 0);
   signal s_csbVec  : slv(1 downto 0);
   signal s_muxSClk : sl;


begin

   hsAdcTest <= '0';

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => writeMasters,
         mAxiWriteSlaves     => writeSlaves,
         mAxiReadMasters     => readMasters,
         mAxiReadSlaves      => readSlaves);

   -----------
   -- Fast ADC
   -----------
   -- Divide the recovered timing clock by 2
   U_ClockManager : entity work.ClockManagerUltraScale
      generic map (
         TPD_G              => 1 ns,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 1,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 8.403,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 5.375,
         CLKOUT0_DIVIDE_F_G => 10.750,
         CLKOUT0_PHASE_G    => 0.0,
         CLKOUT0_RST_HOLD_G => 32)
      port map (
         clkIn     => recClk,
         rstIn     => recRst,
         clkOut(0) => s_recClkDiv2,     -- 59.5 MHz
         rstOut(0) => s_recRstDiv2);

   -- Get the data from the ADC
   U_Ad9229Core : entity work.Ad9229Core
      generic map (
         TPD_G           => TPD_G,
         IODELAY_GROUP_G => "RTM_IDELAY_GRP",
         N_CHANNELS_G    => 4)
      port map (
         sampleClk       => s_recClkDiv2,
         sampleRst       => s_recRstDiv2,
         fadcClkP_o      => hsAdcClkP,
         fadcClkN_o      => hsAdcClkN,
         fadcFrameClkP_i => hsAdcFrameClkP,
         fadcFrameClkN_i => hsAdcFrameClkN,
         fadcDataClkP_i  => hsAdcDataClkP,
         fadcDataClkN_i  => hsAdcDataClkN,
         serDataP_i(0)   => hsAdcBeamVP,
         serDataP_i(1)   => hsAdcBeamIP,
         serDataP_i(2)   => hsAdcFwdPwrP,
         serDataP_i(3)   => hsAdcReflPwrP,
         serDataN_i(0)   => hsAdcBeamVN,
         serDataN_i(1)   => hsAdcBeamIN,
         serDataN_i(2)   => hsAdcFwdPwrN,
         serDataN_i(3)   => hsAdcReflPwrN,
         parData_o(0)    => s_hsAdcdataAsync(11 downto 0),
         parData_o(1)    => s_hsAdcdataAsync(23 downto 12),
         parData_o(2)    => s_hsAdcdataAsync(35 downto 24),
         parData_o(3)    => s_hsAdcdataAsync(47 downto 36),
         locked_o        => s_hsAdcLocked,
         curDelay_o      => s_curDelay,
         setDelay_i      => s_setDelay,
         setValid_i      => s_setValid);

   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 48)
      port map (
         wr_clk => s_recClkDiv2,
         din    => s_hsAdcdataAsync,
         rd_clk => recClk,
         valid  => s_hsAdcValid,
         dout   => s_hsAdcdataSync);

   ---------------------
   -- CPLD SPI interface
   ---------------------
   U_cpldSpi : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         ADDRESS_SIZE_G    => 7,
         DATA_SIZE_G       => 16,
         CLK_PERIOD_G      => 6.4E-9,
         SPI_SCLK_PERIOD_G => 3.0E-6)   -- 1 MHz
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => readMasters(CPLD_INDEX_C),
         axiReadSlave   => readSlaves(CPLD_INDEX_C),
         axiWriteMaster => writeMasters(CPLD_INDEX_C),
         axiWriteSlave  => writeSlaves(CPLD_INDEX_C),
         coreSclk       => cpldSck,
         coreSDin       => cpldSdo,
         coreSDout      => cpldSdi,
         coreCsb        => cpldCsb);

   ----------------------------------------------------------------
   -- Set Threshold SPI interfaces (TPL0202)
   -- 8 bit Address (bit 7 is command 0-write, 1-read)
   -- 8 bit data
   ----------------------------------------------------------------         
   GEN_THR_SPI_CHIPS : for i in 1 downto 0 generate
      U_thrSpi : entity work.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
            WO_SPI_G          => true,
            ADDRESS_SIZE_G    => 7,
            DATA_SIZE_G       => 8,
            CLK_PERIOD_G      => 6.4E-9,
            SPI_SCLK_PERIOD_G => 3.0E-6)  -- 1 MHz
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => readMasters(THR_KLY_INDEX_C+i),
            axiReadSlave   => readSlaves(THR_KLY_INDEX_C+i),
            axiWriteMaster => writeMasters(THR_KLY_INDEX_C+i),
            axiWriteSlave  => writeSlaves(THR_KLY_INDEX_C+i),
            coreSclk       => s_sclkVec(i),
            coreSDin       => '0',
            coreSDout      => s_doutVec(i),
            coreCsb        => s_csbVec(i));
   end generate GEN_THR_SPI_CHIPS;

   -- Output mux
   with s_csbVec select
      potSck <= s_sclkVec(0) when "10",
      s_sclkVec(1)           when "01",
      '0'                    when others;

   with s_csbVec select
      potSdi <= s_doutVec(0) when "10",
      s_doutVec(1)           when "01",
      '0'                    when others;

   klyThrCs <= s_csbVec(0);
   modThrCs <= s_csbVec(1);

   ---------------------------------------
   -- Get Threshold SPI interface (AD7682)
   ---------------------------------------
   U_AdcSpi : entity work.AxiSpiAd7682
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         DATA_SIZE_G       => 16,
         CLK_PERIOD_G      => 6.4E-9,
         SPI_SCLK_PERIOD_G => 1.0E-6,
         N_INPUTS_G        => 4,        -- 4-AD7682, 8-AD7689
         N_SPI_CYCLES_G    => 32)  -- Number of SPI clock cycles between two acquisitions      
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => readMasters(THR_ADC_INDEX_C),
         axiReadSlave   => readSlaves(THR_ADC_INDEX_C),
         axiWriteMaster => writeMasters(THR_ADC_INDEX_C),
         axiWriteSlave  => writeSlaves(THR_ADC_INDEX_C),
         coreSclk       => adcSck,
         coreSDin       => adcSdo,
         coreSDout      => adcSdi,
         coreCnv        => adcCnv);

   ----------------
   -- RTM registers
   ----------------
   U_RtmLlrfMpsReg : entity work.RtmRfInterlockReg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk_i        => axilClk,
         axiRst_i        => axilRst,
         axilReadMaster  => readMasters(RTM_REG_INDEX_C),
         axilReadSlave   => readSlaves(RTM_REG_INDEX_C),
         axilWriteMaster => writeMasters(RTM_REG_INDEX_C),
         axilWriteSlave  => writeSlaves(RTM_REG_INDEX_C),
         devClk_i        => recClk,
         devRst_i        => recRst,
         mode_o          => s_mode,
         bypassMode_o    => bypassMode,
         tuneSled_o      => tuneSled,
         detuneSled_o    => detuneSled,
         -- Ring buffer control
         softTrig_o      => s_softTrig,
         softClear_o     => s_softClear,
         -- Fault status
         fault_i         => fault,
         rfOff_i         => RfOff,
         faultClear_o    => faultClear,
         adcLock_i       => s_hsAdcLocked,
         curDelay_i      => s_curDelay,
         setDelay_o      => s_setDelay,
         loadDelay_o     => s_setValid);

   ----------------------------------------------------------------
   -- ADC data Ring buffers for:
   -- Save the 128 samples after dataTrig trigger
   --   - Beam_V_Data   
   --   - Beam_I_Data   
   --   - FWD_PWR_Data  
   --   - REFL_PWR_Data 
   ----------------------------------------------------------------          
   U_AmcGenericAdcDacSyncTrig : entity work.AmcGenericAdcDacSyncTrig
      generic map (
         TPD_G                    => TPD_G,
         RING_BUFFER_ADDR_WIDTH_G => BUFFER_ADDR_SIZE_C)
      port map (
         clk         => recClk,
         rst         => recRst,
         valid       => s_hsAdcValid,
         softTrig    => s_softTrig,
         softClear   => s_softClear,
         debugTrig   => dataTrig,
         debugLogEn  => s_ringWrEn,
         debugLogClr => s_ringClr);

   -- Beam_I_Data & Beam_V_Data 
   s_bufferData(0) <= x"0" & s_hsAdcdataSync(23 downto 12) & x"0" & s_hsAdcdataSync(11 downto 0);
   -- FWD_PWR_Data & REFL_PWR_Data
   s_bufferData(1) <= x"0" & s_hsAdcdataSync(47 downto 36) & x"0" & s_hsAdcdataSync(35 downto 24);

   GEN_RING_BUF : for i in 1 downto 0 generate
      U_AxiLiteRingBuffer : entity work.AxiLiteRingBuffer
         generic map (
            TPD_G            => TPD_G,
            DATA_WIDTH_G     => BUFFER_WIDTH_C,
            RAM_ADDR_WIDTH_G => BUFFER_ADDR_SIZE_C,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            dataClk         => recClk,
            dataRst         => recRst,
            dataValid       => '1',     -- s_hsAdcLocked
            dataValue       => s_bufferData(i),
            bufferEnable    => s_ringWrEn,
            bufferClear     => s_ringClr,
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => readMasters(BUF0_INDEX_C+i),
            axilReadSlave   => readSlaves(BUF0_INDEX_C+i),
            axilWriteMaster => writeMasters(BUF0_INDEX_C+i),
            axilWriteSlave  => writeSlaves(BUF0_INDEX_C+i));
   end generate GEN_RING_BUF;

end architecture mapping;
