# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code
loadSource      -dir "$::DIR_PATH/rtl/"

# Load AMC BAY[0] constraints files
if { $::AMC_BAY0 == [file dirname $::DIR_PATH]  } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcEmptyBay0Pinout"
}

# Load AMC BAY[1] constraints files
if { $::AMC_BAY1 == [file dirname $::DIR_PATH]  } {
   loadConstraints -path "$::DIR_PATH/xdc/AmcEmptyBay1Pinout"
}
