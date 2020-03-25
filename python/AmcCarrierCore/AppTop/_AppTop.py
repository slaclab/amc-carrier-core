#-----------------------------------------------------------------------------
# Title      : PyRogue Common Application Top Level
#-----------------------------------------------------------------------------
# File       : AppTop.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue Common Application Top Level
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
import pyrogue   as pr
from AmcCarrierCore.AppTop._AppCore    import AppCore
from AmcCarrierCore.AppTop._AppTopJesd import AppTopJesd
import AmcCarrierCore.DacSigGen as dacSigGen
import AmcCarrierCore.DaqMuxV2  as daqMuxV2

import surf.devices.ti         as ti
import surf.protocols.jesd204b as jesd

class AppTop(pr.Device):
    def __init__(   self,
            name           = "AppTop",
            description    = "Common Application Top Level",
            numRxLanes     = [0,0],
            numTxLanes     = [0,0],
            enJesdDrp      = False,
            numSigGen      = [0,0],
            sizeSigGen     = [0,0],
            modeSigGen     = [False,False],
            numWaveformBuffers  = 4,
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self._numRxLanes = numRxLanes
        self._numTxLanes = numTxLanes
        self._numSigGen  = numSigGen
        self._sizeSigGen = sizeSigGen

        ##############################
        # Variables
        ##############################

        for i in range(2):
            self.add(daqMuxV2.DaqMuxV2(
                name       = f'DaqMuxV2[{i}]',
                offset     =  0x20000000 + (i * 0x10000000),
                numBuffers =  numWaveformBuffers,
                expand     =  False,
            ))

        for i in range(2):
            if ( (numRxLanes[i] > 0) or (numTxLanes[i] > 0) ):
                self.add(AppTopJesd(
                    name         = f'AppTopJesd[{i}]',
                    offset       =  0x40000000 + (i * 0x10000000),
                    numRxLanes   =  numRxLanes[i],
                    numTxLanes   =  numTxLanes[i],
                    enJesdDrp    =  enJesdDrp,
                    expand       =  False,
                ))

        for i in range(2):
            if ( (numSigGen[i] > 0) and (sizeSigGen[i] > 0) ):
                self.add(dacSigGen.DacSigGen(
                    name         = f'DacSigGen[{i}]',
                    offset       =  0x60000000 + (i * 0x10000000),
                    numOfChs     =  numSigGen[i],
                    buffSize     =  sizeSigGen[i],
                    fillMode     =  modeSigGen[i],
                    expand       =  False,
                ))

        @self.command(description  = "AppTop Init() cmd")
        def Init():
            # Get devices
            jesdRxDevices = self.find(typ=jesd.JesdRx)
            jesdTxDevices = self.find(typ=jesd.JesdTx)
            dacDevices    = self.find(typ=ti.Dac38J84)
            adcDevices    = self.find(typ=ti.Adc32Rf45)
            lmkDevices    = self.find(typ=ti.Lmk04828)
            appCore       = self.find(typ=AppCore)
            sigGenDevices = self.find(typ=dacSigGen.DacSigGen)

            # Assert GTs Reset
            for rx in jesdRxDevices:
                rx.ResetGTs.set(1)
            for tx in jesdTxDevices:
                rx.ResetGTs.set(1)
            self.checkBlocks(recurse=True)
            time.sleep(0.5) # TODO: Optimize this timeout

            # Execute the AppCore.Disable
            for core in appCore:
                core.Disable()

            # Deassert GTs Reset
            for rx in jesdRxDevices:
                rx.ResetGTs.set(0)
            for tx in jesdTxDevices:
                tx.ResetGTs.set(0)
            self.checkBlocks(recurse=True)
            time.sleep(0.5) # TODO: Optimize this timeout

            # Init the AppCore
            for core in appCore:
                core.Init()
            time.sleep(1.0) # TODO: Optimize this timeout

            # Special DAC Init procedure
            for dac in dacDevices:
                dac.EnableTx.set(0x0)
                time.sleep(0.001) # TODO: Optimize this timeout
                dac.InitJesd.set(0x1)
                time.sleep(0.001) # TODO: Optimize this timeout
                dac.JesdRstN.set(0x0)
                time.sleep(0.001) # TODO: Optimize this timeout
                dac.JesdRstN.set(0x1)
                time.sleep(0.001) # TODO: Optimize this timeout
                dac.InitJesd.set(0x0)
                time.sleep(0.001) # TODO: Optimize this timeout
                dac.EnableTx.set(0x1)
                time.sleep(0.001) # TODO: Optimize this timeout
            if len(dacDevices) > 0:
                for lmk in lmkDevices:
                    lmk.PwrUpSysRef()

            # Clear all error counters
            for rx in jesdRxDevices:
                rx.CmdClearErrors()
            for tx in jesdTxDevices:
                tx.CmdClearErrors()
            for dac in dacDevices:
                enable = dac.enable.get()
                dac.enable.set(True)
                dac.ClearAlarms()
                dac.enable.set(enable)

            for adc in adcDevices:
                adc.PDN_SYSREF.set(0x1)

            # Load the DAC signal generator
            for sigGen in sigGenDevices:
                if ( sigGen.CsvFilePath.get() != "" ):
                    sigGen.LoadCsvFile("")

    def writeBlocks(self, **kwargs):
        super().writeBlocks(**kwargs)

        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)

        # Perform the device init
        self.Init()

        self.checkBlocks(recurse=True)
