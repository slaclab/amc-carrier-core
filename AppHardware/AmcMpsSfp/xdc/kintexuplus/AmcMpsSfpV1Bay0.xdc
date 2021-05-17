##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 Common Carrier Core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkP[0][0]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkN[0][0]}]

set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][0]}] ; #
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][0]}] ; #
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][0]}] ; #
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][0]}] ; #
set_property PACKAGE_PIN AK6 [get_ports {jesdTxP[0][1]}] ; #
set_property PACKAGE_PIN AK5 [get_ports {jesdTxN[0][1]}] ; #
set_property PACKAGE_PIN AJ4 [get_ports {jesdRxP[0][1]}] ; #
set_property PACKAGE_PIN AJ3 [get_ports {jesdRxN[0][1]}] ; #
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][2]}] ; #
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][2]}] ; #
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][2]}] ; #
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][2]}] ; #
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][3]}] ; #
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][3]}] ; #
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][3]}] ; #
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][3]}] ; #
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][4]}] ; #
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][4]}] ; #
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][4]}] ; #
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][4]}] ; #
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][5]}] ; #
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][5]}] ; #
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][5]}] ; #
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][5]}] ; #
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][6]}] ; #
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][6]}] ; #
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][6]}] ; #
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][6]}] ; #
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][7]}] ; #
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][7]}] ; #
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][7]}] ; #
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][7]}] ; #
set_property PACKAGE_PIN AA4 [get_ports {jesdTxP[0][8]}] ; #
set_property PACKAGE_PIN AA3 [get_ports {jesdTxN[0][8]}] ; #
set_property PACKAGE_PIN Y2  [get_ports {jesdRxP[0][8]}] ; #
set_property PACKAGE_PIN Y1  [get_ports {jesdRxN[0][8]}] ; #
set_property PACKAGE_PIN W4  [get_ports {jesdTxP[0][9]}] ; #
set_property PACKAGE_PIN W3  [get_ports {jesdTxN[0][9]}] ; #
set_property PACKAGE_PIN V2  [get_ports {jesdRxP[0][9]}] ; #
set_property PACKAGE_PIN V1  [get_ports {jesdRxN[0][9]}] ; #
