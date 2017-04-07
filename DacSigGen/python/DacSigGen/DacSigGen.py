#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Signal generator module
#-----------------------------------------------------------------------------
# File       : DacSigGen.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Signal generator module
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

from DacSigGen.Waveform import *

class DacSigGen(pr.Device):
    def __init__(self, name="DacSigGen", description="Signal generator module", memBase=None, offset=0x0, hidden=False, numOfChs=2, buffSize=0x200):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden)

        ##############################
        # Variables
        ##############################

        self.add(pr.Variable(   name         = "EnableMask",
                                description  = "Mask Enable channels.",
                                offset       =  0x00,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "ModeMask",
                                description  = "Mask select Mode: 0 - Triggered Mode. 1 - Periodic Mode",
                                offset       =  0x04,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "SignFormat",
                                description  = "Mask select Sign: 0 - Signed 2's complement, 1 - Offset binary (Currently Applies only to zero data)",
                                offset       =  0x08,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "SoftwareTrigger",
                                description  = "Mask Software trigger (applies in triggered mode, Internal edge detector)",
                                offset       =  0x0C,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "Running",
                                description  = "Mask Running status",
                                offset       =  0x20,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "Underflow",
                                description  = "Mask Underflow status: 16bit to 32bit conversion underflow (applies in 32bit interface).",
                                offset       =  0x24,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "Overflow",
                                description  = "Mask Overflow status: 16bit to 32bit conversion underflow (applies in 32bit interface).",
                                offset       =  0x28,
                                bitSize      =  2,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MaxWaveformSize",
                                description  = "Max Waveform size (2**ADDR_WIDTH_G)",
                                offset       =  0x2C,
                                bitSize      =  32,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))
        for i in range(2):
            self.add(pr.Variable(   name         = "PeriodSize_%i" % (i),
                                    description  = "In Periodic mode: Period size (Zero inclusive). In Triggered mode: Waveform size (Zero inclusive). Separate values for separate channels. Channle %i" % (i),
                                    offset       =  0x40 + (i * 0x04),
                                    bitSize      =  32,
                                    bitOffset    =  0x00,
                                    base         = "hex",
                                    mode         = "RW",
                                ))


        digits = len(str(abs(numOfChs-1))) 
        for i in range(numOfChs):
            self.add(Waveform(
                                    name         = "Waveform_%.*i" % (digits, i),
                                    description  = "Waveform data 16-bit samples.",
                                    offset       =  0x01000000 + (i * 0x01000000),
                                    bitSize      =  16,
                                    mode         = "RW",
                                    buffSize     =  buffSize,
                                ))

        ##############################
        # Commands
        ##############################

        self.add(pr.Command (   name         = "SwTrigger",
                                description  = "Trigger waveform from software (All channels. Triggerd mode).",
                                function     = """\
                                               self.SoftwareTrigger.set(0x7F)
                                               self.SoftwareTrigger.set(0x00)
                                               """
                            ))

