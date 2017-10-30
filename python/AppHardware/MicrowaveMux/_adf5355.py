#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : _adf5355.py
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

class Adf5355(pr.Device):
    def __init__(   self, 
            name        = "Adf5355", 
            description = "Adf5355 module", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
                        
        # ##############################    
        # ###     Register 0         ###
        # ##############################
        # self.add(pr.RemoteVariable(   
            # name         = "AUTOCAL",
            # description  = "Automatic Calibration",
            # offset       =  (0x0 << 2), # Register 0
            # bitSize      =  1,
            # bitOffset    =  21,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  

        # self.add(pr.RemoteVariable(   
            # name         = "PRESCALER",
            # description  = "Prescaler Value",
            # offset       =  (0x0 << 2), # Register 0
            # bitSize      =  1,
            # bitOffset    =  20,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))    

        # self.add(pr.RemoteVariable(   
            # name         = "Integer16bValue",
            # description  = "16-Bit Integer Value",
            # offset       =  (0x0 << 2), # Register 0
            # bitSize      =  16,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))            
       
        # ##############################    
        # ###     Register 1         ###
        # ##############################       
        # self.add(pr.RemoteVariable(   
            # name         = "FRAC1",
            # description  = "24-Bit Main Fractional Value",
            # offset       =  (0x1 << 2), # Register 1
            # bitSize      =  24,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))    

        # ##############################    
        # ###     Register 2         ###
        # ##############################       
        # self.add(pr.RemoteVariable(   
            # name         = "FRAC2",
            # description  = "14-Bit Auxiliary Fractional Value",
            # offset       =  (0x2 << 2), # Register 2
            # bitSize      =  14,
            # bitOffset    =  18,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))            
       
        # self.add(pr.RemoteVariable(   
            # name         = "MOD2",
            # description  = "14-Bit Auxiliary Modulus Value",
            # offset       =  (0x2 << 2), # Register 2
            # bitSize      =  14,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))            
              
        # ##############################    
        # ###     Register 3         ###
        # ##############################           
        # self.add(pr.RemoteVariable(   
            # name         = "SDLoadReset",
            # description  = "SD Load Reset",
            # offset       =  (0x3 << 2), # Register 3
            # bitSize      =  1,
            # bitOffset    =  30,
            # base         = pr.UInt,
            # mode         = "RW",
        # )) 

        # self.add(pr.RemoteVariable(   
            # name         = "PhaseResync",
            # description  = "phase resynchronization",
            # offset       =  (0x3 << 2), # Register 3
            # bitSize      =  1,
            # bitOffset    =  29,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  

        # self.add(pr.RemoteVariable(   
            # name         = "PhaseAdjust",
            # description  = "Phase Adjust",
            # offset       =  (0x3 << 2), # Register 3
            # bitSize      =  1,
            # bitOffset    =  28,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))          
       
        # self.add(pr.RemoteVariable(   
            # name         = "PHASE",
            # description  = "24-Bit Phase Value",
            # offset       =  (0x3 << 2), # Register 3
            # bitSize      =  24,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))         
       
        # ##############################    
        # ###     Register 4         ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "MUXOUT",
            # description  = "on-chip multiplexer",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  3,
            # bitOffset    =  27,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))   

        # self.add(pr.RemoteVariable(   
            # name         = "ReferenceDoubler",
            # description  = "Reference Doubler",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  26,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  

        # self.add(pr.RemoteVariable(   
            # name         = "RDIV2",
            # description  = "RDIV2",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  25,
            # base         = pr.UInt,
            # mode         = "RW",
        # )) 

        # self.add(pr.RemoteVariable(   
            # name         = "RCounter",
            # description  = "10-Bit R Counter",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  10,
            # bitOffset    =  15,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))         
       
        # self.add(pr.RemoteVariable(   
            # name         = "DoubleBuffer",
            # description  = "Double Buffer",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  14,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))    
       
        # self.add(pr.RemoteVariable(   
            # name         = "ChargePumpCurrent",
            # description  = "Charge Pump Current Setting",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  4,
            # bitOffset    =  10,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))            
       
        # self.add(pr.RemoteVariable(   
            # name         = "RefMode",
            # description  = "Reference Mode",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  9,
            # base         = pr.UInt,
            # mode         = "RW",
        # )) 
        
        # self.add(pr.RemoteVariable(   
            # name         = "MuxLogic",
            # description  = "MuxLogic",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  8,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))   
        
        # self.add(pr.RemoteVariable(   
            # name         = "PhaseDetPolarity",
            # description  = "Phase Detector Polarity",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  7,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))            
        
        # self.add(pr.RemoteVariable(   
            # name         = "PowerDown",
            # description  = "Power-Down",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  6,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))    
        
        # self.add(pr.RemoteVariable(   
            # name         = "ChargePumpTri",
            # description  = "Charge Pump Three-State",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  5,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))            
        
        # self.add(pr.RemoteVariable(   
            # name         = "CounterReset",
            # description  = "Counter Reset",
            # offset       =  (0x4 << 2), # Register 4
            # bitSize      =  1,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # )) 
        
        
        # ##############################    
        # ###     Register 5         ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "REG5_RESERVED",
            # description  = "The bits in Register 5 are reserved and must be programmed with 0x00800025",
            # offset       =  (0x5 << 2), # Register 5
            # bitSize      =  32,
            # bitOffset    =  0,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0x00800025,
        # ))   
        
        # ##############################    
        # ###     Register 6         ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "GatedBleed",
            # description  = "Gated Bleed",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  1,
            # bitOffset    =  30,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))   

        # self.add(pr.RemoteVariable(   
            # name         = "NegativeBleed",
            # description  = "Negative Bleed",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  1,
            # bitOffset    =  29,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))           
        
        # self.add(pr.RemoteVariable(   
            # name         = "REG6_RESERVED",
            # description  = "REG6_RESERVED[27:25] = 0xA",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  4,
            # bitOffset    =  25,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0xA,
        # ))          
        
        # self.add(pr.RemoteVariable(   
            # name         = "FeedbackSelect",
            # description  = "Feedback Select",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  1,
            # bitOffset    =  24,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  

        # self.add(pr.RemoteVariable(   
            # name         = "DividerSelect",
            # description  = "Divider Select",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  3,
            # bitOffset    =  21,
            # base         = pr.UInt,
            # mode         = "RW",
        # )) 

        # self.add(pr.RemoteVariable(   
            # name         = "ChargePumpBleedCurrent",
            # description  = "Charge Pump Bleed Current",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  8,
            # bitOffset    =  13,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))         
        
        # self.add(pr.RemoteVariable(   
            # name         = "MuteTillLockDetect",
            # description  = "Mute Till Lock Detect",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  1,
            # bitOffset    =  11,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  
        
        # self.add(pr.RemoteVariable(   
            # name         = "RFOutputBEnable",
            # description  = "RF Output B Enable",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  1,
            # bitOffset    =  10,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))   

        # self.add(pr.RemoteVariable(   
            # name         = "RFOutputAEnable",
            # description  = "RF Output A Enable",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  1,
            # bitOffset    =  6,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))           
        
        # self.add(pr.RemoteVariable(   
            # name         = "OutputPower",
            # description  = "Output Power",
            # offset       =  (0x6 << 2), # Register 6
            # bitSize      =  2,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))           
        
        # ##############################    
        # ###     Register 7         ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "REG7_RESERVED",
            # description  = "REG7_RESERVED[31:26] = 0x4",
            # offset       =  (0x7 << 2), # Register 7
            # bitSize      =  6,
            # bitOffset    =  26,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0x4,
        # ))          
        
        # self.add(pr.RemoteVariable(   
            # name         = "LESync",
            # description  = "LE Sync",
            # offset       =  (0x7 << 2), # Register 7
            # bitSize      =  1,
            # bitOffset    =  25,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))   

        # self.add(pr.RemoteVariable(   
            # name         = "LockDetectCount",
            # description  = "Lock Detect Count",
            # offset       =  (0x7 << 2), # Register 7
            # bitSize      =  2,
            # bitOffset    =  8,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))           
        
        # self.add(pr.RemoteVariable(   
            # name         = "LossOfLockMode",
            # description  = "Loss of Lock Mode",
            # offset       =  (0x7 << 2), # Register 7
            # bitSize      =  1,
            # bitOffset    =  7,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))          

        # self.add(pr.RemoteVariable(   
            # name         = "LockDetectPrecision",
            # description  = "Fractional-N Lock Detect Precision",
            # offset       =  (0x7 << 2), # Register 7
            # bitSize      =  2,
            # bitOffset    =  5,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  
        
        # self.add(pr.RemoteVariable(   
            # name         = "LockDetectMode",
            # description  = "Lock Detect Mode",
            # offset       =  (0x7 << 2), # Register 7
            # bitSize      =  1,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  

        # ##############################    
        # ###     Register 8         ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "REG8_RESERVED",
            # description  = "The bits in Register 8 are reserved and must be programmed with 0x102D0428",
            # offset       =  (0x8 << 2), # Register 8
            # bitSize      =  32,
            # bitOffset    =  0,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0x102D0428,
        # ))   

        # ##############################    
        # ###     Register 9         ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "VcoBandDivision",
            # description  = "VCO Band Division",
            # offset       =  (0x9 << 2), # Register 9
            # bitSize      =  8,
            # bitOffset    =  24,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))  
        
        # self.add(pr.RemoteVariable(   
            # name         = "Timeout",
            # description  = "Timeout",
            # offset       =  (0x9 << 2), # Register 9
            # bitSize      =  10,
            # bitOffset    =  14,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))   
        
        # self.add(pr.RemoteVariable(   
            # name         = "AutomaticLevelCalibrationTimeout",
            # description  = "Automatic Level Calibration Timeout",
            # offset       =  (0x9 << 2), # Register 9
            # bitSize      =  5,
            # bitOffset    =  9,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))     
        
        # self.add(pr.RemoteVariable(   
            # name         = "SynthesizerLockTimeout",
            # description  = "Synthesizer Lock Timeout",
            # offset       =  (0x9 << 2), # Register 9
            # bitSize      =  5,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))             

        # ##############################    
        # ###     Register 10        ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "REG10_RESERVED",
            # description  = "REG10_RESERVED[31:14] = 0x300",
            # offset       =  (0xA << 2), # Register 10
            # bitSize      =  18,
            # bitOffset    =  14,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0x300,
        # ))            

        # self.add(pr.RemoteVariable(   
            # name         = "ADC_CLK_DIV",
            # description  = "ADC Conversion Clock Divide",
            # offset       =  (0xA << 2), # Register 10
            # bitSize      =  8,
            # bitOffset    =  6,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))    

        # self.add(pr.RemoteVariable(   
            # name         = "ADCConversionEnable",
            # description  = "ADC Conversion Enable",
            # offset       =  (0xA << 2), # Register 10
            # bitSize      =  1,
            # bitOffset    =  5,
            # base         = pr.UInt,
            # mode         = "RW",
        # )) 

        # self.add(pr.RemoteVariable(   
            # name         = "ADCEnable",
            # description  = "ADC Enable",
            # offset       =  (0xA << 2), # Register 10
            # bitSize      =  1,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))         

        # ##############################    
        # ###     Register 11        ###
        # ##############################          
        # self.add(pr.RemoteVariable(   
            # name         = "REG11_RESERVED",
            # description  = "The bits in Register 11 are reserved and must be programmed with 0x0061300B",
            # offset       =  (0xB << 2), # Register 11
            # bitSize      =  32,
            # bitOffset    =  0,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0x0061300B,
        # ))           
        
        # ##############################    
        # ###     Register 12        ###
        # ##############################           
        # self.add(pr.RemoteVariable(   
            # name         = "PhaseResyncClockDivider",
            # description  = "Phase Resync Clock Divider",
            # offset       =  (0xC << 2), # Register 12
            # bitSize      =  16,
            # bitOffset    =  16,
            # base         = pr.UInt,
            # mode         = "RW",
        # ))           
        
        # self.add(pr.RemoteVariable(   
            # name         = "REG12_RESERVED",
            # description  = "REG12_RESERVED[15:4] = 0x41",
            # offset       =  (0xC << 2), # Register 12
            # bitSize      =  12,
            # bitOffset    =  4,
            # base         = pr.UInt,
            # mode         = "RW",
            # value        = 0x41,
        # ))

        self.addRemoteVariables(   
            name         = "REG",
            description  = "",
            offset       =  0x0,
            bitSize      =  32,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
            number       =  13,
            stride       =  4,
        )        
           
        @self.command(name= "RegInitSeq", description  = "refer to REGISTER INITIALIZATION SEQUENCE section of datasheet")        
        def RegInitSeq(): 
            # print ('Adf5355.RegInitSeq()')
                        
            # Initial Sequence
            for i in range( 12, 0, -1 ): 
                self.REG[i].set(self.REG[i].get())
            self.REG[0].set(self.REG[0].get() & 0xFFDFFFFF)
            
            # Frequency Update Sequence
            self.REG[6].set(self.REG[6].get())
            self.REG[4].set(self.REG[4].get() | 0x00000010)
            self.REG[2].set(self.REG[2].get())   
            self.REG[1].set(self.REG[1].get())   
            self.REG[0].set(self.REG[0].get() & 0xFFDFFFFF)
            self.REG[4].set(self.REG[4].get() & 0xFFFFFFEF)
            time.sleep(0.001)
            self.REG[0].set(self.REG[0].get() | 0x00200000)
     