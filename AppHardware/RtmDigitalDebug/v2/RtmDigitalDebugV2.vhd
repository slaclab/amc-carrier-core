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
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

library amc_carrier_core; 

entity RtmDigitalDebugV2 is
   generic (
      TPD_G            : time                       := 1 ns;
      REG_DOUT_EN_G    : slv(7 downto 0)            := x"00";  -- '1' = registered, '0' = unregistered
      REG_DOUT_MODE_G  : slv(7 downto 0)            := x"00";  -- If registered enabled, '1' = "cout" output, '0' = "dout" output
      DIVCLK_DIVIDE_G  : positive                   := 1;
      CLKFBOUT_MULT_G  : positive                   := 6;
      CLKOUT0_DIVIDE_G : positive                   := 6;
      CLKOUT1_DIVIDE_G : positive                   := 6;  -- drives the RTM's jitter clean input clock port
      CLKOUT0_PHASE_G  : real range -360.0 to 360.0 := 0.0;
      CLKOUT1_PHASE_G  : real range -360.0 to 360.0 := 0.0);
   port (
      -- Digital I/O Interface
      din             : out   slv(7 downto 0);  -- digital inputs from the RTM: ASYNC (not registered in FPGA or RTM)  
      dout            : in    slv(7 downto 0);  -- digital outputs to the RTM: If REG_DOUT_MODE_G[x] = '0', then dout[x] SYNC to recClkOut(0) domain else DOUT driven as clock output.
      cout            : in    slv(7 downto 0);  -- clock outputs to the RTM (REG_DOUT_EN_G(x) = '1' and REG_DOUT_MODE_G(x) = '1')
      -- Clock Jitter Cleaner Interface
      recClkIn        : in    sl;
      recRstIn        : in    sl;
      recClkOut       : out   slv(1 downto 0);
      recRstOut       : out   slv(1 downto 0);
      cleanClkOut     : out   sl;
      cleanClkLocked  : out   sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Optional FPGA's PLL DRP Interface (axilClk domain)
      pllReadMaster   : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      pllReadSlave    : out   AxiLiteReadSlaveType;
      pllWriteMaster  : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      pllWriteSlave   : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- RTM's Low Speed Ports
      rtmLsP          : inout slv(53 downto 0);
      rtmLsN          : inout slv(53 downto 0);
      --  RTM's Clock Reference
      genClkP         : in    sl;
      genClkN         : in    sl);
end RtmDigitalDebugV2;

architecture mapping of RtmDigitalDebugV2 is

   signal clk          : slv(1 downto 0);
   signal rst          : slv(1 downto 0);
   signal userValueIn  : slv(31 downto 0);
   signal userValueOut : slv(31 downto 0);
   signal doutP        : slv(7 downto 0);
   signal doutN        : slv(7 downto 0);
   signal doutClk      : sl;
   signal cleanClock   : sl;


   signal pllBwSel  : slv(1 downto 0);
   signal pllFrqSel : slv(3 downto 0);


   -- Prevent optimization of the "cleanClock" signal
   -- such that the IBUFDS termination doesn't get removed
   -- if the cleanClkOut is unused
   attribute keep                     : string;
   attribute keep of cleanClock       : signal is "TRUE";
   attribute dont_touch               : string;
   attribute dont_touch of cleanClock : signal is "TRUE";

