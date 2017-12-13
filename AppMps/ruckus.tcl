# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -dir "$::DIR_PATH/rtl/"
loadSource -path "$::DIR_PATH/coregen/MpsPgpGthCore.dcp"

if { [info exists ::env(APP_MPS_LNODE)] != 1 || $::env(APP_MPS_LNODE) == 0 } {

   if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu040.xdc"
   } elseif {  $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
               $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu060.xdc"
   } else {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu11p.xdc"
   }
} else {
   loadConstraints -path "$::DIR_PATH/xdc/MpsLinkNodeSaltSerdes.xdc"
   # set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
}
