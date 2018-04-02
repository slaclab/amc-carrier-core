##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[1]}]; # cryoCsL
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsP[3]}]; # cryoSck
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[3]}]; # cryoSdi

set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[7]}];  # LEMO2 = startRampPulse
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsP[12]}]; # startRampPulse

set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[12]}]; # selRamp

set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[13]}]; # maxCsL
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[14]}]; # maxSdi
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsP[15]}]; # maxSck

set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[16]}]; # not(jesdRst)

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[17]}]; # jesdClkDivReg
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[17]}]; # jesdClkDivReg

set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[18]}]; # srSck
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsP[19]}]; # srSdi
set_property -dict { SLEW FAST DRIVE 12 } [get_ports {rtmLsN[19]}]; # srCsL
