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

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][0]}] ; 
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[0][0]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][1]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][1]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][2]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][2]}] ; 

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][0]}] ; #jesdRxSyncP[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][0]}] ; #jesdRxSyncN[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][1]}] ; #jesdRxSyncP[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][1]}] ; #jesdRxSyncN[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][2]}] ; #jesdTxSyncP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][2]}] ; #jesdTxSyncN[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][3]}] ; #jesdTxSyncP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][3]}] ; #jesdTxSyncN[0]

set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[0][2]}] ; #lmkRst[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[0][3]}];
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[0][3]}];
#set_property -dict { IOSTANDARD LVDS } [get_ports {jtagPri[0][1]}];

# Pass through Interfaces
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][0]}] ; #lemoDinP[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][0]}] ; #lemoDinN[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][1]}] ; #lemoDinP[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][1]}] ; #lemoDinN[0][1]
