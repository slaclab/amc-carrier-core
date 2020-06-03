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
                    expand       =  True,
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

            retryCnt = 0
            retryCntMax = 8
            while( retryCnt < retryCntMax ):

                for adc in adcDevices:
                    adc.PDN_SYSREF.set(0x0)

                for lmk in lmkDevices:
                    lmk.PwrDwnLmkChip()
                    lmk.PwrDwnSysRef()

                # Assert GTs Reset
                for rx in jesdRxDevices:
                    rx.ResetGTs.set(1)
                for tx in jesdTxDevices:
                    rx.ResetGTs.set(1)

                # Execute the AppCore.Disable
                for core in appCore:
                    core.Disable()

                time.sleep(0.100) # TODO: Optimize this timeout

                # Deassert GTs Reset
                for rx in jesdRxDevices:
                    rx.ResetGTs.set(0)
                for tx in jesdTxDevices:
                    tx.ResetGTs.set(0)

                time.sleep(0.100) # TODO: Optimize this timeout

                # Init the AppCore
                for core in appCore:
                    core.Init()

                # Special DAC Init procedure
                for dac in dacDevices:
                    dac.EnableTx.set(0x0)
                    time.sleep(0.010) # TODO: Optimize this timeout
                    dac.InitJesd.set(0x1)
                    time.sleep(0.010) # TODO: Optimize this timeout
                    dac.JesdRstN.set(0x0)
                    time.sleep(0.010) # TODO: Optimize this timeout
                    dac.JesdRstN.set(0x1)
                    time.sleep(0.010) # TODO: Optimize this timeout
                    dac.InitJesd.set(0x0)
                    time.sleep(0.010) # TODO: Optimize this timeout
                    dac.EnableTx.set(0x1)
                    time.sleep(0.010) # TODO: Optimize this timeout

                for lmk in lmkDevices:
                    lmk.PwrUpLmkChip()
                time.sleep(1.000) # TODO: Optimize this timeout

                for lmk in lmkDevices:
                    lmk.PwrUpSysRef()
                time.sleep(0.100) # TODO: Optimize this timeout

                for adc in adcDevices:
                    adc.PDN_SYSREF.set(0x1)
                time.sleep(2.0) # TODO: Optimize this timeout

                # Check the link locks
                linkLock = True
                for i in range(10):

                    for rx in jesdRxDevices:
                        if( rx.DataValid.get() == 0 ):
                            print(f'Link Not Locked: {rx.path}.DataValid = {rx.DataValid.get()} ')
                            linkLock = False

                    for tx in jesdTxDevices:
                        if( tx.DataValid.get() == 0 ):
                            print(f'Link Not Locked: {tx.path}.DataValid = {tx.DataValid.get()} ')
                            linkLock = False

                    if( linkLock ):
                        time.sleep(0.100) # TODO: Optimize this timeout
                    else:
                        break

                if( linkLock ):
                    break
                else:
                    retryCnt += 1
                    if (retryCnt == retryCntMax):
                        print('AppTop.Init(): Too many retries and giving up on retries')
                    else:
                        print(f'Re-executing AppTop.Init(): retryCnt = {retryCnt}')

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
