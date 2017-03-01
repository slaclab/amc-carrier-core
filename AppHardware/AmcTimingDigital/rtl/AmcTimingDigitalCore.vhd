-------------------------------------------------------------------------------
-- File       : AmcTimingDigitalCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-06
-- Last update: 2017-02-28
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_06_CXX
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcTimingDigitalCore is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Digital I/O Interface
      smaDin          : out   sl;
      smaDout         : in    slv(1 downto 0);
      lemoDin         : out   slv(3 downto 0);
      lemoDout        : in    slv(3 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- AMC's JTAG Ports
      jtagPri         : inout slv(4 downto 0);
      jtagSec         : inout slv(4 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP        : inout slv(1 downto 0);
      fpgaClkN        : inout slv(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP         : inout slv(3 downto 0);
      sysRefN         : inout slv(3 downto 0);
      -- AMC's Sync Ports
      syncInP         : inout slv(3 downto 0);
      syncInN         : inout slv(3 downto 0);
      syncOutP        : inout slv(9 downto 0);
      syncOutN        : inout slv(9 downto 0);
      -- AMC's Spare Ports
      spareP          : inout slv(15 downto 0);
      spareN          : inout slv(15 downto 0));
end AmcTimingDigitalCore;

architecture mapping of AmcTimingDigitalCore is

   signal lemoDinL : slv(3 downto 0);

begin

   U_smaDin : IBUFDS
      port map (
         I  => spareP(0),
         IB => spareN(0),
         O  => smaDin);  -- polarity correction in hardware (P_SPARE0_M connected to U22.pin4 & P_SPARE0_P connected to U22.pin3)

   U_smaDout0 : OBUFDS
      port map (
         I  => smaDout(0),
         O  => spareP(1),
         OB => spareN(1));

   U_smaDout1 : OBUFDS
      port map (
         I  => smaDout(1),
         O  => spareP(2),
         OB => spareN(2));

   GEN_VEC :
   for i in 3 downto 0 generate

      U_lemoDout : OBUFDS
         port map (
            I  => lemoDout(i),
            O  => syncInP(i),
            OB => syncInN(i));

      U_lemoDin : IBUFDS
         port map (
            I  => syncOutP(i),
            IB => syncOutN(i),
            O  => lemoDinL(i));

      lemoDin(i) <= not(lemoDinL(i));   -- polarity correction in firmware

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
