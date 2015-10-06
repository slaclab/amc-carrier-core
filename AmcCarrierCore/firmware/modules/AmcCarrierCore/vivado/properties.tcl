
## Get variables and Custom Procedures
set VIVADO_BUILD_DIR $::env(VIVADO_BUILD_DIR)
source -quiet ${VIVADO_BUILD_DIR}/vivado_env_var_v1.tcl
source -quiet ${VIVADO_BUILD_DIR}/vivado_proc_v1.tcl

## Check for version 2015.2 of Vivado
if { [VersionCheck 2015.2] < 0 } {
   close_project
   exit -1
}

# ## Add the Microblaze Calibration Code
# add_files ${PROJ_DIR}/../../modules/AmcCarrierCore/coregen/MigCoreMicroblazeCalibration.elf
# set_property SCOPED_TO_REF   {MigCore} [get_files MigCoreMicroblazeCalibration.elf]
# set_property SCOPED_TO_CELLS {U_Core/U_DdrMem/MigCore_Inst/inst/u_ddr_cal_riu/mcs0/microblaze_I} [get_files MigCoreMicroblazeCalibration.elf]
