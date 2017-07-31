# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource           -dir  "$::DIR_PATH/rtl"
loadSource -sim_only -dir  "$::DIR_PATH/tb/"
loadConstraints      -path "$::DIR_PATH/xdc/AppTop.xdc"

# Check for valid FPGA 
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {

   loadSource      -dir  "$::DIR_PATH/rtl/xcku040"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku040/AppTopJesd204bCoregen.dcp"
   # loadIpCore -path "$::DIR_PATH/coregen/xcku040/AppTopJesd204bCoregen.xci"
   
} elseif { $::env(PRJ_PART) == "XCKU060-FFVA1156-2-E" } { 

   loadSource      -dir  "$::DIR_PATH/rtl/xcku060"
   loadConstraints -path  "$::DIR_PATH/xdc/AppTopXCKU060.xdc"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.dcp"
   #loadIpCore -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.xci"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.dcp"
   #loadIpCore -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.xci"   
   
} else { 
   puts "\n\nERROR: PRJ_PART was not defined as 'XCKU040-FFVA1156-2-E' or 'XCKU060-FFVA1156-2-E' in the Makefile\n\n"; exit -1
}


