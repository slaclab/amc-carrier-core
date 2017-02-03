# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource      -dir "$::DIR_PATH/rtl/"
loadConstraints -dir "$::DIR_PATH/xdc/"

loadSource      -path "$::DIR_PATH/coregen/SysMonCore.dcp"
# loadIpCore    -path "$::DIR_PATH/coregen/SysMonCore.xci"

loadSource      -path "$::DIR_PATH/coregen/MigCore.dcp"
# loadIpCore    -path "$::DIR_PATH/coregen/MigCore.xci"
