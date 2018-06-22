##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareP[0][0]}] ; 
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {spareN[0][0]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][1]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][1]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareP[0][2]}] ; 
set_property -dict { IOSTANDARD LVDS } [get_ports {spareN[0][2]}] ; 

# JESD ADC Sync Ports
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][0]}] ; #jesdRxSyncP[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][0]}] ; #jesdRxSyncN[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][1]}] ; #jesdRxSyncP[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][1]}] ; #jesdRxSyncN[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][2]}] ; #jesdTxSyncP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][2]}] ; #jesdTxSyncN[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutP[0][3]}] ; #jesdTxSyncP[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncOutN[0][3]}] ; #jesdTxSyncN[0]

set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[0][2]}] ; #lmkRst[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInP[0][3]}];
set_property -dict { IOSTANDARD LVDS } [get_ports {syncInN[0][3]}];
#set_property -dict { IOSTANDARD LVDS } [get_ports {jtagPri[0][1]}];

# Pass through Interfaces
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][0]}] ; #lemoDinP[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][0]}] ; #lemoDinN[0][0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInP[0][1]}] ; #lemoDinP[0][1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {syncInN[0][1]}] ; #lemoDinN[0][1]
