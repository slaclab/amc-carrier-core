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

from AppTop.AppTopTrig import *
from AppTop.AppTopJesd import *
from DacSigGen.DacSigGen import *
from DaqMuxV2.DaqMuxV2 import *
from common.AppCore import *

class AppTop(pr.Device):
    def __init__(   self, 
                    name        = "AppTop", 
                    description = "Common Application Top Level", 
                    memBase     =  None, 
                    offset      =  0x0, 
                    hidden      =  False, 
                    numRxLanes  =  [0,0], 
                    numTxLanes  =  [0,0],
                    expand      =  True,
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden, expand=expand)
        
        self._numRxLanes = numRxLanes
        self._numTxLanes = numTxLanes
        
        ##############################
        # Variables
        ##############################

        self.add(AppCore(   
                                    offset       =  0x00000000, 
                                    expand       =  True
                        ))

        self.add(AppTopTrig(
                                    offset       =  0x10000000, 
                                    expand       =  False
                           ))

        for i in range(2):
            self.add(DaqMuxV2(
                                        name         = "DaqMuxV2[%i]" % (i),
                                        offset       =  0x20000000 + (i * 0x10000000),
                                        expand       =  False,
                             ))

        for i in range(2):
            if ((numRxLanes[i] > 0) or (numTxLanes[i] > 0)):
                self.add(AppTopJesd(
                                            name         = "AppTopJesd[%i]" % (i),
                                            offset       =  0x40000000 + (i * 0x10000000),
                                            numRxLanes   =  numRxLanes[i],
                                            numTxLanes   =  numTxLanes[i],
                                            expand       =  False,
                                   ))

        for i in range(2):
            self.add(DacSigGen(
                                        name         = "DacSigGen[%i]" % (i),
                                        offset       =  0x60000000 + (i * 0x10000000),
                                        instantiate  =  False,
                                        expand       =  False
                              ))
                              
    def writeBlocks(self, force=False, recurse=True, variable=None):
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
        self._root.checkBlocks(varUpdate=True, recurse=True)
                        
        for i in range(2):
            if (self._numRxLanes[i] > 0):
                v = getattr(self, 'AppTopJesd[%i]'%i)
                v.JesdRx.CmdResetGTs()
                v.JesdRx.CmdClearErrors()
            if (self._numTxLanes[i] > 0):
                v = getattr(self, 'AppTopJesd[%i]'%i)
                v.JesdTx.CmdResetGTs()
                v.JesdTx.CmdClearErrors()                
        self.checkBlocks(recurse=True)