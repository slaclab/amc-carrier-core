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
# set_property PACKAGE_PIN D31 [get_ports {rtmHsTxP}]
# set_property PACKAGE_PIN D32 [get_ports {rtmHsTxN}]
# set_property PACKAGE_PIN E33 [get_ports {rtmHsRxP}]
# set_property PACKAGE_PIN E34 [get_ports {rtmHsRxN}]

# # Spare Clock reference
# set_property PACKAGE_PIN AD6 [get_ports {genClkP}]
# set_property PACKAGE_PIN AD5 [get_ports {genClkN}]

# Default JESD High Speed Port Mapping for BAY[0]
set_property PACKAGE_PIN AL4 [get_ports {jesdTxP[0][0]}] ; #
set_property PACKAGE_PIN AL3 [get_ports {jesdTxN[0][0]}] ; #
set_property PACKAGE_PIN AK2 [get_ports {jesdRxP[0][0]}] ; #
set_property PACKAGE_PIN AK1 [get_ports {jesdRxN[0][0]}] ; #
set_property PACKAGE_PIN AK6 [get_ports {jesdTxP[0][1]}] ; # 
set_property PACKAGE_PIN AK5 [get_ports {jesdTxN[0][1]}] ; #
set_property PACKAGE_PIN AJ4 [get_ports {jesdRxP[0][1]}] ; #
set_property PACKAGE_PIN AJ3 [get_ports {jesdRxN[0][1]}] ; #
set_property PACKAGE_PIN AH6 [get_ports {jesdTxP[0][2]}] ; #
set_property PACKAGE_PIN AH5 [get_ports {jesdTxN[0][2]}] ; #
set_property PACKAGE_PIN AH2 [get_ports {jesdRxP[0][2]}] ; #
set_property PACKAGE_PIN AH1 [get_ports {jesdRxN[0][2]}] ; #
set_property PACKAGE_PIN AG4 [get_ports {jesdTxP[0][3]}] ; #
set_property PACKAGE_PIN AG3 [get_ports {jesdTxN[0][3]}] ; #
set_property PACKAGE_PIN AF2 [get_ports {jesdRxP[0][3]}] ; #
set_property PACKAGE_PIN AF1 [get_ports {jesdRxN[0][3]}] ; #
set_property PACKAGE_PIN AN4 [get_ports {jesdTxP[0][4]}] ; #
set_property PACKAGE_PIN AN3 [get_ports {jesdTxN[0][4]}] ; #
set_property PACKAGE_PIN AP2 [get_ports {jesdRxP[0][4]}] ; #
set_property PACKAGE_PIN AP1 [get_ports {jesdRxN[0][4]}] ; #
set_property PACKAGE_PIN AM6 [get_ports {jesdTxP[0][5]}] ; #
set_property PACKAGE_PIN AM5 [get_ports {jesdTxN[0][5]}] ; #
set_property PACKAGE_PIN AM2 [get_ports {jesdRxP[0][5]}] ; #
set_property PACKAGE_PIN AM1 [get_ports {jesdRxN[0][5]}] ; #
set_property PACKAGE_PIN AE4 [get_ports {jesdTxP[0][6]}] ; #
set_property PACKAGE_PIN AE3 [get_ports {jesdTxN[0][6]}] ; #
set_property PACKAGE_PIN AD2 [get_ports {jesdRxP[0][6]}] ; #
set_property PACKAGE_PIN AD1 [get_ports {jesdRxN[0][6]}] ; #
set_property PACKAGE_PIN AC4 [get_ports {jesdTxP[0][7]}] ; #
set_property PACKAGE_PIN AC3 [get_ports {jesdTxN[0][7]}] ; #
set_property PACKAGE_PIN AB2 [get_ports {jesdRxP[0][7]}] ; #
set_property PACKAGE_PIN AB1 [get_ports {jesdRxN[0][7]}] ; #
set_property PACKAGE_PIN AA4 [get_ports {jesdTxP[0][8]}] ; #
set_property PACKAGE_PIN AA3 [get_ports {jesdTxN[0][8]}] ; #
set_property PACKAGE_PIN Y2  [get_ports {jesdRxP[0][8]}] ; #
set_property PACKAGE_PIN Y1  [get_ports {jesdRxN[0][8]}] ; #
set_property PACKAGE_PIN W4  [get_ports {jesdTxP[0][9]}] ; #
set_property PACKAGE_PIN W3  [get_ports {jesdTxN[0][9]}] ; #
set_property PACKAGE_PIN V2  [get_ports {jesdRxP[0][9]}] ; #
set_property PACKAGE_PIN V1  [get_ports {jesdRxN[0][9]}] ; #

