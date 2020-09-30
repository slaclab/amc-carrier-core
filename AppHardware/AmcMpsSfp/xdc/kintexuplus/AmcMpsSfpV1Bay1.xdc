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

set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][0]}] ; #
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][0]}] ; #
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][0]}] ; #
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][0]}] ; #
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][1]}] ; #
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][1]}] ; #
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][1]}] ; #
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][1]}] ; #
set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][2]}] ; #
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][2]}] ; #
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][2]}] ; #
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][2]}] ; #
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][3]}] ; #
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][3]}] ; #
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][3]}] ; #
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][3]}] ; #
set_property PACKAGE_PIN U4 [get_ports {jesdTxP[1][4]}] ; #
set_property PACKAGE_PIN U3 [get_ports {jesdTxN[1][4]}] ; #
set_property PACKAGE_PIN T2 [get_ports {jesdRxP[1][4]}] ; #
set_property PACKAGE_PIN T1 [get_ports {jesdRxN[1][4]}] ; #
set_property PACKAGE_PIN R4 [get_ports {jesdTxP[1][5]}] ; #
set_property PACKAGE_PIN R3 [get_ports {jesdTxN[1][5]}] ; #
set_property PACKAGE_PIN P2 [get_ports {jesdRxP[1][5]}] ; #
set_property PACKAGE_PIN P1 [get_ports {jesdRxN[1][5]}] ; #
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][6]}] ; #
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][6]}] ; #
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][6]}] ; #
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][6]}] ; #
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][7]}] ; #
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][7]}] ; #
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][7]}] ; #
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][7]}] ; #
set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][8]}] ; #
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][8]}] ; #
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][8]}] ; #
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][8]}] ; #
set_property PACKAGE_PIN B6 [get_ports {jesdTxP[1][9]}] ; #
set_property PACKAGE_PIN B5 [get_ports {jesdTxN[1][9]}] ; #
set_property PACKAGE_PIN A4 [get_ports {jesdRxP[1][9]}] ; #
set_property PACKAGE_PIN A3 [get_ports {jesdRxN[1][9]}] ; #
