#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue _amcCarrierCore Module
#-----------------------------------------------------------------------------
# File       : _amcCarrierCore.py
# Created    : 2017-03-08
# Last update: 2017-03-08
#-----------------------------------------------------------------------------
# Description:
# PyRogue _amcCarrierCore Module
#-----------------------------------------------------------------------------
# This file is part of the ATLAS CHESS2 DEV. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the ATLAS CHESS2 DEV, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import surf
import AmcCarrierCore

class Core(pr.Device):
    def __init__(self, name="Core", memBase=None, offset=0, hidden=False):
        super(self.__class__, self).__init__(name, "AmcCarrierCore Module",
                                             memBase=memBase, offset=offset, hidden=hidden)
        
        self.add(surf.AxiVersion(         offset=0x00000000,expand=False))
        self.add(surf.AxiSysMonUltraScale(offset=0x01000000,expand=False))
        self.add(surf.AxiMicronN25Q(      offset=0x02000000,expand=False))
        self.add(surf.AxiSy56040(         offset=0x03000000,expand=False))
        self.add(AmcCarrierCore.bsi(         offset=0x03000000,expand=False))
        self.add(AmcCarrierCore.timing(         offset=0x03000000,expand=False))
        self.add(AmcCarrierCore.bsa(         offset=0x03000000,expand=False))
        self.add(surf.UdpClient(         offset=0x03000000,expand=False))
        self.add(surf.UdpServer(         offset=0x03000000,expand=False))
        self.add(surf.Rssi(         offset=0x03000000,expand=False))
        
        
        
        ######################################
        # SACI base address and address stride 
        ######################################
        saciAddr = 0x01000000
        saciChip = 0x400000        
        
        #############
        # Add devices
        #############
        self.add(surf.Xadc(                offset=0x00010000,expand=False))  
        self.add(AtlasChess2Feb.sysReg(    offset=0x00030000,expand=False))    
        self.add(AtlasChess2Feb.dac(       offset=0x00100000,expand=False))                
        self.add(AtlasChess2Feb.chargeInj(offset=0x00330000,expand=False))   
                
        for i in range(3):
            self.add(AtlasChess2Feb.Chess2Array( 
                name='Chess2Ctrl%01i'%(i),
                offset=(saciAddr + i*saciChip),expand=False))   
                
        self.add(AtlasChess2Feb.Chess2Test(offset=saciAddr+(3*saciChip),expand=False))
        