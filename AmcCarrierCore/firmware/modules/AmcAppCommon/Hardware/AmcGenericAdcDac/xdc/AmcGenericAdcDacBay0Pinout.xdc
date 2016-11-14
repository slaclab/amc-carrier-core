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
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][0]}]
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][0]}]
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][0]}]
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][0]}]
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][1]}]
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][1]}]
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][1]}]
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][1]}]
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][2]}]
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][2]}]
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][2]}]
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][2]}]
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][3]}]
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][3]}]
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][3]}]
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][3]}]

# JESD Reference Ports
set_property PACKAGE_PIN AD6 [get_ports {jesdClkP[0]}]
set_property PACKAGE_PIN AD5 [get_ports {jesdClkN[0]}]
set_property -dict { PACKAGE_PIN AK22 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdSysRefP[0]}]
set_property -dict { PACKAGE_PIN AK23 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdSysRefN[0]}]

# JESD ADC Sync Ports
set_property -dict { PACKAGE_PIN AJ20 IOSTANDARD LVDS } [get_ports {jesdRxSyncP[0][0]}]
set_property -dict { PACKAGE_PIN AK20 IOSTANDARD LVDS } [get_ports {jesdRxSyncN[0][0]}]
set_property -dict { PACKAGE_PIN AL20 IOSTANDARD LVDS } [get_ports {jesdRxSyncP[0][1]}]
set_property -dict { PACKAGE_PIN AM20 IOSTANDARD LVDS } [get_ports {jesdRxSyncN[0][1]}]
set_property -dict { PACKAGE_PIN AH24 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdTxSyncP[0]}]
set_property -dict { PACKAGE_PIN AJ25 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {jesdTxSyncN[0]}]

# LMK Ports
set_property -dict { PACKAGE_PIN V26  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkClkSel[0][0]}]
set_property -dict { PACKAGE_PIN V29  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkClkSel[0][1]}]
set_property -dict { PACKAGE_PIN W26  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkStatus[0][0]}]
set_property -dict { PACKAGE_PIN W29  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkStatus[0][1]}]
set_property -dict { PACKAGE_PIN T22  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkCsL[0]}]
set_property -dict { PACKAGE_PIN T23  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkSck[0]}]
set_property -dict { PACKAGE_PIN AP21 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkDio[0]}]
set_property -dict { PACKAGE_PIN AP20 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkRst[0]}]
set_property -dict { PACKAGE_PIN AM24 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {lmkSync[0][0]}];# LMK SYNC: AMC Card Version C00
set_property -dict { PACKAGE_PIN AL8  IOSTANDARD LVCMOS25 SLEW FAST DRIVE 12 } [get_ports {lmkSync[0][1]}];# LMK SYNC: AMC Card Version C01 (or later)
set_property -dict { PACKAGE_PIN AM9  IOSTANDARD LVCMOS25 SLEW FAST DRIVE 12 } [get_ports {lmkMuxSel[0]}];# LMK MUX SEL: AMC Card Version C01 (or later)

# Fast ADC's SPI Ports
set_property -dict { PACKAGE_PIN AH16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcCsL[0][0]}]
set_property -dict { PACKAGE_PIN AK17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcCsL[0][1]}]
set_property -dict { PACKAGE_PIN AJ16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcSck[0][0]}]
set_property -dict { PACKAGE_PIN AK16 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcSck[0][1]}]
set_property -dict { PACKAGE_PIN AH17 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMiso[0][0]}]
set_property -dict { PACKAGE_PIN AK18 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMiso[0][1]}]
set_property -dict { PACKAGE_PIN AH18 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMosi[0][0]}]
set_property -dict { PACKAGE_PIN AJ18 IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {adcMosi[0][1]}]

# Fast DAC's SPI Ports
set_property -dict { PACKAGE_PIN U27  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacCsL[0]}]
set_property -dict { PACKAGE_PIN U26  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacSck[0]}]
set_property -dict { PACKAGE_PIN W28  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacMiso[0]}]
set_property -dict { PACKAGE_PIN Y28  IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {dacMosi[0]}]

# Slow DAC's SPI Ports
set_property -dict { PACKAGE_PIN U24  IOSTANDARD LVDS } [get_ports {dacVcoCsP[0]}]
set_property -dict { PACKAGE_PIN U25  IOSTANDARD LVDS } [get_ports {dacVcoCsN[0]}]
set_property -dict { PACKAGE_PIN V27  IOSTANDARD LVDS } [get_ports {dacVcoSckP[0]}]
set_property -dict { PACKAGE_PIN V28  IOSTANDARD LVDS } [get_ports {dacVcoSckN[0]}]
set_property -dict { PACKAGE_PIN V21  IOSTANDARD LVDS } [get_ports {dacVcoDinP[0]}]
set_property -dict { PACKAGE_PIN W21  IOSTANDARD LVDS } [get_ports {dacVcoDinN[0]}]

# Pass through Interfaces
set_property -dict { PACKAGE_PIN AD16 IOSTANDARD LVDS } [get_ports {fpgaClkP[0]}]
set_property -dict { PACKAGE_PIN AD15 IOSTANDARD LVDS } [get_ports {fpgaClkN[0]}]
set_property -dict { PACKAGE_PIN AG24 IOSTANDARD LVDS } [get_ports {smaTrigP[0]}]
set_property -dict { PACKAGE_PIN AG25 IOSTANDARD LVDS } [get_ports {smaTrigN[0]}]
set_property -dict { PACKAGE_PIN AF23 IOSTANDARD LVDS } [get_ports {adcCalP[0]}]
set_property -dict { PACKAGE_PIN AF24 IOSTANDARD LVDS } [get_ports {adcCalN[0]}]
set_property -dict { PACKAGE_PIN AN23 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinP[0][0]}]
set_property -dict { PACKAGE_PIN AP23 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinN[0][0]}]
set_property -dict { PACKAGE_PIN AP24 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinP[0][1]}]
set_property -dict { PACKAGE_PIN AP25 IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {lemoDinN[0][1]}]
set_property -dict { PACKAGE_PIN AE25 IOSTANDARD LVDS } [get_ports {lemoDoutP[0][0]}]
set_property -dict { PACKAGE_PIN AE26 IOSTANDARD LVDS } [get_ports {lemoDoutN[0][0]}]
set_property -dict { PACKAGE_PIN AF22 IOSTANDARD LVDS } [get_ports {lemoDoutP[0][1]}]
set_property -dict { PACKAGE_PIN AG22 IOSTANDARD LVDS } [get_ports {lemoDoutN[0][1]}]
set_property -dict { PACKAGE_PIN AK8 IOSTANDARD LVCMOS25 } [get_ports {bcmL[0]}]