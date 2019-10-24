-------------------------------------------------------------------------------
-- File       : AmcMrLlrfUpConvertCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-07
-- Last update: 2018-03-14
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.jesd204bpkg.all;
use surf.I2cPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMrLlrfUpConvertCore is
   generic (
      TPD_G              : time             := 1 ns;
      TIMING_TRIG_MODE_G : boolean          := false;  -- false = data output, true = clock output
      IODELAY_GROUP_G    : string           := "AMC_DELAY_GROUP";
      AXI_BASE_ADDR_G    : slv(31 downto 0) := (others => '0'));
   port (
      -- JESD SYNC Interface
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      jesdClk2x       : in    sl;
      jesdRst2x       : in    sl;
      jesdSysRef      : out   sl;
      jesdRxSync      : in    sl;
      -- DAC Interface (jesdClk domain)
      dacValues       : in    slv(31 downto 0);
      -- Interlock and trigger
      timingTrig      : in    sl;
      fpgaInterlock   : in    sl;
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Recovered EVR clock
      recClk          : in    sl;
      recRst          : in    sl;
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
end AmcMrLlrfUpConvertCore;

architecture mapping of AmcMrLlrfUpConvertCore is

   constant I2C_DEVICE_MAP_C : I2cAxiLiteDevArray(3 downto 0) := (
      0             => MakeI2cAxiLiteDevType(
         i2cAddress => "1001000",       -- ADT7420: A1=GND,A0=GND
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1',             -- Big endian
         repeatStart=> '1'),            -- Enable repeated start
      1             => MakeI2cAxiLiteDevType(
         i2cAddress => "1001001",       -- ADT7420: A1=GND,A0=VDD
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1',             -- Big endian
         repeatStart=> '1'),            -- Enable repeated start
      2             => MakeI2cAxiLiteDevType(
         i2cAddress => "1001010",       -- ADT7420: A1=VDD,A0=GND
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1',             -- Big endian
         repeatStart=> '1'),            -- Enable repeated start
      3             => MakeI2cAxiLiteDevType(
         i2cAddress => "1001011",       -- ADT7420: A1=VDD,A0=VDD
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1',             -- Big endian
         repeatStart=> '1'));           -- Enable repeated start

   constant NUM_AXI_MASTERS_C      : natural               := 11;
   constant NUM_COMMON_SPI_CHIPS_C : positive range 1 to 8 := 5;
   constant NUM_ATTN_CHIPS_C       : positive range 1 to 8 := 4;

   constant ATT_0_INDEX_C    : natural := 0;
   constant ATT_1_INDEX_C    : natural := 1;
   constant ATT_2_INDEX_C    : natural := 2;
   constant ATT_3_INDEX_C    : natural := 3;
   constant TEMP_I2C_INDEX_C : natural := 4;
   constant ADC_0_INDEX_C    : natural := 5;
   constant ADC_1_INDEX_C    : natural := 6;
   constant ADC_2_INDEX_C    : natural := 7;
   constant LMK_INDEX_C      : natural := 8;
   constant DAC_INDEX_C      : natural := 9;
   constant SIG_GEN_INDEX_C  : natural := 10;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      ATT_0_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0000"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      ATT_1_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0010"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      ATT_2_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0020"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      ATT_3_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0030"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      TEMP_I2C_INDEX_C => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0001_0000"),
         addrBits      => 16,
         connectivity  => X"FFFF"),
      ADC_0_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0002_0000"),
         addrBits      => 17,
         connectivity  => X"0001"),
      ADC_1_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0004_0000"),
         addrBits      => 17,
         connectivity  => X"0001"),
      ADC_2_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0006_0000"),
         addrBits      => 17,
         connectivity  => X"0001"),
      LMK_INDEX_C      => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0008_0000"),
         addrBits      => 17,
         connectivity  => X"0001"),
      DAC_INDEX_C      => (
         baseAddr      => (AXI_BASE_ADDR_G + x"000A_0000"),
         addrBits      => 17,
         connectivity  => X"0001"),
      SIG_GEN_INDEX_C  => (
         baseAddr      => (AXI_BASE_ADDR_G + x"000C_0000"),
         addrBits      => 17,
         connectivity  => X"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal sclkVec : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);
   signal doutVec : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);
   signal csbVec  : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);

   signal muxSDin  : sl;
   signal muxSClk  : sl;
   signal muxSDout : sl;
   signal lmkSDin  : sl;

   signal attSclkVec : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attDoutVec : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attCsbVec  : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attLEnVec  : slv(NUM_ATTN_CHIPS_C-1 downto 0);

   signal attMuxSClk  : sl;
   signal attMuxSDout : sl;

   signal s_dacData    : Slv2Array(15 downto 0);
   signal s_dacDataDly : slv(15 downto 0);

   signal s_load         : slv(15 downto 0);
   signal s_tapDelaySet  : Slv9Array(15 downto 0);
   signal s_tapDelayStat : Slv9Array(15 downto 0);

   signal spiSclk_o : sl;
   signal spiSdi_o  : sl;
   signal spiSdo_i  : sl;
   signal spiCsL_o  : Slv(4 downto 0);

   signal attSclk_o    : sl;
   signal attSdi_o     : sl;
   signal attLatchEn_o : slv(3 downto 0);

   signal i2cScl : sl;
   signal i2cSda : sl;

