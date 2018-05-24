-------------------------------------------------------------------------------
-- File       : AppTopJesd.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2018-05-23
-------------------------------------------------------------------------------
-- Description: 
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
use work.AxiStreamPkg.all;
use work.jesd204bpkg.all;
use work.AppTopPkg.all;
use work.AppTopPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppTopJesd is
   generic (
      TPD_G              : time                  := 1 ns;
      SIM_SPEEDUP_G      : boolean               := false;
      SIMULATION_G       : boolean               := false;
      AXI_BASE_ADDR_G    : slv(31 downto 0)      := (others => '0');
      JESD_DRP_EN_G      : boolean               := false;
      JESD_RX_LANE_G     : natural range 0 to 10 := 8;
      JESD_TX_LANE_G     : natural range 0 to 10 := 8;
      JESD_RX_POLARITY_G : slv(9 downto 0)       := "0000000000";
      JESD_TX_POLARITY_G : slv(9 downto 0)       := "0000000000";
      JESD_RX_ROUTES_G   : AppTopJesdRouteType   := JESD_ROUTES_INIT_C;
      JESD_TX_ROUTES_G   : AppTopJesdRouteType   := JESD_ROUTES_INIT_C;
      JESD_REF_SEL_G     : slv(1 downto 0)       := DEV_CLK2_SEL_C;
      JESD_USR_DIV_G     : natural               := 4);
   port (
      -- Clock/reset/SYNC
      jesdClk         : out sl;
      jesdRst         : out sl;
      jesdClk2x       : out sl;
      jesdRst2x       : out sl;
      jesdSysRef      : in  sl;
      jesdRxSync      : out sl;
      jesdTxSync      : in  sl;
      jesdUsrClk      : out sl;
      jesdUsrRst      : out sl;
      -- ADC Interface
      adcValids       : out slv(9 downto 0);
      adcValues       : out sampleDataArray(9 downto 0);
      -- DAC interface
      dacValids       : in  slv(9 downto 0);
      dacValues       : in  sampleDataArray(9 downto 0);
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------
      -- JESD High Speed Ports
      jesdRxP         : in  slv(9 downto 0);
      jesdRxN         : in  slv(9 downto 0);
      jesdTxP         : out slv(9 downto 0);
      jesdTxN         : out slv(9 downto 0);
      jesdClkP        : in  slv(3 downto 0);
      jesdClkN        : in  slv(3 downto 0));
end AppTopJesd;

