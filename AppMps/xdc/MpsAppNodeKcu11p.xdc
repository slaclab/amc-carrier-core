##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 Common Carrier Core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

################################
## Area/Placement Constraints ##
################################

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_IBUF/O]

# set_property LOC PLL_X0Y4 [get_cells {U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_MpsSerdesPll}]

# set_property LOC BUFGCE_X0Y50    [get_cells {U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_Bufg625}]
# set_property LOC BUFGCE_DIV_X0Y8 [get_cells {U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_Bufg156}]
# set_property LOC BUFGCE_X0Y49    [get_cells {U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_Bufg125}]

# set_property LOC HPIOBDIFFOUTBUF_X0Y144 [get_cells {U_Core/GEN_EN_MPS.U_AppMps/U_Salt/APP_SLOT.U_SaltUltraScale/TX_ONLY.U_SaltUltraScaleCore/U0/lvds_transceiver_mw/serdes_10_to_1_ser8_i/io_data_out}]
# set_property LOC BITSLICE_RX_TX_X0Y312  [get_cells {U_Core/GEN_EN_MPS.U_AppMps/U_Salt/APP_SLOT.U_SaltUltraScale/TX_ONLY.U_SaltUltraScaleCore/U0/lvds_transceiver_mw/serdes_10_to_1_ser8_i/oserdes_m}]

create_pblock MPS_RTL_GRP
add_cells_to_pblock [get_pblocks MPS_RTL_GRP] [get_cells [list U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_MpsSerdesPll]]
add_cells_to_pblock [get_pblocks MPS_RTL_GRP] [get_cells [list U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_Bufg625]]
add_cells_to_pblock [get_pblocks MPS_RTL_GRP] [get_cells [list U_Core/GEN_EN_MPS.U_AppMps/U_Clk/U_Bufg156]]
add_cells_to_pblock [get_pblocks MPS_RTL_GRP] [get_cells [list U_Core/GEN_EN_MPS.U_AppMps/U_Salt/APP_SLOT.U_SaltUltraScale]]
resize_pblock [get_pblocks MPS_RTL_GRP] -add {CLOCKREGION_X2Y6:CLOCKREGION_X2Y6}

##########################
## Misc. Configurations ##
##########################

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Timing/TimingGthCoreWrapper_1/LOCREF_G.U_TimingGtyCore/inst/gen_gtwizard_gtye4_top.TimingGty_fixedlat_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_Timing/TimingGthCoreWrapper_1/LOCREF_G.TIMING_TXCLK_BUFG_GT/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_Timing/TIMING_REFCLK_IBUFDS_GTE3/U_IBUFDS_GT/ODIV2]] -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Timing/TimingGthCoreWrapper_1/LOCREF_G.U_TimingGtyCore/inst/gen_gtwizard_gtye4_top.TimingGty_fixedlat_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[3].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]
