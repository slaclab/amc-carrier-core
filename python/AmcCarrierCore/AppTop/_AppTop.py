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
            print(f'{self.path}.Init()')
            #############
            # Get devices
            #############
            jesdRxDevices = self.find(typ=jesd.JesdRx)
            jesdTxDevices = self.find(typ=jesd.JesdTx)
            dacDevices    = self.find(typ=ti.Dac38J84)
            sigGenDevices = self.find(typ=dacSigGen.DacSigGen)
            appCore       = self.find(typ=AppCore)

            rxEnables  = [rx.Enable.get()  for rx  in jesdRxDevices]
            txEnables  = [tx.Enable.get()  for tx  in jesdTxDevices]
            dacEnables = [dac.enable.get() for dac in dacDevices]

            retryCnt = 0
            retryCntMax = 8
            while( retryCnt < retryCntMax ):

                for rx in jesdRxDevices:
                    rx.Enable.set(0)
                for tx in jesdTxDevices:
                    tx.Enable.set(0)

                for core in appCore:
                    core.Init()

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

                for en, tx in zip(txEnables, jesdTxDevices):
                    tx.Enable.set(en)

                for en, rx in zip(rxEnables, jesdRxDevices):
                    rx.CmdClearErrors()
                    rx.Enable.set(en)

                time.sleep(2.000)

                for en, dac in zip(dacEnables,dacDevices):
                    dac.enable.set(True)
                    dac.Init()
                    dac.ClearAlarms()
                    dac.NcoSync()
                    dac.ClearAlarms()
                    dac.enable.set(en)

                for tx in jesdTxDevices:
                    tx.CmdClearErrors()

                time.sleep(2.000)

                ###########################
                # JESD Link Health Checking
                ###########################
                linkLock = True

                for en, dac in zip(dacEnables,dacDevices):
                    dac.enable.set(True)
                    for ch in dac.LinkErrCnt:
                        ######################################################################
                        if (dac.LinkErrCnt[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.LinkErrCnt[{ch}] = {dac.LinkErrCnt[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.ReadFifoEmpty[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.ReadFifoEmpty[{ch}] = {dac.ReadFifoEmpty[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.ReadFifoUnderflow[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.ReadFifoUnderflow[{ch}] = {dac.ReadFifoUnderflow[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.ReadFifoFull[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.ReadFifoFull[{ch}] = {dac.ReadFifoFull[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.ReadFifoOverflow[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.ReadFifoOverflow[{ch}] = {dac.ReadFifoOverflow[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.DispErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.DispErr[{ch}] = {dac.DispErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.NotitableErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.NotitableErr[{ch}] = {dac.NotitableErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.CodeSyncErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.CodeSyncErr[{ch}] = {dac.CodeSyncErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.FirstDataMatchErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.FirstDataMatchErr[{ch}] = {dac.FirstDataMatchErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.ElasticBuffOverflow[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.ElasticBuffOverflow[{ch}] = {dac.ElasticBuffOverflow[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.LinkConfigErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.LinkConfigErr[{ch}] = {dac.LinkConfigErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.FrameAlignErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.FrameAlignErr[{ch}] = {dac.FrameAlignErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                        if (dac.MultiFrameAlignErr[ch].get() != 0):
                            print(f'AppTop.Init(): {dac.path}.MultiFrameAlignErr[{ch}] = {dac.MultiFrameAlignErr[ch].value()}')
                            linkLock = False
                        ######################################################################
                    dac.enable.set(en)

                time.sleep(2.000)

                for tx in jesdTxDevices:
                    ######################################################################
                    if (tx.SysRefPeriodmin.get() != tx.SysRefPeriodmax.get()):
                        print(f'AppTop.Init().{tx.path}: Link Not Locked: SysRefPeriodmin = {tx.SysRefPeriodmin.value()}, SysRefPeriodmax = {tx.SysRefPeriodmax.value()}')
                        linkLock = False
                    ######################################################################
                    if( tx.DataValid.get() == 0 ):
                        print(f'AppTop.Init(): Link Not Locked: {tx.path}.DataValid = {tx.DataValid.value()} ')
                        linkLock = False
                    ######################################################################
                    for ch in tx.StatusValidCnt:
                        if (tx.StatusValidCnt[ch].get() > 0):
                            print(f'AppTop.Init(): {tx.path}.StatusValidCnt[{ch}] = {tx.StatusValidCnt[ch].value()}')
                            linkLock = False
                    ######################################################################
                    tx.CmdClearErrors()

                for rx in jesdRxDevices:
                    ######################################################################
                    if (rx.SysRefPeriodmin.get() != rx.SysRefPeriodmax.get()):
                        print(f'AppTop.Init().{rx.path}: Link Not Locked: SysRefPeriodmin = {rx.SysRefPeriodmin.value()}, SysRefPeriodmax = {rx.SysRefPeriodmax.value()}')
                        linkLock = False
                    ######################################################################
                    if (rx.DataValid.get() == 0) or (rx.PositionErr.get() != 0) or (rx.AlignErr.get() != 0):
                        print(f'AppTop.Init().{rx.path}: Link Not Locked: DataValid = {rx.DataValid.value()}, PositionErr = {rx.PositionErr.value()}, AlignErr = {rx.AlignErr.value()}')
                        linkLock = False
                    ######################################################################
                    for ch in rx.StatusValidCnt:
                        if (rx.StatusValidCnt[ch].get() > 4):
                            print(f'AppTop.Init(): {rx.path}.StatusValidCnt[{ch}] = {rx.StatusValidCnt[ch].value()}')
                            linkLock = False
                    ######################################################################
                    rx.CmdClearErrors()

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
        print(f'{self.path}.writeBlocks()')
        super().writeBlocks(**kwargs)

        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)

        # Perform the device init
        self.Init()

        self.checkBlocks(recurse=True)
