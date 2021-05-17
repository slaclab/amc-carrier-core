#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : AmcGenericAdcDacCore.py
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

import time
import pyrogue                    as pr
import surf.devices.ti            as ti
import AmcCarrierCore.AppHardware as appHw
import rogue

class AmcGenericAdcDacCore(pr.Device):
    def __init__(   self,
            name        = "AmcGenericAdcDacCore",
            description = "Generic ADC/DAC Board",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #########
        # Devices
        #########
        self.add(appHw.AmcGenericAdcDac.AmcGenericAdcDacCtrl(offset=0x00000000, name='DBG',    expand=False))
        self.add(ti.Dac38J84(  offset=0x00002000, name='DAC',    expand=False, numTxLanes=2))
        self.add(ti.Lmk04828(  offset=0x00020000, name='LMK',    expand=False))
        self.add(ti.Adc16Dx370(offset=0x00040000, name='ADC[0]', expand=False))
        self.add(ti.Adc16Dx370(offset=0x00060000, name='ADC[1]', expand=False))

        @self.command(description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
            self.LMK.Init()
            time.sleep(1.000)
            for i in range(2):
                self.ADC[i].CalibrateAdc()
            self.DAC.Init()

    def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
        print(f'{self.path}.writeBlocks()')
        """
        Write all of the blocks held by this Device to memory
        """
        if not self.enable.get():
            return

        # Process local blocks.
        if variable is not None:
            variable._block.backgroundTransaction(rogue.interfaces.memory.Write)
        else:
            for block in self._blocks:
                if force or block.stale:
                    if block.bulkEn:
                        block.backgroundTransaction(rogue.interfaces.memory.Write)

        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)

        self.DBG.writeBlocks(force=force, recurse=recurse, variable=variable)
        self._root.checkBlocks(recurse=True)

        self.LMK.RESET.set(0x1)
        self.LMK.RESET.set(0x0)

        self.LMK.writeBlocks(force=force, recurse=recurse, variable=variable)
        self._root.checkBlocks(recurse=True)
        time.sleep(0.100)
        self.LMK.Init()
        time.sleep(0.100)

        for x in range(2):
            self.DAC.DacReg[2].set(0x2080) # Setup the SPI configuration
            self.DAC.writeBlocks(force=force, recurse=recurse, variable=variable)
            self._root.checkBlocks(recurse=True)
        self.DAC.Init()

        for i in range(2):
            self.ADC[i].writeBlocks(force=force, recurse=recurse, variable=variable)
            self._root.checkBlocks(recurse=True)
            self.ADC[i].CalibrateAdc()

        self.readBlocks(recurse=True)
        self.checkBlocks(recurse=True)
