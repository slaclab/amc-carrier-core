-------------------------------------------------------------------------------
-- File       : AmcStriplineBpmCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-28
-- Last update: 2017-02-23
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_03_CXX
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.jesd204bpkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcStriplineBpmCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_CLK_FREQ_G   : real             := 156.25E+6;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
   port (
      -- Analog Control Ports 
      attn1A          : in    slv(4 downto 0);
      attn1B          : in    slv(4 downto 0);
      attn2A          : in    slv(4 downto 0);
      attn2B          : in    slv(4 downto 0);
      attn3A          : in    slv(4 downto 0);
      attn3B          : in    slv(4 downto 0);
      attn4A          : in    slv(4 downto 0);
      attn4B          : in    slv(4 downto 0);
      attn5A          : in    slv(4 downto 0);
      -- Calibration Ports
      clSw            : in    slv(5 downto 0);
      clClkOe         : in    sl;
      rfAmpOn         : in    sl;
      lemoTrig        : out   sl;
      -- ADC/DAC Interface
      adcValids       : in    slv(3 downto 0);
      adcValues       : in    sampleDataArray(3 downto 0);
      dacVcoCtrl      : in    slv(15 downto 0);
      -- JESD SYNC Interface
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      jesdSysRef      : out   sl;
      jesdRxSync      : in    sl;
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------
      -- AMC's JTAG Ports
      jtagPri         : inout slv(4 downto 0);
      jtagSec         : inout slv(4 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP        : inout slv(1 downto 0);
      fpgaClkN        : inout slv(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP         : inout slv(3 downto 0);
      sysRefN         : inout slv(3 downto 0);
      -- AMC's Sync Ports
      syncInP         : inout slv(3 downto 0);
      syncInN         : inout slv(3 downto 0);
      syncOutP        : inout slv(9 downto 0);
      syncOutN        : inout slv(9 downto 0);
      -- AMC's Spare Ports
      spareP          : inout slv(15 downto 0);
      spareN          : inout slv(15 downto 0)
      );
end AmcStriplineBpmCore;

architecture mapping of AmcStriplineBpmCore is

   constant NUM_AXI_MASTERS_C : natural := 5;

   constant CTRL_INDEX_C  : natural := 0;
   constant DAC_INDEX_C   : natural := 1;
   constant LMK_INDEX_C   : natural := 2;
   constant ADC_A_INDEX_C : natural := 3;
   constant ADC_B_INDEX_C : natural := 4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      CTRL_INDEX_C    => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_0000"),
         addrBits     => 12,
         connectivity => X"0001"),
      DAC_INDEX_C     => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_2000"),
         addrBits     => 12,
         connectivity => X"0001"),
      LMK_INDEX_C     => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0002_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      ADC_A_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0004_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      ADC_B_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0006_0000"),
         addrBits     => 17,
         connectivity => X"0001"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal lmkClkSel : slv(1 downto 0);
   signal lmkSck    : sl;
   signal lmkDio    : sl;
   signal lmkSync   : sl;
   signal lmkCsL    : sl;
   signal lmkRst    : sl;

   signal adcCsL  : slv(1 downto 0);
   signal adcSck  : sl;
   signal adcMiso : sl;
   signal adcMosi : sl;

   signal dacCsL  : sl;
   signal dacSck  : sl;
   signal dacMosi : sl;

   signal lmkDin        : sl;
   signal lmkDeglitched : sl;
   signal lmkCnt        : slv(3 downto 0);
   signal lmkDout       : sl;

   signal coreSclk  : slv(1 downto 0);
   signal coreSDout : slv(1 downto 0);
   signal coreCsb   : slv(1 downto 0);

   signal dacSckVec       : slv(1 downto 0);
   signal dacMosiVec      : slv(1 downto 0);
   signal dacCsLVec       : slv(1 downto 0);
   signal dacVcoEnable    : sl;
   signal dacVcoSckConfig : slv(15 downto 0);
   
   signal lemoTrigger : sl;

