-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierClkAndRst.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-10-13
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
      MPS_SLOT_G    : boolean := false;
      SIM_SPEEDUP_G : boolean := false);
   port (
      -- Reference Clocks and Resets
      ref125MHzClk : out sl;
      ref125MHzRst : out sl;
      ref156MHzClk : out sl;
      ref156MHzRst : out sl;
      ref312MHzClk : out sl;
      ref312MHzRst : out sl;
      ref625MHzClk : out sl;
      ref625MHzRst : out sl;
      gthFabClk    : out sl;
      -- AXI-Lite Clocks and Resets
      axilClk      : out sl;
      axilRst      : out sl;
      -- MPS Clocks and Resets
      mps125MHzClk : out sl;
      mps125MHzRst : out sl;
      mps312MHzClk : out sl;
      mps312MHzRst : out sl;
      mps625MHzClk : out sl;
      mps625MHzRst : out sl;
      ----------------
      -- Core Ports --
      ----------------   
      -- Common Fabricate Clock
      fabClkP      : in  sl;
      fabClkN      : in  sl;
      -- Backplane MPS Ports
      mpsClkIn     : in  sl;
      mpsClkOut    : out sl);         
end AmcCarrierClkAndRst;

architecture mapping of AmcCarrierClkAndRst is

   signal gtClk     : sl;
   signal fabClk    : sl;
   signal fabRst    : sl;
   signal mpsRefClk : sl;
   signal clk       : sl;
   signal rst       : sl;
   signal clkOut    : slv(2 downto 0);
   signal rstOut    : slv(2 downto 0);
   signal rstDly    : slv(2 downto 0);

begin

   axilClk      <= fabClk;
   ref156MHzClk <= fabClk;

   axilRst      <= rstDly(2);
   ref156MHzRst <= rstDly(2);

   -- Adding registers to help with timing
   process(fabClk)
   begin
      if rising_edge(fabClk) then
         rstDly <= rstDly(1 downto 0) & fabRst after TPD_G;
      end if;
   end process;

   ref125MHzClk <= clkOut(2);
   ref125MHzRst <= rstOut(2);

   ref312MHzClk <= clkOut(1);
   ref312MHzRst <= rstOut(1);

   mps125MHzClk <= clkOut(2);
   mps125MHzRst <= rstOut(2);

   mps312MHzClk <= clkOut(1);
   mps312MHzRst <= rstOut(1);

   -- Adding registers to help with timing
   process(clkOut)
   begin
      if rising_edge(clkOut(0)) then
         mps625MHzRst <= rstOut(0) after TPD_G;
         ref625MHzRst <= rstOut(0) after TPD_G;
      end if;
   end process;
   ref625MHzClk <= clkOut(0);
   mps625MHzClk <= clkOut(0);

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
         O     => gthFabClk);  

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

   U_IBUF : IBUF
      port map (
         I => mpsClkIn,
         O => mpsRefClk);  

   clk <= fabClk when(MPS_SLOT_G) else mpsRefClk;
   rst <= fabRst when(MPS_SLOT_G) else '0';

   U_ClkManagerMps : entity work.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => ite(MPS_SLOT_G, false, true),
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 3,
         -- MMCM attributes
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => ite(MPS_SLOT_G, 6.4, 8.0),
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => ite(MPS_SLOT_G, 8.0, 10.0),  -- 1.25 GHz
         CLKOUT0_DIVIDE_F_G => 2.0,                         -- 625 MHz = 1.25 GHz/2.0
         CLKOUT1_DIVIDE_G   => 4,                           -- 312.5 MHz = 1.25 GHz/4
         CLKOUT2_DIVIDE_G   => 10)                          -- 125 MHz = 1.25 GHz/10
      port map(
         -- Clock Input
         clkIn  => clk,
         rstIn  => rst,
         -- Clock Outputs
         clkOut => clkOut,
         -- Reset Outputs
         rstOut => rstOut);

   U_ClkOutBufSingle : entity work.ClkOutBufSingle
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         outEnL => ite(MPS_SLOT_G, '0', '1'),
         clkIn  => clkOut(2),
         clkOut => mpsClkOut);    

end mapping;
