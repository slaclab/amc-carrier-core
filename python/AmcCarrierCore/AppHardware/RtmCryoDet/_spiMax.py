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
    def __init__(self,
            name        = "RtmSpiMax",
            description = "RTM Bias DAC SPI Interface",
             **kwargs):

        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        for i in range(0,1056,32):
            if i/32 <= 31:
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
                mode         = "RW",
            ))

            self.add(pr.RemoteVariable(
                name         = str1 + "DacDataRegCh[%d]" % (j),
                description  = "BiasDac_Reg1",
                offset       =  0x00 + (i+4),
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.Int,
                mode         = "RW",
            ))

            self.add(pr.RemoteVariable(
                name         = str1 + "DacCtrlRegCh[%d]" % (j),
                description  = "BiasDac_Reg2",
                offset       =  0x00 + (i+8),
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.UInt,
                mode         = "RW",
            ))

            self.add(pr.RemoteVariable(
                name         = str1 + "DacClrCRegCh[%d]" % (j),
                description  = "BiasDac_Reg3",
                offset       =  0x00 + (i+12),
                bitSize      =  20,
                bitOffset    =  0x00,
                base         = pr.UInt,
                mode         = "RW",
            ))

        # make waveform of DacNopRegChArray
        self.add(pr.LinkVariable(
            name         = "TesBiasDacNopRegChArray",
            hidden       = True,
            description  = "TesBiasDacNopRegCh",
            dependencies = [self.node(f'TesBiasDacNopRegCh[{i+1}]') for i in range(32)],
            linkedGet    = lambda dev, var, read: dev.getArray(dev, var, read),
            linkedSet    = lambda dev, var, value: dev.setArray( dev, var, value),
            typeStr      = "List[UInt20]",
        ))

        # make waveform of DacDataRegChArray
        self.add(pr.LinkVariable(
            name         = "TesBiasDacDataRegChArray",
            hidden       = True,
            description  = "TesBiasDacDataRegCh",
            dependencies = [self.node(f'TesBiasDacDataRegCh[{i+1}]') for i in range(32)],
            linkedGet    = lambda dev, var, read: dev.getArray(dev, var, read),
            linkedSet    = lambda dev, var, value: dev.setArray( dev, var, value),
            typeStr      = "List[Int20]",
        ))

        # make waveform of DacCtrlRegChArray
        self.add(pr.LinkVariable(
            name         = "TesBiasDacCtrlRegChArray",
            hidden       = True,
            description  = "TesBiasDacCtrlRegCh",
            dependencies = [self.node(f'TesBiasDacCtrlRegCh[{i+1}]') for i in range(32)],
            linkedGet    = lambda dev, var, read: dev.getArray(dev, var, read),
            linkedSet    = lambda dev, var, value: dev.setArray( dev, var, value),
            typeStr      = "List[UInt20]",
        ))

        # make waveform of DacClrCRegChArray
        self.add(pr.LinkVariable(
            name         = "TesBiasDacClrCRegChArray",
            hidden       = True,
            description  = "TesBiasDacClrCRegCh",
            dependencies = [self.node(f'TesBiasDacClrCRegCh[{i+1}]') for i in range(32)],
            linkedGet    = lambda dev, var, read: dev.getArray(dev, var, read),
            linkedSet    = lambda dev, var, value: dev.setArray( dev, var, value),
            typeStr      = "List[UInt20]",
        ))

        @self.command(description="Set all DACs to 0")
        def initializeAllDac():
            enable = [2 for _ in range(32)]
            val    = [0 for _ in range(32)]
            self.TesBiasDacCtrlRegChArray.set(enable, write=True)
            self.TesBiasDacDataRegChArray.set(val, write=True)

    @staticmethod
    def setArray(dev, var, value):
        # workaround for rogue local variables
        # list objects get written as string, not list of float when set by GUI
        if isinstance(value, str):
            value = eval(value)
        for variable, setpoint in zip( var.dependencies, value ):
            variable.set( setpoint, write=False )
        dev.writeBlocks()
        dev.verifyBlocks()
        dev.checkBlocks()

    @staticmethod
    def getArray(dev, var, read):
        if read:
            dev.readBlocks(variable=var.dependencies)
            dev.checkBlocks(variable=var.dependencies)
        return [variable.value() for variable in var.dependencies]
