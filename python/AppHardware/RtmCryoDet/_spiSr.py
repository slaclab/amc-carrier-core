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
import math

class SpiSr(pr.Device):
    def __init__(   self,
        name        = "RtmSpiSr",
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
        #--entire control register
        self.add(pr.RemoteVariable(
            name         = "ConfigReg",
            description  = "FluxRamp_Reg4",
            offset       =  0x800,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
            overlapEn    = True,
        ))

        #--Ctrl Reg0_[0]
        self.add(pr.RemoteVariable(
            name         = "CfgRegEnaBit",
            description  = "FluxRamp_Reg4_0",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  0, #--offset from LSB
            mode         = "RW",
            overlapEn    = True,
        ))

        #--Ctrl Reg0_[2]
        self.add(pr.RemoteVariable(
            name         = "RampSlope",
            description  = "Sets ramp slope, 0 = Positive, 1 = Negative",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  2, #--offset from LSB
            mode         = "RW",
            overlapEn    = True,
        ))

        #--Ctrl Reg0_[3]
        self.add(pr.RemoteVariable(
            name         = "ModeControl",
            description  = "0 = normal operation, 1 = write to DAC from control registers",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  3, #--offset from LSB
            mode         = "RW",
            overlapEn    = True,
        ))

        self.add(pr.RemoteVariable(    
            name         = "FastSlowStepSizeLow",
            description  = "FluxRamp_Control_Reg5",
            offset       =  0x804,
            bitSize      =  16,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(    
            name         = "FastSlowStepSizeHigh",
            description  = "FluxRamp_Control_Reg5",
            offset       =  0x808,
            bitSize      =  16,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.LinkVariable(    
            name         = "FastSlowStepSize",
            description  = "Flux ramp reset value, UInt32",
            dependencies = [self.FastSlowStepSizeLow, self.FastSlowStepSizeHigh],
            linkedGet    = self.fromReg,
            linkedSet    = self.toReg, 
            typeStr      = "UInt32"
        ))

        self.add(pr.RemoteVariable(    
            name         = "FastSlowRstValueLow",
            description  = "FluxRamp_Control_Reg6",
            offset       =  0x80C,
            bitSize      =  16,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))
         
        self.add(pr.RemoteVariable(    
            name         = "FastSlowRstValueHigh",
            description  = "FluxRamp_Control_Reg6",
            offset       =  0x810,
            bitSize      =  16,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.LinkVariable(    
            name         = "FastSlowRstValue",
            description  = "Flux ramp reset value, UInt32",
            dependencies = [self.FastSlowRstValueLow, self.FastSlowRstValueHigh],
            linkedGet    = self.fromReg,
            linkedSet    = self.toReg, 
            typeStr      = "UInt32"
        ))

        self.add(pr.RemoteVariable(    
            name         = "LTC1668RawDacData",
            description  = "FluxRamp_Control_Reg7",
            offset       =  0x814,
            bitSize      =  16,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

    @staticmethod
    def toReg(dev, var, value):
       highVal = math.floor( value / 2**16 ) 
       lowVal  = value - highVal*2**16
       var.dependencies[0].set( lowVal )
       var.dependencies[1].set( highVal )
 
    @staticmethod
    def fromReg(dev, var, read):
       lowVal  = var.dependencies[0].get(read=read)
       highVal = var.dependencies[1].get(read=read)
       return highVal*2**16 + lowVal
