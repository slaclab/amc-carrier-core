##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 AMC Carrier Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_clock -name mpsClkIn     -period 8.000  [get_ports {mpsClkIn}]
create_clock -name mpsClkThresh -period 16.000 [get_pins {U_Core/U_AppMps/U_Clk/U_PLL/PllGen.U_Pll/CLKOUT0}]

create_generated_clock -name mpsClk625MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name mpsClk312MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT1}] 
create_generated_clock -name mpsClk125MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT2}] 

set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {mpsClk625MHz}]
set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {mpsClk312MHz}]
set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {mpsClk125MHz}]

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {mpsClk125MHz}] 

create_generated_clock -name jesd0_185MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd0_370MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

create_generated_clock -name jesd1_185MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd1_370MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}]  -group [get_clocks {jesd1_185MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}]  -group [get_clocks {jesd1_370MHz}] 

set_clock_groups -asynchronous \
   -group [get_clocks -include_generated_clocks {fabClk}] \
   -group [get_clocks -include_generated_clocks {recTimingClk}] \   
   -group [get_clocks -include_generated_clocks {ddrClkIn}] \
   -group [get_clocks -include_generated_clocks {mpsClkIn}] \
   -group [get_clocks -include_generated_clocks {mpsClkThresh}] \
   -group [get_clocks -include_generated_clocks {ethRef}] \
   -group [get_clocks -include_generated_clocks {jesdClk00}] \
   -group [get_clocks -include_generated_clocks {jesdClk01}] \
   -group [get_clocks -include_generated_clocks {jesdClk02}] \
   -group [get_clocks -include_generated_clocks {jesdClk10}] \
   -group [get_clocks -include_generated_clocks {jesdClk11}] \
   -group [get_clocks -include_generated_clocks {jesdClk12}]
