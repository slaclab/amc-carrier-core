-------------------------------------------------------------------------------
-- File       : RtmFastWireScanner.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-02-07
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/x/BBBODQ  
------------------------------------------------------------------------------
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmFastWireScanner is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Digital I/O Interface      
      encAmadIn       : in    slv(3 downto 0);
      encAmadTri      : in    slv(3 downto 0);
      encAmadOut      : out   slv(3 downto 0);
      encBmodin       : in    slv(3 downto 0);
      encBmodTri      : in    slv(3 downto 0);
      encBmodOut      : out   slv(3 downto 0);
      encIsldIn       : in    slv(3 downto 0);
      encIsldTri      : in    slv(3 downto 0);
      encIsldOut      : out   slv(3 downto 0);
      limit           : in    slv(3 downto 0);
      ok              : in    slv(3 downto 0);
      absInc          : out   slv(3 downto 0);
      -- AXI-Lite
      axilClk         : in    sl;
      axilRst         : in    sl;
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
end RtmFastWireScanner;

architecture mapping of RtmFastWireScanner is

begin

   ---------------------
   -- ABS/INC_[A,B,C,D]
   ---------------------      
   absInc(0) <= rtmLsN(0);
   absInc(1) <= rtmLsN(3);
   absInc(2) <= rtmLsN(11);
   absInc(3) <= rtmLsN(17);

   ---------------------
   -- OK_[A,B,C,D]
   ---------------------    
   rtmLsP(0)  <= ok(0);
   rtmLsP(3)  <= ok(1);
   rtmLsP(11) <= ok(2);
   rtmLsP(17) <= ok(3);

   ---------------------
   -- LIMIT_[A,B,C,D]
   ---------------------   
   rtmLsN(1)  <= limit(0);
   rtmLsN(4)  <= limit(1);
   rtmLsN(12) <= limit(2);
   rtmLsN(18) <= limit(3);

   ---------------------
   -- ENC_A/MA_[A,B,C,D]
   ---------------------
   U_encAmad_0 : IOBUF
      port map (
         I  => encAmadIn(0),
         T  => encAmadTri(0),
         O  => encAmadOut(0),
         IO => rtmLsP(2));

   U_encAmad_1 : IOBUF
      port map (
         I  => encAmadIn(1),
         T  => encAmadTri(1),
         O  => encAmadOut(1),
         IO => rtmLsP(5));

   U_encAmad_2 : IOBUF
      port map (
         I  => encAmadIn(2),
         T  => encAmadTri(2),
         O  => encAmadOut(2),
         IO => rtmLsP(13));

   U_encAmad_3 : IOBUF
      port map (
         I  => encAmadIn(3),
         T  => encAmadTri(3),
         O  => encAmadOut(3),
         IO => rtmLsP(19));

   ---------------------
   -- ENC_B/MO_[A,B,C,D]
   ---------------------
   U_encBmod_0 : IOBUF
      port map (
         I  => encBmodIn(0),
         T  => encBmodTri(0),
         O  => encBmodOut(0),
         IO => rtmLsN(2));

   U_encBmod_1 : IOBUF
      port map (
         I  => encBmodIn(1),
         T  => encBmodTri(1),
         O  => encBmodOut(1),
         IO => rtmLsN(5));

   U_encBmod_2 : IOBUF
      port map (
         I  => encBmodIn(2),
         T  => encBmodTri(2),
         O  => encBmodOut(2),
         IO => rtmLsN(13));

   U_encBmod_3 : IOBUF
      port map (
         I  => encBmodIn(3),
         T  => encBmodTri(3),
         O  => encBmodOut(3),
         IO => rtmLsN(19));

   ---------------------
   -- ENC_I/SL_[A,B,C,D]
   ---------------------
   U_encIsld_0 : IOBUF
      port map (
         I  => encIsldIn(0),
         T  => encIsldTri(0),
         O  => encIsldOut(0),
         IO => rtmLsP(1));

   U_encIsld_1 : IOBUF
      port map (
         I  => encIsldIn(1),
         T  => encIsldTri(1),
         O  => encIsldOut(1),
         IO => rtmLsP(14));

   U_encIsld_2 : IOBUF
      port map (
         I  => encIsldIn(2),
         T  => encIsldTri(2),
         O  => encIsldOut(2),
         IO => rtmLsP(12));

   U_encIsld_3 : IOBUF
      port map (
         I  => encIsldIn(3),
         T  => encIsldTri(3),
         O  => encIsldOut(3),
         IO => rtmLsP(18));

   --------------------------------
   -- Terminate Unused AXI-Lite Bus
   --------------------------------
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

end mapping;
