-------------------------------------------------------------------------------
-- File       : RtmMpsLinkNode.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2017-11-10
-------------------------------------------------------------------------------
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_07_CXX
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

entity RtmMpsLinkNode is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Digital I/O Interface
      dout            : in    slv(7 downto 0);
      din             : out   slv(31 downto 0);
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
end RtmMpsLinkNode;

architecture mapping of RtmMpsLinkNode is

   signal rtmDin  : slv(31 downto 0);
   signal rtmDout : slv(7 downto 0);

   signal unusedRefClk                  : sl;
   attribute dont_touch                 : string;
   attribute dont_touch of unusedRefClk : signal is "TRUE";   

begin

   U_unusedRefClk : entity work.AmcCarrierIbufGt
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
         
   din     <= rtmDin;
   rtmDout <= dout;

   GEN_DIN :
   for i in 31 downto 0 generate

      U_IBUFDS : IBUFDS
         port map (
            I  => rtmLsP(i+0),
            IB => rtmLsN(i+0),
            O  => rtmDin(i));

   end generate GEN_DIN;

   GEN_DOUT :
   for i in 7 downto 0 generate

      U_OBUFDS : OBUFDS
         port map (
            I  => rtmDout(i),
            O  => rtmLsP(i+32),
            OB => rtmLsN(i+32));

   end generate GEN_DOUT;

   U_Monitor : entity work.RtmMpsLinkNodeReg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- RTM Interface
         din             => rtmDin,
         dout            => rtmDout);

end mapping;
