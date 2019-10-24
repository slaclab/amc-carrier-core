# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
if { $::env(RTM_INTF)  == "Version1" } {
   loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl/"
} elseif { $::env(RTM_INTF)  == "Version2" } {
   loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl/"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name. RTM_INTF can be [Version1,Version2]. Please fixed your target/makefile''s.\n\n"   
   exit -1
}
