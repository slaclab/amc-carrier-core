#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcMrLlrfDownConvert
#-----------------------------------------------------------------------------
# File       : AmcMrLlrfDownConvert.py
# Created    : 2019-07-16
#-----------------------------------------------------------------------------
# Description:
# PyRogue MR LLRF downconverter
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

class Ad5541(pr.Device):
    def __init__(self,
            name        = "Ad5541",
            description = "Ad5541",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name        = 'SetValue',
            description = '16 bit DAC output value (offset binary)',
            offset      = 0x000,
            bitSize     = 16,
            bitOffset   = 0,
            base        = pr.UInt,
            mode        = 'RW',
        ))

class Ad5541Mux(pr.Device):
    def __init__(self,
            name        = "Ad5541Mux",
            description = "Ad5541Mux",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name        = 'SelectDspCore',
            description = 'true = DSP core, false = AXI-Lite debug interface',
            offset      = 0x0,
            bitSize     = 1,
            bitOffset   = 0,
            base        = pr.UInt,
            mode        = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name        = 'SckHalfPeriod',
            description = 'Set the half period of the serial clock, in units of JESD clock cycles',
            offset      = 0x4,
            bitSize     = 16,
            bitOffset   = 0,
            base        = pr.UInt,
            mode        = 'RW',
        ))

class AmcMrLlrfDownConvert(pr.Device):
    def __init__(   self,
            name        = "AmcMrLlrfDownConvert",
            description = "AmcMrLlrfDownConvert Board",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #########
        # Devices
        #########
        for i in range(6):
            self.add(ad.AttHmc624(         offset=0x00000000+0x10*i,name=f'AttHmc624[{i}]', expand=False))
        for i in range(3):
            self.add(Ad5541(               offset=0x00000060+0x10*i,name=f'DacAD5541[{i}]', expand=False))
        self.add(Ad5541Mux(         offset=0x00000090,name='DacAD5541Mux', expand=False))
        for i in range(4):
            self.add(ad.Adt7420(         offset=0x10000+0x400*i,name=f'Adt7420[{i}]', expand=False))
        for i in range(3):
            self.add(ti.Adc16Dx370(     offset=0x00020000 + 0x20000*i,name=f'ADC[{i}]', expand=False))
        self.add(ti.Lmk04828(          offset=0x00080000,name='LMK',    expand=False))

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
