-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.Jesd204bPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppTopJesd204b is
   generic (
      TPD_G              : time                 := 1 ns;
      JESD_RX_LANE_G     : natural range 0 to 5 := 5;
      JESD_TX_LANE_G     : natural range 0 to 5 := 5;
      JESD_RX_POLARITY_G : slv(4 downto 0)      := (others => '0');
      JESD_TX_POLARITY_G : slv(4 downto 0)      := (others => '0'));
   port (
      -- DRP Interface
      drpClk          : in  slv(4 downto 0);
      drpRdy          : out slv(4 downto 0)       := (others => '1');
      drpEn           : in  slv(4 downto 0);
      drpWe           : in  slv(4 downto 0);
      drpAddr         : in  slv(44 downto 0);
      drpDi           : in  slv(79 downto 0);
      drpDo           : out slv(79 downto 0)      := (others => '0');
      -- AXI interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      rxReadMaster    : in  AxiLiteReadMasterType;
      rxReadSlave     : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      rxWriteMaster   : in  AxiLiteWriteMasterType;
      rxWriteSlave    : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      txReadMaster    : in  AxiLiteReadMasterType;
      txReadSlave     : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      txWriteMaster   : in  AxiLiteWriteMasterType;
      txWriteSlave    : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      -- Sample data output (Use if external data acquisition core is attached)
      sampleDataArr_o : out sampleDataArray(4 downto 0);
      dataValidVec_o  : out slv(4 downto 0);
      -- Sample data input (Use if external data generator core is attached)
      sampleDataArr_i : in  sampleDataArray(4 downto 0);
      dacReady_o      : out slv(4 downto 0)       := (others=>'0');
      -------
      -- JESD
      -------
      -- Clocks
      stableClk       : in  sl;  -- GT needs a stable clock to "boot up"(buffered refClkDiv2)
      refClk          : in  sl;  -- GT Reference clock directly from GT GTH diff. input buffer
      devClk_i        : in  sl;         -- Device clock also rxUsrClkIn for MGT
      devClk2_i       : in  sl;  -- Device clock divided by 2 also rxUsrClk2In for MGT
      devRst_i        : in  sl;         --
      devClkActive_i  : in  sl                    := '1';  -- devClk_i MCMM locked
      -- GTH Ports
      gtTxP           : out slv(4 downto 0);  -- GT Serial Transmit Positive
      gtTxN           : out slv(4 downto 0);  -- GT Serial Transmit Negative
      gtRxP           : in  slv(4 downto 0);  -- GT Serial Receive Positive
      gtRxN           : in  slv(4 downto 0);  -- GT Serial Receive Negative
      -- SYSREF for subclass 1 fixed latency
      sysRef_i        : in  sl;
      -- Synchronization output combined from all receivers to be connected to ADC/DAC chips
      nSync_o         : out sl                    := '0';
      nSync_i         : in  slv(4 downto 0));
end AppTopJesd204b;

