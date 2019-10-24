# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Get the family type
set family [getFpgaFamily]

# Load Source Code
loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl"
loadSource -lib amc_carrier_core -dir "$::DIR_PATH/rtl/${family}"

loadSource -lib amc_carrier_core -path "$::DIR_PATH/coregen/${family}/MpsPgpGthCore.dcp"
# loadIpCore -path "$::DIR_PATH/coregen/${family}/MpsPgpGthCore.xci"

if { ${family} eq {kintexuplus} } {

   loadSource -lib amc_carrier_core -path "$::DIR_PATH/coregen/${family}/MpsPgpGtyCore.dcp"
   # loadIpCore -path "$::DIR_PATH/coregen/${family}/MpsPgpGtyCore.xci"
   
   loadConstraints -path "$::DIR_PATH/coregen/${family}/MpsPgpGtyCore.xdc"
   set_property PROCESSING_ORDER {EARLY}         [get_files {MpsPgpGtyCore.xdc}]
   set_property SCOPED_TO_REF    {MpsPgpGtyCore} [get_files {MpsPgpGtyCore.xdc}]
   set_property SCOPED_TO_CELLS  {inst}          [get_files {MpsPgpGtyCore.xdc}]   
   
   loadConstraints -path "$::DIR_PATH/coregen/${family}/MpsPgpGthCore.xdc"
   set_property PROCESSING_ORDER {EARLY}         [get_files {MpsPgpGthCore.xdc}]
   set_property SCOPED_TO_REF    {MpsPgpGthCore} [get_files {MpsPgpGthCore.xdc}]
   set_property SCOPED_TO_CELLS  {inst}          [get_files {MpsPgpGthCore.xdc}]      
   
}

if { [info exists ::env(APP_MPS_LNODE)] != 1 || $::env(APP_MPS_LNODE) == 0 } {

   if { $::env(PRJ_PART) == "XCKU040-FFVA1156-2-E" } {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu040.xdc"
   } elseif {  $::env(PRJ_PART) eq {XCKU060-FFVA1156-2-E} ||
               $::env(PRJ_PART) eq {XCKU095-FFVA1156-2-E} } {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu060.xdc"
   } else {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu11p.xdc"
   }
   
   if { $::env(VIVADO_VERSION) >= 2017.3 } {
      loadConstraints -path "$::env(MODULES)/surf/protocols/salt/xilinxUltraScale/xdc/SaltUltraScaleTxOnly.xdc"
      set_property PROCESSING_ORDER {EARLY}                [get_files {SaltUltraScaleTxOnly.xdc}]
      set_property SCOPED_TO_REF    {SaltUltraScaleTxOnly} [get_files {SaltUltraScaleTxOnly.xdc}]
      set_property SCOPED_TO_CELLS  {U0}                   [get_files {SaltUltraScaleTxOnly.xdc}]     
   }
} else {
   loadConstraints -path "$::DIR_PATH/xdc/MpsLinkNodeSaltSerdes.xdc"
   
   if { $::env(VIVADO_VERSION) >= 2017.3 } {
      loadConstraints -path "$::env(MODULES)/surf/protocols/salt/xilinxUltraScale/xdc/SaltUltraScaleRxOnly.xdc"
      set_property PROCESSING_ORDER {EARLY}                [get_files {SaltUltraScaleRxOnly.xdc}]
      set_property SCOPED_TO_REF    {SaltUltraScaleRxOnly} [get_files {SaltUltraScaleRxOnly.xdc}]
      set_property SCOPED_TO_CELLS  {U0}                   [get_files {SaltUltraScaleRxOnly.xdc}]     
   }
}
