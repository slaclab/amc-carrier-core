##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 AMC Carrier Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
#######################
## Application Ports ##
#######################

# # RTM's High Speed Ports
# set_property PACKAGE_PIN B6 [get_ports {rtmHsTxP}]
# set_property PACKAGE_PIN B5 [get_ports {rtmHsTxN}]
# set_property PACKAGE_PIN A4 [get_ports {rtmHsRxP}]
# set_property PACKAGE_PIN A3 [get_ports {rtmHsRxN}]

# Spare Clock reference
set_property PACKAGE_PIN P6 [get_ports {genClkP}]
set_property PACKAGE_PIN P5 [get_ports {genClkN}]

# AMC's JESD Ports
set_property PACKAGE_PIN AB6 [get_ports {jesdClkP[0][0]}] ; #P11 PIN20
set_property PACKAGE_PIN AB5 [get_ports {jesdClkN[0][0]}] ; #P11 PIN21
set_property PACKAGE_PIN AF6 [get_ports {jesdClkP[0][1]}] ; #P11 PIN23
set_property PACKAGE_PIN AF5 [get_ports {jesdClkN[0][1]}] ; #P11 PIN24
set_property PACKAGE_PIN AD6 [get_ports {jesdClkP[0][2]}] ; #P11 PIN88 
set_property PACKAGE_PIN AD5 [get_ports {jesdClkN[0][2]}] ; #P11 PIN87 
set_property PACKAGE_PIN M6  [get_ports {jesdClkP[1][0]}] ; #P13 PIN20 
set_property PACKAGE_PIN M5  [get_ports {jesdClkN[1][0]}] ; #P13 PIN21 
set_property PACKAGE_PIN K6  [get_ports {jesdClkP[1][1]}] ; #P13 PIN23
set_property PACKAGE_PIN K5  [get_ports {jesdClkN[1][1]}] ; #P13 PIN24
set_property PACKAGE_PIN H6  [get_ports {jesdClkP[1][2]}] ; #P13 PIN88
set_property PACKAGE_PIN H5  [get_ports {jesdClkN[1][2]}] ; #P13 PIN87

# AMC's JTAG Ports
set_property -dict { PACKAGE_PIN AK8 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][0]}] ; #P11 PIN165 TCK
set_property -dict { PACKAGE_PIN AL8 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][1]}] ; #P11 PIN166 TMS
set_property -dict { PACKAGE_PIN AM9 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][2]}] ; #P11 PIN167 TRST
set_property -dict { PACKAGE_PIN AJ9 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][3]}] ; #P11 PIN168 TDO
set_property -dict { PACKAGE_PIN AJ8 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][4]}] ; #P11 PIN169 TDI
                                                                                         
set_property -dict { PACKAGE_PIN AN8  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][0]}] ; #P12 PIN165 TCK
set_property -dict { PACKAGE_PIN AP8  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][1]}] ; #P12 PIN166 TMS
set_property -dict { PACKAGE_PIN AK10 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][2]}] ; #P12 PIN167 TRST
set_property -dict { PACKAGE_PIN AL9  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][3]}] ; #P12 PIN168 TDO
set_property -dict { PACKAGE_PIN AN9  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][4]}] ; #P12 PIN169 TDI
                                                                                          
set_property -dict { PACKAGE_PIN AP9  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][0]}] ; #P13 PIN165 TCK
set_property -dict { PACKAGE_PIN AL10 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][1]}] ; #P13 PIN166 TMS
set_property -dict { PACKAGE_PIN AM10 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][2]}] ; #P13 PIN167 TRST
set_property -dict { PACKAGE_PIN AH9  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][3]}] ; #P13 PIN168 TDO
set_property -dict { PACKAGE_PIN AH8  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][4]}] ; #P13 PIN169 TDI
                                                                                         
