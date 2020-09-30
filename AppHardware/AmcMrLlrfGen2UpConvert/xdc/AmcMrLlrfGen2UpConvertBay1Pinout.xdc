##############################################################################
## This file is part of 'LCLS2 LLRF Development'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 LLRF Development', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][0]}]
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][0]}]
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][0]}]
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][0]}]
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][1]}]
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][1]}]
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][1]}]
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][1]}]

set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][2]}]
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][2]}]
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][2]}]
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][2]}]
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][3]}]
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][3]}]
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][3]}]
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][3]}]

set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][4]}]
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][4]}]
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][4]}]
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][4]}]
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][5]}]
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][5]}]
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][5]}]
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][5]}]

set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][6]}]
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][6]}]
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][6]}]
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][6]}]

# JESD Reference Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][7]}] ; #jesdSysRefP[1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][7]}] ; #jesdSysRefN[1]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][9]}] ; #jesdTxSyncP
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[1][9]}] ; #jesdTxSyncN

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][4]}] ; # jesdSyncP[1][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][4]}] ; # jesdSyncN[1][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][2]}] ; # jesdSyncP[1][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][2]}] ; # jesdSyncN[1][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][1]}] ; # jesdSyncP[1][2]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][1]}] ; # jesdSyncN[1][2]

# LMK and ADC SPI
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[1][0]}] ; #spiSdio_io[1]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[1][1]}] ; #spiSclk_o[1]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[1][2]}] ; #spiSdi_o[1]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[1][3]}] ; #spiSdo_i[1]

set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][2]}]  ; # spiCsL_o[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][3]}]  ; # spiCsL_o[1][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][3]}]  ; # spiCsL_o[1][2]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][2]}]  ; # spiCsL_o[1][3]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[1][4]}] ; # spiCsL_o[1][4]

# Attenuator
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[1][6]}] ; #attSclk_o[1]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[1][6]}] ; #attSdi_o[1]

set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[1][8]}] ; # attLatchEn_o[1][0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[1][8]}] ; # attLatchEn_o[1][1]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[1][7]}] ; # attLatchEn_o[1][2]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[1][7]}] ; # attLatchEn_o[1][3]

# Interlock and trigger
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][0]}] ; # timingTrig[1]
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][4]}] ; # fpgaInterlock[1]

# I2C Temp Sensors
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports { spareN[1][1] }] ; # SCL @ P13.PIN150
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports { spareN[1][0] }] ; # SDA @ P13.PIN147

set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports syncOutP[1][1]]
