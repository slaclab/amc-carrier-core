#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue CRYO RTM: SPI SR
#-----------------------------------------------------------------------------
# File       : _spiSr.py
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

class SpiSr(pr.Device):
    def __init__(   self, 
        name        = "C_RtmSpiSr", 
        description = "RTM Flux Ramp SPI Interface", 
        memBase     =  None,
        offset      =  0x00,
        hidden      =  False,
        expand      =  True,
        enabled     =  True,

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
        
        self.add(pr.RemoteVariable(    
            name         = "AD5790_NOP_Reg",
            description  = "FluxRamp_Reg0",
            offset       =  0x00,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "AD5790_Data_Reg",
            description  = "FluxRamp_Reg1",
            offset       =  0x04,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "AD5790_Ctrl_Reg",
            description  = "FluxRamp_Reg2",
            offset       =  0x08,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "AD5790_ClrCode_Reg",
            description  = "FluxRamp_Reg3",
            offset       =  0x0C,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))

        #--entire control register
        self.add(pr.RemoteVariable(    
            name         = "Config_Reg",
            description  = "FluxRamp_Reg4",
            offset       =  0x20,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))

        #--Ctrl Reg0_[0]
        self.add(pr.RemoteVariable(   
            name         = "Cfg_Reg_Ena Bit",
            description  = "FluxRamp_Reg4_0",
            offset       =  0x20,
            bitSize      =  1,
            bitOffset    =  0, #--offset from LSB
            mode         = "WO",
        ))        
        
        #--Ctrl Reg0_[2]
        self.add(pr.RemoteVariable(   
            name         = "Ramp Slope",
            description  = "FluxRamp_Reg4_1",
            offset       =  0x20,
            bitSize      =  1,
            bitOffset    =  2, #--offset from LSB
            mode         = "WO",
        ))        
        
        #--Ctrl Reg0_[3]
        self.add(pr.RemoteVariable(   
            name         = "Mode Control",
            description  = "FluxRamp_Reg4_3",
            offset       =  0x20,
            bitSize      =  1,
            bitOffset    =  3, #--offset from LSB
            mode         = "WO",
        ))        

        self.add(pr.RemoteVariable(    
            name         = "Slow Step Size",
            description  = "FluxRamp_Control_Reg5",
            offset       =  0x24,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))

        self.add(pr.RemoteVariable(    
            name         = "Slow Rst Value",
            description  = "FluxRamp_Control_Reg6",
            offset       =  0x28,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
         
        self.add(pr.RemoteVariable(    
            name         = "Fast Step Size",
            description  = "FluxRamp_Control_Reg7",
            offset       =  0x2C,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))

        self.add(pr.RemoteVariable(    
            name         = "Fast Rst Value",
            description  = "FluxRamp_Control_Reg8",
            offset       =  0x30,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
        
        self.add(pr.RemoteVariable(    
            name         = "LTC1668 Raw DAC Data",
            description  = "FluxRamp_Control_Reg9",
            offset       =  0x34,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "WO",
        ))