set_property -dict { PACKAGE_PIN AD9  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][0]}] ; #P14 PIN165 TCK
set_property -dict { PACKAGE_PIN AD8  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][1]}] ; #P14 PIN166 TMS
set_property -dict { PACKAGE_PIN AD10 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][2]}] ; #P14 PIN167 TRST
set_property -dict { PACKAGE_PIN AE10 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][3]}] ; #P14 PIN168 TDO
set_property -dict { PACKAGE_PIN AE8  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][4]}] ; #P14 PIN169 TDI
  
# AMC's FPGA Clock Ports
set_property -dict { PACKAGE_PIN AD16 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[0][0]}] ; #P11 PIN74
set_property -dict { PACKAGE_PIN AD15 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[0][0]}] ; #P11 PIN75
set_property -dict { PACKAGE_PIN AE17 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[0][1]}] ; #P12 PIN74
set_property -dict { PACKAGE_PIN AF17 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[0][1]}] ; #P12 PIN75

set_property -dict { PACKAGE_PIN AE16 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[1][0]}] ; #P13 PIN74
set_property -dict { PACKAGE_PIN AE15 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[1][0]}] ; #P13 PIN75
set_property -dict { PACKAGE_PIN AE18 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[1][1]}] ; #P14 PIN74
set_property -dict { PACKAGE_PIN AF18 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[1][1]}] ; #P14 PIN75

# AMC's System Reference Ports
set_property -dict { PACKAGE_PIN AE32 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][0]}] ; #P11 PIN94
set_property -dict { PACKAGE_PIN AF32 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][0]}] ; #P11 PIN93
set_property -dict { PACKAGE_PIN AF33 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][1]}] ; #P11 PIN100
set_property -dict { PACKAGE_PIN AG34 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][1]}] ; #P11 PIN99
set_property -dict { PACKAGE_PIN AA34 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][2]}] ; #P11 PIN106
set_property -dict { PACKAGE_PIN AB34 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][2]}] ; #P11 PIN105
set_property -dict { PACKAGE_PIN AA29 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][3]}] ; #P11 PIN112
set_property -dict { PACKAGE_PIN AB29 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][3]}] ; #P11 PIN111

set_property -dict { PACKAGE_PIN AG31 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][0]}] ; #P13 PIN94
set_property -dict { PACKAGE_PIN AG32 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][0]}] ; #P13 PIN93
set_property -dict { PACKAGE_PIN AF30 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][1]}] ; #P13 PIN100
set_property -dict { PACKAGE_PIN AG30 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][1]}] ; #P13 PIN99
set_property -dict { PACKAGE_PIN AC34 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][2]}] ; #P13 PIN106
set_property -dict { PACKAGE_PIN AD34 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][2]}] ; #P13 PIN105
set_property -dict { PACKAGE_PIN AE33 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][3]}] ; #P13 PIN112
set_property -dict { PACKAGE_PIN AF34 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][3]}] ; #P13 PIN111

# AMC's Sync Ports
set_property -dict { PACKAGE_PIN AN23 IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][0]}] ; #P11 PIN97
set_property -dict { PACKAGE_PIN AP23 IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][0]}] ; #P11 PIN96
set_property -dict { PACKAGE_PIN AP24 IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][1]}] ; #P11 PIN103
set_property -dict { PACKAGE_PIN AP25 IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][1]}] ; #P11 PIN102
set_property -dict { PACKAGE_PIN AP20 IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][2]}] ; #P11 PIN109
set_property -dict { PACKAGE_PIN AP21 IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][2]}] ; #P11 PIN108
set_property -dict { PACKAGE_PIN AM24 IOSTANDARD LVCMOS18 } [get_ports {syncInP[0][3]}] ; #P11 PIN115
set_property -dict { PACKAGE_PIN AN24 IOSTANDARD LVCMOS18 } [get_ports {syncInN[0][3]}] ; #P11 PIN114

