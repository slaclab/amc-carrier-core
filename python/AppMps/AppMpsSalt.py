#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcCarrier MPS PHY Module
#-----------------------------------------------------------------------------
# File       : AppMpsSalt.py
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

class AppMpsSalt(pr.Device):
    def __init__(   self,       
            name        = "AppMpsSalt",
            description = "AmcCarrier MPS PHY Module",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        self.add(pr.RemoteVariable(    
            name         = "MpsTxLinkUpCnt",
            description  = "MPS TX LinkUp Counter",
            offset       =  0x00,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.addRemoteVariables( 
            name         = "MpsRxLinkUpCnt",
            description  = "MPS RX LinkUp Counter[13:0]",
            offset       =  0x04,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            number       =  14,
            stride       =  4,
            pollInterval = 1,
        )
        
        self.add(pr.RemoteVariable(    
            name         = "MpsTxPktSentCnt",
            description  = "MPS TX Packet Sent Counter",
            offset       =  0x80,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.addRemoteVariables( 
            name         = "MpsRxPktRcvdSentCnt",
            description  = "MPS RX Packet Received Counter[13:0]",
            offset       =  0x84,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            number       =  14,
            stride       =  4,
            pollInterval = 1,
        )        

        self.add(pr.RemoteVariable(    
            name         = "MpsTxLinkUP",
            description  = "MPS TX LinkUp",
            offset       =  0x700,
            bitSize      =  1,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(    
            name         = "MpsRxLinkUP",
            description  = "MPS TX LinkUp[13:0]",
            offset       =  0x700,
            bitSize      =  14,
            bitOffset    =  0x01,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(    
            name         = "MPS_SLOT_G",
            description  = "MPS_SLOT_G",
            offset       =  0x704,
            bitSize      =  1,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(    
            name         = "APP_TYPE_G",
            description  = "See AmcCarrierPkg.vhd for defination",
            offset       =  0x708,
            bitSize      =  7,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(    
            name         = "MpsPllLocked",
            description  = "MPS PLL Lock Status",
            offset       =  0x714,
            bitSize      =  1,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "DiagnosticStrbCnt",
            description  = "Counts the diagnostic strobes",
            offset       =  0x718,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(    
            name         = "RollOverEn",
            description  = "Status Counter Roll Over Enable",
            offset       =  0xFF0,
            bitSize      =  15,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(    
            name         = "CntRst",
            description  = "Status Counter Reset",
            offset       =  0xFF4,
            bitSize      =  1,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "PllRst",
            description  = "PLL Reset",
            offset       =  0xFF8,
            bitSize      =  1,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))        

        ##############################
        # Commands
        ##############################
        @self.command(name="RstCnt", description="Reset all the status counters",)
        def RstCnt():
            self.CntRst.set(1)
            
        @self.command(name="RstPll", description="PLL Reset",)
        def RstPll():
            self.PllRst.set(1)            
