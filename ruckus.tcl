# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/AmcCarrierCore"
loadRuckusTcl "$::DIR_PATH/BsaCore"
loadRuckusTcl "$::DIR_PATH/AppMps"

loadRuckusTcl "$::DIR_PATH/AppTop"
loadRuckusTcl "$::DIR_PATH/DacSigGen"
loadRuckusTcl "$::DIR_PATH/DaqMuxV2"

loadRuckusTcl "$::DIR_PATH/Hardware"

