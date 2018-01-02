# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(MODULES)/surf
loadRuckusTcl $::env(MODULES)/lcls-timing-core
loadSource      -path "$::DIR_PATH/../../core/AmcCarrierPkg.vhd"

# Load target's source code and constraints
loadSource      -path "$::DIR_PATH/hdl/UdpDebugBridgePkg.vhd"
loadSource      -path "$::DIR_PATH/hdl/UdpDebugBridge$::env(VARIANT)Wrapper.vhd"

## Skip the utilization check during placement
set_param place.skipUtilizationCheck 1
