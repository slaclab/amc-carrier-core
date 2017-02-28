# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource    -dir "$::DIR_PATH/core/"

# Check which AMC bay that you are loading
if { $::AMC_BAY == "BAY0" } {
   if { $::env(AMC_INTF_BAY0)  == "Version1" } {
      loadSource -dir "$::DIR_PATH/v1/"
   } elseif { $::env(AMC_INTF_BAY0)  == "Version2" } {
      loadSource -dir "$::DIR_PATH/v2/"
   } elseif { $::env(AMC_INTF_BAY0)  == "Version3" } {
      loadSource -dir "$::DIR_PATH/v3/"   
   } else {
      puts "\n\n $::env(AMC_INTF_BAY0) is an invalid AMC_INTF_BAY0 name. AMC_INTF_BAY0 can be [Version1,Version2,Version3]. Please fixed your target/makefile''s.\n\n"
      exit -1
   }
} else {
   if { $::env(AMC_INTF_BAY1)  == "Version1" } {
      loadSource -dir "$::DIR_PATH/v1/"
   } elseif { $::env(AMC_INTF_BAY1)  == "Version2" } {
      loadSource -dir "$::DIR_PATH/v2/"
   } elseif { $::env(AMC_INTF_BAY1)  == "Version3" } {
      loadSource -dir "$::DIR_PATH/v3/"   
   } else {
      puts "\n\n $::env(AMC_INTF_BAY1) is an invalid AMC_INTF_BAY1 name. AMC_INTF_BAY1 can be [Version1,Version2,Version3]. Please fixed your target/makefile''s.\n\n"
      exit -1
   }
}
