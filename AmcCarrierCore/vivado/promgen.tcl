##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 AMC Carrier Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# PROM Configurations
set format     "mcs"
set inteface   "SPIx1"
set size       "1024"

# .BIT file locations
set FSBL_BIT    "0x00000000"
set LCLS_II_BIT "0x04000000"

# File Paths
set BIT_PATH   "$::env(IMPL_DIR)/$::env(PROJECT).bit"
