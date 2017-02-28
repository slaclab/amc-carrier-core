-------------------------------------------------------------------------------
-- File       : AmcMrLlrfUpConvertCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-07
-- Last update: 2017-02-27
-------------------------------------------------------------------------------
-- Description: 
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.jesd204bpkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMrLlrfUpConvertCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
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

   constant NUM_AXI_MASTERS_C      : natural               := 10;
   constant NUM_COMMON_SPI_CHIPS_C : positive range 1 to 8 := 5;
   constant NUM_ATTN_CHIPS_C       : positive range 1 to 8 := 4;

   constant ATT_0_INDEX_C   : natural := 0;
   constant ATT_1_INDEX_C   : natural := 1;
   constant ATT_2_INDEX_C   : natural := 2;
   constant ATT_3_INDEX_C   : natural := 3;
   constant ADC_0_INDEX_C   : natural := 4;
   constant ADC_1_INDEX_C   : natural := 5;
   constant ADC_2_INDEX_C   : natural := 6;
   constant LMK_INDEX_C     : natural := 7;
   constant DAC_INDEX_C     : natural := 8;
   constant SIG_GEN_INDEX_C : natural := 9;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      ATT_0_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_0000"),
         addrBits     => 4,
         connectivity => X"FFFF"),
      ATT_1_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_0010"),
         addrBits     => 4,
         connectivity => X"FFFF"),
      ATT_2_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_0020"),
         addrBits     => 4,
         connectivity => X"FFFF"),
      ATT_3_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0000_0030"),
         addrBits     => 4,
         connectivity => X"FFFF"),
      ADC_0_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0002_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      ADC_1_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0004_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      ADC_2_INDEX_C   => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0006_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      LMK_INDEX_C     => (
         baseAddr     => (AXI_BASE_ADDR_G + x"0008_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      DAC_INDEX_C     => (
         baseAddr     => (AXI_BASE_ADDR_G + x"000A_0000"),
         addrBits     => 17,
         connectivity => X"0001"),
      SIG_GEN_INDEX_C => (
         baseAddr     => (AXI_BASE_ADDR_G + x"000C_0000"),
         addrBits     => 17,
         connectivity => X"FFFF"));

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

   signal s_dacData    : slv(15 downto 0);
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

