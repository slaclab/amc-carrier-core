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
import numpy as np

class SpiMax(pr.Device):
    def __init__(self,
            name        = "RtmSpiMax",
            description = "RTM Bias DAC SPI Interface",
             **kwargs):

        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        self.add(pr.RemoteVariable(
            name         = "TesBiasDacNopRegCh",
            description  = "BiasDac_Reg0",
            offset       =  0x00,
            numValues    =  32,
            valueStride  =  32*8,
            valueBits    =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "TesBiasDacDataRegCh",
            description  = "BiasDac_Reg1",
            offset       =  0x00,
            numValues    =  32,
            valueStride  =  32*8,
            valueBits    =  20,
            bitOffset    =  0x00 + 4*8,
            base         = pr.Int,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "TesBiasDacCtrlRegCh",
            description  = "BiasDac_Reg2",
            offset       =  0x00,
            numValues    =  32,
            valueStride  =  32*8,
            valueBits    =  20,
            bitOffset    =  0x00 + 8*8,
            value        =  0x2,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "TesBiasDacClrCRegCh",
            description  = "BiasDac_Reg3",
            offset       =  0x00,
            numValues    =  32,
            valueStride  =  32*8,
            valueBits    =  20,
            bitOffset    =  0x00 + 12*8,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "HemtBiasDacNopRegCh",
            description  = "BiasDac_Reg0",
            offset       =  0x00 + 1024,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "HemtBiasDacDataRegCh",
            description  = "BiasDac_Reg1",
            offset       =  0x00 + 1024 + 4,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.Int,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "HemtBiasDacCtrlRegCh",
            description  = "BiasDac_Reg2",
            offset       =  0x00 + 1024 + 8,
            bitSize      =  20,
            bitOffset    =  0x00,
            value        =  0x2,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "HemtBiasDacClrCRegCh",
            description  = "BiasDac_Reg3",
            offset       =  0x00 + 1024 + 12,
            bitSize      =  20,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        @self.command(description="Set all DACs to 0")
        def initializeAllDac():
            enable = np.array([2 for _ in range(32)], dtype=np.uint32)
            val    = np.array([0 for _ in range(32)], dtype=np.int32)
            self.TesBiasDacCtrlRegCh.set(enable, write=True)
            self.TesBiasDacDataRegCh.set(val, write=True)
