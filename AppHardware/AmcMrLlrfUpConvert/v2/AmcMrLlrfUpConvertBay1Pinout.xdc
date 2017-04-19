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

# LVDS DAC signals
set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][9]}] ; # dacDataP[1][0]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][9]}] ; # dacDataN[1][0]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][10]}] ; # dacDataP[1][1]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][10]}] ; # dacDataN[1][1]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][11]}] ; # dacDataP[1][2]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][11]}] ; # dacDataN[1][2]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][12]}] ; # dacDataP[1][3]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][12]}] ; # dacDataN[1][3]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][13]}] ; # dacDataP[1][4]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][13]}] ; # dacDataN[1][4]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][14]}] ; # dacDataP[1][5]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][14]}] ; # dacDataN[1][5]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[1][15]}] ; # dacDataP[1][6]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[1][15]}] ; # dacDataN[1][6]

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[1][0]}] ; # dacDataP[1][7] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[1][0]}] ; # dacDataN[1][7] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[1][1]}] ; # dacDataP[1][8] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[1][1]}] ; # dacDataN[1][8] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[1][1]}] ; # dacDataP[1][9] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[1][1]}] ; # dacDataN[1][9] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[1][2]}] ; # dacDataP[1][10] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[1][2]}] ; # dacDataN[1][10] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[1][2]}] ; # dacDataP[1][11] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[1][2]}] ; # dacDataN[1][11] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[1][3]}] ; # dacDataP[1][12] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[1][3]}] ; # dacDataN[1][12] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[1][3]}] ; # dacDataP[1][13] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[1][3]}] ; # dacDataN[1][13] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutP[1][0]}] ; # dacDataP[1][14] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutN[1][0]}] ; # dacDataN[1][14] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutP[1][3]}] ; # dacDataP[1][15] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutN[1][3]}] ; # dacDataN[1][15] - Version2 Specific Mapping 

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[1][0]}] ; # dacDckP[1] - Version2 Specific Mapping 
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[1][0]}] ; # dacDckN[1] - Version2 Specific Mapping 

# Interlock and trigger
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][0]}] ; # timingTrig[1]
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][4]}] ; # fpgaInterlock[1]

# Adding placement constraints on the LVDS DAC's ODDRE1 & ODELAYE3 module
set_property LOC BITSLICE_RX_TX_X0Y229 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[0].OutputTapDelay_INST/U_ODELAYE3}]
set_property LOC BITSLICE_RX_TX_X0Y166 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[1].OutputTapDelay_INST/U_ODELAYE3}]
set_property LOC BITSLICE_RX_TX_X0Y164 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[2].OutputTapDelay_INST/U_ODELAYE3}]
set_property LOC BITSLICE_RX_TX_X0Y162 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[3].OutputTapDelay_INST/U_ODELAYE3}]
set_property LOC BITSLICE_RX_TX_X0Y160 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[4].OutputTapDelay_INST/U_ODELAYE3}]
set_property LOC BITSLICE_RX_TX_X0Y158 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[5].OutputTapDelay_INST/U_ODELAYE3}]
set_property LOC BITSLICE_RX_TX_X0Y156 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[6].OutputTapDelay_INST/U_ODELAYE3}]

set_property LOC BITSLICE_RX_TX_X0Y221 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[7].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y218 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[8].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y39  [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[9].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y238 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[10].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y36  [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[11].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y227 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[12].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y34  [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[13].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y2   [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[14].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
set_property LOC BITSLICE_RX_TX_X0Y257 [get_cells {U_AppTop/U_AppCore/U_AMC1/GEN_DLY_OUT[15].OutputTapDelay_INST/U_ODELAYE3}] ; # Version2 Specific Mapping 
