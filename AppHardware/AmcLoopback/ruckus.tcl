# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code
loadSource -dir "$::DIR_PATH/rtl/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::AMC_TYPE_BAY0 == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcLoopbackBay0Pinout.xdc"
}

# Load AMC BAY[1] constraints files
if { $::AMC_TYPE_BAY1 == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcLoopbackBay1Pinout.xdc"
}