#-----------------------------------------------------------------------------
# This file is part of the 'LCLS2 Common Carrier Core'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'LCLS2 Common Carrier Core', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

class Si5317a(pr.Device):
    def __init__(   self,**kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name         = "ScratchPad",
            offset       = 0x00,
            bitSize      = 32,
            bitOffset    = 0,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllInc",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 1,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllDec",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 2,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "Los",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 3,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "Lol",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 4,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "Locked",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 5,
            mode         = "RO",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllBypass",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 8,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllBypassTri",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 9,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllFrqTbl",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 10,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllFrqTblTri",
            offset       = 0x04,
            bitSize      = 1,
            bitOffset    = 11,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllRate",
            offset       = 0x04,
            bitSize      = 2,
            bitOffset    = 12,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllRateTri",
            offset       = 0x04,
            bitSize      = 2,
            bitOffset    = 14,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllSFout",
            offset       = 0x04,
            bitSize      = 2,
            bitOffset    = 16,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllSFoutTri",
            offset       = 0x04,
            bitSize      = 2,
            bitOffset    = 18,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllBwSel",
            offset       = 0x04,
            bitSize      = 2,
            bitOffset    = 20,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllBwSelTri",
            offset       = 0x04,
            bitSize      = 2,
            bitOffset    = 22,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllFrqSel",
            offset       = 0x04,
            bitSize      = 4,
            bitOffset    = 24,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "PllFrqSelTri",
            offset       = 0x04,
            bitSize      = 4,
            bitOffset    = 28,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "CntLos",
            offset       = 0x80,
            bitSize      = 32,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "CntLol",
            offset       = 0x84,
            bitSize      = 32,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "CntLocked",
            offset       = 0x88,
            bitSize      = 32,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "CntPllRst",
            offset       = 0x8C,
            bitSize      = 32,
            mode         = "RO",
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = "PllRst",
            offset       = 0xF8,
            bitSize      = 1,
            mode         = "WO",
        ))

        self.add(pr.RemoteVariable(
            name         = "CntRst",
            offset       = 0xFC,
            bitSize      = 1,
            mode         = "WO",
        ))

    def countReset(self):
        self.CntRst.set(1)
