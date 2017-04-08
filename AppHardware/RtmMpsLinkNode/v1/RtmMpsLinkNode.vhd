-------------------------------------------------------------------------------
-- File       : RtmMpsLinkNode.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2017-02-23
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

begin
   
   GEN_DIN :
   for i in 31 downto 0 generate

      U_IBUFDS : IBUFDS
         port map (
            I  => rtmLsP(i+0),
            IB => rtmLsN(i+0),
            O  => din(i));

   end generate GEN_DIN;   

   GEN_DOUT :
   for i in 7 downto 0 generate

      U_OBUFDS : OBUFDS
         port map (
            I  => dout(i),
            O  => rtmLsP(i+32),
            OB => rtmLsN(i+32));

   end generate GEN_DOUT;

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
