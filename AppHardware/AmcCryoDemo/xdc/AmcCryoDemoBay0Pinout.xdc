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
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][0]}] ; 
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][0]}] ; 
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][0]}] ; 
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][0]}] ; 
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][1]}] ; 
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][1]}] ; 
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][1]}] ; 
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][1]}] ; 
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][2]}] ; 
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][2]}] ; 
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][2]}] ; 
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][2]}] ; 
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][3]}] ; 
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][3]}] ; 
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][3]}] ; 
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][3]}] ; 
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][4]}] ; 
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][4]}] ; 
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][4]}] ; 
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][4]}] ; 
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][5]}] ; 
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][5]}] ; 
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][5]}] ; 
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][5]}] ; 
set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][6]}] ; 
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][6]}] ; 
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][6]}] ; 
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][6]}] ; 

# JESD Reference Ports
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[0][2]}] ; #jesdSysRefP 
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[0][2]}] ; #jesdSysRefN

# JESD ADC Sync Ports
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {syncInP[0][0]}] ; # jesdTxSyncP
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {syncInN[0][0]}] ; # jesdTxSyncN
set_property -dict {IOSTANDARD LVDS} [get_ports {syncOutP[0][5]}]  ; # jesdRxSyncP(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncOutN[0][5]}]  ; # jesdRxSyncN(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncOutP[0][0]}]  ; # jesdRxSyncP(1)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncOutN[0][0]}]  ; # jesdRxSyncN(1)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInP[0][1]}]  ; # jesdRxSyncP(2)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInN[0][1]}]  ; # jesdRxSyncN(2)

# AMC's JTAG Ports jtagPri[1][0-4] remapped for SPI 
set_property -dict {IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][0]}]   ; #spiSdio_io
set_property -dict {IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][1]}]   ; #spiSclk_o
set_property -dict {IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][2]}]   ; #spiSdi_o
set_property -dict {IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][3]}]   ; #spiSdo_i
set_property -dict {IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][4]}]  ; #spiCsL_o

# AMC's Spare Ports remapped for SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][3]}]   ; #spiCsL_o
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][3]}]   ; #spiCsL_o
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][2]}]   ; #spiCsL_o
                                                                           
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][0]}]  ; #spiSclkDac_o
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][0]}]   ; #spiCsLDac_o
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][1]}]  ; #spiSdioDac_io

# Hardware trigger
set_property -dict {IOSTANDARD LVCMOS18 PULLDOWN true} [get_ports {spareN[0][1]}]  ; #amcTrigHw


