##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 Common Carrier Core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property PACKAGE_PIN B6 [get_ports rtmHsTxP]
set_property PACKAGE_PIN B5 [get_ports rtmHsTxN]
set_property PACKAGE_PIN A4 [get_ports rtmHsRxP]
set_property PACKAGE_PIN A3 [get_ports rtmHsRxN]

set_property DIFF_TERM_ADV TERM_100 [get_ports {mpsBusRxP[*]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mpsBusRxN[*]}]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_Bufg156/O]] -group [get_clocks -of_objects [get_pins U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_MpsSerdesPll/CLKOUT1]]
