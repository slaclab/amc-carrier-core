-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2016-06-22
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
      TPD_G                    : time                   := 1 ns;
      SIM_SPEEDUP_G            : boolean                := false;
      SIMULATION_G             : boolean                := false;
      TRIG_CLK_G               : boolean                := false;
      CAL_CLK_G                : boolean                := false;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10;
      AXI_CLK_FREQ_G           : real                   := 156.25E+6;
      AXI_ERROR_RESP_G         : slv(1 downto 0)        := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G          : slv(31 downto 0)       := (others => '0'));
   port (
      -- ADC Interface
      adcClk          : out   sl;
      adcRst          : out   sl;
      adcValids       : out   slv(3 downto 0);
      adcValues       : out   sampleDataArray(3 downto 0);
      -- DAC interface
      dacClk          : out   sl;
      dacRst          : out   sl;
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
      debugTrig       : in    sl;
      fpgaClk         : in    sl;
      smaTrig         : in    sl;
      adcCal          : in    sl;
      lemoDin         : out   slv(1 downto 0);
      lemoDout        : in    slv(1 downto 0);
      bcm             : in    sl;
      -----------------------
      -- Application Ports --
      -----------------------
      -- JESD High Speed Ports
      jesdRxP         : in    slv(3 downto 0);
      jesdRxN         : in    slv(3 downto 0);
      jesdTxP         : out   slv(3 downto 0);
      jesdTxN         : out   slv(3 downto 0);
      -- JESD Reference Ports
      jesdClkP        : in    sl;
      jesdClkN        : in    sl;
      jesdSysRefP     : in    sl;
      jesdSysRefN     : in    sl;
      -- JESD Sync Ports
      jesdRxSyncP     : out   slv(1 downto 0);
      jesdRxSyncN     : out   slv(1 downto 0);
      jesdTxSyncP     : in    sl;
      jesdTxSyncN     : in    sl;
      -- LMK Ports
      lmkMuxSel       : out   sl;
      lmkClkSel       : out   slv(1 downto 0);
      lmkStatus       : in    slv(1 downto 0);
      lmkSck          : out   sl;
      lmkDio          : inout sl;
      lmkSync         : out   slv(1 downto 0);
      lmkCsL          : out   sl;
      lmkRst          : out   sl;
      -- Fast ADC's SPI Ports
      adcCsL          : out   slv(1 downto 0);
      adcSck          : out   slv(1 downto 0);
      adcMiso         : in    slv(1 downto 0);
      adcMosi         : out   slv(1 downto 0);
      -- Fast DAC's SPI Ports
      dacCsL          : out   sl;
      dacSck          : out   sl;
      dacMiso         : in    sl;
      dacMosi         : out   sl;
      -- Slow DAC's SPI Ports
      dacVcoCsP       : out   sl;
      dacVcoCsN       : out   sl;
      dacVcoSckP      : out   sl;
      dacVcoSckN      : out   sl;
      dacVcoDinP      : out   sl;
      dacVcoDinN      : out   sl;
      -- Pass through Interfaces      
      fpgaClkP        : out   sl;
      fpgaClkN        : out   sl;
      smaTrigP        : out   sl;
      smaTrigN        : out   sl;
      adcCalP         : out   sl;
      adcCalN         : out   sl;
      lemoDinP        : in    slv(1 downto 0);
      lemoDinN        : in    slv(1 downto 0);
      lemoDoutP       : out   slv(1 downto 0);
      lemoDoutN       : out   slv(1 downto 0);
      bcmL            : out   sl);
end AmcGenericAdcDacCore;

