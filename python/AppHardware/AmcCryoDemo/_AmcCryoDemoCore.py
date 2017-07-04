#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Rf Demo Board Core
#-----------------------------------------------------------------------------
# File       : AmcCryoDemoCore.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue Cryo Amc Rf Demo Board Core
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

from surf.devices.ti import *

class AmcCryoDemoCore(pr.Device):
    def __init__(   self, 
        name        = "AmcCryoDemoCore", 
        description = "Cryo Amc Rf Demo Board Core", 
        memBase     =  None, 
        offset      =  0x0, 
        hidden      =  False
        expand      =  True,
    ):
        super().__init__(
            name        = name,
            description = description,
            memBase     = memBase,
            offset      = offset,
            hidden      = hidden,
            expand      = expand,
        )

        ##############################
        # Variables
        ##############################
        
        for i in range(3):
            self.add(Adc16Dx370(
                name   = "Adc16Dx370_%i" % (i),
                offset =  0x00010000 + (i * 0x00010000),
            ))
        
        self.add(Lmk04828(
            offset =  0x00040000,
        ))
        
        self.add(Dac38J84(
            offset =  0x00050000,
        ))

        ##############################
        # Commands
        ##############################
        @self.command(name="InitAmcCard", description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
           self.Adc16Dx370_0.CalibrateAdc.set(1)
           self.Adc16Dx370_1.CalibrateAdc.set(1)
           self.Adc16Dx370_2.CalibrateAdc.set(1)
           time.sleep(1.0)
           self.Lmk04828.PwrUpSysRef.set(1)
           time.sleep(1.0)
           self.Dac38J84.InitDac.set(1)
           time.sleep(0.1)
           time.sleep(1.0)
           self.Dac38J84.ClearAlarms.set(1)
