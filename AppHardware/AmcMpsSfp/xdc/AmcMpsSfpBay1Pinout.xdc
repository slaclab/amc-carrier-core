##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkP[1][0]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkN[1][0]}]

set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][0]}]; #P13 PIN32
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][0]}]; #P13 PIN33
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][0]}]; #P13 PIN29
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][0]}]; #P13 PIN30
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][1]}]; #P13 PIN38
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][1]}]; #P13 PIN39
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][1]}]; #P13 PIN35
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][1]}]; #P13 PIN36
set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][2]}]; #P13 PIN47
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][2]}]; #P13 PIN48
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][2]}]; #P13 PIN44
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][2]}]; #P13 PIN45
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][3]}]; #P13 PIN53
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][3]}]; #P13 PIN54
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][3]}]; #P13 PIN50
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][3]}]; #P13 PIN51
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][4]}]; #P13 PIN62
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][4]}]; #P13 PIN63
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][4]}]; #P13 PIN59
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][4]}]; #P13 PIN60
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][5]}]; #P13 PIN68
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][5]}]; #P13 PIN69
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][5]}]; #P13 PIN65
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][5]}]; #P13 PIN66
set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][6]}]; #P14 PIN53
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][6]}]; #P14 PIN54
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][6]}]; #P14 PIN50
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][6]}]; #P14 PIN51