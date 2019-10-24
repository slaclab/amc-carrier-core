-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : DacSigGenTb.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-24
-- Last update: 2016-02-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Converts the 16-bit interface to 32-bit JESD interface
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Common Carrier Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library amc_carrier_core;
use amc_carrier_core.AppTopPkg.all;
use surf.Jesd204bPkg.all;

entity  DacSigGenTb is

end entity ;
--------------------------------------------------------------------------------


architecture Bhv of DacSigGenTb is
  -----------------------------
  -- Port Signals 
  -----------------------------
   constant TPD_G            : time := 1 ns;

   signal   jesdClk          : sl;
   signal   jesdRst          : sl;
   signal   jesdClk2x        : sl;
   signal   jesdRst2x        : sl;
   signal   dacSigCtrl       : DacSigCtrlType  :=DAC_SIG_CTRL_INIT_C;
   signal   dacSigStatus     : DacSigStatusType:=DAC_SIG_STATUS_INIT_C;
   signal   dacSigValids     : slv(6 downto 0);
   signal   dacSigValues     : sampleDataArray(6 downto 0);
   signal   axilClk          : sl;
   signal   axilRst          : sl;
   signal   axilReadMaster    : AxiLiteReadMasterType:= AXI_LITE_READ_MASTER_INIT_C;
   signal   axilReadSlave     : AxiLiteReadSlaveType;
   signal   axilWriteMaster   : AxiLiteWriteMasterType:= AXI_LITE_WRITE_MASTER_INIT_C;
   signal   axilWriteSlave    : AxiLiteWriteSlaveType;

   constant CLK_2X_PERIOD_C   : time := 5 ns;
   constant CLK_PERIOD_C      : time := 10 ns;
   constant CLK_PERIOD_AXI_C  : time := 8 ns;

begin  -- architecture Bhv

   -- Generate clocks and resets
   ClkRst : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 1 ns,     -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => jesdClk,
         clkN => open,
         rst  => jesdRst,--rst,
         rstL => open); 
         
      -- Generate clocks and resets
   ClkRst_2x : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_2X_PERIOD_C,
         RST_START_DELAY_G => 1 ns,     -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => jesdClk2x,
         clkN => open,
         rst  => jesdRst2x,--rst2x,
         rstL => open); 

     -- Generate clocks and resets
   ClkRst_axi : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_AXI_C,
         RST_START_DELAY_G => 1 ns,     -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => axilClk,
         clkN => open,
         rst  => axilRst,--rst2x,
         rstL => open);

  -----------------------------
  -- component instantiation 
  -----------------------------
  DacSigGen_INST: entity amc_carrier_core.DacSigGen
   generic map (
      TPD_G            => TPD_G,
      NUM_SIG_GEN_G    => 2,
      ADDR_WIDTH_G     => 9,
      INTERFACE_G      => '0')
   port map (
      jesdClk         => jesdClk,
      jesdRst         => jesdRst,
      jesdClk2x       => jesdClk2x,
      jesdRst2x       => jesdRst2x,
      dacSigCtrl      => dacSigCtrl,
      dacSigStatus    => dacSigStatus,
      dacSigValids    => dacSigValids,
      dacSigValues    => dacSigValues,
      axilClk         => axilClk,
      axilRst         => axilRst,
      axilReadMaster  => axilReadMaster,
      axilReadSlave   => axilReadSlave,
      axilWriteMaster => axilWriteMaster,
      axilWriteSlave  => axilWriteSlave);

	
  StimuliProcess : process
  begin
      wait until jesdRst2x = '0';
      wait for 250*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '1');
      wait for 10*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '0');
      wait for 100*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '1');
      wait for 10*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '0');
      wait for 100*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '1');
      wait for 10*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '0');
      wait for 100*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '1');
      wait for 10*CLK_2X_PERIOD_C;
      dacSigCtrl.start <= (others => '0');      
  end process StimuliProcess;
  
end architecture Bhv;