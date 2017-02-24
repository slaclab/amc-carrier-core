# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
if { $::env(RTM_INTF)  == "Version1" } {
   loadSource -dir "$::DIR_PATH/rtl/"
} elseif { $::env(RTM_INTF)  == "Version2" } {
   loadSource -dir "$::DIR_PATH/rtl/"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name.  Please fixed your target/makefile''s RTM_INTF variable.\n\n"
   exit -1
}
