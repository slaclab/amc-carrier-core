##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# AMC Low speed LVDS signals
set_property -dict { IOSTANDARD LVDS }                        [get_ports {fpgaClkP[1][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkP[1][1]}]

set_property -dict { IOSTANDARD LVDS }                        [get_ports {sysRefP[1][*]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[1][*]}]

set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[1][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][1]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[1][2]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][3]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[1][4]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][5]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[1][6]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][7]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[1][8]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][9]}]

set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][1]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][2]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][3]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][4]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][5]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][6]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][7]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][8]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][9]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][10]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][11]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][12]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][13]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[1][14]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][15]}]
