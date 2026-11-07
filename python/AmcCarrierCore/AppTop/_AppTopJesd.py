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
import surf.xilinx.eyescan as es
import surf.protocols.jesd204b as jesd

class AppTopJesd(pr.Device):
    def __init__(   self,
            name        = "AppTopJesd",
            description = "Common Application Top Level JESD Module",
            numRxLanes  = 6,
            numTxLanes  = 2,
            enJesdDrp   = False,
            gtClass     = None,
            expand      = False,
            **kwargs):
        super().__init__(name=name, description=description, expand=expand, **kwargs)

        # GT channel register map of the DRP devices: Gthe3Channel on the
        # UltraScale carriers (KU040), Gthe4Channel on UltraScale+ (KU15P).
        # Both carry the eye scan child. The devices are named after the class.
        if gtClass is None:
            gtClass = xil.Gthe3Channel
        self._gtClass    = gtClass
        self._gtName     = gtClass.__name__
        self._numRxLanes = numRxLanes

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
                self.add(gtClass(
                    name   = f'{self._gtName}[{i}]',
                    offset =  0x03000000 + (i * 0x100000),
                    expand =  False,
                ))

            # Eye scan RX reset hook. The sampler of a GT only comes alive after
            # an RX reset and the only RX reset of the bay is JesdRx.ResetGTs,
            # which AppTopJesd204b drives into gtwiz_reset_all (every GT of the
            # bay, RX and TX). Lane i is ready again when its DataValid bit is
            # set. Because the reset is shared, scan one lane at a time
            # (--parallel false) and re-run the JESD bring-up afterwards.
            # Registration only stores the hook; it never touches the hardware.
            for i in range(numRxLanes):
                jesd.JesdRxEyeScanLink.connectRxReset(self.gtChannel(i), self.JesdRx, i)

    def gtChannel(self, lane):
        """Return the GT channel DRP device of a lane (Gthe3Channel[lane] or Gthe4Channel[lane])."""
        return self.node(f'{self._gtName}[{lane}]')

    def eyeScanLanes(self):
        """Return the EyeScanLane list of the RX lanes for surf.xilinx.eyescan.runEyeScan.

        Empty when the GT DRP devices are not instantiated (enJesdDrp False).
        """
        return [
            es.EyeScanLane(
                lane = i,
                gt   = self.gtChannel(i),
                link = jesd.JesdRxEyeScanLink(self.JesdRx, i),
            )
            for i in range(self._numRxLanes) if f'{self._gtName}[{i}]' in self.nodes
        ]
