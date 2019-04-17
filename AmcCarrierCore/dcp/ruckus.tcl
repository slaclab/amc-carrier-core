# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(PROJ_DIR)/../../../surf
loadRuckusTcl $::env(PROJ_DIR)/../../../lcls-timing-core
loadRuckusTcl $::env(PROJ_DIR)/../../BsaCore

# Load target's source code and constraints
loadSource      -dir  "$::DIR_PATH/hdl/"
loadConstraints -path "$::DIR_PATH/hdl/AmcCarrierCore.xdc"
set_property PROCESSING_ORDER EARLY [get_files "$::DIR_PATH/hdl/AmcCarrierCore.xdc"]
loadSource      -path "$::DIR_PATH/../core/AmcCarrierPkg.vhd"
loadSource      -path "$::DIR_PATH/../core/AmcCarrierSysRegPkg.vhd"
loadSource      -dir  "$::DIR_PATH/../core/kintexu"
loadSource      -path "$::DIR_PATH/../core/FpgaType/FpgaTypePkg_XCKU040.vhd"

loadSource -path "$::DIR_PATH/../ip/MigCore.dcp"
#loadIpCore  -path "$::DIR_PATH/../ip/MigCore.xci" 

## Add the Microblaze Calibration Code
add_files -norecurse $::DIR_PATH/../ip/MigCoreMicroblazeCalibration.elf
set_property SCOPED_TO_REF   {MigCore}                                                  [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.elf}]
set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/U0/microblaze_I} [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.elf}]

add_files -norecurse $::DIR_PATH/../ip/MigCoreMicroblazeCalibration.bmm
set_property SCOPED_TO_REF   {MigCore}                                     [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.bmm}]
set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/U0} [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.bmm}]

## Place and Route strategies 
set_property strategy Performance_Explore [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

## Skip the utilization check during placement
set_param place.skipUtilizationCheck 1

set_property XPM_LIBRARIES XPM_MEMORY [current_project]