# Default JESD High Speed Port Mapping for BAY[1]
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
set_property PACKAGE_PIN U4 [get_ports {jesdTxP[1][4]}] ; #
set_property PACKAGE_PIN U3 [get_ports {jesdTxN[1][4]}] ; #
set_property PACKAGE_PIN T2 [get_ports {jesdRxP[1][4]}] ; #
set_property PACKAGE_PIN T1 [get_ports {jesdRxN[1][4]}] ; #
set_property PACKAGE_PIN R4 [get_ports {jesdTxP[1][5]}] ; #
set_property PACKAGE_PIN R3 [get_ports {jesdTxN[1][5]}] ; #
set_property PACKAGE_PIN P2 [get_ports {jesdRxP[1][5]}] ; #
set_property PACKAGE_PIN P1 [get_ports {jesdRxN[1][5]}] ; #
set_property PACKAGE_PIN F6 [get_ports {jesdTxP[1][6]}] ; #
set_property PACKAGE_PIN F5 [get_ports {jesdTxN[1][6]}] ; #
set_property PACKAGE_PIN E4 [get_ports {jesdRxP[1][6]}] ; #
set_property PACKAGE_PIN E3 [get_ports {jesdRxN[1][6]}] ; #
set_property PACKAGE_PIN D6 [get_ports {jesdTxP[1][7]}] ; #
set_property PACKAGE_PIN D5 [get_ports {jesdTxN[1][7]}] ; #
set_property PACKAGE_PIN D2 [get_ports {jesdRxP[1][7]}] ; #
set_property PACKAGE_PIN D1 [get_ports {jesdRxN[1][7]}] ; #
set_property PACKAGE_PIN C4 [get_ports {jesdTxP[1][8]}] ; #
set_property PACKAGE_PIN C3 [get_ports {jesdTxN[1][8]}] ; #
set_property PACKAGE_PIN B2 [get_ports {jesdRxP[1][8]}] ; #
set_property PACKAGE_PIN B1 [get_ports {jesdRxN[1][8]}] ; #
set_property PACKAGE_PIN B6 [get_ports {jesdTxP[1][9]}] ; #
set_property PACKAGE_PIN B5 [get_ports {jesdTxN[1][9]}] ; #
set_property PACKAGE_PIN A4 [get_ports {jesdRxP[1][9]}] ; #
set_property PACKAGE_PIN A3 [get_ports {jesdRxN[1][9]}] ; #

# AMC's JESD Ports
set_property PACKAGE_PIN T6  [get_ports {jesdClkP[0][0]}] ; #P11 PIN20
set_property PACKAGE_PIN T5  [get_ports {jesdClkN[0][0]}] ; #P11 PIN21
set_property PACKAGE_PIN AB6 [get_ports {jesdClkP[0][1]}] ; #P11 PIN23
set_property PACKAGE_PIN AB5 [get_ports {jesdClkN[0][1]}] ; #P11 PIN24
set_property PACKAGE_PIN Y6  [get_ports {jesdClkP[0][2]}] ; #P11 PIN88 
set_property PACKAGE_PIN Y5  [get_ports {jesdClkN[0][2]}] ; #P11 PIN87 
set_property PACKAGE_PIN AF6 [get_ports {jesdClkP[0][3]}] ; #P11 PIN88 
set_property PACKAGE_PIN AF5 [get_ports {jesdClkN[0][3]}] ; #P11 PIN87 

