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
set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][0]}] ; #
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][0]}] ; #
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][0]}] ; #
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][0]}] ; #
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][1]}] ; #
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][1]}] ; #
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][1]}] ; #
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][1]}] ; #
set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][2]}] ; #
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][2]}] ; #
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][2]}] ; #
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][2]}] ; #
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][3]}] ; #
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][3]}] ; #
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][3]}] ; #
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][3]}] ; #
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][4]}] ; #
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][4]}] ; #
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][4]}] ; #
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][4]}] ; #
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][5]}] ; #
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][5]}] ; #
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][5]}] ; #
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][5]}] ; #
set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][6]}] ; #
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][6]}] ; #
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][6]}] ; #
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][6]}] ; #
set_property PACKAGE_PIN H31 [get_ports {jesdTxP[1][7]}] ; #
set_property PACKAGE_PIN H32 [get_ports {jesdTxN[1][7]}] ; #
set_property PACKAGE_PIN G33 [get_ports {jesdRxP[1][7]}] ; #
set_property PACKAGE_PIN G34 [get_ports {jesdRxN[1][7]}] ; #
set_property PACKAGE_PIN G29 [get_ports {jesdTxP[1][8]}] ; #
set_property PACKAGE_PIN G30 [get_ports {jesdTxN[1][8]}] ; #
set_property PACKAGE_PIN F31 [get_ports {jesdRxP[1][8]}] ; #
set_property PACKAGE_PIN F32 [get_ports {jesdRxN[1][8]}] ; #
set_property PACKAGE_PIN D31 [get_ports {jesdTxP[1][9]}] ; #
set_property PACKAGE_PIN D32 [get_ports {jesdTxN[1][9]}] ; #
set_property PACKAGE_PIN E33 [get_ports {jesdRxP[1][9]}] ; #
set_property PACKAGE_PIN E34 [get_ports {jesdRxN[1][9]}] ; #


# JESD Reference Ports
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[1][0]}] ; #jesdSysRefP 
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[1][0]}] ; #jesdSysRefN

# JESD ADC Sync Ports
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInP[1][3]}]  ; # jesdRxSyncP(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInN[1][3]}]  ; # jesdRxSyncN(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {spareP[1][14])}]  ; # jesdRxSyncP(1)
set_property -dict {IOSTANDARD LVDS} [get_ports {spareN[1][14]}]  ; # jesdRxSyncN(1)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[1][1]}] ; # jesdTxSyncP(0)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[1][1]}] ; # jesdTxSyncN(0)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {spareP[1][8]}] ; # jesdTxSyncP(1)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {spareN[1][8]}] ; # jesdTxSyncN(1)

# ADC SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][2]}]    ; # adcSpiDo
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][1]}]    ; # adcSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][2]}]    ; # adcSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutN[1][8]}]  ; # adcSpiCsb(1)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutP[1][9]}]  ; # adcSpiDi


# DAC SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][0]}]    ; # dacSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][1]}]    ; # dacSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][0]}]    ; # dacSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutP[1][8]}]  ; # dacSpiCsb(1)

# LMK SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][10]}]    ; # lmkSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][11]}]    ; # lmkSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][9]}]    ; # lmkSpiCsb

# ADC resets
set_property -dict {IOSTANDARD LVCMOS18} [get_ports {spareN[1][3]}]    ; # adcRst(0)
set_property -dict {IOSTANDARD LVCMOS18} [get_ports {syncOutN[1][9]}]  ; # adcRst(1)


