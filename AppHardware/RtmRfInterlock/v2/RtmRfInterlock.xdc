##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[9]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[9]}]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[14]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[14]}]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[19]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[19]}]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[18]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[18]}]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[3]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[3]}]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[8]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[8]}]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[6]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[6]}]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[7]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[7]}]

# Clocks
create_clock -period 2.801 -name rtmAdcDataClk [get_ports {rtmLsP[3]}]
create_generated_clock -name rtmAdcDataClkDiv2 [get_pins {U_AppTop/U_AppCore/U_RTM/U_CORE/U_Ad9229Core/U_BUFGCE_DIV/O}]
create_generated_clock -name recTimingClkDiv2  [get_pins {U_AppTop/U_AppCore/U_RTM/U_CORE/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]

set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks {rtmAdcDataClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {rtmAdcDataClk}]
set_clock_groups -asynchronous -group [get_clocks {recTimingClkDiv2}] -group [get_clocks {rtmAdcDataClk}]
set_clock_groups -asynchronous -group [get_clocks {recTimingClkDiv2}] -group [get_clocks {rtmAdcDataClkDiv2}]
set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks {rtmAdcDataClkDiv2}]
