#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : AmcCryoCore.py
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

from surf.devices.ti._Dac38J84 import *
from surf.devices.ti._Lmk04828 import *

from AmcCryo._adc32Rf45 import *

class AmcCryoCore(pr.Device):
    def __init__(   self, 
                    name        = "AmcCryoCore", 
                    description = "Cryo Amc Rf Demo Board Core", 
                    memBase     =  None, 
                    offset      =  0x0, 
                    hidden      =  False,
                    expand      =  True,
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden, expand=expand)

        #########
        # Devices
        #########
        self.add(Lmk04828( offset=0x00020000,name='LMK',   expand=False))
        self.add(Dac38J84( offset=0x00040000,name='DAC_0', expand=False))
        self.add(Dac38J84( offset=0x00060000,name='DAC_1', expand=False))
        self.add(Adc32Rf45(offset=0x00080000,name='ADC_0', expand=False))
        # self.add(Adc32Rf45(offset=0x000C0000,name='ADC_1', expand=False))

        ##########
        # Commands
        ##########
        self.addCommand(    name         = "InitAmcCard",
                            description  = "Initialization for AMC card's JESD modules",
                            function     = """\
                                           self.Lmk04828.PwrUpSysRef.set(1)
                                           self.usleep(1000000)
                                           self.Dac38J84.InitDac.set(1)
                                           self.usleep(100000)
                                           self.Dac38J84.ClearAlarms.set(1)
                                           """
                        )
