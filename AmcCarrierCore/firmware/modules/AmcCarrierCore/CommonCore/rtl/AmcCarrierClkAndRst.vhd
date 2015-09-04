-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierClkAndRst.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-08-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierClkAndRst is
   generic (
      TPD_G         : time    := 1 ns;
      SIM_SPEEDUP_G : boolean := false);
   port (
      axiClk       : out sl;
      axiRst       : out sl;
      ref100MHzClk : out sl;
      ref100MHzRst : out sl;
      ref125MHzClk : out sl;
      ref125MHzRst : out sl;
      ref156MHzClk : out sl;
      ref156MHzRst : out sl;
      ref200MHzClk : out sl;
      ref200MHzRst : out sl;
      ref250MHzClk : out sl;
      ref250MHzRst : out sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- Common Fabricate Clock
      fabClkP      : in  sl;
      fabClkN      : in  sl);    
end AmcCarrierClkAndRst;

architecture mapping of AmcCarrierClkAndRst is

   signal gtClk : sl;

   signal fabClk : sl;
   signal fabRst : sl;

   signal axiClock : sl;
   signal axiReset : sl;

begin

   IBUFDS_GTE3_Inst : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => fabClkP,
         IB    => fabClkN,
         CEB   => '0',
         ODIV2 => gtClk,
         O     => open);  

   BUFG_GT_Inst : BUFG_GT
      port map (
         I       => gtClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => fabClk);

   PwrUpRst_Inst : entity work.PwrUpRst
      generic map(
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map(
         clk    => fabClk,
         rstOut => fabRst); 

   U_ClkManager : entity work.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => false,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 5,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 6.4,     -- 156.25 MHz
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 6.4,     -- 1 GHz = 6.4 x 156.25 MHz
         CLKOUT0_DIVIDE_F_G => 6.4,     -- 156.25 MHz = 1 GHz/6.4
         CLKOUT1_DIVIDE_G   => 10,      -- 100 MHz = 1 GHz/10
         CLKOUT2_DIVIDE_G   => 8,       -- 125 MHz = 1 GHz/8
         CLKOUT3_DIVIDE_G   => 5,       -- 200 MHz = 1 GHz/5
         CLKOUT4_DIVIDE_G   => 4)       -- 250 MHz = 1 GHz/4
      port map(
         -- Clock Input
         clkIn     => fabClk,
         rstIn     => fabRst,
         -- Clock Outputs
         clkOut(0) => axiClock,
         clkOut(1) => ref100MHzClk,
         clkOut(2) => ref125MHzClk,
         clkOut(3) => ref200MHzClk,
         clkOut(4) => ref250MHzClk,
         -- Reset Outputs
         rstOut(0) => axiReset,
         rstOut(1) => ref100MHzRst,
         rstOut(2) => ref125MHzRst,
         rstOut(3) => ref200MHzRst,
         rstOut(4) => ref250MHzRst);


   ref156MHzClk <= axiClock;
   ref156MHzRst <= axiReset;

   axiClk <= axiClock;
   axiRst <= axiReset;

end mapping;
