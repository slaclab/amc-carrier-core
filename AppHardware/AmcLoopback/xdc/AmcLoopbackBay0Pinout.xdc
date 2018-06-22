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
set_property -dict { IOSTANDARD LVDS }                        [get_ports {fpgaClkP[0][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkP[0][1]}]

set_property -dict { IOSTANDARD LVDS }                        [get_ports {sysRefP[0][*]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][*]}]

set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[0][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][1]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[0][2]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][3]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[0][4]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][5]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[0][6]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][7]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {syncOutP[0][8]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][9]}]

set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][0]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][1]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][2]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][3]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][4]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][5]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][6]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][7]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][8]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][9]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][10]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][11]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][12]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][13]}]
set_property -dict { IOSTANDARD LVDS }                        [get_ports {spareP[0][14]}]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][15]}]
