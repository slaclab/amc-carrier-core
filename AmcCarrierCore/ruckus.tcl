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
loadSource -dir  "$::DIR_PATH/core/${family}"
loadSource -path "$::DIR_PATH/ip/SysMonCore.dcp"

if { [info exists ::env(USE_XVC_DEBUG)] != 1 || $::env(USE_XVC_DEBUG) == 0 } {
	loadSource -path "$::DIR_PATH/debug/dcp/Stub/images/UdpDebugBridge.dcp"
    set_property IS_GLOBAL_INCLUDE {1} [get_files UdpDebugBridge.dcp]
} elseif { $::env(USE_XVC_DEBUG) == -1 } {
# Load nothing - user provides
} else {
	loadSource -path "$::DIR_PATH/debug/dcp/Impl/images/UdpDebugBridge.dcp"
    set_property IS_GLOBAL_INCLUDE {1} [get_files UdpDebugBridge.dcp]
}

# Check for advance build, which bypasses the pre-built .DCP file
if { $::env(AMC_ADV_BUILD)  == 1 ||
     $::env(RTM_ETH)  == 1 ||
     $::env(PRJ_PART) != "XCKU040-FFVA1156-2-E" } {
     
   # Check for FSBL
   if { [info exists ::env(AMC_FSBL)] == 1 }  {
      loadSource -dir "$::DIR_PATH/fsbl"
   } else {
      # NON-FSBL configuration
      loadSource -path "$::DIR_PATH/core/AmcCarrierCoreAdv.vhd"
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierCore.vhd"
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierRssi.vhd"   
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierRssiInterleave.vhd"   
      loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierXvcDebug.vhd"   
   }
   
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierTiming.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierBsa.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierDdrMem.vhd"
   
   loadSource   -path "$::DIR_PATH/ip/MigCore.dcp"
   # loadIpCore -path "$::DIR_PATH/ip/MigCore.xci"
   
   loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierCorePorts.xdc"    
   loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCoreTiming.xdc" 
   
   # Check for FSBL
   if { [info exists ::env(AMC_FSBL)] == 1 }  {
      loadConstraints -dir "$::DIR_PATH/fsbl/${family}"
   } else {   
      # Check if using zone2 or zone3 ETH interface
      if {  $::env(RTM_ETH)  == 1 } {
         loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierCoreZone3Eth.xdc" 
      } else {
         loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierCoreZone2Eth.xdc" 
      }
   }
   
} else {
   loadSource -path "$::DIR_PATH/core/AmcCarrierCoreBase.vhd"
   loadSource -path "$::DIR_PATH/dcp/images/AmcCarrierCore.dcp"
   # After Vivado 2016.4, DCP don't contain .XDCs anymore
   if { $::env(VIVADO_VERSION) > 2016.4 } {   
      loadConstraints -path "$::DIR_PATH/dcp/hdl/AmcCarrierCore.xdc" 
   }
}

# Add application ports and placement constraints
loadConstraints -path "$::DIR_PATH/xdc/AmcCarrierCorePlacement.xdc" 
loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcCarrierAppPorts.xdc" 

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

# Load the FpgaTypePkg.vhd
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
   loadSource -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU040.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} } {
   loadSource -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU060.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {            
   loadSource -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU095.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} } {  
   loadSource -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU11P.vhd"
} elseif { $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {              
   loadSource -path "$::DIR_PATH/core/FpgaType/FpgaTypePkg_XCKU15P.vhd"
} else { 
}

## Place and Route strategies 
set_property strategy Performance_Explore [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

## Skip the utilization check during placement
set_param place.skipUtilizationCheck 1
