# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code
loadSource -dir "$::DIR_PATH/rtl/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcCryoDemoBay0Pinout.xdc"
}

# Load AMC BAY[1] constraints files
if { $::env(AMC_TYPE_BAY1) == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcCryoDemoBay1Pinout.xdc"
}

if {  $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} ||
      $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {
   puts "\n\nERROR: Invalid PRJ_PART=$::env(PRJ_PART) not supported yet for this application hardware\n\n"; exit -1
}      