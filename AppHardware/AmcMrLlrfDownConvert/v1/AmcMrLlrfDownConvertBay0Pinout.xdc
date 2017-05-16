##############################################################################
## This file is part of 'LCLS2 LLRF Development'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 LLRF Development', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][0]}]
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][0]}]
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][0]}]
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][0]}]
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][1]}]
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][1]}]
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][1]}]
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][1]}]
                             
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][2]}]
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][2]}]
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][2]}]
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][2]}]
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][3]}]
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][3]}]
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][3]}]
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][3]}]
                             
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][4]}]
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][4]}]
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][4]}]
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][4]}]
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][5]}]
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][5]}]
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][5]}]
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][5]}]

set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][6]}]
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][6]}]
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][6]}]
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][6]}]

# Spare_SDclk9 clock
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {sysRefP[0][2]}] ; # jesdSysRefP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {sysRefN[0][2]}] ; # jesdSysRefN[0]

set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][5]}] ; # jesdSyncP[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][5]}] ; # jesdSyncN[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][0]}] ; # jesdSyncP[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][0]}] ; # jesdSyncN[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[0][1]}]  ; # jesdSyncP[0][2]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[0][1]}]  ; # jesdSyncN[0][2]

# LMK and ADC SPI
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][0]}] ; # spiSdio_io[0]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][1]}] ; # spiSclk_o[0]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][2]}] ; # spiSdi_o[0]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][3]}] ; # spiSdo_i[0]

set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][4]}] ; # spiCsL_o[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][3]}]  ; # spiCsL_o[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][3]}]  ; # spiCsL_o[0][2]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][2]}]  ; # spiCsL_o[0][3]

# Attenuator
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][6]}] ; # attSclk_o[0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][6]}] ; # attSdi_o[0]

set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][9]}] ; # attLatchEn_o[0][0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][9]}] ; # attLatchEn_o[0][1]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][8]}] ; # attLatchEn_o[0][2]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][8]}] ; # attLatchEn_o[0][3]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][7]}] ; # attLatchEn_o[0][4]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][7]}] ; # attLatchEn_o[0][5]

# SPI DAC
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][11]}] ; # dacSclk_o[0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][11]}] ; # dacSdi_o[0]

set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][12]}] ; # dacCsL_o[0][0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][12]}] ; # dacCsL_o[0][1]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][13]}] ; # dacCsL_o[0][2]

# Spare LMK clocks
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][2]}] ; # lmkDclk10P[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][2]}] ; # lmkDclk10N[0]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkP[0][0]}] ; # lmkDclk12P[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkN[0][0]}] ; # lmkDclk12N[0]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_AppTop/U_AppCore/U_AMC0/U_lmkDclk10/O]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_AppTop/U_AppCore/U_AMC0/U_lmkDclk12/O]

create_clock -name lmkDclk10 -period  2.702  [get_ports {syncInP}]
create_clock -name lmkDclk12 -period  2.702  [get_ports {fpgaClkP}]

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {jesd0_370MHz}]
