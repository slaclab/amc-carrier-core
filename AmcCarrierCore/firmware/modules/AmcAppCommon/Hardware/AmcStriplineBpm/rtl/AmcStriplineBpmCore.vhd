-------------------------------------------------------------------------------
-- Title      : Hardware core for Stripline BPM AMC card 
-------------------------------------------------------------------------------
-- File       : AmcStriplineBpmCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-28
-- Last update: 2016-07-12
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BPM Common'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 BPM Common', including this file, 
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
use work.I2cPkg.all;
use work.jesd204bpkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcStriplineBpmCore is
   generic (
      TPD_G                    : time                   := 1 ns;
      SIM_SPEEDUP_G            : boolean                := false;
      SIMULATION_G             : boolean                := false;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10;
      AXI_CLK_FREQ_G           : real                   := 156.25E+6;
      AXI_ERROR_RESP_G         : slv(1 downto 0)        := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G          : slv(31 downto 0)       := (others => '0'));
   port (
      extTrig         : out   sl;
      -- ADC Clock and Reset
      adcClk          : out   sl;
      adcRst          : out   sl;
      -- AXI Streaming Interface (adcClk domain)
      adcMasters      : out   AxiStreamMasterArray(3 downto 0);
      adcCtrls        : in    AxiStreamCtrlArray(3 downto 0) := (others => AXI_STREAM_CTRL_UNUSED_C);
      -- Sample data output (adcClk domain: Use if external data acquisition core is attached)
      adcValids       : out   slv(3 downto 0);
      adcValues       : out   sampleDataArray(3 downto 0);
      -- DAC Interface (adcClk domain)
      dacVcoCtrl      : in    slv(15 downto 0);
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
      -- JESD ADC Sync Ports
      jesdSyncP       : out   slv(1 downto 0);
      jesdSyncN       : out   slv(1 downto 0);
      -- LMK Ports
      lmkClkSel       : out   slv(1 downto 0);
      lmkSck          : out   sl;
      lmkDio          : inout sl;
      lmkSync         : out   sl;
      lmkCsL          : out   sl;
      lmkRst          : out   sl;
      -- Fast ADC's SPI Ports
      adcCsL          : out   slv(1 downto 0);
      adcSck          : out   sl;
      adcMiso         : in    sl;
      adcMosi         : out   sl;
      -- Slow DAC's SPI Ports
      dacCsL          : out   sl;
      dacSck          : out   sl;
      dacMosi         : out   sl;
      -- VMON I2C Ports
      vmonScl         : inout sl;
      vmonSda         : inout sl;
      -- External Trigger Ports
      extTrigP        : in    sl;
      extTrigN        : in    sl;
      -- Analog Control Ports 
      attn1A          : out   slv(4 downto 0);
      attn1B          : out   slv(4 downto 0);
      attn2A          : out   slv(4 downto 0);
      attn2B          : out   slv(4 downto 0);
      attn3A          : out   slv(4 downto 0);
      attn3B          : out   slv(4 downto 0);
      attn4A          : out   slv(4 downto 0);
      attn4B          : out   slv(4 downto 0);
      attn5A          : out   slv(4 downto 0);
      clSw            : out   slv(5 downto 0);
      clClkOe         : out   sl;
      rfAmpOn         : out   sl);
end AmcStriplineBpmCore;

