#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcMrLlrfGen2UpConvert
#-----------------------------------------------------------------------------
# File       : _amcMrLlrfGen2UpConvert.py
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

import time
import pyrogue         as pr
import surf.devices.ti as ti
import surf.devices.analog_devices as ad

class AmcMrLlrfGen2UpConvert(pr.Device):
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
        self.add(ti.Dac38J84(          offset=0x000C0000,name='Dac38J84', numTxLanes=4, expand=False))

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

            # Init the DAC
            self.Dac38J84.EnableTx.set(0)
            self.Dac38J84.ClearAlarms()
            self.Dac38J84.DacReg[59].set(0x0000)
            self.Dac38J84.DacReg[37].set(0x0000)
            self.Dac38J84.DacReg[60].set(0x228)
            self.Dac38J84.DacReg[62].set(0x108)
            self.Dac38J84.DacReg[76].set(0x1F01)
            self.Dac38J84.DacReg[77].set(0x100)
            self.Dac38J84.DacReg[75].set(0x501)
            self.Dac38J84.DacReg[77].set(0x100)
            self.Dac38J84.DacReg[78].set(0xF2F)
            self.Dac38J84.DacReg[0].set(0x018)
            self.Dac38J84.DacReg[74].set(0x83E)
            self.Dac38J84.DacReg[74].set(0x83E)
            self.Dac38J84.DacReg[74].set(0x83F)
            self.Dac38J84.DacReg[74].set(0x821)
            self.Dac38J84.EnableTx.set(1)

            # DAC clear alarms
            self.Dac38J84.ClearAlarms()
