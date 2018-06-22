##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 AMC Carrier Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
#######################
## Application Ports ##
#######################

set_property PACKAGE_PIN T31 [get_ports {jesdTxP[0][7]}] ; #
set_property PACKAGE_PIN T32 [get_ports {jesdTxN[0][7]}] ; #
set_property PACKAGE_PIN R33 [get_ports {jesdRxP[0][7]}] ; #
set_property PACKAGE_PIN R34 [get_ports {jesdRxN[0][7]}] ; #
set_property PACKAGE_PIN P31 [get_ports {jesdTxP[0][8]}] ; #
set_property PACKAGE_PIN P32 [get_ports {jesdTxN[0][8]}] ; #
set_property PACKAGE_PIN N33 [get_ports {jesdRxP[0][8]}] ; #
set_property PACKAGE_PIN N34 [get_ports {jesdRxN[0][8]}] ; #
set_property PACKAGE_PIN M31 [get_ports {jesdTxP[0][9]}] ; #
set_property PACKAGE_PIN M32 [get_ports {jesdTxN[0][9]}] ; #
set_property PACKAGE_PIN L33 [get_ports {jesdRxP[0][9]}] ; #
set_property PACKAGE_PIN L34 [get_ports {jesdRxN[0][9]}] ; #

set_property PACKAGE_PIN H31 [get_ports {jesdTxP[1][7]}] ; #
set_property PACKAGE_PIN H32 [get_ports {jesdTxN[1][7]}] ; #
set_property PACKAGE_PIN G33 [get_ports {jesdRxP[1][7]}] ; #
set_property PACKAGE_PIN G34 [get_ports {jesdRxN[1][7]}] ; #
set_property PACKAGE_PIN G29 [get_ports {jesdTxP[1][8]}] ; #
set_property PACKAGE_PIN G30 [get_ports {jesdTxN[1][8]}] ; #
set_property PACKAGE_PIN F31 [get_ports {jesdRxP[1][8]}] ; #
set_property PACKAGE_PIN F32 [get_ports {jesdRxN[1][8]}] ; #
set_property PACKAGE_PIN D31 [get_ports {jesdTxP[1][9]}] ; #
set_property PACKAGE_PIN D32 [get_ports {jesdTxN[1][9]}] ; #
set_property PACKAGE_PIN E33 [get_ports {jesdRxP[1][9]}] ; #
set_property PACKAGE_PIN E34 [get_ports {jesdRxN[1][9]}] ; #

set_property PACKAGE_PIN N29 [get_ports {jesdClkP[0][3]}] ; #P11 PIN88 
set_property PACKAGE_PIN N30 [get_ports {jesdClkN[0][3]}] ; #P11 PIN87 
set_property PACKAGE_PIN J29 [get_ports {jesdClkP[1][3]}] ; #P13 PIN88
set_property PACKAGE_PIN J30 [get_ports {jesdClkN[1][3]}] ; #P13 PIN87

create_clock -name jesdClk00 -period 3.255 [get_ports {jesdClkP[0][0]}]
create_clock -name jesdClk01 -period 3.255 [get_ports {jesdClkP[0][1]}]
create_clock -name jesdClk02 -period 3.255 [get_ports {jesdClkP[0][2]}]
create_clock -name jesdClk03 -period 3.255 [get_ports {jesdClkP[0][3]}]
create_clock -name jesdClk10 -period 3.255 [get_ports {jesdClkP[1][0]}]
create_clock -name jesdClk11 -period 3.255 [get_ports {jesdClkP[1][1]}]
create_clock -name jesdClk12 -period 3.255 [get_ports {jesdClkP[1][2]}]
create_clock -name jesdClk13 -period 3.255 [get_ports {jesdClkP[1][3]}]
