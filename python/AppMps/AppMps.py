#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue MPS Application Module
#-----------------------------------------------------------------------------
# File       : AppMps.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue MPS Application Module
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

from AppMps.AppMpsSalt import *

class AppMps(pr.Device):
    def __init__(   self, 
                    name        = "AppMps", 
                    description = "MPS Application", 
                    memBase     =  None, 
                    offset      =  0x0, 
                    hidden      =  False,
                    expand      =  True,
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden, expand=expand)

        ##############################
        # Variables
        ##############################

        self.add(AppMpsSalt(
                                offset       =  0x00000000,
                            ))