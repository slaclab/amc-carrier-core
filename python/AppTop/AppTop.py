#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Common Application Top Level
#-----------------------------------------------------------------------------
# File       : AppTop.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue Common Application Top Level
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

from AppTop.AppTopJesd import *
from DacSigGen.DacSigGen import *
from DaqMuxV2.DaqMuxV2 import *
from common.AppCore import *

import surf.devices.ti         as ti
import surf.protocols.jesd204b as jesd

import time

class AppTop(pr.Device):
    def __init__(   self, 
            name           = "AppTop", 
            description    = "Common Application Top Level", 
            numRxLanes     = [0,0], 
            numTxLanes     = [0,0],
            enJesdDrp      = False,
            numSigGen      = [0,0],
            sizeSigGen     = [0,0],
            modeSigGen     = [False,False],
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        self._numRxLanes = numRxLanes
        self._numTxLanes = numTxLanes
        self._numSigGen  = numSigGen
        self._sizeSigGen = sizeSigGen
        
        ##############################
        # Variables
        ##############################

        self.add(AppCore(   
            offset       =  0x00000000, 
            numRxLanes   =  numRxLanes,
            numTxLanes   =  numTxLanes,
            expand       =  True,
        ))

        for i in range(2):
            self.add(DaqMuxV2(
                name         = "DaqMuxV2[%i]" % (i),
                offset       =  0x20000000 + (i * 0x10000000),
                expand       =  False,
            ))

        for i in range(2):
            if ( (numRxLanes[i] > 0) or (numTxLanes[i] > 0) ):
                self.add(AppTopJesd(
                    name         = "AppTopJesd[%i]" % (i),
                    offset       =  0x40000000 + (i * 0x10000000),
                    numRxLanes   =  numRxLanes[i],
                    numTxLanes   =  numTxLanes[i],
                    enJesdDrp    =  enJesdDrp,
                    expand       =  False,
                ))

        for i in range(2):
            if ( (numSigGen[i] > 0) and (sizeSigGen[i] > 0) ):
                self.add(DacSigGen(
                    name         = "DacSigGen[%i]" % (i),
                    offset       =  0x60000000 + (i * 0x10000000),
                    numOfChs     =  numSigGen[i],
                    buffSize     =  sizeSigGen[i],
                    fillMode     =  modeSigGen[i],
                    expand       =  False,
                ))
                
        @self.command(description  = "AppTop Init() cmd")        
        def Init():
            # Get devices
            jesdRxDevices = self.find(typ=jesd.JesdRx)
            jesdTxDevices = self.find(typ=jesd.JesdTx)
            appCore       = self.find(typ=AppCore)
            sigGenDevices = self.find(typ=DacSigGen)
            
            # Power down AppCore (power down SysRef)
            for core in appCore:
                core.Disable()
            # GTs Reset
            for rx in jesdRxDevices: 
                rx.CmdResetGTs()
            for tx in jesdTxDevices: 
                tx.CmdResetGTs()
            self.checkBlocks(recurse=True)
            time.sleep(1.0)
            # Init the AppCore
            for core in appCore:
                core.Init()
            # Wait for the system settle
            time.sleep(0.5)            
            # Clear all error counters
            for rx in jesdRxDevices: 
                rx.CmdClearErrors()  
            for tx in jesdTxDevices: 
                tx.CmdClearErrors()
            # Load the DAC signal generator
            for sigGen in sigGenDevices: 
                if ( sigGen.CsvFilePath.get() != "" ):
                    sigGen.LoadCsvFile("")
                    
    def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
        """
        Write all of the blocks held by this Device to memory
        """
        if not self.enable.get(): return

        # Process local blocks.
        if variable is not None:
            variable._block.backgroundTransaction(rogue.interfaces.memory.Write)
        else:
            for block in self._blocks:
                if force or block.stale:
                    if block.bulkEn:
                        block.backgroundTransaction(rogue.interfaces.memory.Write)

        # Process rest of tree
        if recurse:
            for key,value in self.devices.items():
                value.writeBlocks(force=force, recurse=True)
                        
        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)
        
        # Perform the device init 
        self.Init()

        self.checkBlocks(recurse=True)