architecture mapping of AmcStriplineBpmCore is

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant JESD_INDEX_C : natural := 0;
   constant LMK_INDEX_C  : natural := 1;
   constant ADC0_INDEX_C : natural := 2;
   constant ADC1_INDEX_C : natural := 3;
   constant DAC_INDEX_C  : natural := 4;
   constant VMON_INDEX_C : natural := 5;
   constant CTRL_INDEX_C : natural := 6;
   constant GTH_INDEX_C  : natural := 7;

   constant JESD_BASE_ADDR_C       : slv(31 downto 0) := X"00000000" + AXI_BASE_ADDR_G;
   constant LMK_BASE_ADDR_C        : slv(31 downto 0) := X"00100000" + AXI_BASE_ADDR_G;
   constant ADC0_BASE_ADDR_C       : slv(31 downto 0) := X"00200000" + AXI_BASE_ADDR_G;
   constant ADC1_BASE_ADDR_C       : slv(31 downto 0) := X"00300000" + AXI_BASE_ADDR_G;
   constant DAC_BASE_ADDR_C        : slv(31 downto 0) := X"00400000" + AXI_BASE_ADDR_G;
   constant VMON_BASE_ADDR_C       : slv(31 downto 0) := X"00500000" + AXI_BASE_ADDR_G;
   constant CTRL_BASE_ADDR_C       : slv(31 downto 0) := X"00600000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC0_BASE_ADDR_C : slv(31 downto 0) := X"00610000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC1_BASE_ADDR_C : slv(31 downto 0) := X"00620000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC2_BASE_ADDR_C : slv(31 downto 0) := X"00630000" + AXI_BASE_ADDR_G;
   constant DEBUG_ADC3_BASE_ADDR_C : slv(31 downto 0) := X"00640000" + AXI_BASE_ADDR_G;
   constant GTH0_BASE_ADDR_C       : slv(31 downto 0) := X"00700000" + AXI_BASE_ADDR_G;
   constant GTH1_BASE_ADDR_C       : slv(31 downto 0) := X"00710000" + AXI_BASE_ADDR_G;
   constant GTH2_BASE_ADDR_C       : slv(31 downto 0) := X"00720000" + AXI_BASE_ADDR_G;
   constant GTH3_BASE_ADDR_C       : slv(31 downto 0) := X"00730000" + AXI_BASE_ADDR_G;
   
   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      JESD_INDEX_C    => (
         baseAddr     => JESD_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      LMK_INDEX_C     => (
         baseAddr     => LMK_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      ADC0_INDEX_C    => (
         baseAddr     => ADC0_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      ADC1_INDEX_C    => (
         baseAddr     => ADC1_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      DAC_INDEX_C     => (
         baseAddr     => DAC_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      VMON_INDEX_C    => (
         baseAddr     => VMON_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      CTRL_INDEX_C    => (
         baseAddr     => CTRL_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"),
      GTH_INDEX_C     => (
         baseAddr     => GTH0_BASE_ADDR_C,
         addrBits     => 20,
         connectivity => X"0001"));  

   constant CTRL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(4 downto 0) := (
      0               => (
         baseAddr     => CTRL_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      1               => (
         baseAddr     => DEBUG_ADC0_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      2               => (
         baseAddr     => DEBUG_ADC1_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      3               => (
         baseAddr     => DEBUG_ADC2_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      4               => (
         baseAddr     => DEBUG_ADC3_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"));            

   constant GTH_CONFIG_C : AxiLiteCrossbarMasterConfigArray(3 downto 0) := (
      0               => (
         baseAddr     => GTH0_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      1               => (
         baseAddr     => GTH1_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      2               => (
         baseAddr     => GTH2_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"),
      3               => (
         baseAddr     => GTH3_BASE_ADDR_C,
         addrBits     => 16,
         connectivity => X"0001"));           

   constant VMON_I2C_CONFIG_C : I2cAxiLiteDevArray(0 to 0) := (
      0             => MakeI2cAxiLiteDevType(
         i2cAddress => "1001001",
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1'));           -- Big endian          

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal ctrlWriteMasters : AxiLiteWriteMasterArray(4 downto 0);
   signal ctrlWriteSlaves  : AxiLiteWriteSlaveArray(4 downto 0);
   signal ctrlReadMasters  : AxiLiteReadMasterArray(4 downto 0);
   signal ctrlReadSlaves   : AxiLiteReadSlaveArray(4 downto 0);

   signal gthWriteMasters : AxiLiteWriteMasterArray(3 downto 0);
   signal gthWriteSlaves  : AxiLiteWriteSlaveArray(3 downto 0);
   signal gthReadMasters  : AxiLiteReadMasterArray(3 downto 0);
   signal gthReadSlaves   : AxiLiteReadSlaveArray(3 downto 0);

   signal refClkDiv2 : sl;
   signal refClk     : sl;
   signal amcClk     : sl;
   signal amcRst     : sl;

   signal jesdClk185     : sl;
   signal jesdRst185     : sl;
   signal jesdMmcmLocked : sl;
   signal jesdSysRef     : sl;
   signal jesdSync       : sl;

   signal lmkDin        : sl;
   signal lmkDeglitched : sl;
   signal lmkCnt        : slv(3 downto 0);
   signal lmkDout       : sl;

   signal extTrigL : sl;
   signal valids   : slv(3 downto 0);
   signal samples  : sampleDataArray(3 downto 0);

   signal coreSclk  : slv(1 downto 0);
   signal coreSDout : slv(1 downto 0);
   signal coreCsb   : slv(1 downto 0);

   signal dacSckVec       : slv(1 downto 0);
   signal dacMosiVec      : slv(1 downto 0);
   signal dacCsLVec       : slv(1 downto 0);
   signal dacVcoEnable    : sl;
   signal dacVcoSckConfig : slv(15 downto 0);

   signal debugTrig   : sl;
   signal debugLogEn  : sl;
   signal debugLogClr : sl;

   signal drpClk  : slv(3 downto 0);
   signal drpRdy  : slv(3 downto 0);
   signal drpEn   : slv(3 downto 0);
   signal drpWe   : slv(3 downto 0);
   signal drpAddr : slv(35 downto 0);
   signal drpDi   : slv(63 downto 0);
   signal drpDo   : slv(63 downto 0);
   
begin

   IBUFDS_ExtTrig : IBUFDS
      port map (
         I  => extTrigP,
         IB => extTrigN,
         O  => debugTrig); 

   extTrig <= debugTrig;

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

   U_XBAR1 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 5,
         MASTERS_CONFIG_G   => CTRL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMasters(CTRL_INDEX_C),
         sAxiWriteSlaves(0)  => axilWriteSlaves(CTRL_INDEX_C),
         sAxiReadMasters(0)  => axilReadMasters(CTRL_INDEX_C),
         sAxiReadSlaves(0)   => axilReadSlaves(CTRL_INDEX_C),
         mAxiWriteMasters    => ctrlWriteMasters,
         mAxiWriteSlaves     => ctrlWriteSlaves,
         mAxiReadMasters     => ctrlReadMasters,
         mAxiReadSlaves      => ctrlReadSlaves);   

   U_XBAR2 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 4,
         MASTERS_CONFIG_G   => GTH_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMasters(GTH_INDEX_C),
         sAxiWriteSlaves(0)  => axilWriteSlaves(GTH_INDEX_C),
         sAxiReadMasters(0)  => axilReadMasters(GTH_INDEX_C),
         sAxiReadSlaves(0)   => axilReadSlaves(GTH_INDEX_C),
         mAxiWriteMasters    => gthWriteMasters,
         mAxiWriteSlaves     => gthWriteSlaves,
         mAxiReadMasters     => gthReadMasters,
         mAxiReadSlaves      => gthReadSlaves);     

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

   -------------
   -- JESD block
   -------------
   U_Jesd : entity work.AmcBpmJesd204b
      generic map (
         TPD_G            => TPD_G,
         TEST_G           => false,
         SYSREF_GEN_G     => false,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)    
      port map (
         -- DRP Interface
         drpClk          => drpClk,
         drpRdy          => drpRdy,
         drpEn           => drpEn,
         drpWe           => drpWe,
         drpAddr         => drpAddr,
         drpDi           => drpDi,
         drpDo           => drpDo,
         -- AXI interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(JESD_INDEX_C),
         axilReadSlave   => axilReadSlaves(JESD_INDEX_C),
         axilWriteMaster => axilWriteMasters(JESD_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(JESD_INDEX_C),
         -- AXI Streaming Interface
         rxAxisMasterArr => adcMasters,
         rxCtrlArr       => adcCtrls,
         -- Sample data output (Use if external data acquisition core is attached)
         sampleDataArr_o => samples,
         dataValidVec_o  => valids,
         -------
         -- JESD
         -------
         -- Clocks
         stableClk       => axilClk,
         refClk          => refClk,
         devClk_i        => jesdClk185,
         devClk2_i       => jesdClk185,
         devRst_i        => jesdRst185,
         devClkActive_i  => jesdMmcmLocked,
         -- GTH Ports
         gtTxP           => jesdTxP,
         gtTxN           => jesdTxN,
         gtRxP           => jesdRxP,
         gtRxN           => jesdRxN,
         -- SYSREF for subclass 1 fixed latency
         sysRef_i        => jesdSysRef,
         -- Synchronisation output combined from all receivers to be connected to ADC chips
         nSync_o         => jesdSync);

   adcValues <= samples;
   adcValids <= valids;

   IBUFDS_SysRef : IBUFDS
      port map (
         I  => jesdSysRefP,
         IB => jesdSysRefN,
         O  => jesdSysRef);        

   GEN_VEC :
   for i in 1 downto 0 generate
      U_OBUFDS : OBUFDS
         port map (
            I  => jesdSync,
            O  => jesdSyncP(i),
            OB => jesdSyncN(i));  
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
            CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
            SPI_SCLK_PERIOD_G => 1.0E-6)
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(ADC0_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(ADC0_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(ADC0_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(ADC0_INDEX_C+i),
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
         CLK_PERIOD_G      => getRealDiv(1, AXI_CLK_FREQ_G),
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
         clk             => jesdClk185,
         rst             => jesdRst185,
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

   ------------------
   -- VMON I2C Module
   ------------------
   I2C_VMON : entity work.AxiI2cRegMaster
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         DEVICE_MAP_G     => VMON_I2C_CONFIG_C,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G)
      port map (
         -- I2C Ports
         scl            => vmonScl,
         sda            => vmonSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters(VMON_INDEX_C),
         axiReadSlave   => axilReadSlaves(VMON_INDEX_C),
         axiWriteMaster => axilWriteMasters(VMON_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(VMON_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);      

   ---------------------
   -- BPM Control Module
   ---------------------
   U_AmcBpmCtrl : entity work.AmcBpmCtrl
      generic map (
         TPD_G                    => TPD_G,
         RING_BUFFER_ADDR_WIDTH_G => RING_BUFFER_ADDR_WIDTH_G,
         AXI_CLK_FREQ_G           => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G         => AXI_ERROR_RESP_G)
      port map (
         -- Debug Signals
         amcClk          => amcClk,
         clk             => jesdClk185,
         rst             => jesdRst185,
         adcValids       => valids,
         adcValues       => samples,
         dacVcoCtrl      => dacVcoCtrl,
         dacVcoEnable    => dacVcoEnable,
         dacVcoSckConfig => dacVcoSckConfig,
         debugTrig       => debugTrig,
         debugLogEn      => debugLogEn,
         debugLogClr     => debugLogClr,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => ctrlReadMasters(0),
         axilReadSlave   => ctrlReadSlaves(0),
         axilWriteMaster => ctrlWriteMasters(0),
         axilWriteSlave  => ctrlWriteSlaves(0),
         -----------------------
         -- Application Ports --
         -----------------------      
         -- LMK Ports
         lmkClkSel       => lmkClkSel,
         lmkRst          => lmkRst,
         lmkSync         => lmkSync,
         -- Analog Control Ports 
         attn1A          => attn1A,
         attn1B          => attn1B,
         attn2A          => attn2A,
         attn2B          => attn2B,
         attn3A          => attn3A,
         attn3B          => attn3B,
         attn4A          => attn4A,
         attn4B          => attn4B,
         attn5A          => attn5A,
         -- Calibration Ports
         clSw            => clSw,
         clClkOe         => clClkOe,
         rfAmpOn         => rfAmpOn);

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
            dataValid       => valids(i),
            dataValue       => samples(i),
            bufferEnable    => debugLogEn,
            bufferClear     => debugLogClr,
            -- AXI-Lite interface for readout
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => ctrlReadMasters(1+i),
            axilReadSlave   => ctrlReadSlaves(1+i),
            axilWriteMaster => ctrlWriteMasters(1+i),
            axilWriteSlave  => ctrlWriteSlaves(1+i));             
   end generate GEN_ADC_DEBUG;

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
            axilReadMaster  => gthReadMasters(i),
            axilReadSlave   => gthReadSlaves(i),
            axilWriteMaster => gthWriteMasters(i),
            axilWriteSlave  => gthWriteSlaves(i),
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
