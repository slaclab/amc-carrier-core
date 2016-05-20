##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

## Get variables and Custom Procedures
set VIVADO_BUILD_DIR $::env(VIVADO_BUILD_DIR)
source -quiet ${VIVADO_BUILD_DIR}/vivado_env_var_v1.tcl
source -quiet ${VIVADO_BUILD_DIR}/vivado_proc_v1.tcl

## Check for version 2015.4 of Vivado
if { [VersionCheck 2015.4] < 0 } {
   close_project
   exit -1
}

## Add the Microblaze Calibration Code
add_files ${TOP_DIR}/modules/AmcCarrierCore/coregen/DebugMigCoreMicroblazeCalibration.elf
set_property SCOPED_TO_REF   {DebugMigCore} [get_files DebugMigCoreMicroblazeCalibration.elf]
set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/microblaze_I} [get_files DebugMigCoreMicroblazeCalibration.elf]

add_files ${TOP_DIR}/modules/AmcCarrierCore/coregen/DebugMigCoreMicroblazeCalibration.bmm
set_property SCOPED_TO_REF   {DebugMigCore} [get_files DebugMigCoreMicroblazeCalibration.bmm]
set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0} [get_files DebugMigCoreMicroblazeCalibration.bmm]

add_files -quiet -fileset sources_1 ${TOP_DIR}/modules/BsaCore/cores/BsaAxiInterconnect/xilinxUltraScale/BsaAxiInterconnect.dcp
