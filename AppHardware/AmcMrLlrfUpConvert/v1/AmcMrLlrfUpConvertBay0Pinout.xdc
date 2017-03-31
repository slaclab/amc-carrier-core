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

# JESD Reference Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][7]}] ; #jesdSysRefP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][7]}] ; #jesdSysRefN[0]

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][4]}] ; # jesdSyncP[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][4]}] ; # jesdSyncN[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][2]}] ; # jesdSyncP[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][2]}] ; # jesdSyncN[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][1]}] ; # jesdSyncP[0][2]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][1]}] ; # jesdSyncN[0][2]

# LMK and ADC SPI
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][0]}] ; #spiSdio_io[0]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][1]}] ; #spiSclk_o[0]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][2]}] ; #spiSdi_o[0]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][3]}] ; #spiSdo_i[0]

set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][2]}]  ; # spiCsL_o[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][3]}]  ; # spiCsL_o[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[0][3]}]  ; # spiCsL_o[0][2]
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[0][2]}]  ; # spiCsL_o[0][3]
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true} [get_ports {jtagPri[0][4]}] ; # spiCsL_o[0][4]

# Attenuator
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][6]}] ; #attSclk_o[0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][6]}] ; #attSdi_o[0]

set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][8]}] ; # attLatchEn_o[0][0]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][8]}] ; # attLatchEn_o[0][1]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareN[0][7]}] ; # attLatchEn_o[0][2]
set_property -dict { IOSTANDARD LVCMOS18} [get_ports {spareP[0][7]}] ; # attLatchEn_o[0][3]

# LVDS DAC signals
set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][9]}] ; # dacDataP[0][0]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][9]}] ; # dacDataN[0][0]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][10]}] ; # dacDataP[0][1]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][10]}] ; # dacDataN[0][1]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][11]}] ; # dacDataP[0][2]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][11]}] ; # dacDataN[0][2]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][12]}] ; # dacDataP[0][3]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][12]}] ; # dacDataN[0][3]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][13]}] ; # dacDataP[0][4]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][13]}] ; # dacDataN[0][4]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][14]}] ; # dacDataP[0][5]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][14]}] ; # dacDataN[0][5]

set_property -dict { IOSTANDARD LVDS} [get_ports {spareP[0][15]}] ; # dacDataP[0][6]
set_property -dict { IOSTANDARD LVDS} [get_ports {spareN[0][15]}] ; # dacDataN[0][6]

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[0][0]}] ; # dacDataP[0][7]
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[0][0]}] ; # dacDataN[0][7]

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[0][1]}] ; # dacDataP[0][8]
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[0][1]}] ; # dacDataN[0][8]

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[0][1]}] ; # dacDataP[0][9]
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[0][1]}] ; # dacDataN[0][9]

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[0][2]}] ; # dacDataP[0][10]
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[0][2]}] ; # dacDataN[0][10]

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[0][2]}] ; # dacDataP[0][11]
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[0][2]}] ; # dacDataN[0][11]

set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefP[0][3]}] ; # dacDataP[0][12]
set_property -dict { IOSTANDARD LVDS} [get_ports {sysRefN[0][3]}] ; # dacDataN[0][12]

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[0][3]}] ; # dacDataP[0][13]
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[0][3]}] ; # dacDataN[0][13]

set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutP[0][0]}] ; # dacDataP[0][14]
set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutN[0][0]}] ; # dacDataN[0][14]

set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutP[0][3]}] ; # dacDataP[0][15]
set_property -dict { IOSTANDARD LVDS} [get_ports {syncOutN[0][3]}] ; # dacDataN[0][15]

set_property -dict { IOSTANDARD LVDS} [get_ports {syncInP[0][0]}] ; # dacDckP[0]
set_property -dict { IOSTANDARD LVDS} [get_ports {syncInN[0][0]}] ; # dacDckN[0]

# Interlock and trigger
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][0]}] ; # timingTrig[0]
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][4]}] ; # fpgaInterlock[0]

# # Adding placement constraints on the LVDS DAC's ODDRE1 & ODELAYE3 module
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[0].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[1].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[2].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[3].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[4].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[5].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[6].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[7].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[8].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[9].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[10].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[11].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[12].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[13].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[14].OutputTapDelay_INST/U_ODELAYE3}]
# set_property LOC BITSLICE_RX_TX_X0Y*** [get_cells {U_AppTop/U_AppCore/U_AMC0/GEN_DLY_OUT[15].OutputTapDelay_INST/U_ODELAYE3}]
