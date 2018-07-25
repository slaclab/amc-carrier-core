#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue CRYO RTM: SPI CRYO
#-----------------------------------------------------------------------------
# File       : _spiCryo.py
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

class SpiCryo(pr.Device):
    def __init__(   self, 
            name        = "SpiCryo", 
            description = "SpiCryo module", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self.add(pr.LocalVariable(
            name        = "data",
            description = "data - 20 bits",
            mode        = "RW",
            value       = 0,
            typeStr     = "Int20",
        ))

        self.add(pr.LocalVariable(
            name        = "addr",
            description = "address - 11 bits",
            mode        = "RW",
            value       = 0,
            typeStr     = "Int11",
        ))

        @self.command(description="read",)
        def read():
            addr = self.addr.get()
            self._rawWrite( (addr << 2), 0 )
            read = self._rawRead( (addr << 2) ) & 0x1FFF
            self.data.set( read )

        @self.command(description="write",)
        def write():
            address = self.addr.get()
            data    = self.data.get()
            self._rawWrite( (addr << 2), data )            
