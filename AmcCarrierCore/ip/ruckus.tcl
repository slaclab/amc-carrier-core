# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource -path "$::DIR_PATH/SysMonCore/SysMonCore.dcp"
# loadIpCore -path "$::DIR_PATH/SysMonCore/SysMonCore.xci"

loadSource -path "$::DIR_PATH/MigCore/MigCore.dcp"
# loadIpCore -path "$::DIR_PATH/MigCore/MigCore.xci"

# Check for Application Microblaze build
if { [expr [info exists ::env(SDK_SRC_PATH)]] == 0 } {
   ## Add the Microblaze Calibration Code
   add_files -norecurse $::DIR_PATH/MigCore/MigCoreMicroblazeCalibration.elf
   set_property SCOPED_TO_REF   {MigCore}                                                  [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.elf}]
   set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/U0/microblaze_I} [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.elf}]

   add_files -norecurse $::DIR_PATH/MigCore/MigCoreMicroblazeCalibration.bmm
   set_property SCOPED_TO_REF   {MigCore}                                     [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.bmm}]
   set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/U0} [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.bmm}]
}

loadConstraints -path "$::DIR_PATH/MigCore/MigCore.xdc"
set_property PROCESSING_ORDER {EARLY}   [get_files {MigCore.xdc}]
set_property SCOPED_TO_REF    {MigCore} [get_files {MigCore.xdc}]
set_property SCOPED_TO_CELLS  {inst}    [get_files {MigCore.xdc}]

loadConstraints -path "$::DIR_PATH/MigCore/bd_f4f9_microblaze_I_0.xdc"
set_property PROCESSING_ORDER {EARLY}   [get_files {bd_f4f9_microblaze_I_0.xdc}]
set_property SCOPED_TO_REF    {MigCore} [get_files {bd_f4f9_microblaze_I_0.xdc}]
set_property SCOPED_TO_CELLS  {U0}      [get_files {bd_f4f9_microblaze_I_0.xdc}]

loadConstraints -path "$::DIR_PATH/MigCore/bd_f4f9_rst_0_0.xdc"
set_property PROCESSING_ORDER {EARLY}           [get_files {bd_f4f9_rst_0_0.xdc}]
set_property SCOPED_TO_REF    {bd_f4f9_rst_0_0} [get_files {bd_f4f9_rst_0_0.xdc}]
set_property SCOPED_TO_CELLS  {U0}              [get_files {bd_f4f9_rst_0_0.xdc}]

loadConstraints -path "$::DIR_PATH/MigCore/bd_f4f9_ilmb_0.xdc"
set_property PROCESSING_ORDER {EARLY}          [get_files {bd_f4f9_ilmb_0.xdc}]
set_property SCOPED_TO_REF    {bd_f4f9_ilmb_0} [get_files {bd_f4f9_ilmb_0.xdc}]
set_property SCOPED_TO_CELLS  {U0}             [get_files {bd_f4f9_ilmb_0.xdc}]

loadConstraints -path "$::DIR_PATH/MigCore/bd_f4f9_dlmb_0.xdc"
set_property PROCESSING_ORDER {EARLY}          [get_files {bd_f4f9_dlmb_0.xdc}]
set_property SCOPED_TO_REF    {bd_f4f9_dlmb_0} [get_files {bd_f4f9_dlmb_0.xdc}]
set_property SCOPED_TO_CELLS  {U0}             [get_files {bd_f4f9_dlmb_0.xdc}]
