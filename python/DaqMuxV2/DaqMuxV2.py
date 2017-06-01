#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Waveform Data Acquisition Module
#-----------------------------------------------------------------------------
# File       : DaqMuxV2.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Waveform Data Acquisition Module
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

class DaqMuxV2(pr.Device):
    def __init__(   self,       
                    name        = "DaqMuxV2",
                    description = "Waveform Data Acquisition Module",
                    memBase     =  None,
                    offset      =  0x00,
                    hidden      =  False,
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden, )

        ##############################
        # Variables
        ##############################

        self.addVariable(   name         = "TriggerSw",
                            description  = "Software Trigger (triggers DAQ on all enabled channels).",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(   name         = "TriggerCascMask",
                            description  = "Mask for enabling/disabling cascaded trigger.",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x01,
                            base         = "enum",
                            mode         = "RW",
                            enum         = {
                                              0 : "Disabled",
                                              1 : "Enabled",
                                           },
                        )

        self.addVariable(   name         = "TriggerHwAutoRearm",
                            description  = "Mask for enabling/disabling hardware trigger. If disabled it has to be rearmed by ArmHwTrigger.",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x02,
                            base         = "enum",
                            mode         = "RW",
                            enum         = {
                                              0 : "Disabled",
                                              1 : "Enabled",
                                           },
                        )

        self.addVariable(   name         = "TriggerHwArm",
                            description  = "Arm the Hardware trigger (On the rising edge). After trigger occurs the trigger has to be rearmed.",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x03,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(   name         = "TriggerClearStatus",
                            description  = "Trigger status will be cleared (On the rising edge).",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x04,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(   name         = "DaqMode",
                            description  = "Select the data ackuisition mode.",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x05,
                            base         = "enum",
                            mode         = "RW",
                            enum         = {
                                              0 : "TriggeredMode",
                                              1 : "ContinuousMode",
                                           },
                        )

        self.addVariable(   name         = "PacketHeaderEn",
                            description  = "Applies only to Triggered mode.",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x06,
                            base         = "enum",
                            mode         = "RW",
                            enum         = {
                                              0 : "Disabled",
                                              1 : "Enabled",
                                           },
                        )

        self.addVariable(   name         = "FreezeSw",
                            description  = "Software freeze buffer (Freezes all enabled circular buffers).",
                            offset       =  0x00,
                            bitSize      =  1,
                            bitOffset    =  0x07,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(   name         = "FreezeHwMask",
                            description  = "Mask for enabling/disabling hardware freaze buffer request.",
                            offset       =  0x01,
                            bitSize      =  1,
                            bitOffset    =  0x00,
                            base         = "enum",
                            mode         = "RW",
                            enum         = {
                                              0 : "Disabled",
                                              1 : "Enabled",
                                           },
                        )

        self.addVariable(   name         = "TriggerSwStatus",
                            description  = "Software Trigger Status (Registered on first trigger until cleared by TriggerClearStatus).",
                            offset       =  0x04,
                            bitSize      =  1,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariable(   name         = "TriggerCascStatus",
                            description  = "Cascade Trigger Status (Registered on first trigger until cleared by TriggerClearStatus).",
                            offset       =  0x04,
                            bitSize      =  1,
                            bitOffset    =  0x01,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariable(   name         = "TriggerHwStatus",
                            description  = "Hardware Trigger Status (Registered on first trigger until cleared by TriggerClearStatus).",
                            offset       =  0x04,
                            bitSize      =  1,
                            bitOffset    =  0x02,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariable(   name         = "TriggerHwArmed",
                            description  = "Hardware Trigger Armed Status (Registered on rising edge Control(3) and cleared when Hw trigger occurs).",
                            offset       =  0x04,
                            bitSize      =  1,
                            bitOffset    =  0x03,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariable(   name         = "TriggerStatus",
                            description  = "Combined Trigger Status (Registered on first trigger until cleared by TriggerClearStatus).",
                            offset       =  0x04,
                            bitSize      =  1,
                            bitOffset    =  0x04,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariable(   name         = "FreezeStatus",
                            description  = "Freeze Buffers Status (Registered on first freeze until cleared by TriggerClearStatus)",
                            offset       =  0x04,
                            bitSize      =  1,
                            bitOffset    =  0x05,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariable(   name         = "DecimationRateDiv",
                            description  = "Averaging Enabled: (powers of two) 1,2,4,8,16,etc (max 2^12). Averaging Disabled (32-bit): 1,2,3,4,etc (max 2^16-1). Averaging Disabled (16-bit): 1,2,4,6,8,etc (max 2^16-1).",
                            offset       =  0x08,
                            bitSize      =  16,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(   name         = "DataBufferSize",
                            description  = "Number of 32-bit words. Minimum size is 4.",
                            offset       =  0x0C,
                            bitSize      =  32,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariables(  name         = "Timestamp",
                            description  = "Timestamp 63:0",
                            offset       =  0x10,
                            bitSize      =  32,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RO",
                            number       =  2,
                            stride       =  4,
                        )

        self.addVariables(  name         = "Bsa",
                            description  = "bsa(0) - edefAvgDn, bsa(1) - edefMinor, bsa(2) - edefMajor, bsa(3) - edefInit",
                            offset       =  0x18,
                            bitSize      =  32,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariable(   name         = "TrigCount",
                            description  = "Counts valid data acquisition triggers.",
                            offset       =  0x28,
                            bitSize      =  32,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.addVariables(  name         = "InputMuxSel",
                            description  = "Input Mux select. Maximum number of channels is 29.",
                            offset       =  0x40,
                            bitSize      =  5,
                            bitOffset    =  0x00,
                            base         = "enum",
                            mode         = "RW",
                            number       =  4,
                            stride       =  4,
                            enum         = {
                                               0 : "Disabled",
                                               1 : "Test",
                                               2 : "Ch0",
                                               3 : "Ch1",
                                               4 : "Ch2",
                                               5 : "Ch3",
                                               6 : "Ch4",
                                               7 : "Ch5",
                                               8 : "Ch6",
                                               9 : "Ch7",
                                              10 : "Ch8",
                                              11 : "Ch9",
                                              12 : "Ch10",
                                              13 : "Ch11",
                                              14 : "Ch12",
                                              15 : "Ch13",
                                              16 : "Ch14",
                                              17 : "Ch15",
                                              18 : "Ch16",
                                              19 : "Ch17",
                                              20 : "Ch18",
                                              21 : "Ch19",
                                              22 : "Ch20",
                                              23 : "Ch21",
                                              24 : "Ch22",
                                              25 : "Ch23",
                                              26 : "Ch24",
                                              27 : "Ch25",
                                              28 : "Ch26",
                                              29 : "Ch27",
                                              30 : "Ch28",
                                              31 : "Ch29",
                                           },
                        )

        self.addVariables(  name         = "StreamPause",
                            description  = "Raw diagnostic stream control Pause.",
                            offset       =  0x80,
                            bitSize      =  1,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "StreamReady",
                            description  = "Raw diagnostic stream control Ready.",
                            offset       =  0x80,
                            bitSize      =  1,
                            bitOffset    =  0x01,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "StreamOverflow",
                            description  = "Raw diagnostic stream control Overflow.",
                            offset       =  0x80,
                            bitSize      =  1,
                            bitOffset    =  0x02,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "StreamError",
                            description  = "Error during last Acquisition (Raw diagnostic stream control Ready or incoming data valid dropped).",
                            offset       =  0x80,
                            bitSize      =  1,
                            bitOffset    =  0x03,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "InputDataValid",
                            description  = "The incoming data is Valid (Usually connected to JESD valid signal).",
                            offset       =  0x80,
                            bitSize      =  1,
                            bitOffset    =  0x04,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "StreamEnabled",
                            description  = "Output stream enabled.",
                            offset       =  0x80,
                            bitSize      =  1,
                            bitOffset    =  0x05,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "FrameCnt",
                            description  = "Number of 4096 byte frames sent.",
                            offset       =  0x80,
                            bitSize      =  26,
                            bitOffset    =  0x06,
                            base         = "hex",
                            mode         = "RO",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "FormatSignWidth",
                            description  = "Indicating sign extension point.",
                            offset       =  0xC0,
                            bitSize      =  5,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RW",
                            number       =  4,
                            stride       =  4,
                        )

        self.addVariables(  name         = "FormatDataWidth",
                            description  = "Data width 32-bit or 16-bit.",
                            offset       =  0xC0,
                            bitSize      =  1,
                            bitOffset    =  0x05,
                            base         = "enum",
                            mode         = "RW",
                            number       =  4,
                            stride       =  4,
                            enum         = {
                                              0 : "D32-bit",
                                              1 : "D16-bit",
                                           },
                        )

        self.addVariables(  name         = "FormatSign",
                            description  = "Sign format.",
                            offset       =  0xC0,
                            bitSize      =  1,
                            bitOffset    =  0x06,
                            base         = "enum",
                            mode         = "RW",
                            number       =  4,
                            stride       =  4,
                            enum         = {
                                              0 : "Unsigned",
                                              1 : "Signed",
                                           },
                        )

        self.addVariables(  name         = "DecimationAveraging",
                            description  = "Decimation Averaging.",
                            offset       =  0xC0,
                            bitSize      =  1,
                            bitOffset    =  0x07,
                            base         = "enum",
                            mode         = "RW",
                            number       =  4,
                            stride       =  4,
                            enum         = {
                                              0 : "Disabled",
                                              1 : "Enabled",
                                           },
                        )

        ##############################
        # Commands
        ##############################

        self.addCommand(    name         = "TriggerDaq",
                            description  = "Trigger data aquisition from software.",
                            function     = """\
                                           self.TriggerSw.set(1)
                                           self.TriggerSw.set(0)
                                           """
                        )

        self.addCommand(    name         = "ArmHwTrigger",
                            description  = "Arm Hardware Trigger.",
                            function     = """\
                                           self.TriggerHwArm.set(1)
                                           self.TriggerHwArm.set(0)
                                           """
                        )

        self.addCommand(    name         = "FreezeBuffers",
                            description  = "Freeze circular buffers from software.",
                            function     = """\
                                           self.FreezeSw.set(1)
                                           self.FreezeSw.set(0)
                                           """
                        )

        self.addCommand(    name         = "ClearTrigStatus",
                            description  = "Clear the status.",
                            function     = """\
                                           self.TriggerClearStatus.set(1)
                                           self.TriggerClearStatus.set(0)
                                           """
                        )