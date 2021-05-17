-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_16_C02
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

library amc_carrier_core;

entity AmcMrLlrfDownConvertCore is
   generic (
      TPD_G           : time             := 1 ns;
      BUFGCE_DIVIDE_G : positive         := 3;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- JESD SYNC Interface
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      jesdSysRef      : out   sl;
      jesdRxSync      : in    sl;
      -- DAC Interface
      dacValues       : in    Slv16Array(2 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Spare LMK Clock References
      lmkDclk10       : out   sl;
      lmkDclk12       : out   sl;
      bufgCe          : in    sl := '1';
      bufgClr         : in    sl := '0';
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
end AmcMrLlrfDownConvertCore;

architecture mapping of AmcMrLlrfDownConvertCore is

   constant I2C_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 3) := (
      0              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1001000",      -- ADT7420: A1=GND,A0=GND
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '1',            -- Big endian
         repeatStart => '1'),           -- Enable repeated start
      1              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1001001",      -- ADT7420: A1=GND,A0=VDD
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '1',            -- Big endian
         repeatStart => '1'),           -- Enable repeated start
      2              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1001010",      -- ADT7420: A1=VDD,A0=GND
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '1',            -- Big endian
         repeatStart => '1'),           -- Enable repeated start
      3              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1001011",      -- ADT7420: A1=VDD,A0=VDD
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '1',            -- Big endian
         repeatStart => '1'));          -- Enable repeated start

   constant NUM_AXI_MASTERS_C      : natural  := 15;
   constant NUM_COMMON_SPI_CHIPS_C : positive := 4;
   constant NUM_DAC_CHIPS_C        : positive := 3;
   constant NUM_ATTN_CHIPS_C       : positive := 6;

   constant ATT_0_INDEX_C    : natural := 0;
   constant ATT_1_INDEX_C    : natural := 1;
   constant ATT_2_INDEX_C    : natural := 2;
   constant ATT_3_INDEX_C    : natural := 3;
   constant ATT_4_INDEX_C    : natural := 4;
   constant ATT_5_INDEX_C    : natural := 5;
   constant DAC_0_INDEX_C    : natural := 6;
   constant DAC_1_INDEX_C    : natural := 7;
   constant DAC_2_INDEX_C    : natural := 8;
   constant DAC_MUX_INDEX_C  : natural := 9;
   constant TEMP_I2C_INDEX_C : natural := 10;
   constant ADC_0_INDEX_C    : natural := 11;
   constant ADC_1_INDEX_C    : natural := 12;
   constant ADC_2_INDEX_C    : natural := 13;
   constant LMK_INDEX_C      : natural := 14;

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
      ATT_4_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0040"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      ATT_5_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0050"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      DAC_0_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0060"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      DAC_1_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0070"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      DAC_2_INDEX_C    => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0080"),
         addrBits      => 4,
         connectivity  => X"FFFF"),
      DAC_MUX_INDEX_C  => (
         baseAddr      => (AXI_BASE_ADDR_G + x"0000_0090"),
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
         connectivity  => X"0001"));

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

   signal attSclkVec  : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attDoutVec  : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attCsbVec   : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attLEnVec   : slv(NUM_ATTN_CHIPS_C-1 downto 0);
   signal attMuxSClk  : sl;
   signal attMuxSDout : sl;

   signal dacSclkVec  : slv(NUM_DAC_CHIPS_C-1 downto 0);
   signal dacDoutVec  : slv(NUM_DAC_CHIPS_C-1 downto 0);
   signal dacCsbVec   : slv(NUM_DAC_CHIPS_C-1 downto 0);
   signal dacMuxSClk  : sl;
   signal dacMuxSDout : sl;

   signal spiSclk_o : sl;
   signal spiSdi_o  : sl;
   signal spiSdo_i  : sl;
   signal spiCsL_o  : Slv(3 downto 0);

   signal attSclk_o    : sl;
   signal attSdi_o     : sl;
   signal attLatchEn_o : slv(5 downto 0);

   signal dacSclk_o : sl;
   signal dacSdi_o  : sl;
   signal dacCsL_o  : slv(2 downto 0);

   signal lmkDclk : slv(1 downto 0);

   signal i2cScl : sl;
   signal i2cSda : sl;

