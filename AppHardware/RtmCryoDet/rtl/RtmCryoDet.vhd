-------------------------------------------------------------------------------
-- File       : RtmCryoDet.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-11-03
-- Last update: 2018-07-27
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
      TPD_G           : time             := 1 ns;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- JESD Clock Reference
      jesdClk         : in    sl;
      jesdRst         : in    sl;
      -- Digital I/O Interface
      startRamp       : out   sl;
      selectRamp      : out   sl;
      rampCnt         : out   slv(31 downto 0);
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

   constant REG_INDEX_C : natural := 0;
   constant PIC_INDEX_C : natural := 1;
   constant MAX_INDEX_C : natural := 2;
   constant SR_INDEX_C  : natural := 3;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   type RegType is record
      startRamp         : sl;
      startRampInt      : sl;
      startRampExtPulse : sl;
      startRampExt      : sl;
      startRampPulse    : sl;
      cnt               : slv(15 downto 0);
      pulseCnt          : slv(15 downto 0);
      rampMaxCnt        : slv(31 downto 0);
      rampCnt           : slv(31 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
      startRamp         => '0',
      startRampInt      => '0',
      startRampExtPulse => '0',
      startRampExt      => '0',
      startRampPulse    => '0',
      cnt               => (others => '0'),
      pulseCnt          => (others => '0'),
      rampMaxCnt        => (others => '0'),
      rampCnt           => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal picCsL : sl;
   signal picSck : sl;
   signal picSdi : sl;
   signal picSdo : sl;

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

   signal extTrig       : sl;
   signal extTrigSync   : sl;
   signal selRamp       : sl;
   signal enableRamp    : sl;
   signal rampStartMode : sl;
   signal rtmReset      : sl;
   signal kRelay        : slv(1 downto 0);
   signal pulseWidth    : slv(15 downto 0);
   signal debounceWidth : slv(15 downto 0);
   signal rampMaxCnt    : slv(31 downto 0);

   signal startRampPulseReg : slv(1 downto 0);

begin

   selectRamp <= selRamp;

   ------------------------------------------------
   --               RTM Mapping                  --
   ------------------------------------------------
   -- Refer to mapping table on confluence page
   -- https://confluence.slac.stanford.edu/x/5WV4DQ
   ------------------------------------------------
   rtmLsN(1) <= picCsL;
   rtmLsP(3) <= picSck;
   rtmLsN(3) <= picSdi;

   extTrig <= rtmLsP(7);                -- LEMO1

   ---------------------------------------------
   U_OREG_startRampPulse0 : ODDRE1
      port map (
         C  => jesdClk,
         Q  => startRampPulseReg(0),
         D1 => r.startRampPulse,
         D2 => r.startRampPulse,
         SR => '0');

   U_OBUFDS_startRampPulse0 : OBUF
      port map (
         I => startRampPulseReg(0),
         O => rtmLsN(7));               -- LEMO2
   ---------------------------------------------

   picSdo    <= rtmLsP(11);
   kRelay(0) <= rtmLsN(11);

   ---------------------------------------------
   U_OREG_startRampPulse1 : ODDRE1
      port map (
         C  => jesdClk,
         Q  => startRampPulseReg(1),
         D1 => r.startRampPulse,
         D2 => r.startRampPulse,
         SR => '0');

   U_OBUFDS_startRampPulse1 : OBUF
      port map (
         I => startRampPulseReg(1),
         O => rtmLsP(12));
   ---------------------------------------------

   rtmLsN(12) <= selRamp;
   kRelay(1)  <= rtmLsP(13);
   rtmLsN(13) <= maxCsL;
   rtmLsN(14) <= maxSdi;
   rtmLsP(15) <= maxSck;
   maxSdo     <= rtmLsN(15);
   rtmLsN(16) <= not(jesdRst or rtmReset);

   ---------------------------------------------
   U_OREG_jesdClkDiv : ODDRE1
      port map (
         C  => jesdClk,
         Q  => jesdClkDivReg,
         D1 => jesdClkDiv,
         D2 => jesdClkDiv,
         SR => '0');

   U_OBUFDS_jesdClkDiv : OBUFDS
      port map (
         I  => jesdClkDivReg,
         O  => rtmLsP(17),
         OB => rtmLsN(17));
   ---------------------------------------------

   srSdo      <= rtmLsP(18);
   rtmLsN(18) <= srSck;
   rtmLsP(19) <= srSdi;
   rtmLsN(19) <= srCsL;

   U_extTrig : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => jesdClk,
         dataIn  => extTrig,
         dataOut => extTrigSync);

   ------
   -- FSM
   ------
   comb : process (debounceWidth, enableRamp, extTrigSync, jesdRst, pulseWidth,
                   r, rampMaxCnt, rampStartMode) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobe
      v.startRamp         := '0';
      v.startRampInt      := '0';
      v.startRampExtPulse := '0';

      ------------------------------------------------------------
      -- Internal Ramp Generation
      ------------------------------------------------------------

      -- Update the registered values
      v.rampMaxCnt := rampMaxCnt;

      -- Check for change in configurations
      if (r.rampMaxCnt /= rampMaxCnt) then
         -- Reset the counter
         v.rampCnt := (others => '0');
      -- Check the counter
      elsif (r.rampMaxCnt = r.rampCnt) then
         -- Reset the counter
         v.rampCnt      := (others => '0');
         -- Set the flag
         v.startRampInt := '1';
      else
         -- Increment the counter
         v.rampCnt := r.rampCnt + 1;
      end if;

      ------------------------------------------------------------
      -- Debouncing External Triggering
      ------------------------------------------------------------ 

      -- Check if external trigger has changed
      if (extTrigSync /= r.startRampExt) then
         -- Check counter
         if (r.cnt = debounceWidth) then
            -- Reset the counter
            v.cnt               := (others => '0');
            -- Toggle the trigger
            v.startRampExt      := not(r.startRampExt);
            -- Generate a one-shot pulse
            v.startRampExtPulse := v.startRampExt;
         else
            -- Increment the counter
            v.cnt := r.cnt + 1;
         end if;
      else
         -- Reset the counter
         v.cnt := (others => '0');
      end if;

      ------------------------------------------------------------
      -- Mux the triggers together
      ------------------------------------------------------------ 

      -- Check if enabled
      if (enableRamp = '1') then
         -- Check ramp mode
         if (rampStartMode = '0') then
            -- Select internal mode
            v.startRamp := r.startRampInt;
         else
            -- Select external mode
            v.startRamp := r.startRampExtPulse;
         end if;
      end if;

      ------------------------------------------------------------
      -- Pulse Stretching
      ------------------------------------------------------------       

      -- Check if pulse stretching 
      if (r.startRamp = '1') or (r.pulseCnt /= 0) then
         -- Check the counter
         if (r.pulseCnt = pulseWidth) then
            -- Reset the counter
            v.pulseCnt       := (others => '0');
            -- Clear the flag
            v.startRampPulse := '0';
         else
            -- Increment the counter
            v.pulseCnt       := r.pulseCnt + 1;
            -- Set the flag
            v.startRampPulse := '1';
         end if;
      end if;

      ------------------------------------------------------------       
      -- Synchronous Reset
      ------------------------------------------------------------       
      if (jesdRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      startRamp <= r.startRamp;
      rampCnt   <= r.rampCnt;

   end process comb;

   seq : process (jesdClk) is
   begin
      if (rising_edge(jesdClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
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
         TPD_G => TPD_G)
      port map (
         jesdClk         => jesdClk,
         jesdRst         => jesdRst,
         jesdClkDiv      => jesdClkDiv,
         kRelay          => kRelay,
         rampMaxCnt      => rampMaxCnt,
         selRamp         => selRamp,
         enableRamp      => enableRamp,
         rampStartMode   => rampStartMode,
         pulseWidth      => pulseWidth,
         debounceWidth   => debounceWidth,
         rtmReset        => rtmReset,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(REG_INDEX_C),
         axilReadSlave   => axilReadSlaves(REG_INDEX_C),
         axilWriteMaster => axilWriteMasters(REG_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(REG_INDEX_C));

   ------------------
   -- PIC SPI Module
   ------------------
   PIC_SPI : entity work.RtmCryoSpiMaster      -- FPGA=Master and PIC=SLAVE
      generic map (
         TPD_G             => TPD_G,
         CPHA_G            => '0',             -- CPHA = 0
         CPOL_G            => '0',             -- CPOL = 0
         CLK_PERIOD_G      => (1.0/AXI_CLK_FREQ_G),
         SPI_SCLK_PERIOD_G => (1.0/100.0E+3))  -- SCLK = 100KHz
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(PIC_INDEX_C),
         axiReadSlave   => axilReadSlaves(PIC_INDEX_C),
         axiWriteMaster => axilWriteMasters(PIC_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(PIC_INDEX_C),
         coreSclk       => picSck,
         coreSDin       => picSdo,
         coreSDout      => picSdi,
         coreCsb        => picCsL);

   ------------------
   -- MAX SPI Module
   ------------------
   MAX_SPI : entity work.AxiSpiMaster        -- FPGA=Master and CPLD=SLAVE
      generic map (
         TPD_G             => TPD_G,
         MODE_G            => "RW",
         ADDRESS_SIZE_G    => 11,            -- A[10:0]
         DATA_SIZE_G       => 20,            -- D[19:0]
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
         MODE_G            => "RW",
         ADDRESS_SIZE_G    => 11,            -- A[10:0]
         DATA_SIZE_G       => 20,            -- D[19:0]
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
