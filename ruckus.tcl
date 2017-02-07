# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check if required variables exist
if { [info exists ::env(AMC_ADV_BUILD)] != 1 } {
   puts "\n\nERROR: AMC_ADV_BUILD is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(RTM_ETH)] != 1 } {
   puts "\n\nERROR: RTM_ETH is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(AMC_TYPE_BAY0)] != 1 } {
   puts "\n\nERROR: AMC_TYPE_BAY0 is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(AMC_INTF_BAY0)] != 1 } {
   puts "\n\nERROR: AMC_INTF_BAY0 is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(AMC_TYPE_BAY1)] != 1 } {
   puts "\n\nERROR: AMC_TYPE_BAY1 is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(AMC_INTF_BAY1)] != 1 } {
   puts "\n\nERROR: AMC_INTF_BAY1 is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(RTM_TYPE)] != 1 } {
   puts "\n\nERROR: RTM_TYPE is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(RTM_INTF)] != 1 } {
   puts "\n\nERROR: RTM_INTF is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

if { [info exists ::env(COMMON_FILE)] != 1 } {
   puts "\n\nERROR: COMMON_FILE is not defined in $::env(PROJ_DIR)/Makefile\n\n"; exit -1
}

# Check for invalid configurations
if { ( $::env(AMC_ADV_BUILD)  != 1) && ( $::env(RTM_ETH)  != 0) } {
   puts "\n\nERROR: (AMC_ADV_BUILD = 0) and (RTM_ETH = 1) is NOT supported!!!\n\n\n\n"
   exit -1
}

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/AmcCarrierCore"   "quiet"
loadRuckusTcl "$::DIR_PATH/BsaCore"          "quiet"
loadRuckusTcl "$::DIR_PATH/AppTop"           "quiet"
loadRuckusTcl "$::DIR_PATH/AppMps"           "quiet"
loadRuckusTcl "$::DIR_PATH/DacSigGen"        "quiet"
loadRuckusTcl "$::DIR_PATH/DaqMuxV2"         "quiet"
loadRuckusTcl "$::DIR_PATH/AppHardware"