set_property -dict { PACKAGE_PIN AM22 IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][0]}] ; #P13 PIN97
set_property -dict { PACKAGE_PIN AN22 IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][0]}] ; #P13 PIN96
set_property -dict { PACKAGE_PIN AM21 IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][1]}] ; #P13 PIN103
set_property -dict { PACKAGE_PIN AN21 IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][1]}] ; #P13 PIN102
set_property -dict { PACKAGE_PIN AL24 IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][2]}] ; #P13 PIN109
set_property -dict { PACKAGE_PIN AL25 IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][2]}] ; #P13 PIN108
set_property -dict { PACKAGE_PIN AL22 IOSTANDARD LVCMOS18 } [get_ports {syncInP[1][3]}] ; #P13 PIN115
set_property -dict { PACKAGE_PIN AL23 IOSTANDARD LVCMOS18 } [get_ports {syncInN[1][3]}] ; #P13 PIN114

set_property -dict { PACKAGE_PIN AJ20 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][0]}] ; #P11 PIN118
set_property -dict { PACKAGE_PIN AK20 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][0]}] ; #P11 PIN117
set_property -dict { PACKAGE_PIN AL20 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][1]}] ; #P11 PIN121
set_property -dict { PACKAGE_PIN AM20 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][1]}] ; #P11 PIN120
set_property -dict { PACKAGE_PIN AH24 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][2]}] ; #P11 PIN124
set_property -dict { PACKAGE_PIN AJ25 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][2]}] ; #P11 PIN123
set_property -dict { PACKAGE_PIN AG24 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][3]}] ; #P11 PIN127
set_property -dict { PACKAGE_PIN AG25 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][3]}] ; #P11 PIN126
set_property -dict { PACKAGE_PIN AF23 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][4]}] ; #P11 PIN130
set_property -dict { PACKAGE_PIN AF24 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][4]}] ; #P11 PIN129
set_property -dict { PACKAGE_PIN AE25 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][5]}] ; #P11 PIN133
set_property -dict { PACKAGE_PIN AE26 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][5]}] ; #P11 PIN132
set_property -dict { PACKAGE_PIN AF22 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][6]}] ; #P11 PIN136
set_property -dict { PACKAGE_PIN AG22 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][6]}] ; #P11 PIN135
set_property -dict { PACKAGE_PIN AE22 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][7]}] ; #P11 PIN139
set_property -dict { PACKAGE_PIN AE23 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][7]}] ; #P11 PIN138
set_property -dict { PACKAGE_PIN AG21 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][8]}] ; #P11 PIN142
set_property -dict { PACKAGE_PIN AH21 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][8]}] ; #P11 PIN141
set_property -dict { PACKAGE_PIN AD20 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[0][9]}] ; #P11 PIN145
set_property -dict { PACKAGE_PIN AE20 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[0][9]}] ; #P11 PIN144
                                                                                                               
set_property -dict { PACKAGE_PIN AF20 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][0]}] ; #P13 PIN118  
set_property -dict { PACKAGE_PIN AG20 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][0]}] ; #P13 PIN117  
set_property -dict { PACKAGE_PIN AD21 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][1]}] ; #P13 PIN121  
set_property -dict { PACKAGE_PIN AE21 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][1]}] ; #P13 PIN120
set_property -dict { PACKAGE_PIN AN14 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][2]}] ; #P13 PIN124
set_property -dict { PACKAGE_PIN AP14 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][2]}] ; #P13 PIN123
set_property -dict { PACKAGE_PIN V31  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][3]}] ; #P13 PIN127
set_property -dict { PACKAGE_PIN W31  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][3]}] ; #P13 PIN126
set_property -dict { PACKAGE_PIN U34  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][4]}] ; #P13 PIN130
set_property -dict { PACKAGE_PIN V34  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][4]}] ; #P13 PIN129
set_property -dict { PACKAGE_PIN Y31  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][5]}] ; #P13 PIN133
set_property -dict { PACKAGE_PIN Y32  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][5]}] ; #P13 PIN132
set_property -dict { PACKAGE_PIN V33  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][6]}] ; #P13 PIN136
set_property -dict { PACKAGE_PIN W34  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][6]}] ; #P13 PIN135
set_property -dict { PACKAGE_PIN W30  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][7]}] ; #P13 PIN139
set_property -dict { PACKAGE_PIN Y30  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][7]}] ; #P13 PIN138
set_property -dict { PACKAGE_PIN W33  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][8]}] ; #P13 PIN142
set_property -dict { PACKAGE_PIN Y33  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][8]}] ; #P13 PIN141
set_property -dict { PACKAGE_PIN AC33 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][9]}] ; #P13 PIN145
set_property -dict { PACKAGE_PIN AD33 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][9]}] ; #P13 PIN144

