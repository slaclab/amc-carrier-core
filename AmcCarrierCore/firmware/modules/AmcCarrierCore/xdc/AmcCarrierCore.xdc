##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######################
## Common Core Ports ##
#######################

# Common fabrication clock
set_property PACKAGE_PIN T6 [get_ports {fabClkP}]
set_property PACKAGE_PIN T5 [get_ports {fabClkN}]

# XAUI Ports
set_property PACKAGE_PIN AA4 [get_ports {xauiTxP[0]}]
set_property PACKAGE_PIN AA3 [get_ports {xauiTxN[0]}]
set_property PACKAGE_PIN Y2  [get_ports {xauiRxP[0]}]
set_property PACKAGE_PIN Y1  [get_ports {xauiRxN[0]}]
set_property PACKAGE_PIN W4  [get_ports {xauiTxP[1]}]
set_property PACKAGE_PIN W3  [get_ports {xauiTxN[1]}]
set_property PACKAGE_PIN V2  [get_ports {xauiRxP[1]}]
set_property PACKAGE_PIN V1  [get_ports {xauiRxN[1]}]
set_property PACKAGE_PIN U4  [get_ports {xauiTxP[2]}]
set_property PACKAGE_PIN U3  [get_ports {xauiTxN[2]}]
set_property PACKAGE_PIN T2  [get_ports {xauiRxP[2]}]
set_property PACKAGE_PIN T1  [get_ports {xauiRxN[2]}]
set_property PACKAGE_PIN R4  [get_ports {xauiTxP[3]}]
set_property PACKAGE_PIN R3  [get_ports {xauiTxN[3]}]
set_property PACKAGE_PIN P2  [get_ports {xauiRxP[3]}]
set_property PACKAGE_PIN P1  [get_ports {xauiRxN[3]}]
set_property PACKAGE_PIN V6  [get_ports {xauiClkP}]
set_property PACKAGE_PIN V5  [get_ports {xauiClkN}]

# Backplane MPS Ports
set_property -dict { PACKAGE_PIN AD19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[1]}]
set_property -dict { PACKAGE_PIN AD18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[1]}]
set_property -dict { PACKAGE_PIN AG15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[2]}]
set_property -dict { PACKAGE_PIN AG14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[2]}]
set_property -dict { PACKAGE_PIN AG19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[3]}]
set_property -dict { PACKAGE_PIN AH19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[3]}]
set_property -dict { PACKAGE_PIN AJ15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[4]}]
set_property -dict { PACKAGE_PIN AJ14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[4]}]
set_property -dict { PACKAGE_PIN AG17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[5]}]
set_property -dict { PACKAGE_PIN AG16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[5]}]
set_property -dict { PACKAGE_PIN AL18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[6]}]
set_property -dict { PACKAGE_PIN AL17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[6]}]
set_property -dict { PACKAGE_PIN AK15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[7]}]
set_property -dict { PACKAGE_PIN AL15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[7]}]
set_property -dict { PACKAGE_PIN AL19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[8]}]
set_property -dict { PACKAGE_PIN AM19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[8]}]
set_property -dict { PACKAGE_PIN AL14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[9]}]
set_property -dict { PACKAGE_PIN AM14 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[9]}]
set_property -dict { PACKAGE_PIN AP16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[10]}]
set_property -dict { PACKAGE_PIN AP15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[10]}]
set_property -dict { PACKAGE_PIN AM16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[11]}]
set_property -dict { PACKAGE_PIN AM15 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[11]}]
set_property -dict { PACKAGE_PIN AN18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[12]}]
set_property -dict { PACKAGE_PIN AN17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[12]}]
set_property -dict { PACKAGE_PIN AM17 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[13]}]
set_property -dict { PACKAGE_PIN AN16 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[13]}]
set_property -dict { PACKAGE_PIN AN19 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxP[14]}]
set_property -dict { PACKAGE_PIN AP18 IOSTANDARD LVDS DIFF_TERM_ADV TERM_NONE } [get_ports {mpsBusRxN[14]}]

set_property -dict { PACKAGE_PIN AP11 IOSTANDARD LVDS_25 } [get_ports {mpsTxP}]
set_property -dict { PACKAGE_PIN AP10 IOSTANDARD LVDS_25 } [get_ports {mpsTxN}]

