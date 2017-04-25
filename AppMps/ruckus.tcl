# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -dir "$::DIR_PATH/rtl/"
loadSource -path "$::DIR_PATH/coregen/MpsPgpGthCore.dcp"

if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
   loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu040.xdc"
} else {
   loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu060.xdc"
}