# AMC's Spare Ports
set_property -dict { PACKAGE_PIN AK22 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][0]}] ; #P11 PIN148
set_property -dict { PACKAGE_PIN AK23 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][0]}] ; #P11 PIN147
set_property -dict { PACKAGE_PIN AJ21 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][1]}] ; #P11 PIN151
set_property -dict { PACKAGE_PIN AK21 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][1]}] ; #P11 PIN150
set_property -dict { PACKAGE_PIN AH22 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][2]}] ; #P11 PIN154
set_property -dict { PACKAGE_PIN AH23 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][2]}] ; #P11 PIN153
set_property -dict { PACKAGE_PIN AJ23 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][3]}] ; #P11 PIN157
set_property -dict { PACKAGE_PIN AJ24 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][3]}] ; #P11 PIN156
set_property -dict { PACKAGE_PIN V26  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][4]}] ; #P11 PIN160
set_property -dict { PACKAGE_PIN W26  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][4]}] ; #P11 PIN159
set_property -dict { PACKAGE_PIN V29  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][5]}] ; #P11 PIN163
set_property -dict { PACKAGE_PIN W29  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][5]}] ; #P11 PIN162
set_property -dict { PACKAGE_PIN AH16 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][6]}] ; #P12 PIN118
set_property -dict { PACKAGE_PIN AJ16 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][6]}] ; #P12 PIN117
set_property -dict { PACKAGE_PIN AH18 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][7]}] ; #P12 PIN121
set_property -dict { PACKAGE_PIN AH17 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][7]}] ; #P12 PIN120
set_property -dict { PACKAGE_PIN AK17 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][8]}] ; #P12 PIN124
set_property -dict { PACKAGE_PIN AK16 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][8]}] ; #P12 PIN123
set_property -dict { PACKAGE_PIN AJ18 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][9]}] ; #P12 PIN127
set_property -dict { PACKAGE_PIN AK18 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][9]}] ; #P12 PIN126
set_property -dict { PACKAGE_PIN U26  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][10]}] ; #P12 PIN130
set_property -dict { PACKAGE_PIN U27  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][10]}] ; #P12 PIN129
set_property -dict { PACKAGE_PIN W28  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][11]}] ; #P12 PIN133
set_property -dict { PACKAGE_PIN Y28  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][11]}] ; #P12 PIN132
set_property -dict { PACKAGE_PIN U24  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][12]}] ; #P12 PIN142
set_property -dict { PACKAGE_PIN U25  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][12]}] ; #P12 PIN141
set_property -dict { PACKAGE_PIN V27  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][13]}] ; #P12 PIN145
set_property -dict { PACKAGE_PIN V28  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][13]}] ; #P12 PIN144
set_property -dict { PACKAGE_PIN V21  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][14]}] ; #P12 PIN148
set_property -dict { PACKAGE_PIN W21  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][14]}] ; #P12 PIN147
set_property -dict { PACKAGE_PIN T22  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][15]}] ; #P12 PIN151
set_property -dict { PACKAGE_PIN T23  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][15]}] ; #P12 PIN150

