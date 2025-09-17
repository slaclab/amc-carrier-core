# Load RUCKUS environment and library
source $::env(RUCKUS_PROC_TCL)

# Load AMC BAY[0] ruckus files
set ::AMC_BAY "BAY0"
loadRuckusTcl "$::DIR_PATH/$::env(AMC_TYPE_BAY0)"

# Load AMC BAY[1] ruckus files
set ::AMC_BAY "BAY1"
loadRuckusTcl "$::DIR_PATH/$::env(AMC_TYPE_BAY1)"

# Load RTM TYPE ruckus files
loadRuckusTcl "$::DIR_PATH/$::env(RTM_TYPE)"

# Load local Source Code
loadRuckusTcl "$::DIR_PATH/common"