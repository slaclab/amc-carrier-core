-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Testbench for design "AxiLiteAsync"
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

library surf;
use surf.StdRtlPkg.all;
use surf.TextUtilPkg.all;
use surf.AxiLitePkg.all;

library amc_carrier_core; 

entity Adf5355Tb is
end entity Adf5355Tb;
architecture tb of Adf5355Tb is

   constant TPD_G : time := 1 ns;

   signal axilClk : sl;
   signal axilRst : sl;

   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;
   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;

begin

   U_ClkRst : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 10 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 1 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => axilClk,
         rst  => axilRst);

   U_PLL : entity amc_carrier_core.adf5355
      generic map (
         TPD_G             => TPD_G)
      port map (
         -- Clock and Reset
         axiClk         => axilClk,
         axiRst         => axilRst,
         -- AXI-Lite Interface
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave,
         -- Multiple Chip Support
         busyIn         => '0',
         busyOut        => open,
         -- SPI Interface
         coreSclk       => open,
         coreSDout      => open,
         coreCsb        => open);

   test : process is
      variable addr : slv(31 downto 0) := (others => '0');
      variable data : slv(31 downto 0) := (others => '0');
   begin
      wait until axilRst = '1';
      wait until axilRst = '0';


      wait for 5 us;
      wait until axilClk = '1';

      data := X"11111111";
      axiLiteBusSimWrite(axilClk, axilWriteMaster, axilWriteSlave, X"00000000", X"FFFFFFFF", true);
      axiLiteBusSimWrite(axilClk, axilWriteMaster, axilWriteSlave, X"00000004", X"12345678", true);
      axiLiteBusSimWrite(axilClk, axilWriteMaster, axilWriteSlave, X"00000008", X"87654321", true);

      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"00000000", data, true);
      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"00000004", data, true);
      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"00000008", data, true);
      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"0000000C", data, true);

      wait until axilRst = '0';
      wait for 10 us;
      wait until axilClk = '1';

      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"00000000", data, true);
      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"00000004", data, true);
      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"00000008", data, true);
      axiLiteBusSimRead(axilClk, axilReadMaster, axilReadSlave, X"0000000C", data, true);

   end process test;

end architecture tb;
