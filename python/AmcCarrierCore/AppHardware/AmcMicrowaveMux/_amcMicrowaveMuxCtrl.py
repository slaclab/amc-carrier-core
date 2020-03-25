#-----------------------------------------------------------------------------
# Title      : PyRogue AmcMicrowaveMux Amc Core
#-----------------------------------------------------------------------------
# File       : _amcMicrowaveMuxCtrl.py
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

import pyrogue as pr
import time

class AmcMicrowaveMuxCtrl(pr.Device):
    def __init__(   self,
            name        = "AmcMicrowaveMuxCtrl",
            description = "Debugging module",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = "txSyncRaw",
            description  = "txSyncRaw",
            offset       =  0x7F0,
            bitSize      =  2,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "txSync",
            description  = "txSync",
            offset       =  0x7F4,
            bitSize      =  2,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "rxSync",
            description  = "rxSync",
            offset       =  0x7F8,
            bitSize      =  1,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "txSyncMask",
            description  = "txSyncMask",
            offset       =  0x800,
            bitSize      =  2,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "dacReset[0]",
            description  = "dac(0) reset",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  2,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "dacReset[1]",
            description  = "dac(1) reset",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  3,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "dacJtagReset",
            description  = "dac JTAG reset",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  4,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "lmkSync",
            description  = "lmk SYNC request",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  5,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "dacSpiMode",
            description  = "0 for original 3-wire SPI configuration, 1 for new 4-wire configuration",
            offset       =  0x800,
            bitSize      =  1,
            bitOffset    =  6,
            base         = pr.UInt,
            mode         = "RW",
        ))

        @self.command(name= "Init", description  = "Initialize ADC/DAC")
        def Init():
            # Reset DAC, active low
            self.dacReset[0].set(1)
            self.dacReset[1].set(1)
            time.sleep(0.1) # TODO: Optimize this timeout
            self.dacReset[0].set(0)
            self.dacReset[1].set(0)
            time.sleep(0.001) # TODO: Optimize this timeout
            self.lmkSync.set(0)
            time.sleep(0.001) # TODO: Optimize this timeout
