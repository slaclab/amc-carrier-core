#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue BSA Waveform Engine Module
#-----------------------------------------------------------------------------
# File       : BsaWaveformEngine.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue BSA Waveform Engine Module
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

class BsaWaveformEngine(pr.Device):
    def __init__(   self, 
            name        = "BsaWaveformEngine", 
            description = "Configuration and status of the BSA dignosic buffers", 
            numBuffers  = 4,
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(axi.AxiStreamDmaRingWrite(
            name       = "WaveformEngineBuffers",
            offset     = 0x00000000,
            numBuffers = numBuffers,
        ))
        