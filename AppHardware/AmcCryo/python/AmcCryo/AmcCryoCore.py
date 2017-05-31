#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : AmcCryoCore.py
# Created    : 2017-05-30
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

from surf._Adc16Dx370 import *
from surf._Lmk04828 import *
from surf._Dac38J84 import *
from surf._Adc32Rf45 import *

class AmcCryoCore(pr.Device):
    def __init__(   self, 
                    name        = "AmcCryoDemoCore", 
                    description = "Cryo Amc Rf Demo Board Core", 
                    memBase     =  None, 
                    offset      =  0x0, 
                    hidden      =  False
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden)

        ##############################
        # Variables
        ##############################
        
        for i in range(2):
          self.add(Adc32Rf45(
                                  name         = "Adc32Rf45_%i" % (i),
                                  offset       =  0x00020000 + (i * 0x00020000),
                              ))
        
        self.add(Lmk04828(
                                offset       = 0x000A0000,
                            ))
#        for i in range(2):
#          self.add(Dac38J84(
#                                  name         = "Dac38J84_%i" % (i),
#                                  offset       =  0x00060000 + (i * 0x00020000),
#                              ))

        ##############################
        # Commands
        ##############################

        self.addCommand(    name         = "InitAmcCard",
                            description  = "Initialization for AMC card's JESD modules",
                            function     = """\
                                           self.usleep(1000000)
                                           self.Lmk04828.PwrUpSysRef.set(1)
                                           self.usleep(1000000)
                                           self.Dac38J84.InitDac.set(1)
                                           self.usleep(100000)
                                           self.Dac38J84.ClearAlarms.set(1)
                                           """
                        )
