# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

# Check for GEN1 + extended JESD lanes
if { $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
     $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {   
   set bayExt true
} else {
   set bayExt false
}

# Load local Source Code
loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   # Check the AMC card version
   if { $::env(AMC_INTF_BAY0) == "Version1" } {
      ################################################
      # Version1 = PC-379-396-09-C00/PC-379-396-09-C01
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV1Bay0.xdc"
      if { ${bayExt} } {
         loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV1Bay0Ext.xdc"
      }
   } elseif { $::env(AMC_INTF_BAY0)  == "Version2" } {
      ################################################
      # Version2 = PC-379-396-09-C02 (or later)
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV2Bay0.xdc"
      if { ${bayExt} } {
         loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV2Bay0Ext.xdc"
      }      
   } else {
      puts "\n\n $::env(AMC_INTF_BAY0) is an invalid AMC_INTF_BAY0 name. AMC_INTF_BAY0 can be \[Version1,Version2\]. Please fixed your target/makefile's.\n\n"   
      exit -1
   }
}

# Load AMC BAY[1] constraints files
if { $::env(AMC_TYPE_BAY1) == ${rootName} } {
   # Check the AMC card version
   if { $::env(AMC_INTF_BAY1) == "Version1" } {
      ################################################
      # Version1 = PC-379-396-09-C00/PC-379-396-09-C01
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV1Bay1.xdc"
      if { ${bayExt} } {
         loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV1Bay1Ext.xdc"
      }      
   } elseif { $::env(AMC_INTF_BAY1)  == "Version2" } {
      ################################################
      # Version2 = PC-379-396-09-C02 (or later)
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV2Bay1.xdc"
      if { ${bayExt} } {
         loadConstraints -path "$::DIR_PATH/xdc/${family}/AmcMpsSfpV2Bay1Ext.xdc"
      }        
   } else {
      puts "\n\n $::env(AMC_INTF_BAY1) is an invalid AMC_INTF_BAY1 name. AMC_INTF_BAY1 can be \[Version1,Version2\]. Please fixed your target/makefile's.\n\n"   
      exit -1
   }
}
