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
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[1][0]}] ; #jesdSysRefP 
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[1][0]}] ; #jesdSysRefN

# JESD ADC Sync Ports
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInP[1][3]}]  ; # jesdRxSyncP(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {syncInN[1][3]}]  ; # jesdRxSyncN(0)
set_property -dict {IOSTANDARD LVDS} [get_ports {spareP[1][14])}]  ; # jesdRxSyncP(1)
set_property -dict {IOSTANDARD LVDS} [get_ports {spareN[1][14]}]  ; # jesdRxSyncN(1)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefP[1][1]}] ; # jesdTxSyncP(0)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {sysRefN[1][1]}] ; # jesdTxSyncN(0)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {spareP[1][8]}] ; # jesdTxSyncP(1)
set_property -dict {IOSTANDARD LVDS DIFF_TERM TRUE } [get_ports {spareN[1][8]}] ; # jesdTxSyncN(1)

# ADC SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][2]}]    ; # adcSpiDo(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncInN[1][0]}]   ; # adcSpiDo(1)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][1]}]    ; # adcSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][2]}]    ; # adcSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutN[1][8]}]  ; # adcSpiCsb(1)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutP[1][9]}]  ; # adcSpiDi

# DAC SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][0]}]    ; # dacSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][1]}]    ; # dacSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareN[1][0]}]    ; # dacSpiCsb(0)
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {syncOutP[1][8]}]  ; # dacSpiCsb(1)

# LMK SPI
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][10]}]    ; # lmkSpiClk
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][11]}]    ; # lmkSpiDio
set_property -dict {IOSTANDARD LVCMOS18 PULLUP true} [get_ports {spareP[1][9]}]     ; # lmkSpiCsb

# PLL SPI
set_property -dict { IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 } [get_ports {spareP[1][12]}]    ; # pllSpiClk
set_property -dict { IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 } [get_ports {spareN[1][12]}]    ; # pllSpiDio
set_property -dict { IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 } [get_ports {spareN[1][15]}]    ; # pllSpiCsb(0)
set_property -dict { IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 } [get_ports {spareP[1][15]}]    ; # pllSpiCsb(1)
set_property -dict { IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 } [get_ports {spareP[1][13]}]    ; # pllSpiCsb(2)
set_property -dict { IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 2 } [get_ports {spareN[1][13]}]    ; # pllSpiCsb(3)

# ADC resets
set_property -dict {IOSTANDARD LVCMOS18} [get_ports {spareN[1][3]}]    ; # adcRst(0)
set_property -dict {IOSTANDARD LVCMOS18} [get_ports {syncOutN[1][9]}]  ; # adcRst(1)
