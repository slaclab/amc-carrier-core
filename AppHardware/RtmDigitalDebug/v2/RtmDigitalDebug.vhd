-------------------------------------------------------------------------------
-- File       : RtmDigitalDebug.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2017-05-04
-------------------------------------------------------------------------------
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_10_CXX
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmDigitalDebug is
   generic (
      TPD_G            : time            := 1 ns;
      REG_DOUT_EN_G    : slv(7 downto 0) := x"00";  -- '1' = registered, '0' = unregistered
      REG_DOUT_MODE_G  : slv(7 downto 0) := x"00";  -- If registered enabled, '1' = clk output, '0' = data output
      DEFAULT_MODE_G   : boolean         := true;  -- true = 185 MHz clock, false = 119 MHz clock
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Digital I/O Interface
      dout            : in    slv(7 downto 0);
      doutClk         : in    slv(7 downto 0)        := x"00";
      doutDisable     : in    slv(7 downto 0)        := x"00";
      din             : out   slv(7 downto 0);
      -- Clock Jitter Cleaner
      dirtyClkIn      : in    sl;
      cleanClkOut     : out   sl;
      cleanClkLocked  : out   sl;
      -- AXI-Lite Interface
      axilClk         : in    sl                     := '0';
      axilRst         : in    sl                     := '0';
      axilReadMaster  : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- RTM's Low Speed Ports
      rtmLsP          : inout slv(53 downto 0);
      rtmLsN          : inout slv(53 downto 0);
      --  RTM's Clock Reference
      genClkP         : in    sl;
      genClkN         : in    sl);
end RtmDigitalDebug;

architecture mapping of RtmDigitalDebug is

   signal doutReg  : slv(7 downto 0);
   signal cleanClk : sl;

begin

   U_DIN0 : IBUF
      port map (
         I => rtmLsP(2),
         O => din(0));

   U_DIN1 : IBUF
      port map (
         I => rtmLsN(2),
         O => din(1));

   U_DIN2 : IBUF
      port map (
         I => rtmLsP(3),
         O => din(2));

   U_DIN3 : IBUF
      port map (
         I => rtmLsN(3),
         O => din(3));

   U_DIN4 : IBUF
      port map (
         I => rtmLsP(4),
         O => din(4));

   U_DIN5 : IBUF
      port map (
         I => rtmLsN(4),
         O => din(5));

   U_DIN6 : IBUF
      port map (
         I => rtmLsP(5),
         O => din(6));

   U_DIN7 : IBUF
      port map (
         I => rtmLsN(5),
         O => din(7));

   GEN_VEC :
   for i in 7 downto 0 generate

      NON_REG : if (REG_DOUT_EN_G(i) = '0') generate
         U_OBUFDS : OBUFDS
            port map (
               I  => dout(i),
               O  => rtmLsP(i+8),
               OB => rtmLsN(i+8));
      end generate;

      REG_OUT : if (REG_DOUT_EN_G(i) = '1') generate

         REG_DATA : if (REG_DOUT_MODE_G(i) = '0') generate
            U_ODDR : ODDRE1
               port map (
                  C  => doutClk(i),
                  Q  => doutReg(i),
                  D1 => dout(i),
                  D2 => dout(i),
                  SR => doutDisable(i));
            U_OBUFDS : OBUFDS
               port map (
                  I  => doutReg(i),
                  O  => rtmLsP(i+8),
                  OB => rtmLsN(i+8));
         end generate;

         REG_CLK : if (REG_DOUT_MODE_G(i) = '1') generate
            U_CLK : entity work.ClkOutBufDiff
               generic map (
                  TPD_G          => TPD_G,
                  RST_POLARITY_G => '1',
                  XIL_DEVICE_G   => "ULTRASCALE")
               port map (
                  rstIn   => doutDisable(i),
                  clkIn   => doutClk(i),
                  clkOutP => rtmLsP(i+8),
                  clkOutN => rtmLsN(i+8));
         end generate;

      end generate;

   end generate GEN_VEC;

   U_CLK : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => dirtyClkIn,
         clkOutP => rtmLsP(0),
         clkOutN => rtmLsN(0));

   U_IBUFDS : IBUFDS
      port map (
         I  => rtmLsP(1),
         IB => rtmLsN(1),
         O  => cleanClk);

   U_BUFG : BUFG
      port map (
         I => cleanClk,
         O => cleanClkOut);

   U_Si5317a : entity work.Si5317a
      generic map (
         TPD_G            => TPD_G,
         TIMING_MODE_G    => DEFAULT_MODE_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map(
         -- PLL Parallel Interface
         pllLol          => rtmLsP(18),
         pllLos          => rtmLsN(18),
         pllRstL         => rtmLsP(19),
         pllInc          => open,
         pllDec          => open,
         pllFrqTbl       => open,
         pllBypass       => open,
         pllRate(0)      => open,
         pllRate(1)      => open,
         pllSFout(0)     => open,
         pllSFout(1)     => open,
         pllBwSel(0)     => rtmLsP(7),
         pllBwSel(1)     => rtmLsN(7),
         pllFrqSel(0)    => rtmLsP(16),
         pllFrqSel(1)    => rtmLsN(16),
         pllFrqSel(2)    => rtmLsP(17),
         pllFrqSel(3)    => rtmLsN(17),
         pllLocked       => cleanClkLocked,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

end mapping;
