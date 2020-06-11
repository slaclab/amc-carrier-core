-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmLoopback is
   generic (
      TPD_G : time := 1 ns);
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

begin

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

   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

end mapping;
