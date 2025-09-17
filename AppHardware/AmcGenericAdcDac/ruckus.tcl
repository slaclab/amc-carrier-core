# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Load local Source Code
loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcGenericAdcDacBay0Pinout.xdc"
}

# Load AMC BAY[1] constraints files
if { $::env(AMC_TYPE_BAY1) == ${rootName} } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcGenericAdcDacBay1Pinout.xdc"
}
