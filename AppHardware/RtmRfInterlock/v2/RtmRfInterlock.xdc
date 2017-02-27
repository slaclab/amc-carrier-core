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
