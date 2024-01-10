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

class RtmDigitalDebugV2b(pr.Device):
    def __init__(   self,
            name        = "RtmDigitalDebugV2b",
            description = "",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.RemoteVariable(
            name         = "DisableOutput",
            description  = "8-bit Output Disable Mask",
            offset       =  0x0,
            bitSize      =  8,
            bitOffset    =  0,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "DebugOutputMode",
            description  = "8-bit Output Debug Mode Mask",
            offset       =  0x0,
            bitSize      =  8,
            bitOffset    =  8,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "DebugOutputValue",
            description  = "8-bit Output Debug Value Mask (sets output in debug mode)",
            offset       =  0x0,
            bitSize      =  8,
            bitOffset    =  16,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "DinMonitor",
            description  = "8-bit Digital Input Monitor",
            offset       =  0x4,
            bitSize      =  8,
            bitOffset    =  0,
            mode         = "RO",
            pollInterval = 1
        ))

        self.add(pr.RemoteVariable(
            name         = "DoutMonitor",
            description  = "8-bit Digital Output Monitor",
            offset       =  0x4,
            bitSize      =  8,
            bitOffset    =  8,
            mode         = "RO",
            pollInterval = 1
        ))

        self.add(pr.RemoteVariable(
            name         = "PllFpgaLocked",
            description  = "PLL FPGA Lock status",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    =  16,
            mode         = "RO",
            pollInterval = 1
        ))

        self.add(pr.RemoteVariable(
            name         = "PllRtmLocked",
            description  = "PLL RTM Lock status",
            offset       =  0x4,
            bitSize      =  1,
            bitOffset    =  24,
            mode         = "RO",
            pollInterval = 1
        ))

        self.add(pr.RemoteVariable(
            name         = "CleanClkFreq",
            description  = "RTM Clean Clock Frequency",
            offset       =  0x8,
            bitSize      =  32,
            bitOffset    =  0,
            mode         = "RO",
            disp         = '{:d}',
            units        = 'Hz',
            pollInterval = 1
        ))
