#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcCarrier BSA Module
#-----------------------------------------------------------------------------
# File       : AmcCarrierBsa.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue AmcCarrier BSA Module
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

from BsaCore.BsaBufferControl import *
from BsaCore.BsaWaveformEngine import *

class AmcCarrierBsa(pr.Device):
    def __init__( self, 
            name        = "AmcCarrierBsa", 
            description = "AmcCarrier BSA Module", 
            enableBsa   = True,
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        ##############################
        # Variables
        ##############################

        if (enableBsa):
            self.add(BsaBufferControl(
                offset       =  0x00000000,
            ))

        for i in range(2):
            self.add(BsaWaveformEngine(
                name         = "BsaWaveformEngine[%i]" % (i), 
                offset       =  0x00010000 + i * 0x00010000,
            ))