set_property -dict { PACKAGE_PIN AF10 IOSTANDARD LVCMOS25 }           [get_ports {mpsClkIn}]
set_property -dict { PACKAGE_PIN AG10 IOSTANDARD LVCMOS25 SLEW FAST } [get_ports {mpsClkOut}]

# LCLS Timing Ports
set_property -dict { PACKAGE_PIN AH13 IOSTANDARD LVDS_25  } [get_ports {timingRecClkOutP}]
set_property -dict { PACKAGE_PIN AJ13 IOSTANDARD LVDS_25  } [get_ports {timingRecClkOutN}]
set_property -dict { PACKAGE_PIN K22  IOSTANDARD LVCMOS25 } [get_ports {timingClkSel}]
set_property -dict { PACKAGE_PIN AE11 IOSTANDARD LVCMOS25 } [get_ports {timingClkScl}]
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVCMOS25 } [get_ports {timingClkSda}]

set_property PACKAGE_PIN AK6  [get_ports {timingTxP}]
set_property PACKAGE_PIN AK5  [get_ports {timingTxN}]
set_property PACKAGE_PIN AJ4  [get_ports {timingRxP}]
set_property PACKAGE_PIN AJ3  [get_ports {timingRxN}]
set_property PACKAGE_PIN Y6   [get_ports {timingRefClkInP}]
set_property PACKAGE_PIN Y5   [get_ports {timingRefClkInN}]

# Crossbar Ports
set_property -dict { PACKAGE_PIN AF13 IOSTANDARD LVCMOS25 } [get_ports {xBarSin[0]}] 
set_property -dict { PACKAGE_PIN AK13 IOSTANDARD LVCMOS25 } [get_ports {xBarSin[1]}] 
set_property -dict { PACKAGE_PIN AL13 IOSTANDARD LVCMOS25 } [get_ports {xBarSout[0]}] 
set_property -dict { PACKAGE_PIN AK12 IOSTANDARD LVCMOS25 } [get_ports {xBarSout[1]}] 
set_property -dict { PACKAGE_PIN AL12 IOSTANDARD LVCMOS25 } [get_ports {xBarConfig}] 
set_property -dict { PACKAGE_PIN AK11 IOSTANDARD LVCMOS25 } [get_ports {xBarLoad}] 

# Secondary AMC Auxiliary Power Enable Port
set_property -dict { PACKAGE_PIN H23 IOSTANDARD LVCMOS25 } [get_ports {enAuxPwrL}] 

# IPMC Ports
set_property -dict { PACKAGE_PIN AE12 IOSTANDARD LVCMOS25 } [get_ports {ipmcScl}]
set_property -dict { PACKAGE_PIN AF12 IOSTANDARD LVCMOS25 } [get_ports {ipmcSda}]

# Configuration PROM Ports
set_property -dict { PACKAGE_PIN N27 IOSTANDARD LVCMOS25 } [get_ports {calScl}]
set_property -dict { PACKAGE_PIN N23 IOSTANDARD LVCMOS25 } [get_ports {calSda}]

# DDR3L SO-DIMM Ports
set_property PACKAGE_PIN      G17         [get_ports {ddrClkP}] 
set_property PACKAGE_PIN      G16         [get_ports {ddrClkN}] 
set_property IOSTANDARD       DIFF_HSTL_I [get_ports {ddrClkP ddrClkN}]
set_property IBUF_LOW_PWR     FALSE       [get_ports {ddrClkP ddrClkN}]
set_property PULLTYPE         KEEPER      [get_ports {ddrClkP ddrClkN}]

