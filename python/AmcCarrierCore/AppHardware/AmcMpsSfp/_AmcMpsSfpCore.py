#-----------------------------------------------------------------------------
# This file is part of the 'LCLS2 Common Carrier Core'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'LCLS2 Common Carrier Core', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr
import AmcCarrierCore.AppHardware.common as common
import AmcCarrierCore.AppHardware.AmcMpsSfp as amcMpsSfp
import surf.devices.transceivers as xceiver

class AmcMpsSfpCore(pr.Device):
    def __init__(self,EN_PLL_G=True,EN_HS_REPEATER_G=True,**kwargs):
        super().__init__(**kwargs)

        if EN_PLL_G:
            self.add(common.Si5317a(
                offset=0x0000_0000
            ))

        for i in range(8):
            self.add(xceiver.Sfp(
                name       = f'Sfp[{i}]',
                offset     = 0x0002_0000+i*0x0000_1000,
            ))

        self.add(amcMpsSfp.SfpSummary(
            description = 'PCA9506',
            offset      = 0x0003_0000
        ))

        if EN_HS_REPEATER_G:
            for i in range(3):
                self.add(amcMpsSfp.Ds125br401(
                    name       = f'HsRepeater[{i}]',
                    offset     = 0x0004_0000+i*0x0000_1000,
                ))
