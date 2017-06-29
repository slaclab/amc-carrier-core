-------------------------------------------------------------------------------
-- Title      : LCLS-II Cryo-Sensor High Speed ADC/DAC Board
-------------------------------------------------------------------------------
-- File       : AmcCryoCore.vhd
-- Author     : Uros Legat <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2017-10-05
-- Last update: 2017-06-29
-- Platform   : LCLS2 Common Plaform Carrier
--              AMC ADC/Analog demo
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
--    
--    8 lane JESD receiver ADC
--    8 lane JESD transmitter DAC
--    SPI: 1 LMK chip, 2 ADC chip (ADC32RF45), and 2 DAC chip () 
--
--    https://confluence.slac.stanford.edu/pages/viewpage.action?spaceKey=AIRTRACK&title=PC_379_396_23_C00
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.jesd204bPkg.all;

entity AmcCryoCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_CLK_FREQ_G   : real             := 156.25E+6;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
   port (
      -- JESD Interface
      jesdSysRef      : out   sl;
      jesdRxSync      : in    sl;
      jesdTxSync      : out   sl;
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
end AmcCryoCore;

architecture top_level_app of AmcCryoCore is

   -------------------------------------------------------------------------------------------------
   -- AXI Lite Config and Signals
   -------------------------------------------------------------------------------------------------
   constant NUM_AXI_MASTERS_C : natural := 6;

   constant CTRL_INDEX_C  : natural := 0;
   constant LMK_INDEX_C   : natural := 1;
   constant DAC_0_INDEX_C : natural := 2;
   constant DAC_1_INDEX_C : natural := 3;
   constant ADC_0_INDEX_C : natural := 4;
   constant ADC_1_INDEX_C : natural := 5;

   constant CTRL_BASE_ADDR_C  : slv(31 downto 0) := x"0000_0000" + AXI_BASE_ADDR_G;
   constant LMK_BASE_ADDR_C   : slv(31 downto 0) := x"0002_0000" + AXI_BASE_ADDR_G;
   constant DAC_0_BASE_ADDR_C : slv(31 downto 0) := x"0004_0000" + AXI_BASE_ADDR_G;
   constant DAC_1_BASE_ADDR_C : slv(31 downto 0) := x"0006_0000" + AXI_BASE_ADDR_G;
   constant ADC_0_BASE_ADDR_C : slv(31 downto 0) := x"0008_0000" + AXI_BASE_ADDR_G;
   constant ADC_1_BASE_ADDR_C : slv(31 downto 0) := x"000C_0000" + AXI_BASE_ADDR_G;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      CTRL_INDEX_C    => (
         baseAddr     => CTRL_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => x"FFFF"),
      LMK_INDEX_C     => (
         baseAddr     => LMK_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => x"FFFF"),
      DAC_0_INDEX_C   => (
         baseAddr     => DAC_0_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => x"FFFF"),
      DAC_1_INDEX_C   => (
         baseAddr     => DAC_1_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => x"FFFF"),
      ADC_0_INDEX_C   => (
         baseAddr     => ADC_0_BASE_ADDR_C,
         addrBits     => 18,
         connectivity => x"FFFF"),
      ADC_1_INDEX_C   => (
         baseAddr     => ADC_1_BASE_ADDR_C,
         addrBits     => 18,
         connectivity => x"FFFF"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   -----------------------
   -- Application Ports --
   -----------------------
   -------------------------------------------------------------------------------------------------
   -- JESD constants and signals
   -------------------------------------------------------------------------------------------------
   -- JESD Reference Ports
   signal jesdSysRefP    : sl;
   signal jesdSysRefN    : sl;
   -- JESD Sync Ports
   signal jesdRxSyncP    : slv(1 downto 0);
   signal jesdRxSyncN    : slv(1 downto 0);
   signal jesdTxSyncP    : slv(1 downto 0);
   signal jesdTxSyncN    : slv(1 downto 0);
   signal jesdTxSyncRaw  : slv(1 downto 0);
   signal jesdTxSyncVec  : slv(1 downto 0);
   signal jesdTxSyncMask : slv(1 downto 0);
   signal s_jesdSysRef   : sl;
   signal jesdRxSyncL    : sl;
   -------------------------------------------------------------------------------------------------
   -- SPI
   -------------------------------------------------------------------------------------------------   

   -- ADC SPI config interface   
   signal adcCoreRst  : slv(1 downto 0) := "00";
   signal adcCoreClk  : slv(1 downto 0);
   signal adcCoreDout : slv(1 downto 0);
   signal adcCoreCsb  : slv(1 downto 0);

   signal adcMuxClk  : sl;
   signal adcMuxDout : sl;

   signal adcSpiClk : sl;
   signal adcSpiDi  : sl;
   signal adcSpiDo  : sl;
   signal adcSpiCsb : slv(1 downto 0);

   -- DAC SPI config interface 
   signal dacCoreClk  : slv(1 downto 0);
   signal dacCoreDout : slv(1 downto 0);
   signal dacCoreCsb  : slv(1 downto 0);

   signal dacMuxClk  : sl;
   signal dacMuxDout : sl;
   signal dacMuxDin  : sl;

   signal dacSpiClk : sl;
   signal dacSpiDio : sl;
   signal dacSpiCsb : slv(1 downto 0);


   -- LMK SPI config interface
   signal lmkSpiDout : sl;
   signal lmkSpiDin  : sl;

   signal lmkSpiClk : sl;
   signal lmkSpiDio : sl;
   signal lmkSpiCsb : sl;

begin
   -----------------------
   -- Generalized Mapping 
   -----------------------

   -- JESD Reference Ports
   jesdSysRefP <= sysRefP(0);  -- Polarity swapped on page 2 of schematics
   jesdSysRefN <= sysRefN(0);

   -- JESD RX Sync Ports
   syncInP(3) <= jesdRxSyncP(0);
   syncInN(3) <= jesdRxSyncN(0);
   spareP(14) <= jesdRxSyncP(1);        -- Swapped
   spareN(14) <= jesdRxSyncN(1);

   -- JESD TX Sync Ports
   jesdTxSyncP(0) <= sysRefP(1);        -- Swapped
   jesdTxSyncN(0) <= sysRefN(1);
   jesdTxSyncP(1) <= spareP(8);
   jesdTxSyncN(1) <= spareN(8);

   -- ADC SPI 
   spareP(2)   <= adcSpiDo;
   spareN(1)   <= adcSpiClk;
   spareN(2)   <= adcSpiCsb(0);
   syncOutN(8) <= adcSpiCsb(1);
   adcSpiDi    <= syncOutP(9);

   -- DAC SPI
   spareP(0)   <= dacSpiClk;
   spareP(1)   <= dacSpiDio;
   spareN(0)   <= dacSpiCsb(0);
   syncOutP(8) <= dacSpiCsb(1);

   -- LMK SPI
   spareP(10) <= lmkSpiClk;
   spareP(11) <= lmkSpiDio;
   spareP(9)  <= lmkSpiCsb;

   -- ADC resets remapping
   spareN(3)   <= axilRst or adcCoreRst(0);
   syncOutN(9) <= axilRst or adcCoreRst(1);


   -------------------------------------------------------------------------------------------------
   -- Application Top Axi Crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR0 : entity work.AxiLiteCrossbar
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

   U_Ctrl : entity work.AmcCryoCoreCtrl
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => locAxilReadMasters(CTRL_INDEX_C),
         axilReadSlave   => locAxilReadSlaves(CTRL_INDEX_C),
         axilWriteMaster => locAxilWriteMasters(CTRL_INDEX_C),
         axilWriteSlave  => locAxilWriteSlaves(CTRL_INDEX_C),
         -- AMC Debug Signals
         rxSync          => jesdRxSync,
         txSyncRaw       => jesdTxSyncRaw,
         txSync          => jesdTxSyncVec,
         txSyncMask      => jesdTxSyncMask);

   ----------------------------------------------------------------
   -- JESD Buffers
   ----------------------------------------------------------------
   IBUFDS_SysRef : IBUFDS
      port map (
         I  => jesdSysRefP,
         IB => jesdSysRefN,
         O  => s_jesdSysRef);

   jesdSysRef <= not(s_jesdSysRef);  -- Note inverted because it is Swapped on the board

   OBUFDS0_RxSync : OBUFDS
      port map (
         I  => jesdRxSync,
         O  => jesdRxSyncP(0),
         OB => jesdRxSyncN(0));

   jesdRxSyncL <= not(jesdRxSync);  -- Note inverted because it is Swapped on the board

   OBUFDS1_RxSync : OBUFDS
      port map (
         I  => jesdRxSyncL,
         O  => jesdRxSyncP(1),
         OB => jesdRxSyncN(1));

   IBUFDS0_TxSync : IBUFDS
      port map (
         I  => jesdTxSyncP(0),
         IB => jesdTxSyncN(0),
         O  => jesdTxSyncRaw(0));

   IBUFDS1_TxSync : IBUFDS
      port map (
         I  => jesdTxSyncP(1),
         IB => jesdTxSyncN(1),
         O  => jesdTxSyncRaw(1));

   jesdTxSyncVec(0) <= jesdTxSyncMask(0) or not(jesdTxSyncRaw(0));
   jesdTxSyncVec(1) <= jesdTxSyncMask(1) or jesdTxSyncRaw(1);

   jesdTxSync <= jesdTxSyncVec(0) and jesdTxSyncVec(1);

   ----------------------------------------------------------------
   -- SPI interface ADC
   ----------------------------------------------------------------
   GEN_ADC : for i in 1 downto 0 generate

      -- AxiSpiMaster_INST : entity work.AxiSpiMaster
      -- generic map (
      -- TPD_G             => TPD_G,
      -- ADDRESS_SIZE_G    => 15,
      -- DATA_SIZE_G       => 8,
      -- CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
      -- SPI_SCLK_PERIOD_G => (1.0/100.0E+3))

      AxiSpiMaster_INST : entity work.Adc32Rf45SpiMaster
         generic map (
            TPD_G             => TPD_G,
            AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
            CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
            SPI_SCLK_PERIOD_G => (1.0/100.0E+3))
         -- SPI_SCLK_PERIOD_G => (1.0/1.0E+6))
         -- SPI_SCLK_PERIOD_G => (1.0/10.0E+6))

         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => locAxilReadMasters(ADC_0_INDEX_C+i),
            axiReadSlave   => locAxilReadSlaves(ADC_0_INDEX_C+i),
            axiWriteMaster => locAxilWriteMasters(ADC_0_INDEX_C+i),
            axiWriteSlave  => locAxilWriteSlaves(ADC_0_INDEX_C+i),
            coreRst        => adcCoreRst(i),
            coreSclk       => adcCoreClk(i),
            coreSDin       => adcSpiDo,
            coreSDout      => adcCoreDout(i),
            coreCsb        => adcCoreCsb(i));

   end generate GEN_ADC;

   -- Output mux
   with adcCoreCsb select
      adcMuxClk <= adcCoreClk(0) when "10",
      adcCoreClk(1)              when "01",
      '0'                        when others;

   with adcCoreCsb select
      adcMuxDout <= adcCoreDout(0) when "10",
      adcCoreDout(1)               when "01",
      '0'                          when others;
   -- IO Assignment
   adcSpiClk <= adcMuxClk;
   adcSpiDi  <= adcMuxDout;
   adcSpiCsb <= adcCoreCsb;

   ----------------------------------------------------------------
   -- SPI interface DAC
   ----------------------------------------------------------------
   GEN_DAC : for i in 1 downto 0 generate
      U_dacAxiSpiMaster : entity work.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
            ADDRESS_SIZE_G    => 7,
            DATA_SIZE_G       => 16,
            CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
            -- SPI_SCLK_PERIOD_G => (1.0/100.0E+3))
            SPI_SCLK_PERIOD_G => (1.0/500.0E+3))
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => locAxilReadMasters(DAC_0_INDEX_C+i),
            axiReadSlave   => locAxilReadSlaves(DAC_0_INDEX_C+i),
            axiWriteMaster => locAxilWriteMasters(DAC_0_INDEX_C+i),
            axiWriteSlave  => locAxilWriteSlaves(DAC_0_INDEX_C+i),
            coreSclk       => dacCoreClk(i),
            coreSDin       => dacMuxDin,
            coreSDout      => dacCoreDout(i),
            coreCsb        => dacCoreCsb(i));
   end generate GEN_DAC;

   -- Output mux
   with dacCoreCsb select
      dacMuxClk <= dacCoreClk(0) when "10",
      dacCoreClk(1)              when "01",
      '0'                        when others;

   with dacCoreCsb select
      dacMuxDout <= dacCoreDout(0) when "10",
      dacCoreDout(1)               when "01",
      '0'                          when others;
   -- IO Assignment
   IOBUF_Dac : IOBUF
      port map (
         I  => '0',
         O  => dacMuxDin,
         IO => dacSpiDio,
         T  => dacMuxDout);

   dacSpiClk <= dacMuxClk;
   dacSpiCsb <= dacCoreCsb;

   -----------------
   -- SPI interface LMK
   -----------------   
   U_lmkAxiSpiMaster : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         ADDRESS_SIZE_G    => 15,
         DATA_SIZE_G       => 8,
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         -- SPI_SCLK_PERIOD_G => (1.0/100.0E+3))
         SPI_SCLK_PERIOD_G => (1.0/500.0E+3))
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(LMK_INDEX_C),
         axiReadSlave   => locAxilReadSlaves(LMK_INDEX_C),
         axiWriteMaster => locAxilWriteMasters(LMK_INDEX_C),
         axiWriteSlave  => locAxilWriteSlaves(LMK_INDEX_C),
         coreSclk       => lmkSpiClk,
         coreSDin       => lmkSpiDin,
         coreSDout      => lmkSpiDout,
         coreCsb        => lmkSpiCsb);

   IOBUF_Lmk : IOBUF
      port map (
         I  => '0',
         O  => lmkSpiDin,
         IO => lmkSpiDio,
         T  => lmkSpiDout);

end top_level_app;
