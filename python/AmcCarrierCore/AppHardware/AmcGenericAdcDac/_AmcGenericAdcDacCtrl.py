#-----------------------------------------------------------------------------
# Title      : PyRogue Cryo Amc Core
#-----------------------------------------------------------------------------
# File       : _AmcGenericAdcDacCtrl.py
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

class AmcGenericAdcDacCtrl(pr.Device):
    def __init__(   self, 
            name        = "AmcGenericAdcDacCtrl", 
            description = "Debugging module", 
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
                        
        self.addRemoteVariables( 
            name         = "AdcValidCnt",
            description  = "ADC Valid Transition Counter[3:0]",
            offset       = 0x00,
            bitSize      = 32,            
            number       = 4,
            stride       = 4,
            mode         = "RO",
            pollInterval = 1,
        )

        self.add(pr.RemoteVariable( 
            name         = "AdcValid",
            description  = "ADC Valid[3:0]",
            offset       = 0x0FC,
            bitSize      = 4,
            mode         = "RO",
            pollInterval = 1,
        ))          
        
        self.addRemoteVariables(   
            name         = "AdcData",
            description  = "ADC Data[3:0]",
            offset       =  0x100,
            bitSize      =  16,
            mode         = "RO",
            number       =  4,
            stride       =  4,
            pollInterval = 1,
        )     

        self.addRemoteVariables(   
            name         = "DacData",
            description  = "DAC Data[1:0]",
            offset       =  0x110,
            bitSize      =  16,
            mode         = "RO",
            number       =  2,
            stride       =  4,
            pollInterval = 1,
        )             
        
        self.add(pr.RemoteVariable( 
            name         = "VcoDac",
            description  = "VCO's DAC Value",
            offset       = 0x1F8,
            bitSize      = 16,
            mode         = "RO",
            pollInterval = 1,
        ))          
        
        self.add(pr.RemoteVariable( 
            name         = "AmcClkFreq",
            description  = "AMC Clock frequency",
            offset       = 0x1FC,
            bitSize      = 32,
            mode         = "RO",
            units        = "Hz",
            disp         = '{:d}',
            pollInterval = 1,
        ))          
                
        self.add(pr.RemoteVariable( 
            name         = "LmkClkSel",
            description  = "LMK Clock Select",
            offset       = 0x200,
            bitSize      = 2,
            bitOffset    = 0,
            mode         = "RW",
        ))   
                
        self.add(pr.RemoteVariable( 
            name         = "LmkRst",
            description  = "LMK Reset",
            offset       = 0x204,
            bitSize      = 1,
            mode         = "RW",
        ))   
                
        self.add(pr.RemoteVariable( 
            name         = "LmkSync",
            description  = "LMK SYNC",
            offset       = 0x208,
            bitSize      = 1,
            mode         = "RW",
        ))           
        
        self.add(pr.RemoteVariable( 
            name         = "LmkStatus",
            description  = "LMK Status",
            offset       = 0x20C,
            bitSize      = 2,
            mode         = "RO",
            pollInterval = 1,
        ))   
        
        self.add(pr.RemoteVariable( 
            name         = "LmkMuxSel",
            description  = "LMK Clock MUX Select",
            offset       = 0x214,
            bitSize      = 1,
            mode         = "RW",
        )) 

        self.add(pr.RemoteVariable( 
            name         = "VcoDacSckConfig",
            description  = "VCO DAC SCK Rate Configuration",
            offset       = 0x220,
            bitSize      = 16,
            mode         = "RW",
        ))         
        
        self.add(pr.RemoteVariable( 
            name         = "VcoDacEnable",
            description  = "VCO DAC Enable",
            offset       = 0x224,
            bitSize      = 1,
            mode         = "RW",
        ))   
        
        self.add(pr.RemoteVariable( 
            name         = "RollOverEn",
            description  = "Enable Status counter roll over",
            offset       = 0x3F8,
            bitSize      = 4,
            mode         = "RW",
        ))           

        self.add(pr.RemoteCommand(   
            name         = 'CntRst',
            description  = 'Status counter reset',
            offset       = 0x3FC,
            bitSize      = 1,
            function     = pr.BaseCommand.touchOne
        ))        
        
    def countReset(self):
        self.CntRst()