##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#############################
## Core Timing Constraints ##
#############################
 
set_property CLOCK_DEDICATED_ROUTE FALSE    [get_nets -hier -filter {NAME =~ *U_DdrMem/refClock}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets -hier -filter {NAME =~ *U_DdrMem/refClkBufg}]

create_clock -name ddrClkIn   -period  5.000  [get_pins -hier -filter {NAME =~ *U_DdrMem/BUFG_Inst/O}]
create_clock -name fabClk     -period  6.400  [get_ports {fabClkP}]
create_clock -name ethRef     -period  6.400  [get_ports {ethClkP}]
create_clock -name timingRef  -period  2.691  [get_ports {timingRefClkInP}]

create_generated_clock -name axilClk      [get_pins -hier -filter {NAME =~ *U_AmcCorePll/PllGen.U_Pll/CLKOUT0}] 
create_generated_clock -name ddrIntClk0   [get_pins -hier -filter {NAME =~ *U_DdrMem/MigCore_Inst/inst/u_ddr3_infrastructure/gen_mmcme3.u_mmcme_adv_inst/CLKOUT0}]
create_generated_clock -name ddrIntClk1   [get_pins -hier -filter {NAME =~ *U_DdrMem/MigCore_Inst/inst/u_ddr3_infrastructure/gen_mmcme3.u_mmcme_adv_inst/CLKOUT6}]
create_generated_clock -name recTimingClk [get_pins -hier -filter {NAME =~ *U_Timing/TimingGthCoreWrapper_1/*/RXOUTCLK}]   

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ddrClkIn}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ddrIntClk1}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks -include_generated_clocks {timingRef}]
set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks {axilClk}] 
set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {ddrClkIn}] -group [get_clocks {ddrIntClk0}]
set_clock_groups -asynchronous -group [get_clocks {ddrClkIn}] -group [get_clocks {ddrIntClk1}]

################################
## Wrapper Timing Constraints ##
################################

create_generated_clock -name iprogClk -divide_by 8 -source [get_pins {U_Core/U_SysReg/U_Iprog/GEN_ULTRA_SCALE.IprogUltraScale_Inst/BUFGCE_DIV_Inst/I}] [get_pins {U_Core/U_SysReg/U_Iprog/GEN_ULTRA_SCALE.IprogUltraScale_Inst/BUFGCE_DIV_Inst/O}]
create_generated_clock -name dnaClk -divide_by 8 -source [get_pins {U_Core/U_SysReg/U_Version/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/I}] [get_pins {U_Core/U_SysReg/U_Version/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/O}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {iprogClk}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {dnaClk}]

create_generated_clock -name jesd0_185MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd0_370MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name jesd1_185MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd1_370MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

create_generated_clock -name mpsClk625MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name mpsClk312MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT1}] 
create_generated_clock -name mpsClk125MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT2}] 

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdClk00}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdClk01}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdClk02}] 

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdClk10}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdClk11}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdClk12}] 

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {jesd1_185MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {jesd1_370MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {jesd1_185MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {jesd1_370MHz}] 

set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks {jesd0_185MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks {jesd0_370MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_370MHz}] -group [get_clocks {jesd0_185MHz}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_370MHz}] -group [get_clocks {jesd0_370MHz}] 

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {recTimingClk}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {axilClk}] 

set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {recTimingClk}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {axilClk}] 

set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks {recTimingClk}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks {axilClk}] 

set_clock_groups -asynchronous -group [get_clocks {jesd1_370MHz}] -group [get_clocks {recTimingClk}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_370MHz}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {jesd1_370MHz}] -group [get_clocks {axilClk}] 

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {mpsClk125MHz}] 
