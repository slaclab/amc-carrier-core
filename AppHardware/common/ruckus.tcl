# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

# Load local Source Code
loadSource -dir "$::DIR_PATH/rtl"

# Load AMC BAY[0] constraints files
if { $::env(AMC_TYPE_BAY0) != "AmcMpsSfp" } {
   set temp "AmcMpsSfp uses special JESD mapping"
} else {
   loadConstraints -path "$::DIR_PATH/xdc/${family}/StandardJesdMapBay0.xdc"  
   if { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
        $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {   
      loadConstraints -path "$::DIR_PATH/xdc/${family}/StandardJesdMapBay0Ext.xdc"  
   }
}

# Load AMC BAY[1] constraints files
if { $::env(AMC_TYPE_BAY1) != "AmcMpsSfp" } {
   set temp "AmcMpsSfp uses special JESD mapping"
} else {
   loadConstraints -path "$::DIR_PATH/xdc/${family}/StandardJesdMapBay1.xdc"  
   if { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
        $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {   
      loadConstraints -path "$::DIR_PATH/xdc/${family}/StandardJesdMapBay1Ext.xdc"  
   }
}
