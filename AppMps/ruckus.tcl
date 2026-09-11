# Load RUCKUS library
source $::env(RUCKUS_PROC_TCL)

# Get the FPGA architecture and map it onto the directory name that actually
# exists under rtl/ and coregen/. The FAMILY property is not usable here: on
# this part FAMILY and ARCHITECTURE both return the same string, but on other
# parts FAMILY collapses distinct architectures that need different sources.
set arch [getFpgaArch]
if { ${arch} eq {kintexu} ||
     ${arch} eq {virtexu} } {
   set family "kintexu"
} elseif { ${arch} eq {kintexuplus}     ||
           ${arch} eq {virtexuplus}     ||
           ${arch} eq {virtexuplusHBM}  ||
           ${arch} eq {zynquplus}       ||
           ${arch} eq {zynquplusRFSOC} } {
   set family "kintexuplus"
} else {
   # loadSource -dir on a directory that doesn't exist is a silent no-op in
   # ruckus, so falling through here would load zero AppMps RTL files and
   # still report success. Fail loudly instead.
   error "AppMps/ruckus.tcl: unsupported FPGA architecture '${arch}'; no AppMps rtl/coregen directory serves it"
}

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
   } elseif { $::env(PRJ_PART) eq {XCZU48DR-FFVG1517-2-E} } {
      # No AppMps/xdc file is loaded for this part. Everything in
      # MpsAppNodeKcu11p.xdc except the pblock is already present, with
      # correct hierarchy paths, in rfmc-carrier-core's own timing
      # constraints, and the pblock itself resizes to CLOCKREGION_X2Y6, a
      # clock region coordinate that does not exist on this die.
      puts "AppMps/ruckus.tcl: app-node placement constraints for this part are supplied by the carrier core, not AppMps/xdc"
   } else {
      loadConstraints -path "$::DIR_PATH/xdc/MpsAppNodeKcu11p.xdc"
   }

} else {

   if { $::env(PRJ_PART) eq {XCZU48DR-FFVG1517-2-E} } {
      # No AppMps/xdc file is loaded for this part. This board's
      # mpsBusRxP/N and mpsTxP/N are already pinned in the carrier-core
      # constraints independent of slot type, and the four scalar rtmHs
      # pin assignments in MpsLinkNodeSaltSerdes.xdc name ports that
      # AppMps does not have.
      puts "AppMps/ruckus.tcl: link-node placement constraints for this part are supplied by the carrier core, not AppMps/xdc"
   } else {
      loadConstraints -path "$::DIR_PATH/xdc/MpsLinkNodeSaltSerdes.xdc"
   }

}
