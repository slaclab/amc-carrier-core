#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Rf Demo Board Core
#-----------------------------------------------------------------------------
# File       : RtmDigitalDebug.py
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

class RtmDigitalDebug(pr.Device):
    def __init__(   self, 
            name        = "RtmDigitalDebug", 
            description = "", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        

        self.add(pr.RemoteVariable(   
            name         = "doutDisable",
            description  = "doutDisable",
            offset       =  0x0,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))   

        self.add(pr.RemoteVariable(   
            name         = "pllRst",
            description  = "pllRst",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "WO",
        ))    

        self.add(pr.RemoteVariable(   
            name         = "los",
            description  = "los",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    =  3,
            base         = pr.UInt,
            mode         = "RO",
            # pollInterval = 1
        ))      

        self.add(pr.RemoteVariable(   
            name         = "lol",
            description  = "lol",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    =  4,
            base         = pr.UInt,
            mode         = "RO",
            # pollInterval = 1
        ))  

        self.add(pr.RemoteVariable(   
            name         = "locked",
            description  = "locked",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    =  5,
            base         = pr.UInt,
            mode         = "RO",
            # pollInterval = 1
        ))           
        
        self.add(pr.RemoteVariable(   
            name         = "pllFrqTbl",
            description  = "pllFrqTbl",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    = 10,
            base         = pr.UInt,
            mode         = "RW",
        ))   

        self.add(pr.RemoteVariable(   
            name         = "pllFrqTblTri",
            description  = "pllFrqTblTri",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    = 11,
            base         = pr.UInt,
            mode         = "RW",
        ))   

        self.add(pr.RemoteVariable(   
            name         = "pllRate",
            description  = "pllRate",
            offset       =  0x4,
            bitSize      =  2,
            bitOffset    = 12,
            base         = pr.UInt,
            mode         = "RW",
        ))         

        self.add(pr.RemoteVariable(   
            name         = "pllRateTri",
            description  = "pllRateTri",
            offset       =  0x4,
            bitSize      =  2,
            bitOffset    = 14,
            base         = pr.UInt,
            mode         = "RW",
        ))    

        self.add(pr.RemoteVariable(   
            name         = "pllSFout",
            description  = "pllSFout",
            offset       =  0x4,
            bitSize      =  2,
            bitOffset    = 16,
            base         = pr.UInt,
            mode         = "RW",
        ))         

        self.add(pr.RemoteVariable(   
            name         = "pllSFoutTri",
            description  = "pllSFoutTri",
            offset       =  0x4,
            bitSize      =  2,
            bitOffset    = 18,
            base         = pr.UInt,
            mode         = "RW",
        ))     

        self.add(pr.RemoteVariable(   
            name         = "pllBwSel",
            description  = "pllBwSel",
            offset       =  0x4,
            bitSize      =  2,
            bitOffset    = 20,
            base         = pr.UInt,
            mode         = "RW",
        ))         

        self.add(pr.RemoteVariable(   
            name         = "pllBwSelTri",
            description  = "pllBwSelTri",
            offset       =  0x4,
            bitSize      =  2,
            bitOffset    = 22,
            base         = pr.UInt,
            mode         = "RW",
        ))       

        self.add(pr.RemoteVariable(   
            name         = "pllFrqSel",
            description  = "pllFrqSel",
            offset       =  0x4,
            bitSize      =  4,
            bitOffset    = 24,
            base         = pr.UInt,
            mode         = "RW",
        ))         

        self.add(pr.RemoteVariable(   
            name         = "pllFrqSelTri",
            description  = "pllFrqSelTri",
            offset       =  0x4,
            bitSize      =  4,
            bitOffset    = 28,
            base         = pr.UInt,
            mode         = "RW",
        ))               
        
        self.add(pr.RemoteVariable(   
            name         = "FpgaPllLocked",
            description  = "FpgaPllLocked",
            offset       =  0x8,
            bitSize      =  1,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1
        ))  
        
        self.add(pr.RemoteVariable(   
            name         = "cntLos",
            description  = "cntLos",
            offset       =  0x80,
            bitSize      =  32,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1
        ))  

        self.add(pr.RemoteVariable(   
            name         = "cntLol",
            description  = "cntLol",
            offset       =  0x84,
            bitSize      =  32,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1
        ))   

        self.add(pr.RemoteVariable(   
            name         = "cntLocked",
            description  = "cntLocked",
            offset       =  0x88,
            bitSize      =  32,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1
        ))

        self.add(pr.RemoteVariable(   
            name         = "cntPllRst",
            description  = "cntPllRst",
            offset       =  0x8C,
            bitSize      =  32,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1
        ))        

        self.add(pr.RemoteVariable(   
            name         = "cntRst",
            description  = "cntRst",
            offset       =  0xFC,
            bitSize      =  1,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "WO",
        ))            
        