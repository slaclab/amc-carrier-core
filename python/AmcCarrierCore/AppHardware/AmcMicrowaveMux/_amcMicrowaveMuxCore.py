#-----------------------------------------------------------------------------
# Title      : PyRogue AmcMicrowaveMux Amc Core
#-----------------------------------------------------------------------------
# File       : AmcMicrowaveMuxCore.py
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
import pyrogue         as pr
import surf.devices.ti as ti
import AmcCarrierCore.AppHardware     as appHw
import rogue

class AmcMicrowaveMuxCore(pr.Device):
    def __init__(   self,
            name        = "AmcMicrowaveMuxCore",
            description = "AmcMicrowaveMux Board",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        #########
        # Devices
        #########
        self.add(appHw.AmcMicrowaveMux.AmcMicrowaveMuxCtrl(offset=0x00000000,name='DBG',    expand=False))
        self.add(appHw.AmcMicrowaveMux.Adf5355(           offset=0x00001000,name='PLL[0]', expand=False))
        self.add(appHw.AmcMicrowaveMux.Adf5355(           offset=0x00002000,name='PLL[1]', expand=False))
        self.add(appHw.AmcMicrowaveMux.Adf5355(           offset=0x00003000,name='PLL[2]', expand=False))
        self.add(appHw.AmcMicrowaveMux.Adf5355(           offset=0x00004000,name='PLL[3]', expand=False))
        self.add(appHw.AmcMicrowaveMux.Hmc305(            offset=0x00005000,name='ATT',    expand=False))
        self.add(ti.Lmk04828(          offset=0x00020000,name='LMK',    expand=False))
        self.add(ti.Dac38J84(          offset=0x00040000,name='DAC[0]',numTxLanes=4, expand=False))
        self.add(ti.Dac38J84(          offset=0x00060000,name='DAC[1]',numTxLanes=4, expand=False))
        self.add(ti.Adc32Rf45(         offset=0x00100000,name='ADC[0]', verify=True, expand=False))
        self.add(ti.Adc32Rf45(         offset=0x00180000,name='ADC[1]', verify=True, expand=False))

        ##########
        # Commands
        ##########
        @self.command(description="Initialization for AMC card's JESD modules",)
        def InitAmcCard():
            for i in range(2):
                self.ADC[i].Init()
                self.DAC[i].Init()
                self.DAC[i].NcoSync()

        @self.command(description="Select internal LMK reference",)
        def SelExtRef():
            self.LMK.LmkReg_0x0147.set(0x1A)

        @self.command(description="Select external LMK reference",)
        def SelTimingRef():
            self.LMK.LmkReg_0x0147.set(0xA)

        @self.command(description="Enable Front Panel LMK reference",)
        def CmdEnLmkRef():
            self.LMK.LmkReg_0x011F.set(0x7)

        @self.command(description="Disable Front Panel LMK reference",)
        def CmdDisLmkRef():
            self.LMK.LmkReg_0x011F.set(0x0)

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

        for i in range(2):
            self.ADC[i].HW_RST.set(0x1)
            self.DBG.dacReset[i].set(0x1)

        self.LMK.RESET.set(0x1)
        self.LMK.RESET.set(0x0)

        self.LMK.writeBlocks(force=force, recurse=recurse, variable=variable)
        self._root.checkBlocks(recurse=True)
        time.sleep(5.000)

        self.LMK.Init()
        for i in range(2):
            self.ADC[i].HW_RST.set(0x0)
            self.DBG.dacReset[i].set(0x0)
        time.sleep(1.000)

        for i in range(4):
            self.PLL[i].writeBlocks(force=force, recurse=recurse, variable=variable)
            self._root.checkBlocks(recurse=True)
            self.PLL[i].RegInitSeq()

        for i in range(2):
            self.DAC[i].writeBlocks(force=force, recurse=recurse, variable=variable)
            self._root.checkBlocks(recurse=True)
            self.DAC[i].Init()
            self.DAC[i].NcoSync()

        for i in range(2):
            self.ADC[i].Powerup_AnalogConfig()
            self.ADC[i].writeBlocks(force=force, recurse=recurse, variable=variable)
            self._root.checkBlocks(recurse=True)
            self.ADC[i].Init()

        self.readBlocks(recurse=True)
        self.checkBlocks(recurse=True)
