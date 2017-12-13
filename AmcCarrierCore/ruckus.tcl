# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

# Load local Source Code and constraints
loadSource -path "$::DIR_PATH/core/AmcCarrierBsi.vhd"
loadSource -path "$::DIR_PATH/core/AmcCarrierPkg.vhd"
loadSource -path "$::DIR_PATH/core/AmcCarrierSysMon.vhd"
loadSource -path "$::DIR_PATH/core/AmcCarrierSysReg.vhd"
loadSource -path "$::DIR_PATH/core/AmcCarrierSysRegPkg.vhd"
loadSource -path "$::DIR_PATH/ip/SysMonCore.dcp"

# Check for advance build, which bypasses the pre-built .DCP file
if { $::env(AMC_ADV_BUILD)  == 1 ||
     $::env(RTM_ETH)        == 1 ||
     ${family} eq {kintexuplus} } {
     
   # Check for FSBL
   if { [info exists ::env(AMC_FSBL)] == 1 }  {
      loadSource -dir "$::DIR_PATH/fsbl"
   } else {
      # NON-FSBL configuration
      loadSource -path "$::DIR_PATH/core/AmcCarrierCoreAdv.vhd"
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierCore.vhd"
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierEth.vhd"
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierRssi.vhd"   
   }
   
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierTiming.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierBsa.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierDdrMem.vhd"
   
   loadSource   -path "$::DIR_PATH/ip/MigCore.dcp"
   # loadIpCore -path "$::DIR_PATH/ip/MigCore.xci"
   
   # Check for Kintex Ultrascale+
   if { ${family} == "kintexuplus" } {
      loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCorePorts_gen2.xdc" 
   # Else Kintex Ultrascale
   } else {
      loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCorePorts_gen1.xdc" 
   }   
   
   loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCoreTiming.xdc" 
   
   # Check for FSBL
   if { [info exists ::env(AMC_FSBL)] == 1 }  {
      loadConstraints -dir "$::DIR_PATH/fsbl"
   } else {   
      # Check if using zone2 or zone3 ETH interface
      if {  $::env(RTM_ETH)  == 1 } {
         loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCoreZone3Eth.xdc" 
      } else {
         loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCoreZone2Eth.xdc" 
      }
   }
   
} else {
   loadSource -path "$::DIR_PATH/core/AmcCarrierCoreBase.vhd"
   loadSource -path "$::DIR_PATH/dcp/images/AmcCarrierCore.dcp"
}

# Add application ports and placement constraints
loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCorePlacement.xdc" 

# Check for Kintex Ultrascale+
if { ${family} == "kintexuplus" } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierAppPorts_gen2.xdc" 
# Else Kintex Ultrascale
} else {
   loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierAppPorts_gen1.xdc" 
}

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

## Place and Route strategies 
set_property strategy Performance_Explore [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

## Skip the utilization check during placement
set_param place.skipUtilizationCheck 1
