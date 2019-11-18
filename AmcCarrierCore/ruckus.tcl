# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

# Load local Source Code and constraints
loadSource -lib amc_carrier_core -dir  "$::DIR_PATH/core"
loadSource -lib amc_carrier_core -dir  "$::DIR_PATH/core/${family}"

loadSource -lib amc_carrier_core -path "$::DIR_PATH/ip/SysMonCore.dcp"
# loadIpCore -path "$::DIR_PATH/ip/SysMonCore.xci"

loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierCorePorts.xdc"    
loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCoreTiming.xdc" 
loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCorePlacement.xdc" 
loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierAppPorts.xdc" 

# Check for FSBL
if { [info exists ::env(AMC_FSBL)] == 1 }  {

   loadSource -lib amc_carrier_core      -dir "$::DIR_PATH/fsbl"
   loadSource -lib amc_carrier_core      -dir "$::DIR_PATH/fsbl/${family}"
   loadConstraints -dir "$::DIR_PATH/fsbl/${family}"
   
} else {   

   loadSource -lib amc_carrier_core -dir "$::DIR_PATH/non-fsbl"
   
   # Check if using zone2 or zone3 ETH interface
   if {  $::env(RTM_ETH)  == 1 } {
      loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierCoreZone3Eth.xdc" 
   } else {
      loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierCoreZone2Eth.xdc" 
   }
   
}

# Load the FpgaTypePkg.vhd
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
   loadSource -lib amc_carrier_core -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU040.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} } {
   loadSource -lib amc_carrier_core -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU060.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {            
   loadSource -lib amc_carrier_core -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU095.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} } {  
   loadSource -lib amc_carrier_core -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU11P.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {              
   loadSource -lib amc_carrier_core -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU15P.vhd"
} else { 
}

loadSource -lib amc_carrier_core   -path "$::DIR_PATH/ip/MigCore.dcp"
# loadIpCore -path "$::DIR_PATH/ip/MigCore.xci"

# Check for Application Microblaze build
if { [expr [info exists ::env(SDK_SRC_PATH)]] == 0 } {
   ## Add the Microblaze Calibration Code
   add_files -norecurse $::DIR_PATH/ip/MigCoreMicroblazeCalibration.elf
   set_property SCOPED_TO_REF   {MigCore}                                                  [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.elf}]
   set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/U0/microblaze_I} [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.elf}]

   add_files -norecurse $::DIR_PATH/ip/MigCoreMicroblazeCalibration.bmm
   set_property SCOPED_TO_REF   {MigCore}                                     [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.bmm}]
   set_property SCOPED_TO_CELLS {inst/u_ddr3_mem_intfc/u_ddr_cal_riu/mcs0/U0} [get_files -all -of_objects [get_fileset sources_1] {MigCoreMicroblazeCalibration.bmm}]
}

# Place and Route strategies 
set_property strategy Performance_Explore [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Skip the utilization check during placement
set_param place.skipUtilizationCheck 1
