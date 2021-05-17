#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcMrLlrfUpConvert
#-----------------------------------------------------------------------------
# File       : _amcMrLlrfUpConvert.py
# Created    : 2019-07-16
#-----------------------------------------------------------------------------
# Description:
# PyRogue MR LLRF GEN2 upconverter
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

# import time
import pyrogue         as pr
import surf.devices.ti as ti
import surf.devices.analog_devices as ad

class DacLtc2000(pr.Device):
    def __init__(   self,
            name        = "DacLtc2000",
            description = "Ltc2000 Parallel DAC module",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        for i in range(1, 5):
            self.add(pr.RemoteVariable(
                name         = f'LvdsDacReg_0x000{i}',
                description  = "Ltc2000 registers",
                offset       =  0x0 + i*0x4,
                bitSize      =  8,
                bitOffset    =  0,
                base         = pr.UInt,
                mode         = "RW",
            ))

        for i in range(7, 10):
            self.add(pr.RemoteVariable(
                name         = f'LvdsDacReg_0x000{i}',
                description  = "Ltc2000 registers",
                offset       =  0x0 + i*0x4,
                bitSize      =  8,
                bitOffset    =  0,
                base         = pr.UInt,
                mode         = "RW",
            ))

        self.add(pr.RemoteVariable(
            name         = "LvdsDacReg_0x0018",
            description  = "Ltc2000 registers",
            offset       =  0x60,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "LvdsDacReg_0x0019",
            description  = "Ltc2000 registers",
            offset       =  0x64,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "LvdsDacReg_0x001E",
            description  = "Ltc2000 registers",
            offset       =  0x78,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "LvdsDacReg_0x001F",
            description  = "Ltc2000 registers",
            offset       =  0x7C,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        #STATUS  registers
        self.add(pr.RemoteVariable(
            name         = "AutoPhaseSelect",
            description  = "Ltc2000 registers",
            offset       =  0x14,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "PhaseComparator",
            description  = "Ltc2000 registers",
            offset       =  0x18,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))

class LvdsSigGen(pr.Device):
    def __init__(   self,
            name        = "LvdsSigGen",
            description = "LvdsSigGen Board",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = "Enable",
            description  = "Enable generation of waveform",
            offset       =  0x0,
            bitSize      =  1,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PolarityMask",
            description  = "Polarity of the corresponding LVDS output [15:0]",
            offset       =  0x4,
            bitSize      =  16,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PeriodSize",
            description  = "Size of generated period buffer",
            offset       =  0x8,
            bitSize      =  10,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "LoadTap",
            description  = "Load tap delay from registers",
            offset       =  0xC,
            bitSize      =  16,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        for i in range(16):
            self.add(pr.RemoteVariable(
                name         = f'LvdsTapSet[{i}]',
                description  = "Set 9-bit LVDS tap delay",
                offset       =  0x040 + 0x4*i,
                bitSize      =  9,
                bitOffset    =  0,
                base         = pr.UInt,
                mode         = "RW",
            ))

        for i in range(16):
            self.add(pr.RemoteVariable(
                name         = f'LvdsTapGet[{i}]',
                description  = "Set 9-bit LVDS tap delay",
                offset       =  0x080 + 0x4*i,
                bitSize      =  9,
                bitOffset    =  0,
                base         = pr.UInt,
                mode         = "RO",
            ))

class AmcMrLlrfUpConvert(pr.Device):
    def __init__(   self,
            name        = "AmcMrLlrfUpConvert",
            description = "AmcMrLlrfUpConvert Board",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #########
        # Devices
        #########
        for i in range(4):
            self.add(ad.AttHmc624(         offset=0x00000000+0x10*i,name=f'AttHmc624[{i}]', expand=False))
        for i in range(4):
            self.add(ad.Adt7420(          offset=0x10000 + 0x400*i,name=f'Adt7420[{i}]', expand=False))
        for i in range(3):
            self.add(ti.Adc16Dx370(     offset=0x00020000 + 0x20000*i,name=f'ADC[{i}]', expand=False))
        self.add(ti.Lmk04828(          offset=0x00080000,name='LMK',    expand=False))

        self.add(DacLtc2000(           offset=0x000A0000,name='DacLtc2000',    expand=False))

        self.add(LvdsSigGen(           offset=0x000C0000,name='LvdsSigGen',    expand=False))

        @self.command(description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
            # calibrate the JESD ADCs
            self.ADC[0].AdcReg_0x0002.set(0x3)
            self.ADC[1].AdcReg_0x0002.set(0x3)
            self.ADC[2].AdcReg_0x0002.set(0x3)

            self.ADC[0].AdcReg_0x0002.set(0x0)
            self.ADC[1].AdcReg_0x0002.set(0x0)
            self.ADC[2].AdcReg_0x0002.set(0x0)

            # Power up continuous SYSREF
            self.LMK.EnableSysRef.set(0x3)

            # Init LMK
            self.LMK.EnableSysRef.set(0x0)
            self.LMK.EnableSync.set(0x0)

            self.LMK.SyncBit.set(0x1)
            self.LMK.SyncBit.set(0x0)

            self.LMK.EnableSysRef.set(0x3)
            self.LMK.EnableSync.set(0xFF)
