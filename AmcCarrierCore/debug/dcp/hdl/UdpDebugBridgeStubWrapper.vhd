-------------------------------------------------------------------------------
-- Title      : XVC Debug Bridge Support
-------------------------------------------------------------------------------
-- File       : UdpDebugBridgeStubWrapper.vhd
-- Author     : Till Straumann <strauman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-05
-- Last update: 2017-12-05
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;

library amc_carrier_core;
use amc_carrier_core.UdpDebugBridgePkg.all;

-- AxisJtagDebugBridge Configured for AmcCarrierCore

entity UdpDebugBridge is
   port (
      axisClk          : in sl;
      axisRst          : in sl;

      mAxisReq         : in  AxiStreamMasterType;
      sAxisReq         : out AxiStreamSlaveType;

      mAxisTdo         : out AxiStreamMasterType;
      sAxisTdo         : in  AxiStreamSlaveType
   );
end entity UdpDebugBridge;

architecture UdpDebugBridgeImpl of UdpDebugBridge is
begin

   U_AxisJtagDebugBridge : entity surf.AxisJtagDebugBridge(AxisJtagDebugBridgeStub)
      generic map (
         AXIS_FREQ_G         => XVC_ACLK_FREQ_C,
         CLK_DIV2_G          => XVC_TCLK_DIV2_C,
         AXIS_WIDTH_G        => XVC_AXIS_WIDTH_C,
         MEM_DEPTH_G         => XVC_MEM_DEPTH_C,
         MEM_STYLE_G         => XVC_MEM_STYLE_C
      )
      port map (
         axisClk             => axisClk,
         axisRst             => axisRst,

         mAxisReq            => mAxisReq,
         sAxisReq            => sAxisReq,

         mAxisTdo            => mAxisTdo,
         sAxisTdo            => sAxisTdo
      );

end architecture UdpDebugBridgeImpl;
