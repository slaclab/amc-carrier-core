#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AmcCarrier BSI Module
#-----------------------------------------------------------------------------
# File       : Adc32Rf45.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Adc32Rf45 Module
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
import time
from AppHardware.AmcCryo._adc32Rf45Channel import *

class Adc32Rf45(pr.Device):
    def __init__(   self,       
                    name        = "Adc32Rf45",
                    description = "Adc32Rf45 Module",
                    memBase     =  None,
                    offset      =  0x00,
                    hidden      =  False,
                    expand      =  True,
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden, expand=expand)
        
        ################
        # Base addresses
        ################
        generalAddr = (0x0 << 14)
        masterPage  = (0x7 << 14)
        analogPage  = (0x8 << 14)
        
        #####################
        # Add Device Channels
        #####################
        self.add(Adc32Rf45Channel(name='CHA',offset=(0x0 << 14),expand=expand))
        # self.add(Adc32Rf45Channel(name='CHB',offset=(0x8 << 14),expand=expand))         
                
        ##################
        # General Register
        ##################
                        
        self.addVariable(  name         = "RESET",
                            description  = "Send 0x81 value to reset the device",
                            offset       =  (generalAddr + (4*0x000)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "WO",
                            verify       =  False,                            
                            # hidden       =  True,                            
                        )
                        
        # self.addVariable(  name         = "SPI_CONFIG",
                            # description  = "0 = 4-wire SPI (default), 1 = 3-wire SPI where SDIN become input or output",
                            # offset       =  (generalAddr + (4*0x010)),
                            # bitSize      =  1,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "WO",
                            # # SDOUT pin on ADC32RF45 is not tri-stated when CS is high rendering it useless in a 4wire SPI configuration. 
                            # # TI has acknowledged this error.  Remove routing to this pin and operate in 3 wire SPI mode (this has been verified to work)
                            # value        =  0,
                            # # hidden       =  True,
                        # )  

        self.addVariable(  name         = "HW_RST",
                            description  = "Hardware Reset",
                            offset       =  (0xF << 14),
                            bitSize      =  1,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RW",
                            # hidden       =  True,
                        ) 


        self.addVariable(  name         = "BASE_4",
                            offset       =  (0x00080000+(0x4<<2)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RO",                                              
                            verify       =  False,
                        )     

        self.addVariable(  name         = "BASE_3",
                            offset       =  (0x00080000+(0x3<<2)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RO",                                      
                            verify       =  False,
                        ) 

        self.addVariable(  name         = "BASE_2",
                            offset       =  (0x00080000+(0x2<<2)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RO",
                            verify       =  False,
                        ) 

        self.addVariable(  name         = "BASE_10",
                            offset       =  (0x00080000+(0x10<<2)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RO",                                                
                            verify       =  False,
                        )                         
                        
        self.addVariable(  name         = "BASE_11",
                            offset       =  (0x00080000+(0x11<<2)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "WO",                                                
                            verify       =  False,
                        ) 

        self.addVariable(  name         = "BASE_12",
                            offset       =  (0x00080000+(0x12<<2)),
                            bitSize      =  8,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "WO",
                            verify       =  False,
                        )                                
                        
                        
                        
        # self.addVariable(  name         = "TEMP2",
                            # offset       =  (generalAddr+(0x4<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                              
                        # )     

        # self.addVariable(  name         = "TEMP1",
                            # offset       =  (generalAddr+(0x3<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                      
                        # ) 

        # self.addVariable(  name         = "TEMP0",
                            # offset       =  (generalAddr+(0x2<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",
                        # ) 

        # self.addVariable(  name         = "TEMP_A",
                            # offset       =  (generalAddr+(0x10<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                              
                        # ) 

        # self.addVariable(  name         = "TEMP_B",
                            # offset       =  (generalAddr+(0x11<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                                
                        # ) 

        # self.addVariable(  name         = "TEMP_C",
                            # offset       =  (generalAddr+(0x12<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",
                        # )                          
                        
                        
        #############
        # Master Page 
        #############
        self.addVariable(  name         = "PDN_SYSREF",
                            description  = "0 = Normal operation, 1 = SYSREF input capture buffer is powered down and further SYSREF input pulses are ignored",
                            offset       =  (masterPage + (4*0x020)),
                            bitSize      =  1,
                            bitOffset    =  4,
                            base         = "hex",
                            mode         = "RW",
                        )
                        
        self.addVariable(  name         = "PDN_CHB",
                            description  = "0 = Normal operation, 1 = Channel B is powered down",
                            offset       =  (masterPage + (4*0x020)),
                            bitSize      =  1,
                            bitOffset    =  1,
                            base         = "hex",
                            mode         = "RW",
                        )                          
                        
        self.addVariable(  name         = "GLOBAL_PDN",
                            description  = "0 = Normal operation, 1 = Global power-down enabled",
                            offset       =  (masterPage + (4*0x020)),
                            bitSize      =  1,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RW",
                        )  

        self.addVariable(  name         = "INCR_CM_IMPEDANCE",
                            description  = "0 = VCM buffer directly drives the common point of biasing resistors, 1 = VCM buffer drives the common point of biasing resistors with > 5 kOhm",
                            offset       =  (masterPage + (4*0x032)),
                            bitSize      =  1,
                            bitOffset    =  5,
                            base         = "hex",
                            mode         = "RW",
                        )                          
                        
        self.addVariable(  name         = "AlwaysWrite0x1_A",
                            description  = "Always set this bit to 1",
                            offset       =  (masterPage + (4*0x039)),
                            bitSize      =  1,
                            bitOffset    =  6,
                            base         = "hex",
                            mode         = "WO",
                            value        = 0x1,
                            hidden       = True,
                        )
                        
        self.addVariable(  name         = "AlwaysWrite0x1_B",
                            description  = "Always set this bit to 1",
                            offset       =  (masterPage + (4*0x039)),
                            bitSize      =  1,
                            bitOffset    =  4,
                            base         = "hex",
                            mode         = "WO",
                            value        = 0x1,
                            hidden       = True,
                        )                             

        self.addVariable(  name         = "PDN_CHB_EN",
                            description  = "This bit enables the power-down control of channel B through the SPI in register 20h: 0 = PDN control disabled, 1 = PDN control enabled",
                            offset       =  (masterPage + (4*0x039)),
                            bitSize      =  1,
                            bitOffset    =  1,
                            base         = "hex",
                            mode         = "RW",
                        )                             

        self.addVariable(  name         = "SYNC_TERM_DIS",
                            description  = "0 = On-chip, 100-Ohm termination enabled, 1 = On-chip, 100-Ohm termination disabled",
                            offset       =  (masterPage + (4*0x039)),
                            bitSize      =  1,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(  name         = "SYSREF_DEL_EN",
                            description  = "0 = SYSREF delay disabled, 1 = SYSREF delay enabled through register settings [3Ch (bits 1-0), 5Ah (bits 7-5)]",
                            offset       =  (masterPage + (4*0x03C)),
                            bitSize      =  1,
                            bitOffset    =  6,
                            base         = "hex",
                            mode         = "RW",
                        )    

        self.addVariable(  name         = "SYSREF_DEL_HI",
                            description  = "When the SYSREF delay feature is enabled (3Ch, bit 6) the delay can be adjusted in 25-ps steps; the first step is 175 ps. The PVT variation of each 25-ps step is +/-10 ps. The 175-ps step is +/-50 ps",
                            offset       =  (masterPage + (4*0x03C)),
                            bitSize      =  2,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(  name         = "JESD_OUTPUT_SWING",
                            description  = "These bits select the output amplitude (VOD) of the JESD transmitter for all lanes.",
                            offset       =  (masterPage + (4*0x3D)),
                            bitSize      =  3,
                            bitOffset    =  0,
                            base         = "hex",
                            mode         = "RW",
                        ) 

        self.addVariable(  name         = "SYSREF_DEL_LO",
                            description  = "When the SYSREF delay feature is enabled (3Ch, bit 6) the delay can be adjusted in 25-ps steps; the first step is 175 ps. The PVT variation of each 25-ps step is +/-10 ps. The 175-ps step is +/-50 ps",
                            offset       =  (masterPage + (4*0x05A)),
                            bitSize      =  3,
                            bitOffset    =  5,
                            base         = "hex",
                            mode         = "RW",
                        )

        self.addVariable(  name         = "SEL_SYSREF_REG",
                            description  = "0 = SYSREF is logic low, 1 = SYSREF is logic high",
                            offset       =  (masterPage + (4*0x057)),
                            bitSize      =  1,
                            bitOffset    =  4,
                            base         = "hex",
                            mode         = "RW",
                        )  
                        
        self.addVariable(  name         = "ASSERT_SYSREF_REG",
                            description  = "0 = SYSREF is asserted by device pins, 1 = SYSREF can be asserted by the ASSERT SYSREF REG register bit",
                            offset       =  (masterPage + (4*0x057)),
                            bitSize      =  1,
                            bitOffset    =  3,
                            base         = "hex",
                            mode         = "RW",
                        )  
                        
        self.addVariable(  name         = "SYNCB_POL",
                            description  = "0 = Polarity is not inverted, 1 = Polarity is inverted",
                            offset       =  (masterPage + (4*0x058)),
                            bitSize      =  1,
                            bitOffset    =  5,
                            base         = "hex",
                            mode         = "RW",
                        )  
                       
        # ##########
        # # ADC PAGE 
        # ##########
        self.addVariable(  name         = "SLOW_SP_EN1",
                            description  = "0 = ADC sampling rates are faster than 2.5 GSPS, 1 = ADC sampling rates are slower than 2.5 GSPS",
                            offset       =  (analogPage + (4*0x03F)),
                            bitSize      =  1,
                            bitOffset    =  2,
                            base         = "hex",
                            mode         = "RW",
                        )
                        
        self.addVariable(  name         = "SLOW_SP_EN2",
                            description  = "0 = ADC sampling rates are faster than 2.5 GSPS, 1 = ADC sampling rates are slower than 2.5 GSPS",
                            offset       =  (analogPage + (4*0x042)),
                            bitSize      =  1,
                            bitOffset    =  2,
                            base         = "hex",
                            mode         = "RW",
                        )
                        
        ##############################
        # Commands
        ##############################
        def reset(dev, cmd, arg):
            dev.HW_RST.set(0x1)
            time.sleep(0.1)
            dev.HW_RST.set(0x0)
            dev.RESET.set(0x81)
            dev.SPI_CONFIG.set(0x1)
                
        self.addCommand(    name         = "devRst",
                            description  = "device reset",
                            function     = reset
                        )        
