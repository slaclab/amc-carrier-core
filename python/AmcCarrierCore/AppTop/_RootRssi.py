#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : AmcCarrierCore Base Root Class For RSSI Ethernet
#-----------------------------------------------------------------------------
# File       : RootRssi.py
# Created    : 2019-10-11
#-----------------------------------------------------------------------------
# Description:
# Base Root class for AmcCarrierCore with non-interleaved RSSI
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
import pyrogue.protocols
import rogue.protocols.srp

class RootRssi(pyrogue.Root):
    def __init__(self, *, ipAddr='10.0.0.1', name='base', description = '', **kwargs):
        pyrogue.Root.__init__(self,
                         name         = name,
                         description  = description,
                         **kwargs
                        )

        # Create SRP/ASYNC_MSG interface
        self.rudp = pyrogue.protocols.UdpRssiPack( name='rudpReg', host=ipAddr, port=8193, packVer = 1, jumbo = False)

        # Connect the SRPv3 to tDest = 0x0
        self.srp = rogue.protocols.srp.SrpV3()
        pr.streamConnectBiDir( self.srp, self.rudp.application(dest=0x0) )

        # Create stream interface
        self.stream = pr.protocols.UdpRssiPack( name='rudpData', host=ipAddr, port=8194, packVer = 1, jumbo = False)

        # Top level module should be added here.
        # Top level is a sub-class of AmcCarrierCore.AppTop.TopLevel
        # SRP interface should be passed as an arg
        #self.add(FpgaTopLevel(memBase=self.srp))

