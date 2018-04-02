#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue CRYO RTM: SPI MAX
#-----------------------------------------------------------------------------
# File       : _spiMax.py
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

class SpiMax(pr.Device):
    def __init__(   self, 
        name        = "RtmSpiMax", 
        description = "RTM Bias DAC SPI Interface", 
        memBase     =  None,
        offset      =  0x00,
        hidden      =  False,
        expand      =  True,
        enabled     =  True
        
    ):     
        super().__init__(
            name        = name,
            description = description,
            memBase     = memBase,
            offset      = offset,
            hidden      = hidden,
            expand      = expand,
            enabled     = enabled,
        )
       
        ##############################
        # Variables
        ##############################

        for i in range(0,225,32):
            if i/32 < 7: 
                j = i/32+1
                str1 = "TesBias"
            else: 
                j = 33
                str1 = "HemtBias"
                         
            self.add(pr.RemoteVariable(
                name         = str1 + "DacNopRegCh[%d]" % (j),
                description  = "BiasDac_Reg0",
                #offset       =  hex(i), #--this does not work
                offset       =  0x00 + i,
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.UInt,
                mode         = "WO",
            ))
            
            self.add(pr.RemoteVariable(    
                name         = str1 + "DacDataRegCh[%d]" % (j),
                description  = "BiasDac_Reg1",
                offset       =  0x00 + (i+4),
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.Int,
                mode         = "WO",
            ))
            
            self.add(pr.RemoteVariable(    
                name         = str1 + "DacCtrlRegCh[%d]" % (j),
                description  = "BiasDac_Reg2",
                offset       =  0x00 + (i+8),
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.UInt,
                mode         = "WO",
            ))
            
            self.add(pr.RemoteVariable(    
                name         = str1 + "DacClrCRegCh[%d]" % (j),
                description  = "BiasDac_Reg3",
                offset       =  0x00 + (i+12),
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.UInt,
                mode         = "WO",
            ))
