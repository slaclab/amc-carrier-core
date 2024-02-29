# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -lib amc_carrier_core           -dir  "$::DIR_PATH/rtl"
loadSource -lib amc_carrier_core -sim_only -dir  "$::DIR_PATH/tb/"

# Check for valid FPGA
if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" ||
     $::env(USE_APPTOP_040_INTF) == 1 } {
   loadConstraints -path "$::DIR_PATH/xdc/AppTop_gen1.xdc"

   if { [info exists ::env(APP_MPS_LNODE)] != 1 || $::env(APP_MPS_LNODE) == 0 } {
      loadSource -lib amc_carrier_core      -dir  "$::DIR_PATH/rtl/xcku040"

      loadSource -lib amc_carrier_core  -path "$::DIR_PATH/coregen/xcku040/AppTopJesd204bCoregen.dcp"
      # loadIpCore -path "$::DIR_PATH/coregen/xcku040/AppTopJesd204bCoregen.xci"
   } else {
      loadSource -lib amc_carrier_core      -dir  "$::DIR_PATH/rtl/xcku040_mpsln"

      loadSource -lib amc_carrier_core  -path "$::DIR_PATH/coregen/xcku040_mpsln/AppTopJesd204bCoregen.dcp"
      #loadIpCore -path "$::DIR_PATH/coregen/xcku040_mpsln/AppTopJesd204bCoregen.xci"
   }

} elseif {  $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
            $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {

   loadSource -lib amc_carrier_core      -dir  "$::DIR_PATH/rtl/xcku060"
   loadConstraints -path "$::DIR_PATH/xdc/AppTop_gen1.xdc"
   loadConstraints -path "$::DIR_PATH/xdc/AppTopXCKU060.xdc"

   loadSource -lib amc_carrier_core  -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.dcp"
   #loadIpCore -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreLeftColumn/JesdCryoCoreLeftColumn.xci"

   loadSource -lib amc_carrier_core  -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.dcp"
   #loadIpCore -path "$::DIR_PATH/coregen/xcku060/JesdCryoCoreRightColumn/JesdCryoCoreRightColumn.xci"

} elseif {  $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} ||
            $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {

   loadSource -lib amc_carrier_core      -dir  "$::DIR_PATH/rtl/xcku15p"
   loadConstraints -path "$::DIR_PATH/xdc/AppTop_gen2.xdc"

   loadSource -lib amc_carrier_core  -path "$::DIR_PATH/coregen/xcku15p/AppTopJesd204bCoregen.dcp"
   # loadIpCore -path "$::DIR_PATH/coregen/xcku15p/AppTopJesd204bCoregen.xci"

} else {
   puts "\n\nERROR: Invalid PRJ_PART was defined in the Makefile\n\n"; exit -1
}
