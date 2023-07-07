#-----------------------------------------------------------------------------
# Title      : PyRogue BSA Diagnostic Buffer Module
#-----------------------------------------------------------------------------
# File       : BsaBufferControl.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue BSA Diagnostic Buffer Module
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue  as pr
import surf.axi as axi

class BsaBufferControl(pr.Device):
    def __init__(   self,
            name        = "BsaBufferControl",
            description = "Configuration and status of the BSA diagnostic buffers",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ##############################
        # Variables
        ##############################

        self.add(pr.RemoveVariable(
            name        = 'Timestamps',
            description = '',
            offset      = 0x00,
            bitSize     = 8*8*64, # Units of bits
            numValues   = 64,
            valueBits   = 64,
            valueStride = 64,
            verify      = False,
            mode        = "RO",
        ))

        self.add(axi.AxiStreamDmaRingWrite(
            offset     =  0x00001000,
            name       = "BsaBuffers",
            numBuffers =  1,
        ))
