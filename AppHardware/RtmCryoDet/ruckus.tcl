# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
if { $::env(RTM_INTF)  == "Version2" } {
   loadSource           -dir "$::DIR_PATH/rtl"
   loadConstraints      -dir "$::DIR_PATH/xdc"
   loadSource -sim_only -dir "$::DIR_PATH/tb"
} else {
   puts "\n\n $::env(RTM_INTF) is an invalid RTM_INTF name. RTM_INTF can be Version2. Please fixed your target/makefile's.\n\n"   
   exit -1
}
