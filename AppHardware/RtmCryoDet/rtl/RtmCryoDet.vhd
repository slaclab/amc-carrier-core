-------------------------------------------------------------------------------
-- File       : RtmCryoDet.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-11-03
-- Last update: 2017-11-06
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/x/5WV4DQ    
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

entity RtmCryoDet is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_CLK_FREQ_G   : real             := 156.25E+6;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      -- JESD Clock Reference
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      -- Digital I/O Interface
      kRelay          : out   slv(1 downto 0);
      startRamp       : in    sl;
      selectRamp      : in    sl;
      lemo1           : out   sl;
      lemo2           : in    sl;
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
end RtmCryoDet;

architecture mapping of RtmCryoDet is

   constant NUM_AXI_MASTERS_C : natural := 4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 24, 20);

   constant REG_INDEX_C  : natural := 0;
   constant CRYO_INDEX_C : natural := 1;
   constant MAX_INDEX_C  : natural := 2;
   constant SR_INDEX_C   : natural := 3;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal cryoCsL : sl;
   signal cryoSck : sl;
   signal cryoSdi : sl;
   signal cryoSdo : sl;

   signal maxCsL : sl;
   signal maxSck : sl;
   signal maxSdi : sl;
   signal maxSdo : sl;

   signal srCsL : sl;
   signal srSck : sl;
   signal srSdi : sl;
   signal srSdo : sl;

   signal jesdClkDiv    : sl;
   signal jesdClkDivReg : sl;
   
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

   ------------------------------------------------
   --               RTM Mapping                  --
   ------------------------------------------------
   -- Refer to mapping table on confluence page
   -- https://confluence.slac.stanford.edu/x/5WV4DQ
   ------------------------------------------------
   rtmLsN(1)  <= cryoCsL;
   rtmLsP(3)  <= cryoSck;
   rtmLsN(3)  <= cryoSdi;
   lemo1      <= rtmLsP(7);
   rtmLsN(7)  <= lemo2;
   cryoSdo    <= rtmLsP(11);
   kRelay(0)  <= rtmLsN(11);
   rtmLsP(12) <= startRamp;
   rtmLsN(12) <= selectRamp;
   kRelay(1)  <= rtmLsP(13);
   rtmLsN(13) <= maxCsL;
   rtmLsN(14) <= maxSdi;
   rtmLsP(15) <= maxSck;
   maxSdo     <= rtmLsN(15);
   rtmLsN(16) <= not(jesdRst);

   U_ODDRE1 : ODDRE1
      port map (
         C  => jesdClk,
         Q  => jesdClkDivReg,
         D1 => jesdClkDiv,
         D2 => jesdClkDiv,
         SR => '0');

   U_OBUFDS : OBUFDS
      port map (
         I  => jesdClkDivReg,
         O  => rtmLsP(17),
         OB => rtmLsN(17));

   srSdo      <= rtmLsP(18);
   rtmLsN(18) <= srSck;
   rtmLsP(19) <= srSdi;
   rtmLsN(19) <= srCsL;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
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

   --------------------------
   -- CRYO DET RTM REG Module
   --------------------------
   U_Reg : entity work.RtmCryoDetReg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         jesdClk         => jesdClk,
         jesdRst         => jesdRst,
         jesdClkDiv      => jesdClkDiv,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(REG_INDEX_C),
         axilReadSlave   => axilReadSlaves(REG_INDEX_C),
         axilWriteMaster => axilWriteMasters(REG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(REG_INDEX_C));

   ------------------
   -- CRYO SPI Module
   ------------------
   CRYO_SPI : entity work.AxiSpiMaster         -- FPGA=Master and CPLD=SLAVE
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         MODE_G            => "RW",
         ADDRESS_SIZE_G    => 7,               -- A[6:0]
         DATA_SIZE_G       => 32,              -- D[31:0]
         CPHA_G            => '0',             -- CPHA = 0
         CPOL_G            => '0',             -- CPOL = 0
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => (1.0/100.0E+3))  -- SCLK = 100KHz
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(CRYO_INDEX_C),
         axiReadSlave   => axilReadSlaves(CRYO_INDEX_C),
         axiWriteMaster => axilWriteMasters(CRYO_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(CRYO_INDEX_C),
         coreSclk       => cryoSck,
         coreSDin       => cryoSdo,
         coreSDout      => cryoSdi,
         coreCsb        => cryoCsL);

   ------------------
   -- MAX SPI Module
   ------------------
   MAX_SPI : entity work.AxiSpiMaster        -- FPGA=Master and CPLD=SLAVE
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         MODE_G            => "RW",
         ADDRESS_SIZE_G    => 7,             -- A[6:0]
         DATA_SIZE_G       => 24,            -- D[23:0]
         CPHA_G            => '0',           -- CPHA = 0
         CPOL_G            => '0',           -- CPOL = 0
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => (1.0/1.0E+6))  -- SCLK = 1MHz
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(MAX_INDEX_C),
         axiReadSlave   => axilReadSlaves(MAX_INDEX_C),
         axiWriteMaster => axilWriteMasters(MAX_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(MAX_INDEX_C),
         coreSclk       => maxSck,
         coreSDin       => maxSdo,
         coreSDout      => maxSdi,
         coreCsb        => maxCsL);

   ----------------
   -- SR SPI Module
   ----------------
   SR_SPI : entity work.AxiSpiMaster         -- FPGA=Master and CPLD=SLAVE
      generic map (
         TPD_G             => TPD_G,
         AXI_ERROR_RESP_G  => AXI_ERROR_RESP_G,
         MODE_G            => "RW",
         ADDRESS_SIZE_G    => 7,             -- A[6:0]
         DATA_SIZE_G       => 24,            -- D[23:0]
         CPHA_G            => '0',           -- CPHA = 0
         CPOL_G            => '0',           -- CPOL = 0
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => (1.0/1.0E+6))  -- SCLK = 1MHz
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(SR_INDEX_C),
         axiReadSlave   => axilReadSlaves(SR_INDEX_C),
         axiWriteMaster => axilWriteMasters(SR_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(SR_INDEX_C),
         coreSclk       => srSck,
         coreSDin       => srSdo,
         coreSDout      => srSdi,
         coreCsb        => srCsL);

end architecture mapping;
