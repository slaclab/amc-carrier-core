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
set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][0]}]
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][0]}]
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][0]}]
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][0]}]
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][1]}]
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][1]}]
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][1]}]
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][1]}]
set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][2]}]
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][2]}]
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][2]}]
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][2]}]
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][3]}]
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][3]}]
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][3]}]
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][3]}]

# JESD Reference Ports
set_property PACKAGE_PIN M6  [get_ports {jesdClkP[1]}]
set_property PACKAGE_PIN M5  [get_ports {jesdClkN[1]}]
set_property -dict { PACKAGE_PIN W25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdSysRefP[1]}]
set_property -dict { PACKAGE_PIN Y25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdSysRefN[1]}]

# JESD ADC Sync Ports
set_property -dict { PACKAGE_PIN AF20 IOSTANDARD LVDS } [get_ports {jesdRxSyncP[1][0]}]
set_property -dict { PACKAGE_PIN AG20 IOSTANDARD LVDS } [get_ports {jesdRxSyncN[1][0]}]
set_property -dict { PACKAGE_PIN AD21 IOSTANDARD LVDS } [get_ports {jesdRxSyncP[1][1]}]
set_property -dict { PACKAGE_PIN AE21 IOSTANDARD LVDS } [get_ports {jesdRxSyncN[1][1]}]
set_property -dict { PACKAGE_PIN AN14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdTxSyncP[1]}]
set_property -dict { PACKAGE_PIN AP14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdTxSyncN[1]}]

# LMK Ports
set_property -dict { PACKAGE_PIN AA20 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkClkSel[1][0]}]
set_property -dict { PACKAGE_PIN AC22 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkClkSel[1][1]}]
set_property -dict { PACKAGE_PIN AB20 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkStatus[1][0]}]
set_property -dict { PACKAGE_PIN AC23 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkStatus[1][1]}]
set_property -dict { PACKAGE_PIN Y26  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkCsL[1]}]
set_property -dict { PACKAGE_PIN Y27  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkSck[1]}]
set_property -dict { PACKAGE_PIN AL25 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkDio[1]}]
set_property -dict { PACKAGE_PIN AL22 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkSync[1][0]}];# LMK SYNC: AMC Card Version C00
set_property -dict { PACKAGE_PIN AL10 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkSync[1][1]}];# LMK SYNC: AMC Card Version C01
set_property -dict { PACKAGE_PIN AL24 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkRst[1]}]

# Fast ADC's SPI Ports
set_property -dict { PACKAGE_PIN AB30 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcCsL[1][0]}]
set_property -dict { PACKAGE_PIN AC31 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcCsL[1][1]}]
set_property -dict { PACKAGE_PIN AB31 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcSck[1][0]}]
set_property -dict { PACKAGE_PIN AC32 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcSck[1][1]}]
set_property -dict { PACKAGE_PIN AB32 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMiso[1][0]}]
set_property -dict { PACKAGE_PIN AD31 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMiso[1][1]}]
set_property -dict { PACKAGE_PIN AA32 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMosi[1][0]}]
set_property -dict { PACKAGE_PIN AD30 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMosi[1][1]}]

# Fast DAC's SPI Ports
set_property -dict { PACKAGE_PIN AB26 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacCsL[1]}]
set_property -dict { PACKAGE_PIN AB25 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacSck[1]}]
set_property -dict { PACKAGE_PIN AA27 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacMiso[1]}]
set_property -dict { PACKAGE_PIN AB27 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacMosi[1]}]

# Slow DAC's SPI Ports
set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVDS } [get_ports {dacVcoCsP[1]}]
set_property -dict { PACKAGE_PIN AC27 IOSTANDARD LVDS } [get_ports {dacVcoCsN[1]}]
set_property -dict { PACKAGE_PIN AB24 IOSTANDARD LVDS } [get_ports {dacVcoSckP[1]}]
set_property -dict { PACKAGE_PIN AC24 IOSTANDARD LVDS } [get_ports {dacVcoSckN[1]}]
set_property -dict { PACKAGE_PIN AD25 IOSTANDARD LVDS } [get_ports {dacVcoDinP[1]}]
set_property -dict { PACKAGE_PIN AD26 IOSTANDARD LVDS } [get_ports {dacVcoDinN[1]}]

# Pass through Interfaces
set_property -dict { PACKAGE_PIN AE16 IOSTANDARD LVDS } [get_ports {fpgaClkP[1]}]
set_property -dict { PACKAGE_PIN AE15 IOSTANDARD LVDS } [get_ports {fpgaClkN[1]}]
set_property -dict { PACKAGE_PIN V31  IOSTANDARD LVDS } [get_ports {smaTrigP[1]}]
set_property -dict { PACKAGE_PIN W31  IOSTANDARD LVDS } [get_ports {smaTrigN[1]}]
set_property -dict { PACKAGE_PIN U34  IOSTANDARD LVDS } [get_ports {adcCalP[1]}]
set_property -dict { PACKAGE_PIN V34  IOSTANDARD LVDS } [get_ports {adcCalN[1]}]
set_property -dict { PACKAGE_PIN AM22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinP[1][0]}]
set_property -dict { PACKAGE_PIN AN22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinN[1][0]}]
set_property -dict { PACKAGE_PIN AM21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinP[1][1]}]
set_property -dict { PACKAGE_PIN AN21 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinN[1][1]}]
set_property -dict { PACKAGE_PIN Y31  IOSTANDARD LVDS } [get_ports {lemoDoutP[1][0]}]
set_property -dict { PACKAGE_PIN Y32  IOSTANDARD LVDS } [get_ports {lemoDoutN[1][0]}]
set_property -dict { PACKAGE_PIN V33  IOSTANDARD LVDS } [get_ports {lemoDoutP[1][1]}]
set_property -dict { PACKAGE_PIN W34  IOSTANDARD LVDS } [get_ports {lemoDoutN[1][1]}]
set_property -dict { PACKAGE_PIN AP9  IOSTANDARD LVCMOS25 } [get_ports {bcmL[1]}]