architecture mapping of AppTopJesd is

   constant NUM_AXI_MASTERS_C : natural          := ite(JESD_DRP_EN_G, 4, 2);
   constant LANE_C            : natural          := ite((JESD_RX_LANE_G > JESD_TX_LANE_G), JESD_RX_LANE_G, JESD_TX_LANE_G);
   constant JESD_LANE_C       : positive         := ite((LANE_C = 0), 1, LANE_C);
   constant GTH_BASE_ADDR_C   : slv(31 downto 0) := (AXI_BASE_ADDR_G+x"0300_0000");

   constant JESD_RX_INDEX_C : natural := 0;
   constant JESD_TX_INDEX_C : natural := 1;
   constant MMCM_INDEX_C    : natural := 2;
   constant GTH_INDEX_C     : natural := 3;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 28, 24);
   constant GTH_CONFIG_C : AxiLiteCrossbarMasterConfigArray(JESD_LANE_C-1 downto 0)       := genAxiLiteConfig(JESD_LANE_C, GTH_BASE_ADDR_C, 24, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(3 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(3 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_INIT_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(3 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(3 downto 0)   := (others => AXI_LITE_READ_SLAVE_INIT_C);

   signal gthWriteMasters : AxiLiteWriteMasterArray(JESD_LANE_C-1 downto 0);
   signal gthWriteSlaves  : AxiLiteWriteSlaveArray(JESD_LANE_C-1 downto 0);
   signal gthReadMasters  : AxiLiteReadMasterArray(JESD_LANE_C-1 downto 0);
   signal gthReadSlaves   : AxiLiteReadSlaveArray(JESD_LANE_C-1 downto 0);

   signal refClkDiv2Vec  : slv(3 downto 0);
   signal refClkVec      : slv(3 downto 0);
   signal refClk         : sl;
   signal amcClkVec      : slv(3 downto 0);
   signal amcClk         : sl;
   signal amcRst         : sl;
   signal jesdClk1x      : sl;
   signal jesdRst1x      : sl;
   signal jesdMmcmLocked : sl;

   signal clkOut   : slv(2 downto 0);
   signal resetOut : slv(2 downto 0);
   signal rstOut   : slv(2 downto 0);
   signal locked   : sl;

   signal drpClk  : slv(9 downto 0)       := (others => '0');
   signal drpRdy  : slv(9 downto 0)       := (others => '1');
   signal drpEn   : slv(9 downto 0)       := (others => '0');
   signal drpWe   : slv(9 downto 0)       := (others => '0');
   signal drpAddr : slv(10*10-1 downto 0) := (others => '0');
   signal drpDi   : slv(10*16-1 downto 0) := (others => '0');
   signal drpDo   : slv(10*16-1 downto 0) := (others => '0');

   signal rawAdcValids : slv(9 downto 0)             := (others => '0');
   signal rawAdcValues : sampleDataArray(9 downto 0) := (others => (others => '0'));
   signal rawDacValues : sampleDataArray(9 downto 0) := (others => (others => '0'));

begin

   GEN_ROUTE : for i in 9 downto 0 generate

      adcValids(i) <= rawAdcValids(JESD_RX_ROUTES_G(i));
      adcValues(i) <= rawAdcValues(JESD_RX_ROUTES_G(i));

      rawDacValues(JESD_TX_ROUTES_G(i)) <= dacValues(i);

   end generate GEN_ROUTE;

   ---------------------
   -- AXI-Lite Crossbars
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
         mAxiWriteMasters    => axilWriteMasters(NUM_AXI_MASTERS_C-1 downto 0),
         mAxiWriteSlaves     => axilWriteSlaves(NUM_AXI_MASTERS_C-1 downto 0),
         mAxiReadMasters     => axilReadMasters(NUM_AXI_MASTERS_C-1 downto 0),
         mAxiReadSlaves      => axilReadSlaves(NUM_AXI_MASTERS_C-1 downto 0));

   ----------------
   -- JESD Clocking
   ----------------
   GEN_GTH_R_CLK : for i in 3 downto 0 generate

      U_IBUFDS_GTE3 : entity work.AmcCarrierIbufGt
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => jesdClkP(i),
            IB    => jesdClkN(i),
            CEB   => '0',
            ODIV2 => refClkDiv2Vec(i),  -- 185 MHz, Frequency the same as jesdRefClk
            O     => refClkVec(i));     -- 185 MHz     

      U_BUFG_GT : BUFG_GT
         port map (
            I       => refClkDiv2Vec(i),  -- 185 MHz
            CE      => '1',
            CLR     => '0',
            CEMASK  => '1',
            CLRMASK => '1',
            DIV     => "000",             -- Divide by 1
            O       => amcClkVec(i));     -- 185 MHz

   end generate GEN_GTH_R_CLK;

   refClk <= refClkVec(conv_integer(JESD_REF_SEL_G));
   amcClk <= amcClkVec(conv_integer(JESD_REF_SEL_G));

   U_PwrUpRst : entity work.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => amcClk,
         rstOut => amcRst);

   U_ClockManager : entity work.ClockManagerUltraScale
      generic map (
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 3,
         BANDWIDTH_G        => "OPTIMIZED",
         --CLKIN_PERIOD_G     => 3.2,
         CLKIN_PERIOD_G     => 3.2,
         --CLKIN_PERIOD_G     => 6.4,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 4.000,
         CLKOUT0_DIVIDE_F_G => 4.000,
         CLKOUT0_RST_HOLD_G => 16,
         CLKOUT1_DIVIDE_G   => 2,
         CLKOUT1_RST_HOLD_G => 32,
         CLKOUT2_DIVIDE_G   => JESD_USR_DIV_G*3,
         CLKOUT2_RST_HOLD_G => 32)
      port map (
         clkIn           => amcClk,
         rstIn           => amcRst,
         clkOut          => clkOut,
         rstOut          => resetOut,
         locked          => locked,
         -- AXI-Lite Interface 
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(MMCM_INDEX_C),
         axilReadSlave   => axilReadSlaves(MMCM_INDEX_C),
         axilWriteMaster => axilWriteMasters(MMCM_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(MMCM_INDEX_C));

   GEN_RST : for i in 2 downto 0 generate
      U_RstPipeline : entity work.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => clkOut(i),
            rstIn  => resetOut(i),
            rstOut => rstOut(i));
   end generate GEN_RST;

   jesdClk1x      <= axilClk when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else clkOut(0);
   jesdClk2x      <= axilClk when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else clkOut(1);
   jesdUsrClk     <= axilClk when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else clkOut(2);
   jesdRst1x      <= axilRst when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else rstOut(0);
   jesdRst2x      <= axilRst when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else rstOut(1);
   jesdUsrRst     <= axilRst when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else rstOut(2);
   jesdMmcmLocked <= '1'     when((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) else locked;

   jesdClk <= jesdClk1x;
   jesdRst <= jesdRst1x;

   -------------
   -- JESD block
   -------------
   U_Jesd : entity work.AppTopJesd204b
      generic map (
         TPD_G              => TPD_G,
         JESD_RX_LANE_G     => JESD_RX_LANE_G,
         JESD_TX_LANE_G     => JESD_TX_LANE_G,
         JESD_RX_POLARITY_G => JESD_RX_POLARITY_G,
         JESD_TX_POLARITY_G => JESD_TX_POLARITY_G)
      port map (
         -- DRP Interface
         drpClk          => drpClk,
         drpRdy          => drpRdy,
         drpEn           => drpEn,
         drpWe           => drpWe,
         drpAddr         => drpAddr,
         drpDi           => drpDi,
         drpDo           => drpDo,
         -- AXI interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         rxReadMaster    => axilReadMasters(JESD_RX_INDEX_C),
         rxReadSlave     => axilReadSlaves(JESD_RX_INDEX_C),
         rxWriteMaster   => axilWriteMasters(JESD_RX_INDEX_C),
         rxWriteSlave    => axilWriteSlaves(JESD_RX_INDEX_C),
         txReadMaster    => axilReadMasters(JESD_TX_INDEX_C),
         txReadSlave     => axilReadSlaves(JESD_TX_INDEX_C),
         txWriteMaster   => axilWriteMasters(JESD_TX_INDEX_C),
         txWriteSlave    => axilWriteSlaves(JESD_TX_INDEX_C),
         -- Sample data output (Use if external data acquisition core is attached)
         dataValidVec_o  => rawAdcValids,
         sampleDataArr_o => rawAdcValues,
         sampleDataArr_i => rawDacValues,
         -------
         -- JESD
         -------
         -- Clocks
         stableClk       => axilClk,
         refClk          => refClk,
         devClk_i        => jesdClk1x,
         devClk2_i       => jesdClk1x,
         devRst_i        => jesdRst1x,
         devClkActive_i  => jesdMmcmLocked,
         -- GTH Ports
         gtTxP           => jesdTxP,
         gtTxN           => jesdTxN,
         gtRxP           => jesdRxP,
         gtRxN           => jesdRxN,
         -- SYSREF for subclass 1 fixed latency
         sysRef_i        => jesdSysRef,
         -- Synchronization output combined from all receivers to be connected to ADC chips
         nSync_o         => jesdRxSync,
         nSync_i         => jesdTxSync);

   -----------------------
   -- GTH's DRP Interfaces
   -----------------------
   drpClk <= (others => axilClk);
   GTH_DRP : if (JESD_DRP_EN_G = true) generate

      U_XBAR : entity work.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => JESD_LANE_C,
            MASTERS_CONFIG_G   => GTH_CONFIG_C)
         port map (
            axiClk              => axilClk,
            axiClkRst           => axilRst,
            sAxiWriteMasters(0) => axilWriteMasters(GTH_INDEX_C),
            sAxiWriteSlaves(0)  => axilWriteSlaves(GTH_INDEX_C),
            sAxiReadMasters(0)  => axilReadMasters(GTH_INDEX_C),
            sAxiReadSlaves(0)   => axilReadSlaves(GTH_INDEX_C),
            mAxiWriteMasters    => gthWriteMasters,
            mAxiWriteSlaves     => gthWriteSlaves,
            mAxiReadMasters     => gthReadMasters,
            mAxiReadSlaves      => gthReadSlaves);

      GEN_GTH_DRP : for i in (JESD_LANE_C-1) downto 0 generate
         U_AxiLiteToDrp : entity work.AxiLiteToDrp
            generic map (
               TPD_G            => TPD_G,
               COMMON_CLK_G     => true,
               EN_ARBITRATION_G => false,
               TIMEOUT_G        => 4096,
               ADDR_WIDTH_G     => 10,
               DATA_WIDTH_G     => 16)
            port map (
               -- AXI-Lite Port
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => gthReadMasters(i),
               axilReadSlave   => gthReadSlaves(i),
               axilWriteMaster => gthWriteMasters(i),
               axilWriteSlave  => gthWriteSlaves(i),
               -- DRP Interface
               drpClk          => axilClk,
               drpRst          => axilRst,
               drpRdy          => drpRdy(i),
               drpEn           => drpEn(i),
               drpWe           => drpWe(i),
               drpAddr         => drpAddr((i*10)+9 downto (i*10)),
               drpDi           => drpDi((i*16)+15 downto (i*16)),
               drpDo           => drpDo((i*16)+15 downto (i*16)));

      end generate GEN_GTH_DRP;
   end generate;

end mapping;
