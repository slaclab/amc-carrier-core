
## Get variables and Custom Procedures
set VIVADO_BUILD_DIR $::env(VIVADO_BUILD_DIR)
source -quiet ${VIVADO_BUILD_DIR}/vivado_env_var_v1.tcl
source -quiet ${VIVADO_BUILD_DIR}/vivado_proc_v1.tcl

## Check for version 2015.3 of Vivado
if { [VersionCheck 2015.3] < 0 } {
   close_project
   exit -1
}

## Add the Microblaze Calibration Code
add_files ${PROJ_DIR}/../../modules/AmcCarrierCore/coregen/MigCoreMicroblazeCalibration.elf
set_property SCOPED_TO_REF   {MigCore} [get_files MigCoreMicroblazeCalibration.elf]
set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/microblaze_I} [get_files MigCoreMicroblazeCalibration.elf]

add_files ${PROJ_DIR}/../../modules/AmcCarrierCore/coregen/MigCoreMicroblazeCalibration.bmm
set_property SCOPED_TO_REF   {MigCore} [get_files MigCoreMicroblazeCalibration.bmm]
set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0} [get_files MigCoreMicroblazeCalibration.bmm]
