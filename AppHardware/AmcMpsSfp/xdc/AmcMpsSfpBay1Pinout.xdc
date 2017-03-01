##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
# JESD High Speed Ports
set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][0]}] ; #P13 PIN47
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][0]}] ; #P13 PIN48
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][0]}] ; #P13 PIN44
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][0]}] ; #P13 PIN45
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][1]}] ; #P13 PIN53
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][1]}] ; #P13 PIN54
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][1]}] ; #P13 PIN50
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][1]}] ; #P13 PIN51
set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][2]}] ; #P13 PIN62
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][2]}] ; #P13 PIN63
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][2]}] ; #P13 PIN59
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][2]}] ; #P13 PIN60
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][3]}] ; #P13 PIN68
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][3]}] ; #P13 PIN69
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][3]}] ; #P13 PIN65
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][3]}] ; #P13 PIN66
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][4]}] ; #P13 PIN32
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][4]}] ; #P13 PIN33
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][4]}] ; #P13 PIN29
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][4]}] ; #P13 PIN30
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][5]}] ; #P13 PIN38
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][5]}] ; #P13 PIN39
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][5]}] ; #P13 PIN35
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][5]}] ; #P13 PIN36
set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][6]}] ; #P14 PIN53
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][6]}] ; #P14 PIN54
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][6]}] ; #P14 PIN50
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][6]}] ; #P14 PIN51

# JESD Reference Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[1][0]}] ; #jesdSysRefP[1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[1][0]}] ; #jesdSysRefN[1]

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][0]}] ; #jesdRxSyncP[1][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][0]}] ; #jesdRxSyncN[1][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][1]}] ; #jesdRxSyncP[1][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][1]}] ; #jesdRxSyncN[1][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][2]}] ; #jesdTxSyncP[1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][2]}] ; #jesdTxSyncN[1]

# LMK Ports
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][4]}] ; #lmkClkSel[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][5]}] ; #lmkClkSel[1][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][4]}] ; #lmkStatus[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][5]}] ; #lmkStatus[1][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][15]}] ; #lmkCsL[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][15]}] ; #lmkSck[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {syncInN[1][2]}] ; #lmkDio[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {syncInP[1][2]}] ; #lmkRst[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {syncInP[1][3]}];# lmkSync[1][0]: AMC Card Version C00
set_property -dict { IOSTANDARD LVCMOS25 PULLTYPE PULLUP } [get_ports {jtagPri[1][1]}];# lmkSync[1][1]: AMC Card Version C01 (or later)
set_property -dict { IOSTANDARD LVCMOS25 PULLTYPE PULLUP } [get_ports {jtagPri[1][2]}];# lmkMuxSel[1]: AMC Card Version C01 (or later)

# Fast ADC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][6]}] ; #adcCsL[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][8]}] ; #adcCsL[1][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][6]}] ; #adcSck[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][8]}] ; #adcSck[1][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE NONE   } [get_ports {spareN[1][7]}] ; #adcMiso[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE NONE   } [get_ports {spareN[1][9]}] ; #adcMiso[1][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][7]}] ; #adcMosi[1][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][9]}] ; #adcMosi[1][1]

# Fast DAC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][10]}] ; #dacCsL[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[1][10]}] ; #dacSck[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE NONE   } [get_ports {spareP[1][11]}] ; #dacMiso[1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[1][11]}] ; #dacMosi[1]

# Slow DAC's SPI Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[1][12]}] ; #dacVcoCsP[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[1][12]}] ; #dacVcoCsN[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[1][13]}] ; #dacVcoSckP[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[1][13]}] ; #dacVcoSckN[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[1][14]}] ; #dacVcoDinP[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[1][14]}] ; #dacVcoDinN[1]

# Pass through Interfaces
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkP[1][0]}] ; #fpgaClkP[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkN[1][0]}] ; #fpgaClkN[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][3]}] ; #smaTrigP[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][3]}] ; #smaTrigN[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][4]}] ; #adcCalP[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][4]}] ; #adcCalN[1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[1][0]}] ; #lemoDinP[1][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[1][0]}] ; #lemoDinN[1][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[1][1]}] ; #lemoDinP[1][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[1][1]}] ; #lemoDinN[1][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][5]}] ; #lemoDoutP[1][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][5]}] ; #lemoDoutN[1][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[1][6]}] ; #lemoDoutP[1][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[1][6]}] ; #lemoDoutN[1][1]
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][0]}] ; #bcmL[1]

set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks {jesd1_370MHz}]