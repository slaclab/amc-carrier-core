#-----------------------------------------------------------------------------
# Title      : PyRogue Common Application Top Level JESD Module
#-----------------------------------------------------------------------------
# File       : AppTopJesd.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Common Application Top Level JESD Module
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

import surf.xilinx as xil
import surf.protocols.jesd204b as jesd

class AppTopJesd(pr.Device):
    def __init__(   self,
            name        = "AppTopJesd",
            description = "Common Application Top Level JESD Module",
            numRxLanes  = 6,
            numTxLanes  = 2,
            enJesdDrp   = False,
            expand      = False,
            **kwargs):
        super().__init__(name=name, description=description, expand=expand, **kwargs)

        ##############################
        # Variables
        ##############################
        if (numRxLanes > 0):
            self.add(jesd.JesdRx(
                offset       = 0x00000000,
                numRxLanes   = numRxLanes,
                expand       = expand,
            ))

        if (numTxLanes > 0):
            self.add(jesd.JesdTx(
                offset       = 0x01000000,
                numTxLanes   = numTxLanes,
                expand       = expand,
            ))

        # Find max number of lanes
        maxlanes = numRxLanes
        if (numTxLanes>maxlanes):
            maxlanes = numTxLanes

        # Check if DRP enabled and non-zero lane count
        if ((maxlanes > 0) and enJesdDrp):
            for i in range(maxlanes):
                self.add(xil.Gthe3Channel(
                    name   = f'Gthe3Channel[{i}]',
                    offset =  0x03000000 + (i * 0x100000),
                    expand =  False,
                ))
