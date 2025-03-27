# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Check if AMC BAY[0] configuration
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   puts "\n\n AmcMrLlrfGen2UpConvert is not supported in AMC BAY\[0\].\n\n"
   exit -1
}

if { $::env(AMC_TYPE_BAY1) == ${rootName} } {
   # Load local Source Code and constraints
   loadSource -lib amc_carrier_core      -dir "$::DIR_PATH/core"
   loadConstraints -dir "$::DIR_PATH/xdc"
}

if {  $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} ||
      $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {
   puts "\n\nERROR: Invalid PRJ_PART=$::env(PRJ_PART) not supported yet for this application hardware\n\n"; exit -1
}
