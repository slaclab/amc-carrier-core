-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmFastWireScanner is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Digital I/O Interface      
--      encAmadIn       : in    slv(3 downto 0);
--      encAmadTri      : in    slv(3 downto 0);
      encAmadOut      : out   slv(3 downto 0);
--      encBmodin       : in    slv(3 downto 0);
--      encBmodTri      : in    slv(3 downto 0);
      encBmodOut      : out   slv(3 downto 0);
--      encIsldIn       : in    slv(3 downto 0);
--      encIsldTri      : in    slv(3 downto 0);
      encIsldOut      : out   slv(3 downto 0);
      limit           : out   slv(3 downto 0);
      ok              : out   slv(3 downto 0);
      absInc          : in    slv(3 downto 0);
      spareIn         : in    slv(3 downto 0);
      spareTri        : in    slv(3 downto 0);
      spareOut        : out   slv(3 downto 0);
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
   rtmLsN(0)  <= absInc(0);
   rtmLsN(3)  <= absInc(1);
   rtmLsN(11) <= absInc(2);
   rtmLsN(17) <= absInc(3);

   ---------------------
   -- OK_[A,B,C,D]
   ---------------------    
   ok(0) <= rtmLsP(0);
   ok(1) <= rtmLsP(3);
   ok(2) <= rtmLsP(11);
   ok(3) <= rtmLsP(17);

   ---------------------
   -- LIMIT_[A,B,C,D]
   ---------------------   
   limit(0) <= rtmLsN(1);
   limit(1) <= rtmLsN(4);
   limit(2) <= rtmLsN(12);
   limit(3) <= rtmLsN(18);

   ---------------------
   -- ENC_A/MA_[A,B,C,D]
   ---------------------
   encAmadOut(0) <= rtmLsP(2);
   encAmadOut(1) <= rtmLsP(5);
   encAmadOut(2) <= rtmLsP(13);
   encAmadOut(3) <= rtmLsP(19);
   
   -- ONLY INPUT CAN BE USED
   -- U_encAmad_0 : IOBUF
      -- port map (
         -- I  => encAmadIn(0),
         -- T  => encAmadTri(0),
         -- O  => encAmadOut(0),
         -- IO => rtmLsP(2));

   -- U_encAmad_1 : IOBUF
      -- port map (
         -- I  => encAmadIn(1),
         -- T  => encAmadTri(1),
         -- O  => encAmadOut(1),
         -- IO => rtmLsP(5));

   -- U_encAmad_2 : IOBUF
      -- port map (
         -- I  => encAmadIn(2),
         -- T  => encAmadTri(2),
         -- O  => encAmadOut(2),
         -- IO => rtmLsP(13));

   -- U_encAmad_3 : IOBUF
      -- port map (
         -- I  => encAmadIn(3),
         -- T  => encAmadTri(3),
         -- O  => encAmadOut(3),
         -- IO => rtmLsP(19));

   ---------------------
   -- ENC_B/MO_[A,B,C,D]
   ---------------------
   encBmodOut(0) <= rtmLsN(2);
   encBmodOut(1) <= rtmLsN(5);
   encBmodOut(2) <= rtmLsN(13);
   encBmodOut(3) <= rtmLsN(19);
   
   -- ONLY INPUT CAN BE USED
   -- U_encBmod_0 : IOBUF
      -- port map (
         -- I  => encBmodIn(0),
         -- T  => encBmodTri(0),
         -- O  => encBmodOut(0),
         -- IO => rtmLsN(2));

   -- U_encBmod_1 : IOBUF
      -- port map (
         -- I  => encBmodIn(1),
         -- T  => encBmodTri(1),
         -- O  => encBmodOut(1),
         -- IO => rtmLsN(5));

   -- U_encBmod_2 : IOBUF
      -- port map (
         -- I  => encBmodIn(2),
         -- T  => encBmodTri(2),
         -- O  => encBmodOut(2),
         -- IO => rtmLsN(13));

   -- U_encBmod_3 : IOBUF
      -- port map (
         -- I  => encBmodIn(3),
         -- T  => encBmodTri(3),
         -- O  => encBmodOut(3),
         -- IO => rtmLsN(19));

   ---------------------
   -- ENC_I/SL_[A,B,C,D]
   ---------------------
   encIsldOut(0) <= rtmLsP(1);
   encIsldOut(1) <= rtmLsP(4);
   encIsldOut(2) <= rtmLsP(12);
   encIsldOut(3) <= rtmLsP(18);
   
   -- ONLY INPUT CAN BE USED
   -- U_encIsld_0 : IOBUF
      -- port map (
         -- I  => encIsldIn(0),
         -- T  => encIsldTri(0),
         -- O  => encIsldOut(0),
         -- IO => rtmLsP(1));

   -- U_encIsld_1 : IOBUF
      -- port map (
         -- I  => encIsldIn(1),
         -- T  => encIsldTri(1),
         -- O  => encIsldOut(1),
         -- IO => rtmLsP(4));

   -- U_encIsld_2 : IOBUF
      -- port map (
         -- I  => encIsldIn(2),
         -- T  => encIsldTri(2),
         -- O  => encIsldOut(2),
         -- IO => rtmLsP(12));

   -- U_encIsld_3 : IOBUF
      -- port map (
         -- I  => encIsldIn(3),
         -- T  => encIsldTri(3),
         -- O  => encIsldOut(3),
         -- IO => rtmLsP(18));

		 
		    ---------------------
   -- SPARE_[A,B,C,D]
   ---------------------
   U_spare_0 : IOBUF
      port map (
         I  => spareIn(0),
         T  => spareTri(0),
         O  => spareOut(0),
         IO => rtmLsP(6));

   U_spare_1 : IOBUF
      port map (
         I  => spareIn(1),
         T  => spareTri(1),
         O  => spareOut(1),
         IO => rtmLsN(6));

   U_spare_2 : IOBUF
      port map (
         I  => spareIn(2),
         T  => spareTri(2),
         O  => spareOut(2),
         IO => rtmLsP(10));

   U_spare_3 : IOBUF
      port map (
         I  => spareIn(3),
         T  => spareTri(3),
         O  => spareOut(3),
         IO => rtmLsP(16));
		 
   --------------------------------
   -- Terminate Unused AXI-Lite Bus
   --------------------------------
   axilReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   axilWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

end mapping;
