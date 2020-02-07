#-----------------------------------------------------------------------------
# Title      : AmcCarrierCore Base Root Class
#-----------------------------------------------------------------------------
# File       : RootBase.py
# Created    : 2019-10-11
#-----------------------------------------------------------------------------
# Description:
# Base Root class for AmcCarrierCore based designs.
#-----------------------------------------------------------------------------
# This file is part of the AmcCarrier Core. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the AmcCarrierCore, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue

class RootBase(pyrogue.Root):
    def __init__(self, *, name='base', description = '', **kwargs):
        pyrogue.Root.__init__(self,
                         name         = name,
                         description  = description,
                         **kwargs
                        )

        self.srp    = None
        self.stream = None

        # Top level module should be added here.
        # Top level is a sub-class of AmcCarrierCore.AppTop.TopLevel
        # SRP interface should be passed as an arg
        # self.add(FpgaTopLevel(memBase=self.srp))


