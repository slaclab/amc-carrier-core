##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# JESD Reference Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][0]}] ; #jesdSysRefP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[0][0]}] ; #jesdSysRefN[0]

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][0]}] ; #jesdRxSyncP[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][0]}] ; #jesdRxSyncN[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][1]}] ; #jesdRxSyncP[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][1]}] ; #jesdRxSyncN[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][2]}] ; #jesdTxSyncP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][2]}] ; #jesdTxSyncN[0]

# LMK Ports
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][4]}] ; #lmkClkSel[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][5]}] ; #lmkClkSel[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][4]}] ; #lmkStatus[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][5]}] ; #lmkStatus[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][15]}] ; #lmkCsL[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][15]}] ; #lmkSck[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {syncInN[0][2]}] ; #lmkDio[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {syncInP[0][2]}] ; #lmkRst[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {syncInP[0][3]}];# lmkSync[0][0]: AMC Card Version C00
set_property -dict { IOSTANDARD LVCMOS25 PULLTYPE PULLUP } [get_ports {jtagPri[0][1]}];# lmkSync[0][1]: AMC Card Version C01 (or later)
set_property -dict { IOSTANDARD LVCMOS25 PULLTYPE PULLUP } [get_ports {jtagPri[0][2]}];# lmkMuxSel[0]: AMC Card Version C01 (or later)

# Fast ADC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][6]}] ; #adcCsL[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][8]}] ; #adcCsL[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][6]}] ; #adcSck[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][8]}] ; #adcSck[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE NONE   } [get_ports {spareN[0][7]}] ; #adcMiso[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE NONE   } [get_ports {spareN[0][9]}] ; #adcMiso[0][1]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][7]}] ; #adcMosi[0][0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][9]}] ; #adcMosi[0][1]

# Fast DAC's SPI Ports
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][10]}] ; #dacCsL[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareP[0][10]}] ; #dacSck[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE NONE   } [get_ports {spareP[0][11]}] ; #dacMiso[0]
set_property -dict { IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports {spareN[0][11]}] ; #dacMosi[0]

# Slow DAC's SPI Ports
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][12]}] ; #dacVcoCsP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][12]}] ; #dacVcoCsN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][13]}] ; #dacVcoSckP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][13]}] ; #dacVcoSckN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][14]}] ; #dacVcoDinP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][14]}] ; #dacVcoDinN[0]

# Pass through Interfaces
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkP[0][0]}] ; #fpgaClkP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {fpgaClkN[0][0]}] ; #fpgaClkN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][3]}] ; #smaTrigP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][3]}] ; #smaTrigN[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][4]}] ; #adcCalP[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][4]}] ; #adcCalN[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][0]}] ; #lemoDinP[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][0]}] ; #lemoDinN[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][1]}] ; #lemoDinP[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][1]}] ; #lemoDinN[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][5]}] ; #lemoDoutP[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][5]}] ; #lemoDoutN[0][0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutP[0][6]}] ; #lemoDoutP[0][1]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncOutN[0][6]}] ; #lemoDoutN[0][1]
set_property -dict { IOSTANDARD LVCMOS25 } [get_ports {jtagPri[0][0]}] ; #bcmL[0]
