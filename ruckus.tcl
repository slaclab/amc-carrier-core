# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

# Check for submodule tagging
if { [SubmoduleCheck {ruckus}             {1.5.8} ] < 0 } {exit -1}
if { [SubmoduleCheck {surf}               {1.6.5} ] < 0 } {exit -1}
if { [SubmoduleCheck {lcls-timing-core}   {1.8.0} ] < 0 } {exit -1}

# Check for Kintex Ultrascale+
if { ${family} == "kintexuplus" } {
   ## Check for version 2017.3 of Vivado
   if { [VersionCheck 2017.3 "mustBeExact"] < 0 } {
      exit -1
   }
# Check Kintex Ultrascale
} elseif { ${family} == "kintexu" } {  
   # Check for version 2016.4 of Vivado
   if { [VersionCheck 2016.4] < 0 } {
      ## Check for version 2017.3 of Vivado
      if { [VersionCheck 2017.3 "mustBeExact"] < 0 } {
         exit -1
      }
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