begin

   -----------------------
   -- Generalized Mapping 
   -----------------------
   U_jesdSysRef : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => syncOutP(7),
         IB => syncOutN(7),
         O  => jesdSysRef);

   U_jesdRxSync0 : OBUFDS
      port map (
         I  => jesdRxSync,
         O  => syncOutP(4),
         OB => syncOutN(4));

   U_jesdRxSync1 : OBUFDS
      port map (
         I  => jesdRxSync,
         O  => syncOutP(2),
         OB => syncOutN(2));

   U_jesdRxSync2 : OBUFDS
      port map (
         I  => jesdRxSync,
         O  => syncOutP(1),
         OB => syncOutN(1));

   ADC_SDIO_IOBUFT : IOBUF
      port map (
         I  => '0',
         O  => lmkSDin,
         IO => jtagPri(0),
         T  => muxSDout);


   jtagPri(1) <= spiSclk_o;
   jtagPri(2) <= spiSdi_o;
   spiSdo_i   <= jtagPri(3);

   spareN(2)  <= spiCsL_o(0);
   spareP(3)  <= spiCsL_o(1);
   spareN(3)  <= spiCsL_o(2);
   spareP(2)  <= spiCsL_o(3);
   jtagPri(4) <= spiCsL_o(4);

   spareN(6) <= attSclk_o;
   spareP(6) <= attSdi_o;

   spareN(8) <= attLatchEn_o(0);
   spareP(8) <= attLatchEn_o(1);
   spareN(7) <= attLatchEn_o(2);
   spareP(7) <= attLatchEn_o(3);

   U_DOUT0  : OBUFDS port map (I => s_dacDataDly(0), O => spareP(9), OB => spareN(9));
   U_DOUT1  : OBUFDS port map (I => s_dacDataDly(1), O => spareP(10), OB => spareN(10));
   U_DOUT2  : OBUFDS port map (I => s_dacDataDly(2), O => spareP(11), OB => spareN(11));
   U_DOUT3  : OBUFDS port map (I => s_dacDataDly(3), O => spareP(12), OB => spareN(12));
   U_DOUT4  : OBUFDS port map (I => s_dacDataDly(4), O => spareP(13), OB => spareN(13));
   U_DOUT5  : OBUFDS port map (I => s_dacDataDly(5), O => spareP(14), OB => spareN(14));
   U_DOUT6  : OBUFDS port map (I => s_dacDataDly(6), O => spareP(15), OB => spareN(15));
   U_DOUT7  : OBUFDS port map (I => s_dacDataDly(7), O => sysRefP(0), OB => sysRefN(0));
   U_DOUT8  : OBUFDS port map (I => s_dacDataDly(8), O => sysRefP(1), OB => sysRefN(1));
   U_DOUT9  : OBUFDS port map (I => s_dacDataDly(9), O => syncInP(1), OB => syncInN(1));
   U_DOUT10 : OBUFDS port map (I => s_dacDataDly(10), O => sysRefP(2), OB => sysRefN(2));
   U_DOUT11 : OBUFDS port map (I => s_dacDataDly(11), O => syncInP(2), OB => syncInN(2));
   U_DOUT12 : OBUFDS port map (I => s_dacDataDly(12), O => sysRefP(3), OB => sysRefN(3));
   U_DOUT13 : OBUFDS port map (I => s_dacDataDly(13), O => syncInP(3), OB => syncInN(3));
   U_DOUT14 : OBUFDS port map (I => s_dacDataDly(14), O => syncOutP(0), OB => syncOutN(0));
   U_DOUT15 : OBUFDS port map (I => s_dacDataDly(15), O => syncOutP(3), OB => syncOutN(3));

   -- Samples on both edges of jesdClk (~185MHz). Sample rate = jesdClk2x (~370MHz)
   U_CLK_DIFF_BUF : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         rstIn   => jesdRst,
         clkIn   => jesdClk,
         clkOutP => syncInP(0),
         clkOutN => syncInN(0));

   jtagSec(0) <= timingTrig;
   jtagSec(4) <= fpgaInterlock;

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

   ----------------------------------------------------------------
   -- SPI interface ADCs and LMK
   ----------------------------------------------------------------
   GEN_SPI_CHIPS : for i in 3 downto 0 generate
      U_AXI_SPI : entity work.AxiSpiMaster
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
   U_AXI_SPI_DAC : entity work.AxiSpiMaster
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
            AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
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

   ---------------------------------------------------------
   -- LVDS DAC Signal generator one channel
   -- Clock domain jesdClk2x (~370MHz)
   ---------------------------------------------------------
   U_DAC_SIG_GEN : entity work.LvdsDacSigGen
      generic map (
         TPD_G            => TPD_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(SIG_GEN_INDEX_C).baseAddr,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         DATA_WIDTH_G     => 16)
      port map (
         -- Clocks and Resets
         axiClk          => axilClk,
         axiRst          => axilRst,
         devClk2x_i      => jesdClk2x,
         devRst2x_i      => jesdRst2x,
         -- DAC Interface (devClk_i domain)
         devClk_i        => jesdClk,
         devRst_i        => jesdRst,
         extData_i       => dacValues,
         -- AXI-Lite Interface
         axilReadMaster  => axilReadMasters(SIG_GEN_INDEX_C),
         axilReadSlave   => axilReadSlaves(SIG_GEN_INDEX_C),
         axilWriteMaster => axilWriteMasters(SIG_GEN_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SIG_GEN_INDEX_C),
         -- Delay control
         load_o          => s_load,
         tapDelaySet_o   => s_tapDelaySet,
         tapDelayStat_i  => s_tapDelayStat,
         sampleData_o    => s_dacData);

   GEN_DLY_OUT :
   for i in 15 downto 0 generate
      OutputTapDelay_INST : entity work.OutputTapDelay
         generic map (
            TPD_G              => TPD_G,
            REFCLK_FREQUENCY_G => 370.0)
         port map (
            clk_i    => jesdClk2x,
            rst_i    => jesdRst2x,
            load_i   => s_load(i),
            tapSet_i => s_tapDelaySet(i),
            tapGet_o => s_tapDelayStat(i),
            data_i   => s_dacData(i),
            data_o   => s_dacDataDly(i));
   end generate GEN_DLY_OUT;

end mapping;
