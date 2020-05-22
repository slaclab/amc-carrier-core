-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;

library amc_carrier_core;
use amc_carrier_core.FpgaTypePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmDigitalDebugDout is
   generic (
      TPD_G           : time            := 1 ns;
      REG_DOUT_EN_G   : slv(7 downto 0) := x"00";  -- '1' = registered, '0' = unregistered
      REG_DOUT_MODE_G : slv(7 downto 0) := x"00");  -- If registered enabled, '1' = "cout" output, '0' = "dout" output
   port (
      clk     : in  sl;
      disable : in  slv(7 downto 0);
      -- Digital Output Interface
      dout    : in  slv(7 downto 0);
      cout    : in  slv(7 downto 0);
      doutP   : out slv(7 downto 0);
      doutN   : out slv(7 downto 0));
end RtmDigitalDebugDout;

architecture mapping of RtmDigitalDebugDout is

   signal doutReg : slv(7 downto 0);

begin

   GEN_VEC :
   for i in 7 downto 0 generate

      NON_REG : if (REG_DOUT_EN_G(i) = '0') generate
         U_OBUFDS : OBUFDS
            port map (
               I  => dout(i),
               O  => doutP(i),
               OB => doutN(i));
      end generate;

      REG_OUT : if (REG_DOUT_EN_G(i) = '1') generate

         REG_DATA : if (REG_DOUT_MODE_G(i) = '0') generate

            U_ODDR : ODDRE1
               generic map (
                  SIM_DEVICE => ite(ULTRASCALE_PLUS_C,"ULTRASCALE_PLUS","ULTRASCALE"))
               port map (
                  C  => clk,
                  Q  => doutReg(i),
                  D1 => dout(i),
                  D2 => dout(i),
                  SR => disable(i));

            U_OBUFDS : OBUFDS
               port map (
                  I  => doutReg(i),
                  O  => doutP(i),
                  OB => doutN(i));

         end generate;

         REG_CLK : if (REG_DOUT_MODE_G(i) = '1') generate
            U_CLK : entity surf.ClkOutBufDiff
               generic map (
                  TPD_G          => TPD_G,
                  RST_POLARITY_G => '1',
                  XIL_DEVICE_G   => "ULTRASCALE")
               port map (
                  rstIn   => disable(i),
                  clkIn   => cout(i),
                  clkOutP => doutP(i),
                  clkOutN => doutN(i));
         end generate;

      end generate;

   end generate GEN_VEC;

end mapping;