begin

   U_AmcMapping : entity work.AmcMrLlrfUpConvertMapping
      generic map (
         TPD_G              => TPD_G,
         TIMING_TRIG_MODE_G => TIMING_TRIG_MODE_G)
      port map (
         jesdSysRef    => jesdSysRef,
         jesdRxSync    => jesdRxSync,
         lmkSDin       => lmkSDin,
         muxSDout      => muxSDout,
         spiSclk_o     => spiSclk_o,
         spiSdi_o      => spiSdi_o,
         spiSdo_i      => spiSdo_i,
         spiCsL_o      => spiCsL_o,
         attSclk_o     => attSclk_o,
         attSdi_o      => attSdi_o,
         attLatchEn_o  => attLatchEn_o,
         s_dacDataDly  => s_dacDataDly,
         jesdClk       => jesdClk,
         jesdRst       => jesdRst,
         timingTrig    => timingTrig,
         fpgaInterlock => fpgaInterlock,
         i2cScl        => i2cScl,
         i2cSda        => i2cSda,
         -- Recovered EVR clock
         recClk        => recClk,
         recRst        => recRst,
         -----------------------
         -- Application Ports --
         -----------------------      
         -- AMC's JTAG Ports
         jtagPri       => jtagPri,
         jtagSec       => jtagSec,
         -- AMC's FPGA Clock Ports
         fpgaClkP      => fpgaClkP,
         fpgaClkN      => fpgaClkN,
         -- AMC's System Reference Ports
         sysRefP       => sysRefP,
         sysRefN       => sysRefN,
         -- AMC's Sync Ports
         syncInP       => syncInP,
         syncInN       => syncInN,
         syncOutP      => syncOutP,
         syncOutN      => syncOutN,
         -- AMC's Spare Ports
         spareP        => spareP,
         spareN        => spareN);

   ---------------------
   -- AXI-Lite Crossbars
   ---------------------
   U_XBAR0 : entity surf.AxiLiteCrossbar
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

   --------------------------
   -- I2C Temperature Sensors
   --------------------------
   U_I2C : entity surf.AxiI2cRegMaster
      generic map (
         TPD_G          => TPD_G,
         I2C_SCL_FREQ_G => 100.0E+3,    -- units of Hz
         DEVICE_MAP_G   => I2C_DEVICE_MAP_C,
         AXI_CLK_FREQ_G => 156.25E+6)
      port map (
         -- I2C Ports
         scl            => i2cScl,
         sda            => i2cSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters(TEMP_I2C_INDEX_C),
         axiReadSlave   => axilReadSlaves(TEMP_I2C_INDEX_C),
         axiWriteMaster => axilWriteMasters(TEMP_I2C_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(TEMP_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   ----------------------------------------------------------------
   -- SPI interface ADCs and LMK
   ----------------------------------------------------------------
   GEN_SPI_CHIPS : for i in 3 downto 0 generate
      U_AXI_SPI : entity surf.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
            ADDRESS_SIZE_G    => 15,
            DATA_SIZE_G       => 8,
            CLK_PERIOD_G      => 6.4E-9,
            SPI_SCLK_PERIOD_G => 100.0E-6)
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(ADC_0_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(ADC_0_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(ADC_0_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(ADC_0_INDEX_C+i),
            coreSclk       => sclkVec(i),
            coreSDin       => muxSDin,
            coreSDout      => doutVec(i),
            coreCsb        => csbVec(i));
   end generate GEN_SPI_CHIPS;

   ----------------------------------------------------------------
   -- SPI interface LVDS DAC
   ----------------------------------------------------------------
   U_AXI_SPI_DAC : entity surf.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         ADDRESS_SIZE_G    => 7,
         DATA_SIZE_G       => 8,
         CLK_PERIOD_G      => 6.4E-9,
         SPI_SCLK_PERIOD_G => 100.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(DAC_INDEX_C),
         axiReadSlave   => axilReadSlaves(DAC_INDEX_C),
         axiWriteMaster => axilWriteMasters(DAC_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(DAC_INDEX_C),
         coreSclk       => sclkVec(4),
         coreSDin       => muxSDin,
         coreSDout      => doutVec(4),
         coreCsb        => csbVec(4));

   -- Input mux from "IO" port if LMK and from "I" port for ADCs 
   muxSDin <= lmkSDin when csbVec = "10111" else spiSdo_i;

   -- Output mux
   with csbVec select
      muxSclk <= sclkVec(0) when "11110",
      sclkVec(1)            when "11101",
      sclkVec(2)            when "11011",
      sclkVec(3)            when "10111",
      sclkVec(4)            when "01111",
      '0'                   when others;

   with csbVec select
      muxSDout <= doutVec(0) when "11110",
      doutVec(1)             when "11101",
      doutVec(2)             when "11011",
      doutVec(3)             when "10111",
      doutVec(4)             when "01111",
      '0'                    when others;
   -- Outputs 
   spiSclk_o <= muxSclk;
   spiSdi_o  <= muxSDout;

   -- Active low chip selects
   spiCsL_o <= csbVec;

   -----------------------------
   -- Serial Attenuator modules
   -----------------------------
   GEN_ATT_CHIPS : for i in NUM_ATTN_CHIPS_C-1 downto 0 generate
      U_Attn : entity work.AxiSerAttnMaster
         generic map (
            TPD_G             => TPD_G,
            DATA_SIZE_G       => 6,
            CLK_PERIOD_G      => 6.4E-9,
            SPI_SCLK_PERIOD_G => 1.0E-6)  -- 10KHz
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(ATT_0_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(ATT_0_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(ATT_0_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(ATT_0_INDEX_C+i),
            coreSclk       => attSclkVec(i),
            coreSDin       => '0',
            coreSDout      => attDoutVec(i),
            coreCsb        => attCsbVec(i),
            coreLEn        => attLEnVec(i));
   end generate GEN_ATT_CHIPS;

   -- Output mux
   with attcsbVec select
      attMuxSclk <= attSclkVec(0) when "1110",
      attSclkVec(1)               when "1101",
      attSclkVec(2)               when "1011",
      attSclkVec(3)               when "0111",
      '0'                         when others;

   with attcsbVec select
      attMuxSDout <= attDoutVec(0) when "1110",
      attDoutVec(1)                when "1101",
      attDoutVec(2)                when "1011",
      attDoutVec(3)                when "0111",
      '0'                          when others;

   -- Outputs                   
   attSclk_o    <= attMuxSclk;
   attSdi_o     <= attMuxSDout;
   --attLatchEn_o   <= attCsbVec;
   attLatchEn_o <= attLEnVec;

   ----------------------------
   -- LVDS DAC Signal generator
   ----------------------------
   U_DAC_SIG_GEN : entity work.LvdsDacSigGen
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => AXI_CONFIG_C(SIG_GEN_INDEX_C).baseAddr)
      port map (
         -- devClk2x Reference
         devClk2x_i      => jesdClk2x,
         devRst2x_i      => jesdRst2x,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SIG_GEN_INDEX_C),
         axilReadSlave   => axilReadSlaves(SIG_GEN_INDEX_C),
         axilWriteMaster => axilWriteMasters(SIG_GEN_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SIG_GEN_INDEX_C),
         -- DAC Interface (devClk_i domain)
         devClk_i        => jesdClk,
         devRst_i        => jesdRst,
         extData_i       => dacValues,
         -- Delay control (devClk_i domain)
         load_o          => s_load,
         tapDelaySet_o   => s_tapDelaySet,
         tapDelayStat_i  => s_tapDelayStat,
         -- Sample data output (devClk_i domain)
         sampleData_o    => s_dacData);

   GEN_DLY_OUT :
   for i in 15 downto 0 generate
      OutputTapDelay_INST : entity work.OutputTapDelay
         generic map (
            TPD_G              => TPD_G,
            IODELAY_GROUP_G    => IODELAY_GROUP_G,
            REFCLK_FREQUENCY_G => 370.0)  -- external IDELAYCTRL uses jesdClk2x@370MHz
         port map (
            clk_i    => jesdClk,
            rst_i    => jesdRst,
            load_i   => s_load(i),
            tapSet_i => s_tapDelaySet(i),
            tapGet_o => s_tapDelayStat(i),
            data_i   => s_dacData(i),
            data_o   => s_dacDataDly(i));
   end generate GEN_DLY_OUT;

end mapping;
