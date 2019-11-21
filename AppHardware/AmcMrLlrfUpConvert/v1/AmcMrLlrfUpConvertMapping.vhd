-------------------------------------------------------------------------------
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.jesd204bpkg.all;

library amc_carrier_core;
use amc_carrier_core.FpgaTypePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMrLlrfUpConvertMapping is
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
      s_dacDataDly  : in    slv(15 downto 0);
      jesdClk       : in    sl;
      jesdRst       : in    sl;
      timingTrig    : in    sl;
      fpgaInterlock : in    sl;
      i2cScl        : inout sl;
      i2cSda        : inout sl;
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
end AmcMrLlrfUpConvertMapping;

architecture mapping of AmcMrLlrfUpConvertMapping is

   signal timingTrigReg : sl;

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
         jesdSyncP => syncOutP(7),
         jesdSyncN => syncOutN(7),
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
         jesdSyncP => syncOutP(4),
         jesdSyncN => syncOutN(4));

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
         jesdSyncP => syncOutP(2),
         jesdSyncN => syncOutN(2));

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
            SIM_DEVICE => ite(ULTRASCALE_PLUS_C, "ULTRASCALE_PLUS", "ULTRASCALE"))
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
      U_CLK : entity surf.ClkOutBufSingle
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE")
         port map (
            clkIn  => timingTrig,
            clkOut => jtagSec(0));
   end generate;

   U_DOUT0 : OBUFDS port map (I => s_dacDataDly(0), O => spareP(9), OB => spareN(9));
   U_DOUT1 : OBUFDS port map (I => s_dacDataDly(1), O => spareP(10), OB => spareN(10));
   U_DOUT2 : OBUFDS port map (I => s_dacDataDly(2), O => spareP(11), OB => spareN(11));
   U_DOUT3 : OBUFDS port map (I => s_dacDataDly(3), O => spareP(12), OB => spareN(12));
   U_DOUT4 : OBUFDS port map (I => s_dacDataDly(4), O => spareP(13), OB => spareN(13));
   U_DOUT5 : OBUFDS port map (I => s_dacDataDly(5), O => spareP(14), OB => spareN(14));
   U_DOUT6 : OBUFDS port map (I => s_dacDataDly(6), O => spareP(15), OB => spareN(15));

   i2cScl <= spareN(1);
   i2cSda <= spareN(0);

   ----------------------------
   -- Version1 Specific Mapping 
   ----------------------------   

   U_DOUT7  : OBUFDS port map (I => s_dacDataDly(7), O => syncOutP(8), OB => syncOutN(8));
   U_DOUT8  : OBUFDS port map (I => s_dacDataDly(8), O => syncInP(0), OB => syncInN(0));
   U_DOUT9  : OBUFDS port map (I => s_dacDataDly(9), O => sysRefP(1), OB => sysRefN(1));
   U_DOUT10 : OBUFDS port map (I => s_dacDataDly(10), O => syncInP(1), OB => syncInN(1));
   U_DOUT11 : OBUFDS port map (I => s_dacDataDly(11), O => sysRefP(2), OB => sysRefN(2));
   U_DOUT12 : OBUFDS port map (I => s_dacDataDly(12), O => syncInP(2), OB => syncInN(2));
   U_DOUT13 : OBUFDS port map (I => s_dacDataDly(13), O => sysRefP(3), OB => sysRefN(3));
   U_DOUT14 : OBUFDS port map (I => s_dacDataDly(14), O => syncInP(3), OB => syncInN(3));
   U_DOUT15 : OBUFDS port map (I => s_dacDataDly(15), O => syncOutP(0), OB => syncOutN(0));

   U_CLK_DIFF_BUF : entity surf.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         rstIn   => jesdRst,
         clkIn   => jesdClk,  -- Samples on both edges of jesdClk (~185MHz). Sample rate = jesdClk2x (~370MHz)
         clkOutP => sysRefP(0),
         clkOutN => sysRefN(0));

end mapping;
