# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource      -path "$::DIR_PATH/rtl/AmcCarrierBsi.vhd"
loadSource      -path "$::DIR_PATH/rtl/AmcCarrierPkg.vhd"
loadSource      -path "$::DIR_PATH/rtl/AmcCarrierSysMon.vhd"
loadSource      -path "$::DIR_PATH/rtl/AmcCarrierSysReg.vhd"
loadSource      -path "$::DIR_PATH/rtl/AmcCarrierSysRegPkg.vhd"
loadConstraints -dir  "$::DIR_PATH/xdc/"

loadSource      -path "$::DIR_PATH/coregen/SysMonCore.dcp"
# loadIpCore    -path "$::DIR_PATH/coregen/SysMonCore.xci"

# Check for advance build, which bypasses the pre-built .DCP file
set AmcAdvBuild [expr {[info exists ::env(AMC_ADV_BUILD)] && [string is true -strict $::env(AMC_ADV_BUILD)]}]  
puts "AmcAdvBuild = ${AmcAdvBuild}"
if { ${AmcAdvBuild} == 1 } {
   loadSource -path "$::DIR_PATH/rtl/AmcCarrierCoreAdv.vhd"
   loadSource      -path "$::DIR_PATH/coregen/MigCore.dcp"
   # loadIpCore    -path "$::DIR_PATH/coregen/MigCore.xci"   
} else {
   loadSource -path "$::DIR_PATH/rtl/AmcCarrierCoreBase.vhd"
   loadSource -path "$::DIR_PATH/dcp/images/AmcCarrierCore.dcp"
}