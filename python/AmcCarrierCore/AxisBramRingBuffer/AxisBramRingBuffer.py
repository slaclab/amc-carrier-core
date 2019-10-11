#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Waveform Data Acquisition Module
#-----------------------------------------------------------------------------
# File       : AxisBramRingBuffer.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Waveform Data Acquisition Module
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

class AxisBramRingBuffer(pr.Device):
    def __init__(   self,       
            name        = "AxisBramRingBuffer",
            description = "Waveform Data Acquisition Module",
            numAppCh    = 1,
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ####################
        # Variables/Commands
        ####################

        self.addRemoteVariables(  
            name         = "Tdest",
            description  = "AXI stream TDEST",
            offset       = 0x0,
            bitSize      = 8,
            bitOffset    = 0,
            base         = pr.UInt,
            mode         = "RW",
            number       = numAppCh,
            stride       = 4,                        
        )        
        
        self.add(pr.RemoteCommand(   
            name         = 'CmdSwTrig',
            description  = 'Command for Software Trigger',
            offset       = 0xF8,
            bitSize      = 1,
            bitOffset    = 0,
            base         = pr.UInt,
            function     = lambda cmd: cmd.post(1),
            hidden       = False,
        ))
        
        self.add(pr.RemoteVariable(   
            name         = 'Enable',
            description  = 'Enable for triggers',
            offset       = 0xFC,
            bitSize      = 1,
            bitOffset    = 0,
            base         = pr.UInt,
            mode         = 'RW',
        ))
        