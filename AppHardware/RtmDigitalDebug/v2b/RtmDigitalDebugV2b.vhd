-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Board Support: Revision C05 (or later)
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_10_C05
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

entity RtmDigitalDebugV2b is
   generic (
      TPD_G            : time                       := 1 ns;
      PLL_INIT_FILE_G  : string                     := "RtmDigitalDebug_Si5345_LCLS_II.mem";
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
      din                : out   slv(7 downto 0);  -- digital inputs from the RTM: ASYNC (not registered in FPGA or RTM)
      dout               : in    slv(7 downto 0);  -- digital outputs to the RTM: If REG_DOUT_MODE_G[x] = '0', then dout[x] SYNC to recClkOut(0) domain else DOUT driven as clock output.
      cout               : in    slv(7 downto 0);  -- clock outputs to the RTM (REG_DOUT_EN_G(x) = '1' and REG_DOUT_MODE_G(x) = '1')
      -- Clock Jitter Cleaner Interface
      recClkIn           : in    sl;
      recRstIn           : in    sl;
      recClkOut          : out   slv(1 downto 0);
      recRstOut          : out   slv(1 downto 0);
      cleanClkOut        : out   sl;
      cleanRstOut        : out   sl;
      -- Digital I/O Register Interface (axilClk domain)
      axilClk            : in    sl;
      axilRst            : in    sl;
      axilReadMaster     : in    AxiLiteReadMasterType;
      axilReadSlave      : out   AxiLiteReadSlaveType;
      axilWriteMaster    : in    AxiLiteWriteMasterType;
      axilWriteSlave     : out   AxiLiteWriteSlaveType;
      -- Optional RTM's PLL Register Interface (axilClk domain)
      pllRtmReadMaster   : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      pllRtmReadSlave    : out   AxiLiteReadSlaveType;
      pllRtmWriteMaster  : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      pllRtmWriteSlave   : out   AxiLiteWriteSlaveType;
      -- Optional FPGA's PLL DRP Register Interface (axilClk domain)
      pllFpgaReadMaster  : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      pllFpgaReadSlave   : out   AxiLiteReadSlaveType;
      pllFpgaWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      pllFpgaWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------
      -- RTM's Low Speed Ports
      rtmLsP             : inout slv(53 downto 0);
      rtmLsN             : inout slv(53 downto 0);
      --  RTM's Clock Reference
      genClkP            : in    sl;
      genClkN            : in    sl);
end RtmDigitalDebugV2b;

architecture mapping of RtmDigitalDebugV2b is

   type RegType is record
      disable        : slv(7 downto 0);
      debugMode      : slv(7 downto 0);
      debugValue     : slv(7 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      disable        => (others => '0'),
      debugMode      => (others => '0'),
      debugValue     => (others => '0'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clk           : slv(1 downto 0);
   signal rst           : slv(1 downto 0);
   signal pllFpgaLocked : sl;

   signal dinMon      : slv(7 downto 0);
   signal dinMonSync  : slv(7 downto 0);
   signal doutMonSync : slv(7 downto 0);
   signal doutP       : slv(7 downto 0);
   signal doutN       : slv(7 downto 0);
   signal doutClk     : sl;

   signal cleanClock   : sl;
   signal cleanClk     : sl;
   signal cleanRst     : sl;
   signal cleanClkFreq : slv(31 downto 0);
   signal pllRtmLocked : sl;

   -- Prevent optimization of the "cleanClock" signal
   -- such that the IBUFDS termination doesn't get removed
   -- if the cleanClkOut is unused
   attribute keep                     : string;
   attribute keep of cleanClock       : signal is "TRUE";
   attribute dont_touch               : string;
   attribute dont_touch of cleanClock : signal is "TRUE";

begin

   ----------
   -- RTM PLL
   ----------
   U_RTM_PLL : entity surf.Si5345
      generic map (
         TPD_G              => TPD_G,
         MEMORY_INIT_FILE_G => PLL_INIT_FILE_G,
         CLK_PERIOD_G       => 6.4E-9,      -- 1/156.25MHz
         SPI_SCLK_PERIOD_G  => (1/1.0E+6))  -- 1/(1 MHz SCLK)
      port map (
         -- AXI-Lite Register Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => pllRtmReadMaster,
         axiReadSlave   => pllRtmReadSlave,
         axiWriteMaster => pllRtmWriteMaster,
         axiWriteSlave  => pllRtmWriteSlave,
         -- SPI Ports
         coreCsb        => rtmLsP(16),
         coreSclk       => rtmLsN(16),
         coreSDout      => rtmLsP(17),
         coreSDin       => rtmLsN(17));

   -------------------------
   -- OutBound Clock Mapping
   -------------------------
   U_FPGA_PLL : entity surf.ClockManagerUltraScale
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
         locked          => pllFpgaLocked,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => pllFpgaReadMaster,
         axilReadSlave   => pllFpgaReadSlave,
         axilWriteMaster => pllFpgaWriteMaster,
         axilWriteSlave  => pllFpgaWriteSlave);

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
         O => cleanClk);

   cleanClkOut <= cleanClk;

   U_cleanRst : entity surf.RstSync
      generic map(
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',
         OUT_POLARITY_G => '1')
      port map (
         clk      => cleanClk,
         asyncRst => pllRtmLocked,
         syncRst  => cleanRst);

   pllRtmLocked <= rtmLsP(18);
   cleanRstOut  <= cleanRst;

   U_cleanClkFreq : entity surf.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => 156.25E+6,
         REFRESH_RATE_G => 1.0,
         CNT_WIDTH_G    => 32)
      port map (
         -- Frequency Measurement (locClk domain)
         freqOut => cleanClkFreq,
         -- Clocks
         clkIn   => cleanClk,
         locClk  => axilClk,
         refClk  => axilClk);

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
         din     => dinMon);

   din     <= dinMon;
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
         clk        => doutClk,         -- Used for REG_DOUT_EN_G(x) = '1')
         disable    => r.disable,
         debugMode  => r.debugMode,
         debugValue => r.debugValue,
         -- Digital Output Interface
         dout       => dout,
         cout       => cout,
         doutP      => doutP,
         doutN      => doutN);

   GEN_VEC :
   for i in 7 downto 0 generate
      rtmLsP(i+8) <= doutP(i);
      rtmLsN(i+8) <= doutN(i);
   end generate GEN_VEC;

   --------------------------------
   -- Local AXI-Lite Register Space
   --------------------------------
   comb : process (axilReadMaster, axilRst, axilWriteMaster, cleanClkFreq,
                   dinMonSync, doutMonSync, pllFpgaLocked, pllRtmLocked, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"0", 0, v.disable);
      axiSlaveRegister (axilEp, x"0", 8, v.debugMode);
      axiSlaveRegister (axilEp, x"0", 16, v.debugValue);

      axiSlaveRegisterR(axilEp, x"4", 0, dinMonSync);
      axiSlaveRegisterR(axilEp, x"4", 8, doutMonSync);
      axiSlaveRegisterR(axilEp, x"4", 16, pllFpgaLocked);
      axiSlaveRegisterR(axilEp, x"4", 24, pllRtmLocked);

      axiSlaveRegisterR(axilEp, x"8", 0, cleanClkFreq);

      -- Close the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_dinMon : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 8)
      port map (
         clk     => axilClk,
         dataIn  => dinMon,
         dataOut => dinMonSync);

   U_doutMon : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 8)
      port map (
         clk     => axilClk,
         dataIn  => dout,
         dataOut => doutMonSync);

end mapping;
