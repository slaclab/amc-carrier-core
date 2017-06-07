#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : AmcCryoCore.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue Cryo Amc Core
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

from surf.devices.ti._Dac38J84 import *
from surf.devices.ti._Lmk04828 import *

from AppHardware.AmcCryo._adc32Rf45 import *

class AmcCryoCore(pr.Device):
    def __init__(   self, 
                    name        = "AmcCryoCore", 
                    description = "Cryo Amc Rf Demo Board Core", 
                    memBase     =  None, 
                    offset      =  0x0, 
                    hidden      =  False,
                    expand      =  True,
                ):
        super(self.__class__, self).__init__(name, description, memBase, offset, hidden, expand=expand)

        
        # self.backdoor = RawBlock(self)
        # self.backdoor.write(0x000,0xFF)
        
        
        #########
        # Devices
        #########
        self.add(Lmk04828( offset=0x00020000,name='LMK',   expand=False))
        self.add(Dac38J84( offset=0x00040000,name='DAC_0', expand=False))
        self.add(Dac38J84( offset=0x00060000,name='DAC_1', expand=False))
        # self.add(Adc32Rf45(offset=0x00080000,name='ADC_0', expand=False))
        # self.add(Adc32Rf45(offset=0x000C0000,name='ADC_1', expand=False))

        
        
        # self.addVariable(  name         = "RESET",
                            # description  = "Send 0x81 value to reset the device",
                            # offset       =  (0x00080000 + (4*0x000)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",
                            # verify       =  False,                            
                            # # hidden       =  True,                            
                        # )
                        
        # # self.addVariable(  name         = "SPI_CONFIG",
                            # # description  = "0 = 4-wire SPI (default), 1 = 3-wire SPI where SDIN become input or output",
                            # # offset       =  (0x00080000 + (4*0x010)),
                            # # bitSize      =  8,
                            # # bitOffset    =  0,
                            # # base         = "hex",
                            # # mode         = "RW",
                            # # # SDOUT pin on ADC32RF45 is not tri-stated when CS is high rendering it useless in a 4wire SPI configuration. 
                            # # # TI has acknowledged this error.  Remove routing to this pin and operate in 3 wire SPI mode (this has been verified to work)
                            # # value        =  0,
                            # # verify       =  False,
                            # # # hidden       =  True,
                        # # )           
         

        # self.addVariable(  name         = "BASE_4",
                            # offset       =  (0x00080000+(0x4<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                              
                            # verify       =  False,
                        # )     

        # self.addVariable(  name         = "BASE_3",
                            # offset       =  (0x00080000+(0x3<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                      
                            # verify       =  False,
                        # ) 

        # self.addVariable(  name         = "BASE_2",
                            # offset       =  (0x00080000+(0x2<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",
                            # verify       =  False,
                        # ) 

        # self.addVariable(  name         = "BASE_10",
                            # offset       =  (0x00080000+(0x10<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                              
                            # verify       =  False,
                        # ) 

        # self.addVariable(  name         = "BASE_11",
                            # offset       =  (0x00080000+(0x11<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                                                
                            # verify       =  False,
                        # ) 

        # self.addVariable(  name         = "BASE_12",
                            # offset       =  (0x00080000+(0x12<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",
                            # verify       =  False,
                        # )   

        # self.addVariable(  name         = "PWR_DET",
                            # offset       =  (0x00080000+(0x5000<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",
                        # )                           
                        
        
        
        # def reset(dev, cmd, arg):
            # dev.RESET.set(0x81)
                
        # self.addCommand(    name         = "devRst",
                            # description  = "device reset",
                            # function     = reset
                        # )                
        
        # self.addVariable(  name         = "TEST4",
                            # offset       =  (0x00080000+(0x4004<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "WO",
                            # verify       =  False,                            
                            # # hidden       =  True,                            
                        # )
                        
        # self.addVariable(  name         = "TEST3",
                            # offset       =  (0x00080000+(0x4003<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "WO",
                            # verify       =  False,                            
                            # # hidden       =  True,                            
                        # ) 

        # self.addVariable(  name         = "TEST2",
                            # offset       =  (0x00080000+(0x4002<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "WO",
                            # verify       =  False,                            
                            # # hidden       =  True,                            
                        # )  
                        
        # self.addVariable(  name         = "TEST1",
                            # offset       =  (0x00080000+(0x4001<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "WO",
                            # verify       =  False,                            
                            # # hidden       =  True,                            
                        # )                          

        # self.addVariable(  name         = "DIGRST",
                            # offset       =  (0x00080000+(0x60A6<<2)),
                            # bitSize      =  8,
                            # bitOffset    =  0,
                            # base         = "hex",
                            # mode         = "RW",                     
                            # verify       =  False,                            
                            # # hidden       =  True,                            
                        # )                          

        # def testCmd(dev, cmd, arg):
            # dev.TEST1.post(0x00)
            # dev.TEST2.post(0x00)
            # dev.TEST3.post(0x00)
            # dev.TEST4.post(0x69)
            # dev.DIGRST.set(0x80)
            # print (dev.DIGRST.get())
            # dev.DIGRST.set(0x00)
            # print (dev.DIGRST.get())   


            # # dev.TEST2.post(0x68)
            # # dev.TEST1.post(0x00)
            # # dev.TEST0.post(0x00)
            # # dev.DIGRST.post(0x07)
            # # print (dev.DIGRST.get())
            # # dev.DIGRST.set(0x01)
            # # print (dev.DIGRST.get())
            # # dev.DIGRST.set(0x00)
            # # print (dev.DIGRST.get())               
                          
        # self.addCommand(    name         = "TestCmd",
                            # function     = testCmd
                        # )        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        # ##########
        # # Commands
        # ##########
        # def initAmcCard(dev, cmd, arg):
            # dev.Lmk04828.PwrUpSysRef.set(1)
            # time.sleep(1)
            # dev.Dac38J84.InitDac.set(1)
            # time.sleep(1)
            # dev.Dac38J84.ClearAlarms.set(1)                
                
        # self.addCommand(    name         = "InitAmcCard",
                            # description  = "Initialization for AMC card's JESD modules",
                            # function     = initAmcCard
                        # )
                        
                        
                        
                        