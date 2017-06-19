import pyrogue as pr

# Modules from surf
from surf.axi import *
from surf.devices.microchip import *
from surf.devices.ti import *
from surf.devices.micron import *
from surf.ethernet import *
from surf.misc import *
from surf.protocols import *
from surf.xilinx import *
from surf.ethernet.udp import *
from surf.protocols.rssi import *

# Modules from AmcCarrierCore
from AmcCarrierCore import *

# Modules from AppMps
from AppMps.AppMps import *

class AmcCarrierCore(pr.Device):
    def __init__(   self, 
                    name        = "AmcCarrierCore", 
                    memBase     = None, 
                    offset      = 0x0, 
                    enableBsa   = True,
                    hidden      = False,
                    expand	    = False,
                ):
        super(self.__class__, self).__init__(name, "AmcCarrierCore", memBase, offset, hidden, expand=expand)   

        ##############################
        # Variables
        ##############################                        
        self.add(AxiVersion(            
                                offset       =  0x00000000, 
                                expand       =  False
                            ))

        self.add(AxiSysMonUltraScale(   
                                offset       =  0x01000000, 
                                expand       =  False
                            ))

        self.add(AxiSy56040(    offset       =  0x03000000, 
                                expand       =  False,
                                description  = "\n\
                                                Timing Crossbar:\n\
                                                -----------------------------------------------------------------\n\
                                                OutputConfig[0] = 0x0: Connects RTM_TIMING_OUT0 to RTM_TIMING_IN0\n\
                                                OutputConfig[0] = 0x1: Connects RTM_TIMING_OUT0 to FPGA_TIMING_IN\n\
                                                OutputConfig[0] = 0x2: Connects RTM_TIMING_OUT0 to BP_TIMING_IN\n\
                                                OutputConfig[0] = 0x3: Connects RTM_TIMING_OUT0 to RTM_TIMING_IN1\n\
                                                -----------------------------------------------------------------\n\
                                                OutputConfig[1] = 0x0: Connects FPGA_TIMING_OUT to RTM_TIMING_IN0\n\
                                                OutputConfig[1] = 0x1: Connects FPGA_TIMING_OUT to FPGA_TIMING_IN\n\
                                                OutputConfig[1] = 0x2: Connects FPGA_TIMING_OUT to BP_TIMING_IN\n\
                                                OutputConfig[1] = 0x3: Connects FPGA_TIMING_OUT to RTM_TIMING_IN1 \n\
                                                -----------------------------------------------------------------\n\
                                                OutputConfig[2] = 0x0: Connects Backplane DIST0 to RTM_TIMING_IN0\n\
                                                OutputConfig[2] = 0x1: Connects Backplane DIST0 to FPGA_TIMING_IN\n\
                                                OutputConfig[2] = 0x2: Connects Backplane DIST0 to BP_TIMING_IN\n\
                                                OutputConfig[2] = 0x3: Connects Backplane DIST0 to RTM_TIMING_IN1\n\
                                                -----------------------------------------------------------------\n\
                                                OutputConfig[3] = 0x0: Connects Backplane DIST1 to RTM_TIMING_IN0\n\
                                                OutputConfig[3] = 0x1: Connects Backplane DIST1 to FPGA_TIMING_IN\n\
                                                OutputConfig[3] = 0x2: Connects Backplane DIST1 to BP_TIMING_IN\n\
                                                OutputConfig[3] = 0x3: Connects Backplane DIST1 to RTM_TIMING_IN1\n\
                                                -----------------------------------------------------------------\n"\
                            ))

        self.add(Axi24LC64FT(
                                offset       =  0x04000000,
                                nelms        =  0x800,
                                instantiate  =  False,
                                hidden       =  True,
                            ))
                            
        self.add(AxiCdcm6208(     
                                offset       =  0x05000000, 
                                expand       =  False,
                            ))

        # self.add(DdrSpd(          
                                # offset       =  0x06000000, 
                                # expand       =  False, 
                                # hidden       =  True,
                            # ))

        self.add(AmcCarrierBsi(   
                                offset       =  0x07000000, 
                                expand       =  False,
                            ))

        self.add(AmcCarrierTiming(
                                offset       =  0x08000000, 
                                expand       =  False,
                            ))

        self.add(AmcCarrierBsa(   
                                offset       =  0x09000000, 
                                enableBsa    =  enableBsa,
                                expand       =  False,
                            ))
                            
        self.add(UdpEngineClient(
                                name         = "BpUdpClient",
                                offset       =  0x0A000000,
                                description  = "BpUdpClient",
                                expand       =  False,
                            ))

        self.add(UdpEngineServer(
                                name         = "BpUdpServer",
                                offset       =  0x0A000818,
                                description  = "BpUdpServer",
                                expand       =  False,
                            ))


        for i in range(2):                                       
            self.add(UdpEngineServer(
                                    name         = "SwUdpServer[%i]" % (i),
                                    offset       =  0x0A000808 + (i * 0x08),
                                    description  = "SwUdpServer. Server: %i" % (i),  
                                    expand       =  False,                                    
                                ))
        for i in range(2):
            self.add(RssiCore(
                                    name         = "SwRssiServer[%i]" % (i),
                                    offset       =  0x0A010000 + (i * 0x1000),
                                    description  = "SwRssiServer. Server: %i" % (i),                                
                                    expand       =  False,                                    
                                ))

        self.add(AxiMemTester(
                                offset       =  0x0B000000, 
                                expand       =  False, 
                                hidden       =  True
                            ))
        self.add(AppMps(      
                                offset       =  0x0C000000, 
                                expand       =  False
                            ))

    def writeBlocks(self, force=False, recurse=True, variable=None):
        """
        Write all of the blocks held by this Device to memory
        """
        if not self.enable.get(): return

        # Process local blocks.
        if variable is not None:
            variable._block.backgroundTransaction(rogue.interfaces.memory.Write)
        else:
            for block in self._blocks:
                if force or block.stale:
                    if block.bulkEn:
                        block.backgroundTransaction(rogue.interfaces.memory.Write)

        # Process rest of tree
        if recurse:
            for key,value in self.devices.items():
                value.writeBlocks(force=force, recurse=True)                        
                        
        # Retire any in-flight transactions before starting
        self._root.checkBlocks(varUpdate=True, recurse=True)
        
        for i in range(2):
            v = getattr(self.AmcCarrierBsa, 'BsaWaveformEngine[%i]'%i)
            v.WaveformEngineBuffers.Initialize()
        
        self.checkBlocks(recurse=True)
        