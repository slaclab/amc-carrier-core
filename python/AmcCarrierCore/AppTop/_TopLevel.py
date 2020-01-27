#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AMC Carrier Cryo Demo Board Application
#-----------------------------------------------------------------------------
# File       : AppCore.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue AMC Carrier Cryo Demo Board Application
#
# Network Interfaces:
#    UDP_SRV_XVC_IDX_C         => 2542,  -- Xilinx XVC
#    UDP_SRV_SRPV0_IDX_C       => 8192,  -- Legacy SRPv0 register access (still used for remote FPGA reprogramming)
#    UDP_SRV_RSSI0_IDX_C       => 8193,  -- Legacy Non-interleaved RSSI for Register access and ASYNC messages
#    UDP_SRV_RSSI1_IDX_C       => 8194,  -- Legacy Non-interleaved RSSI for bulk data transfer
#    UDP_SRV_BP_MGS_IDX_C      => 8195,  -- Backplane Messaging
#    UDP_SRV_TIMING_IDX_C      => 8197,  -- Timing ASYNC Messaging
#    UDP_SRV_RSSI_ILEAVE_IDX_C => 8198);  -- Interleaved RSSI
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
import pyrogue.interfaces.simulation
import pyrogue.protocols
import pyrogue.utilities.fileio
import rogue.hardware.axi
import rogue.protocols.packetizer
import AmcCarrierCore as amccCore
from AmcCarrierCore.AppTop._AppTop import AppTop

class TopLevel(pr.Device):
    def __init__(   self, 
            name            = 'FpgaTopLevel',
            description     = 'Container for FPGA Top-Level', 
            # JESD Parameters
            numRxLanes      = [0,0],
            numTxLanes      = [0,0],
            enJesdDrp       = False,
            # Signal Generator Parameters
            numSigGen       = [0,0],
            sizeSigGen      = [0,0],
            modeSigGen      = [False,False],
            # General Parameters
            enablePwrI2C    = False,
            enableBsa       = False,
            enableMps       = False,
            numWaveformBuffers  = 4,
            expand          = True,
            enableTpgMini   = True,
            **kwargs):
        super().__init__(name=name, description=description, expand=expand, **kwargs)

        self._numRxLanes = numRxLanes
        self._numTxLanes = numTxLanes
        self._numWaveformBuffers = numWaveformBuffers
        
        # Add devices
        self.add(amccCore.AmcCarrierCore(
            offset            = 0x00000000,
            enablePwrI2C      = enablePwrI2C,
            enableBsa         = enableBsa,
            enableMps         = enableMps,
            numWaveformBuffers= numWaveformBuffers,
            enableTpgMini     = enableTpgMini,
        ))
        self.add(AppTop(
            offset       = 0x80000000,
            numRxLanes   = numRxLanes,
            numTxLanes   = numTxLanes,
            enJesdDrp    = enJesdDrp,
            numSigGen    = numSigGen,
            sizeSigGen   = sizeSigGen,
            modeSigGen   = modeSigGen,
            numWaveformBuffers = numWaveformBuffers,
            expand       = True
        ))

        # Define SW trigger command
        @self.command(description="Software Trigger for DAQ MUX",)
        def SwDaqMuxTrig():
            for i in range(2): 
                self.AppTop.DaqMuxV2[i].TriggerDaq.call()

    def writeBlocks(self, **kwargs):
        super().writeBlocks(**kwargs)

        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)

        # Calculate the BsaWaveformEngine buffer sizes
        size    = [[0]*self._numWaveformBuffers,[0]*self._numWaveformBuffers]
        for i in range(2):
            if ((self._numRxLanes[i] > 0) or (self._numTxLanes[i] > 0)):
                for j in range(self._numWaveformBuffers):
                    waveBuff = self.AmcCarrierCore.AmcCarrierBsa.BsaWaveformEngine[i].WaveformEngineBuffers
                    if ( (waveBuff.Enabled[j].get() > 0) and (waveBuff.EndAddr[j].get() > waveBuff.StartAddr[j].get()) ):
                        size[i][j] = waveBuff.EndAddr[j].get() - waveBuff.StartAddr[j].get()

        # Calculate the 
        minSize = [size[0][0],size[1][0]]
        for i in range(2):
            if ((self._numRxLanes[i] > 0) or (self._numTxLanes[i] > 0)):
                for j in range(self._numWaveformBuffers):
                    if ( size[i][j]<minSize[i] ):
                        minSize[i] = size[i][j]

        # Set the DAQ MUX buffer sizes to match the BsaWaveformEngine buffer sizes
        for i in range(2):
            if ((self._numRxLanes[i] > 0) or (self._numTxLanes[i] > 0)):
                # Convert from bytes to words
                minSize[i] = minSize[i] >> 2
                # Set the DAQ MUX buffer sizes
                self.AppTop.DaqMuxV2[i].DataBufferSize.set(minSize[i])

        self.checkBlocks(recurse=True)
