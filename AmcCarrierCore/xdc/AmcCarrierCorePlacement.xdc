##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#####################################
## Core Area/Placement Constraints ##
#####################################

set_property package_pin "" [get_ports [list  rtmHsTxP]]
set_property package_pin "" [get_ports [list  rtmHsTxN]]
set_property package_pin "" [get_ports [list  rtmHsRxP]]
set_property package_pin "" [get_ports [list  rtmHsRxN]]

##########################
## Misc. Configurations ##
##########################

set_property BITSTREAM.CONFIG.CONFIGRATE 50      [current_design] 
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1     [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE No   [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE     [current_design]

set_property CFGBVS         {VCCO} [current_design]
set_property CONFIG_VOLTAGE {3.3} [current_design]

set_property SEVERITY {Warning} [get_drc_checks {NSTD-1}]
set_property SEVERITY {Warning} [get_drc_checks {UCIO-1}]

set_property UNAVAILABLE_DURING_CALIBRATION TRUE [get_ports {ddrPg}]