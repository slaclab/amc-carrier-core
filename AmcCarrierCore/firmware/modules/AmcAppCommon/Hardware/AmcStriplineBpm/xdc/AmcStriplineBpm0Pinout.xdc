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
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][4]}] ; #P11 PIN47
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][4]}] ; #P11 PIN48
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][4]}] ; #P11 PIN44
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][4]}] ; #P11 PIN45
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][0]}] ; #P11 PIN53
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][0]}] ; #P11 PIN54
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][0]}] ; #P11 PIN50
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][0]}] ; #P11 PIN51
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][1]}] ; #P11 PIN62
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][1]}] ; #P11 PIN63
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][1]}] ; #P11 PIN59
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][1]}] ; #P11 PIN60
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][5]}] ; #P11 PIN68
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][5]}] ; #P11 PIN69
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][5]}] ; #P11 PIN65
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][5]}] ; #P11 PIN66
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][2]}] ; #P11 PIN32
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][2]}] ; #P11 PIN33
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][2]}] ; #P11 PIN29
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][2]}] ; #P11 PIN30
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][3]}] ; #P11 PIN38
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][3]}] ; #P11 PIN39
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][3]}] ; #P11 PIN35
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][3]}] ; #P11 PIN36
set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][6]}] ; #P12 PIN53
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][6]}] ; #P12 PIN54
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][6]}] ; #P12 PIN50
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][6]}] ; #P12 PIN51

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkP[0][0]}]; #jesdSysRefP P11 PIN74
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {fpgaClkN[0][0]}]; #jesdSysRefN P11 PIN75

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[0][0]}]; #jesdSyncP P12 PIN165
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[0][1]}]; #jesdSyncN P12 PIN166
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[0][2]}]; #jesdSyncP P12 PIN167
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {jtagSec[0][3]}]; #jesdSyncN P12 PIN168

# LMK Ports
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][5]}]; #lmkClkSel P11 PIN162
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][5]}]; #lmkClkSel P11 PIN163
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[0][10]}]; #lmkSck P12 PIN129
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[0][15]}]; #lmkDio P12 PIN151
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[0][15]}]; #lmkSync P12 PIN150
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[0][10]}]; #lmkCsL P12 PIN130
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[0][14]}]; #lmkRst P12 PIN148

# Fast ADC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[0][4]}]; #adcCsL P11 PIN169
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[0][3]}]; #adcCsL P11 PIN157
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[0][1]}]; #adcSck P11 PIN166
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[0][3]}]; #adcMiso P11 PIN168
set_property -dict { IOSTANDARD LVCMOS25 PULLUP true } [get_ports {jtagPri[0][2]}]; #adcMosi P11 PIN167

# Slow DAC's SPI Ports    
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareP[0][12]}]; #dacCsL P12 PIN142                                                                 
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[0][13]}]; #dacSck P12 PIN144
set_property -dict { IOSTANDARD LVCMOS18 PULLUP true } [get_ports {spareN[0][12]}]; #dacMosi P12 PIN141

# Analog Control Ports
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][0]}]; #attn1A[0][0] P11 PIN93
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][0]}]; #attn1A[0][1] P11 PIN94
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][0]}]; #attn1A[0][2] P11 PIN96
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][0]}]; #attn1A[0][3] P11 PIN97
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][1]}]; #attn1A[0][4] P11 PIN99

set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][1]}]; #attn1B[0][0] P11 PIN100
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][1]}]; #attn1B[0][1] P11 PIN102
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][1]}]; #attn1B[0][2] P11 PIN103
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][2]}]; #attn1B[0][3] P11 PIN105
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][2]}]; #attn1B[0][4] P11 PIN106

set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][2]}]; #attn2A[0][0] P11 PIN108
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][2]}]; #attn2A[0][1] P11 PIN109
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][3]}]; #attn2A[0][2] P11 PIN111
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][3]}]; #attn2A[0][3] P11 PIN112
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][3]}]; #attn2A[0][4] P11 PIN114
                                                                   
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncInP [0][3]}]; #attn2B[0][0] P11 PIN115
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][0]}]; #attn2B[0][1] P11 PIN117
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][0]}]; #attn2B[0][2] P11 PIN118
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][1]}]; #attn2B[0][3] P11 PIN120
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][1]}]; #attn2B[0][4] P11 PIN121
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][2]}]; #attn3A[0][0] P11 PIN123
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][2]}]; #attn3A[0][1] P11 PIN124
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][3]}]; #attn3A[0][2] P11 PIN126
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][3]}]; #attn3A[0][3] P11 PIN127
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][4]}]; #attn3A[0][4] P11 PIN129
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][4]}]; #attn3B[0][0] P11 PIN130
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][5]}]; #attn3B[0][1] P11 PIN132
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][5]}]; #attn3B[0][2] P11 PIN133
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][8]}]; #attn3B[0][3] P11 PIN141
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][8]}]; #attn3B[0][4] P11 PIN142
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][9]}]; #attn4A[0][0] P11 PIN144
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][9]}]; #attn4A[0][1] P11 PIN145
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][0]}]; #attn4A[0][2] P11 PIN147
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][0]}]; #attn4A[0][3] P11 PIN148
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][1]}]; #attn4A[0][4] P11 PIN151
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][2]}]; #attn4B[0][0] P11 PIN153
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][2]}]; #attn4B[0][1] P11 PIN154
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][3]}]; #attn4B[0][2] P11 PIN156
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][4]}]; #attn4B[0][3] P11 PIN159
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][4]}]; #attn4B[0][4] P11 PIN160
                                                                               
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][6]}]; #attn5A[0][0] P12 PIN117
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][6]}]; #attn5A[0][1] P12 PIN118
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][7]}]; #attn5A[0][2] P12 PIN120
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][7]}]; #attn5A[0][3] P12 PIN121
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][8]}]; #attn5A[0][4] P12 PIN123

set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][11]}]; #clSw[0][0] P12 PIN132
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][11]}]; #clSw[0][1] P12 PIN133
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[0][1]}]; #clSw[0][2] P12 PIN74
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[0][1]}]; #clSw[0][3] P12 PIN75
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][7]}]; #clSw[0][4] P11 PIN138
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][7]}]; #clSw[0][5] P11 PIN139
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareN[0][9]}]; #clClkOe P12 PIN126
set_property -dict { IOSTANDARD LVCMOS18 } [get_ports {spareP[0][9]}]; #rfAmpOn P12 PIN127

# Triggers
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][6]}]; #extTrigP P11 PIN136
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][6]}]; #extTrigN P11 PIN135

