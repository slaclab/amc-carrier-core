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
from surf.devices.ti._Lmk04828  import *
from common.AppCore import *
import time

class AppTop(pr.Device):
    def __init__(   self, 
            name           = "AppTop", 
            description    = "Common Application Top Level", 
            numRxLanes     = [0,0], 
            numTxLanes     = [0,0],
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
                
        @self.command(description  = "JESD Reset")        
        def JesdReset():
            for i in range(2):
                if (self._numRxLanes[i] > 0):
                    v = getattr(self, 'AppTopJesd[%i]'%i)
                    v.JesdRx.LinkErrMask.set(0x3F)            
            lmkDevices = self.find(typ=Lmk04828)
            for lmk in lmkDevices: 
                lmk.PwrDwnSysRef()
            self.checkBlocks(recurse=True)
            for i in range(2):
                if (self._numRxLanes[i] > 0):
                    v = getattr(self, 'AppTopJesd[%i]'%i)
                    v.JesdRx.CmdResetGTs()
                if (self._numTxLanes[i] > 0):
                    v = getattr(self, 'AppTopJesd[%i]'%i)
                    v.JesdTx.CmdResetGTs()
            self.checkBlocks(recurse=True)
            time.sleep(1.0)
            for lmk in lmkDevices: 
                lmk.PwrUpSysRef()            
            time.sleep(1.0)
            for i in range(2):
                if (self._numRxLanes[i] > 0):
                    v = getattr(self, 'AppTopJesd[%i]'%i)
                    v.JesdRx.CmdClearErrors()
                    v.JesdRx.LinkErrMask.set(0x38) # Work around for DEC2017 demo, plan to remove this line when we receive C07 revision of the AMC carrier. 
                if (self._numTxLanes[i] > 0):
                    v = getattr(self, 'AppTopJesd[%i]'%i)
                    v.JesdTx.CmdClearErrors()        
        
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
        self.JesdReset()
        for i in range(2):
            if ( (self._numSigGen[i] > 0) and (self._sizeSigGen[i] > 0) ):
                v = getattr(self, 'DacSigGen[%i]'%i)
                if ( v.CsvFilePath.get() != "" ):
                    v.LoadCsvFile("")
        self.checkBlocks(recurse=True)
