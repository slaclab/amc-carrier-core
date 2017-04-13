import pyrogue as pr

# Modules from surf
from surf._AxiVersion import *
from surf._AxiSysMonUltraScale import *
from surf._AxiMicronN25Q import *
from surf._AxiSy56040 import *
from surf._AxiCdcm6208 import *
from surf._UdpEngineClient import *
from surf._UdpEngineServer import *
from surf._RssiCore import *
from surf._AxiMemTester import *
from surf._Axi24LC64FT import *
from surf._DdrSpd import *

# Modules from AmcCarrierCore
from AmcCarrierCore.AmcCarrierBsi import *
from AmcCarrierCore.AmcCarrierTiming import *
from AmcCarrierCore.AmcCarrierBsa import *

# Modules from AppMps
from AppMps.AppMps import *

class AmcCarrierCore(pr.Device):
    def __init__(   self, 
                    name        = "AmcCarrierCore", 
                    memBase     =  None, 
                    offset      =  0x0, 
                    hidden      = False,
                ):
        super(self.__class__, self).__init__(name, "AmcCarrierCore", memBase, offset, hidden)

        ##############################
        # Variables
        ##############################

        self.addVariable(   name         = "AMC_CARRIER_CORE_VERSION_C",
                            description  = "FAMC Carrier Core Version Number",
                            offset       =  0x00000400,
                            bitSize      =  32,
                            bitOffset    =  0x00,
                            base         = "hex",
                            mode         = "RO",
                        )

        self.add(AxiVersion(
                                offset       =  0x00000000
                            ))

        self.add(AxiSysMonUltraScale(
                                offset       =  0x01000000
                            ))

        self.add(AxiMicronN25Q(
                                offset=0x02000000
                            ))

        self.add(AxiSy56040(
                                offset       =  0x03000000, 
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
                                #instantiate  =  False,
                            ))

        self.add(AxiCdcm6208(
                                offset       =  0x05000000,
                            ))

        self.add(DdrSpd(
                                offset       =  0x06000000,
                            ))

        self.add(AmcCarrierBsi(
                                offset       =  0x07000000,
                            ))
        
        self.add(AmcCarrierTiming(
                                offset       =  0x08000000,
                            ))

        self.add(AmcCarrierBsa(
                                offset       =  0x09000000,
                            ))
              
        for i in range(4):                                       
            self.add(UdpEngineClient(
                                    name         = "UdpEngineClient_%i" % (i),
                                    offset       =  0x0A000000 + (i * 0x08),
                                    description  = "ClientConfig[1:0]. Client: %i" % (i),
                                ))

        for i in range(4):                                       
            self.add(UdpEngineServer(
                                    name         = "UdpEngineServer_%i" % (i),
                                    offset       =  0x0A000800 + (i * 0x08),
                                    description  = "ServerConfig[4:0]. Server: %i" % (i),             
                                ))
        for i in range(2):
            self.add(RssiCore(
                                    name         = "RssiServerSw_%i" % (i),
                                    offset       =  0x0A010000 + (i * 0x08),
                                    description  = "ServerConfig[4:0]. Server: %i" % (i),                                
                                ))

        self.add(AxiMemTester(
                                offset       =  0x0B000000
                            ))

        self.add(AppMps(
                                offset       =  0x0C000000
                            ))