set_property PACKAGE_PIN V6  [get_ports {jesdClkP[1][0]}] ; #P13 PIN20 
set_property PACKAGE_PIN V5  [get_ports {jesdClkN[1][0]}] ; #P13 PIN21 
set_property PACKAGE_PIN P6  [get_ports {jesdClkP[1][1]}] ; #P13 PIN23
set_property PACKAGE_PIN P5  [get_ports {jesdClkN[1][1]}] ; #P13 PIN24
set_property PACKAGE_PIN M6  [get_ports {jesdClkP[1][2]}] ; #P13 PIN88
set_property PACKAGE_PIN M5  [get_ports {jesdClkN[1][2]}] ; #P13 PIN87
set_property PACKAGE_PIN K6  [get_ports {jesdClkP[1][3]}] ; #P13 PIN88
set_property PACKAGE_PIN K5  [get_ports {jesdClkN[1][3]}] ; #P13 PIN87

# AMC's JTAG Ports
set_property -dict { PACKAGE_PIN AK8  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][0]}] ; #P11 PIN165 TCK
set_property -dict { PACKAGE_PIN AL8  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][1]}] ; #P11 PIN166 TMS
set_property -dict { PACKAGE_PIN AP11 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][2]}] ; #P11 PIN167 TRST
set_property -dict { PACKAGE_PIN AJ9  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][3]}] ; #P11 PIN168 TDO
set_property -dict { PACKAGE_PIN AJ8  IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][4]}] ; #P11 PIN169 TDI
                                                                                         
set_property -dict { PACKAGE_PIN AN8  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][0]}] ; #P12 PIN165 TCK
set_property -dict { PACKAGE_PIN AP8  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][1]}] ; #P12 PIN166 TMS
set_property -dict { PACKAGE_PIN AK10 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][2]}] ; #P12 PIN167 TRST
set_property -dict { PACKAGE_PIN AL9  IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][3]}] ; #P12 PIN168 TDO
set_property -dict { PACKAGE_PIN AF10 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[0][4]}] ; #P12 PIN169 TDI
                                                                                          
set_property -dict { PACKAGE_PIN AG10 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][0]}] ; #P13 PIN165 TCK
set_property -dict { PACKAGE_PIN AG11 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][1]}] ; #P13 PIN166 TMS
set_property -dict { PACKAGE_PIN AH11 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][2]}] ; #P13 PIN167 TRST
set_property -dict { PACKAGE_PIN AG12 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][3]}] ; #P13 PIN168 TDO
set_property -dict { PACKAGE_PIN AH12 IOSTANDARD LVCMOS25 } [get_ports {jtagPri[1][4]}] ; #P13 PIN169 TDI
                                                                                         
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][0]}] ; #P14 PIN165 TCK
set_property -dict { PACKAGE_PIN AE11 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][1]}] ; #P14 PIN166 TMS
set_property -dict { PACKAGE_PIN AE12 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][2]}] ; #P14 PIN167 TRST
set_property -dict { PACKAGE_PIN AF12 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][3]}] ; #P14 PIN168 TDO
set_property -dict { PACKAGE_PIN AP10 IOSTANDARD LVCMOS25 } [get_ports {jtagSec[1][4]}] ; #P14 PIN169 TDI
  
# AMC's FPGA Clock Ports
set_property -dict { PACKAGE_PIN V33 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[0][0]}] ; #P11 PIN74
set_property -dict { PACKAGE_PIN W34 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[0][0]}] ; #P11 PIN75
set_property -dict { PACKAGE_PIN W33 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[0][1]}] ; #P12 PIN74
set_property -dict { PACKAGE_PIN Y33 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[0][1]}] ; #P12 PIN75

set_property -dict { PACKAGE_PIN AD29 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[1][0]}] ; #P13 PIN74
set_property -dict { PACKAGE_PIN AE30 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[1][0]}] ; #P13 PIN75
set_property -dict { PACKAGE_PIN AC28 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkP[1][1]}] ; #P14 PIN74
set_property -dict { PACKAGE_PIN AD28 IOSTANDARD LVCMOS18 } [get_ports {fpgaClkN[1][1]}] ; #P14 PIN75

