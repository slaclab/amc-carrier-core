# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(PROJ_DIR)/../../../surf
loadRuckusTcl $::env(PROJ_DIR)/../../../lcls-timing-core
loadRuckusTcl $::env(PROJ_DIR)/../../BsaCore

# Load target's source code and constraints
loadSource      -dir  "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"
loadSource      -path "$::DIR_PATH/Version.vhd"
loadSource      -path "$::DIR_PATH/../core/AmcCarrierPkg.vhd"
loadSource      -path "$::DIR_PATH/../core/AmcCarrierSysRegPkg.vhd"

loadSource -path "$::DIR_PATH/../ip/MigCore.dcp"
#loadIpCore  -path "$::DIR_PATH/../ip/MigCore.xci" 
