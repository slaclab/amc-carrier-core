#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Signal generator Waveform data samples buffer.
#-----------------------------------------------------------------------------
# File       : Waveform.py
# Created    : 2017-04-06
#-----------------------------------------------------------------------------
# Description:
# PyRogue Signal generator Waveform data samples buffer.
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

from surf._GenericMemory import *

class Waveform(pr.Device):
    def __init__(	self, 
    				name        = "Waveform", 
    				description = "Waveform data samples buffer.", 
    				memBase     =  None, 
    				offset      =  0x0, 
    				hidden      =  False, 
                    bitSize     =  32, 
                    bitOffset   =  0, 
                    base        = "hex", 
                    mode        = "RW",                                      
    				buffSize    =  0x200
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden)

        ##############################
        # Variables
        ##############################

        self.add(GenericMemory(
                                offset       =  0x00,
                                bitSize      =  bitSize,
                                bitOffset    =  bitOffset,
                                base         =  base,
                                mode         =  mode,
                                nelms        =  buffSize,
                            ))