# AMC's System Reference Ports
set_property -dict { PACKAGE_PIN AB21 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][0]}] ; #P11 PIN94
set_property -dict { PACKAGE_PIN AC21 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][0]}] ; #P11 PIN93
set_property -dict { PACKAGE_PIN AA20 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][1]}] ; #P11 PIN100
set_property -dict { PACKAGE_PIN AB20 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][1]}] ; #P11 PIN99
set_property -dict { PACKAGE_PIN T22  IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][2]}] ; #P11 PIN106
set_property -dict { PACKAGE_PIN T23  IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][2]}] ; #P11 PIN105
set_property -dict { PACKAGE_PIN V22  IOSTANDARD LVCMOS18 } [get_ports {sysRefP[0][3]}] ; #P11 PIN112
set_property -dict { PACKAGE_PIN V23  IOSTANDARD LVCMOS18 } [get_ports {sysRefN[0][3]}] ; #P11 PIN111

set_property -dict { PACKAGE_PIN AC22 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][0]}] ; #P13 PIN94
set_property -dict { PACKAGE_PIN AC23 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][0]}] ; #P13 PIN93
set_property -dict { PACKAGE_PIN AA22 IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][1]}] ; #P13 PIN100
set_property -dict { PACKAGE_PIN AB22 IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][1]}] ; #P13 PIN99
set_property -dict { PACKAGE_PIN U21  IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][2]}] ; #P13 PIN106
set_property -dict { PACKAGE_PIN U22  IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][2]}] ; #P13 PIN105
set_property -dict { PACKAGE_PIN F27  IOSTANDARD LVCMOS18 } [get_ports {sysRefP[1][3]}] ; #P13 PIN112
set_property -dict { PACKAGE_PIN E27  IOSTANDARD LVCMOS18 } [get_ports {sysRefN[1][3]}] ; #P13 PIN111

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
set_property -dict { PACKAGE_PIN AE32 IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][2]}] ; #P13 PIN124
set_property -dict { PACKAGE_PIN AF32 IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][2]}] ; #P13 PIN123
set_property -dict { PACKAGE_PIN G19  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][3]}] ; #P13 PIN127
set_property -dict { PACKAGE_PIN F19  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][3]}] ; #P13 PIN126
set_property -dict { PACKAGE_PIN G15  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][4]}] ; #P13 PIN130
set_property -dict { PACKAGE_PIN G14  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][4]}] ; #P13 PIN129
set_property -dict { PACKAGE_PIN D19  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][5]}] ; #P13 PIN133
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][5]}] ; #P13 PIN132
set_property -dict { PACKAGE_PIN D14  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][6]}] ; #P13 PIN136
set_property -dict { PACKAGE_PIN C14  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][6]}] ; #P13 PIN135
set_property -dict { PACKAGE_PIN B29  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][7]}] ; #P13 PIN139
set_property -dict { PACKAGE_PIN A29  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][7]}] ; #P13 PIN138
set_property -dict { PACKAGE_PIN E28  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][8]}] ; #P13 PIN142
set_property -dict { PACKAGE_PIN D29  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][8]}] ; #P13 PIN141
set_property -dict { PACKAGE_PIN C27  IOSTANDARD LVCMOS18 } [get_ports {syncOutP[1][9]}] ; #P13 PIN145
set_property -dict { PACKAGE_PIN B27  IOSTANDARD LVCMOS18 } [get_ports {syncOutN[1][9]}] ; #P13 PIN144