set_property -dict { PACKAGE_PIN W25  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][0]}] ; #P13 PIN148
set_property -dict { PACKAGE_PIN Y25  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][0]}] ; #P13 PIN147
set_property -dict { PACKAGE_PIN W23  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][1]}] ; #P13 PIN151
set_property -dict { PACKAGE_PIN W24  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][1]}] ; #P13 PIN150
set_property -dict { PACKAGE_PIN AA24 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][2]}] ; #P13 PIN154
set_property -dict { PACKAGE_PIN AA25 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][2]}] ; #P13 PIN153
set_property -dict { PACKAGE_PIN Y23  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][3]}] ; #P13 PIN157
set_property -dict { PACKAGE_PIN AA23 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][3]}] ; #P13 PIN156
set_property -dict { PACKAGE_PIN AA20 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][4]}] ; #P13 PIN160
set_property -dict { PACKAGE_PIN AB20 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][4]}] ; #P13 PIN159
set_property -dict { PACKAGE_PIN AC22 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][5]}] ; #P13 PIN163
set_property -dict { PACKAGE_PIN AC23 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][5]}] ; #P13 PIN162
set_property -dict { PACKAGE_PIN AB30 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][6]}] ; #P14 PIN118
set_property -dict { PACKAGE_PIN AB31 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][6]}] ; #P14 PIN117
set_property -dict { PACKAGE_PIN AA32 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][7]}] ; #P14 PIN121
set_property -dict { PACKAGE_PIN AB32 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][7]}] ; #P14 PIN120
set_property -dict { PACKAGE_PIN AC31 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][8]}] ; #P14 PIN124
set_property -dict { PACKAGE_PIN AC32 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][8]}] ; #P14 PIN123
set_property -dict { PACKAGE_PIN AD30 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][9]}] ; #P14 PIN127
set_property -dict { PACKAGE_PIN AD31 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][9]}] ; #P14 PIN126
set_property -dict { PACKAGE_PIN AB25 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][10]}] ; #P14 PIN130
set_property -dict { PACKAGE_PIN AB26 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][10]}] ; #P14 PIN129
set_property -dict { PACKAGE_PIN AA27 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][11]}] ; #P14 PIN133
set_property -dict { PACKAGE_PIN AB27 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][11]}] ; #P14 PIN132
set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][12]}] ; #P14 PIN142
set_property -dict { PACKAGE_PIN AC27 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][12]}] ; #P14 PIN141
set_property -dict { PACKAGE_PIN AB24 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][13]}] ; #P14 PIN145
set_property -dict { PACKAGE_PIN AC24 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][13]}] ; #P14 PIN144
set_property -dict { PACKAGE_PIN AD25 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][14]}] ; #P14 PIN148
set_property -dict { PACKAGE_PIN AD26 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][14]}] ; #P14 PIN147
set_property -dict { PACKAGE_PIN Y26  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][15]}] ; #P14 PIN151
set_property -dict { PACKAGE_PIN Y27  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][15]}] ; #P14 PIN150

