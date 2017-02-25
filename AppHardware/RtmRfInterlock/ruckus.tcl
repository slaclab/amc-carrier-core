# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -dir "$::DIR_PATH/core/"
if { $::env(RTM_INTF)  == "Version1" } {
   loadSource      -dir "$::DIR_PATH/v1/"
   loadConstraints -dir "$::DIR_PATH/v1/"
} elseif { $::env(RTM_INTF)  == "Version2" } {

   puts "\n\n RTM_INTF = Version2 not supported yet.\n\n"
   exit -1

   loadSource      -dir "$::DIR_PATH/v2/"
   loadConstraints -dir "$::DIR_PATH/v2/"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name.  Please fixed your target/makefile''s RTM_INTF variable.\n\n"
   exit -1
}
