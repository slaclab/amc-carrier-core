#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcCarrier MPS PHY Module
#-----------------------------------------------------------------------------
# File       : AppMpsSalt.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue AmcCarrier MPS PHY Module
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

class AppMpsSalt(pr.Device):
    def __init__(self, name="AppMpsSalt", description="AmcCarrier MPS PHY Module", memBase=None, offset=0x0, hidden=False):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden)

        ##############################
        # Variables
        ##############################

        self.add(pr.Variable(   name         = "MpsTxLinkUpCnt",
                                description  = "MPS TX LinkUp Counter",
                                offset       =  0x00,
                                bitSize      =  32,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        for i in range(14):
            self.add(pr.Variable(   name         = "MpsRxLinkUpCnt_%.*i" % (2, i),
                                    description  = "MPS RX LinkUp Counter[13:0] %.*i" % (2, i),
                                    offset       =  0x04 + (i * 0x04),
                                    bitSize      =  32,
                                    bitOffset    =  0x00,
                                    base         = "hex",
                                    mode         = "RO",
                                ))

        self.add(pr.Variable(   name         = "MpsTxLinkUP",
                                description  = "MPS TX LinkUp",
                                offset       =  0x700,
                                bitSize      =  1,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MpsRxLinkUP",
                                description  = "MPS TX LinkUp[13:0]",
                                offset       =  0x700,
                                bitSize      =  14,
                                bitOffset    =  0x01,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MPS_SLOT_G",
                                description  = "MPS_SLOT_G",
                                offset       =  0x704,
                                bitSize      =  1,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "APP_TYPE_G",
                                description  = "See AmcCarrierPkg.vhd for defination",
                                offset       =  0x708,
                                bitSize      =  7,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MPS_CHANNELS_C",
                                description  = "Number of MPS channels",
                                offset       =  0x70C,
                                bitSize      =  32,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MPS_THRESHOLD_C",
                                description  = "Number of MPS Thresholds",
                                offset       =  0x710,
                                bitSize      =  32,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MpsPllLocked",
                                description  = "MPS PLL Lock Status",
                                offset       =  0x714,
                                bitSize      =  1,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RO",
                            ))

        self.add(pr.Variable(   name         = "MpsEnable",
                                description  = "MPS Enable Flag",
                                offset       =  0x800,
                                bitSize      =  1,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "MpsTestMode",
                                description  = "MPS Test Mode Flag",
                                offset       =  0x804,
                                bitSize      =  1,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "RollOverEn",
                                description  = "Status Counter Roll Over Enable",
                                offset       =  0xFF0,
                                bitSize      =  15,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "RW",
                            ))

        self.add(pr.Variable(   name         = "CntRst",
                                description  = "Status Counter Reset",
                                offset       =  0xFF4,
                                bitSize      =  1,
                                bitOffset    =  0x00,
                                base         = "hex",
                                mode         = "WO",
                            ))

