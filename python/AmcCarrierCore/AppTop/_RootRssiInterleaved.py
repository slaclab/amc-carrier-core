#-----------------------------------------------------------------------------
# Title      : AmcCarrierCore Base Root Class For Interleaved RSSI Ethernet
#-----------------------------------------------------------------------------
# File       : RootRssiInterleaved.py
# Created    : 2019-10-11
#-----------------------------------------------------------------------------
# Description:
# Base Root class for AmcCarrierCore with interleaved RSSI
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

class RootRssiInterleaved(pyrogue.Root):
    def __init__(self, *, ipAddr='10.0.0.1', name='base', description = '', **kwargs):
        pyrogue.Root.__init__(self,
                         name         = name,
                         description  = description,
                         **kwargs
                        )

        # Create Interleaved RSSI interface
        self.rudp = self.stream = pyrogue.protocols.UdpRssiPack( name='rudp', host=ipAddr, port=8198, packVer = 2, jumbo = True)
        
        # Connect the SRPv3 to tDest = 0x0
        self.srp = rogue.protocols.srp.SrpV3()
        pr.streamConnectBiDir( self.srp, self.rudp.application(dest=0x0) )

        # Top level module should be added here.
        # Top level is a sub-class of AmcCarrierCore.AppTop.TopLevel
        # SRP interface should be passed as an arg
        #self.add(FpgaTopLevel(memBase=self.srp))

