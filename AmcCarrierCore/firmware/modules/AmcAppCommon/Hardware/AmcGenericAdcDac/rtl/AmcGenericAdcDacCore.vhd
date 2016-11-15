-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2016-11-14
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
      TPD_G            : time             := 1 ns;
      SIM_SPEEDUP_G    : boolean          := false;
      SIMULATION_G     : boolean          := false;
      TRIG_CLK_G       : boolean          := false;
      CAL_CLK_G        : boolean          := false;
      AXI_CLK_FREQ_G   : real             := 156.25E+6;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
   port (
      -- JESD SYNC Interface
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      jesdSysRef      : out   sl;
      jesdRxSync      : in    sl;
      jesdTxSync      : out   sl;
      -- ADC/DAC Interface
      adcValids       : in   slv(3 downto 0);
      adcValues       : in   sampleDataArray(3 downto 0);
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

   constant LMK_INDEX_C   : natural := 0;
   constant ADC_A_INDEX_C : natural := 1;
   constant ADC_B_INDEX_C : natural := 2;
   constant DAC_INDEX_C   : natural := 3;
   constant CTRL_INDEX_C  : natural := 4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 15, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal lmkDataIn  : sl;
   signal lmkDataOut : sl;

   signal dacVcoEnable    : sl;
   signal dacVcoSckConfig : slv(15 downto 0);
   
begin

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
            O  => lemoDin(i));              

   end generate GEN_LEMO;

   jtagPri(0) <= not(bcm);

   IBUFDS_SysRef : IBUFDS
      port map (
         I  => spareP(0),
         IB => spareN(0),
         O  => jesdSysRef);   

   IBUFDS_TxSync : IBUFDS
      port map (
         I  => syncOutP(2),
         IB => syncOutN(2),
         O  => jesdTxSync);            

   GEN_VEC :
   for i in 1 downto 0 generate
      OBUFDS_RxSync : OBUFDS
         port map (
            I  => jesdRxSync,
            O  => syncOutP(i),
            OB => syncOutN(i));  
   end generate GEN_VEC;

   ---------------------
   -- AXI-Lite Crossbars
   ---------------------
   U_XBAR0 : entity work.AxiLiteCrossbar
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
         CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 1.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(LMK_INDEX_C),
         axiReadSlave   => axilReadSlaves(LMK_INDEX_C),
         axiWriteMaster => axilWriteMasters(LMK_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(LMK_INDEX_C),
         coreSclk       => spareN(15),
         coreSDin       => lmkDataIn,
         coreSDout      => lmkDataOut,
         coreCsb        => spareP(15));  

   IOBUF_Lmk : IOBUF
      port map (
         I  => '0',
         O  => lmkDataIn,
         IO => syncInN(2),
         T  => lmkDataOut);   

   ----------------------
   -- Fast ADC SPI Module
   ----------------------   
   GEN_ADC_SPI : for i in 1 downto 0 generate
      FAST_ADC_SPI : entity work.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
            AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
            ADDRESS_SIZE_G    => 15,
            DATA_SIZE_G       => 8,
            CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
            SPI_SCLK_PERIOD_G => 1.0E-6)
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(ADC_A_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(ADC_A_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(ADC_A_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(ADC_A_INDEX_C+i),
            coreSclk       => spareN(6+(2*i)),
            coreSDin       => spareN(7+(2*i)),
            coreSDout      => spareP(7+(2*i)),
            coreCsb        => spareP(6+(2*i)));
   end generate GEN_ADC_SPI;

   ----------------------
   -- Fast DAC SPI Module
   ----------------------     
   FAST_SPI_DAC : entity work.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         ADDRESS_SIZE_G    => 7,
         DATA_SIZE_G       => 16,
         CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 1.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(DAC_INDEX_C),
         axiReadSlave   => axilReadSlaves(DAC_INDEX_C),
         axiWriteMaster => axilWriteMasters(DAC_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(DAC_INDEX_C),
         coreSclk       => spareP(10),
         coreSDin       => spareP(11),
         coreSDout      => spareN(11),
         coreCsb        => spareN(10));   

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
         dacVcoCsP       => spareP(12),
         dacVcoCsN       => spareN(12),
         dacVcoSckP      => spareP(13),
         dacVcoSckN      => spareN(13),
         dacVcoDinP      => spareP(14),
         dacVcoDinN      => spareN(14));

   -----------------------   
   -- Misc. Control Module
   ----------------------- 
   U_Ctrl : entity work.AmcGenericAdcDacCtrl
      generic map (
         TPD_G            => TPD_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
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
         lmkMuxSel       => jtagPri(2),
         lmkClkSel(0)    => spareP(4),
         lmkClkSel(1)    => spareP(5),
         lmkStatus(0)    => spareN(4),
         lmkStatus(1)    => spareN(5),
         lmkRst          => syncInP(2),
         lmkSync(0)      => syncInP(3),
         lmkSync(1)      => jtagPri(1));

end mapping;
