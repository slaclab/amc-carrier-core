#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcCarrier MPS PHY Module
#-----------------------------------------------------------------------------
# File       : AppMpsThr.py
# Created    : 2017-05-26
#-----------------------------------------------------------------------------
# Description:
# PyRogue AmcCarrier MPS PHY Module
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

class AppMpsThr(pr.Device):
    def __init__(   self,       
            name        = "AppMpsThr",
            description = "AppMpsThr Module",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        self.add(pr.RemoteVariable(    
            name         = "MpsAppId",
            description  = "Application ID",
            offset       =  0x00,
            bitSize      =  10,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "MpsEnable",
            description  = "Mps enable",
            offset       =  0x00,
            bitSize      =  1,
            bitOffset    =  16,
            base         = pr.UInt,
            mode         = "RW",
        ))  

        self.add(pr.RemoteVariable(    
            name         = "Lcls1Mode",
            description  = "True = LCLS1, False = LCLS2 mode",
            offset       =  0x00,
            bitSize      =  1,
            bitOffset    =  17,
            base         = pr.UInt,
            mode         = "RW",
        ))  

        self.add(pr.RemoteVariable(    
            name         = "MpsVersion",
            description  = "Mps Version",
            offset       =  0x00,
            bitSize      =  5,
            bitOffset    =  24,
            base         = pr.UInt,
            mode         = "RW",
        ))          
        
        self.add(pr.RemoteVariable(    
            name         = "ByteCount",
            description  = "Number of bytes in MPS message",
            offset       =  0x04,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))     

        self.add(pr.RemoteVariable(    
            name         = "DigitalEn",
            description  = "Application generates digital message",
            offset       =  0x04,
            bitSize      =  1,
            bitOffset    =  8,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))   

        self.add(pr.RemoteVariable(    
            name         = "BeamDestMask",
            description  = "One bit per destination for BPM or kicker not idle for idelEn=true",
            offset       =  0x08,
            bitSize      =  16,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(    
            name         = "AltDestMask",
            description  = "One bit per destination for alternative table for altEn=true",
            offset       =  0x08,
            bitSize      =  16,
            bitOffset    =  16,
            base         = pr.UInt,
            mode         = "RW",
        ))
        