architecture mapping of AmcGenericAdcDacCore is

   constant NUM_AXI_MASTERS_C : natural := 17;

   constant JESD_RX_INDEX_C    : natural := 0;
   constant JESD_TX_INDEX_C    : natural := 1;
   constant LMK_INDEX_C        : natural := 2;
   constant ADC_A_INDEX_C      : natural := 3;
   constant ADC_B_INDEX_C      : natural := 4;
   constant DAC_INDEX_C        : natural := 5;
   constant CTRL_INDEX_C       : natural := 6;
   constant DEBUG_ADC0_INDEX_C : natural := 7;
   constant DEBUG_ADC1_INDEX_C : natural := 8;
   constant DEBUG_ADC2_INDEX_C : natural := 9;
   constant DEBUG_ADC3_INDEX_C : natural := 10;
   constant DEBUG_DAC0_INDEX_C : natural := 11;
   constant DEBUG_DAC1_INDEX_C : natural := 12;
   constant GTH0_INDEX_C       : natural := 13;
   constant GTH1_INDEX_C       : natural := 14;
   constant GTH2_INDEX_C       : natural := 15;
   constant GTH3_INDEX_C       : natural := 16;

   constant JESD_RX_BASE_ADDR_C    : slv(31 downto 0) := X"00000000" + AXI_BASE_ADDR_G;
   constant JESD_TX_BASE_ADDR_C    : slv(31 downto 0) := X"00100000" + AXI_BASE_ADDR_G;
   constant LMK_BASE_ADDR_C        : slv(31 downto 0) := X"00200000" + AXI_BASE_ADDR_G;
   constant ADC_A_BASE_ADDR_C      : slv(31 downto 0) := X"00300000" + AXI_BASE_ADDR_G;
   constant ADC_B_BASE_ADDR_C      : slv(31 downto 0) := X"00400000" + AXI_BASE_ADDR_G;
   constant DAC_BASE_ADDR_C        : slv(31 downto 0) := X"00500000" + AXI_BASE_ADDR_G;
   constant CTRL_BASE_ADDR_C       : slv(31 downto 0) := X"00600000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC0_BASE_ADDR_C : slv(31 downto 0) := X"00610000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC1_BASE_ADDR_C : slv(31 downto 0) := X"00620000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC2_BASE_ADDR_C : slv(31 downto 0) := X"00630000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC3_BASE_ADDR_C : slv(31 downto 0) := X"00640000" + AXI_BASE_ADDR_G;
   constant DEBUG_DAC0_BASE_ADDR_C : slv(31 downto 0) := X"00650000" + AXI_BASE_ADDR_G;
   constant DEBUG_DAC1_BASE_ADDR_C : slv(31 downto 0) := X"00660000" + AXI_BASE_ADDR_G;
   constant GTH0_BASE_ADDR_C       : slv(31 downto 0) := X"00700000" + AXI_BASE_ADDR_G;
   constant GTH1_BASE_ADDR_C       : slv(31 downto 0) := X"00710000" + AXI_BASE_ADDR_G;
   constant GTH2_BASE_ADDR_C       : slv(31 downto 0) := X"00720000" + AXI_BASE_ADDR_G;
   constant GTH3_BASE_ADDR_C       : slv(31 downto 0) := X"00730000" + AXI_BASE_ADDR_G;
   
   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      JESD_RX_INDEX_C    => (
         baseAddr        => JESD_RX_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      JESD_TX_INDEX_C    => (
         baseAddr        => JESD_TX_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      LMK_INDEX_C        => (
         baseAddr        => LMK_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      ADC_A_INDEX_C      => (
         baseAddr        => ADC_A_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      ADC_B_INDEX_C      => (
         baseAddr        => ADC_B_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DAC_INDEX_C        => (
         baseAddr        => DAC_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      CTRL_INDEX_C       => (
         baseAddr        => CTRL_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DEBUG_ADC0_INDEX_C => (
         baseAddr        => DEBUG_ADC0_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DEBUG_ADC1_INDEX_C => (
         baseAddr        => DEBUG_ADC1_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DEBUG_ADC2_INDEX_C => (
         baseAddr        => DEBUG_ADC2_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DEBUG_ADC3_INDEX_C => (
         baseAddr        => DEBUG_ADC3_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DEBUG_DAC0_INDEX_C => (
         baseAddr        => DEBUG_DAC0_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      DEBUG_DAC1_INDEX_C => (
         baseAddr        => DEBUG_DAC1_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      GTH0_INDEX_C       => (
         baseAddr        => GTH0_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      GTH1_INDEX_C       => (
         baseAddr        => GTH1_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      GTH2_INDEX_C       => (
         baseAddr        => GTH2_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"),
      GTH3_INDEX_C       => (
         baseAddr        => GTH3_BASE_ADDR_C,
         addrBits        => 16,
         connectivity    => X"0001"));              

   signal writeMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal writeSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal refClkDiv2      : sl;
   signal refClk          : sl;
   signal amcClk          : sl;
   signal amcRst          : sl;
   signal jesdClk185      : sl;
   signal jesdRst185      : sl;
   signal jesdMmcmLocked  : sl;
   signal jesdSysRef      : sl;
   signal jesdRxSync      : sl;
   signal jesdTxSync      : sl;
   signal adcDav          : slv(3 downto 0);
   signal adcData         : sampleDataArray(3 downto 0);
   signal dacLocMux       : sampleDataArray(1 downto 0);
   signal dacDav          : slv(1 downto 0);
   signal loopback        : sl;
   signal debugLogEn      : sl;
   signal debugLogClr     : sl;
   signal lmkDataIn       : sl;
   signal lmkDataOut      : sl;
   signal dacVcoEnable    : sl;
   signal dacVcoSckConfig : slv(15 downto 0);

   signal drpClk  : slv(3 downto 0);
   signal drpRdy  : slv(3 downto 0);
   signal drpEn   : slv(3 downto 0);
   signal drpWe   : slv(3 downto 0);
   signal drpAddr : slv(35 downto 0);
   signal drpDi   : slv(63 downto 0);
   signal drpDo   : slv(63 downto 0);
   
begin

   ClkBuf_0 : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => fpgaClk,
         clkOutP => fpgaClkP,
         clkOutN => fpgaClkN);

   TRIG_SIGNAL : if (TRIG_CLK_G = false) generate
      OBUFDS_1 : OBUFDS
         port map (
            I  => smaTrig,
            O  => smaTrigP,
            OB => smaTrigN);         
   end generate;

   TRIG_CLK : if (TRIG_CLK_G = true) generate
      ClkBuf_1 : entity work.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn   => smaTrig,
            clkOutP => smaTrigP,
            clkOutN => smaTrigN);      
   end generate;

   CAL_SIGNAL : if (CAL_CLK_G = false) generate
      OBUFDS_2 : OBUFDS
         port map (
            I  => adcCal,
            O  => adcCalP,
            OB => adcCalN);         
   end generate;

   CAL_CLK : if (CAL_CLK_G = true) generate
      ClkBuf_2 : entity work.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn   => adcCal,
            clkOutP => adcCalP,
            clkOutN => adcCalN);      
   end generate;

   GEN_LEMO :
   for i in 1 downto 0 generate
      
      OBUFDS_LemoDout : OBUFDS
         port map (
            I  => lemoDout(i),
            O  => lemoDoutP(i),
            OB => lemoDoutN(i));  

      IBUFDS_LemoDin : IBUFDS
         port map (
            I  => lemoDinP(i),
            IB => lemoDinN(i),
            O  => lemoDin(i));              

   end generate GEN_LEMO;

   bcmL <= not(bcm);

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
         mAxiWriteMasters    => writeMasters,
         mAxiWriteSlaves     => writeSlaves,
         mAxiReadMasters     => readMasters,
         mAxiReadSlaves      => readSlaves);

   ----------------
   -- JESD Clocking
   ----------------
   U_IBUFDS_GTE3 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")   
      port map (
         I     => jesdClkP,
         IB    => jesdClkN,
         CEB   => '0',
         ODIV2 => refClkDiv2,           -- 185 MHz, Frequency the same as jesdRefClk
         O     => refClk);              -- 185 MHz     

   U_BUFG_GT : BUFG_GT
      port map (
         I       => refClkDiv2,         -- 185 MHz
         CE      => '1',
         CLR     => '0',
         CEMASK  => '1',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => amcClk);            -- 185 MHz

   U_PwrUpRst : entity work.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => amcClk,
         rstOut => amcRst);      

   U_ClockManager : entity work.ClockManagerUltraScale
      generic map (
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 1,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 5.405,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 5.375,  --12.75,--6.375,--6.375,
         CLKOUT0_DIVIDE_F_G => 5.375,  --12.75,--6.375,
         CLKOUT0_RST_HOLD_G => 16)
      port map (
         clkIn     => amcClk,
         rstIn     => amcRst,
         clkOut(0) => jesdClk185,
         rstOut(0) => jesdRst185,
         locked    => jesdMmcmLocked);

   adcClk <= jesdClk185;
   adcRst <= jesdRst185;
   dacClk <= jesdClk185;
   dacRst <= jesdRst185;

   -------------
   -- JESD block
   -------------
   U_Jesd : entity work.AmcGenericAdcDacJesd204b
      generic map (
         TPD_G            => TPD_G,
         TEST_G           => false,
         SYSREF_GEN_G     => false,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)    
      port map (
         -- DRP Interface
         drpClk             => drpClk,
         drpRdy             => drpRdy,
         drpEn              => drpEn,
         drpWe              => drpWe,
         drpAddr            => drpAddr,
         drpDi              => drpDi,
         drpDo              => drpDo,
         -- AXI interface
         axilClk            => axilClk,
         axilRst            => axilRst,
         rxReadMaster       => readMasters(JESD_RX_INDEX_C),
         rxReadSlave        => readSlaves(JESD_RX_INDEX_C),
         rxWriteMaster      => writeMasters(JESD_RX_INDEX_C),
         rxWriteSlave       => writeSlaves(JESD_RX_INDEX_C),
         txReadMaster       => readMasters(JESD_TX_INDEX_C),
         txReadSlave        => readSlaves(JESD_TX_INDEX_C),
         txWriteMaster      => writeMasters(JESD_TX_INDEX_C),
         txWriteSlave       => writeSlaves(JESD_TX_INDEX_C),
         -- Sample data output (Use if external data acquisition core is attached)
         dataValidVec_o(0)  => adcDav(1),   -- Swap CH0 and CH1 to match the front panel labels
         dataValidVec_o(1)  => adcDav(0),   -- Swap CH0 and CH1 to match the front panel labels
         dataValidVec_o(2)  => adcDav(2),
         dataValidVec_o(3)  => adcDav(3),
         sampleDataArr_o(0) => adcData(1),  -- Swap CH0 and CH1 to match the front panel labels
         sampleDataArr_o(1) => adcData(0),  -- Swap CH0 and CH1 to match the front panel labels
         sampleDataArr_o(2) => adcData(2),
         sampleDataArr_o(3) => adcData(3),
         sampleDataArr_i    => dacLocMux,
         -------
         -- JESD
         -------
         -- Clocks
         stableClk          => axilClk,
         refClk             => refClk,
         devClk_i           => jesdClk185,
         devClk2_i          => jesdClk185,
         devRst_i           => jesdRst185,
         devClkActive_i     => jesdMmcmLocked,
         -- GTH Ports
         gtTxP              => jesdTxP,
         gtTxN              => jesdTxN,
         gtRxP              => jesdRxP,
         gtRxN              => jesdRxN,
         -- SYSREF for subclass 1 fixed latency
         sysRef_i           => jesdSysRef,
         -- Synchronisation output combined from all receivers to be connected to ADC chips
         nSync_o            => jesdRxSync,
         nSync_i            => jesdTxSync);

   GEN_DAC_MUX :
   for i in 1 downto 0 generate
      dacLocMux(i) <= dacValues(i) when(loopback = '0') else adcData(i);
      dacDav(i)    <= '1'          when(loopback = '0') else adcDav(i);
   end generate GEN_DAC_MUX;

   adcValids <= adcDav;
   adcValues <= adcData;

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

   GEN_VEC :
   for i in 1 downto 0 generate
      OBUFDS_RxSync : OBUFDS
         port map (
            I  => jesdRxSync,
            O  => jesdRxSyncP(i),
            OB => jesdRxSyncN(i));  
   end generate GEN_VEC;

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
         axiReadMaster  => readMasters(LMK_INDEX_C),
         axiReadSlave   => readSlaves(LMK_INDEX_C),
         axiWriteMaster => writeMasters(LMK_INDEX_C),
         axiWriteSlave  => writeSlaves(LMK_INDEX_C),
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
            AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
            ADDRESS_SIZE_G    => 15,
            DATA_SIZE_G       => 8,
            CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
            SPI_SCLK_PERIOD_G => 1.0E-6)
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => readMasters(ADC_A_INDEX_C+i),
            axiReadSlave   => readSlaves(ADC_A_INDEX_C+i),
            axiWriteMaster => writeMasters(ADC_A_INDEX_C+i),
            axiWriteSlave  => writeSlaves(ADC_A_INDEX_C+i),
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
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         ADDRESS_SIZE_G    => 7,
         DATA_SIZE_G       => 16,
         CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 1.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => readMasters(DAC_INDEX_C),
         axiReadSlave   => readSlaves(DAC_INDEX_C),
         axiWriteMaster => writeMasters(DAC_INDEX_C),
         axiWriteSlave  => writeSlaves(DAC_INDEX_C),
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
         clk             => jesdClk185,
         rst             => jesdRst185,
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
         TPD_G                    => TPD_G,
         RING_BUFFER_ADDR_WIDTH_G => RING_BUFFER_ADDR_WIDTH_G,
         AXI_CLK_FREQ_G           => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G         => AXI_ERROR_RESP_G)
      port map (
         -- AMC Debug Signals
         amcClk          => amcClk,
         clk             => jesdClk185,
         rst             => jesdRst185,
         adcValids       => adcDav,
         adcValues       => adcData,
         dacValues       => dacLocMux,
         dacVcoCtrl      => dacVcoCtrl,
         dacVcoEnable    => dacVcoEnable,
         dacVcoSckConfig => dacVcoSckConfig,
         loopback        => loopback,
         debugTrig       => debugTrig,
         debugLogEn      => debugLogEn,
         debugLogClr     => debugLogClr,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => readMasters(CTRL_INDEX_C),
         axilReadSlave   => readSlaves(CTRL_INDEX_C),
         axilWriteMaster => writeMasters(CTRL_INDEX_C),
         axilWriteSlave  => writeSlaves(CTRL_INDEX_C),
         -----------------------
         -- Application Ports --
         -----------------------      
         -- LMK Ports
         lmkMuxSel       => lmkMuxSel,
         lmkClkSel       => lmkClkSel,
         lmkStatus       => lmkStatus,
         lmkRst          => lmkRst,
         lmkSync         => lmkSync);

   --------------------
   -- Debug ADC Modules
   --------------------
   GEN_ADC_DEBUG : for i in 3 downto 0 generate
      ADC_DEBUG : entity work.AxiLiteRingBuffer
         generic map (
            TPD_G            => TPD_G,
            BRAM_EN_G        => true,
            REG_EN_G         => true,
            DATA_WIDTH_G     => 32,
            RAM_ADDR_WIDTH_G => RING_BUFFER_ADDR_WIDTH_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            -- Data to store in ring buffer
            dataClk         => jesdClk185,
            dataRst         => jesdRst185,
            dataValid       => adcDav(i),
            dataValue       => adcData(i),
            bufferEnable    => debugLogEn,
            bufferClear     => debugLogClr,
            -- AXI-Lite interface for readout
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => readMasters(DEBUG_ADC0_INDEX_C+i),
            axilReadSlave   => readSlaves(DEBUG_ADC0_INDEX_C+i),
            axilWriteMaster => writeMasters(DEBUG_ADC0_INDEX_C+i),
            axilWriteSlave  => writeSlaves(DEBUG_ADC0_INDEX_C+i));             
   end generate GEN_ADC_DEBUG;

   --------------------
   -- Debug DAC Modules
   --------------------
   GEN_DAC_DEBUG : for i in 1 downto 0 generate
      DAC_DEBUG : entity work.AxiLiteRingBuffer
         generic map (
            TPD_G            => TPD_G,
            BRAM_EN_G        => true,
            REG_EN_G         => true,
            DATA_WIDTH_G     => 32,
            RAM_ADDR_WIDTH_G => RING_BUFFER_ADDR_WIDTH_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            -- Data to store in ring buffer
            dataClk         => jesdClk185,
            dataRst         => jesdRst185,
            dataValid       => dacDav(i),
            dataValue       => dacLocMux(i),
            bufferEnable    => debugLogEn,
            bufferClear     => debugLogClr,
            -- AXI-Lite interface for readout
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => readMasters(DEBUG_DAC0_INDEX_C+i),
            axilReadSlave   => readSlaves(DEBUG_DAC0_INDEX_C+i),
            axilWriteMaster => writeMasters(DEBUG_DAC0_INDEX_C+i),
            axilWriteSlave  => writeSlaves(DEBUG_DAC0_INDEX_C+i));             
   end generate GEN_DAC_DEBUG;

   -----------------------
   -- GTH's DRP Interfaces
   -----------------------
   GEN_GTH_DRP : for i in 3 downto 0 generate
      U_AxiLiteToDrp : entity work.AxiLiteToDrp
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_RESP_DECERR_C,
            COMMON_CLK_G     => true,
            EN_ARBITRATION_G => false,
            TIMEOUT_G        => 4096,
            ADDR_WIDTH_G     => 9,
            DATA_WIDTH_G     => 16)      
         port map (
            -- AXI-Lite Port
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => readMasters(GTH0_INDEX_C+i),
            axilReadSlave   => readSlaves(GTH0_INDEX_C+i),
            axilWriteMaster => writeMasters(GTH0_INDEX_C+i),
            axilWriteSlave  => writeSlaves(GTH0_INDEX_C+i),
            -- DRP Interface
            drpClk          => axilClk,
            drpRst          => axilRst,
            drpRdy          => drpRdy(i),
            drpEn           => drpEn(i),
            drpWe           => drpWe(i),
            drpAddr         => drpAddr((i*9)+8 downto (i*9)),
            drpDi           => drpDi((i*16)+15 downto (i*16)),
            drpDo           => drpDo((i*16)+15 downto (i*16)));
      drpClk(i) <= axilClk;
   end generate GEN_GTH_DRP;

end mapping;