begin

   -- LMK Ports
   spareN(5)  <= lmkClkSel(0);
   spareP(5)  <= lmkClkSel(1);
   spareN(10) <= lmkSck;
   spareP(15) <= lmkDio;
   spareN(15) <= lmkSync;
   spareP(10) <= lmkCsL;
   spareP(14) <= lmkRst;
   -- Fast ADC's SPI Ports
   jtagPri(4) <= adcCsL(0);
   spareP(3)  <= adcCsL(1);
   jtagPri(1) <= adcSck;
   adcMiso    <= jtagPri(3);
   jtagPri(2) <= adcMosi;
   -- Slow DAC's SPI Ports
   spareP(12) <= dacCsL;
   spareN(13) <= dacSck;
   spareN(12) <= dacMosi;
   -- Analog Control Ports 
   sysRefN(0) <= attn1A(0);
   sysRefP(0) <= attn1A(1);
   syncInN(0) <= attn1A(2);
   syncInP(0) <= attn1A(3);
   sysRefN(1) <= attn1A(4);

   sysRefP(1) <= attn1B(0);
   syncInN(1) <= attn1B(1);
   syncInP(1) <= attn1B(2);
   sysRefN(2) <= attn1B(3);
   sysRefP(2) <= attn1B(4);

   syncInN(2) <= attn2A(0);
   syncInP(2) <= attn2A(1);
   sysRefN(3) <= attn2A(2);
   sysRefP(3) <= attn2A(3);
   syncInN(3) <= attn2A(4);

   syncInP(3)  <= attn2B(0);
   syncOutN(0) <= attn2B(1);
   syncOutP(0) <= attn2B(2);
   syncOutN(1) <= attn2B(3);
   syncOutP(1) <= attn2B(4);

   syncOutN(2) <= attn3A(0);
   syncOutP(2) <= attn3A(1);
   syncOutN(3) <= attn3A(2);
   syncOutP(3) <= attn3A(3);
   syncOutN(4) <= attn3A(4);

   syncOutP(4) <= attn3B(0);
   syncOutN(5) <= attn3B(1);
   syncOutP(5) <= attn3B(2);
   syncOutN(8) <= attn3B(3);
   syncOutP(8) <= attn3B(4);

   syncOutN(9) <= attn4A(0);
   syncOutP(9) <= attn4A(1);
   spareN(0)   <= attn4A(2);
   spareP(0)   <= attn4A(3);
   spareP(1)   <= attn4A(4);

   spareN(2) <= attn4B(0);
   spareP(2) <= attn4B(1);
   spareN(3) <= attn4B(2);
   spareN(4) <= attn4B(3);
   spareP(4) <= attn4B(4);

   spareN(6) <= attn5A(0);
   spareP(6) <= attn5A(1);
   spareN(7) <= attn5A(2);
   spareP(7) <= attn5A(3);
   spareN(8) <= attn5A(4);

   spareN(11)  <= clSw(0);
   spareP(11)  <= clSw(1);
   fpgaClkP(1) <= clSw(2);
   fpgaClkN(1) <= clSw(3);
   syncOutN(7) <= clSw(4);
   syncOutP(7) <= clSw(5);
   spareN(9)   <= clClkOe;
   spareP(9)   <= rfAmpOn;
   -- JESD
   IBUFDS_SysRef : IBUFDS
      port map (
         I  => fpgaClkP(0),
         IB => fpgaClkN(0),
         O  => jesdSysRef);

   OBUFDS_RxSync0 : OBUFDS
      port map (
         I  => jesdRxSync,
         O  => jtagSec(0),
         OB => jtagSec(1));

   OBUFDS_RxSync1 : OBUFDS
      port map (
         I  => jesdRxSync,
         O  => jtagSec(2),
         OB => jtagSec(3));

   -- Triggers
   IBUFDS_ExtTrig : IBUFDS
      port map (
         I  => syncOutP(6),
         IB => syncOutN(6),
         O  => lemoTrigger);
         
   lemoTrig <= lemoTrigger;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
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
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -----------------
   -- LMK SPI Module
   -----------------   
   SPI_LMK : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         ADDRESS_SIZE_G    => 15,
         DATA_SIZE_G       => 8,
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 10.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(LMK_INDEX_C),
         axiReadSlave   => axilReadSlaves(LMK_INDEX_C),
         axiWriteMaster => axilWriteMasters(LMK_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(LMK_INDEX_C),
         coreSclk       => lmkSck,
         coreSDin       => lmkDeglitched,
         coreSDout      => lmkDout,
         coreCsb        => lmkCsL);

   -- Deglitch TXB0108 (not really designed for SDIO operations)
   process(axilClk)
   begin
      if rising_edge(axilClk) then
         if lmkDin = '0' then
            lmkDeglitched <= '0'  after TPD_G;
            lmkCnt        <= x"0" after TPD_G;
         else
            if lmkCnt = x"F" then
               lmkDeglitched <= '1' after TPD_G;
            else
               lmkCnt <= lmkCnt + 1 after TPD_G;
            end if;
         end if;
      end if;
   end process;

   U_IOBUF : IOBUF
      port map (
         I  => '0',
         O  => lmkDin,
         IO => lmkDio,
         T  => lmkDout);

   -----------------
   -- ADC SPI Module
   -----------------   
   GEN_ADC_SPI : for i in 1 downto 0 generate
      SPI_DAC : entity work.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
            AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
            ADDRESS_SIZE_G    => 15,
            DATA_SIZE_G       => 8,
            CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
            SPI_SCLK_PERIOD_G => 1.0E-6)
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(ADC_A_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(ADC_A_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(ADC_A_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(ADC_A_INDEX_C+i),
            coreSclk       => coreSclk(i),
            coreSDin       => adcMiso,
            coreSDout      => coreSDout(i),
            coreCsb        => coreCsb(i));
   end generate GEN_ADC_SPI;

   adcCsL <= coreCsb;

   with coreCsb select
      adcSck <= coreSclk(0) when "10",
      coreSclk(1)           when "01",
      '0'                   when others;

   with coreCsb select
      adcMosi <= coreSDout(0) when "10",
      coreSDout(1)            when "01",
      '0'                     when others;

   -----------------
   -- DAC SPI Module
   -----------------   
   SPI_DAC_0 : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         ADDRESS_SIZE_G    => 7,
         DATA_SIZE_G       => 16,
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 1.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(DAC_INDEX_C),
         axiReadSlave   => axilReadSlaves(DAC_INDEX_C),
         axiWriteMaster => axilWriteMasters(DAC_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(DAC_INDEX_C),
         coreSclk       => dacSckVec(0),
         coreSDin       => '0',
         coreSDout      => dacMosiVec(0),
         coreCsb        => dacCsLVec(0));

   SPI_DAC_1 : entity work.AmcBpmDacVcoSpi
      generic map (
         TPD_G => TPD_G)
      port map (
         clk             => jesdClk,
         rst             => jesdRst,
         dacVcoEnable    => dacVcoEnable,
         dacVcoCtrl      => dacVcoCtrl,
         dacVcoSckConfig => dacVcoSckConfig,
         -- Slow DAC's SPI Ports
         dacCsL          => dacCsLVec(1),
         dacSck          => dacSckVec(1),
         dacMosi         => dacMosiVec(1));

   dacCsL  <= dacCsLVec(0)  when(dacVcoEnable = '0') else dacCsLVec(1);
   dacSck  <= dacSckVec(0)  when(dacVcoEnable = '0') else dacSckVec(1);
   dacMosi <= dacMosiVec(0) when(dacVcoEnable = '0') else dacMosiVec(1);

   ---------------------
   -- BPM Control Module
   ---------------------
   U_AmcBpmCtrl : entity work.AmcBpmCtrl
      generic map (
         TPD_G            => TPD_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- Debug Signals
         amcClk          => jesdClk,
         clk             => jesdClk,
         rst             => jesdRst,
         adcValids       => adcValids,
         adcValues       => adcValues,
         dacVcoCtrl      => dacVcoCtrl,
         dacVcoEnable    => dacVcoEnable,
         dacVcoSckConfig => dacVcoSckConfig,
         lemoTrig        => lemoTrigger,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(CTRL_INDEX_C),
         axilReadSlave   => axilReadSlaves(CTRL_INDEX_C),
         axilWriteMaster => axilWriteMasters(CTRL_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(CTRL_INDEX_C),
         -----------------------
         -- Application Ports --
         -----------------------      
         -- LMK Ports
         lmkClkSel       => lmkClkSel,
         lmkRst          => lmkRst,
         lmkSync         => lmkSync);

end mapping;
