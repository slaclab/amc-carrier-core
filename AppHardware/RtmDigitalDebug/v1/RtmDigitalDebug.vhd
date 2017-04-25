-------------------------------------------------------------------------------
-- File       : RtmDigitalDebug.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2017-04-04
-------------------------------------------------------------------------------
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_10_CXX
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Common Carrier Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmDigitalDebug is
   generic (
      TPD_G            : time             := 1 ns;
      REG_DOUT_EN_G    : slv(15 downto 0) := x"0000";  -- '1' = registered, '0' = unregistered
      REG_DOUT_MODE_G  : slv(15 downto 0) := x"0000";  -- If registered enabled, '1' = clk output, '0' = data output
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C);
   port (
      -- Digital I/O Interface
      dout            : in    slv(15 downto 0);
      doutClk         : in    slv(15 downto 0)       := x"0000";
      din             : out   slv(15 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl                     := '0';
      axilRst         : in    sl                     := '0';
      axilReadMaster  : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- RTM's Low Speed Ports
      rtmLsP          : inout slv(53 downto 0);
      rtmLsN          : inout slv(53 downto 0);
      --  RTM's Clock Reference
      genClkP         : in    sl;
      genClkN         : in    sl);
end RtmDigitalDebug;

architecture mapping of RtmDigitalDebug is

   signal doutReg : slv(15 downto 0);

begin

   GEN_VEC :
   for i in 15 downto 0 generate

      NON_REG : if (REG_DOUT_EN_G(i) = '0') generate
         U_OBUFDS : OBUFDS
            port map (
               I  => dout(i),
               O  => rtmLsP(i+16),
               OB => rtmLsN(i+16));
      end generate;

      REG_OUT : if (REG_DOUT_EN_G(i) = '1') generate

         REG_DATA : if (REG_DOUT_MODE_G(i) = '0') generate
            U_ODDR : ODDRE1
               port map (
                  C  => doutClk(i),
                  Q  => doutReg(i),
                  D1 => dout(i),
                  D2 => dout(i),
                  SR => '0');
            U_OBUFDS : OBUFDS
               port map (
                  I  => doutReg(i),
                  O  => rtmLsP(i+16),
                  OB => rtmLsN(i+16));
         end generate;

         REG_CLK : if (REG_DOUT_MODE_G(i) = '1') generate
            U_CLK : entity work.ClkOutBufDiff
               generic map (
                  TPD_G        => TPD_G,
                  XIL_DEVICE_G => "ULTRASCALE")
               port map (
                  clkIn   => doutClk(i),
                  clkOutP => rtmLsP(i+16),
                  clkOutN => rtmLsN(i+16));
         end generate;

      end generate;

      U_IBUFDS : IBUFDS
         port map (
            I  => rtmLsP(i+0),
            IB => rtmLsN(i+0),
            O  => din(i));

   end generate GEN_VEC;

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

end mapping;
