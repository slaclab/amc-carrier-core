-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacDualCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2015-12-16
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
use work.I2cPkg.all;
use work.jesd204bpkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcGenericAdcDacDualCore is
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
      -- ADC Interface
      adcClk          : out   slv(1 downto 0);
      adcRst          : out   slv(1 downto 0);
      adcValids       : out   Slv4Array(1 downto 0);
      adcValues       : out   sampleDataVectorArray(1 downto 0, 3 downto 0);
      -- DAC interface
      dacClk          : out   slv(1 downto 0);
      dacRst          : out   slv(1 downto 0);
      dacValues       : in    sampleDataVectorArray(1 downto 0, 1 downto 0);
      dacVcoCtrl      : in    Slv16Array(1 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Pass through Interfaces
      fpgaClk         : in    slv(1 downto 0);
      smaTrig         : in    slv(1 downto 0);
      adcCal          : in    slv(1 downto 0);
      lemoDin         : out   Slv2Array(1 downto 0);
      lemoDout        : in    Slv2Array(1 downto 0);
      bcm             : in    slv(1 downto 0);
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
      jesdRxSyncP     : out   Slv2Array(1 downto 0);
      jesdRxSyncN     : out   Slv2Array(1 downto 0);
      jesdTxSyncP     : in    slv(1 downto 0);
      jesdTxSyncN     : in    slv(1 downto 0);
      -- LMK Ports
      lmkClkSel       : out   Slv2Array(1 downto 0);
      lmkStatus       : in    Slv2Array(1 downto 0);
      lmkSck          : out   slv(1 downto 0);
      lmkDio          : inout slv(1 downto 0);
      lmkSync         : out   slv(1 downto 0);
      lmkCsL          : out   slv(1 downto 0);
      lmkRst          : out   slv(1 downto 0);
      -- Fast ADC's SPI Ports
      adcCsL          : out   Slv2Array(1 downto 0);
      adcSck          : out   Slv2Array(1 downto 0);
      adcMiso         : in    Slv2Array(1 downto 0);
      adcMosi         : out   Slv2Array(1 downto 0);
      -- Fast DAC's SPI Ports
      dacCsL          : out   slv(1 downto 0);
      dacSck          : out   slv(1 downto 0);
      dacMiso         : in    slv(1 downto 0);
      dacMosi         : out   slv(1 downto 0);
      -- Slow DAC's SPI Ports
      dacVcoCsP       : out   slv(1 downto 0);
      dacVcoCsN       : out   slv(1 downto 0);
      dacVcoSckP      : out   slv(1 downto 0);
      dacVcoSckN      : out   slv(1 downto 0);
      dacVcoDinP      : out   slv(1 downto 0);
      dacVcoDinN      : out   slv(1 downto 0);
      -- Pass through Interfaces      
      fpgaClkP        : out   slv(1 downto 0);
      fpgaClkN        : out   slv(1 downto 0);
      smaTrigP        : out   slv(1 downto 0);
      smaTrigN        : out   slv(1 downto 0);
      adcCalP         : out   slv(1 downto 0);
      adcCalN         : out   slv(1 downto 0);
      lemoDinP        : in    Slv2Array(1 downto 0);
      lemoDinN        : in    Slv2Array(1 downto 0);
      lemoDoutP       : out   Slv2Array(1 downto 0);
      lemoDoutN       : out   Slv2Array(1 downto 0);
      bcmL            : out   slv(1 downto 0));      
end AmcGenericAdcDacDualCore;

architecture mapping of AmcGenericAdcDacDualCore is

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
      U_AMC : entity work.AmcGenericAdcDacCore
         generic map (
            TPD_G            => TPD_G,
            SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
            SIMULATION_G     => SIMULATION_G,
            TRIG_CLK_G       => TRIG_CLK_G,
            CAL_CLK_G        => CAL_CLK_G,
            AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            AXI_BASE_ADDR_G  => AXI_CONFIG_C(i).baseAddr)
         port map(
            -- ADC Interface
            adcClk          => adcClk(i),
            adcRst          => adcRst(i),
            adcValids       => adcValids(i),
            adcValues(0)    => adcValues(i, 0),
            adcValues(1)    => adcValues(i, 1),
            adcValues(2)    => adcValues(i, 2),
            adcValues(3)    => adcValues(i, 3),
            -- DAC interface
            dacClk          => dacClk(i),
            dacRst          => dacRst(i),
            dacValues(0)    => dacValues(i, 0),
            dacValues(1)    => dacValues(i, 1),
            dacVcoCtrl      => dacVcoCtrl(i),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => readMasters(i),
            axilReadSlave   => readSlaves(i),
            axilWriteMaster => writeMasters(i),
            axilWriteSlave  => writeSlaves(i),
            -- Pass through Interfaces
            fpgaClk         => fpgaClk(i),
            smaTrig         => smaTrig(i),
            adcCal          => adcCal(i),
            lemoDin         => lemoDin(i),
            lemoDout        => lemoDout(i),
            bcm             => bcm(i),
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
            jesdRxSyncP     => jesdRxSyncP(i),
            jesdRxSyncN     => jesdRxSyncN(i),
            jesdTxSyncP     => jesdTxSyncP(i),
            jesdTxSyncN     => jesdTxSyncN(i),
            -- LMK Ports
            lmkClkSel       => lmkClkSel(i),
            lmkStatus       => lmkStatus(i),
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
            -- Fast DAC's SPI Ports
            dacCsL          => dacCsL(i),
            dacSck          => dacSck(i),
            dacMiso         => dacMiso(i),
            dacMosi         => dacMosi(i),
            -- Slow DAC's SPI Ports
            dacVcoCsP       => dacVcoCsP(i),
            dacVcoCsN       => dacVcoCsN(i),
            dacVcoSckP      => dacVcoSckP(i),
            dacVcoSckN      => dacVcoSckN(i),
            dacVcoDinP      => dacVcoDinP(i),
            dacVcoDinN      => dacVcoDinN(i),
            -- Pass through Interfaces      
            fpgaClkP        => fpgaClkP(i),
            fpgaClkN        => fpgaClkN(i),
            smaTrigP        => smaTrigP(i),
            smaTrigN        => smaTrigN(i),
            adcCalP         => adcCalP(i),
            adcCalN         => adcCalN(i),
            lemoDinP        => lemoDinP(i),
            lemoDinN        => lemoDinN(i),
            lemoDoutP       => lemoDoutP(i),
            lemoDoutN       => lemoDoutN(i),
            bcmL            => bcmL(i));
   end generate GEN_AMC;

end mapping;