# AMC's Spare Ports
set_property -dict { PACKAGE_PIN AK22 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][0]}] ; #P11 PIN148
set_property -dict { PACKAGE_PIN AK23 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][0]}] ; #P11 PIN147
set_property -dict { PACKAGE_PIN AJ21 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][1]}] ; #P11 PIN151
set_property -dict { PACKAGE_PIN AK21 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][1]}] ; #P11 PIN150
set_property -dict { PACKAGE_PIN AH22 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][2]}] ; #P11 PIN154
set_property -dict { PACKAGE_PIN AH23 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][2]}] ; #P11 PIN153
set_property -dict { PACKAGE_PIN AJ23 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][3]}] ; #P11 PIN157
set_property -dict { PACKAGE_PIN AJ24 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][3]}] ; #P11 PIN156
set_property -dict { PACKAGE_PIN L19  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][4]}] ; #P11 PIN160
set_property -dict { PACKAGE_PIN L18  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][4]}] ; #P11 PIN159
set_property -dict { PACKAGE_PIN K16  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][5]}] ; #P11 PIN163
set_property -dict { PACKAGE_PIN J16  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][5]}] ; #P11 PIN162
set_property -dict { PACKAGE_PIN AB30 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][6]}] ; #P12 PIN118
set_property -dict { PACKAGE_PIN AB31 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][6]}] ; #P12 PIN117
set_property -dict { PACKAGE_PIN AA32 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][7]}] ; #P12 PIN121
set_property -dict { PACKAGE_PIN AB32 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][7]}] ; #P12 PIN120
set_property -dict { PACKAGE_PIN AC31 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][8]}] ; #P12 PIN124
set_property -dict { PACKAGE_PIN AC32 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][8]}] ; #P12 PIN123
set_property -dict { PACKAGE_PIN AD30 IOSTANDARD LVCMOS18 } [get_ports {spareP[0][9]}] ; #P12 PIN127
set_property -dict { PACKAGE_PIN AD31 IOSTANDARD LVCMOS18 } [get_ports {spareN[0][9]}] ; #P12 PIN126
set_property -dict { PACKAGE_PIN J19  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][10]}] ; #P12 PIN130
set_property -dict { PACKAGE_PIN J18  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][10]}] ; #P12 PIN129
set_property -dict { PACKAGE_PIN L15  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][11]}] ; #P12 PIN133
set_property -dict { PACKAGE_PIN K15  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][11]}] ; #P12 PIN132
set_property -dict { PACKAGE_PIN K18  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][12]}] ; #P12 PIN142
set_property -dict { PACKAGE_PIN K17  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][12]}] ; #P12 PIN141
set_property -dict { PACKAGE_PIN J15  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][13]}] ; #P12 PIN145
set_property -dict { PACKAGE_PIN J14  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][13]}] ; #P12 PIN144
set_property -dict { PACKAGE_PIN H19  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][14]}] ; #P12 PIN148
set_property -dict { PACKAGE_PIN H18  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][14]}] ; #P12 PIN147
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS18 } [get_ports {spareP[0][15]}] ; #P12 PIN151
set_property -dict { PACKAGE_PIN H16  IOSTANDARD LVCMOS18 } [get_ports {spareN[0][15]}] ; #P12 PIN150

