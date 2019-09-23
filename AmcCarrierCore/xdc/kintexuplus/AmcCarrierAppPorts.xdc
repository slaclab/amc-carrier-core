##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######################
## Common Core Ports ##
#######################

# Backplane MPS Ports
set_property -dict { PACKAGE_PIN V31  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[1]}]
set_property -dict { PACKAGE_PIN W31  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[1]}]
set_property -dict { PACKAGE_PIN Y31  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[2]}]
set_property -dict { PACKAGE_PIN Y32  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[2]}]
set_property -dict { PACKAGE_PIN W30  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[3]}]
set_property -dict { PACKAGE_PIN Y30  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[3]}]
set_property -dict { PACKAGE_PIN AC33 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[4]}]
set_property -dict { PACKAGE_PIN AD33 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[4]}]
set_property -dict { PACKAGE_PIN AF30 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[5]}]
set_property -dict { PACKAGE_PIN AG30 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[5]}]
set_property -dict { PACKAGE_PIN AF29 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[6]}]
set_property -dict { PACKAGE_PIN AG29 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[6]}]
set_property -dict { PACKAGE_PIN AE28 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[7]}]
set_property -dict { PACKAGE_PIN AF28 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[7]}]
set_property -dict { PACKAGE_PIN V26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[8]}]
set_property -dict { PACKAGE_PIN W26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[8]}]
set_property -dict { PACKAGE_PIN U26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[9]}]
set_property -dict { PACKAGE_PIN U27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[9]}]
set_property -dict { PACKAGE_PIN U24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[10]}]
set_property -dict { PACKAGE_PIN U25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[10]}]
set_property -dict { PACKAGE_PIN V21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[11]}]
set_property -dict { PACKAGE_PIN W21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[11]}]
set_property -dict { PACKAGE_PIN AB25 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[12]}]
set_property -dict { PACKAGE_PIN AB26 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[12]}]
set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[13]}]
set_property -dict { PACKAGE_PIN AC27 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[13]}]
set_property -dict { PACKAGE_PIN AD25 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[14]}]
set_property -dict { PACKAGE_PIN AD26 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[14]}]

set_property -dict { PACKAGE_PIN AE27 IOSTANDARD LVDS } [get_ports {mpsTxP}]
set_property -dict { PACKAGE_PIN AF27 IOSTANDARD LVDS } [get_ports {mpsTxN}]

# set_property -dict { PACKAGE_PIN AP9 IOSTANDARD LVCMOS25 }         [get_ports {mpsClkIn}]  ; # BP_CLK1_IN
set_property -dict { PACKAGE_PIN P24 IOSTANDARD LVCMOS15 }           [get_ports {mpsClkIn}]  ; # BP_CLK1_IN
set_property -dict { PACKAGE_PIN AF8 IOSTANDARD LVCMOS25 SLEW FAST } [get_ports {mpsClkOut}] ; # BP_CLK1_OUT

# LCLS Timing Ports
set_property -dict { PACKAGE_PIN AH8 IOSTANDARD LVCMOS25 } [get_ports {timingClkScl}]
set_property -dict { PACKAGE_PIN AH9 IOSTANDARD LVCMOS25 } [get_ports {timingClkSda}]

# Crossbar Ports
set_property -dict { PACKAGE_PIN AE13 IOSTANDARD LVCMOS25 } [get_ports {xBarSin[0]}] 
set_property -dict { PACKAGE_PIN AF13 IOSTANDARD LVCMOS25 } [get_ports {xBarSin[1]}] 
set_property -dict { PACKAGE_PIN AK13 IOSTANDARD LVCMOS25 } [get_ports {xBarSout[0]}] 
set_property -dict { PACKAGE_PIN AL13 IOSTANDARD LVCMOS25 } [get_ports {xBarSout[1]}] 
set_property -dict { PACKAGE_PIN AK12 IOSTANDARD LVCMOS25 } [get_ports {xBarConfig}] 
set_property -dict { PACKAGE_PIN AL12 IOSTANDARD LVCMOS25 } [get_ports {xBarLoad}] 

# IPMC Ports
set_property -dict { PACKAGE_PIN AD9 IOSTANDARD LVCMOS25 } [get_ports {ipmcScl}]
set_property -dict { PACKAGE_PIN AD8 IOSTANDARD LVCMOS25 } [get_ports {ipmcSda}]

# Configuration PROM Ports
set_property -dict { PACKAGE_PIN AM12 IOSTANDARD LVCMOS25 } [get_ports {calScl}]
set_property -dict { PACKAGE_PIN AN12 IOSTANDARD LVCMOS25 } [get_ports {calSda}]

# VCCINT DC/DC Ports
set_property -dict { PACKAGE_PIN AA34 IOSTANDARD LVCMOS18 } [get_ports {pwrScl}]
set_property -dict { PACKAGE_PIN AB34 IOSTANDARD LVCMOS18 } [get_ports {pwrSda}]

# DDR3L SO-DIMM Ports
set_property -dict { PACKAGE_PIN K20 IOSTANDARD LVCMOS15 } [get_ports {ddrScl}] 
set_property -dict { PACKAGE_PIN K21 IOSTANDARD LVCMOS15 } [get_ports {ddrSda}] 

