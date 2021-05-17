#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : AmcCryoCore.py
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

import pyrogue         as pr
import surf.devices.ti as ti
import AmcCarrierCore.AppHardware     as appHw
import rogue

class AmcCryoCore(pr.Device):
    def __init__(   self,
            name        = "AmcCryoCore",
            description = "Cryo Amc Rf Demo Board Core",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #########
        # Devices
        #########
        self.add(appHw.AmcCryo.AmcCryoCtrl( offset=0x00000000,name='DBG',   expand=False))
        self.add(ti.Lmk04828( offset=0x00020000,name='LMK',   expand=False))
        self.add(ti.Dac38J84( offset=0x00040000,name='DAC[0]',numTxLanes=4, expand=False))
        self.add(ti.Dac38J84( offset=0x00060000,name='DAC[1]',numTxLanes=4, expand=False))
        self.add(ti.Adc32Rf45(offset=0x00080000,name='ADC[0]', expand=False))
        self.add(ti.Adc32Rf45(offset=0x000C0000,name='ADC[1]', expand=False))

        ##########
        # Commands
        ##########
        @self.command(description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
            self.checkBlocks(recurse=True)
            self.LMK.Init()
            self.DAC[0].Init()
            self.DAC[1].Init()
            self.ADC[0].Init()
            self.ADC[1].Init()
            self.checkBlocks(recurse=True)

        @self.command(description="Enable Front Panel LMK reference",)
        def CmdEnLmkRef():
            self.LMK.LmkReg_0x011F.set(0x7)

        @self.command(description="Disable Front Panel LMK reference",)
        def CmdDisLmkRef():
            self.LMK.LmkReg_0x011F.set(0x0)

    def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
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

        # Note: Requires that AmcCryoCore: enable: 'True' in defaults.yml file
        self.enable.set(True)
        self.DBG.enable.set(True)
        self.LMK.enable.set(True)
        self.DAC[0].enable.set(True)
        self.DAC[1].enable.set(True)
        self.ADC[0].enable.set(True)
        self.ADC[1].enable.set(True)

        self.DBG.writeBlocks(force=force, recurse=recurse, variable=variable)
        self.LMK.writeBlocks(force=force, recurse=recurse, variable=variable)
        self.DAC[0].writeBlocks(force=force, recurse=recurse, variable=variable)
        self.DAC[1].writeBlocks(force=force, recurse=recurse, variable=variable)

        self.InitAmcCard()

        self.ADC[0].writeBlocks(force=force, recurse=recurse, variable=variable)
        self.ADC[1].writeBlocks(force=force, recurse=recurse, variable=variable)

        self._root.checkBlocks(recurse=True)
        self.ADC[0].DigRst()
        self.ADC[1].DigRst()

        # Stop SPI transactions after configuration to minimize digital crosstalk to ADC/DAC
        self.DAC[0].enable.set(False)
        self.DAC[1].enable.set(False)
        self.ADC[0].enable.set(False)
        self.ADC[1].enable.set(False)

        self.readBlocks(recurse=True)
        self.checkBlocks(recurse=True)
