#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : AmcCarrierCore Base Root Class For First Stage Boot Loader
#-----------------------------------------------------------------------------
# File       : RootFsbl.py
# Created    : 2019-10-11
#-----------------------------------------------------------------------------
# Description:
# Base Root class for AmcCarrierCore based designs.
#-----------------------------------------------------------------------------
# This file is part of the AmcCarrier Core. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the AmcCarrierCore, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue
import rogue.protocols.udp
import rogue.protocols.srp

from AmcCarrierCore.AppTop import TopLevel as FpgaTopLevel

class RootFsbl(pyrogue.Root):
    def __init__(self, *, ipAddr='10.0.0.1', name='base', description = '', **kwargs):
        pyrogue.Root.__init__(self,
                         name         = name,
                         description  = description,
                         **kwargs
                        )

        self.srp=pyrogue.interfaces.simulation.MemEmulate()

        # UDP only
        self.udp = rogue.protocols.udp.Client(ipAddr,8192,0)
    
        # Connect the SRPv0 to RAW UDP
        self.srp = rogue.protocols.srp.SrpV0()
        pyrogue.streamConnectBiDir( self.srp, self.udp )

        self.stream = None

        # Top level module should be added here.
        # Top level is a sub-class of AmcCarrierCore.AppTop.TopLevel
        # SRP interface should be passed as an arg
        self.add(FpgaTopLevel(memBase=self.srp))

