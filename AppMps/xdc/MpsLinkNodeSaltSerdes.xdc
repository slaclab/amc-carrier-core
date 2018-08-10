##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property PACKAGE_PIN B6 [get_ports rtmHsTxP]
set_property PACKAGE_PIN B5 [get_ports rtmHsTxN]
set_property PACKAGE_PIN A4 [get_ports rtmHsRxP]
set_property PACKAGE_PIN A3 [get_ports rtmHsRxN]

set_property DIFF_TERM_ADV TERM_100 [get_ports {mpsBusRxP[*]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mpsBusRxN[*]}]

set_false_path -to [get_pins U_Core/U_AppMps/U_Salt/MPS_SLOT.U_SaltDelayCtrl/SALT_IDELAY_CTRL_Inst/RST]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.U_SaltDelayCtrl/SALT_IDELAY_CTRL_Inst*}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/*/idelay_cal}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/*/idelay_m}]
set_property IODELAY_GROUP MPS_IODELAY_GRP [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/*/idelay_s}]

# set_property LOC MMCME3_ADV_X0Y1 [get_cells {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/MmcmGen.U_Mmcm}]

# set_property LOC BUFGCE_X0Y24 [get_cells {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/ClkOutGen[0].U_Bufg}]
# set_property LOC BUFGCE_X0Y28 [get_cells {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/ClkOutGen[1].U_Bufg}]
# set_property LOC BUFGCE_X0Y32 [get_cells {U_Core/U_AppMps/U_Clk/U_ClkManagerMps/ClkOutGen[2].U_Bufg}]

#####################################
## Core Area/Placement Constraints ##
#####################################

# SALT MPS Backplane: CH1
set_property LOC BITSLICE_RX_TX_X0Y94  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[1].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y91  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[1].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y91  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[1].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y92  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[1].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y92  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[1].*/iserdes_s}]

# SALT MPS Backplane: CH2
set_property LOC BITSLICE_RX_TX_X0Y95  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[2].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y88  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[2].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y88  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[2].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y89  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[2].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y89  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[2].*/iserdes_s}]

# SALT MPS Backplane: CH3
set_property LOC BITSLICE_RX_TX_X0Y96  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[3].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y86  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[3].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y86  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[3].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y87  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[3].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y87  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[3].*/iserdes_s}]

# SALT MPS Backplane: CH4
set_property LOC BITSLICE_RX_TX_X0Y97  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[4].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y84  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[4].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y84  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[4].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y85  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[4].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y85  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[4].*/iserdes_s}]

# SALT MPS Backplane: CH5
set_property LOC BITSLICE_RX_TX_X0Y98  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[5].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y82  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[5].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y82  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[5].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y83  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[5].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y83  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[5].*/iserdes_s}]

# SALT MPS Backplane: CH6
set_property LOC BITSLICE_RX_TX_X0Y99  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[6].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y71  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[6].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y71  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[6].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y72  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[6].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y72  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[6].*/iserdes_s}]

# SALT MPS Backplane: CH7
set_property LOC BITSLICE_RX_TX_X0Y100 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[7].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y69  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[7].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y69  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[7].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y70  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[7].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y70  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[7].*/iserdes_s}]

# SALT MPS Backplane: CH8
set_property LOC BITSLICE_RX_TX_X0Y101 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[8].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y67  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[8].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y67  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[8].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y68  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[8].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y68  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[8].*/iserdes_s}]

# SALT MPS Backplane: CH9
set_property LOC BITSLICE_RX_TX_X0Y102 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[9].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y65  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[9].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y65  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[9].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y66  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[9].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y66  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[9].*/iserdes_s}]

# SALT MPS Backplane: CH10
set_property LOC BITSLICE_RX_TX_X0Y103 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[10].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y62  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[10].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y62  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[10].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y63  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[10].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y63  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[10].*/iserdes_s}]

# SALT MPS Backplane: CH11
set_property LOC BITSLICE_RX_TX_X0Y105 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[11].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y60  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[11].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y60  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[11].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y61  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[11].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y61  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[11].*/iserdes_s}]

# SALT MPS Backplane: CH12
set_property LOC BITSLICE_RX_TX_X0Y107 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[12].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y58  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[12].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y58  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[12].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y59  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[12].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y59  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[12].*/iserdes_s}]

# SALT MPS Backplane: CH13
set_property LOC BITSLICE_RX_TX_X0Y111 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[13].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y56  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[13].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y56  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[13].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y57  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[13].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y57  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[13].*/iserdes_s}]

# SALT MPS Backplane: CH14
set_property LOC BITSLICE_RX_TX_X0Y113 [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[14].*/idelay_cal}]
set_property LOC BITSLICE_RX_TX_X0Y54  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[14].*/idelay_m}]
set_property LOC BITSLICE_RX_TX_X0Y54  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[14].*/iserdes_m}]
set_property LOC BITSLICE_RX_TX_X0Y55  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[14].*/idelay_s}]
set_property LOC BITSLICE_RX_TX_X0Y55  [get_cells -hier -filter {name =~ U_Core/U_AppMps/U_Salt/MPS_SLOT.GEN_VEC[14].*/iserdes_s}]

##########################
## Misc. Configurations ##
##########################
