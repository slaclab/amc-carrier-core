##############################################################################
## This file is part of 'LCLS2 Common Carrier Core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 Common Carrier Core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

############
## Inputs ##
############
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[0]}] ; #dout[0]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[0]}] ; #dout[0]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[1]}] ; #dout[1]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[1]}] ; #dout[1]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[2]}] ; #dout[2]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[2]}] ; #dout[2]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[3]}] ; #dout[3]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[3]}] ; #dout[3]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[4]}] ; #dout[4]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[4]}] ; #dout[4]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[5]}] ; #dout[5]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[5]}] ; #dout[5]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[6]}] ; #dout[6]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[6]}] ; #dout[6]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[7]}] ; #dout[7]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[7]}] ; #dout[7]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[8]}] ; #dout[8]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[8]}] ; #dout[8]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[9]}] ; #dout[9]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[9]}] ; #dout[9]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[10]}] ; #dout[10]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[10]}] ; #dout[10]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[11]}] ; #dout[11]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[11]}] ; #dout[11]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[12]}] ; #dout[12]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[12]}] ; #dout[12]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[13]}] ; #dout[13]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[13]}] ; #dout[13]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[14]}] ; #dout[14]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[14]}] ; #dout[14]

set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsP[15]}] ; #dout[15]
set_property -dict { IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports {rtmLsN[15]}] ; #dout[15]

#############
## Outputs ##
#############

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[16]}] ; #din[0]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[16]}] ; #din[0]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[17]}] ; #din[1]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[17]}] ; #din[1]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[18]}] ; #din[2]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[18]}] ; #din[2]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[19]}] ; #din[3]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[19]}] ; #din[3]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[20]}] ; #din[4]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[20]}] ; #din[4]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[21]}] ; #din[5]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[21]}] ; #din[5]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[22]}] ; #din[6]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[22]}] ; #din[6]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[23]}] ; #din[7]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[23]}] ; #din[7]

set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsP[24]}] ; #din[8]
set_property -dict { IOSTANDARD LVDS } [get_ports {rtmLsN[24]}] ; #din[8]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[25]}] ; #din[9]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[25]}] ; #din[9]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[26]}] ; #din[10]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[26]}] ; #din[10]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[27]}] ; #din[11]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[27]}] ; #din[11]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[28]}] ; #din[12]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[28]}] ; #din[12]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[29]}] ; #din[13]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[29]}] ; #din[13]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[30]}] ; #din[14]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[30]}] ; #din[14]

set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsP[31]}] ; #din[15]
set_property -dict { IOSTANDARD LVDS_25 } [get_ports {rtmLsN[31]}] ; #din[15]
