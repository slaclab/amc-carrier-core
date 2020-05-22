-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_02_C00
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.jesd204bPkg.all;

library amc_carrier_core;

entity AmcCryoDemoCore is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- Internal ports
      amcTrigHw : out sl;

      -- JESD Interface
      jesdSysRef : out sl;
      jesdRxSync : in  sl;
      jesdTxSync : out slv(9 downto 0);

      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -----------------------
      -- Application Ports --
      -----------------------
      -- AMC's JTAG Ports
      jtagPri  : inout slv(4 downto 0);
      jtagSec  : inout slv(4 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP : inout slv(1 downto 0);
      fpgaClkN : inout slv(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP  : inout slv(3 downto 0);
      sysRefN  : inout slv(3 downto 0);
      -- AMC's Sync Ports
      syncInP  : inout slv(3 downto 0);
      syncInN  : inout slv(3 downto 0);
      syncOutP : inout slv(9 downto 0);
      syncOutN : inout slv(9 downto 0);
      -- AMC's Spare Ports
      spareP   : inout slv(15 downto 0);
      spareN   : inout slv(15 downto 0));
end AmcCryoDemoCore;

architecture top_level_app of AmcCryoDemoCore is

   -------------------------------------------------------------------------------------------------
   -- AXI Lite Config and Signals
   -------------------------------------------------------------------------------------------------
   constant NUM_AXI_MASTERS_C : natural := 5;

   constant ADC_0_INDEX_C : natural := 0;
   constant ADC_1_INDEX_C : natural := 1;
   constant ADC_2_INDEX_C : natural := 2;
   constant LMK_INDEX_C   : natural := 3;
   constant DAC_INDEX_C   : natural := 4;

   constant ADC_0_BASE_ADDR_C : slv(31 downto 0) := X"0002_0000" + AXI_BASE_ADDR_G;
   constant ADC_1_BASE_ADDR_C : slv(31 downto 0) := X"0004_0000" + AXI_BASE_ADDR_G;
   constant ADC_2_BASE_ADDR_C : slv(31 downto 0) := X"0006_0000" + AXI_BASE_ADDR_G;
   constant LMK_BASE_ADDR_C   : slv(31 downto 0) := X"0008_0000" + AXI_BASE_ADDR_G;
   constant DAC_BASE_ADDR_C   : slv(31 downto 0) := X"000A_0000" + AXI_BASE_ADDR_G;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      ADC_0_INDEX_C   => (
         baseAddr     => ADC_0_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => X"FFFF"),
      ADC_1_INDEX_C   => (
         baseAddr     => ADC_1_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => X"FFFF"),
      ADC_2_INDEX_C   => (
         baseAddr     => ADC_2_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => X"FFFF"),
      LMK_INDEX_C     => (
         baseAddr     => LMK_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => X"FFFF"),
      DAC_INDEX_C     => (
         baseAddr     => DAC_BASE_ADDR_C,
         addrBits     => 17,
         connectivity => X"FFFF"));

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
   signal jesdSysRefP : sl;
   signal jesdSysRefN : sl;
   -- JESD Sync Ports
   signal jesdRxSyncP : slv(3 downto 0);
   signal jesdRxSyncN : slv(3 downto 0);
   signal jesdTxSyncP : sl;
   signal jesdTxSyncN : sl;

   signal locJesdTxSync : sl;

   -------------------------------------------------------------------------------------------------
   -- SPI
   -------------------------------------------------------------------------------------------------

   -- ADC and LMK SPI config interface
   constant NUM_COMMON_SPI_CHIPS_C : positive range 1 to 8 := 4;
   signal coreSclk                 : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);
   signal coreSDout                : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);
   signal coreCsb                  : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);

   signal muxSDin  : sl;
   signal muxSClk  : sl;
   signal muxSDout : sl;

   signal lmkSDin : sl;

   signal spiSclk : sl;
   signal spiSdi  : sl;
   signal spiSdo  : sl;
   signal spiSdio : sl;
   signal spiCsL  : slv(NUM_COMMON_SPI_CHIPS_C-1 downto 0);

   -- Fast DAC's SPI Ports
   signal spiSDinDac  : sl;
   signal spiSDoutDac : sl;

   signal spiSclkDac : sl;
   signal spiSdioDac : sl;
   signal spiCsLDac  : sl;

