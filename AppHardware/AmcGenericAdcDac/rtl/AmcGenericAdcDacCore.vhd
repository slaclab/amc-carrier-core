-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_13_CXX
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

entity AmcGenericAdcDacCore is
   generic (
      TPD_G           : time             := 1 ns;
      SIM_SPEEDUP_G   : boolean          := false;
      SIMULATION_G    : boolean          := false;
      TRIG_CLK_G      : boolean          := false;
      CAL_CLK_G       : boolean          := false;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- JESD SYNC Interface
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      jesdSysRef      : out   sl;
      jesdRxSync      : in    sl;
      jesdTxSync      : out   sl;
      -- ADC/DAC Interface
      adcValids       : in    slv(3 downto 0);
      adcValues       : in    sampleDataArray(3 downto 0);
      dacValues       : in    sampleDataArray(1 downto 0);
      dacVcoCtrl      : in    slv(15 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Pass through Interfaces
      fpgaClk         : in    sl;
      smaTrig         : in    sl;
      adcCal          : in    sl;
      lemoDin         : out   slv(1 downto 0);
      lemoDout        : in    slv(1 downto 0);
      bcm             : in    sl;
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
      spareN          : inout slv(15 downto 0));
end AmcGenericAdcDacCore;

architecture mapping of AmcGenericAdcDacCore is

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

   signal lmkDataIn  : sl;
   signal lmkDataOut : sl;

   signal dacVcoEnable    : sl;
   signal dacVcoSckConfig : slv(15 downto 0);

   -----------------------
   -- Application Ports --
   -----------------------
   -- JESD Reference Ports
   signal jesdSysRefP : sl;
   signal jesdSysRefN : sl;
   -- JESD Sync Ports
   signal jesdRxSyncP : slv(1 downto 0);
   signal jesdRxSyncN : slv(1 downto 0);
   signal jesdTxSyncP : sl;
   signal jesdTxSyncN : sl;
   -- LMK Ports
   signal lmkMuxSel   : sl;
   signal lmkClkSel   : slv(1 downto 0);
   signal lmkStatus   : slv(1 downto 0);
   signal lmkSck      : sl;
   signal lmkDio      : sl;
   signal lmkSync     : slv(1 downto 0);
   signal lmkCsL      : sl;
   signal lmkRst      : sl;
   -- Fast ADC's SPI Ports
   signal adcCsL      : slv(1 downto 0);
   signal adcSck      : slv(1 downto 0);
   signal adcMiso     : slv(1 downto 0);
   signal adcMosi     : slv(1 downto 0);
   -- Fast DAC's SPI Ports
   signal dacCsL      : sl;
   signal dacSck      : sl;
   signal dacMiso     : sl;
   signal dacMosi     : sl;
   -- Slow DAC's SPI Ports
   signal dacVcoCsP   : sl;
   signal dacVcoCsN   : sl;
   signal dacVcoSckP  : sl;
   signal dacVcoSckN  : sl;
   signal dacVcoDinP  : sl;
   signal dacVcoDinN  : sl;
   -- Pass through Interfaces      
   signal fpgaClockP  : sl;
   signal fpgaClockN  : sl;
   signal smaTrigP    : sl;
   signal smaTrigN    : sl;
   signal adcCalP     : sl;
   signal adcCalN     : sl;
   signal lemoDinP    : slv(1 downto 0);
   signal lemoDinN    : slv(1 downto 0);
   signal lemoDoutP   : slv(1 downto 0);
   signal lemoDoutN   : slv(1 downto 0);
   signal lemoDinput  : slv(1 downto 0);
   signal bcmL        : sl;

begin

   -----------------------
   -- Generalized Mapping 
   -----------------------

   -- JESD Reference Ports
   jesdSysRefP <= spareP(0);
   jesdSysRefN <= spareN(0);

   -- JESD Sync Ports
   syncOutP(0) <= jesdRxSyncP(0);
   syncOutN(0) <= jesdRxSyncN(0);
   syncOutP(1) <= jesdRxSyncP(1);
   syncOutN(1) <= jesdRxSyncN(1);
   jesdTxSyncP <= syncOutP(2);
   jesdTxSyncN <= syncOutN(2);

   -- LMK Ports
   jtagPri(2)   <= lmkMuxSel;
   spareP(4)    <= lmkClkSel(0);
   spareP(5)    <= lmkClkSel(1);
   lmkStatus(0) <= spareN(4);
   lmkStatus(1) <= spareN(5);
   spareN(15)   <= lmkSck;
   syncInN(2)   <= lmkDio;
   syncInP(3)   <= lmkSync(0);
   jtagPri(1)   <= lmkSync(1);
   spareP(15)   <= lmkCsL;
   syncInP(2)   <= lmkRst;

   -- Fast ADC's SPI Ports
   spareP(6)  <= adcCsL(0);
   spareN(6)  <= adcSck(0);
   adcMiso(0) <= spareN(7);
   spareP(7)  <= adcMosi(0);

   spareP(8)  <= adcCsL(1);
   spareN(8)  <= adcSck(1);
   adcMiso(1) <= spareN(9);
   spareP(9)  <= adcMosi(1);

   -- Fast DAC's SPI Ports
   spareN(10) <= dacCsL;
   spareP(10) <= dacSck;
   dacMiso    <= spareP(11);
   spareN(11) <= dacMosi;

   -- Slow DAC's SPI Ports
   spareP(12) <= dacVcoCsP;
   spareN(12) <= dacVcoCsN;
   spareP(13) <= dacVcoSckP;
   spareN(13) <= dacVcoSckN;
   spareP(14) <= dacVcoDinP;
   spareN(14) <= dacVcoDinN;

   -- Pass through Interfaces      
   fpgaClkP(0) <= fpgaClockP;
   fpgaClkN(0) <= fpgaClockN;
   syncOutP(3) <= smaTrigP;
   syncOutN(3) <= smaTrigN;
   syncOutP(4) <= adcCalP;
   syncOutN(4) <= adcCalN;
   lemoDinP(0) <= syncInP(0);
   lemoDinN(0) <= syncInN(0);
   lemoDinP(1) <= syncInP(1);
   lemoDinN(1) <= syncInN(1);
   syncOutP(5) <= lemoDoutP(0);
   syncOutN(5) <= lemoDoutN(0);
   syncOutP(6) <= lemoDoutP(1);
   syncOutN(6) <= lemoDoutN(1);
   jtagPri(0)  <= bcmL;

   --------------------
   -- Application Ports
   --------------------
   ClkBuf_0 : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => fpgaClk,
         clkOutP => fpgaClkP(0),
         clkOutN => fpgaClkN(0));

   TRIG_SIGNAL : if (TRIG_CLK_G = false) generate
      OBUFDS_1 : OBUFDS
         port map (
            I  => smaTrig,
            O  => syncOutP(3),
            OB => syncOutN(3));
   end generate;

   TRIG_CLK : if (TRIG_CLK_G = true) generate
      ClkBuf_1 : entity work.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn   => smaTrig,
            clkOutP => syncOutP(3),
            clkOutN => syncOutN(3));
   end generate;

   CAL_SIGNAL : if (CAL_CLK_G = false) generate
      OBUFDS_2 : OBUFDS
         port map (
            I  => adcCal,
            O  => syncOutP(4),
            OB => syncOutN(4));
   end generate;

   CAL_CLK : if (CAL_CLK_G = true) generate
      ClkBuf_2 : entity work.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn   => adcCal,
            clkOutP => syncOutP(4),
            clkOutN => syncOutN(4));
   end generate;

   GEN_LEMO :
   for i in 1 downto 0 generate

      OBUFDS_LemoDout : OBUFDS
         port map (
            I  => lemoDout(i),
            O  => syncOutP(5+i),
            OB => syncOutN(5+i));

      IBUFDS_LemoDin : IBUFDS
         port map (
            I  => syncInP(i),
            IB => syncInN(i),
            O  => lemoDinput(i));

   end generate GEN_LEMO;

   lemoDin <= lemoDinput;

   bcmL <= not(bcm);

   IBUFDS_SysRef : IBUFDS
      port map (
         I  => jesdSysRefP,
         IB => jesdSysRefN,
         O  => jesdSysRef);

   IBUFDS_TxSync : IBUFDS
      port map (
         I  => jesdTxSyncP,
         IB => jesdTxSyncN,
         O  => jesdTxSync);

   GEN_RX_SYNC :
   for i in 1 downto 0 generate
      OBUFDS_RxSync : OBUFDS
         port map (
            I  => jesdRxSync,
            O  => jesdRxSyncP(i),
            OB => jesdRxSyncN(i));
   end generate GEN_RX_SYNC;

   ---------------------
   -- AXI-Lite Crossbars
   ---------------------
   U_XBAR0 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
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
         ADDRESS_SIZE_G    => 15,
         DATA_SIZE_G       => 8,
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 1.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(LMK_INDEX_C),
         axiReadSlave   => axilReadSlaves(LMK_INDEX_C),
         axiWriteMaster => axilWriteMasters(LMK_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(LMK_INDEX_C),
         coreSclk       => lmkSck,
         coreSDin       => lmkDataIn,
         coreSDout      => lmkDataOut,
         coreCsb        => lmkCsL);

   IOBUF_Lmk : IOBUF
      port map (
         I  => '0',
         O  => lmkDataIn,
         IO => lmkDio,
         T  => lmkDataOut);

   ----------------------
   -- Fast ADC SPI Module
   ----------------------   
   GEN_ADC_SPI : for i in 1 downto 0 generate
      FAST_ADC_SPI : entity work.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
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
            coreSclk       => adcSck(i),
            coreSDin       => adcMiso(i),
            coreSDout      => adcMosi(i),
            coreCsb        => adcCsL(i));
   end generate GEN_ADC_SPI;

   ----------------------
   -- Fast DAC SPI Module
   ----------------------     
   FAST_SPI_DAC : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
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
         coreSclk       => dacSck,
         coreSDin       => dacMiso,
         coreSDout      => dacMosi,
         coreCsb        => dacCsL);

   ----------------------   
   -- SLOW DAC SPI Module
   ----------------------   
   SLOW_SPI_DAC : entity work.AmcGenericAdcDacVcoSpi
      generic map (
         TPD_G => TPD_G)
      port map (
         clk             => jesdClk,
         rst             => jesdRst,
         dacVcoEnable    => dacVcoEnable,
         dacVcoCtrl      => dacVcoCtrl,
         dacVcoSckConfig => dacVcoSckConfig,
         -- Slow DAC's SPI Ports
         dacVcoCsP       => dacVcoCsP,
         dacVcoCsN       => dacVcoCsN,
         dacVcoSckP      => dacVcoSckP,
         dacVcoSckN      => dacVcoSckN,
         dacVcoDinP      => dacVcoDinP,
         dacVcoDinN      => dacVcoDinN);

   -----------------------   
   -- Misc. Control Module
   ----------------------- 
   U_Ctrl : entity work.AmcGenericAdcDacCtrl
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_G)
      port map (
         -- Pass through Interfaces
         smaTrig         => ite(TRIG_CLK_G, '0', smaTrig),
         adcCal          => ite(CAL_CLK_G, '0', adcCal),
         lemoDin         => lemoDinput,
         lemoDout        => lemoDout,
         bcm             => bcm,
         -- AMC Debug Signals
         clk             => jesdClk,
         rst             => jesdRst,
         adcValids       => adcValids,
         adcValues       => adcValues,
         dacValues       => dacValues,
         dacVcoCtrl      => dacVcoCtrl,
         dacVcoEnable    => dacVcoEnable,
         dacVcoSckConfig => dacVcoSckConfig,
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
         lmkMuxSel       => lmkMuxSel,
         lmkClkSel       => lmkClkSel,
         lmkStatus       => lmkStatus,
         lmkRst          => lmkRst,
         lmkSync         => lmkSync);

end mapping;
