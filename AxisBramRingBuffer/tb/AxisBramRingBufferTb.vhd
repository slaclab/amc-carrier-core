-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for DaqMuxV2
------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 Common Carrier Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library amc_carrier_core;

entity AxisBramRingBufferTb is
end entity;

architecture testbed of AxisBramRingBufferTb is

   constant CLK_PERIOD_C : time := 10 ns;
   constant TPD_G        : time := (CLK_PERIOD_C/4);

   signal clk  : sl := '0';
   signal rst  : sl := '0';
   signal trig : sl := '0';

   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;
   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;

begin

   U_ClkRst : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 1 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk,
         rst  => rst);

   ----------------------
   -- Module to be tested
   ----------------------
   U_Core : entity amc_carrier_core.AxisBramFlashBuffer
      generic map (
         TPD_G          => TPD_G,
         NUM_CH_G       => 4,
         BUFFER_WIDTH_G => 8)
      port map (
         -- Input Data Interface (appClk domain)
         appClk          => clk,
         appRst          => rst,
         apptrig         => trig,
         appValid        => (others => '1'),
         appData         => (others => x"0000_0000"),
         -- Input timing interface (timingClk domain)
         timingClk       => clk,
         timingRst       => rst,
         timingTimestamp => (others => '0'),
         -- Output AXIS Interface (axisClk domain)
         axisClk         => clk,
         axisRst         => rst,
         axisMaster      => open,
         axisSlave       => AXI_STREAM_SLAVE_FORCE_C,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => clk,
         axilRst         => rst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   test : process is
   begin
      trig <= '0';
      wait until rst = '1';
      wait until rst = '0';

      axiLiteBusSimWrite(clk, axilWriteMaster, axilWriteSlave, x"0000_0000", x"0000_0080", true);
      axiLiteBusSimWrite(clk, axilWriteMaster, axilWriteSlave, x"0000_0004", x"0000_0081", true);
      axiLiteBusSimWrite(clk, axilWriteMaster, axilWriteSlave, x"0000_0008", x"0000_0082", true);
      axiLiteBusSimWrite(clk, axilWriteMaster, axilWriteSlave, x"0000_000C", x"0000_0083", true);
      axiLiteBusSimWrite(clk, axilWriteMaster, axilWriteSlave, x"0000_00FC", x"0000_0001", true);
      axiLiteBusSimWrite(clk, axilWriteMaster, axilWriteSlave, x"0000_00F8", x"0000_0001", true);

      wait for 100 us;
      trig <= '1';
      wait for 100 ns;
      trig <= '0';

   end process test;

end testbed;
