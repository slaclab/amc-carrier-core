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
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][0]}] ; #
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][0]}] ; #
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][0]}] ; #
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][0]}] ; #
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][1]}] ; # 
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][1]}] ; #
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][1]}] ; #
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][1]}] ; #
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][2]}] ; #
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][2]}] ; #
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][2]}] ; #
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][2]}] ; #
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][3]}] ; #
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][3]}] ; #
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][3]}] ; #
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][3]}] ; #
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][4]}] ; #
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][4]}] ; #
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][4]}] ; #
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][4]}] ; #
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][5]}] ; #
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][5]}] ; #
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][5]}] ; #
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][5]}] ; #
set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][6]}] ; #
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][6]}] ; #
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][6]}] ; #
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][6]}] ; #
set_property PACKAGE_PIN T31 [get_ports {jesdTxP[0][7]}] ; #
set_property PACKAGE_PIN T32 [get_ports {jesdTxN[0][7]}] ; #
set_property PACKAGE_PIN R33 [get_ports {jesdRxP[0][7]}] ; #
set_property PACKAGE_PIN R34 [get_ports {jesdRxN[0][7]}] ; #
set_property PACKAGE_PIN P31 [get_ports {jesdTxP[0][8]}] ; #
set_property PACKAGE_PIN P32 [get_ports {jesdTxN[0][8]}] ; #
set_property PACKAGE_PIN N33 [get_ports {jesdRxP[0][8]}] ; #
set_property PACKAGE_PIN N34 [get_ports {jesdRxN[0][8]}] ; #
set_property PACKAGE_PIN M31 [get_ports {jesdTxP[0][9]}] ; #
set_property PACKAGE_PIN M32 [get_ports {jesdTxN[0][9]}] ; #
set_property PACKAGE_PIN L33 [get_ports {jesdRxP[0][9]}] ; #
set_property PACKAGE_PIN L34 [get_ports {jesdRxN[0][9]}] ; #

# JESD Reference Ports
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[0][0]}] ; #jesdSysRefP 
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[0][0]}] ; #jesdSysRefN

# JESD ADC Sync Ports
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInP[0][3]}]  ; # jesdRxSyncP(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInN[0][3]}]  ; # jesdRxSyncN(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {spareP[0][14])}]  ; # jesdRxSyncP(1)
set_property -dict {IOSTANDARD LVDS} [get_ports {spareN[0][14]}]  ; # jesdRxSyncN(1)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[0][1]}] ; # jesdTxSyncP(0)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[0][1]}] ; # jesdTxSyncN(0)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {spareP[0][8]}] ; # jesdTxSyncP(1)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {spareN[0][8]}] ; # jesdTxSyncN(1)

# ADC SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][2]}]    ; # adcSpiDo(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncInN[0][0]}]   ; # adcSpiDo(1)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][1]}]    ; # adcSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][2]}]    ; # adcSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutN[0][8]}]  ; # adcSpiCsb(1)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutP[0][9]}]  ; # adcSpiDi

# DAC SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][0]}]    ; # dacSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][1]}]    ; # dacSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][0]}]    ; # dacSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutP[0][8]}]  ; # dacSpiCsb(1)

# LMK SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][10]}]    ; # lmkSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][11]}]    ; # lmkSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][9]}]     ; # lmkSpiCsb

# LMK SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][12]}]    ; # pllSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][12]}]    ; # pllSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][15]}]    ; # pllSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][15]}]    ; # pllSpiCsb(1)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][13]}]    ; # pllSpiCsb(2)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][13]}]    ; # pllSpiCsb(3)

# ADC resets
set_property -dict {IOSTANDARD LVCMOS18} [get_ports {spareN[0][3]}]    ; # adcRst(0)
set_property -dict {IOSTANDARD LVCMOS18} [get_ports {syncOutN[0][9]}]  ; # adcRst(1)
