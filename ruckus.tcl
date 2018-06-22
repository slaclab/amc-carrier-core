# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

proc MyVersionCheck { } {

   # Get the Vivado version
   set VersionNumber [version -short]
   set supported "2016.4 2017.4 2018.1 2018.2"
   set retVar -1
   
   # Generate error message
   set errMsg "\n\n*********************************************************\n"
   set errMsg "${errMsg}Your Vivado Version Vivado   = ${VersionNumber}\n"
   set errMsg "${errMsg}However, Vivado Version Lock = ${supported}\n"
   set errMsg "${errMsg}You need to change your Vivado software to one of these versions\n"
   set errMsg "${errMsg}*********************************************************\n\n"  
   
   # Loop through the different support version list
   foreach pntr ${supported} {
      if { ${VersionNumber} == ${pntr} } {
         set retVar 0      
      }
   }
   
   # Check for no support version detected
   if  { ${retVar} < 0 } {
      puts ${errMsg}
   }
   
   return ${retVar}
}

# Get the family type
set family [getFpgaFamily]

# Check for submodule tagging
if { [info exists ::env(OVERRIDE_SUBMODULE_LOCKS)] != 1 || $::env(OVERRIDE_SUBMODULE_LOCKS) == 0 } {
   if { [SubmoduleCheck {lcls-timing-core} {1.11.6} "mustBeExact" ] < 0 } {exit -1}
   if { [SubmoduleCheck {ruckus}           {1.6.8}  "mustBeExact" ] < 0 } {exit -1}
   if { [SubmoduleCheck {surf}             {1.8.5}  "mustBeExact" ] < 0 } {exit -1}
} else {
   puts "\n\n*********************************************************"
   puts "OVERRIDE_SUBMODULE_LOCKS != 0"
   puts "Ignoring the submodule locks in amc-carrier-core/ruckus.tcl"
   puts "*********************************************************\n\n"
}

# Check for Kintex Ultrascale+
if { ${family} == "kintexuplus" } {
   ## Check for Vivado version 2018.2 (or later)
   if { [VersionCheck 2018.2 ] < 0 } {
      exit -1
   }
# Check Kintex Ultrascale
} elseif { ${family} == "kintexu" } {  
   if { [MyVersionCheck] < 0 } {
      exit -1
   }
} else { 
   puts "\n\nERROR: Invalid PRJ_PART was defined in the Makefile\n\n"; exit -1
}

# Check if required variables exist
if { [info exists ::env(AMC_ADV_BUILD)] != 1 }  {puts "\n\nERROR: AMC_ADV_BUILD is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(RTM_ETH)] != 1 }        {puts "\n\nERROR: RTM_ETH is not defined in $::env(PROJ_DIR)/Makefile\n\n";         exit -1}
if { [info exists ::env(AMC_TYPE_BAY0)] != 1 }  {puts "\n\nERROR: AMC_TYPE_BAY0 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(AMC_INTF_BAY0)] != 1 }  {puts "\n\nERROR: AMC_INTF_BAY0 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(AMC_TYPE_BAY1)] != 1 }  {puts "\n\nERROR: AMC_TYPE_BAY1 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(AMC_INTF_BAY1)] != 1 }  {puts "\n\nERROR: AMC_INTF_BAY1 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(RTM_TYPE)] != 1 }       {puts "\n\nERROR: RTM_TYPE is not defined in $::env(PROJ_DIR)/Makefile\n\n";        exit -1}
if { [info exists ::env(RTM_INTF)] != 1 }       {puts "\n\nERROR: RTM_INTF is not defined in $::env(PROJ_DIR)/Makefile\n\n";        exit -1}
if { [info exists ::env(COMMON_FILE)] != 1 }    {puts "\n\nERROR: COMMON_FILE is not defined in $::env(PROJ_DIR)/Makefile\n\n";     exit -1}
if { ( $::env(AMC_ADV_BUILD)  != 1) && ( $::env(RTM_ETH)  != 0) } {puts "\n\nERROR: (AMC_ADV_BUILD = 0) and (RTM_ETH = 1) is NOT supported!!!\n\n\n\n"; exit -1}

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/AmcCarrierCore"
loadRuckusTcl "$::DIR_PATH/BsaCore"
loadRuckusTcl "$::DIR_PATH/AppTop"
loadRuckusTcl "$::DIR_PATH/AppMps"
loadRuckusTcl "$::DIR_PATH/DacSigGen"
loadRuckusTcl "$::DIR_PATH/DaqMuxV2"
loadRuckusTcl "$::DIR_PATH/AppHardware"
loadRuckusTcl "$::DIR_PATH/AxisBramRingBuffer"
