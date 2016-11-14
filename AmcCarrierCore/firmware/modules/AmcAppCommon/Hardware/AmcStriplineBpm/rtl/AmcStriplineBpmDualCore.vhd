-------------------------------------------------------------------------------
-- Title      : Dual Hardware core for Stripline BPM AMC card 
-------------------------------------------------------------------------------
-- File       : AmcStriplineBpmDualCore.vhd
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

entity AmcStriplineBpmDualCore is
   generic (
      TPD_G                    : time                   := 1 ns;
      SIM_SPEEDUP_G            : boolean                := false;
      SIMULATION_G             : boolean                := false;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10;
      AXI_CLK_FREQ_G           : real                   := 156.25E+6;
      AXI_ERROR_RESP_G         : slv(1 downto 0)        := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G          : slv(31 downto 0)       := (others => '0'));
   port (
      extTrig         : out   slv(1 downto 0);
      -- ADC Clock and Reset
      adcClk          : out   slv(1 downto 0);
      adcRst          : out   slv(1 downto 0);
      -- AXI Streaming Interface (adcClk domain)
      adcMasters      : out   AxiStreamMasterVectorArray(1 downto 0, 3 downto 0);
      adcCtrls        : in    AxiStreamCtrlVectorArray(1 downto 0, 3 downto 0) := (others => (others => AXI_STREAM_CTRL_UNUSED_C));
      -- Sample data output (adcClk domain: Use if external data acquisition core is attached)
      adcValids       : out   Slv4Array(1 downto 0);
      adcValues       : out   sampleDataVectorArray(1 downto 0, 3 downto 0);
      -- DAC Interface (adcClk domain)
      dacVcoCtrl      : in    Slv16Array(1 downto 0);
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
      jesdRxP         : in    Slv4Array(1 downto 0);
      jesdRxN         : in    Slv4Array(1 downto 0);
      jesdTxP         : out   Slv4Array(1 downto 0);
      jesdTxN         : out   Slv4Array(1 downto 0);
      -- JESD Reference Ports
      jesdClkP        : in    slv(1 downto 0);
      jesdClkN        : in    slv(1 downto 0);
      jesdSysRefP     : in    slv(1 downto 0);
      jesdSysRefN     : in    slv(1 downto 0);
      -- JESD ADC Sync Ports
      jesdSyncP       : out   Slv2Array(1 downto 0);
      jesdSyncN       : out   Slv2Array(1 downto 0);
      -- LMK Ports
      lmkClkSel       : out   Slv2Array(1 downto 0);
      lmkSck          : out   slv(1 downto 0);
      lmkDio          : inout slv(1 downto 0);
      lmkSync         : out   slv(1 downto 0);
      lmkCsL          : out   slv(1 downto 0);
      lmkRst          : out   slv(1 downto 0);
      -- Fast ADC's SPI Ports
      adcCsL          : out   Slv2Array(1 downto 0);
      adcSck          : out   slv(1 downto 0);
      adcMiso         : in    slv(1 downto 0);
      adcMosi         : out   slv(1 downto 0);
      -- Slow DAC's SPI Ports
      dacCsL          : out   slv(1 downto 0);
      dacSck          : out   slv(1 downto 0);
      dacMosi         : out   slv(1 downto 0);
      -- VMON I2C Ports
      vmonScl         : inout slv(1 downto 0);
      vmonSda         : inout slv(1 downto 0);
      -- External Trigger Ports
      extTrigP        : in    slv(1 downto 0);
      extTrigN        : in    slv(1 downto 0);
      -- Analog Control Ports 
      attn1A          : out   Slv5Array(1 downto 0);
      attn1B          : out   Slv5Array(1 downto 0);
      attn2A          : out   Slv5Array(1 downto 0);
      attn2B          : out   Slv5Array(1 downto 0);
      attn3A          : out   Slv5Array(1 downto 0);
      attn3B          : out   Slv5Array(1 downto 0);
      attn4A          : out   Slv5Array(1 downto 0);
      attn4B          : out   Slv5Array(1 downto 0);
      attn5A          : out   Slv5Array(1 downto 0);
      clSw            : out   Slv6Array(1 downto 0);
      clClkOe         : out   slv(1 downto 0);
      rfAmpOn         : out   slv(1 downto 0));
end AmcStriplineBpmDualCore;

