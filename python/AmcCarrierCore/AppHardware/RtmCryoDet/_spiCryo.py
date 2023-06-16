#-----------------------------------------------------------------------------
# Title      : PyRogue CRYO RTM: SPI CRYO
#-----------------------------------------------------------------------------
# File       : _spiCryo.py
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

class SpiCryo(pr.Device):
    def __init__(   self,
            name        = "SpiCryo",
            description = "SpiCryo module",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        ## ## _rawWrite/_rawRead
        ## self.write_address = 0x0
        ## self.read_address  = 0x4
        ##
        ## self.relay_address = 0x2
        ## self.hemt_bias_address = 0x3
        ## self.a50K_bias_address = 0x4
        ## self.temperature_address = 0x5
        ## self.cycle_count_address = 0x6  # used for testing
        ## self.ps_en_address = 0x7 # PS enable (HEMT: bit 0, 50k: bit 1)
        ## self.ac_dc_status_address = 0x8 # AC/DC mode status (bit 0: FRN_RLY, bit 1: FRP_RLY)
        ## self.adc_scale = 3.3/(1024.0 * 5)
        ## self.temperature_scale = 1/.028 # was 100
        ## self.temperature_offset =.25
        ## self.bias_scale = 1.0
        ## self.max_retries = 5  #number of re-tries waiting for response
        ## self.retry = 0 # counts nubmer of retries
        ## self.busy_retry = 0  # counts number of retries due to relay busy status

        self.add(pr.RemoteVariable(
            name        = "write",
            description = "write - 32 bits",
            offset      = 0x0,
            bitSize     = 32,
            base        = pr.UInt,
            mode        = "WO",
            hidden      = True,
        ))

        self.add(pr.RemoteVariable(
            name        = "read",
            description = "read - 32 bits",
            offset      = 0x4,
            bitSize     = 32,
            base        = pr.UInt,
            mode        = "RO",
            hidden      = True,
        ))

        ## 6/12/23 - SWH commented out ; someone started trying to
        ## move cryostat card interface into rogue but not working.
        ## Good idea, leaving to maybe complete later.
        ##
        ## self.add(pr.LinkVariable(
        ##     name         = "temperature",
        ##     description  = "temperature",
        ##     dependencies = [],
        ##     linkedGet    = lambda dev, var, read: dev.read_temperature(dev, var, read),
        ##     typeStr      = "Float64",
        ##     mode         = "RO",
        ## ))
        ##
        ## self.add(pr.LinkVariable(
        ##     name         = "50kBias",
        ##     description  = "temperature",
        ##     dependencies = [],
        ##     linkedGet    = lambda dev, var, read: dev.read_50k_bias(dev, var, read),
        ##     typeStr      = "Float64",
        ##     mode         = "RO",
        ## ))
        ##
        ## self.add(pr.LinkVariable(
        ##     name         = "hemtBias",
        ##     description  = "hemtBias",
        ##     dependencies = [],
        ##     linkedGet    = lambda dev, var, read: dev.read_hemt_bias(dev, var, read),
        ##     typeStr      = "Float64",
        ##     mode         = "RO",
        ## ))

    ## 6/12/23 - SWH commented out ; someone started trying to
    ## move cryostat card interface into rogue but not working.
    ## Good idea, leaving to maybe complete later.
    ##
    ## def cmd_read(self, data):  # checks for a read bit set in data
    ##     return ( (data & 0x80000000) != 0)
    ##
    ## def cmd_address(self, data): # returns address data
    ##     return ((data & 0x7FFF0000) >> 20)
    ##
    ## def cmd_data(self, data):  # returns data
    ##     return (data & 0xFFFFF)
    ##
    ## def cmd_make(self, read, address, data):
    ##     return ((read << 31) | ((address << 20) & 0x7FFF00000) | (data & 0xFFFFF))
    ##
    ## def do_read(self, address):
    ##     #need double write to make sure buffer is updated
    ##     self._rawWrite(self.write_address, self.cmd_make(1, address, 0))
    ##     for self.retry in range(0, self.max_retries):
    ##         self._rawWrite(self.write_address, self.cmd_make(1, address, 0))
    ##         data = self._rawRead(self.read_address)
    ##         addrrb = self.cmd_address(data)
    ##         if (addrrb == address):
    ##             return (data)
    ##     return (0)
    ##
    ## @staticmethod
    ## def read_temperature(dev, var, read):
    ##     data = dev.do_read(dev.temperature_address)
    ##     volts = (data & 0xFFFFF) * dev.adc_scale
    ##     return round(((volts - dev.temperature_offset) * dev.temperature_scale),2)
    ##
    ## @staticmethod
    ## def write_relays(dev, var, value):  # relay is the bit partern to set
    ##     dev._rawWrite(dev.write_address, dev.cmd_make(0, dev.relay_address, value))
    ##     time.sleep(0.1)
    ##     dev._rawWrite(dev.write_address, dev.cmd_make(0, dev.relay_address, value))
    ##
    ## @staticmethod
    ## def read_relays(dev, var, read):
    ##     for dev.busy_retry in range(0, dev.max_retries):
    ##         data = dev.do_read(dev.relay_address)
    ##         if ~(data & 0x80000):  # check that not moving
    ##             return (data & 0x7FFFF)
    ##             time.sleep(0.1) # wait for relays to move
    ##     return (80000) # busy flag still set
    ##
    ## @staticmethod
    ## def read_hemt_bias(dev, var, read):
    ##     data = dev.do_read(dev.hemt_bias_address)
    ##     return round(((data& 0xFFFFF) * dev.bias_scale * dev.adc_scale),6)
    ##
    ## @staticmethod
    ## def read_50k_bias(dev, var, read):
    ##     data = dev.do_read(dev.a50K_bias_address)
    ##     return round(((data& 0xFFFFF) * dev.bias_scale * dev.adc_scale), 6)
