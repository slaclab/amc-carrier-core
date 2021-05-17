# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -lib amc_carrier_core -dir  "$::DIR_PATH/rtl/"
# loadIpCore    -path "$::DIR_PATH/cores/BsaAxiInterconnect/BsaAxiInterconnect.xci"

# Get the family type
set family [getFpgaFamily]

if { ${family} == "kintexuplus" } {
   loadSource -path "$::DIR_PATH/cores/BsaAxiInterconnect/xilinxUltraScale/BsaAxiInterconnect.dcp"
}

if { ${family} == "kintexu" } {
   loadSource -path "$::DIR_PATH/cores/BsaAxiInterconnect/xilinxUltraScale/BsaAxiInterconnect.dcp"
}

if { ${family} == "kintex7" } {
   loadSource -path "$::DIR_PATH/cores/BsaAxiInterconnect/xilinx7/BsaAxiInterconnect.dcp"
}

loadConstraints -path "$::DIR_PATH/cores/BsaAxiInterconnect/BsaAxiInterconnect_clocks.xdc"
set_property PROCESSING_ORDER {LATE}               [get_files {BsaAxiInterconnect_clocks.xdc}]
set_property SCOPED_TO_REF    {BsaAxiInterconnect} [get_files {BsaAxiInterconnect_clocks.xdc}]
set_property SCOPED_TO_CELLS  {inst}               [get_files {BsaAxiInterconnect_clocks.xdc}]