set_property -dict { PACKAGE_PIN F18  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][0]}] ; #P13 PIN148
set_property -dict { PACKAGE_PIN F17  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][0]}] ; #P13 PIN147
set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][1]}] ; #P13 PIN151
set_property -dict { PACKAGE_PIN G16  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][1]}] ; #P13 PIN150
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][2]}] ; #P13 PIN154
set_property -dict { PACKAGE_PIN E17  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][2]}] ; #P13 PIN153
set_property -dict { PACKAGE_PIN E16  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][3]}] ; #P13 PIN157
set_property -dict { PACKAGE_PIN D16  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][3]}] ; #P13 PIN156
set_property -dict { PACKAGE_PIN F15  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][4]}] ; #P13 PIN160
set_property -dict { PACKAGE_PIN F14  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][4]}] ; #P13 PIN159
set_property -dict { PACKAGE_PIN E15  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][5]}] ; #P13 PIN163
set_property -dict { PACKAGE_PIN D15  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][5]}] ; #P13 PIN162
set_property -dict { PACKAGE_PIN W25  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][6]}] ; #P14 PIN118
set_property -dict { PACKAGE_PIN Y25  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][6]}] ; #P14 PIN117
set_property -dict { PACKAGE_PIN W23  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][7]}] ; #P14 PIN121
set_property -dict { PACKAGE_PIN W24  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][7]}] ; #P14 PIN120
set_property -dict { PACKAGE_PIN AA24 IOSTANDARD LVCMOS18 } [get_ports {spareP[1][8]}] ; #P14 PIN124
set_property -dict { PACKAGE_PIN AA25 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][8]}] ; #P14 PIN123
set_property -dict { PACKAGE_PIN Y23  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][9]}] ; #P14 PIN127
set_property -dict { PACKAGE_PIN AA23 IOSTANDARD LVCMOS18 } [get_ports {spareN[1][9]}] ; #P14 PIN126
set_property -dict { PACKAGE_PIN C18  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][10]}] ; #P14 PIN130
set_property -dict { PACKAGE_PIN C17  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][10]}] ; #P14 PIN129
set_property -dict { PACKAGE_PIN B17  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][11]}] ; #P14 PIN133
set_property -dict { PACKAGE_PIN B16  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][11]}] ; #P14 PIN132
set_property -dict { PACKAGE_PIN C19  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][12]}] ; #P14 PIN142
set_property -dict { PACKAGE_PIN B19  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][12]}] ; #P14 PIN141
set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][13]}] ; #P14 PIN145
set_property -dict { PACKAGE_PIN A15  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][13]}] ; #P14 PIN144
set_property -dict { PACKAGE_PIN A19  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][14]}] ; #P14 PIN148
set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][14]}] ; #P14 PIN147
set_property -dict { PACKAGE_PIN B14  IOSTANDARD LVCMOS18 } [get_ports {spareP[1][15]}] ; #P14 PIN151
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS18 } [get_ports {spareN[1][15]}] ; #P14 PIN150

# RTM's Low Speed Ports
set_property -dict { PACKAGE_PIN E22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[0]}]
set_property -dict { PACKAGE_PIN E23 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[0]}]
set_property -dict { PACKAGE_PIN D23 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[1]}]
set_property -dict { PACKAGE_PIN C23 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[1]}]
set_property -dict { PACKAGE_PIN D24 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[2]}]
set_property -dict { PACKAGE_PIN C24 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[2]}]
set_property -dict { PACKAGE_PIN E25 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[3]}]
set_property -dict { PACKAGE_PIN D25 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[3]}]
set_property -dict { PACKAGE_PIN H21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[4]}]
set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[4]}]
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[5]}]
set_property -dict { PACKAGE_PIN F22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[5]}]
set_property -dict { PACKAGE_PIN G20 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[6]}]
set_property -dict { PACKAGE_PIN F20 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[6]}]
set_property -dict { PACKAGE_PIN F23 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[7]}]
set_property -dict { PACKAGE_PIN F24 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[7]}]
set_property -dict { PACKAGE_PIN E20 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[8]}]
set_property -dict { PACKAGE_PIN E21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[8]}]
set_property -dict { PACKAGE_PIN G24 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[9]}]
set_property -dict { PACKAGE_PIN F25 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[9]}]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[10]}]
set_property -dict { PACKAGE_PIN D21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[10]}]
set_property -dict { PACKAGE_PIN B20 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[11]}]
set_property -dict { PACKAGE_PIN A20 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[11]}]
set_property -dict { PACKAGE_PIN C21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[12]}]
set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[12]}]
set_property -dict { PACKAGE_PIN B21 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[13]}]
set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[13]}]
set_property -dict { PACKAGE_PIN B24 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[14]}]
set_property -dict { PACKAGE_PIN A24 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[14]}]
set_property -dict { PACKAGE_PIN C26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[15]}]
set_property -dict { PACKAGE_PIN B26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[15]}]
set_property -dict { PACKAGE_PIN B25 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[16]}]
set_property -dict { PACKAGE_PIN A25 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[16]}]
set_property -dict { PACKAGE_PIN E26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[17]}]
set_property -dict { PACKAGE_PIN D26 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[17]}]
set_property -dict { PACKAGE_PIN A27 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[18]}]
set_property -dict { PACKAGE_PIN A28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[18]}]
set_property -dict { PACKAGE_PIN D28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsP[19]}]
set_property -dict { PACKAGE_PIN C28 IOSTANDARD LVCMOS18 } [get_ports {rtmLsN[19]}]

