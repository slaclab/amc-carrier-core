-------------------------------------------------------------------------------
-- File       : RtmLoopback.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2017-03-09
-------------------------------------------------------------------------------
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_22_CXX
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

entity RtmLoopback is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Loopback Interface
      loopbackIn      : in    slv(9 downto 0);
      loopbackOut     : out   slv(9 downto 0);
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
end RtmLoopback;

architecture mapping of RtmLoopback is

   signal unusedRefClk                  : sl;
   attribute dont_touch                 : string;
   attribute dont_touch of unusedRefClk : signal is "TRUE";   

begin

   U_unusedRefClk : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => genClkP,
         IB    => genClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => unusedRefClk);

   GEN_VEC :
   for i in 9 downto 0 generate

      U_OBUFDS : OBUFDS
         port map (
            I  => loopbackIn(i),
            O  => rtmLsP((2*i)+0),
            OB => rtmLsN((2*i)+0));

      U_IBUFDS : IBUFDS
         port map (
            I  => rtmLsP((2*i)+1),
            IB => rtmLsN((2*i)+1),
            O  => loopbackOut(i));

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
