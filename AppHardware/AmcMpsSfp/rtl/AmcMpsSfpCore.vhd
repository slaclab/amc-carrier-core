-------------------------------------------------------------------------------
-- File       : AmcMpsSfpCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-28
-- Last update: 2017-02-28
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_09_C00
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

entity AmcMpsSfpCore is
   generic (
      TPD_G            : time             := 1 ns;
      EN_PLL_G         : boolean          := false;
      EN_HS_REPEATER_G : boolean          := false;
      AXI_CLK_FREQ_G   : real             := 156.25E+6;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
   port (
      -- PLL Interface
      pllClk          : in    sl := 0;;
      pllLos          : out   sl;
      pllLol          : out   sl;
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
end AmcMpsSfpCore;

architecture mapping of AmcMpsSfpCore is

   constant NUM_AXI_MASTERS_C : natural := 3;

   constant PLL_INDEX_C         : natural := 0;
   constant SFP_I2C_INDEX_C     : natural := 1;
   constant HS_REPEATER_INDEX_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      PLL_INDEX_C         => (
         baseAddr         => (AXI_BASE_ADDR_G + x"0000_0000"),
         addrBits         => 17,
         connectivity     => X"0001"),
      SFP_I2C_INDEX_C     => (
         baseAddr         => (AXI_BASE_ADDR_G + x"0002_0000"),
         addrBits         => 17,
         connectivity     => X"0001"),
      HS_REPEATER_INDEX_C => (
         baseAddr         => (AXI_BASE_ADDR_G + x"0004_0000"),
         addrBits         => 17,
         connectivity     => X"0001"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin

   --------------------
   -- Application Ports
   --------------------
   ClkBuf_0 : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => pllClk,
         clkOutP => fpgaClkP(0),
         clkOutN => fpgaClkN(0));

   ---------------------
   -- AXI-Lite Crossbars
   ---------------------
   U_XBAR0 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   BYP_PLL : if (EN_PLL_G = false) generate

      pllLos <= '0';
      pllLol <= '0';

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMasters(PLL_INDEX_C),
            axiReadSlave   => axilReadSlaves(PLL_INDEX_C),
            axiWriteMaster => axilWriteMasters(PLL_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(PLL_INDEX_C));

   end generate;

   GEN_PLL : if (EN_PLL_G = true) generate

      pllLos <= syncInP(0);
      pllLol <= syncInP(1);

      U_PLL : entity work.AmcMpsSfpPll
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map(
            -- PLL Parallel Interface
            pllRst          => spareP(0),
            pllInc          => spareP(1),
            pllDec          => spareP(2),
            pllFrqTbl       => spareP(3),
            pllDbly2By      => spareP(4),
            pllRate(0)      => spareP(5),
            pllRate(1)      => spareP(6),
            pllSFout(0)     => spareP(7),
            pllSFout(1)     => spareP(8),
            pllBwSel(0)     => spareP(9),
            pllBwSel(1)     => spareP(10),
            pllFrqSel(0)    => spareP(11),
            pllFrqSel(1)    => spareP(12),
            pllFrqSel(2)    => spareP(13),
            pllFrqSel(3)    => spareP(14),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(PLL_INDEX_C),
            axilReadSlave   => axilReadSlaves(PLL_INDEX_C),
            axilWriteMaster => axilWriteMasters(PLL_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(PLL_INDEX_C));

   end generate;

   BYP_HSR : if (EN_PLL_G = false) generate

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMasters(PLL_INDEX_C),
            axiReadSlave   => axilReadSlaves(PLL_INDEX_C),
            axiWriteMaster => axilWriteMasters(PLL_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(PLL_INDEX_C));

   end generate;

   GEN_HSR : if (EN_PLL_G = true) generate

      pllLos <= syncInP(0);
      pllLol <= syncInP(1);

      U_HSR : entity work.AmcMpsSfpHsRepeater
         generic map (
            TPD_G            => TPD_G,
            AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            AXI_BASE_ADDR_G  => AXI_CONFIG_C(HS_REPEATER_INDEX_C).baseAddr)
         port map(
            -- I2C Interface
            i2cScl(0)       => jtagSec(0),
            i2cScl(1)       => jtagSec(2),
            i2cScl(2)       => jtagSec(4),
            i2cSda(0)       => jtagSec(1),
            i2cSda(1)       => jtagSec(3),
            i2cSda(2)       => jtagPri(4),
            -- AXI-Lite Interface
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(HS_REPEATER_INDEX_C),
            axilReadSlave   => axilReadSlaves(HS_REPEATER_INDEX_C),
            axilWriteMaster => axilWriteMasters(HS_REPEATER_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(HS_REPEATER_INDEX_C));

   end generate;

   U_SfpMon : entity work.AmcMpsSfpMon
      generic map (
         TPD_G            => TPD_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(SFP_I2C_INDEX_C).baseAddr)
      port map(
         -- I2C Interface
         i2cScl          => jtagPri(0),
         i2cSda          => jtagPri(1),
         i2cRstL         => jtagPri(2),
         i2cIntL         => jtagPri(3),
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(SFP_I2C_INDEX_C),
         axilReadSlave   => axilReadSlaves(SFP_I2C_INDEX_C),
         axilWriteMaster => axilWriteMasters(SFP_I2C_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SFP_I2C_INDEX_C));

end mapping;
