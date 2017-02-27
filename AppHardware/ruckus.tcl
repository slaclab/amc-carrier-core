# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load AMC BAY[0] ruckus files
loadRuckusTcl "$::DIR_PATH/$::env(AMC_TYPE_BAY0)"

# Load AMC BAY[1] ruckus files
loadRuckusTcl "$::DIR_PATH/$::env(AMC_TYPE_BAY1)"

# Load RTM TYPE ruckus files
loadRuckusTcl "$::DIR_PATH/$::env(RTM_TYPE)"

# Load local Source Code
loadSource -dir "$::DIR_PATH/common/"