set_property PACKAGE_PIN B10 [get_ports {ddrDqsP[0]}] 
set_property PACKAGE_PIN A10 [get_ports {ddrDqsN[0]}] 
set_property PACKAGE_PIN K10 [get_ports {ddrDqsP[1]}] 
set_property PACKAGE_PIN J10 [get_ports {ddrDqsN[1]}] 
set_property PACKAGE_PIN L13 [get_ports {ddrDqsP[2]}] 
set_property PACKAGE_PIN K13 [get_ports {ddrDqsN[2]}] 
set_property PACKAGE_PIN F13 [get_ports {ddrDqsP[3]}] 
set_property PACKAGE_PIN E13 [get_ports {ddrDqsN[3]}] 
set_property PACKAGE_PIN B29 [get_ports {ddrDqsP[4]}] 
set_property PACKAGE_PIN A29 [get_ports {ddrDqsN[4]}] 
set_property PACKAGE_PIN B24 [get_ports {ddrDqsP[5]}] 
set_property PACKAGE_PIN A24 [get_ports {ddrDqsN[5]}] 
set_property PACKAGE_PIN C21 [get_ports {ddrDqsP[6]}] 
set_property PACKAGE_PIN C22 [get_ports {ddrDqsN[6]}] 
set_property PACKAGE_PIN G20 [get_ports {ddrDqsP[7]}] 
set_property PACKAGE_PIN F20 [get_ports {ddrDqsN[7]}] 
set_property IOSTANDARD DIFF_SSTL15_DCI   [get_ports {ddrDqsP[*] ddrDqsN[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrDqsP[*] ddrDqsN[*]}]
set_property SLEW          FAST           [get_ports {ddrDqsP[*] ddrDqsN[*]}]
set_property IBUF_LOW_PWR  FALSE          [get_ports {ddrDqsP[*] ddrDqsN[*]}]
set_property ODT           RTT_40         [get_ports {ddrDqsP[*] ddrDqsN[*]}]

set_property PACKAGE_PIN F8  [get_ports {ddrDm[0]}] 
set_property PACKAGE_PIN L8  [get_ports {ddrDm[1]}] 
set_property PACKAGE_PIN H11 [get_ports {ddrDm[2]}] 
set_property PACKAGE_PIN E11 [get_ports {ddrDm[3]}] 
set_property PACKAGE_PIN F27 [get_ports {ddrDm[4]}] 
set_property PACKAGE_PIN E26 [get_ports {ddrDm[5]}] 
set_property PACKAGE_PIN D23 [get_ports {ddrDm[6]}] 
set_property PACKAGE_PIN G24 [get_ports {ddrDm[7]}] 
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrDm[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrDm[*]}]
set_property SLEW FAST                    [get_ports {ddrDm[*]}]

