# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

####################################################################################
## Create the SubmoduleCheck() because didn't exist in vivado_proc.tcl before v1.3.2 
####################################################################################
proc SubmoduleCheck { name lockTag } {
   # Get the full git submodule string for a particular module
   set submodule [exec git -C $::env(MODULES) submodule status -- ${name}]
   # Scan for the hash, name, and tag portions of the string
   scan $submodule "%s %s (v%s)" hash temp tag
   # Blowoff everything except for the major, minor, and patch numbers
   scan $tag     "%d.%d.%d%s" major minor patch d
   scan $lockTag "%d.%d.%d" majorLock minorLock patchLock
   set tag [string map [list $d ""] $tag]
   
   ###################################################################
   # Major Number Checking
   ###################################################################
   # major.X.X < majorLock.X.X
   if { [expr { ${major} < ${majorLock} }] } {
      set validTag 0
   # major.X.X = majorLock.X.X
   } elseif { [expr { ${major} == ${majorLock} }] } {
      ################################################################
      # Minor Number Checking
      ################################################################
      # major.minor.X < major.minorLock.X
      if { [expr { ${minor} < ${minorLock} }] } {
         set validTag 0
      # major.minor.X = major.minorLock.X
      } elseif { [expr { ${minor} == ${minorLock} }] } {
         #############################################################
         # Patch Number Checking
         #############################################################
         # major.minor.patch < major.minor.patchLock
         if { [expr { ${patch} < ${patchLock} }] } {
            set validTag 0
         # major.minor.patch = major.minor.patchLock
         } elseif { [expr { ${patch} == ${patchLock} }] } {
            set validTag 1
         # major.minor.patch > major.minor.patchLock
         } else { 
            set validTag 1
         }     
      ################################################################
      # major.minor.X > major.minorLock.X
      } else { 
         set validTag 1
      }   
   ###################################################################
   # major.X.X > majorLock.X.X
   } else { 
      set validTag 1
   }   
   # Check the validTag flag
   if { ${validTag} != 1 } {
      puts "\n\n*********************************************************"
      puts "Your git clone ${name} = v${tag}"
      puts "However, ${name} Lock  = v${lockTag}"
      puts "Please update this submodule tag to v${lockTag} (or later)"
      puts "*********************************************************\n\n"
      return -1
   } elseif { ${major} == ${majorLock} && ${minor} == ${minorLock} && ${patch} == ${patchLock} } {
      return 0
   } else { 
      return 1
   }
}

## Check for submodule tagging
if { [SubmoduleCheck {ruckus}             {1.4.0} ] < 0 } {exit -1}
if { [SubmoduleCheck {surf}               {1.3.8} ] < 0 } {exit -1}
if { [SubmoduleCheck {lcls-timing-core}   {1.7.3} ] < 0 } {exit -1}

## Check for version 2016.4 of Vivado
if { [VersionCheck 2016.4] < 0 } {exit -1}

# Check if required variables exist
if { [info exists ::env(AMC_ADV_BUILD)] != 1 }  {puts "\n\nERROR: AMC_ADV_BUILD is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(RTM_ETH)] != 1 }        {puts "\n\nERROR: RTM_ETH is not defined in $::env(PROJ_DIR)/Makefile\n\n";         exit -1}
if { [info exists ::env(AMC_TYPE_BAY0)] != 1 }  {puts "\n\nERROR: AMC_TYPE_BAY0 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(AMC_INTF_BAY0)] != 1 }  {puts "\n\nERROR: AMC_INTF_BAY0 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(AMC_TYPE_BAY1)] != 1 }  {puts "\n\nERROR: AMC_TYPE_BAY1 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(AMC_INTF_BAY1)] != 1 }  {puts "\n\nERROR: AMC_INTF_BAY1 is not defined in $::env(PROJ_DIR)/Makefile\n\n";   exit -1}
if { [info exists ::env(RTM_TYPE)] != 1 }       {puts "\n\nERROR: RTM_TYPE is not defined in $::env(PROJ_DIR)/Makefile\n\n";        exit -1}
if { [info exists ::env(RTM_INTF)] != 1 }       {puts "\n\nERROR: RTM_INTF is not defined in $::env(PROJ_DIR)/Makefile\n\n";        exit -1}
if { [info exists ::env(COMMON_FILE)] != 1 }    {puts "\n\nERROR: COMMON_FILE is not defined in $::env(PROJ_DIR)/Makefile\n\n";     exit -1}
if { ( $::env(AMC_ADV_BUILD)  != 1) && ( $::env(RTM_ETH)  != 0) } {puts "\n\nERROR: (AMC_ADV_BUILD = 0) and (RTM_ETH = 1) is NOT supported!!!\n\n\n\n"; exit -1}

# Load ruckus files
loadRuckusTcl "$::DIR_PATH/AmcCarrierCore"   "quiet"
loadRuckusTcl "$::DIR_PATH/BsaCore"          "quiet"
loadRuckusTcl "$::DIR_PATH/AppTop"           
loadRuckusTcl "$::DIR_PATH/AppMps"           
loadRuckusTcl "$::DIR_PATH/DacSigGen"        "quiet"
loadRuckusTcl "$::DIR_PATH/DaqMuxV2"         "quiet"
loadRuckusTcl "$::DIR_PATH/AppHardware"
