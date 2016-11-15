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
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][0]}] ; #P11 PIN47
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][0]}] ; #P11 PIN48
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][0]}] ; #P11 PIN44
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][0]}] ; #P11 PIN45
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][1]}] ; #P11 PIN53
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][1]}] ; #P11 PIN54
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][1]}] ; #P11 PIN50
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][1]}] ; #P11 PIN51
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][2]}] ; #P11 PIN62
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][2]}] ; #P11 PIN63
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][2]}] ; #P11 PIN59
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][2]}] ; #P11 PIN60
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][3]}] ; #P11 PIN68
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][3]}] ; #P11 PIN69
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][3]}] ; #P11 PIN65
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][3]}] ; #P11 PIN66
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][4]}] ; #P11 PIN32
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][4]}] ; #P11 PIN33
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][4]}] ; #P11 PIN29
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][4]}] ; #P11 PIN30
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][5]}] ; #P11 PIN38
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][5]}] ; #P11 PIN39
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][5]}] ; #P11 PIN35
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][5]}] ; #P11 PIN36
set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][6]}] ; #P12 PIN53
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][6]}] ; #P12 PIN54
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][6]}] ; #P12 PIN50
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][6]}] ; #P12 PIN51

# JESD Reference Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][0]}] ; #jesdSysRefP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[0][0]}] ; #jesdSysRefN[0]

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][0]}] ; #jesdRxSyncP[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][0]}] ; #jesdRxSyncN[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][1]}] ; #jesdRxSyncP[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][1]}] ; #jesdRxSyncN[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][2]}] ; #jesdTxSyncP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][2]}] ; #jesdTxSyncN[0]

# LMK Ports
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][4]}] ; #lmkClkSel[0][0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][5]}] ; #lmkClkSel[0][1]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][4]}] ; #lmkStatus[0][0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][5]}] ; #lmkStatus[0][1]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][15]}] ; #lmkCsL[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][15]}] ; #lmkSck[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {syncInN[0][2]}] ; #lmkDio[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {syncInP[0][2]}] ; #lmkRst[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {syncInP[0][3]}];# lmkSync[0][0]: AMC Card Version C00
set_property -dict { IOSTANDARD LVCMOS25 SLEW FAST DRIVE 12 } [get_ports {jtagPri[0][1]}];# lmkSync[0][1]: AMC Card Version C01 (or later)
set_property -dict { IOSTANDARD LVCMOS25 SLEW FAST DRIVE 12 } [get_ports {jtagPri[0][2]}];# lmkMuxSel[0]: AMC Card Version C01 (or later)

# Fast ADC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][6]}] ; #adcCsL[0][0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][8]}] ; #adcCsL[0][1]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][6]}] ; #adcSck[0][0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][8]}] ; #adcSck[0][1]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][7]}] ; #adcMiso[0][0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][9]}] ; #adcMiso[0][1]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][7]}] ; #adcMosi[0][0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][9]}] ; #adcMosi[0][1]

# Fast DAC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][10]}] ; #dacCsL[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][10]}] ; #dacSck[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareP[0][11]}] ; #dacMiso[0]
set_property -dict { IOSTANDARD LVCMOS18 SLEW FAST DRIVE 12 } [get_ports {spareN[0][11]}] ; #dacMosi[0]

# Slow DAC's SPI Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][12]}] ; #dacVcoCsP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][12]}] ; #dacVcoCsN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][13]}] ; #dacVcoSckP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][13]}] ; #dacVcoSckN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][14]}] ; #dacVcoDinP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][14]}] ; #dacVcoDinN[0]

# Pass through Interfaces
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkP[0][0]}] ; #fpgaClkP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkN[0][0]}] ; #fpgaClkN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][3]}] ; #smaTrigP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][3]}] ; #smaTrigN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][4]}] ; #adcCalP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][4]}] ; #adcCalN[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][0]}] ; #lemoDinP[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][0]}] ; #lemoDinN[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][1]}] ; #lemoDinP[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][1]}] ; #lemoDinN[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][5]}] ; #lemoDoutP[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][5]}] ; #lemoDoutN[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][6]}] ; #lemoDoutP[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][6]}] ; #lemoDoutN[0][1]
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][0]}] ; #bcmL[0]
