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
set_property PACKAGE_PIN N4 [get_ports {jesdTxP[1][6]}] ; #P13 PIN47
set_property PACKAGE_PIN N3 [get_ports {jesdTxN[1][6]}] ; #P13 PIN48
set_property PACKAGE_PIN M2 [get_ports {jesdRxP[1][6]}] ; #P13 PIN44
set_property PACKAGE_PIN M1 [get_ports {jesdRxN[1][6]}] ; #P13 PIN45
set_property PACKAGE_PIN L4 [get_ports {jesdTxP[1][0]}] ; #P13 PIN53
set_property PACKAGE_PIN L3 [get_ports {jesdTxN[1][0]}] ; #P13 PIN54
set_property PACKAGE_PIN K2 [get_ports {jesdRxP[1][0]}] ; #P13 PIN50
set_property PACKAGE_PIN K1 [get_ports {jesdRxN[1][0]}] ; #P13 PIN51
set_property PACKAGE_PIN J4 [get_ports {jesdTxP[1][1]}] ; #P13 PIN62
set_property PACKAGE_PIN J3 [get_ports {jesdTxN[1][1]}] ; #P13 PIN63
set_property PACKAGE_PIN H2 [get_ports {jesdRxP[1][1]}] ; #P13 PIN59
set_property PACKAGE_PIN H1 [get_ports {jesdRxN[1][1]}] ; #P13 PIN60
set_property PACKAGE_PIN G4 [get_ports {jesdTxP[1][4]}] ; #P13 PIN68
set_property PACKAGE_PIN G3 [get_ports {jesdTxN[1][4]}] ; #P13 PIN69
set_property PACKAGE_PIN F2 [get_ports {jesdRxP[1][4]}] ; #P13 PIN65
set_property PACKAGE_PIN F1 [get_ports {jesdRxN[1][4]}] ; #P13 PIN66
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][2]}] ; #P13 PIN32
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][2]}] ; #P13 PIN33
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][2]}] ; #P13 PIN29
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][2]}] ; #P13 PIN30
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][3]}] ; #P13 PIN38
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][3]}] ; #P13 PIN39
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][3]}] ; #P13 PIN35
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][3]}] ; #P13 PIN36
set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][5]}] ; #P14 PIN53
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][5]}] ; #P14 PIN54
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][5]}] ; #P14 PIN50
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][5]}] ; #P14 PIN51

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkP[1][0]}]; #jesdSysRefP P11 PIN74
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkN[1][0]}]; #jesdSysRefN P11 PIN75

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[1][0]}]; #jesdSyncP P12 PIN165
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[1][1]}]; #jesdSyncN P12 PIN166
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[1][2]}]; #jesdSyncP P12 PIN167
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[1][3]}]; #jesdSyncN P12 PIN168

# LMK Ports
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][5]}]; #lmkClkSel P11 PIN162
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][5]}]; #lmkClkSel P11 PIN163
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[1][10]}]; #lmkSck P12 PIN129
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[1][15]}]; #lmkDio P12 PIN151
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[1][15]}]; #lmkSync P12 PIN150
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[1][10]}]; #lmkCsL P12 PIN130
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[1][14]}]; #lmkRst P12 PIN148

# Fast ADC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[1][4]}]; #adcCsL P11 PIN169
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[1][3]}]; #adcCsL P11 PIN157
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[1][1]}]; #adcSck P11 PIN166
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[1][3]}]; #adcMiso P11 PIN168
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[1][2]}]; #adcMosi P11 PIN167

# Slow DAC's SPI Ports    
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[1][12]}]; #dacCsL P12 PIN142                                                                 
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[1][13]}]; #dacSck P12 PIN144
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[1][12]}]; #dacMosi P12 PIN141

# Analog Control Ports
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][0]}]; #attn1A[0][0] P11 PIN93
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][0]}]; #attn1A[0][1] P11 PIN94
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][0]}]; #attn1A[0][2] P11 PIN96
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][0]}]; #attn1A[0][3] P11 PIN97
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][1]}]; #attn1A[0][4] P11 PIN99

set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][1]}]; #attn1B[0][0] P11 PIN100
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][1]}]; #attn1B[0][1] P11 PIN102
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][1]}]; #attn1B[0][2] P11 PIN103
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][2]}]; #attn1B[0][3] P11 PIN105
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][2]}]; #attn1B[0][4] P11 PIN106

set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][2]}]; #attn2A[0][0] P11 PIN108
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][2]}]; #attn2A[0][1] P11 PIN109
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][3]}]; #attn2A[0][2] P11 PIN111
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][3]}]; #attn2A[0][3] P11 PIN112
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][3]}]; #attn2A[0][4] P11 PIN114
                                                                   
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][3]}]; #attn2B[0][0] P11 PIN115
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][0]}]; #attn2B[0][1] P11 PIN117
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][0]}]; #attn2B[0][2] P11 PIN118
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][1]}]; #attn2B[0][3] P11 PIN120
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][1]}]; #attn2B[0][4] P11 PIN121
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][2]}]; #attn3A[0][0] P11 PIN123
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][2]}]; #attn3A[0][1] P11 PIN124
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][3]}]; #attn3A[0][2] P11 PIN126
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][3]}]; #attn3A[0][3] P11 PIN127
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][4]}]; #attn3A[0][4] P11 PIN129
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][4]}]; #attn3B[0][0] P11 PIN130
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][5]}]; #attn3B[0][1] P11 PIN132
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][5]}]; #attn3B[0][2] P11 PIN133
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][8]}]; #attn3B[0][3] P11 PIN141
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][8]}]; #attn3B[0][4] P11 PIN142
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][9]}]; #attn4A[0][0] P11 PIN144
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][9]}]; #attn4A[0][1] P11 PIN145
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][0]}]; #attn4A[0][2] P11 PIN147
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][0]}]; #attn4A[0][3] P11 PIN148
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][1]}]; #attn4A[0][4] P11 PIN151
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][2]}]; #attn4B[0][0] P11 PIN153
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][2]}]; #attn4B[0][1] P11 PIN154
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][3]}]; #attn4B[0][2] P11 PIN156
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][4]}]; #attn4B[0][3] P11 PIN159
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][4]}]; #attn4B[0][4] P11 PIN160
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][6]}]; #attn5A[0][0] P12 PIN117
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][6]}]; #attn5A[0][1] P12 PIN118
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][7]}]; #attn5A[0][2] P12 PIN120
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][7]}]; #attn5A[0][3] P12 PIN121
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][8]}]; #attn5A[0][4] P12 PIN123

set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][11]}]; #clSw[0][0] P12 PIN132
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][11]}]; #clSw[0][1] P12 PIN133
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[1][1]}]; #clSw[0][2] P12 PIN74
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[1][1]}]; #clSw[0][3] P12 PIN75
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][7]}]; #clSw[0][4] P11 PIN138
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][7]}]; #clSw[0][5] P11 PIN139
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[1][9]}]; #clClkOe P12 PIN126
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[1][9]}]; #rfAmpOn P12 PIN127

# Triggers
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[1][6]}]; #extTrigP P11 PIN136
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[1][6]}]; #extTrigN P11 PIN135
