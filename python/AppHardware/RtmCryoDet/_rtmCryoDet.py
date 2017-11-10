#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcMicrowaveMux Amc Core
#-----------------------------------------------------------------------------
# File       : RtmCryoDet.py
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

from AppHardware.RtmCryoDet._spiCryo import *
from AppHardware.RtmCryoDet._spiMax import *
from AppHardware.RtmCryoDet._spiSr import *

class RtmCryoDet(pr.Device):
    def __init__(   self, 
            name        = "RtmCryoDet", 
            description = "RtmCryoDet Board", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
                
        #########
        # Devices
        #########
        self.add(SpiCryo(offset=0x00100000, expand=False))    
        self.add(SpiMax( offset=0x00200000, expand=False))    
        self.add(SpiSr(  offset=0x00300000, expand=False))    
        
        ###########
        # Registers
        ###########  
        self.add(pr.RemoteVariable(    
            name         = "LowCycle",
            description  = "CPLD's clock: low cycle duration (zero inclusive)",
            offset       = 0x0,
            bitSize      = 8,
            bitOffset    = 0,
            base         = pr.UInt,
            mode         = "RW",
            units        = "1/(307MHz)",
        )) 
        
        self.add(pr.RemoteVariable(    
            name         = "HighCycle",
            description  = "CPLD's clock: high cycle duration (zero inclusive)",
            offset       = 0x4,
            bitSize      = 8,
            bitOffset    = 0,
            base         = pr.UInt,
            mode         = "RW",
            units        = "1/(307MHz)",
        ))
        