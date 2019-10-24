-------------------------------------------------------------------------------
-- File       : RtmMpsLinkNode.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2018-03-14
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

library amc_carrier_core; 

entity RtmMpsLinkNode is
   generic (
      TPD_G : time := 1 ns);
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

   signal doutL : slv(7 downto 0);
   signal dinL  : slv(31 downto 0);

   signal rtmDin      : slv(31 downto 0);
   signal rtmDout     : slv(7 downto 0);
   signal rtmDoutMask : slv(7 downto 0);

begin

   din     <= rtmDin;
   rtmDout <= dout or rtmDoutMask;

   rtmDin <= not(dinL);
   doutL  <= not(rtmDout);

   GEN_DIN :
   for i in 15 downto 0 generate

      U_IBUF_P : IBUF
         port map (
            I => rtmLsP(i+0),
            O => dinL(i+0));

      U_IBUF_N : IBUF
         port map (
            I => rtmLsN(i+0),
            O => dinL(i+16));

   end generate GEN_DIN;

   GEN_DOUT :
   for i in 3 downto 0 generate

      U_OBUF_P : OBUF
         port map (
            I => doutL((2*i)+0),
            O => rtmLsP(i+16));

      U_OBUF_N : OBUF
         port map (
            I => doutL((2*i)+1),
            O => rtmLsN(i+16));

   end generate GEN_DOUT;

   U_Monitor : entity amc_carrier_core.RtmMpsLinkNodeReg
      generic map (
         TPD_G => TPD_G)
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
         dout            => rtmDout,
         doutMask        => rtmDoutMask);

end mapping;
