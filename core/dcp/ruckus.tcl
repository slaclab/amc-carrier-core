# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(PROJ_DIR)/../../../surf
loadRuckusTcl $::env(PROJ_DIR)/../../../lcls-timing-core

# Load target's source code and constraints
loadSource      -path "$::DIR_PATH/../rtl/AmcCarrierPkg.vhd"
loadSource      -path "$::DIR_PATH/Version.vhd"
loadSource      -dir  "$::DIR_PATH/hdl/"
