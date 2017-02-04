# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -dir  "$::DIR_PATH/DebugRtmEth/"
loadSource -dir  "$::DIR_PATH/DebugRtmPgp/"

# Get the family type
set family [getFpgaFamily]
if { ${family} == "kintexu" } {
   # loadIpCore  -path "$::DIR_PATH/coregen/DebugRtmPgpGthCore.xci"
   loadSource    -path "$::DIR_PATH/coregen/DebugRtmPgpGthCore.dcp"
}

