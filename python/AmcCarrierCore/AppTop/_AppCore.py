#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Common Application Core Level
#-----------------------------------------------------------------------------
# File       : AppCore.py
# Created    : 2019-10-08
#-----------------------------------------------------------------------------
# Description:
# PyRogue Common Application Core template
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

# A sub-class of this generic class should be added to 
# the AppTop class from the application python

#  self.TopLevel.AppTop.add(appCore(offset       =  0x00000000,     
#                                   numRxLanes   =  numRxLanes,     
#                                   numTxLanes   =  numTxLanes,     
#                                   expand       =  True))

class AppCore(pr.Device):
    def __init__(self,
            name        = "AppCore",
            description = "AMC Carrier Cryo Demo Board Application",
            offset      = 0x00000000,
            numRxLanes  = [0,0],
            numTxLanes  = [0,0],
            **kwargs):
        super().__init__(name=name, description=description, offset=offset, **kwargs)

        self._numRxLanes = numRxLanes
        self._numTxLanes = numTxLanes

        self.add(pr.LocalCommand(name='Init', description='Init', function=self.init))
        self.add(pr.LocalCommand(name='Disable', description='Disable', function=self.disable))

    def init(self):
        pass

    def disable(self):
        pass

