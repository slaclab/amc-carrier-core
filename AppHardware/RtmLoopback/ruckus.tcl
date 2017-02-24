# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
if { $::env(RTM_INTF)  == "Version1" } {
   puts "\n\nRTM_INTF = Version1 is not support hardware.\n\n"
   exit -1
} elseif { $::env(RTM_INTF)  == "Version2" } {
   loadSource -dir "$::DIR_PATH/v2/"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name.  Please fixed your target/makefile''s RTM_INTF variable.\n\n"
   exit -1
}
