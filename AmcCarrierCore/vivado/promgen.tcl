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

# Define the CPSW tarball path
set DATA_PATH  "$::env(IMAGES_DIR)/$::env(IMAGENAME).cpsw.tar.gz"

# Defined the CPSW.TAR.GZ file base address locations
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
   set LCLS_II_CPSW "0x04F43EFC"
} elseif { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} } {
   set LCLS_II_CPSW "0x05701DEC"
} elseif { $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {            
   set LCLS_II_CPSW "0x0622ED24"
} elseif { $::env(PRJ_PART) eq {XCKU11P-FFVA1156-3-E} } {  
   set LCLS_II_CPSW "0x0567D0EC"
} elseif { $::env(PRJ_PART) eq {XCKU15P-FFVA1156-3-E} } {              
   set LCLS_II_CPSW "0x062A8D48"
} else { 
   puts "\n\nERROR: Invalid PRJ_PART was defined in the Makefile\n\n"; exit -1
}

# Setup the .BIT file and user file configurations
set loadbit  "up ${LCLS_II_BIT}  ${BIT_PATH}"
set loaddata "up ${LCLS_II_CPSW} ${DATA_PATH}"
