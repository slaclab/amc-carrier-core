##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LCLS2 Common Carrier Core', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######################
## Common Core Ports ##
#######################

set_property PACKAGE_PIN T31 [get_ports {ethTxP[0]}]
set_property PACKAGE_PIN T32 [get_ports {ethTxN[0]}]
set_property PACKAGE_PIN R33 [get_ports {ethRxP[0]}]
set_property PACKAGE_PIN R34 [get_ports {ethRxN[0]}]
set_property PACKAGE_PIN P31 [get_ports {ethTxP[1]}]
set_property PACKAGE_PIN P32 [get_ports {ethTxN[1]}]
set_property PACKAGE_PIN N33 [get_ports {ethRxP[1]}]
set_property PACKAGE_PIN N34 [get_ports {ethRxN[1]}]
set_property PACKAGE_PIN M31 [get_ports {ethTxP[2]}]
set_property PACKAGE_PIN M32 [get_ports {ethTxN[2]}]
set_property PACKAGE_PIN L33 [get_ports {ethRxP[2]}]
set_property PACKAGE_PIN L34 [get_ports {ethRxN[2]}]
set_property PACKAGE_PIN K31 [get_ports {ethTxP[3]}]
set_property PACKAGE_PIN K32 [get_ports {ethTxN[3]}]
set_property PACKAGE_PIN J33 [get_ports {ethRxP[3]}]
set_property PACKAGE_PIN J34 [get_ports {ethRxN[3]}]

set_property PACKAGE_PIN D31 [get_ports {rtmHsTxP}]
set_property PACKAGE_PIN D32 [get_ports {rtmHsTxN}]
set_property PACKAGE_PIN E33 [get_ports {rtmHsRxP}]
set_property PACKAGE_PIN E34 [get_ports {rtmHsRxN}]

#############################
## Core Timing Constraints ##
#############################

create_generated_clock -name ethPhyClk    [get_pins {U_Core/U_Core/U_Eth/U_Xaui/XauiGtyUltraScale_Inst/U_XauiGtyUltraScaleCore/U0/XauiGtyUltraScale156p25MHz10GigECore_gt_i/inst/gen_gtwizard_gtye4_top.XauiGtyUltraScale156p25MHz10GigECore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethPhyClk}] 
set_false_path -to   [get_cells -hierarchical -filter {NAME =~ *plllocked_sync_i/sync1_r_reg[0]}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *uclk_mgt_tx_reset_reg}] -to [get_cells -hierarchical -filter {NAME =~ *mgt_tx_reset_pulse_stretcher_i/sync_r_reg[*]}]
set_false_path -from [get_cells -hierarchical -filter {NAME =~ *uclk_mgt_rx_reset_reg}] -to [get_cells -hierarchical -filter {NAME =~ *mgt_rx_reset_pulse_stretcher_i/sync_r_reg[*]}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta_reg/PRE}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1_reg/PRE}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2_reg/PRE}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3_reg/PRE}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out_reg/PRE}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta_reg/CLR}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1_reg/CLR}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2_reg/CLR}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3_reg/CLR}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out_reg/CLR}]

set_clock_groups -asynchronous -group [get_clocks {ethPhyClk}] -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Xaui/XauiGtyUltraScale_Inst/U_XauiGtyUltraScaleCore/U0/XauiGtyUltraScale156p25MHz10GigECore_gt_i/inst/gen_gtwizard_gtye4_top.XauiGtyUltraScale156p25MHz10GigECore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {ethPhyClk}] -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Xaui/XauiGtyUltraScale_Inst/U_XauiGtyUltraScaleCore/U0/XauiGtyUltraScale156p25MHz10GigECore_gt_i/inst/gen_gtwizard_gtye4_top.XauiGtyUltraScale156p25MHz10GigECore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {ethPhyClk}] -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Xaui/XauiGtyUltraScale_Inst/U_XauiGtyUltraScaleCore/U0/XauiGtyUltraScale156p25MHz10GigECore_gt_i/inst/gen_gtwizard_gtye4_top.XauiGtyUltraScale156p25MHz10GigECore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -asynchronous -group [get_clocks {ethPhyClk}] -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Xaui/XauiGtyUltraScale_Inst/U_XauiGtyUltraScaleCore/U0/XauiGtyUltraScale156p25MHz10GigECore_gt_i/inst/gen_gtwizard_gtye4_top.XauiGtyUltraScale156p25MHz10GigECore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]]

create_generated_clock -name ethClk125MHz  [get_pins {U_Core/U_Core/U_Eth/U_Rtm/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}] 
create_generated_clock -name ethClk62p5MHz [get_pins {U_Core/U_Core/U_Eth/U_Rtm/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}] 
set_clock_groups -asynchronous -group [get_clocks {ethRef}] -group [get_clocks {ethClk125MHz}] 
set_clock_groups -asynchronous -group [get_clocks {ethRef}] -group [get_clocks {ethClk62p5MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethClk125MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethClk62p5MHz}] 
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {ethRef}] 

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Rtm/GEN_LANE[0].U_GigEthGtyUltraScale/U_GigEthGtyUltraScaleCore/U0/transceiver_inst/GigEthGtyUltraScaleCore_gt_i/inst/gen_gtwizard_gtye4_top.GigEthGtyUltraScaleCore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_Eth/U_Rtm/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_Eth/U_Rtm/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1]] -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Rtm/GEN_LANE[0].U_GigEthGtyUltraScale/U_GigEthGtyUltraScaleCore/U0/transceiver_inst/GigEthGtyUltraScaleCore_gt_i/inst/gen_gtwizard_gtye4_top.GigEthGtyUltraScaleCore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]


set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Eth/U_Rtm/GEN_LANE[0].U_GigEthGtyUltraScale/U_GigEthGtyUltraScaleCore/U0/transceiver_inst/GigEthGtyUltraScaleCore_gt_i/inst/gen_gtwizard_gtye4_top.GigEthGtyUltraScaleCore_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_Eth/U_Rtm/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_Core/U_Core/U_Timing/TimingGthCoreWrapper_1/LOCREF_G.U_TimingGtyCore/inst/gen_gtwizard_gtye4_top.TimingGty_fixedlat_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[2].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins U_Core/U_Core/U_Timing/TIMING_REFCLK_IBUFDS_GTE3/U_IBUFDS_GT/ODIV2]]