begin
   -----------------------
   -- Generalized Mapping
   -----------------------

   -- JESD Reference Ports
   jesdSysRefP <= sysRefP(2);
   jesdSysRefN <= sysRefN(2);

   -- JESD Sync Ports
   syncOutP(5) <= jesdRxSyncP(0);
   syncOutN(5) <= jesdRxSyncN(0);
   syncOutP(0) <= jesdRxSyncP(1);
   syncOutN(0) <= jesdRxSyncN(1);
   syncInP(1)  <= jesdRxSyncP(2);
   syncInN(1)  <= jesdRxSyncN(2);

   jesdTxSyncP <= syncInP(0);
   jesdTxSyncN <= syncInN(0);

   -- SPI
   jtagPri(0) <= spiSdio;
   jtagPri(1) <= spiSclk;
   jtagPri(2) <= spiSdi;
   spiSdo     <= jtagPri(3);

   jtagPri(4) <= spiCsL(0);
   spareP(3)  <= spiCsL(1);
   spareN(3)  <= spiCsL(2);
   spareP(2)  <= spiCsL(3);

   spareP(0) <= spiSclkDac;
   spareN(0) <= spiCsLDac;
   spareP(1) <= spiSdioDac;

   -- Trigger remapping
   amcTrigHw <= spareN(1);

   -------------------------------------------------------------------------------------------------
   -- Application Top Axi Crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR0 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
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

   ----------------------------------------------------------------
   -- JESD Buffers
   ----------------------------------------------------------------
   U_jesdSysRef : entity amc_carrier_core.JesdSyncIn
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Ports
         jesdSyncP => jesdSysRefP,
         jesdSyncN => jesdSysRefN,
         -- JESD Low speed Interface
         jesdSync  => jesdSysRef);

   GEN_RX_SYNC :
   for i in 2 downto 0 generate
      U_jesdRxSync : entity amc_carrier_core.JesdSyncOut
         generic map (
            TPD_G    => TPD_G,
            INVERT_G => false)
         port map (
            -- Clock
            jesdClk   => jesdClk,
            -- JESD Low speed Interface
            jesdSync  => jesdRxSync,
            -- JESD Low speed Ports
            jesdSyncP => jesdRxSyncP(i),
            jesdSyncN => jesdRxSyncN(i));
   end generate GEN_RX_SYNC;

   U_jesdTxSync : entity amc_carrier_core.JesdSyncIn
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Ports
         jesdSyncP => jesdTxSyncP,
         jesdSyncN => jesdTxSyncN,
         -- JESD Low speed Interface
         jesdSync  => locJesdTxSync);

   jesdTxSync <= (others=>locJesdTxSync);

   ----------------------------------------------------------------
   -- SPI interface ADCs and LMK
   ----------------------------------------------------------------
   gen_dcSpiChips : for I in NUM_COMMON_SPI_CHIPS_C-1 downto 0 generate
      AxiSpiMaster_INST : entity surf.AxiSpiMaster
         generic map (
            TPD_G             => TPD_G,
            ADDRESS_SIZE_G    => 15,
            DATA_SIZE_G       => 8,
            CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
            SPI_SCLK_PERIOD_G => 10.0E-6)
         port map (
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => locAxilReadMasters(ADC_0_INDEX_C+I),
            axiReadSlave   => locAxilReadSlaves(ADC_0_INDEX_C+I),
            axiWriteMaster => locAxilWriteMasters(ADC_0_INDEX_C+I),
            axiWriteSlave  => locAxilWriteSlaves(ADC_0_INDEX_C+I),
            coreSclk       => coreSclk(I),
            coreSDin       => muxSDin,
            coreSDout      => coreSDout(I),
            coreCsb        => coreCsb(I));
   end generate gen_dcSpiChips;

   -- Input mux from "IO" port if LMK and from "I" port for ADCs
   muxSDin <= lmkSDin when coreCsb = "0111" else spiSdo;

   -- Output mux
   with coreCsb select
      muxSclk <= coreSclk(0) when "1110",
      coreSclk(1)            when "1101",
      coreSclk(2)            when "1011",
      coreSclk(3)            when "0111",
      '0'                    when others;

   with coreCsb select
      muxSDout <= coreSDout(0) when "1110",
      coreSDout(1)             when "1101",
      coreSDout(2)             when "1011",
      coreSDout(3)             when "0111",
      '0'                      when others;

   -- Outputs
   spiSclk <= muxSclk;
   spiSdi  <= muxSDout;

   U_ADC_SDIO_IOBUFT : IOBUF
      port map (
         I  => '0',
         O  => lmkSDin,
         IO => spiSdio,
         T  => muxSDout);

   -- Active low chip selects
   spiCsL <= coreCsb;

   ----------------------------------------------------------------
   -- SPI interface DAC
   ----------------------------------------------------------------
   U_dacAxiSpiMaster : entity surf.AxiSpiMaster
      generic map (
         TPD_G             => TPD_G,
         ADDRESS_SIZE_G    => 7,
         DATA_SIZE_G       => 16,
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => 10.0E-6)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(DAC_INDEX_C),
         axiReadSlave   => locAxilReadSlaves(DAC_INDEX_C),
         axiWriteMaster => locAxilWriteMasters(DAC_INDEX_C),
         axiWriteSlave  => locAxilWriteSlaves(DAC_INDEX_C),
         coreSclk       => spiSclkDac,
         coreSDin       => spiSDinDac,
         coreSDout      => spiSDoutDac,
         coreCsb        => spiCsLDac);

   U_DAC_SDIO_IOBUFT : IOBUF
      port map (
         I  => '0',
         O  => spiSDinDac,
         IO => spiSdioDac,
         T  => spiSDoutDac);
-----------------------------------
end top_level_app;