set_property PACKAGE_PIN B9  [get_ports {ddrDq[0]}] 
set_property PACKAGE_PIN A9  [get_ports {ddrDq[1]}] 
set_property PACKAGE_PIN D8  [get_ports {ddrDq[2]}] 
set_property PACKAGE_PIN C8  [get_ports {ddrDq[3]}] 
set_property PACKAGE_PIN D9  [get_ports {ddrDq[4]}] 
set_property PACKAGE_PIN C9  [get_ports {ddrDq[5]}] 
set_property PACKAGE_PIN E10 [get_ports {ddrDq[6]}] 
set_property PACKAGE_PIN D10 [get_ports {ddrDq[7]}] 
set_property PACKAGE_PIN J9  [get_ports {ddrDq[8]}] 
set_property PACKAGE_PIN H9  [get_ports {ddrDq[9]}] 
set_property PACKAGE_PIN J8  [get_ports {ddrDq[10]}] 
set_property PACKAGE_PIN H8  [get_ports {ddrDq[11]}] 
set_property PACKAGE_PIN G9  [get_ports {ddrDq[12]}] 
set_property PACKAGE_PIN F9  [get_ports {ddrDq[13]}] 
set_property PACKAGE_PIN G10 [get_ports {ddrDq[14]}] 
set_property PACKAGE_PIN F10 [get_ports {ddrDq[15]}] 
set_property PACKAGE_PIN H12 [get_ports {ddrDq[16]}] 
set_property PACKAGE_PIN G12 [get_ports {ddrDq[17]}] 
set_property PACKAGE_PIN K11 [get_ports {ddrDq[18]}] 
set_property PACKAGE_PIN J11 [get_ports {ddrDq[19]}] 
set_property PACKAGE_PIN L12 [get_ports {ddrDq[20]}] 
set_property PACKAGE_PIN K12 [get_ports {ddrDq[21]}] 
set_property PACKAGE_PIN J13 [get_ports {ddrDq[22]}] 
set_property PACKAGE_PIN H13 [get_ports {ddrDq[23]}] 
set_property PACKAGE_PIN C12 [get_ports {ddrDq[24]}] 
set_property PACKAGE_PIN B12 [get_ports {ddrDq[25]}] 
set_property PACKAGE_PIN C11 [get_ports {ddrDq[26]}] 
set_property PACKAGE_PIN B11 [get_ports {ddrDq[27]}] 
set_property PACKAGE_PIN A13 [get_ports {ddrDq[28]}] 
set_property PACKAGE_PIN A12 [get_ports {ddrDq[29]}] 
set_property PACKAGE_PIN D13 [get_ports {ddrDq[30]}] 
set_property PACKAGE_PIN C13 [get_ports {ddrDq[31]}] 
set_property PACKAGE_PIN C27 [get_ports {ddrDq[32]}] 
set_property PACKAGE_PIN B27 [get_ports {ddrDq[33]}] 
set_property PACKAGE_PIN E28 [get_ports {ddrDq[34]}] 
set_property PACKAGE_PIN D29 [get_ports {ddrDq[35]}] 
set_property PACKAGE_PIN D28 [get_ports {ddrDq[36]}] 
set_property PACKAGE_PIN C28 [get_ports {ddrDq[37]}] 
set_property PACKAGE_PIN A27 [get_ports {ddrDq[38]}] 
set_property PACKAGE_PIN A28 [get_ports {ddrDq[39]}] 
set_property PACKAGE_PIN B25 [get_ports {ddrDq[40]}] 
set_property PACKAGE_PIN A25 [get_ports {ddrDq[41]}] 
set_property PACKAGE_PIN C26 [get_ports {ddrDq[42]}] 
set_property PACKAGE_PIN B26 [get_ports {ddrDq[43]}] 
set_property PACKAGE_PIN E25 [get_ports {ddrDq[44]}] 
set_property PACKAGE_PIN D25 [get_ports {ddrDq[45]}] 
set_property PACKAGE_PIN D24 [get_ports {ddrDq[46]}] 
set_property PACKAGE_PIN C24 [get_ports {ddrDq[47]}] 
set_property PACKAGE_PIN E22 [get_ports {ddrDq[48]}] 
set_property PACKAGE_PIN E23 [get_ports {ddrDq[49]}] 
set_property PACKAGE_PIN B21 [get_ports {ddrDq[50]}] 
set_property PACKAGE_PIN B22 [get_ports {ddrDq[51]}] 
set_property PACKAGE_PIN B20 [get_ports {ddrDq[52]}] 
set_property PACKAGE_PIN A20 [get_ports {ddrDq[53]}] 
set_property PACKAGE_PIN D20 [get_ports {ddrDq[54]}] 
set_property PACKAGE_PIN D21 [get_ports {ddrDq[55]}] 
set_property PACKAGE_PIN E20 [get_ports {ddrDq[56]}] 
set_property PACKAGE_PIN E21 [get_ports {ddrDq[57]}] 
set_property PACKAGE_PIN F23 [get_ports {ddrDq[58]}] 
set_property PACKAGE_PIN F24 [get_ports {ddrDq[59]}] 
set_property PACKAGE_PIN G22 [get_ports {ddrDq[60]}] 
set_property PACKAGE_PIN F22 [get_ports {ddrDq[61]}] 
set_property PACKAGE_PIN H21 [get_ports {ddrDq[62]}] 
set_property PACKAGE_PIN G21 [get_ports {ddrDq[63]}] 
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrDq[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrDq[*]}]
set_property SLEW          FAST           [get_ports {ddrDq[*]}]
set_property IBUF_LOW_PWR  FALSE          [get_ports {ddrDq[*]}]
set_property ODT           RTT_40         [get_ports {ddrDq[*]}]

set_property PACKAGE_PIN B14 [get_ports {ddrA[0]}] 
set_property PACKAGE_PIN A14 [get_ports {ddrA[1]}] 
set_property PACKAGE_PIN A19 [get_ports {ddrA[2]}] 
set_property PACKAGE_PIN A18 [get_ports {ddrA[3]}] 
set_property PACKAGE_PIN B15 [get_ports {ddrA[4]}] 
set_property PACKAGE_PIN A15 [get_ports {ddrA[5]}] 
set_property PACKAGE_PIN B17 [get_ports {ddrA[6]}] 
set_property PACKAGE_PIN B16 [get_ports {ddrA[7]}] 
set_property PACKAGE_PIN C18 [get_ports {ddrA[8]}] 
set_property PACKAGE_PIN C17 [get_ports {ddrA[9]}] 
set_property PACKAGE_PIN D14 [get_ports {ddrA[10]}] 
set_property PACKAGE_PIN C14 [get_ports {ddrA[11]}] 
set_property PACKAGE_PIN E15 [get_ports {ddrA[12]}] 
set_property PACKAGE_PIN D15 [get_ports {ddrA[13]}] 
set_property PACKAGE_PIN F15 [get_ports {ddrA[14]}] 
set_property PACKAGE_PIN F14 [get_ports {ddrA[15]}]
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrA[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrA[*]}]
set_property SLEW FAST                    [get_ports {ddrA[*]}]

