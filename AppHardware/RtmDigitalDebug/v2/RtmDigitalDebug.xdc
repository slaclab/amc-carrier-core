##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[0]}] ; # To PLL
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[0]}] ; # To PLL

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[1]}] ; # From PLL
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[1]}] ; # From PLL

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[8]}] ; # dout[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[8]}] ; # dout[0]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[9]}] ; # dout[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[9]}] ; # dout[1]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[10]}] ; # dout[2]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[10]}] ; # dout[2]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[11]}] ; # dout[3]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[11]}] ; # dout[3]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[12]}] ; # dout[4]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[12]}] ; # dout[4]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[13]}] ; # dout[5]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[13]}] ; # dout[5]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[14]}] ; # dout[6]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[14]}] ; # dout[6]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[15]}] ; # dout[7]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[15]}] ; # dout[7]

set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks -of_objects [get_pins -hier -filter {NAME =~ */U_RTM/U_PLL/PllGen.U_Pll/CLKOUT1}]]