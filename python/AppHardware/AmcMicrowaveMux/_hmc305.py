#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : _hmc305.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue Cryo Amc Core
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
import time

class Hmc305(pr.Device):
    def __init__(   self, 
            name        = "Hmc305", 
            description = "Hmc305 module", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
           
        devConfig = [
            ['DC[1]', 0x1C],
            ['DC[2]', 0x08],
            ['DC[3]', 0x04],
            ['DC[4]', 0x00],
            ['UC[1]', 0x18],
            ['UC[2]', 0x14],
            ['UC[3]', 0x10],
            ['UC[4]', 0x0C],
        ]
            
        for i in range(8):     
            self.add(pr.RemoteVariable(
                name        = devConfig[i][0], 
                description = 'Hmc305 Device: Note that firmware does an invert and bit order swap to make the software interface with a LSB of 0.5dB',
                offset      = devConfig[i][1], 
                bitSize     = 5, 
                mode        = 'WO',
                units       = '0.5dB',
            ))
            