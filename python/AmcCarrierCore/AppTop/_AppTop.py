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

            retryCnt = 0
            retryCntMax = 8
            while( retryCnt < retryCntMax ):

                for rx in jesdRxDevices:
                    rx.ResetGTs.set(1)
                for tx in jesdTxDevices:
                    tx.ResetGTs.set(1)

                for adc in adcDevices:
                    adc.ASSERT_SYSREF_REG.set(0x0)
                    adc.SEL_SYSREF_REG.set(0x0)
                    adc.PDN_SYSREF.set(0x0)

                for lmk in lmkDevices:
                    lmk.PwrDwnLmkChip()
                    lmk.PwrDwnSysRef()

                for core in appCore:
                    core.Init()

                for lmk in lmkDevices:
                    lmk.PwrUpLmkChip()
                time.sleep(1.000) # TODO: Optimize this timeout

                for lmk in lmkDevices:
                    lmk.PwrUpSysRef()
                time.sleep(0.250) # TODO: Optimize this timeout

                for adc in adcDevices:
                    adc.PDN_SYSREF.set(0x1)
                    time.sleep(0.100) # TODO: Optimize this timeout
                for adc in adcDevices:
                    adc.PDN_SYSREF.set(0x0)
                    time.sleep(0.100) # TODO: Optimize this timeout
                for adc in adcDevices:
                    adc.PDN_SYSREF.set(0x1)
                    time.sleep(0.100) # TODO: Optimize this timeout

                for tx in jesdTxDevices:
                    tx.CmdClearErrors()
                    tx.ResetGTs.set(0)
                for rx in jesdRxDevices:
                    rxEnable = rx.Enable.get()
                    rx.Enable.set(0)
                    rx.ResetGTs.set(0)
                    time.sleep(0.100) # TODO: Optimize this timeout
                    rx.CmdClearErrors()
                    rx.Enable.set(rxEnable)

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
                    ##################################################################
                    # Release sequence above with "dac.NcoSync()" on next SURF release
                    ##################################################################
                    # dac.NcoSync()

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
                        time.sleep(0.100) # TODO: Optimize this timeout
                    else:
                        break

                for tx in jesdTxDevices:
                    if (tx.SysRefPeriodmin.get() != tx.SysRefPeriodmax.get()):
                        print(f'AppTop.Init().{tx.path}: Link Not Locked: SysRefPeriodmin = {tx.SysRefPeriodmin.value()}, SysRefPeriodmax = {tx.SysRefPeriodmax.value()}')
                        linkLock = False
                for rx in jesdRxDevices:
                    if (rx.SysRefPeriodmin.get() != rx.SysRefPeriodmax.get()):
                        print(f'AppTop.Init().{rx.path}: Link Not Locked: SysRefPeriodmin = {rx.SysRefPeriodmin.value()}, SysRefPeriodmax = {rx.SysRefPeriodmax.value()}')
                        linkLock = False

                if( linkLock ):
                    break
                else:
                    retryCnt += 1
                    if (retryCnt == retryCntMax):
                        raise pr.DeviceError('AppTop.Init(): Too many retries and giving up on retries')
                    else:
                        print(f'Re-executing AppTop.Init(): retryCnt = {retryCnt}')

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
