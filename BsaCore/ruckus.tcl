# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -dir  "$::DIR_PATH/rtl/"
# loadIpCore    -path "$::DIR_PATH/cores/BsaAxiInterconnect/BsaAxiInterconnect.xci"

# # Get the family type
# set family [getFpgaFamily]

# if { ${family} == "kintexu" } {
   # loadSource -path  "$::DIR_PATH/cores/BsaAxiInterconnect/xilinxUltraScale/BsaAxiInterconnect.dcp"
# }

# if { ${family} == "kintex7" } {
   # loadSource -path  "$::DIR_PATH/cores/BsaAxiInterconnect/xilinx7/BsaAxiInterconnect.dcp"
# }