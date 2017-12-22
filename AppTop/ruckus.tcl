# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource           -dir  "$::DIR_PATH/rtl"
loadSource -sim_only -dir  "$::DIR_PATH/tb/"

# Check for valid FPGA 
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
   loadConstraints -path "$::DIR_PATH/xdc/kintexu/AppTopPinout.xdc"
   loadConstraints -path "$::DIR_PATH/xdc/AppTopTiming.xdc"

   if { [info exists ::env(APP_MPS_LNODE)] != 1 || $::env(APP_MPS_LNODE) == 0 } {
      loadSource      -dir  "$::DIR_PATH/rtl/xcku040"
      
      loadSource  -path "$::DIR_PATH/coregen/xcku040/AppTopJesd204bCoregen.dcp"
      # loadIpCore -path "$::DIR_PATH/coregen/xcku040/AppTopJesd204bCoregen.xci"
   } else {
      loadSource      -dir  "$::DIR_PATH/rtl/xcku040_mpsln"
      
      loadSource  -path "$::DIR_PATH/coregen/xcku040_mpsln/AppTopJesd204bCoregen.dcp"
      #loadIpCore -path "$::DIR_PATH/coregen/xcku040_mpsln/AppTopJesd204bCoregen.xci"
   }
   
} elseif {  $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
            $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {

   loadSource      -dir  "$::DIR_PATH/rtl/xcku060"
   loadConstraints -path "$::DIR_PATH/xdc/kintexu/AppTopPinout.xdc"
   loadConstraints -path "$::DIR_PATH/xdc/kintexu/AppTopXCKU060.xdc"
   loadConstraints -path "$::DIR_PATH/xdc/AppTopTiming.xdc"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.dcp"
   #loadIpCore -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.xci"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.dcp"
   #loadIpCore -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.xci"   

} elseif {  $::env(PRJ_PART) eq {XCKU11P-FFVA1156-3-E} ||
            $::env(PRJ_PART) eq {XCKU15P-FFVA1156-3-E} } {
            
   loadSource      -dir  "$::DIR_PATH/rtl/xcku11p"
   loadConstraints -path "$::DIR_PATH/xdc/kintexuplus/AppTopPinout.xdc"
   loadConstraints -path "$::DIR_PATH/xdc/AppTopTiming.xdc"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku11p/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.dcp"
   # loadIpCore -path "$::DIR_PATH/coregen/xcku11p/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.xci"
   
   loadSource  -path "$::DIR_PATH/coregen/xcku11p/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.dcp"
   # loadIpCore -path "$::DIR_PATH/coregen/xcku11p/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.xci"      
   
} else { 
   puts "\n\nERROR: Invalid PRJ_PART was defined in the Makefile\n\n"; exit -1
}