begin

   -----------------------
   -- Generalized Mapping
   -----------------------
   U_jesdSysRef : entity amc_carrier_core.JesdSyncIn
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Ports
         jesdSyncP => sysRefP(2),
         jesdSyncN => sysRefN(2),
         -- JESD Low speed Interface
         jesdSync  => jesdSysRef);

   U_jesdRxSync0 : entity amc_carrier_core.JesdSyncOut
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Interface
         jesdSync  => jesdRxSync,
         -- JESD Low speed Ports
         jesdSyncP => syncOutP(5),
         jesdSyncN => syncOutN(5));

   U_jesdRxSync1 : entity amc_carrier_core.JesdSyncOut
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Interface
         jesdSync  => jesdRxSync,
         -- JESD Low speed Ports
         jesdSyncP => syncOutP(0),
         jesdSyncN => syncOutN(0));

   U_jesdRxSync2 : entity amc_carrier_core.JesdSyncOut
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Interface
         jesdSync  => jesdRxSync,
         -- JESD Low speed Ports
         jesdSyncP => syncInP(1),
         jesdSyncN => syncInN(1));

   ADC_SDIO_IOBUFT : IOBUF
      port map (
         I  => '0',
         O  => lmkSDin,
         IO => jtagPri(0),
         T  => muxSDout);

   jtagPri(1) <= spiSclk_o;
   jtagPri(2) <= spiSdi_o;
   spiSdo_i   <= jtagPri(3);
   jtagPri(4) <= spiCsL_o(0);
   spareP(3)  <= spiCsL_o(1);
   spareN(3)  <= spiCsL_o(2);
   spareP(2)  <= spiCsL_o(3);

   spareN(6) <= attSclk_o;
   spareP(6) <= attSdi_o;

   spareN(9) <= attLatchEn_o(0);
   spareP(9) <= attLatchEn_o(1);
   spareN(8) <= attLatchEn_o(2);
   spareP(8) <= attLatchEn_o(3);
   spareN(7) <= attLatchEn_o(4);
   spareP(7) <= attLatchEn_o(5);

   spareN(11) <= dacSclk_o;
   spareP(11) <= dacSdi_o;

   spareN(12) <= dacCsL_o(0);
   spareP(12) <= dacCsL_o(1);
   spareN(13) <= dacCsL_o(2);

   U_lmkDclk10 : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => syncInP(2),
         IB => syncInN(2),
         O  => lmkDclk(0));

   U_lmkDclk12 : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => fpgaClkP(0),
         IB => fpgaClkN(0),
         O  => lmkDclk(1));

   U_LMK10 : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => BUFGCE_DIVIDE_G)
      port map (
         I   => lmkDclk(0),
         CLR => bufgClr,
         CE  => bufgCe,
         O   => lmkDclk10);

   U_LMK12 : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => BUFGCE_DIVIDE_G)
      port map (
         I   => lmkDclk(1),
         CLR => bufgClr,
         CE  => bufgCe,
         O   => lmkDclk12);

   i2cScl <= spareN(1);
   i2cSda <= spareN(0);

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

   -----------------------------
   -- SPI interface ADCs and LMK
   -----------------------------
   GEN_SPI_CHIPS : for i in NUM_COMMON_SPI_CHIPS_C-1 downto 0 generate
      AxiSpiMaster_INST : entity surf.AxiSpiMaster
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

   -- Input mux from "IO" port if LMK and from "I" port for ADCs
   muxSDin <= lmkSDin when csbVec = "0111" else spiSdo_i;

   -- Output mux
   with csbVec select
      muxSclk <= sclkVec(0) when "1110",
      sclkVec(1)            when "1101",
      sclkVec(2)            when "1011",
      sclkVec(3)            when "0111",
      '0'                   when others;

   with csbVec select
      muxSDout <= doutVec(0) when "1110",
      doutVec(1)             when "1101",
      doutVec(2)             when "1011",
      doutVec(3)             when "0111",
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
      U_Attn : entity amc_carrier_core.AxiSerAttnMaster
         generic map (
            TPD_G             => TPD_G,
            DATA_SIZE_G       => 6,
            CLK_PERIOD_G      => 6.4E-9,
            SPI_SCLK_PERIOD_G => 1.0E-6)  -- 1MHz
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
   with attCsbVec select
      attMuxSclk <= attSclkVec(0) when "111110",
      attSclkVec(1)               when "111101",
      attSclkVec(2)               when "111011",
      attSclkVec(3)               when "110111",
      attSclkVec(4)               when "101111",
      attSclkVec(5)               when "011111",
      '0'                         when others;

   with attCsbVec select
      attMuxSDout <= attDoutVec(0) when "111110",
      attDoutVec(1)                when "111101",
      attDoutVec(2)                when "111011",
      attDoutVec(3)                when "110111",
      attDoutVec(4)                when "101111",
      attDoutVec(5)                when "011111",
      '0'                          when others;

   -- Outputs
   attSclk_o    <= attMuxSclk;
   attSdi_o     <= attMuxSDout;
   attLatchEn_o <= attLEnVec;

   -----------------------------
   -- SPI DAC modules
   -----------------------------
   GEN_DAC_CHIPS : for i in NUM_DAC_CHIPS_C-1 downto 0 generate
      AxiSerAttnMaster_INST : entity amc_carrier_core.AxiSerAttnMaster
         generic map (
            TPD_G             => TPD_G,
            DATA_SIZE_G       => 16,
            CLK_PERIOD_G      => 6.4E-9,
            SPI_SCLK_PERIOD_G => 1.0E-6)  -- 1MHz
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(DAC_0_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(DAC_0_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(DAC_0_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(DAC_0_INDEX_C+i),
            coreSclk       => dacSclkVec(i),
            coreSDin       => '0',
            coreSDout      => dacDoutVec(i),
            coreCsb        => dacCsbVec(i),
            coreLEn        => open);
   end generate GEN_DAC_CHIPS;

   -- Output mux
   with dacCsbVec select
      dacMuxSclk <= dacSclkVec(0) when "110",
      dacSclkVec(1)               when "101",
      dacSclkVec(2)               when "011",
      '0'                         when others;

   with dacCsbVec select
      dacMuxSDout <= dacDoutVec(0) when "110",
      dacDoutVec(1)                when "101",
      dacDoutVec(2)                when "011",
      '0'                          when others;

   U_Dac : entity amc_carrier_core.AmcMrLlrfDownConvertDacMux
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(DAC_MUX_INDEX_C),
         axilReadSlave   => axilReadSlaves(DAC_MUX_INDEX_C),
         axilWriteMaster => axilWriteMasters(DAC_MUX_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(DAC_MUX_INDEX_C),
         -- External AXI-Module interface
         clk             => jesdClk,
         rst             => jesdRst,
         dacValues       => dacValues,
         dacSclk_i       => dacMuxSclk,
         dacSdi_i        => dacMuxSDout,
         dacCsL_i        => dacCsbVec,
         -- Slow DAC's SPI Ports
         dacSclk_o       => dacSclk_o,
         dacSdi_o        => dacSdi_o,
         dacCsL_o        => dacCsL_o);

end mapping;
