#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcCarrier BSI Module
#-----------------------------------------------------------------------------
# File       : AmcCarrierBsi.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue AmcCarrier BSI Module
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

class AmcCarrierBsi(pr.Device):
    def __init__(self, name="AmcCarrierBsi", description="AmcCarrier BSI Module", memBase=None, offset=0x0, hidden=False):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden)

        ##############################
        # Variables
        ##############################

        for i in range(4):
            self.add(pr.Variable(   name         = "MAC_%i" % (i),
                                    description  = "MAC Address[3:0]",
                                    offset       =  0x00 + (i * 0x08),
                                    bitSize      =  48,
                                    bitOffset    =  0x00,
                                    base         = "hex",
                                    mode         = "RO",
                                ))

        self.add(pr.Variable(   name         = "CrateId",
                                description  = "ATCA Crate ID",
                                offset       =  0x80,
                                bitSize      =  16,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "SlotNumber",
                                description  = "ATCA Logical Slot Number",
                                offset       =  0x84,
                                bitSize      =  4,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "BootStartAddress",
                                description  = "Bootloader Start Address",
                                offset       =  0x88,
                                bitSize      =  32,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "VersionMinor",
                                description  = "BSI's Minor Version Number",
                                offset       =  0x8C,
                                bitSize      =  8,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "VersionMajor",
                                description  = "BSI's Major Version Number",
                                offset       =  0x90,
                                bitSize      =  8,
                                bitOffset    =  0x08,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "EthUpTime",
                                description  = "ETH Uptime (units of sec)",
                                offset       =  0x94,
                                bitSize      =  32,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))
