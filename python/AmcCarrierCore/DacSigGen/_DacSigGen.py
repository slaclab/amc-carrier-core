#-----------------------------------------------------------------------------
# Title      : PyRogue Signal generator module
#-----------------------------------------------------------------------------
# File       : DacSigGen.py
# Created    : 2017-04-04
#-----------------------------------------------------------------------------
# Description:
# PyRogue Signal generator module
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
import click
import csv

class DacSigGen(pr.Device):
    def __init__(   self,
            name        = "DacSigGen",
            description = "Signal generator module",
            numOfChs    = 2,
            buffSize    = 0x200,
            fillMode    = False, # False = 16-bit RAM, True = 32-bit RAM
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self._numOfChs = numOfChs
        self._buffSize = (buffSize<<1) if (fillMode) else buffSize

        ##############################
        # Variables
        ##############################
        self.add(pr.RemoteVariable(
            name         = "EnableMask",
            description  = "Mask Enable channels.",
            offset       =  0x00,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "ModeMask",
            description  = "Mask select Mode: 0 - Triggered Mode. 1 - Periodic Mode",
            offset       =  0x04,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "SignFormat",
            description  = "Mask select Sign: 0 - Signed 2's complement, 1 - Offset binary (Currently Applies only to zero data)",
            offset       =  0x08,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(
            name         = "SoftwareTrigger",
            description  = "Mask Software trigger (applies in triggered mode, Internal edge detector)",
            offset       =  0x0C,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
            hidden       = True,
        ))

        self.add(pr.RemoteVariable(
            name         = "Running",
            description  = "Mask Running status",
            offset       =  0x20,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval =  1,
        ))

        self.add(pr.RemoteVariable(
            name         = "Underflow",
            description  = "Mask Underflow status: 16bit to 32bit conversion underflow (applies in 32bit interface).",
            offset       =  0x24,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval =  1,
        ))

        self.add(pr.RemoteVariable(
            name         = "Overflow",
            description  = "Mask Overflow status: 16bit to 32bit conversion underflow (applies in 32bit interface).",
            offset       =  0x28,
            bitSize      =  self._numOfChs,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval =  1,
        ))

        self.add(pr.RemoteVariable(
            name         = "MaxWaveformSize",
            description  = "Max Waveform size (2**ADDR_WIDTH_G)",
            offset       =  0x2C,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RO",
            pollInterval =  1,
        ))

        self.addRemoteVariables(
            name         = "PeriodSize",
            description  = "In Periodic mode: Period size (Zero inclusive). In Triggered mode: Waveform size (Zero inclusive). Separate values for separate channels.",
            offset       =  0x40,
            bitSize      =  32,
            bitOffset    =  0x00,
            base         = pr.UInt,
            mode         = "RW",
            number       =  self._numOfChs,
            stride       =  4,
        )

        for i in range(self._numOfChs):
            self.add(pr.RemoteVariable(
                name         = ('Waveform[%d]' % i),
                description  = "Waveform data 16-bit samples.",
                offset       = 0x01000000 + (i * 0x01000000),
                updateNotify = False,
                bulkOpEn     = False,
                hidden       = True,
                numValues    = self._buffSize,
                valueBits    = 16 if fillMode else 32,
                valueStride  = 16 if fillMode else 32,
                bitSize      = (16*self._buffSize) if fillMode else (32*self._buffSize),
                bitOffset    = 0,
                base         = pr.Int,
            ))

        self.add(pr.LocalVariable(
            name         = "CsvFilePath",
            description  = "Used if command's argument is empty",
            mode         = "RW",
            value        = "",
        ))

        ##############################
        # Commands
        ##############################
        # Define SW trigger command
        @self.command(description="Trigger waveform from software (All channels. Triggered mode).",)
        def SwTrigger():
            trigAllCh = int(2**self._numOfChs)-1
            self.SoftwareTrigger.set(trigAllCh)
            self.SoftwareTrigger.set(0x00)

        @self.command(value='',description="Load the .CSV",)
        def LoadCsvFile(arg):
            # Check if non-empty argument
            if (arg != ""):
                path = arg
            else:
                # Use the variable path instead
                path = self.CsvFilePath.get()

            # Open the .CSV file
            with open(path) as csvfile:
                reader = csv.reader(csvfile, delimiter=',', quoting=csv.QUOTE_NONE)
                idx     = 0
                cnt     = 0
                csvData = []
                # Loop through the rows in the CSV file
                for row in reader:
                    if ( idx<self._buffSize ):
                        entry = []
                        for ch in range(self._numOfChs):
                            entry.append(row[ch])
                        csvData.append(entry)
                        # Increment the counter
                        idx  += 1
                    # Increment the counter
                    cnt  += 1
                # User friendly print message
                click.secho( ('LoadCsvFile(): %d samples per channel found' % idx ), fg='green')
                if ( cnt>idx ):
                    click.secho( ('\tHowever %d of samples detected in the CSV file' % cnt ), fg='red')
                    click.secho( ('\tCSV data dropped because firmware only support up to %d samples' % idx ), fg='red')
                # Check for 32-bit fill mode and odd number of samples
                if (fillMode) and ( (cnt%2) == 1 ):
                    csvData.append(csvData[cnt-1])
                    cnt += 1
                # Get the current enable mask value
                enableMask = self.EnableMask.get()
                # Reset the enable mask during the load
                self.EnableMask.set(0x0)
                # Loop through the channels
                for ch in range(self._numOfChs):
                    data = []
                    for row in csvData:
                        data.append(int(row[ch]))

                    self.Waveform[ch].set(0x000000000,data,write=True)

                    v = getattr(self, 'PeriodSize[%i]'%ch)
                    v.set(((cnt>>1)-1) if (fillMode) else (cnt-1))

                # Restore the enable mask value
                self.EnableMask.set(enableMask)
