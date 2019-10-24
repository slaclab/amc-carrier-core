# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code
loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl/"
loadSource -lib amc_carrier_core -sim_only -dir "$::DIR_PATH/tb/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcMicrowaveMuxBay0Pinout.xdc"
}

# Load AMC BAY[1] constraints files
if { $::env(AMC_TYPE_BAY1) == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcMicrowaveMuxBay1Pinout.xdc"
}
