-------------------------------------------------------------------------------
-- File       : AppTopJesd204b.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2018-02-12
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
use work.SsiPkg.all;
use work.Jesd204bPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppTopJesd204b is
   generic (
      TPD_G              : time                  := 1 ns;
      TEST_G             : boolean               := false;
      SYSREF_GEN_G       : boolean               := false;
      JESD_RX_LANE_G     : natural range 0 to 10 := 8;
      JESD_TX_LANE_G     : natural range 0 to 10 := 8;
      GT_LANE_G          : natural range 0 to 10 := 8;
      JESD_RX_POLARITY_G : slv(9 downto 0)       := "0000000000";
      JESD_TX_POLARITY_G : slv(9 downto 0)       := "0000000000");
   port (
      -- DRP Interface
      drpClk          : in  slv(GT_LANE_G-1 downto 0);
      drpRdy          : out slv(GT_LANE_G-1 downto 0);
      drpEn           : in  slv(GT_LANE_G-1 downto 0);
      drpWe           : in  slv(GT_LANE_G-1 downto 0);
      drpAddr         : in  slv(GT_LANE_G*9-1 downto 0);
      drpDi           : in  slv(GT_LANE_G*16-1 downto 0);
      drpDo           : out slv(GT_LANE_G*16-1 downto 0);
      -- AXI interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      rxReadMaster    : in  AxiLiteReadMasterType;
      rxReadSlave     : out AxiLiteReadSlaveType;
      rxWriteMaster   : in  AxiLiteWriteMasterType;
      rxWriteSlave    : out AxiLiteWriteSlaveType;
      txReadMaster    : in  AxiLiteReadMasterType;
      txReadSlave     : out AxiLiteReadSlaveType;
      txWriteMaster   : in  AxiLiteWriteMasterType;
      txWriteSlave    : out AxiLiteWriteSlaveType;
      -- Sample data output (Use if external data acquisition core is attached)
      sampleDataArr_o : out sampleDataArray(GT_LANE_G-1 downto 0);
      dataValidVec_o  : out slv(GT_LANE_G-1 downto 0);
      -- Sample data input (Use if external data generator core is attached)      
      sampleDataArr_i : in  sampleDataArray(GT_LANE_G-1 downto 0);
      -------
      -- JESD
      -------
      -- Clocks
      stableClk       : in  sl;  -- GT needs a stable clock to "boot up"(buffered refClkDiv2) 
      refClkR         : in  sl;  -- GT Reference clock directly from GT GTH diff. input buffer Right
      refClkL         : in  sl;  -- GT Reference clock directly from GT GTH diff. input buffer Left 
      devClk_i        : in  sl;         -- Device clock also rxUsrClkIn for MGT
      devClk2_i       : in  sl;         -- Device clock divided by 2 also rxUsrClk2In for MGT       
      devRst_i        : in  sl;         -- 
      devClkActive_i  : in  sl := '1';  -- devClk_i MCMM locked      
      -- GTH Ports
      gtTxP           : out slv(GT_LANE_G-1 downto 0);  -- GT Serial Transmit Positive
      gtTxN           : out slv(GT_LANE_G-1 downto 0);  -- GT Serial Transmit Negative
      gtRxP           : in  slv(GT_LANE_G-1 downto 0);  -- GT Serial Receive Positive
      gtRxN           : in  slv(GT_LANE_G-1 downto 0);  -- GT Serial Receive Negative      
      -- SYSREF for subclass 1 fixed latency
      sysRef_i        : in  sl;
      -- Synchronization output combined from all receivers to be connected to ADC/DAC chips
      nSync_o         : out sl;         -- Active HIGH
      nSync_i         : in  sl);        -- Active HIGH
end AppTopJesd204b;

