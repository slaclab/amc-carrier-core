# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

################################################################################
## Check for submodule/ruckus tag
## Note: Can't use SubmoduleCheck() because didn't exist before v1.3.2 
################################################################################
set lockTag {1.3.3}
# Get the full git submodule string for a particular module
set submodule [exec git -C $::env(MODULES) submodule status -- ruckus]
# Scan for the hash, name, and tag portions of the string
scan $submodule "%s %s (v%s )" hash temp tag
# Blowoff everything except for the major, minor, and patch numbers
set tag [string range $tag 0 4]
# Compare the tag version for the targeted submodule version lock
if { ${tag} < ${lockTag} } {
   puts "\n\n\n\n\n\n*********************************************************"
   puts "Your git clone ruckus = v${tag}"
   puts "However, ruckus Lock  = v${lockTag}"
   puts "Please update this submodule tag to v${lockTag} (or later)"
   puts "*********************************************************\n\n\n\n\n\n"
   exit -1
}

## Check for submodule tagging
if { [SubmoduleCheck {surf} {1.3.5} ] < 0 } {exit -1}

## Check for version 2016.4 of Vivado
if { [VersionCheck 2016.4] < 0 } {exit -1}

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
loadRuckusTcl "$::DIR_PATH/AmcCarrierCore"   "quiet"
loadRuckusTcl "$::DIR_PATH/BsaCore"          "quiet"
loadRuckusTcl "$::DIR_PATH/AppTop"           "quiet"
loadRuckusTcl "$::DIR_PATH/AppMps"           "quiet"
loadRuckusTcl "$::DIR_PATH/DacSigGen"        "quiet"
loadRuckusTcl "$::DIR_PATH/DaqMuxV2"         "quiet"
loadRuckusTcl "$::DIR_PATH/AppHardware"
