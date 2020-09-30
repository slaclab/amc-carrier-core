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

# ETH Ports
set_property PACKAGE_PIN AA4 [get_ports {ethTxP[0]}]
set_property PACKAGE_PIN AA3 [get_ports {ethTxN[0]}]
set_property PACKAGE_PIN Y2  [get_ports {ethRxP[0]}]
set_property PACKAGE_PIN Y1  [get_ports {ethRxN[0]}]
set_property PACKAGE_PIN W4  [get_ports {ethTxP[1]}]
set_property PACKAGE_PIN W3  [get_ports {ethTxN[1]}]
set_property PACKAGE_PIN V2  [get_ports {ethRxP[1]}]
set_property PACKAGE_PIN V1  [get_ports {ethRxN[1]}]
set_property PACKAGE_PIN U4  [get_ports {ethTxP[2]}]
set_property PACKAGE_PIN U3  [get_ports {ethTxN[2]}]
set_property PACKAGE_PIN T2  [get_ports {ethRxP[2]}]
set_property PACKAGE_PIN T1  [get_ports {ethRxN[2]}]
set_property PACKAGE_PIN R4  [get_ports {ethTxP[3]}]
set_property PACKAGE_PIN R3  [get_ports {ethTxN[3]}]
set_property PACKAGE_PIN P2  [get_ports {ethRxP[3]}]
set_property PACKAGE_PIN P1  [get_ports {ethRxN[3]}]

# #############################
# ## Core Timing Constraints ##
# #############################

create_generated_clock -name ethPhyClk    [get_pins -hier -filter {name =~ U_Core/U_Core/U_Eth/ETH_ZONE2.U_Xaui/XauiGthUltraScale_Inst/*/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethPhyClk}]
