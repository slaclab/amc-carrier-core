#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : AmcGenericAdcDacCore.py
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

from surf.devices.ti import *

from AppHardware.AmcGenericAdcDac._AmcGenericAdcDacCtrl import *

class AmcGenericAdcDacCore(pr.Device):
    def __init__(   self, 
            name        = "AmcGenericAdcDacCore", 
            description = "Generic ADC/DAC Board", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
                
        #########
        # Devices
        #########
        self.add(AmcGenericAdcDacCtrl(  offset=0x00000000, name='DBG',    expand=False))
        self.add(Dac38J84(              offset=0x00002000, name='DAC',    expand=False, numTxLanes=2))
        self.add(Lmk04828(              offset=0x00020000, name='LMK',    expand=False))
        self.add(Adc16Dx370(            offset=0x00040000, name='ADC[0]', expand=False))
        self.add(Adc16Dx370(            offset=0x00060000, name='ADC[1]', expand=False))

        @self.command(description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
            self.checkBlocks(recurse=True)
            self.ADC[0].CalibrateAdc()
            self.ADC[1].CalibrateAdc()
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

        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)
        
        # Note: Requires that AmcCryoCore: enable: 'True' in defaults.yml file
        self.enable.set(True)
        self.DBG.enable.set(True)
        self.DAC.enable.set(True)
        self.LMK.enable.set(True)        
        self.ADC[0].enable.set(True)
        self.ADC[1].enable.set(True)    

        self.DAC.DacReg[2].set(0x2080) # Setup the SPI configuration
        
        #self.DBG.writeBlocks(force=force, recurse=recurse, variable=variable, checkEach=checkEach) # > 2.4.0
        self.DBG.writeBlocks(force=force, recurse=recurse, variable=variable)
        #self.DAC.writeBlocks(force=force, recurse=recurse, variable=variable, checkEach=checkEach) # > 2.4.0
        self.DAC.writeBlocks(force=force, recurse=recurse, variable=variable)
        #self.LMK.writeBlocks(force=force, recurse=recurse, variable=variable, checkEach=checkEach) # > 2.4.0
        self.LMK.writeBlocks(force=force, recurse=recurse, variable=variable)
        #self.ADC[0].writeBlocks(force=force, recurse=recurse, variable=variable, checkEach=checkEach) # > 2.4.0
        self.ADC[0].writeBlocks(force=force, recurse=recurse, variable=variable)
        #self.ADC[1].writeBlocks(force=force, recurse=recurse, variable=variable, checkEach=checkEach) # > 2.4.0
        self.ADC[1].writeBlocks(force=force, recurse=recurse, variable=variable)

        self.InitAmcCard()
        
        # Stop SPI transactions after configuration to minimize digital crosstalk to ADC/DAC
        self.ADC[0].enable.set(False)
        self.ADC[1].enable.set(False)         
        self.DAC.enable.set(False)    
        self.checkBlocks(recurse=True)        
        
