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

set_property PACKAGE_PIN N29 [get_ports {jesdClkP[0][3]}] ; #P11 PIN88 
set_property PACKAGE_PIN N30 [get_ports {jesdClkN[0][3]}] ; #P11 PIN87 
set_property PACKAGE_PIN J29 [get_ports {jesdClkP[1][3]}] ; #P13 PIN88
set_property PACKAGE_PIN J30 [get_ports {jesdClkN[1][3]}] ; #P13 PIN87

create_clock -name jesdClk00 -period 3.2 [get_ports {jesdClkP[0][0]}]
create_clock -name jesdClk01 -period 3.2 [get_ports {jesdClkP[0][1]}]
create_clock -name jesdClk02 -period 3.2 [get_ports {jesdClkP[0][2]}]
create_clock -name jesdClk03 -period 3.2 [get_ports {jesdClkP[0][3]}]
create_clock -name jesdClk10 -period 3.2 [get_ports {jesdClkP[1][0]}]
create_clock -name jesdClk11 -period 3.2 [get_ports {jesdClkP[1][1]}]
create_clock -name jesdClk12 -period 3.2 [get_ports {jesdClkP[1][2]}]
create_clock -name jesdClk13 -period 3.2 [get_ports {jesdClkP[1][3]}]