set_property PACKAGE_PIN D19 [get_ports {ddrBa[0]}] 
set_property PACKAGE_PIN D18 [get_ports {ddrBa[1]}] 
set_property PACKAGE_PIN E16 [get_ports {ddrBa[2]}] 
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrBa[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrBa[*]}]
set_property SLEW FAST                    [get_ports {ddrBa[*]}]

set_property PACKAGE_PIN D16 [get_ports {ddrCsL[0]}] 
set_property PACKAGE_PIN L15 [get_ports {ddrCsL[1]}] 
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrCsL[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrCsL[*]}]
set_property SLEW FAST                    [get_ports {ddrCsL[*]}]

set_property PACKAGE_PIN E17 [get_ports {ddrOdt[0]}] 
set_property PACKAGE_PIN K15 [get_ports {ddrOdt[1]}] 
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrOdt[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrOdt[*]}]
set_property SLEW FAST                    [get_ports {ddrOdt[*]}]

set_property PACKAGE_PIN E18 [get_ports {ddrCke[0]}] 
set_property PACKAGE_PIN H18 [get_ports {ddrCke[1]}] 
set_property IOSTANDARD SSTL15_DCI        [get_ports {ddrCke[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrCke[*]}]
set_property SLEW FAST                    [get_ports {ddrCke[*]}]

set_property PACKAGE_PIN C19 [get_ports {ddrCkP[0]}] 
set_property PACKAGE_PIN B19 [get_ports {ddrCkN[0]}] 
set_property PACKAGE_PIN H17 [get_ports {ddrCkP[1]}] 
set_property PACKAGE_PIN H16 [get_ports {ddrCkN[1]}] 
set_property IOSTANDARD DIFF_SSTL15_DCI   [get_ports {ddrCkP[*] ddrCkN[*]}]
set_property OUTPUT_IMPEDANCE RDRV_40_40  [get_ports {ddrCkP[*] ddrCkN[*]}]
set_property SLEW FAST                    [get_ports {ddrCkP[*] ddrCkN[*]}]

set_property -dict { PACKAGE_PIN G15 IOSTANDARD SSTL15_DCI OUTPUT_IMPEDANCE RDRV_40_40 SLEW FAST } [get_ports {ddrWeL}] 
set_property -dict { PACKAGE_PIN F18 IOSTANDARD SSTL15_DCI OUTPUT_IMPEDANCE RDRV_40_40 SLEW FAST } [get_ports {ddrRasL}] 
set_property -dict { PACKAGE_PIN F17 IOSTANDARD SSTL15_DCI OUTPUT_IMPEDANCE RDRV_40_40 SLEW FAST } [get_ports {ddrCasL}] 
set_property -dict { PACKAGE_PIN C16 IOSTANDARD SSTL15     OUTPUT_IMPEDANCE RDRV_48_48 SLEW SLOW } [get_ports {ddrRstL}] 
set_property -dict { PACKAGE_PIN L19 IOSTANDARD LVCMOS15 } [get_ports {ddrScl}] 
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS15 } [get_ports {ddrSda}] 
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS15 } [get_ports {ddrPwrEnL}] 

#####################################
## Core Area/Placement Constraints ##
#####################################

# MIG Area Constraint
create_pblock MIG_GRP; add_cells_to_pblock [get_pblocks MIG_GRP] [get_cells {U_Core/U_DdrMem/MigCore_Inst}]
resize_pblock [get_pblocks MIG_GRP] -add {CLOCKREGION_X2Y2:CLOCKREGION_X2Y4}

# XAUI Area Constraint
create_pblock XAUI_GRP; add_cells_to_pblock [get_pblocks XAUI_GRP] [get_cells {U_Core/U_Eth/U_Xaui/XauiGthUltraScale_Inst/GEN_10GIGE.GEN_156p25MHz.U_XauiGthUltraScaleCore}]
resize_pblock [get_pblocks XAUI_GRP] -add {CLOCKREGION_X3Y2:CLOCKREGION_X3Y2}

#############################
## Core Timing Constraints ##
#############################
 
set_property CLOCK_DEDICATED_ROUTE FALSE    [get_nets {U_Core/U_DdrMem/refClock}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets {U_Core/U_DdrMem/refClkBufg}]