architecture mapping of AppTopJesd204b is

   component AppTopJesd204bCoregen
      port (
         gtwiz_userclk_tx_active_in         : in  std_logic_vector(0 downto 0);
         gtwiz_userclk_rx_active_in         : in  std_logic_vector(0 downto 0);
         gtwiz_buffbypass_tx_reset_in       : in  std_logic_vector(0 downto 0);
         gtwiz_buffbypass_tx_start_user_in  : in  std_logic_vector(0 downto 0);
         gtwiz_buffbypass_tx_done_out       : out std_logic_vector(0 downto 0);
         gtwiz_buffbypass_tx_error_out      : out std_logic_vector(0 downto 0);
         gtwiz_reset_clk_freerun_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_all_in                 : in  std_logic_vector(0 downto 0);
         gtwiz_reset_tx_pll_and_datapath_in : in  std_logic_vector(0 downto 0);
         gtwiz_reset_tx_datapath_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_rx_pll_and_datapath_in : in  std_logic_vector(0 downto 0);
         gtwiz_reset_rx_datapath_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_rx_cdr_stable_out      : out std_logic_vector(0 downto 0);
         gtwiz_reset_tx_done_out            : out std_logic_vector(0 downto 0);
         gtwiz_reset_rx_done_out            : out std_logic_vector(0 downto 0);
         gtwiz_userdata_tx_in               : in  std_logic_vector(159 downto 0);
         gtwiz_userdata_rx_out              : out std_logic_vector(159 downto 0);
         drpaddr_in                         : in  std_logic_vector(44 downto 0);
         drpclk_in                          : in  std_logic_vector(4 downto 0);
         drpdi_in                           : in  std_logic_vector(79 downto 0);
         drpen_in                           : in  std_logic_vector(4 downto 0);
         drpwe_in                           : in  std_logic_vector(4 downto 0);
         gthrxn_in                          : in  std_logic_vector(4 downto 0);
         gthrxp_in                          : in  std_logic_vector(4 downto 0);
         gtrefclk0_in                       : in  std_logic_vector(4 downto 0);
         loopback_in                        : in  std_logic_vector(14 downto 0);
         rx8b10ben_in                       : in  std_logic_vector(4 downto 0);
         rxcommadeten_in                    : in  std_logic_vector(4 downto 0);
         rxmcommaalignen_in                 : in  std_logic_vector(4 downto 0);
         rxpcommaalignen_in                 : in  std_logic_vector(4 downto 0);
         rxpd_in                            : in  std_logic_vector(9 downto 0);
         rxpolarity_in                      : in  std_logic_vector(4 downto 0);
         rxusrclk_in                        : in  std_logic_vector(4 downto 0);
         rxusrclk2_in                       : in  std_logic_vector(4 downto 0);
         tx8b10ben_in                       : in  std_logic_vector(4 downto 0);
         txctrl0_in                         : in  std_logic_vector(79 downto 0);
         txctrl1_in                         : in  std_logic_vector(79 downto 0);
         txctrl2_in                         : in  std_logic_vector(39 downto 0);
         txdiffctrl_in                      : in  std_logic_vector(19 downto 0);
         txinhibit_in                       : in  std_logic_vector(4 downto 0);
         txpd_in                            : in  std_logic_vector(9 downto 0);
         txpolarity_in                      : in  std_logic_vector(4 downto 0);
         txpostcursor_in                    : in  std_logic_vector(24 downto 0);
         txprecursor_in                     : in  std_logic_vector(24 downto 0);
         txusrclk_in                        : in  std_logic_vector(4 downto 0);
         txusrclk2_in                       : in  std_logic_vector(4 downto 0);
         drpdo_out                          : out std_logic_vector(79 downto 0);
         drprdy_out                         : out std_logic_vector(4 downto 0);
         gthtxn_out                         : out std_logic_vector(4 downto 0);
         gthtxp_out                         : out std_logic_vector(4 downto 0);
         rxbyteisaligned_out                : out std_logic_vector(4 downto 0);
         rxbyterealign_out                  : out std_logic_vector(4 downto 0);
         rxcommadet_out                     : out std_logic_vector(4 downto 0);
         rxctrl0_out                        : out std_logic_vector(79 downto 0);
         rxctrl1_out                        : out std_logic_vector(79 downto 0);
         rxctrl2_out                        : out std_logic_vector(39 downto 0);
         rxctrl3_out                        : out std_logic_vector(39 downto 0);
         rxoutclk_out                       : out std_logic_vector(4 downto 0);
         rxpmaresetdone_out                 : out std_logic_vector(4 downto 0);
         txoutclk_out                       : out std_logic_vector(4 downto 0);
         txpmaresetdone_out                 : out std_logic_vector(4 downto 0));
   end component;

   signal r_jesdGtRxArr : jesdGtRxLaneTypeArray(4 downto 0) := (others => JESD_GT_RX_LANE_INIT_C);
   signal r_jesdGtTxArr : jesdGtTxLaneTypeArray(4 downto 0) := (others => JESD_GT_TX_LANE_INIT_C);

   signal s_gtRxUserReset : slv(4 downto 0) := (others => '0');
   signal s_gtRxReset     : sl              := '0';
   signal s_gtTxUserReset : slv(4 downto 0) := (others => '0');
   signal s_gtTxReset     : sl              := '0';
   signal s_gtResetAll    : sl              := '0';

   signal s_sysRef        : sl                          := '0';
   signal s_sysRefDbg     : sl                          := '0';
   signal s_rxctrl0       : slv(79 downto 0)            := (others => '0');
   signal s_rxctrl1       : slv(79 downto 0)            := (others => '0');
   signal s_rxctrl2       : slv(39 downto 0)            := (others => '0');
   signal s_rxctrl3       : slv(39 downto 0)            := (others => '0');
   signal s_rxData        : slv(159 downto 0)           := (others => '0');
   signal s_txData        : slv(159 downto 0)           := (others => '0');
   signal s_txDataK       : slv(39 downto 0)            := (others => '0');
   signal s_devClkVec     : slv(4 downto 0)             := (others => '0');
   signal s_devClk2Vec    : slv(4 downto 0)             := (others => '0');
   signal s_stableClkVec  : slv(4 downto 0)             := (others => '0');
   signal s_gtRefClkVec   : slv(4 downto 0)             := (others => '0');
   signal s_rxDone        : sl                          := '0';
   signal s_txDone        : sl                          := '0';
   signal s_gtTxReady     : slv(4 downto 0)             := (others => '0');
   signal s_allignEnVec   : slv(4 downto 0)             := (others => '0');
   signal s_dataValidVec  : slv(4 downto 0)             := (others => '0');
   signal s_sampleDataArr : sampleDataArray(4 downto 0) := (others => (others => '0'));

   signal txDiffCtrl   : Slv8Array(4 downto 0) := (others => (others => '1'));
   signal txPostCursor : Slv8Array(4 downto 0) := (others => (others => '0'));
   signal txPreCursor  : Slv8Array(4 downto 0) := (others => (others => '0'));
   signal txPolarity   : slv(4 downto 0)       := (others => '0');
   signal rxPolarity   : slv(4 downto 0)       := (others => '0');
   signal txPowerDown  : slv(4 downto 0)       := (others => '0');
   signal rxPowerDown  : slv(4 downto 0)       := (others => '0');
   signal txInhibit    : slv(4 downto 0)       := (others => '1');

   signal gtTxDiffCtrl   : slv(19 downto 0)    := (others => '1');
   signal gtTxPostCursor : slv(24 downto 0)    := (others => '0');
   signal gtTxPreCursor  : slv(24 downto 0)    := (others => '0');
   signal gtTxPd         : slv(5*2-1 downto 0) := (others => '0');
   signal gtRxPd         : slv(5*2-1 downto 0) := (others => '0');

   signal s_cdrStable  : sl;
   signal dummyZeroBit : sl;

