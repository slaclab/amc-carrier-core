# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Load local Source Code and constraints
if { $::env(RTM_INTF)  == "Version1" } {
   loadSource -lib amc_carrier_core -dir "$::DIR_PATH/v1"
   loadConstraints                  -dir "$::DIR_PATH/v1"
} elseif { $::env(RTM_INTF)  == "Version2" } {
   loadSource -lib amc_carrier_core -dir "$::DIR_PATH/v2"
   loadConstraints                  -dir "$::DIR_PATH/v2"
} elseif { $::env(RTM_INTF)  == "Version2b" } {
   loadSource -lib amc_carrier_core -dir "$::DIR_PATH/v2b"
   loadConstraints                  -dir "$::DIR_PATH/v2b"
   add_files -norecurse "$::DIR_PATH/v2b/pll-config/RtmDigitalDebug_Si5345_LCLS_I.mem"
   add_files -norecurse "$::DIR_PATH/v2b/pll-config/RtmDigitalDebug_Si5345_LCLS_II.mem"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name. RTM_INTF can be [Version1,Version2,Version2b]. Please fixed your target/makefile''s.\n\n"
   exit -1
}
