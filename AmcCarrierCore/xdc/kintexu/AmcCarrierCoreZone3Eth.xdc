##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######################
## Common Core Ports ##
#######################

# ETH Ports (Mapping to RTM's High Speed Ports rtmHsTxP/M & rtmHsRxP/M)
set_property PACKAGE_PIN B6 [get_ports {ethTxP[0]}]
set_property PACKAGE_PIN B5 [get_ports {ethTxN[0]}]
set_property PACKAGE_PIN A4 [get_ports {ethRxP[0]}]
set_property PACKAGE_PIN A3 [get_ports {ethRxN[0]}]

#############################
## Core Timing Constraints ##
#############################
 
create_generated_clock -name ethClk125MHz  [get_pins {U_Core/U_Core/U_Eth/ETH_ZONE3.U_Rtm/GEN_INT_PLL.U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name ethClk62p5MHz [get_pins {U_Core/U_Core/U_Eth/ETH_ZONE3.U_Rtm/GEN_INT_PLL.U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}] 
set_clock_groups -asynchronous -group [get_clocks {ethRef}] -group [get_clocks {ethClk125MHz}] 
set_clock_groups -asynchronous -group [get_clocks {ethRef}] -group [get_clocks {ethClk62p5MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethClk125MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethClk62p5MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethRef}] 