begin

   dataValidVec_o  <= s_dataValidVec;
   sampleDataArr_o <= s_sampleDataArr;
   s_sysRef        <= sysRef_i;

   ---------------
   -- JESD RX core
   ---------------
   EN_RX_CORE : if (JESD_RX_LANE_G /= 0) generate
      U_Jesd204bRx : entity surf.Jesd204bRx
         generic map (
            TPD_G => TPD_G,
            F_G   => 2,
            K_G   => 32,
            L_G   => JESD_RX_LANE_G)
         port map (
            axiClk          => axilClk,
            axiRst          => axilRst,
            axilReadMaster  => rxReadMaster,
            axilReadSlave   => rxReadSlave,
            axilWriteMaster => rxWriteMaster,
            axilWriteSlave  => rxWriteSlave,
            devClk_i        => devClk_i,
            devRst_i        => devRst_i,
            sysRef_i        => s_sysRef,
            sysRefDbg_o     => s_sysRefDbg,
            r_jesdGtRxArr   => r_jesdGtRxArr(JESD_RX_LANE_G-1 downto 0),
            gtRxReset_o     => s_gtRxUserReset(JESD_RX_LANE_G-1 downto 0),
            sampleDataArr_o => s_sampleDataArr(JESD_RX_LANE_G-1 downto 0),
            dataValidVec_o  => s_dataValidVec(JESD_RX_LANE_G-1 downto 0),
            nSync_o         => nSync_o,
            rxPowerDown     => rxPowerDown(JESD_RX_LANE_G-1 downto 0),
            rxPolarity      => rxPolarity(JESD_RX_LANE_G-1 downto 0));
      s_gtRxReset <= devRst_i or uOr(s_gtRxUserReset(JESD_RX_LANE_G-1 downto 0));
   end generate;

   TERM_UNUSED : if (JESD_RX_LANE_G /= 7) generate
      s_dataValidVec(4 downto JESD_RX_LANE_G)  <= (others => dummyZeroBit);
      s_sampleDataArr(4 downto JESD_RX_LANE_G) <= (others => (others => dummyZeroBit));
   end generate;

   BYP_RX_CORE : if (JESD_RX_LANE_G = 0) generate
      rxReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      rxWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      s_gtRxReset  <= devRst_i;
   end generate;

   ---------------
   -- JESD TX core
   ---------------
   EN_TX_CORE : if (JESD_TX_LANE_G /= 0) generate
      U_Jesd204bTx : entity surf.Jesd204bTx
         generic map (
            TPD_G => TPD_G,
            F_G   => 2,
            K_G   => 32,
            L_G   => JESD_TX_LANE_G)
         port map (
            axiClk               => axilClk,
            axiRst               => axilRst,
            axilReadMaster       => txReadMaster,
            axilReadSlave        => txReadSlave,
            axilWriteMaster      => txWriteMaster,
            axilWriteSlave       => txWriteSlave,
            extSampleDataArray_i => sampleDataArr_i(JESD_TX_LANE_G-1 downto 0),
            dacReady_o           => dacReady_o(JESD_TX_LANE_G-1 downto 0),
            devClk_i             => devClk_i,
            devRst_i             => devRst_i,
            sysRef_i             => s_sysRef,
            nSync_i              => nSync_i(JESD_TX_LANE_G-1 downto 0),
            gtTxReady_i          => s_gtTxReady(JESD_TX_LANE_G-1 downto 0),
            gtTxReset_o          => s_gtTxUserReset(JESD_TX_LANE_G-1 downto 0),
            r_jesdGtTxArr        => r_jesdGtTxArr(JESD_TX_LANE_G-1 downto 0),
            txDiffCtrl           => txDiffCtrl(JESD_TX_LANE_G-1 downto 0),
            txPostCursor         => txPostCursor(JESD_TX_LANE_G-1 downto 0),
            txPreCursor          => txPreCursor(JESD_TX_LANE_G-1 downto 0),
            txPowerDown          => txPowerDown(JESD_TX_LANE_G-1 downto 0),
            txPolarity           => txPolarity(JESD_TX_LANE_G-1 downto 0),
            txEnableL            => txInhibit(JESD_TX_LANE_G-1 downto 0));
      s_gtTxReset <= devRst_i or uOr(s_gtTxUserReset(JESD_TX_LANE_G-1 downto 0));
   end generate;

   BYP_TX_CORE : if (JESD_TX_LANE_G = 0) generate
      txReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      txWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      s_gtTxReset  <= devRst_i;
   end generate;

   -----------------
   -- GTH TX signals
   -----------------
   TX_LANES_GEN : for i in 4 downto 0 generate

      process(devClk_i)
      begin
         if rising_edge(devClk_i) then
            -- Help with timing
            s_txData((i*32)+31 downto (i*32)) <= r_jesdGtTxArr(i).data           after TPD_G;
            s_txDataK((i*8)+7 downto (i*8))   <= (x"0" & r_jesdGtTxArr(i).dataK) after TPD_G;
         end if;
      end process;

      s_gtTxReady(i)                     <= s_txDone;
      gtTxDiffCtrl((i*4)+3 downto i*4)   <= txDiffCtrl(i)(3 downto 0);
      gtTxPostCursor((i*5)+4 downto i*5) <= txPostCursor(i)(4 downto 0);
      gtTxPreCursor((i*5)+4 downto i*5)  <= txPreCursor(i)(4 downto 0);
      gtTxPd((i*2)+1 downto i*2)         <= txPowerDown(i) & txPowerDown(i);

   end generate TX_LANES_GEN;

   -----------------
   -- GTH RX signals
   -----------------
   RX_LANES_GEN : for i in 4 downto 0 generate

      process(devClk_i)
      begin
         if rising_edge(devClk_i) then
            -- Help with timing
            r_jesdGtRxArr(i).data      <= s_rxData(i*(GT_WORD_SIZE_C*8)+31 downto i*(GT_WORD_SIZE_C*8));
            r_jesdGtRxArr(i).dataK     <= s_rxctrl0(i*16+GT_WORD_SIZE_C-1 downto i*16);
            r_jesdGtRxArr(i).dispErr   <= s_rxctrl1(i*16+GT_WORD_SIZE_C-1 downto i*16);
            r_jesdGtRxArr(i).decErr    <= s_rxctrl3(i*8+GT_WORD_SIZE_C-1 downto i*8);
            r_jesdGtRxArr(i).rstDone   <= s_rxDone;
            r_jesdGtRxArr(i).cdrStable <= s_cdrStable;
         end if;
      end process;

      s_devClkVec(i)    <= devClk_i;
      s_devClk2Vec(i)   <= devClk2_i;
      s_stableClkVec(i) <= stableClk;
      s_gtRefClkVec(i)  <= refClk;

      gtRxPd((i*2)+1 downto i*2) <= rxPowerDown(i) & rxPowerDown(i);

      process(devClk_i)
      begin
         if rising_edge(devClk_i) then
            s_allignEnVec(i) <= not(s_dataValidVec(i)) after TPD_G;
         end if;
      end process;

   end generate RX_LANES_GEN;

   s_gtResetAll <= s_gtTxReset or s_gtRxReset;
   process(devClk_i)
   begin
      if rising_edge(devClk_i) then
         dummyZeroBit <= (devRst_i and s_txDone and s_rxDone) after TPD_G;
      end if;
   end process;

   GEN_GT : if ((JESD_RX_LANE_G /= 0) or (JESD_TX_LANE_G /= 0)) generate

      U_Coregen : AppTopJesd204bCoregen
         port map (
            -- Clocks
            gtwiz_userclk_tx_active_in(0)         => devClkActive_i,
            gtwiz_userclk_rx_active_in(0)         => devClkActive_i,
            gtwiz_buffbypass_tx_reset_in(0)       => s_gtTxReset,
            gtwiz_buffbypass_tx_start_user_in(0)  => s_gtTxReset,
            gtwiz_buffbypass_tx_done_out          => open,
            gtwiz_buffbypass_tx_error_out         => open,
            gtwiz_reset_clk_freerun_in(0)         => stableClk,
            gtwiz_reset_all_in(0)                 => s_gtResetAll,
            gtwiz_reset_tx_pll_and_datapath_in(0) => s_gtTxReset,
            gtwiz_reset_tx_datapath_in(0)         => s_gtTxReset,
            gtwiz_reset_rx_pll_and_datapath_in(0) => s_gtRxReset,
            gtwiz_reset_rx_datapath_in(0)         => s_gtRxReset,
            gtwiz_reset_rx_cdr_stable_out(0)      => s_cdrStable,
            gtwiz_reset_tx_done_out(0)            => s_txDone,
            gtwiz_reset_rx_done_out(0)            => s_rxDone,
            gtwiz_userdata_tx_in                  => s_txData,
            gtwiz_userdata_rx_out                 => s_rxData,
            drpaddr_in                            => drpAddr,
            drpclk_in                             => drpClk,
            drpdi_in                              => drpDi,
            drpen_in                              => drpEn,
            drpwe_in                              => drpWe,
            gthrxn_in                             => gtRxN,
            gthrxp_in                             => gtRxP,
            gtrefclk0_in                          => s_gtRefClkVec,
            loopback_in                           => (others => '0'),
            rx8b10ben_in                          => (others => '1'),
            rxcommadeten_in                       => (others => '1'),
            rxmcommaalignen_in                    => s_allignEnVec,
            rxpcommaalignen_in                    => s_allignEnVec,
            rxpd_in                               => gtRxPd,
            rxpolarity_in                         => JESD_RX_POLARITY_G,
            rxusrclk_in                           => s_devClkVec,
            rxusrclk2_in                          => s_devClk2Vec,
            tx8b10ben_in                          => (others => '1'),
            txctrl0_in                            => (others => '0'),
            txctrl1_in                            => (others => '0'),
            txctrl2_in                            => s_txDataK,
            txdiffctrl_in                         => gtTxDiffCtrl,
            txinhibit_in                          => txInhibit,
            txpd_in                               => gtTxPd,
            txpolarity_in                         => JESD_TX_POLARITY_G,
            txpostcursor_in                       => gtTxPostCursor,
            txprecursor_in                        => gtTxPreCursor,
            txusrclk_in                           => s_devClkVec,
            txusrclk2_in                          => s_devClk2Vec,
            drpdo_out                             => drpDo,
            drprdy_out                            => drpRdy,
            gthtxn_out                            => gtTxN,
            gthtxp_out                            => gtTxP,
            rxbyteisaligned_out                   => open,
            rxbyterealign_out                     => open,
            rxcommadet_out                        => open,
            rxctrl0_out                           => s_rxctrl0,
            rxctrl1_out                           => s_rxctrl1,
            rxctrl2_out                           => s_rxctrl2,
            rxctrl3_out                           => s_rxctrl3,
            rxoutclk_out                          => open,
            rxpmaresetdone_out                    => open,
            txoutclk_out                          => open,
            txpmaresetdone_out                    => open);
   end generate;

   BYP_GT : if ((JESD_RX_LANE_G = 0) and (JESD_TX_LANE_G = 0)) generate

      U_TERM_GT : entity surf.Gthe3ChannelDummy
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 5)
         port map (
            refClk => axilClk,
            gtRxP  => gtRxP,
            gtRxN  => gtRxN,
            gtTxP  => gtTxP,
            gtTxN  => gtTxN);

   end generate;

end mapping;