begin

   -------------------------        
   -- OutBound Clock Mapping
   -------------------------        
   U_PLL : entity surf.ClockManagerUltraScale
      generic map (
         TPD_G            => TPD_G,
         TYPE_G           => "PLL",
         INPUT_BUFG_G     => false,
         FB_BUFG_G        => true,
         NUM_CLOCKS_G     => 2,
         DIVCLK_DIVIDE_G  => DIVCLK_DIVIDE_G,
         CLKFBOUT_MULT_G  => CLKFBOUT_MULT_G,
         CLKOUT0_DIVIDE_G => CLKOUT0_DIVIDE_G,
         CLKOUT1_DIVIDE_G => CLKOUT1_DIVIDE_G,
         CLKOUT0_PHASE_G  => CLKOUT0_PHASE_G,
         CLKOUT1_PHASE_G  => CLKOUT1_PHASE_G)
      port map (
         clkIn           => recClkIn,
         rstIn           => recRstIn,
         clkOut          => clk,
         rstOut          => rst,
         locked          => userValueIn(0),
         -- AXI-Lite Interface 
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => pllReadMaster,
         axilReadSlave   => pllReadSlave,
         axilWriteMaster => pllWriteMaster,
         axilWriteSlave  => pllWriteSlave);

   userValueIn(31 downto 1) <= (others => '0');

   U_CLK : entity surf.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => clk(1),  -- drives the RTM's jitter clean input clock port
         clkOutP => rtmLsP(0),
         clkOutN => rtmLsN(0));

   recClkOut <= clk;
   recRstOut <= rst;

   -------------------------        
   -- Inbound Clock Mapping
   -------------------------               
   U_IBUFDS : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map(
         I  => rtmLsP(1),
         IB => rtmLsN(1),
         O  => cleanClock);

   U_BUFG : BUFG
      port map (
         I => cleanClock,
         O => cleanClkOut);

   ------------------------
   -- Digital Input Mapping
   ------------------------
   U_DIN : entity amc_carrier_core.RtmDigitalDebugDin
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Digital Input Interface
         xDin(0) => rtmLsP(2),
         xDin(1) => rtmLsN(2),
         xDin(2) => rtmLsP(3),
         xDin(3) => rtmLsN(3),
         xDin(4) => rtmLsP(4),
         xDin(5) => rtmLsN(4),
         xDin(6) => rtmLsP(5),
         xDin(7) => rtmLsN(5),
         din     => din);

   doutClk <= not clk(0);
   
   -------------------------
   -- Digital Output Mapping
   -------------------------         
   U_DOUT : entity amc_carrier_core.RtmDigitalDebugDout
      generic map (
         TPD_G           => TPD_G,
         REG_DOUT_EN_G   => REG_DOUT_EN_G,
         REG_DOUT_MODE_G => REG_DOUT_MODE_G)
      port map (
         clk     => doutClk,             -- Used for REG_DOUT_EN_G(x) = '1')
         disable => userValueOut(7 downto 0),
         -- Digital Output Interface
         dout    => dout,
         cout    => cout,
         doutP   => doutP,
         doutN   => doutN);

   GEN_VEC :
   for i in 7 downto 0 generate
      rtmLsP(i+8) <= doutP(i);
      rtmLsN(i+8) <= doutN(i);
   end generate GEN_VEC;

   ---------------------
   -- Register Interface
   ---------------------
   U_REG : entity amc_carrier_core.Si5317a
      generic map (
         TPD_G => TPD_G)
      port map(
         -- PLL Parallel Interface
         pllLol          => rtmLsP(18),
         pllLos          => rtmLsN(18),
         pllRstL         => rtmLsP(19),
         pllInc          => open,       -- Hard wired on the RTM
         pllDec          => open,       -- Hard wired on the RTM
         pllFrqTbl       => open,       -- Hard wired on the RTM
         pllBypass       => open,       -- Hard wired on the RTM
         pllRate         => open,       -- Hard wired on the RTM
         pllSFout        => open,       -- Hard wired on the RTM
         pllBwSel        => pllBwSel,
         pllFrqSel       => pllFrqSel,
         pllLocked       => cleanClkLocked,
         -- Misc Interface
         userValueIn     => userValueIn,
         userValueOut    => userValueOut,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   rtmLsP(7)  <= pllBwSel(0);
   rtmLsN(7)  <= pllBwSel(1);
   rtmLsP(16) <= pllFrqSel(0);
   rtmLsN(16) <= pllFrqSel(1);
   rtmLsP(17) <= pllFrqSel(2);
   rtmLsN(17) <= pllFrqSel(3);

end mapping;
