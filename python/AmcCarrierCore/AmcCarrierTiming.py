#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AMC Carrier Timing Receiver Module
#-----------------------------------------------------------------------------
# File       : AmcCarrierTiming.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue AMC Carrier Timing Receiver Module
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

from LclsTimingCore.TimingFrameRx import *
from LclsTimingCore.TPGMiniCore import *
from LclsTimingCore.GthRxAlignCheck import *

class AmcCarrierTiming(pr.Device):
    def __init__(   self, 
            name        = "AmcCarrierTiming", 
            description = "AMC Carrier Timing Receiver Module", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        self.add(TimingFrameRx(
            offset = 0x00000000,
        ))

        self.add(TPGMiniCore(
            offset = 0x00030000,
        ))

        self.add(GthRxAlignCheck(
            offset = 0x00800000,
        ))        