# RTM's Low Speed Ports
set_property -dict { PACKAGE_PIN AK31 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[0]}]
set_property -dict { PACKAGE_PIN AK32 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[0]}]
set_property -dict { PACKAGE_PIN AJ29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[1]}]
set_property -dict { PACKAGE_PIN AK30 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[1]}]
set_property -dict { PACKAGE_PIN AL30 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[2]}]
set_property -dict { PACKAGE_PIN AM30 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[2]}]
set_property -dict { PACKAGE_PIN AL29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[3]}]
set_property -dict { PACKAGE_PIN AM29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[3]}]
set_property -dict { PACKAGE_PIN AL34 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[4]}]
set_property -dict { PACKAGE_PIN AM34 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[4]}]
set_property -dict { PACKAGE_PIN AM32 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[5]}]
set_property -dict { PACKAGE_PIN AN32 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[5]}]
set_property -dict { PACKAGE_PIN AN34 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[6]}]
set_property -dict { PACKAGE_PIN AP34 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[6]}]
set_property -dict { PACKAGE_PIN AN31 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[7]}]
set_property -dict { PACKAGE_PIN AP31 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[7]}]
set_property -dict { PACKAGE_PIN AN33 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[8]}]
set_property -dict { PACKAGE_PIN AP33 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[8]}]
set_property -dict { PACKAGE_PIN AL32 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[9]}]
set_property -dict { PACKAGE_PIN AL33 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[9]}]
set_property -dict { PACKAGE_PIN AH34 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[10]}]
set_property -dict { PACKAGE_PIN AJ34 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[10]}]
set_property -dict { PACKAGE_PIN AH31 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[11]}]
set_property -dict { PACKAGE_PIN AH32 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[11]}]
set_property -dict { PACKAGE_PIN AH33 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[12]}]
set_property -dict { PACKAGE_PIN AJ33 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[12]}]
set_property -dict { PACKAGE_PIN AJ30 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[13]}]
set_property -dict { PACKAGE_PIN AJ31 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[13]}]
set_property -dict { PACKAGE_PIN AN29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[14]}]
set_property -dict { PACKAGE_PIN AP30 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[14]}]
set_property -dict { PACKAGE_PIN AN27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[15]}]
set_property -dict { PACKAGE_PIN AN28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[15]}]
set_property -dict { PACKAGE_PIN AP28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[16]}]
set_property -dict { PACKAGE_PIN AP29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[16]}]
set_property -dict { PACKAGE_PIN AN26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[17]}]
set_property -dict { PACKAGE_PIN AP26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[17]}]
set_property -dict { PACKAGE_PIN AJ28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[18]}]
set_property -dict { PACKAGE_PIN AK28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[18]}]
set_property -dict { PACKAGE_PIN AH27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[19]}]
set_property -dict { PACKAGE_PIN AH28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[19]}]
set_property -dict { PACKAGE_PIN AL27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[20]}]
set_property -dict { PACKAGE_PIN AL28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[20]}]
set_property -dict { PACKAGE_PIN AK26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[21]}]
set_property -dict { PACKAGE_PIN AK27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[21]}]
set_property -dict { PACKAGE_PIN AM26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[22]}]
set_property -dict { PACKAGE_PIN AM27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[22]}]
set_property -dict { PACKAGE_PIN AH26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[23]}]
set_property -dict { PACKAGE_PIN AJ26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[23]}]
set_property -dict { PACKAGE_PIN AE27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[24]}]
set_property -dict { PACKAGE_PIN AF27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[24]}]
set_property -dict { PACKAGE_PIN AM12 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[25]}]
set_property -dict { PACKAGE_PIN AN12 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[25]}]
set_property -dict { PACKAGE_PIN AM11 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[26]}]
set_property -dict { PACKAGE_PIN AN11 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[26]}]
set_property -dict { PACKAGE_PIN AN13 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[27]}]
set_property -dict { PACKAGE_PIN AP13 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[27]}]
set_property -dict { PACKAGE_PIN K20 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[28]}]
set_property -dict { PACKAGE_PIN K21 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[28]}]
set_property -dict { PACKAGE_PIN N21 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[29]}]
set_property -dict { PACKAGE_PIN M21 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[29]}]
set_property -dict { PACKAGE_PIN M20 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[30]}]
set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[30]}]
set_property -dict { PACKAGE_PIN R21 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[31]}]
set_property -dict { PACKAGE_PIN R22 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[31]}]
set_property -dict { PACKAGE_PIN P20 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[32]}]
set_property -dict { PACKAGE_PIN P21 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[32]}]
set_property -dict { PACKAGE_PIN N22 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[33]}]
set_property -dict { PACKAGE_PIN M22 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[33]}]
set_property -dict { PACKAGE_PIN R23 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[34]}]
set_property -dict { PACKAGE_PIN P23 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[34]}]
set_property -dict { PACKAGE_PIN R25 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[35]}]
set_property -dict { PACKAGE_PIN R26 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[35]}]
set_property -dict { PACKAGE_PIN T24 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[36]}]
set_property -dict { PACKAGE_PIN T25 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[36]}]
set_property -dict { PACKAGE_PIN T27 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[37]}]
set_property -dict { PACKAGE_PIN R27 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[37]}]
set_property -dict { PACKAGE_PIN P24 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[38]}]
set_property -dict { PACKAGE_PIN P25 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[38]}]
set_property -dict { PACKAGE_PIN P26 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[39]}]
set_property -dict { PACKAGE_PIN N26 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[39]}]
set_property -dict { PACKAGE_PIN N24 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[40]}]
set_property -dict { PACKAGE_PIN M24 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[40]}]
set_property -dict { PACKAGE_PIN M25 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[41]}]
set_property -dict { PACKAGE_PIN M26 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[41]}]
set_property -dict { PACKAGE_PIN L22 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[42]}]
set_property -dict { PACKAGE_PIN K23 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[42]}]
set_property -dict { PACKAGE_PIN L25 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[43]}]
set_property -dict { PACKAGE_PIN K25 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[43]}]
set_property -dict { PACKAGE_PIN L23 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[44]}]
set_property -dict { PACKAGE_PIN L24 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[44]}]
set_property -dict { PACKAGE_PIN M27 IOSTANDARD LVCMOS25 } [get_ports {rtmLsP[45]}]
set_property -dict { PACKAGE_PIN L27 IOSTANDARD LVCMOS25 } [get_ports {rtmLsN[45]}]
set_property -dict { PACKAGE_PIN AD29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[46]}]
set_property -dict { PACKAGE_PIN AE30 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[46]}]
set_property -dict { PACKAGE_PIN AF29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[47]}]
set_property -dict { PACKAGE_PIN AG29 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[47]}]
set_property -dict { PACKAGE_PIN AC28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[48]}]
set_property -dict { PACKAGE_PIN AD28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[48]}]
set_property -dict { PACKAGE_PIN AE28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[49]}]
set_property -dict { PACKAGE_PIN AF28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[49]}]
set_property -dict { PACKAGE_PIN V22  IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[50]}]
set_property -dict { PACKAGE_PIN V23  IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[50]}]
set_property -dict { PACKAGE_PIN U21  IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[51]}]
set_property -dict { PACKAGE_PIN U22  IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[51]}]
set_property -dict { PACKAGE_PIN AB21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[52]}]
set_property -dict { PACKAGE_PIN AC21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[52]}]
set_property -dict { PACKAGE_PIN AA22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[53]}]
set_property -dict { PACKAGE_PIN AB22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[53]}]

####################################
## Application Timing Constraints ##
####################################

create_clock -name jesdClk00 -period 5.405 [get_ports {jesdClkP[0][0]}]
create_clock -name jesdClk01 -period 5.405 [get_ports {jesdClkP[0][1]}]
create_clock -name jesdClk02 -period 5.405 [get_ports {jesdClkP[0][2]}]
create_clock -name jesdClk10 -period 5.405 [get_ports {jesdClkP[1][0]}]
create_clock -name jesdClk11 -period 5.405 [get_ports {jesdClkP[1][1]}]
create_clock -name jesdClk12 -period 5.405 [get_ports {jesdClkP[1][2]}]
create_clock -name mpsClkP   -period 8.000 [get_ports {mpsClkIn}]

create_generated_clock -name mpsClk625MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name mpsClk312MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT1}] 
create_generated_clock -name mpsClk125MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT2}] 

create_generated_clock -name jesd0_185MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd0_370MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name jesd1_185MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd1_370MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {jesd1_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {jesd1_370MHz}]

##########################
## Misc. Configurations ##
##########################
