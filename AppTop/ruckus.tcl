# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource      -dir  "$::DIR_PATH/rtl/"
loadConstraints -dir  "$::DIR_PATH/xdc/"
loadSource -sim_only -dir "$::DIR_PATH/tb/"

loadSource      -path "$::DIR_PATH/coregen/AppTopJesd204bCoregen.dcp"
# loadSource    -path "$::DIR_PATH/coregen/AppTopJesd204bCoregen.xci"
