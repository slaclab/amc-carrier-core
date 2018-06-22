# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -dir "$::DIR_PATH/core/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   # Check the AMC card version
   if { $::env(AMC_INTF_BAY0) == "Version1" } {
      loadConstraints -path "$::DIR_PATH/v1/AmcMrLlrfDownConvertBay0Pinout.xdc"
   } elseif { $::env(AMC_INTF_BAY0)  == "Version2" } {
      loadConstraints -path "$::DIR_PATH/v2/AmcMrLlrfDownConvertBay0Pinout.xdc"
   } else {
      puts "\n\n $::env(AMC_INTF_BAY0) is an invalid AMC_INTF_BAY0 name. AMC_INTF_BAY0 can be \[Version1,Version2\]. Please fixed your target/makefile's.\n\n"   
      exit -1
   }   
}

# Load AMC BAY[1] constraints files
if { $::env(AMC_TYPE_BAY1) == ${rootName} } {
   puts "\n\n AmcMrLlrfDownConvert is not supported in AMC BAY\[1\].\n\n"   
   exit -1
}

if {  $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} ||
      $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {
   puts "\n\nERROR: Invalid PRJ_PART=$::env(PRJ_PART) not supported yet for this application hardware\n\n"; exit -1
} 