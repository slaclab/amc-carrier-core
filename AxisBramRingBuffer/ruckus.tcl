# Load RUCKUS library
source $::env(RUCKUS_PROC_TCL)

# Load Source Code
loadSource -lib amc_carrier_core -dir  "$::DIR_PATH/rtl/"

# Load Simulation
loadSource -lib amc_carrier_core -sim_only -dir "$::DIR_PATH/tb"