create_clock -name ddrClkIn   -period  5.000  [get_pins {U_Core/U_DdrMem/BUFG_Inst/O}]
create_clock -name fabClk     -period  6.400  [get_ports {fabClkP}]
create_clock -name xauiRef    -period  6.400  [get_ports {xauiClkP}]
create_clock -name mpsClkP    -period  8.000  [get_ports {mpsClkIn}]
create_clock -name timingRef  -period  2.691  [get_ports {timingRefClkInP}]

create_generated_clock -name axilClk      [get_pins -hier -filter {NAME =~ U_Core/U_ClkAndRst/U_ClkManagerAxiLite/*/CLKOUT0}] 
create_generated_clock -name mpsClk625MHz [get_pins -hier -filter {NAME =~ U_Core/U_ClkAndRst/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name mpsClk312MHz [get_pins -hier -filter {NAME =~ U_Core/U_ClkAndRst/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT1}] 
create_generated_clock -name mpsClk125MHz [get_pins -hier -filter {NAME =~ U_Core/U_ClkAndRst/U_ClkManagerMps/MmcmGen.U_Mmcm/CLKOUT2}] 
create_generated_clock -name iprogClk     [get_pins {U_Core/U_RegMap/U_Version/GEN_ICAP.Iprog_1/GEN_ULTRA_SCALE.IprogUltraScale_Inst/BUFGCE_DIV_Inst/O}]
create_generated_clock -name dnaClk       [get_pins {U_Core/U_RegMap/U_Version/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/O}]
create_generated_clock -name xauiPhyClk   [get_pins -hier -filter {name =~ U_Core/U_Eth/U_Xaui/XauiGthUltraScale_Inst/*/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_generated_clock -name ddrIntClk0   [get_pins {U_Core/U_DdrMem/MigCore_Inst/inst/u_ddr3_infrastructure/gen_mmcme3.u_mmcme_adv_inst/CLKOUT0}]
create_generated_clock -name ddrIntClk1   [get_pins {U_Core/U_DdrMem/MigCore_Inst/inst/u_ddr3_infrastructure/gen_mmcme3.u_mmcme_adv_inst/CLKOUT6}]
create_generated_clock -name recTimingClk [get_pins -hier -filter {name =~ U_Core/U_Timing/TimingGthCoreWrapper_1/U_TimingGthCore/*/RXOUTCLK}]  
create_generated_clock -name timingGenClk [get_pins -hier -filter {name =~ U_Core/U_Timing/TimingGthCoreWrapper_1/U_TimingGthCore/*/TXOUTCLK}]
create_generated_clock -name timingGenUsrClk [get_pins -hier -filter {name =~ U_Core/U_Timing/TIMING_TXCLK_BUFG_GT/O}]
# U_Core/U_Timing/TIMING_RECCLK_BUFG_GT/O
#create_generated_clock -name recTimingClk [get_pins -hier -filter {name =~ U_Core/U_Timing/recTimingClk}]

set_false_path -to [get_pins -hier -filter {name =~ */U_SaltDelayCtrl/SALT_IDELAY_CTRL_Inst*/RST}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_MpsandFfb/*/SALT_IDELAY_CTRL_Inst*}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_MpsandFfb/*/serdes_1_to_10_ser8_i/idelay_cal}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_MpsandFfb/*/serdes_1_to_10_ser8_i/idelay_m}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_MpsandFfb/*/serdes_1_to_10_ser8_i/idelay_s}]

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {xauiPhyClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ddrClkIn}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ddrIntClk0}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ddrIntClk1}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {iprogClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {dnaClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {mpsClk125MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {timingRecClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {timingGenClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {timingGenUsrClk}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {recTimingClk}] 

# set_clock_groups -asynchronous \
    # -group [get_clocks -include_generated_clocks {timingRef}] \
    # -group [get_clocks -include_generated_clocks {ddrClkIn}] \
    # -group [get_clocks -include_generated_clocks {fabClk}] \
    # -group [get_clocks -include_generated_clocks {xauiRef}] \
    # -group [get_clocks -include_generated_clocks {mpsClkP}]

##########################
## Misc. Configurations ##
##########################

# BITSTREAM Configurations
set_property BITSTREAM.CONFIG.CONFIGRATE 90 [current_design] 
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE No [current_design]

# StdLib
set_property ASYNC_REG TRUE [get_cells -hierarchical {*crossDomainSyncReg_reg*}]
