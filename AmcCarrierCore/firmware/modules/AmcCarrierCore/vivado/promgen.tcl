##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 AMC Carrier Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################
set format     "mcs"
set inteface   "SPIx1"
set size       "1024"

set FSBL_BIT    "0x00000000"
set LCLS_I_BIT  "0x02000000"
set LCLS_II_BIT "0x04000000"
set TEMP_BIT    "0x06000000"

set FSBL_GZ    "0x00F43EFC"
set LCLS_I_GZ  "0x02F43EFC"
set LCLS_II_GZ "0x04F43EFC"
set TEMP_GZ    "0x06F43EFC"

set BIT_PATH   "$::env(IMPL_DIR)/$::env(PROJECT).bit"
set DATA_PATH  "$::env(IMAGES_DIR)/$::env(PROJECT)_$::env(PRJ_VERSION).tar.gz"
