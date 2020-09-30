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
set_property -dict { PACKAGE_PIN AD19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[1]}]
set_property -dict { PACKAGE_PIN AD18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[1]}]
set_property -dict { PACKAGE_PIN AG15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[2]}]
set_property -dict { PACKAGE_PIN AG14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[2]}]
set_property -dict { PACKAGE_PIN AG19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[3]}]
set_property -dict { PACKAGE_PIN AH19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[3]}]
set_property -dict { PACKAGE_PIN AJ15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[4]}]
set_property -dict { PACKAGE_PIN AJ14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[4]}]
set_property -dict { PACKAGE_PIN AG17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[5]}]
set_property -dict { PACKAGE_PIN AG16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[5]}]
set_property -dict { PACKAGE_PIN AL18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[6]}]
set_property -dict { PACKAGE_PIN AL17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[6]}]
set_property -dict { PACKAGE_PIN AK15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[7]}]
set_property -dict { PACKAGE_PIN AL15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[7]}]
set_property -dict { PACKAGE_PIN AL19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[8]}]
set_property -dict { PACKAGE_PIN AM19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[8]}]
set_property -dict { PACKAGE_PIN AL14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[9]}]
set_property -dict { PACKAGE_PIN AM14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[9]}]
set_property -dict { PACKAGE_PIN AP16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[10]}]
set_property -dict { PACKAGE_PIN AP15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[10]}]
set_property -dict { PACKAGE_PIN AM16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[11]}]
set_property -dict { PACKAGE_PIN AM15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[11]}]
set_property -dict { PACKAGE_PIN AN18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[12]}]
set_property -dict { PACKAGE_PIN AN17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[12]}]
set_property -dict { PACKAGE_PIN AM17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[13]}]
set_property -dict { PACKAGE_PIN AN16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[13]}]
set_property -dict { PACKAGE_PIN AN19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[14]}]
set_property -dict { PACKAGE_PIN AP18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[14]}]

set_property -dict { PACKAGE_PIN AP11 IOSTANDARD LVDS_25 } [get_ports {mpsTxP}]
set_property -dict { PACKAGE_PIN AP10 IOSTANDARD LVDS_25 } [get_ports {mpsTxN}]

set_property -dict { PACKAGE_PIN AF10 IOSTANDARD LVCMOS25 }           [get_ports {mpsClkIn}]  ; # BP_CLK1_IN
set_property -dict { PACKAGE_PIN AG10 IOSTANDARD LVCMOS25 SLEW FAST } [get_ports {mpsClkOut}] ; # BP_CLK1_OUT

# LCLS Timing Ports
set_property -dict { PACKAGE_PIN AE11 IOSTANDARD LVCMOS25 } [get_ports {timingClkScl}]
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVCMOS25 } [get_ports {timingClkSda}]

# Crossbar Ports
set_property -dict { PACKAGE_PIN AF13 IOSTANDARD LVCMOS25 } [get_ports {xBarSin[0]}]
set_property -dict { PACKAGE_PIN AK13 IOSTANDARD LVCMOS25 } [get_ports {xBarSin[1]}]
set_property -dict { PACKAGE_PIN AL13 IOSTANDARD LVCMOS25 } [get_ports {xBarSout[0]}]
set_property -dict { PACKAGE_PIN AK12 IOSTANDARD LVCMOS25 } [get_ports {xBarSout[1]}]
set_property -dict { PACKAGE_PIN AL12 IOSTANDARD LVCMOS25 } [get_ports {xBarConfig}]
set_property -dict { PACKAGE_PIN AK11 IOSTANDARD LVCMOS25 } [get_ports {xBarLoad}]

# IPMC Ports
set_property -dict { PACKAGE_PIN AE12 IOSTANDARD LVCMOS25 } [get_ports {ipmcScl}]
set_property -dict { PACKAGE_PIN AF12 IOSTANDARD LVCMOS25 } [get_ports {ipmcSda}]

# Configuration PROM Ports
set_property -dict { PACKAGE_PIN N27 IOSTANDARD LVCMOS25 } [get_ports {calScl}]
set_property -dict { PACKAGE_PIN N23 IOSTANDARD LVCMOS25 } [get_ports {calSda}]

# DDR3L SO-DIMM Ports
set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS15 } [get_ports {ddrScl}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS15 } [get_ports {ddrSda}]

