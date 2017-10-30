#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Common Application Top Level JESD Module
#-----------------------------------------------------------------------------
# File       : AppTopJesd.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Common Application Top Level JESD Module
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

from surf.protocols.jesd204b import *

class AppTopJesd(pr.Device):
    def __init__(   self, 
            name        = "AppTopJesd", 
            description = "Common Application Top Level JESD Module", 
            numRxLanes  =  6, 
            numTxLanes  =  2,
            expand      =  False,
            **kwargs):
        super().__init__(name=name, description=description, expand=expand, **kwargs)

        ##############################
        # Variables
        ##############################
        if (numRxLanes > 0):
            self.add(JesdRx(
                offset       =  0x00000000,
                numRxLanes   =  numRxLanes,
                expand       = expand,
            ))

        if (numTxLanes > 0):
            self.add(JesdTx(
                offset       =  0x01000000,
                numTxLanes   =  numTxLanes,
                expand       = expand,
            ))
