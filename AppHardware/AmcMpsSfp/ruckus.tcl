# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code
loadSource -dir "$::DIR_PATH/rtl/"

# Load AMC BAY[0] constraints files
set rootName [file rootname [file tail $::DIR_PATH]]
if { $::env(AMC_TYPE_BAY0) == ${rootName} } {
   # Check the AMC card version
   if { $::env(AMC_INTF_BAY0) == "Version1" } {
      ################################################
      # Version1 = PC-379-396-09-C00/PC-379-396-09-C01
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/AmcMpsSfpV1Bay0Pinout.xdc"
   } elseif { $::env(AMC_INTF_BAY0)  == "Version2" } {
      ################################################
      # Version2 = PC-379-396-09-C02 (or later)
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/AmcMpsSfpV2Bay0Pinout.xdc"
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
      loadConstraints -path "$::DIR_PATH/xdc/AmcMpsSfpV1Bay1Pinout.xdc"
   } elseif { $::env(AMC_INTF_BAY1)  == "Version2" } {
      ################################################
      # Version2 = PC-379-396-09-C02 (or later)
      ################################################
      loadConstraints -path "$::DIR_PATH/xdc/AmcMpsSfpV2Bay1Pinout.xdc"
   } else {
      puts "\n\n $::env(AMC_INTF_BAY1) is an invalid AMC_INTF_BAY1 name. AMC_INTF_BAY1 can be \[Version1,Version2\]. Please fixed your target/makefile's.\n\n"   
      exit -1
   }
}

if {  $::env(PRJ_PART) eq {XCKU11P-FFVA1156-2-E} ||
      $::env(PRJ_PART) eq {XCKU15P-FFVA1156-2-E} } {
   puts "\n\nERROR: Invalid PRJ_PART=$::env(PRJ_PART) not supported yet for this application hardware\n\n"; exit -1
} 