####################################
## Application Timing Constraints ##
####################################

create_clock -name jesdClk00 -period 3.255 [get_ports {jesdClkP[0][0]}]
create_clock -name jesdClk01 -period 3.255 [get_ports {jesdClkP[0][1]}]
create_clock -name jesdClk02 -period 3.255 [get_ports {jesdClkP[0][2]}]
create_clock -name jesdClk03 -period 3.255 [get_ports {jesdClkP[0][3]}]
create_clock -name jesdClk10 -period 3.255 [get_ports {jesdClkP[1][0]}]
create_clock -name jesdClk11 -period 3.255 [get_ports {jesdClkP[1][1]}]
create_clock -name jesdClk12 -period 3.255 [get_ports {jesdClkP[1][2]}]
create_clock -name jesdClk13 -period 3.255 [get_ports {jesdClkP[1][3]}]
create_clock -name mpsClkIn  -period 8.000 [get_ports {mpsClkIn}]

create_generated_clock -name mpsClk625MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name mpsClk312MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT1}] 
create_generated_clock -name mpsClk125MHz  [get_pins {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT2}] 
create_clock           -name mpsClkThresh  -period 16.000 [get_pins {U_Core/U_AppMps/U_Clk/U_PLL/PllGen.U_Pll/CLKOUT0}]

set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {mpsClk625MHz}]
set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {mpsClk312MHz}]
set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {mpsClk125MHz}]
set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {axilClk}]
set_clock_groups -asynchronous -group [get_clocks {mpsClkThresh}] -group [get_clocks {recTimingClk}]

create_generated_clock -name jesd0_185MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd0_370MHz [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

create_generated_clock -name jesd1_185MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name jesd1_370MHz [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {jesd1_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {jesd0_370MHz}] -group [get_clocks {jesd1_370MHz}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {recTimingClk}] \
    -group [get_clocks -include_generated_clocks {ddrClkIn}] \
    -group [get_clocks -include_generated_clocks {fabClk}] \
    -group [get_clocks -include_generated_clocks {ethRef}] \
    -group [get_clocks -include_generated_clocks {mpsClkIn}] \
    -group [get_clocks -include_generated_clocks {jesd0_185MHz}] \
    -group [get_clocks -include_generated_clocks {jesd1_185MHz}]
    
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {fabClk}] \
    -group [get_clocks -include_generated_clocks {jesd0_370MHz}] \
    -group [get_clocks -include_generated_clocks {jesd1_370MHz}]  

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {mpsClkIn}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {ddrClkIn}] -group [get_clocks -include_generated_clocks {fabClk}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk00}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk01}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk02}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk03}] -group [get_clocks -include_generated_clocks {fabClk}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk10}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk11}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk12}] -group [get_clocks -include_generated_clocks {fabClk}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {jesdClk13}] -group [get_clocks -include_generated_clocks {fabClk}]

set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks -of_objects [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_Jesd/U_Coregen_Left/inst/gen_gtwizard_gtye4_top.JesdCryoCoreLeftColumn_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks -of_objects [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_Jesd/U_Coregen_Left/inst/gen_gtwizard_gtye4_top.JesdCryoCoreLeftColumn_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks -of_objects [get_pins {U_AppTop/U_AmcBay[0].U_JesdCore/U_Jesd/U_Coregen_Left/inst/gen_gtwizard_gtye4_top.JesdCryoCoreLeftColumn_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]

set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks -of_objects [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_Jesd/U_Coregen_Left/inst/gen_gtwizard_gtye4_top.JesdCryoCoreLeftColumn_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks -of_objects [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_Jesd/U_Coregen_Left/inst/gen_gtwizard_gtye4_top.JesdCryoCoreLeftColumn_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {jesd1_185MHz}] -group [get_clocks -of_objects [get_pins {U_AppTop/U_AmcBay[1].U_JesdCore/U_Jesd/U_Coregen_Left/inst/gen_gtwizard_gtye4_top.JesdCryoCoreLeftColumn_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]

##########################
## Misc. Configurations ##
##########################
