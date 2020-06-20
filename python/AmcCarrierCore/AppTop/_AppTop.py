#-----------------------------------------------------------------------------
# Title      : PyRogue Common Application Top Level
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

            rxEnables = [rx.Enable.get() for rx in jesdRxDevices]
            txEnables = [tx.Enable.get() for tx in jesdTxDevices]

            retryCnt = 0
            retryCntMax = 8
            while( retryCnt < retryCntMax ):

                for rx in jesdRxDevices:
                    rx.Enable.set(0)
                for tx in jesdTxDevices:
                    tx.Enable.set(0)

                for rx in jesdRxDevices:
                    rx.ResetGTs.set(1) # tx.ResetGTs/rx.ResetGTs OR'd together in FW
                for tx in jesdTxDevices:
                    tx.ResetGTs.set(1) # tx.ResetGTs/rx.ResetGTs OR'd together in FW

                time.sleep(1.000)

                for tx in jesdTxDevices:
                    tx.ResetGTs.set(0) # tx.ResetGTs/rx.ResetGTs OR'd together in FW
                for rx in jesdRxDevices:
                    rx.ResetGTs.set(0) # tx.ResetGTs/rx.ResetGTs OR'd together in FW

                time.sleep(1.000)

                for i in range(10):

                    for tx in jesdTxDevices:
                        tx.Enable.set(0)

                    for dac in dacDevices:
                        dac.Init()
                        dac.NcoSync()
                        dac.ClearAlarms()

                    for en, tx in zip(txEnables, jesdTxDevices):
                        tx.CmdClearErrors()
                        tx.Enable.set(en)

                    time.sleep(0.250)

                    linkLock = True
                    for tx in jesdTxDevices:
                        if( tx.DataValid.get() == 0 ):
                            linkLock = False
                    if( linkLock ):
                        break

                for en, rx in zip(rxEnables, jesdRxDevices):
                    rx.CmdClearErrors()
                    rx.Enable.set(en)

                time.sleep(2.000)

                # Check the link locks
                linkLock = True
                for i in range(10):

                    for rx in jesdRxDevices:
                        if (rx.DataValid.get() == 0) or (rx.PositionErr.get() != 0) or (rx.AlignErr.get() != 0):
                            print(f'AppTop.Init().{rx.path}: Link Not Locked: DataValid = {rx.DataValid.value()}, PositionErr = {rx.PositionErr.value()}, AlignErr = {rx.AlignErr.value()}')
                            linkLock = False

                    for tx in jesdTxDevices:
                        if( tx.DataValid.get() == 0 ):
                            print(f'AppTop.Init(): Link Not Locked: {tx.path}.DataValid = {tx.DataValid.value()} ')
                            linkLock = False

                    if( linkLock ):
                        time.sleep(0.100)
                    else:
                        break

                if( linkLock ):
                    break
                else:
                    retryCnt += 1
                    if (retryCnt == retryCntMax):
                        raise pr.DeviceError('AppTop.Init(): Too many retries and giving up on retries')
                    else:
                        print(f'Re-executing AppTop.Init(): retryCnt = {retryCnt}')

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
