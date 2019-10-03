-------------------------------------------------------------------------------
-- File       : AmcMrLlrfGen2UpConvertMapping.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use work.FpgaTypePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMrLlrfGen2UpConvertMapping is
   generic (
      TPD_G              : time    := 1 ns;
      TIMING_TRIG_MODE_G : boolean := false);  -- false = data output, true = clock output
   port (
      jesdSysRef    : out   sl;
      jesdRxSync    : in    sl;
      lmkSDin       : out   sl;
      muxSDout      : in    sl;
      spiSclk_o     : in    sl;
      spiSdi_o      : in    sl;
      spiSdo_i      : out   sl;
      spiCsL_o      : in    Slv(4 downto 0);
      attSclk_o     : in    sl;
      attSdi_o      : in    sl;
      attLatchEn_o  : in    slv(3 downto 0);
      jesdClk       : in    sl;
      jesdRst       : in    sl;
      timingTrig    : in    sl;
      fpgaInterlock : in    sl;
      i2cScl        : inout sl;
      i2cSda        : inout sl;
      jesdTxSync    : out   slv(9 downto 0);
      dacRst        : in    sl;
      dacCsL        : in    sl;
      dacSck        : in    sl;
      dacSdi        : in    sl;
      dacSdo        : out   sl;
      -- Recovered EVR clock
      recClk        : in    sl;
      recRst        : in    sl;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- AMC's JTAG Ports
      jtagPri       : inout slv(4 downto 0);
      jtagSec       : inout slv(4 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP      : inout slv(1 downto 0);
      fpgaClkN      : inout slv(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP       : inout slv(3 downto 0);
      sysRefN       : inout slv(3 downto 0);
      -- AMC's Sync Ports
      syncInP       : inout slv(3 downto 0);
      syncInN       : inout slv(3 downto 0);
      syncOutP      : inout slv(9 downto 0);
      syncOutN      : inout slv(9 downto 0);
      -- AMC's Spare Ports
      spareP        : inout slv(15 downto 0);
      spareN        : inout slv(15 downto 0));
end AmcMrLlrfGen2UpConvertMapping;

architecture mapping of AmcMrLlrfGen2UpConvertMapping is

   signal timingTrigReg : sl;

   signal locJesdTxSync : sl;   

begin

   -----------------------
   -- Generalized Mapping 
   -----------------------
   U_jesdSysRef : entity work.JesdSyncIn
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Ports
         jesdSyncP => syncOutP(7),
         jesdSyncN => syncOutN(7),
         -- JESD Low speed Interface
         jesdSync  => jesdSysRef);

   U_jesdRxSync0 : entity work.JesdSyncOut
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Interface
         jesdSync  => jesdRxSync,
         -- JESD Low speed Ports
         jesdSyncP => syncOutP(4),
         jesdSyncN => syncOutN(4));

   U_jesdRxSync1 : entity work.JesdSyncOut
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Interface
         jesdSync  => jesdRxSync,
         -- JESD Low speed Ports
         jesdSyncP => syncOutP(2),
         jesdSyncN => syncOutN(2));

   U_jesdRxSync2 : entity work.JesdSyncOut
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => false)
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Interface
         jesdSync  => jesdRxSync,
         -- JESD Low speed Ports
         jesdSyncP => syncOutP(1),
         jesdSyncN => syncOutN(1));

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

   jtagSec(4) <= fpgaInterlock;

   DATA_OUT : if (TIMING_TRIG_MODE_G = false) generate
      U_ODDR : ODDRE1
         generic map (
            SIM_DEVICE => ite(ULTRASCALE_PLUS_C,"ULTRASCALE_PLUS","ULTRASCALE"))      
         port map (
            C  => recClk,
            Q  => timingTrigReg,
            D1 => timingTrig,
            D2 => timingTrig,
            SR => '0');
      U_OBUF : OBUF
         port map (
            I => timingTrigReg,
            O => jtagSec(0));
   end generate;

   CLK_OUT : if (TIMING_TRIG_MODE_G = true) generate
      U_CLK : entity work.ClkOutBufSingle
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn  => timingTrig,
            clkOut => jtagSec(0));
   end generate;

   i2cScl <= spareN(1);
   i2cSda <= spareN(0);

   -- DAC reset (active LOW)
   spareP(14) <= not(dacRst);
   spareN(12) <= dacSck;
   spareP(12) <= dacCsL;
   spareN(13) <= dacSdi;
   dacSdo     <= spareP(13);

   U_jesdTxSync : entity work.JesdSyncIn
      generic map (
         TPD_G    => TPD_G,
         INVERT_G => true)  -- Note inverted because it is Swapped on the board
      port map (
         -- Clock
         jesdClk   => jesdClk,
         -- JESD Low speed Ports
         jesdSyncP => spareP(9),
         jesdSyncN => spareN(9),
         -- JESD Low speed Interface
         jesdSync  => locJesdTxSync);
         
   jesdTxSync <= (others=>locJesdTxSync);    

end mapping;
