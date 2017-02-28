-------------------------------------------------------------------------------
-- Title      : ODLAY Module (Ultrascale)
-------------------------------------------------------------------------------
-- File       : OutputTapDelay.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-03-11
-- Last update: 2016-10-05
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: The ODELAYE3 Ultrascale
--              - Non cascaded
--              - Variable load delay type (VAR_LOAD)
--              - When load_i = '1' the tapSet_i is applied
--              - tapGet_o shows the delay setting status
--              - Taps,load and refclk can b asynchronous
--              - refClk input frequency range in MHz (200.0-2400.0)
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

library unisim;
use unisim.vcomponents.all;

entity OutputTapDelay is
   generic (
      TPD_G              : time := 1 ns;
      -- refClk input frequency range in MHz (200.0-2400.0)
      REFCLK_FREQUENCY_G : real := 200.0);
   port (
      -- When load_i = '1' the tapSet_i is applied
      clk_i    : in  sl;
      rst_i    : in  sl;
      load_i   : in  sl;
      tapSet_i : in  slv(8 downto 0);
      tapGet_o : out slv(8 downto 0);   -- Tap status
      --
      data_i   : in  sl;
      data_o   : out sl);
end OutputTapDelay;

architecture rtl of OutputTapDelay is

   signal dataReg : sl;

begin

   -- ODDRE1 module
   U_ODDR : ODDRE1
      generic map (
         IS_C_INVERTED  => '0',         -- Optional inversion for C
         IS_D1_INVERTED => '0',         -- Optional inversion for D1
         IS_D2_INVERTED => '0',         -- Optional inversion for D2
         SRVAL          => '0')  -- Initializes the ODDRE1 Flip-Flops to the specified value ('0', '1')
      port map (
         Q  => dataReg,                 -- 1-bit output: Data output to IOB
         C  => clk_i,                   -- 1-bit input: High-speed clock input
         D1 => data_i,                  -- 1-bit input: Parallel data input 1
         D2 => data_i,                  -- 1-bit input: Parallel data input 2
         SR => rst_i);                  -- 1-bit input: Active High Async Reset

   -- ODELAYE3 module
   U_ODELAYE3 : ODELAYE3
      generic map (
         CASCADE          => "NONE",
         DELAY_FORMAT     => "COUNT",
         DELAY_TYPE       => "VAR_LOAD",
         DELAY_VALUE      => 0,
         IS_CLK_INVERTED  => '0',
         IS_RST_INVERTED  => '0',
         REFCLK_FREQUENCY => REFCLK_FREQUENCY_G,
         UPDATE_MODE      => "ASYNC")
      port map (
         CE          => '0',   -- CE increments or decrements tap delay (Not used in VAR_LOAD type)
         CLK         => clk_i,
         RST         => rst_i,
         -- No cascade
         CASC_OUT    => open,           -- Disabled (Not cascaded)
         CASC_IN     => '1',            -- Disabled (Not cascaded)
         CASC_RETURN => '1',            -- Disabled (Not cascaded)

         -- Data INOUT
         ODATAIN     => dataReg,
         DATAOUT     => data_o,
         --
         CNTVALUEOUT => tapGet_o,       -- Tap delay indicator
         CNTVALUEIN  => tapSet_i,       -- Tap delay setting
         --
         EN_VTC      => '0',  -- Disable voltage temperature compensation! (Not used in VAR_LOAD type)
         INC         => '1',  -- Increment or decrement flag - not used (Not used in VAR_LOAD type)
         LOAD        => load_i);

end rtl;
