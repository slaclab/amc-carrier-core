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
import pyrogue.interfaces.simulation
import pyrogue.protocols
import pyrogue.utilities.fileio
import rogue.hardware.axi
import rogue.protocols.packetizer

from AmcCarrierCore import *
from AppTop import *

class TopLevel(pr.Device):
    def __init__(   self, 
            name            = 'FpgaTopLevel',
            description     = 'Container for FPGA Top-Level', 
            # Communication Parameters
            simGui          = False,
            commType        = 'eth-rssi-non-interleaved',
            ipAddr          = '10.0.1.101',
            pcieDev         = '/dev/datadev_0',
            pcieRssiLink    = 0,
            # JESD Parameters
            numRxLanes      = [0,0],
            numTxLanes      = [0,0],
            enJesdDrp       = False,
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
        
        rssiInterlaved    = False
        rssiNotInterlaved = False
        
        # Check for valid link range
        if (pcieRssiLink<0) or (pcieRssiLink>5):
            raise ValueError("Invalid pcieRssiLink (%d)" % (pcieRssiLink) )

        if (simGui):
            # Create simulation srp interface
            srp=pyrogue.interfaces.simulation.MemEmulate()
        else:
        
            ################################################################################################################
            # UDP_SRV_XVC_IDX_C         => 2542,  -- Xilinx XVC 
            # UDP_SRV_SRPV0_IDX_C       => 8192,  -- Legacy SRPv0 register access (still used for remote FPGA reprogramming)
            # UDP_SRV_RSSI0_IDX_C       => 8193,  -- Legacy Non-interleaved RSSI for Register access and ASYNC messages
            # UDP_SRV_RSSI1_IDX_C       => 8194,  -- Legacy Non-interleaved RSSI for bulk data transfer
            # UDP_SRV_BP_MGS_IDX_C      => 8195,  -- Backplane Messaging
            # UDP_SRV_TIMING_IDX_C      => 8197,  -- Timing ASYNC Messaging
            # UDP_SRV_RSSI_ILEAVE_IDX_C => 8198);  -- Interleaved RSSI         
            ################################################################################################################
        
            if ( commType=="eth-fsbl" ):
            
                # UDP only
                self.udp = rogue.protocols.udp.Client(ipAddr,8192,0)
            
                # Connect the SRPv0 to RAW UDP
                self.srp = rogue.protocols.srp.SrpV0()
                pyrogue.streamConnectBiDir( self.srp, self.udp )
            
            elif ( commType=="eth-rssi-non-interleaved" ):
                
                # Update the flag
                rssiNotInterlaved = True
            
                # Create SRP/ASYNC_MSG interface
                self.rudp = pyrogue.protocols.UdpRssiPack( name='rudpReg', host=ipAddr, port=8193, packVer = 1) 

                # Connect the SRPv3 to tDest = 0x0
                self.srp = rogue.protocols.srp.SrpV3()
                pr.streamConnectBiDir( self.srp, self.rudp.application(dest=0x0) )

                # Create stream interface
                self.stream = pr.protocols.UdpRssiPack( name='rudpData', host=ipAddr, port=8194, packVer = 1)       
            
            elif ( commType=="eth-rssi-interleaved" ):
            
                # Update the flag
                rssiInterlaved = True

                # Create Interleaved RSSI interface
                self.rudp = self.stream = pyrogue.protocols.UdpRssiPack( name='rudp', host=ipAddr, port=8198, packVer = 2)
                
                # Connect the SRPv3 to tDest = 0x0
                self.srp = rogue.protocols.srp.SrpV3()
                pr.streamConnectBiDir( self.srp, self.rudp.application(dest=0x0) )
                
            elif ( commType == 'pcie-fsbl' ):
            
                # Using PackVer2 after the DMA in firmware
                self.dma  = rogue.hardware.axi.AxiStreamDma(pcieDev,pcieRssiLink,1)
                self.pack = rogue.protocols.packetizer.CoreV2(False,False) # ibCRC = False, obCRC = False
                pr.streamConnectBiDir( self.pack.transport(), self.dma )

                # Connect the SRPv0 to tDest = 0x0
                self.srp = rogue.protocols.srp.SrpV0()
                pr.streamConnectBiDir( self.srp, self.pack.application(0x0) )            

            elif ( commType == 'pcie-rssi-interleaved' ):
            
                # Update the flag
                rssiInterlaved = True
            
                # Using PackVer2 after the DMA in firmware
                self.dma  = rogue.hardware.axi.AxiStreamDma(pcieDev,pcieRssiLink,1)
                self.pack = rogue.protocols.packetizer.CoreV2(False,False) # ibCRC = False, obCRC = False
                pr.streamConnectBiDir( self.pack.transport(), self.dma )

                # TDEST 0 routed to stream 0 (SRPv3)
                self.srp = rogue.protocols.srp.SrpV3()
                pr.streamConnectBiDir( self.srp, self.pack.application(0x0) )

                # TDEST x80-0xBF routed to stream 4 (Raw Data)
                self.rawData = [None] * 64
                for i in range(64):
                    self.rawData[i] = self.pack.application(0x80+i)

                # TDEST 0xC0-0xFF routed to stream 5 (Application) 
                self.appData = [None] * 64
                for i in range(64):
                    self.appData[i] = self.pack.application(0xC0+i)
                    
            # Undefined device type
            else:
                raise ValueError("Invalid type (%s)" % (commType) )

        # Add devices
        self.add(AmcCarrierCore(
            memBase           = self.srp,
            offset            = 0x00000000,
            rssiInterlaved    = rssiInterlaved,
            rssiNotInterlaved = rssiNotInterlaved,
            enableBsa         = enableBsa,
            enableMps         = enableMps,
        ))
        self.add(AppTop(
            memBase      = self.srp,
            offset       = 0x80000000,
            numRxLanes   = numRxLanes,
            numTxLanes   = numTxLanes,
            enJesdDrp    = enJesdDrp,
            numSigGen    = numSigGen,
            sizeSigGen   = sizeSigGen,
            modeSigGen   = modeSigGen,
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
