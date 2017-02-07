# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check if required variables exist
if { [catch { info globals $::AMC_ADV_BUILD} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: AMC_ADV_BUILD is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::RTM_ETH} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: RTM_ETH is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::AMC_TYPE_BAY0} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: AMC_TYPE_BAY0 is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::AMC_INTF_BAY0} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: AMC_INTF_BAY0 is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::AMC_TYPE_BAY1} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: AMC_TYPE_BAY1 is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::AMC_INTF_BAY1} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: AMC_INTF_BAY1 is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::RTM_TYPE} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: RTM_TYPE is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::RTM_INTF} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: RTM_INTF is not defined!!!\n\n\n\n"; exit -1
}

if { [catch { info globals $::COMMON_FILE} _RESULT] == 1 } {
   puts "\n\n\n\n\tERROR: COMMON_FILE is not defined!!!\n\n\n\n"; exit -1
}

# Check for invalid configurations
if { ($::AMC_ADV_BUILD  == 0) && ($::RTM_ETH  == 1) } {
   puts "\n\n\n\n\tERROR: (AMC_ADV_BUILD = 0) and (RTM_ETH = 1) is NOT supported!!!\n\n\n\n"
   exit -1
}

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/AmcCarrierCore"
loadRuckusTcl "$::DIR_PATH/BsaCore"
loadRuckusTcl "$::DIR_PATH/AppTop"
loadRuckusTcl "$::DIR_PATH/AppMps"
loadRuckusTcl "$::DIR_PATH/AppHardware"
loadRuckusTcl "$::DIR_PATH/DacSigGen"
loadRuckusTcl "$::DIR_PATH/DaqMuxV2"
