# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource      -path "$::DIR_PATH/core/AmcCarrierBsi.vhd"
loadSource      -path "$::DIR_PATH/core/AmcCarrierPkg.vhd"
loadSource      -path "$::DIR_PATH/core/AmcCarrierSysMon.vhd"
loadSource      -path "$::DIR_PATH/core/AmcCarrierSysReg.vhd"
loadSource      -path "$::DIR_PATH/core/AmcCarrierSysRegPkg.vhd"
loadConstraints -dir  "$::DIR_PATH/xdc/"

loadSource      -path "$::DIR_PATH/ip/SysMonCore.dcp"
# loadIpCore    -path "$::DIR_PATH/ip/SysMonCore.xci"

# Check for advance build, which bypasses the pre-built .DCP file
if { [GetEnvVarBool {AMC_ADV_BUILD} ]  == 1 } {
   loadSource -path "$::DIR_PATH/core/AmcCarrierCoreAdv.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierCore.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierEth.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierRssi.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierTiming.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierBsa.vhd"
   loadSource -path "$::DIR_PATH/dcp/hdl/AmcCarrierDdrMem.vhd"
   loadSource -path "$::DIR_PATH/ip/MigCore.dcp"  
} else {
   loadSource -path "$::DIR_PATH/core/AmcCarrierCoreBase.vhd"
   loadSource -path "$::DIR_PATH/dcp/images/AmcCarrierCore.dcp"
}