architecture mapping of AmcStriplineBpmDualCore is

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant AMC0_INDEX_C : natural := 0;
   constant AMC1_INDEX_C : natural := 1;

   constant AMC0_BASE_ADDR_C : slv(31 downto 0) := x"00000000" + AXI_BASE_ADDR_G;
   constant AMC1_BASE_ADDR_C : slv(31 downto 0) := x"00800000" + AXI_BASE_ADDR_G;
   
   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      AMC0_INDEX_C    => (
         baseAddr     => AMC0_BASE_ADDR_C,
         addrBits     => 23,
         connectivity => X"0001"),
      AMC1_INDEX_C    => (
         baseAddr     => AMC1_BASE_ADDR_C,
         addrBits     => 23,
         connectivity => X"0001"));

   signal writeMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal writeSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin

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

   -----------
   -- AMC Core
   -----------
   GEN_AMC : for i in 1 downto 0 generate
      U_AMC : entity work.AmcBpmCore
         generic map (
            TPD_G                    => TPD_G,
            SIM_SPEEDUP_G            => SIM_SPEEDUP_G,
            SIMULATION_G             => SIMULATION_G,
            RING_BUFFER_ADDR_WIDTH_G => RING_BUFFER_ADDR_WIDTH_G,
            AXI_CLK_FREQ_G           => AXI_CLK_FREQ_G,
            AXI_ERROR_RESP_G         => AXI_ERROR_RESP_G,
            AXI_BASE_ADDR_G          => AXI_CONFIG_C(i).baseAddr)
         port map(
            extTrig         => extTrig(i),
            -- ADC Clock and Reset
            adcClk          => adcClk(i),
            adcRst          => adcRst(i),
            -- AXI Streaming Interface (adcClk domain)
            adcMasters(0)   => adcMasters(i, 0),
            adcMasters(1)   => adcMasters(i, 1),
            adcMasters(2)   => adcMasters(i, 2),
            adcMasters(3)   => adcMasters(i, 3),
            adcCtrls(0)     => adcCtrls(i, 0),
            adcCtrls(1)     => adcCtrls(i, 1),
            adcCtrls(2)     => adcCtrls(i, 2),
            adcCtrls(3)     => adcCtrls(i, 3),
            -- Sample data output (adcClk domain: Use if external data acquisition core is attached)
            adcValids       => adcValids(i),
            adcValues(0)    => adcValues(i, 0),
            adcValues(1)    => adcValues(i, 1),
            adcValues(2)    => adcValues(i, 2),
            adcValues(3)    => adcValues(i, 3),
            -- DAC Interface (adcClk domain)
            dacVcoCtrl      => dacVcoCtrl(i),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => readMasters(i),
            axilReadSlave   => readSlaves(i),
            axilWriteMaster => writeMasters(i),
            axilWriteSlave  => writeSlaves(i),
            -----------------------
            -- Application Ports --
            -----------------------
            -- JESD High Speed Ports
            jesdRxP         => jesdRxP(i),
            jesdRxN         => jesdRxN(i),
            jesdTxP         => jesdTxP(i),
            jesdTxN         => jesdTxN(i),
            -- JESD Reference Ports
            jesdClkP        => jesdClkP(i),
            jesdClkN        => jesdClkN(i),
            jesdSysRefP     => jesdSysRefP(i),
            jesdSysRefN     => jesdSysRefN(i),
            -- JESD ADC Sync Ports
            jesdSyncP       => jesdSyncP(i),
            jesdSyncN       => jesdSyncN(i),
            -- LMK Ports
            lmkClkSel       => lmkClkSel(i),
            lmkSck          => lmkSck(i),
            lmkDio          => lmkDio(i),
            lmkSync         => lmkSync(i),
            lmkCsL          => lmkCsL(i),
            lmkRst          => lmkRst(i),
            -- Fast ADC's SPI Ports
            adcCsL          => adcCsL(i),
            adcSck          => adcSck(i),
            adcMiso         => adcMiso(i),
            adcMosi         => adcMosi(i),
            -- Slow DAC's SPI Ports
            dacCsL          => dacCsL(i),
            dacSck          => dacSck(i),
            dacMosi         => dacMosi(i),
            -- VMON I2C Ports
            vmonScl         => vmonScl(i),
            vmonSda         => vmonSda(i),
            -- External Trigger Ports
            extTrigP        => extTrigP(i),
            extTrigN        => extTrigN(i),
            -- Analog Control Ports 
            attn1A          => attn1A(i),
            attn1B          => attn1B(i),
            attn2A          => attn2A(i),
            attn2B          => attn2B(i),
            attn3A          => attn3A(i),
            attn3B          => attn3B(i),
            attn4A          => attn4A(i),
            attn4B          => attn4B(i),
            attn5A          => attn5A(i),
            clSw            => clSw(i),
            clClkOe         => clClkOe(i),
            rfAmpOn         => rfAmpOn(i));   
   end generate GEN_AMC;

end mapping;
