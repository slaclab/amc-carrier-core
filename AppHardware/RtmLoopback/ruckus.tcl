# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
if { $::env(RTM_INTF)  == "Version1" } {
   puts "\n\nRTM_INTF = Version1 is not support hardware.\n\n"
   exit -1
} elseif { $::env(RTM_INTF)  == "Version2" } {
   loadSource -lib amc_carrier_core      -dir "$::DIR_PATH/v2"
   loadConstraints -dir "$::DIR_PATH/v2"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name. RTM_INTF can be [Version2]. Please fixed your target/makefile''s.\n\n"   
   exit -1
}
