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
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        self.add(Adc16Dx370(offset=0x00020000, name='ADC[0]', expand=False))
        self.add(Adc16Dx370(offset=0x00040000, name='ADC[1]', expand=False))
        self.add(Adc16Dx370(offset=0x00060000, name='ADC[2]', expand=False))
        self.add(Lmk04828(  offset=0x00080000, name='LMK',    expand=False))
        self.add(Dac38J84(  offset=0x000A0000, name='DAC',    expand=False, numTxLanes=2))

        @self.command(description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
            self.checkBlocks(recurse=True)
            self.ADC[0].CalibrateAdc()
            self.ADC[1].CalibrateAdc()
            self.ADC[2].CalibrateAdc()
            self.LMK.Init()
            self.DAC.Init()        
            self.checkBlocks(recurse=True)  
           
    def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
        """
        Write all of the blocks held by this Device to memory
        """
        if not self.enable.get(): return

        # Process local blocks.
        if variable is not None:
            #variable._block.startTransaction(rogue.interfaces.memory.Write, check=checkEach) # > 2.4.0
            variable._block.backgroundTransaction(rogue.interfaces.memory.Write)
        else:
            for block in self._blocks:
                if force or block.stale:
                    if block.bulkEn:
                        #block.startTransaction(rogue.interfaces.memory.Write, check=checkEach) # > 2.4.0
                        block.backgroundTransaction(rogue.interfaces.memory.Write)

        # Process rest of tree
        if recurse:
            for key,value in self.devices.items():
                #value.writeBlocks(force=force, recurse=True, checkEach=checkEach) # > 2.4.0
                value.writeBlocks(force=force, recurse=True)
                        
        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)
        
        self.enable.set(True)
        self.ADC[0].enable.set(True)
        self.ADC[1].enable.set(True)         
        self.ADC[2].enable.set(True)         
        self.LMK.enable.set(True)        
        self.DAC.enable.set(True)
        
        # Init the AMC card
        self.InitAmcCard()
        
        # Stop SPI transactions after configuration to minimize digital crosstalk to ADC/DAC
        self.ADC[0].enable.set(False)
        self.ADC[1].enable.set(False)         
        self.ADC[2].enable.set(False)         
        self.DAC.enable.set(False)    
        self.checkBlocks(recurse=True)        
        
