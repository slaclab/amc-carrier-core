# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -lib amc_carrier_core -dir  "$::DIR_PATH/rtl/"
# loadIpCore    -path "$::DIR_PATH/cores/BsaAxiInterconnect/BsaAxiInterconnect.xci"

# Get the family type
set family [getFpgaFamily]

if { ${family} == "kintexuplus" } {
   loadSource -lib amc_carrier_core -path  "$::DIR_PATH/cores/BsaAxiInterconnect/xilinxUltraScale/BsaAxiInterconnect.dcp"
}

if { ${family} == "kintexu" } {
   loadSource -lib amc_carrier_core -path  "$::DIR_PATH/cores/BsaAxiInterconnect/xilinxUltraScale/BsaAxiInterconnect.dcp"
}

if { ${family} == "kintex7" } {
   loadSource -lib amc_carrier_core -path  "$::DIR_PATH/cores/BsaAxiInterconnect/xilinx7/BsaAxiInterconnect.dcp"
}