architecture mapping of AppTopJesd204b is

   component JesdCryoCoreRightColumn
      port (
         gtwiz_userclk_tx_active_in         : in  std_logic_vector (0 to 0);
         gtwiz_userclk_rx_active_in         : in  std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_reset_in       : in  std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_start_user_in  : in  std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_done_out       : out std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_error_out      : out std_logic_vector (0 to 0);
         gtwiz_reset_clk_freerun_in         : in  std_logic_vector (0 to 0);
         gtwiz_reset_all_in                 : in  std_logic_vector (0 to 0);
         gtwiz_reset_tx_pll_and_datapath_in : in  std_logic_vector (0 to 0);
         gtwiz_reset_tx_datapath_in         : in  std_logic_vector (0 to 0);
         gtwiz_reset_rx_pll_and_datapath_in : in  std_logic_vector (0 to 0);
         gtwiz_reset_rx_datapath_in         : in  std_logic_vector (0 to 0);
         gtwiz_reset_rx_cdr_stable_out      : out std_logic_vector (0 to 0);
         gtwiz_reset_tx_done_out            : out std_logic_vector (0 to 0);
         gtwiz_reset_rx_done_out            : out std_logic_vector (0 to 0);
         gtwiz_userdata_tx_in               : in  std_logic_vector (223 downto 0);
         gtwiz_userdata_rx_out              : out std_logic_vector (223 downto 0);
         drpaddr_in                         : in  std_logic_vector (62 downto 0);
         drpclk_in                          : in  std_logic_vector (6 downto 0);
         drpdi_in                           : in  std_logic_vector (111 downto 0);
         drpen_in                           : in  std_logic_vector (6 downto 0);
         drpwe_in                           : in  std_logic_vector (6 downto 0);
         gthrxn_in                          : in  std_logic_vector (6 downto 0);
         gthrxp_in                          : in  std_logic_vector (6 downto 0);
         gtrefclk0_in                       : in  std_logic_vector (6 downto 0);
         loopback_in                        : in  std_logic_vector(20 downto 0);
         rx8b10ben_in                       : in  std_logic_vector (6 downto 0);
         rxcommadeten_in                    : in  std_logic_vector (6 downto 0);
         rxmcommaalignen_in                 : in  std_logic_vector (6 downto 0);
         rxpcommaalignen_in                 : in  std_logic_vector (6 downto 0);
         rxpd_in                            : in  std_logic_vector (13 downto 0);
         rxpolarity_in                      : in  std_logic_vector (6 downto 0);
         rxusrclk_in                        : in  std_logic_vector (6 downto 0);
         rxusrclk2_in                       : in  std_logic_vector (6 downto 0);
         tx8b10ben_in                       : in  std_logic_vector (6 downto 0);
         txctrl0_in                         : in  std_logic_vector (111 downto 0);
         txctrl1_in                         : in  std_logic_vector (111 downto 0);
         txctrl2_in                         : in  std_logic_vector (55 downto 0);
         txdiffctrl_in                      : in  std_logic_vector (27 downto 0);
         txinhibit_in                       : in  std_logic_vector(6 downto 0);
         txpd_in                            : in  std_logic_vector (13 downto 0);
         txpolarity_in                      : in  std_logic_vector (6 downto 0);
         txpostcursor_in                    : in  std_logic_vector (34 downto 0);
         txprecursor_in                     : in  std_logic_vector (34 downto 0);
         txusrclk_in                        : in  std_logic_vector (6 downto 0);
         txusrclk2_in                       : in  std_logic_vector (6 downto 0);
         drpdo_out                          : out std_logic_vector (111 downto 0);
         drprdy_out                         : out std_logic_vector (6 downto 0);
         gthtxn_out                         : out std_logic_vector (6 downto 0);
         gthtxp_out                         : out std_logic_vector (6 downto 0);
         rxbyteisaligned_out                : out std_logic_vector (6 downto 0);
         rxbyterealign_out                  : out std_logic_vector (6 downto 0);
         rxcommadet_out                     : out std_logic_vector (6 downto 0);
         rxctrl0_out                        : out std_logic_vector (111 downto 0);
         rxctrl1_out                        : out std_logic_vector (111 downto 0);
         rxctrl2_out                        : out std_logic_vector (55 downto 0);
         rxctrl3_out                        : out std_logic_vector (55 downto 0);
         rxoutclk_out                       : out std_logic_vector (6 downto 0);
         rxpmaresetdone_out                 : out std_logic_vector (6 downto 0);
         txoutclk_out                       : out std_logic_vector (6 downto 0);
         txpmaresetdone_out                 : out std_logic_vector (6 downto 0);
         txprgdivresetdone_out              : out std_logic_vector (6 downto 0)
         );
   end component;

   component JesdCryoCoreLeftColumn
      port (
         gtwiz_userclk_tx_active_in         : in  std_logic_vector (0 to 0);
         gtwiz_userclk_rx_active_in         : in  std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_reset_in       : in  std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_start_user_in  : in  std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_done_out       : out std_logic_vector (0 to 0);
         gtwiz_buffbypass_tx_error_out      : out std_logic_vector (0 to 0);
         gtwiz_reset_clk_freerun_in         : in  std_logic_vector (0 to 0);
         gtwiz_reset_all_in                 : in  std_logic_vector (0 to 0);
         gtwiz_reset_tx_pll_and_datapath_in : in  std_logic_vector (0 to 0);
         gtwiz_reset_tx_datapath_in         : in  std_logic_vector (0 to 0);
         gtwiz_reset_rx_pll_and_datapath_in : in  std_logic_vector (0 to 0);
         gtwiz_reset_rx_datapath_in         : in  std_logic_vector (0 to 0);
         gtwiz_reset_rx_cdr_stable_out      : out std_logic_vector (0 to 0);
         gtwiz_reset_tx_done_out            : out std_logic_vector (0 to 0);
         gtwiz_reset_rx_done_out            : out std_logic_vector (0 to 0);
         gtwiz_userdata_tx_in               : in  std_logic_vector (95 downto 0);
         gtwiz_userdata_rx_out              : out std_logic_vector (95 downto 0);
         drpaddr_in                         : in  std_logic_vector (26 downto 0);
         drpclk_in                          : in  std_logic_vector (2 downto 0);
         drpdi_in                           : in  std_logic_vector (47 downto 0);
         drpen_in                           : in  std_logic_vector (2 downto 0);
         drpwe_in                           : in  std_logic_vector (2 downto 0);
         gthrxn_in                          : in  std_logic_vector (2 downto 0);
         gthrxp_in                          : in  std_logic_vector (2 downto 0);
         gtrefclk0_in                       : in  std_logic_vector (2 downto 0);
         loopback_in                        : in  std_logic_vector(8 downto 0);
         rx8b10ben_in                       : in  std_logic_vector (2 downto 0);
         rxcommadeten_in                    : in  std_logic_vector (2 downto 0);
         rxmcommaalignen_in                 : in  std_logic_vector (2 downto 0);
         rxpcommaalignen_in                 : in  std_logic_vector (2 downto 0);
         rxpd_in                            : in  std_logic_vector (5 downto 0);
         rxpolarity_in                      : in  std_logic_vector (2 downto 0);
         rxusrclk_in                        : in  std_logic_vector (2 downto 0);
         rxusrclk2_in                       : in  std_logic_vector (2 downto 0);
         tx8b10ben_in                       : in  std_logic_vector (2 downto 0);
         txctrl0_in                         : in  std_logic_vector (47 downto 0);
         txctrl1_in                         : in  std_logic_vector (47 downto 0);
         txctrl2_in                         : in  std_logic_vector (23 downto 0);
         txdiffctrl_in                      : in  std_logic_vector (11 downto 0);
         txinhibit_in                       : in  std_logic_vector(2 downto 0);
         txpd_in                            : in  std_logic_vector (5 downto 0);
         txpolarity_in                      : in  std_logic_vector (2 downto 0);
         txpostcursor_in                    : in  std_logic_vector (14 downto 0);
         txprecursor_in                     : in  std_logic_vector (14 downto 0);
         txusrclk_in                        : in  std_logic_vector (2 downto 0);
         txusrclk2_in                       : in  std_logic_vector (2 downto 0);
         drpdo_out                          : out std_logic_vector (47 downto 0);
         drprdy_out                         : out std_logic_vector (2 downto 0);
         gthtxn_out                         : out std_logic_vector (2 downto 0);
         gthtxp_out                         : out std_logic_vector (2 downto 0);
         rxbyteisaligned_out                : out std_logic_vector (2 downto 0);
         rxbyterealign_out                  : out std_logic_vector (2 downto 0);
         rxcommadet_out                     : out std_logic_vector (2 downto 0);
         rxctrl0_out                        : out std_logic_vector (47 downto 0);
         rxctrl1_out                        : out std_logic_vector (47 downto 0);
         rxctrl2_out                        : out std_logic_vector (23 downto 0);
         rxctrl3_out                        : out std_logic_vector (23 downto 0);
         rxoutclk_out                       : out std_logic_vector (2 downto 0);
         rxpmaresetdone_out                 : out std_logic_vector (2 downto 0);
         txoutclk_out                       : out std_logic_vector (2 downto 0);
         txpmaresetdone_out                 : out std_logic_vector (2 downto 0);
         txprgdivresetdone_out              : out std_logic_vector (2 downto 0)
         );
   end component;


   signal r_jesdGtRxArr : jesdGtRxLaneTypeArray(GT_LANE_G-1 downto 0) := (others => JESD_GT_RX_LANE_INIT_C);
   signal r_jesdGtTxArr : jesdGtTxLaneTypeArray(GT_LANE_G-1 downto 0) := (others => JESD_GT_TX_LANE_INIT_C);

   signal s_gtRxUserReset : slv(GT_LANE_G-1 downto 0) := (others => '0');
   signal s_gtRxReset     : sl                        := '0';
   signal s_gtTxUserReset : slv(GT_LANE_G-1 downto 0) := (others => '0');
   signal s_gtTxReset     : sl                        := '0';
   signal s_gtResetAll    : sl                        := '0';

   signal s_sysRef        : sl                                    := '0';
   signal s_sysRefDbg     : sl                                    := '0';
   signal s_rxctrl0       : slv(GT_LANE_G*16-1 downto 0)          := (others => '0');
   signal s_rxctrl1       : slv(GT_LANE_G*16-1 downto 0)          := (others => '0');
   signal s_rxctrl2       : slv(GT_LANE_G*8-1 downto 0)           := (others => '0');
   signal s_rxctrl3       : slv(GT_LANE_G*8-1 downto 0)           := (others => '0');
   signal s_rxData        : slv(GT_LANE_G*32-1 downto 0)          := (others => '0');
   signal s_txData        : slv(GT_LANE_G*32-1 downto 0)          := (others => '0');
   signal s_txDataK       : slv(GT_LANE_G*8-1 downto 0)           := (others => '0');
   signal s_devClkVec     : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_devClk2Vec    : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_stableClkVec  : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_gtRefClkVec   : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_rxDone        : slv(1 downto 0)                       := (others => '0');
   signal s_txDone        : slv(1 downto 0)                       := (others => '0');
   signal s_gtTxReady     : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_allignEnVec   : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_dataValidVec  : slv(GT_LANE_G-1 downto 0)             := (others => '0');
   signal s_sampleDataArr : sampleDataArray(GT_LANE_G-1 downto 0) := (others => (others => '0'));

   signal txDiffCtrl   : Slv8Array(GT_LANE_G-1 downto 0) := (others => (others => '1'));
   signal txPostCursor : Slv8Array(GT_LANE_G-1 downto 0) := (others => (others => '0'));
   signal txPreCursor  : Slv8Array(GT_LANE_G-1 downto 0) := (others => (others => '0'));
   signal txPolarity   : slv(GT_LANE_G-1 downto 0)       := (others => '0');
   signal rxPolarity   : slv(GT_LANE_G-1 downto 0)       := (others => '0');
   signal txInhibit    : slv(GT_LANE_G-1 downto 0)       := (others => '1');

   signal gtTxDiffCtrl   : slv(GT_LANE_G*4-1 downto 0) := (others => '1');
   signal gtTxPostCursor : slv(GT_LANE_G*5-1 downto 0) := (others => '0');
   signal gtTxPreCursor  : slv(GT_LANE_G*5-1 downto 0) := (others => '0');

   signal s_cdrStable  : slv(1 downto 0);
   signal dummyZeroBit : sl;

   type RegType is record
      jesdGtRxArr : jesdGtRxLaneTypeArray(GT_LANE_G-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      jesdGtRxArr => (others => JESD_GT_RX_LANE_INIT_C)
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   dataValidVec_o  <= s_dataValidVec;
   sampleDataArr_o <= s_sampleDataArr;

   ---------------
   -- JESD RX core
   ---------------
   EN_RX_CORE : if (JESD_RX_LANE_G /= 0) generate
      U_Jesd204bRx : entity work.Jesd204bRx
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
            r_jesdGtRxArr   => r.jesdGtRxArr(JESD_RX_LANE_G-1 downto 0),
            gtRxReset_o     => s_gtRxUserReset(JESD_RX_LANE_G-1 downto 0),
            sampleDataArr_o => s_sampleDataArr(JESD_RX_LANE_G-1 downto 0),
            dataValidVec_o  => s_dataValidVec(JESD_RX_LANE_G-1 downto 0),
            nSync_o         => nSync_o,
            rxPolarity      => rxPolarity);
      s_gtRxReset <= devRst_i or uOr(s_gtRxUserReset(JESD_RX_LANE_G-1 downto 0));
   end generate;

   TERM_UNUSED : if (JESD_RX_LANE_G /= GT_LANE_G) generate
      s_dataValidVec(GT_LANE_G-1 downto JESD_RX_LANE_G)  <= (others => dummyZeroBit);
      s_sampleDataArr(GT_LANE_G-1 downto JESD_RX_LANE_G) <= (others => (others => dummyZeroBit));
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
      U_Jesd204bTx : entity work.Jesd204bTx
         generic map (
            TPD_G        => TPD_G,
            INPUT_REG_G  => true,
            OUTPUT_REG_G => true,
            F_G          => 2,
            K_G          => 32,
            L_G          => JESD_TX_LANE_G)
         port map (
            axiClk               => axilClk,
            axiRst               => axilRst,
            axilReadMaster       => txReadMaster,
            axilReadSlave        => txReadSlave,
            axilWriteMaster      => txWriteMaster,
            axilWriteSlave       => txWriteSlave,
            extSampleDataArray_i => sampleDataArr_i(JESD_TX_LANE_G-1 downto 0),
            devClk_i             => devClk_i,
            devRst_i             => devRst_i,
            sysRef_i             => s_sysRef,
            nSync_i              => nSync_i,
            gtTxReady_i          => s_gtTxReady(JESD_TX_LANE_G-1 downto 0),
            gtTxReset_o          => s_gtTxUserReset(JESD_TX_LANE_G-1 downto 0),
            r_jesdGtTxArr        => r_jesdGtTxArr(JESD_TX_LANE_G-1 downto 0),
            txDiffCtrl           => txDiffCtrl,
            txPostCursor         => txPostCursor,
            txPreCursor          => txPreCursor,
            txPolarity           => txPolarity,
            txEnableL            => txInhibit);

      s_gtTxReset <= devRst_i or uOr(s_gtTxUserReset(JESD_TX_LANE_G-1 downto 0));
   end generate;

   BYP_TX_CORE : if (JESD_TX_LANE_G = 0) generate
      txReadSlave  <= AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      txWriteSlave <= AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      s_gtTxReset  <= devRst_i;
   end generate;

   -------------------------------------------
   -- Generate the internal or external SYSREF 
   -------------------------------------------
   SELF_TEST_GEN : if SYSREF_GEN_G = true generate
      -- Generate the sysref internally
      -- Sysref period will be 8x K_G.
      SysrefGen_INST : entity work.JesdLmfcGen
         generic map (
            TPD_G => TPD_G,
            K_G   => 256,
            F_G   => 2)
         port map (
            clk      => devClk_i,
            rst      => devRst_i,
            nSync_i  => '0',
            sysref_i => '0',
            lmfc_o   => s_sysRef
            );
   end generate SELF_TEST_GEN;

   OPER_GEN : if SYSREF_GEN_G = false generate
      s_sysRef <= sysRef_i;
   end generate OPER_GEN;

   -----------------
   -- GTH TX signals
   -----------------   
   TX_LANES_GEN : for i in GT_LANE_G-1 downto 0 generate
      process(devClk_i)
      begin
         if rising_edge(devClk_i) then
            -- Help with timing
            s_txData((i*32)+31 downto (i*32)) <= r_jesdGtTxArr(i).data           after TPD_G;
            s_txDataK((i*8)+7 downto (i*8))   <= (x"0" & r_jesdGtTxArr(i).dataK) after TPD_G;
         end if;
      end process;

      s_gtTxReady(i)                     <= s_txDone(0) when (i < 7) else s_txDone(1);
      gtTxDiffCtrl((i*4)+3 downto i*4)   <= txDiffCtrl(i)(3 downto 0);
      gtTxPostCursor((i*5)+4 downto i*5) <= txPostCursor(i)(4 downto 0);
      gtTxPreCursor((i*5)+4 downto i*5)  <= txPreCursor(i)(4 downto 0);

   end generate TX_LANES_GEN;

   -----------------
   -- GTH RX signals
   -----------------
   RX_LANES_GEN : for i in GT_LANE_G-1 downto 0 generate

      r_jesdGtRxArr(i).data      <= s_rxData(i*(GT_WORD_SIZE_C*8)+31 downto i*(GT_WORD_SIZE_C*8));
      r_jesdGtRxArr(i).dataK     <= s_rxctrl0(i*16+GT_WORD_SIZE_C-1 downto i*16);
      r_jesdGtRxArr(i).dispErr   <= s_rxctrl1(i*16+GT_WORD_SIZE_C-1 downto i*16);
      r_jesdGtRxArr(i).decErr    <= s_rxctrl3(i*8+GT_WORD_SIZE_C-1 downto i*8);
      r_jesdGtRxArr(i).rstDone   <= s_rxDone(0)    when i < 7 else s_rxDone(1);
      r_jesdGtRxArr(i).cdrStable <= s_cdrStable(0) when i < 7 else s_cdrStable(1);

      s_devClkVec(i)    <= devClk_i;
      s_devClk2Vec(i)   <= devClk2_i;
      s_stableClkVec(i) <= stableClk;
      s_gtRefClkVec(i)  <= refClkR when i < 7 else refClkL;

      process(devClk_i)
      begin
         if rising_edge(devClk_i) then
            s_allignEnVec(i) <= not(s_dataValidVec(i)) after TPD_G;
         end if;
      end process;

   end generate RX_LANES_GEN;

   process(devClk_i)
   begin
      if rising_edge(devClk_i) then
         s_gtResetAll <= s_gtTxReset or s_gtRxReset                     after TPD_G;
         dummyZeroBit <= devRst_i and uAnd(s_txDone) and uAnd(s_rxDone) after TPD_G;
      end if;
   end process;

   U_Coregen_Right : JesdCryoCoreRightColumn
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
         gtwiz_reset_rx_cdr_stable_out(0)      => s_cdrStable(0),
         gtwiz_reset_tx_done_out(0)            => s_txDone(0),
         gtwiz_reset_rx_done_out(0)            => s_rxDone(0),
         gtwiz_userdata_tx_in                  => s_txData(223 downto 0),
         gtwiz_userdata_rx_out                 => s_rxData(223 downto 0),
         drpaddr_in                            => drpAddr(62 downto 0),
         drpclk_in                             => drpClk(6 downto 0),
         drpdi_in                              => drpDi(111 downto 0),
         drpen_in                              => drpEn(6 downto 0),
         drpwe_in                              => drpWe(6 downto 0),
         gthrxn_in                             => gtRxN(6 downto 0),
         gthrxp_in                             => gtRxP(6 downto 0),
         gtrefclk0_in                          => s_gtRefClkVec(6 downto 0),
         loopback_in                           => (others => '0'),
         rx8b10ben_in                          => (others => '1'),
         rxcommadeten_in                       => (others => '1'),
         rxmcommaalignen_in                    => s_allignEnVec(6 downto 0),
         rxpcommaalignen_in                    => s_allignEnVec(6 downto 0),
         rxpd_in                               => (others => '0'),
         rxpolarity_in                         => rxPolarity(6 downto 0),
         rxusrclk_in                           => s_devClkVec(6 downto 0),
         rxusrclk2_in                          => s_devClk2Vec(6 downto 0),
         tx8b10ben_in                          => (others => '1'),
         txctrl0_in                            => (others => '0'),
         txctrl1_in                            => (others => '0'),
         txctrl2_in                            => s_txDataK(55 downto 0),
         txdiffctrl_in                         => gtTxDiffCtrl(27 downto 0),
         txinhibit_in                          => txInhibit(6 downto 0),
         txpd_in                               => (others => '0'),
         txpolarity_in                         => txPolarity(6 downto 0),
         txpostcursor_in                       => gtTxPostCursor(34 downto 0),
         txprecursor_in                        => gtTxPreCursor(34 downto 0),
         txusrclk_in                           => s_devClkVec(6 downto 0),
         txusrclk2_in                          => s_devClk2Vec(6 downto 0),
         drpdo_out                             => drpDo(111 downto 0),
         drprdy_out                            => drpRdy(6 downto 0),
         gthtxn_out                            => gtTxN(6 downto 0),
         gthtxp_out                            => gtTxP(6 downto 0),
         rxbyteisaligned_out                   => open,
         rxbyterealign_out                     => open,
         rxcommadet_out                        => open,
         rxctrl0_out                           => s_rxctrl0(111 downto 0),
         rxctrl1_out                           => s_rxctrl1(111 downto 0),
         rxctrl2_out                           => s_rxctrl2(55 downto 0),
         rxctrl3_out                           => s_rxctrl3(55 downto 0),
         rxoutclk_out                          => open,
         rxpmaresetdone_out                    => open,
         txoutclk_out                          => open,
         txpmaresetdone_out                    => open);

   U_Coregen_Left : JesdCryoCoreLeftColumn
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
         gtwiz_reset_rx_cdr_stable_out(0)      => s_cdrStable(1),
         gtwiz_reset_tx_done_out(0)            => s_txDone(1),
         gtwiz_reset_rx_done_out(0)            => s_rxDone(1),
         gtwiz_userdata_tx_in                  => s_txData(319 downto 224),
         gtwiz_userdata_rx_out                 => s_rxData(319 downto 224),
         drpaddr_in                            => drpAddr(89 downto 63),
         drpclk_in                             => drpClk(9 downto 7),
         drpdi_in                              => drpDi(159 downto 112),
         drpen_in                              => drpEn(9 downto 7),
         drpwe_in                              => drpWe(9 downto 7),
         gthrxn_in                             => gtRxN(9 downto 7),
         gthrxp_in                             => gtRxP(9 downto 7),
         gtrefclk0_in                          => s_gtRefClkVec(9 downto 7),
         loopback_in                           => (others => '0'),
         rx8b10ben_in                          => (others => '1'),
         rxcommadeten_in                       => (others => '1'),
         rxmcommaalignen_in                    => s_allignEnVec(9 downto 7),
         rxpcommaalignen_in                    => s_allignEnVec(9 downto 7),
         rxpd_in                               => (others => '0'),
         rxpolarity_in                         => rxPolarity(9 downto 7),
         rxusrclk_in                           => s_devClkVec(9 downto 7),
         rxusrclk2_in                          => s_devClk2Vec(9 downto 7),
         tx8b10ben_in                          => (others => '1'),
         txctrl0_in                            => (others => '0'),
         txctrl1_in                            => (others => '0'),
         txctrl2_in                            => s_txDataK(79 downto 56),
         txdiffctrl_in                         => gtTxDiffCtrl(39 downto 28),
         txinhibit_in                          => txInhibit(9 downto 7),
         txpd_in                               => (others => '0'),
         txpolarity_in                         => txPolarity(9 downto 7),
         txpostcursor_in                       => gtTxPostCursor(49 downto 35),
         txprecursor_in                        => gtTxPreCursor(49 downto 35),
         txusrclk_in                           => s_devClkVec(9 downto 7),
         txusrclk2_in                          => s_devClk2Vec(9 downto 7),
         drpdo_out                             => drpDo(159 downto 112),
         drprdy_out                            => drpRdy(9 downto 7),
         gthtxn_out                            => gtTxN(9 downto 7),
         gthtxp_out                            => gtTxP(9 downto 7),
         rxbyteisaligned_out                   => open,
         rxbyterealign_out                     => open,
         rxcommadet_out                        => open,
         rxctrl0_out                           => s_rxctrl0(159 downto 112),
         rxctrl1_out                           => s_rxctrl1(159 downto 112),
         rxctrl2_out                           => s_rxctrl2(79 downto 56),
         rxctrl3_out                           => s_rxctrl3(79 downto 56),
         rxoutclk_out                          => open,
         rxpmaresetdone_out                    => open,
         txoutclk_out                          => open,
         txpmaresetdone_out                    => open);



   comb : process (devRst_i, r, r_jesdGtRxArr) is
      variable v : RegType;
   begin
      v := r;

      -- Register/Delay for 1 clock cycle 
      v.jesdGtRxArr := r_jesdGtRxArr;

      if (devRst_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Output assignment
      rin <= v;
   end process comb;

   seq : process (devClk_i) is
   begin
      if (rising_edge(devClk_i)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

--------------------------------------------------------------------
end mapping;
