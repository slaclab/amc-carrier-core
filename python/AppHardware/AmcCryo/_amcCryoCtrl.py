#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : _amcCryoCtrl.py
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

class AmcCryoCtrl(pr.Device):
    def __init__(   self, 
            name        = "AmcCryoCtrl", 
            description = "Debugging module", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
                        
        self.add(pr.RemoteVariable(   
            name         = "txSyncRaw",
            description  = "txSyncRaw",
            offset       =  0x7F0,
            bitSize      =  2,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))      

        self.add(pr.RemoteVariable(   
            name         = "txSync",
            description  = "txSync",
            offset       =  0x7F4,
            bitSize      =  2,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))       

        self.add(pr.RemoteVariable(   
            name         = "rxSync",
            description  = "rxSync",
            offset       =  0x7F8,
            bitSize      =  1,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))                               
        
        self.add(pr.RemoteVariable(   
            name         = "txSyncMask",
            description  = "txSyncMask",
            offset       =  0x800,
            bitSize      =  2,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))                           
                        