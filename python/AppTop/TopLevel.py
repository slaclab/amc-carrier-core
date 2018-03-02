#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AMC Carrier Cryo Demo Board Application
#-----------------------------------------------------------------------------
# File       : AppCore.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue AMC Carrier Cryo Demo Board Application
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
import pyrogue.simulation
import pyrogue.protocols
import pyrogue.utilities.fileio
import rogue.hardware.data

from AmcCarrierCore import *
from AppTop import *

class TopLevel(pr.Device):
    def __init__(   self, 
            name            = "FpgaTopLevel", 
            description     = "Container for FPGA Top-Level", 
            # Communication Parameters
            simGui          = False,
            commType        = "eth-rssi-non-interleaved",
            ipAddr          = "10.0.1.101",
            pcieRssiLink    = 0,
            # JESD Parameters
            numRxLanes      = [0,0],
            numTxLanes      = [0,0],
            # Signal Generator Parameters
            numSigGen       = [0,0],
            sizeSigGen      = [0,0],
            modeSigGen      = [False,False],
            # General Parameters
            enableBsa       = False,
            enableMps       = False,
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self._numRxLanes = numRxLanes
        self._numTxLanes = numTxLanes

        if (simGui):
            # Create simulation srp interface
            srp=pyrogue.simulation.MemEmulate()
        else:

            # File writer
            dataWriter = pyrogue.utilities.fileio.StreamWriter(name='dataWriter')
            self.add(dataWriter)

            # Create SRPv3 module
            srp = rogue.protocols.srp.SrpV3()

            # Determine if ETH or PCIe communication:
            if ( commType=="eth-rssi-non-interleaved" ):
            
                # Create SRP/ASYNC_MSG interface
                udp = pyrogue.protocols.UdpRssiPack( host=ipAddr, port=8193, size=1400)

                # Connect the SRPv3 to tDest = 0x0
                pr.streamConnectBiDir( srp, udp.application(dest=0x0) )

                # Create stream interface
                udpStream = self.stream = pr.protocols.UdpRssiPack( host=ipAddr, port=8194, size=1400)

                # Add data streams
                for i in range(8):
                    pyrogue.streamConnect(udpStream.application(0x80 + i), dataWriter.getChannel(i))            
            
            elif ( commType=="eth-rssi-interleaved" ):

                # Create Interleaved RSSI interface
                rudp = self.stream = pyrogue.protocols.UdpRssiPack( host=ipAddr, port=8193, size=1400, packVer = 2)

                # Connect the SRPv3 to tDest = 0x0
                pr.streamConnectBiDir( srp, rudp.application(dest=0x0) )

                # Add data streams
                for i in range(8):
                    pyrogue.streamConnect(rudp.application(0x80 + i), dataWriter.getChannel(i))
                    
            elif ( commType == 'pcie' ):

                #########################################################################################
                # Assumes this PCIe card Configuration:
                #########################################################################################
                # constant NUM_LINKS_C     : positive := 1;
                # constant RSSI_PER_LINK_C : positive := 6;
                # constant RSSI_STREAMS_C  : positive := 3;
                # constant AXIS_PER_LINK_C : positive := RSSI_PER_LINK_C*RSSI_STREAMS_C;
                # constant NUM_AXIS_C      : positive := NUM_LINKS_C*AXIS_PER_LINK_C;
                # constant NUM_RSSI_C      : positive := NUM_LINKS_C*RSSI_PER_LINK_C;
                #########################################################################################
   
                # Check for valid link range
                if (pcieRssiLink<0) or (pcieRssiLink>6):
                    raise ValueError("Invalid pcieRssiLink (%d)" % (pcieRssiLink) )
            
                #########################################################################################
                # Assumes this RSSI Wrapper TDEST Mapping:
                #########################################################################################
                #   APP_STREAM_ROUTES_G => (
                #       0 => X"00",         -- TDEST 0 routed to stream 0 (SRPv3)
                #       1 => "10------",    -- TDEST x80-0xBF routed to stream 1 (Raw Data)
                #       2 => "11------"),   -- TDEST 0xC0-0xFF routed to stream 2 (Application)  
                #########################################################################################
            
                # Connect the SRPv3 to tDest = 0x0
                vc0Srp  = rogue.hardware.data.DataCard('/dev/datadev_0',(pcieRssiLink*4)+0)
                pr.streamConnectBiDir( srp, vc0Srp )   

                # Create the Raw Data stream interface
                vc1RawData = self.stream = rogue.hardware.data.DataCard('/dev/datadev_0',(pcieRssiLink*4)+1)
                pyrogue.streamConnect(vc1RawData, dataWriter.getChannel(0))

                # Create the Raw Data stream interface
                vc2AppData = self.stream = rogue.hardware.data.DataCard('/dev/datadev_0',(pcieRssiLink*4)+2)
                pyrogue.streamConnect(vc2AppData, dataWriter.getChannel(1))

            # Undefined device type
            else:
                raise ValueError("Invalid type (%s)" % (commType) )

        # Add devices
        self.add(AmcCarrierCore(
            memBase    =  srp,
            offset     =  0x00000000,
            enableBsa  =  enableBsa,
            enableMps  =  enableMps,
        ))
        self.add(AppTop(
            memBase      =  srp,
            offset       =  0x80000000,
            numRxLanes   =  numRxLanes,
            numTxLanes   =  numTxLanes,
            numSigGen    =  numSigGen,
            sizeSigGen   =  sizeSigGen,
            modeSigGen   =  modeSigGen,
        ))

        # Define SW trigger command
        @self.command(description="Software Trigger for DAQ MUX",)
        def SwDaqMuxTrig():
            for i in range(2): 
                self.AppTop.DaqMuxV2[i].TriggerDaq.call()

    def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
        """
        Write all of the blocks held by this Device to memory
        """
        if not self.enable.get(): return

        # Process local blocks.
        if variable is not None:
            #variable._block.startTransaction(rogue.interfaces.memory.Write, check=checkEach) # > 2.4.0
            variable._block.backgroundTransaction(rogue.interfaces.memory.Write)
        else:
            for block in self._blocks:
                if force or block.stale:
                    if block.bulkEn:
                        #block.startTransaction(rogue.interfaces.memory.Write, check=checkEach) # > 2.4.0
                        block.backgroundTransaction(rogue.interfaces.memory.Write)

        # Process rest of tree
        if recurse:
            for key,value in self.devices.items():
                #value.writeBlocks(force=force, recurse=True, checkEach=checkEach)  # > 2.4.0
                value.writeBlocks(force=force, recurse=True)

        # Retire any in-flight transactions before starting
        self._root.checkBlocks(recurse=True)

        # Calculate the BsaWaveformEngine buffer sizes
        size    = [[0,0,0,0],[0,0,0,0]]
        for i in range(2):
            if ((self._numRxLanes[i] > 0) or (self._numTxLanes[i] > 0)):
                for j in range(4):
                    waveBuff = self.AmcCarrierCore.AmcCarrierBsa.BsaWaveformEngine[i].WaveformEngineBuffers
                    if ( (waveBuff.Enabled[j].get() > 0) and (waveBuff.EndAddr[j].get() > waveBuff.StartAddr[j].get()) ):
                        size[i][j] = waveBuff.EndAddr[j].get() - waveBuff.StartAddr[j].get()

        # Calculate the 
        minSize = [size[0][0],size[1][0]]
        for i in range(2):
            if ((self._numRxLanes[i] > 0) or (self._numTxLanes[i] > 0)):
                for j in range(4):
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
