import pyrogue as pr
import rogue
import pyrogue.protocols

class MyRoot(pr.Root):
    def __init__(   self,
            ip           = '10.0.0.101',
            commType     = 'eth-rssi-non-interleaved',
            FpgaTopLevel = None,
            **kwargs):
        super().__init__(**kwargs)

        #################################################################

        if ( commType=="eth-fsbl" ):
            # UDP only
            self.udp = rogue.protocols.udp.Client(ip,8192,0)

            # Connect the SRPv0 to RAW UDP
            self.srp = rogue.protocols.srp.SrpV0()
            self.srp == self.udp

        elif ( commType=="eth-rssi-non-interleaved" ):

            # Create SRP/ASYNC_MSG interface
            self.rudp = pyrogue.protocols.UdpRssiPack( name='rudpReg', host=ip, port=8193, packVer = 1, jumbo = False)

            # Connect the SRPv3 to tDest = 0x0
            self.srp = rogue.protocols.srp.SrpV3()
            self.srp == self.rudp.application(dest=0x0)

            # Create stream interface
            self.stream = pr.protocols.UdpRssiPack( name='rudpData', host=ip, port=8194, packVer = 1, jumbo = False)

        elif ( commType=="eth-rssi-interleaved" ):

            # Create Interleaved RSSI interface
            self.rudp = self.stream = pyrogue.protocols.UdpRssiPack( name='rudp', host=ip, port=8198, packVer = 2, jumbo = True)

            # Connect the SRPv3 to tDest = 0x0
            self.srp = rogue.protocols.srp.SrpV3()
            self.srp == self.rudp.application(dest=0x0)

        # Undefined device type
        else:
            raise ValueError("Invalid type (%s)" % (commType) )

        # Add the top level device to ROOT
        self.add(FpgaTopLevel(
            memBase = self.srp,
        ))
