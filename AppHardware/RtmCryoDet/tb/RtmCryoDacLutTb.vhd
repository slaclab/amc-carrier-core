-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the RtmCryoDacLutTb module
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
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

library amc_carrier_core; 

entity RtmCryoDacLutTb is end RtmCryoDacLutTb;

architecture testbed of RtmCryoDacLutTb is

   constant CLK_PERIOD_G : time := 4 ns;
   constant TPD_G        : time := CLK_PERIOD_G/4;

   signal axilClk         : sl                     := '0';
   signal axilClkL        : sl                     := '1';
   signal axilRst         : sl                     := '0';
   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;

   signal rtmLsP : slv(53 downto 0) := (others => 'Z');
   signal rtmLsN : slv(53 downto 0) := (others => 'Z');

begin

   --------------------
   -- Clocks and Resets
   --------------------
   U_axilClk : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_G,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1000 ns)
      port map (
         clkP => axilClk,
         clkN => axilClkL,
         rst  => axilRst);

   -----------------------
   -- Module to be tested
   -----------------------
   U_RtmCryoDet : entity amc_carrier_core.RtmCryoDet
      generic map (
         TPD_G           => TPD_G,
         SIMULATION_G    => true,
         AXI_BASE_ADDR_G => (others => '0'))
      port map (
         -- JESD Clock Reference
         jesdClk         => axilClk,
         jesdRst         => axilRst,
         -- Timing trigger
         timingTrig      => '0',
         -- Digital I/O Interface
         startRamp       => open,
         selectRamp      => open,
         rampCnt         => open,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -----------------------
         -- Application Ports --
         -----------------------      
         -- RTM's Low Speed Ports
         rtmLsP          => rtmLsP,
         rtmLsN          => rtmLsN,
         --  RTM's Clock Reference
         genClkP         => axilClk,
         genClkN         => axilClkL);

   ---------------------------------
   -- AXI-Lite Register Transactions
   ---------------------------------
   test : process is
      variable debugData : slv(31 downto 0) := (others => '0');
   begin
      debugData := x"1111_1111";
      wait until axilRst = '1';
      wait until axilRst = '0';

      -- dacAxilAddr(0) = 0x00020000
      axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0030_0000", x"0020_0000", true);

      -- dacAxilAddr(1) = 0x00020004
      axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0030_0004", x"0020_0004", true);

      -- timerSize = 0xFF
      axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0030_0048", x"0000_00FF", true);

      -- -- maxAddr = 0x0
      -- axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0030_0044", x"0000_0000", true);    
      
      -- enableCh = 0x1
      axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0030_0044", x"0000_0001", true);          
      
      -- continuous = 0x1
      axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0030_0040", x"0000_0001", true);

      while (true) loop

         -- Write to dacAxilAddr(0)
         axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0020_0000", x"0000_0000", false);

         -- Read from dacAxilAddr(0)
         axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0020_0000", debugData, false);

      end loop;

   end process test;

end testbed;
