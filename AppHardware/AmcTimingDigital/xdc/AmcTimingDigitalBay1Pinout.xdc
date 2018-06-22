##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# Timing Digital I/O

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[1][0]}]

set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[1][1]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[1][1]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[1][2]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[1][2]}]

set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[1][0]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[1][0]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[1][1]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[1][1]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[1][2]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[1][2]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[1][3]}]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[1][3]}]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][1]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][1]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][2]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][2]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][3]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][3]}]
