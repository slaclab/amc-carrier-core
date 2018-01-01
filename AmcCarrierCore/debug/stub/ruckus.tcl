# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(MODULES)/surf
loadRuckusTcl $::env(MODULES)/lcls-timing-core

# Load target's source code and constraints
loadSource      -path "$::DIR_PATH/../../core/AmcCarrierPkg.vhd"
loadSource      -dir  "$::DIR_PATH/../hdl/"
loadSource      -path "$::DIR_PATH/UdpDebugBridgeConfig.vhd"

## Skip the utilization check during placement
set_param place.skipUtilizationCheck 1
