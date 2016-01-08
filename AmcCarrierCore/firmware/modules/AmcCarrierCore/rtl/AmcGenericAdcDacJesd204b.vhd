-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacJesd204b.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2015-12-04
-- Platform   : 
-- Standard   : VHDL'93/02
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

entity AmcGenericAdcDacJesd204b is
   generic (
      TPD_G            : time            := 1 ns;
      TEST_G           : boolean         := false;
      SYSREF_GEN_G     : boolean         := false;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C);
   port (
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
      sampleDataArr_o : out sampleDataArray(3 downto 0);
      dataValidVec_o  : out slv(3 downto 0);
      -- Sample data input (Use if external data generator core is attached)      
      sampleDataArr_i : in  sampleDataArray(1 downto 0);
      -------
      -- JESD
      -------
      -- Clocks
      stableClk       : in  sl;  -- GT needs a stable clock to "boot up"(buffered refClkDiv2) 
      refClk          : in  sl;  -- GT Reference clock directly from GT GTH diff. input buffer   
      devClk_i        : in  sl;         -- Device clock also rxUsrClkIn for MGT
      devClk2_i       : in  sl;         -- Device clock divided by 2 also rxUsrClk2In for MGT       
      devRst_i        : in  sl;         -- 
      devClkActive_i  : in  sl := '1';  -- devClk_i MCMM locked      
      -- GTH Ports
      gtTxP           : out slv(3 downto 0);  -- GT Serial Transmit Positive
      gtTxN           : out slv(3 downto 0);  -- GT Serial Transmit Negative
      gtRxP           : in  slv(3 downto 0);  -- GT Serial Receive Positive
      gtRxN           : in  slv(3 downto 0);  -- GT Serial Receive Negative      
      -- SYSREF for subclass 1 fixed latency
      sysRef_i        : in  sl;
      -- Synchronisation output combined from all receivers to be connected to ADC/DAC chips
      nSync_o         : out sl;         -- Active HIGH
      nSync_i         : in  sl);        -- Active HIGH
end AmcGenericAdcDacJesd204b;

architecture mapping of AmcGenericAdcDacJesd204b is

   component AmcGenericAdcDacJesd204bCoregen
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
         gtwiz_userdata_tx_in               : in  std_logic_vector(127 downto 0);
         gtwiz_userdata_rx_out              : out std_logic_vector(127 downto 0);
         drpclk_in                          : in  std_logic_vector(3 downto 0);
         gthrxn_in                          : in  std_logic_vector(3 downto 0);
         gthrxp_in                          : in  std_logic_vector(3 downto 0);
         gtrefclk0_in                       : in  std_logic_vector(3 downto 0);
         rx8b10ben_in                       : in  std_logic_vector(3 downto 0);
         rxcommadeten_in                    : in  std_logic_vector(3 downto 0);
         rxmcommaalignen_in                 : in  std_logic_vector(3 downto 0);
         rxpcommaalignen_in                 : in  std_logic_vector(3 downto 0);
         rxpolarity_in                      : in  std_logic_vector(3 downto 0);
         rxusrclk_in                        : in  std_logic_vector(3 downto 0);
         rxusrclk2_in                       : in  std_logic_vector(3 downto 0);
         tx8b10ben_in                       : in  std_logic_vector(3 downto 0);
         txctrl0_in                         : in  std_logic_vector(63 downto 0);
         txctrl1_in                         : in  std_logic_vector(63 downto 0);
         txctrl2_in                         : in  std_logic_vector(31 downto 0);
         txpd_in                            : in  std_logic_vector(7 downto 0);
         txpolarity_in                      : in  std_logic_vector(3 downto 0);
         txusrclk_in                        : in  std_logic_vector(3 downto 0);
         txusrclk2_in                       : in  std_logic_vector(3 downto 0);
         gthtxn_out                         : out std_logic_vector(3 downto 0);
         gthtxp_out                         : out std_logic_vector(3 downto 0);
         rxbyteisaligned_out                : out std_logic_vector(3 downto 0);
         rxbyterealign_out                  : out std_logic_vector(3 downto 0);
         rxcommadet_out                     : out std_logic_vector(3 downto 0);
         rxctrl0_out                        : out std_logic_vector(63 downto 0);
         rxctrl1_out                        : out std_logic_vector(63 downto 0);
         rxctrl2_out                        : out std_logic_vector(31 downto 0);
         rxctrl3_out                        : out std_logic_vector(31 downto 0);
         rxoutclk_out                       : out std_logic_vector(3 downto 0);
         rxpmaresetdone_out                 : out std_logic_vector(3 downto 0);
         txoutclk_out                       : out std_logic_vector(3 downto 0);
         txpmaresetdone_out                 : out std_logic_vector(3 downto 0));
   end component;

   signal r_jesdGtRxArr : jesdGtRxLaneTypeArray(3 downto 0);
   signal r_jesdGtTxArr : jesdGtTxLaneTypeArray(1 downto 0);

   signal s_gtRxUserReset : slv(3 downto 0);
   signal s_gtRxReset     : sl;
   signal s_gtTxUserReset : slv(1 downto 0);
   signal s_gtTxReset     : sl;

   signal s_sysRef       : sl;
   signal s_sysRefDbg    : sl;
   signal s_rxctrl0      : slv(63 downto 0)  := (others => '0');
   signal s_rxctrl1      : slv(63 downto 0)  := (others => '0');
   signal s_rxctrl2      : slv(31 downto 0)  := (others => '0');
   signal s_rxctrl3      : slv(31 downto 0)  := (others => '0');
   signal s_rxData       : slv(127 downto 0) := (others => '0');
   signal s_txData       : slv(127 downto 0) := (others => '0');
   signal s_txDataK      : slv(31 downto 0)  := (others => '0');
   signal s_devClkVec    : slv(3 downto 0)   := (others => '0');
   signal s_devClk2Vec   : slv(3 downto 0)   := (others => '0');
   signal s_stableClkVec : slv(3 downto 0)   := (others => '0');
   signal s_gtRefClkVec  : slv(3 downto 0)   := (others => '0');
   signal s_rxDone       : sl;
   signal s_txDone       : sl;
   signal s_gtTxReady    : slv(1 downto 0)   := (others => '0');
   signal s_dataValidVec : slv(3 downto 0)   := (others => '0');
   signal s_allignEnVec  : slv(3 downto 0)   := (others => '0');

begin

   dataValidVec_o <= s_dataValidVec;

   ---------------
   -- JESD RX core
   ---------------
   Jesd204bRx_INST : entity work.Jesd204bRx
      generic map (
         TPD_G            => TPD_G,
         TEST_G           => TEST_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         F_G              => 2,
         K_G              => 32,
         L_G              => 4)
      port map (
         axiClk            => axilClk,
         axiRst            => axilRst,
         axilReadMaster    => rxReadMaster,
         axilReadSlave     => rxReadSlave,
         axilWriteMaster   => rxWriteMaster,
         axilWriteSlave    => rxWriteSlave,
         rxAxisMasterArr_o => open,
         rxCtrlArr_i       => (others => AXI_STREAM_CTRL_UNUSED_C),
         devClk_i          => devClk_i,
         devRst_i          => devRst_i,
         sysRef_i          => s_sysRef,
         sysRefDbg_o       => s_sysRefDbg,
         r_jesdGtRxArr     => r_jesdGtRxArr,
         gtRxReset_o       => s_gtRxUserReset,
         sampleDataArr_o   => sampleDataArr_o,
         dataValidVec_o    => s_dataValidVec,
         nSync_o           => nSync_o,
         pulse_o           => open,
         leds_o            => open);

   ---------------
   -- JESD TX core
   ---------------         
   Jesd204bTx_INST : entity work.Jesd204bTx
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         F_G              => 2,
         K_G              => 32,
         L_G              => 2)
      port map (
         axiClk               => axilClk,
         axiRst               => axilRst,
         axilReadMaster       => txReadMaster,
         axilReadSlave        => txReadSlave,
         axilWriteMaster      => txWriteMaster,
         axilWriteSlave       => txWriteSlave,
         txAxisMasterArr_i    => (others => AXI_STREAM_MASTER_INIT_C),
         txAxisSlaveArr_o     => open,
         extSampleDataArray_i => sampleDataArr_i,
         devClk_i             => devClk_i,
         devRst_i             => devRst_i,
         sysRef_i             => s_sysRef,
         nSync_i              => nSync_i,
         gtTxReady_i          => s_gtTxReady,
         gtTxReset_o          => s_gtTxUserReset,
         r_jesdGtTxArr        => r_jesdGtTxArr,
         pulse_o              => open,
         leds_o               => open);

   -------------------------------------------
   -- Generate the internal or external SYSREF 
   -------------------------------------------
   SELF_TEST_GEN : if SYSREF_GEN_G = true generate
      -- Generate the sysref internally
      -- Sysref period will be 8x K_G.
      SysrefGen_INST : entity work.LmfcGen
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
   s_gtTxReset <= devRst_i or uOr(s_gtTxUserReset);
   s_txData    <= x"00000000_00000000" & r_jesdGtTxArr(1).data & r_jesdGtTxArr(0).data;
   s_txDataK   <= x"00_00" & x"0" & r_jesdGtTxArr(1).dataK & X"0" & r_jesdGtTxArr(0).dataK;
   s_gtTxReady <= s_txDone & s_txDone;

   -----------------
   -- GTH RX signals
   -----------------
   s_gtRxReset <= devRst_i or uOr(s_gtRxUserReset);

   RX_LANES_GEN : for i in 3 downto 0 generate
      r_jesdGtRxArr(i).data    <= s_rxData(i*(GT_WORD_SIZE_C*8)+31 downto i*(GT_WORD_SIZE_C*8));
      r_jesdGtRxArr(i).dataK   <= s_rxctrl0(i*16+GT_WORD_SIZE_C-1 downto i*16);
      r_jesdGtRxArr(i).dispErr <= s_rxctrl1(i*16+GT_WORD_SIZE_C-1 downto i*16);
      r_jesdGtRxArr(i).decErr  <= s_rxctrl3(i*8+GT_WORD_SIZE_C-1 downto i*8);
      r_jesdGtRxArr(i).rstDone <= s_rxDone;
      s_devClkVec(I)           <= devClk_i;
      s_devClk2Vec(I)          <= devClk2_i;
      s_stableClkVec(I)        <= stableClk;
      s_gtRefClkVec(I)         <= refClk;

      -- Disable comma alignment when data valid
      s_allignEnVec(i) <= not s_dataValidVec(i);
      
   end generate RX_LANES_GEN;

   --------------------------------------------------------------------------
   --    Include Core from Coregen Vivado 15.1 
   --    Coregen settings:
   --    - Lane rate 7.4 GHz
   --    - Reference freq 184 MHz
   --    - 8b10b enabled
   --    - 32b/40b word datapath
   --    - Comma detection has to be enabled to any byte boundary - IMPORTANT
   -------------------------------------------------------------------------
   U_Coregen : AmcGenericAdcDacJesd204bCoregen
      port map (
         -- Clocks
         gtwiz_userclk_tx_active_in(0)         => devClkActive_i,
         gtwiz_userclk_rx_active_in(0)         => devClkActive_i,
         gtwiz_buffbypass_tx_reset_in(0)       => s_gtTxReset,
         gtwiz_buffbypass_tx_start_user_in(0)  => s_gtTxReset,
         gtwiz_buffbypass_tx_done_out          => open,
         gtwiz_buffbypass_tx_error_out         => open,
         gtwiz_reset_clk_freerun_in(0)         => stableClk,
         gtwiz_reset_all_in(0)                 => '0',
         gtwiz_reset_tx_pll_and_datapath_in(0) => s_gtTxReset,
         gtwiz_reset_tx_datapath_in(0)         => s_gtTxReset,
         gtwiz_reset_rx_pll_and_datapath_in(0) => s_gtRxReset,
         gtwiz_reset_rx_datapath_in(0)         => s_gtRxReset,
         gtwiz_reset_rx_cdr_stable_out         => open,
         gtwiz_reset_tx_done_out(0)            => s_txDone,
         gtwiz_reset_rx_done_out(0)            => s_rxDone,
         gtwiz_userdata_tx_in                  => s_txData,
         gtwiz_userdata_rx_out                 => s_rxData,
         drpclk_in                             => s_stableClkVec,
         gthrxn_in                             => gtRxN,
         gthrxp_in                             => gtRxP,
         gtrefclk0_in                          => s_gtRefClkVec,
         rx8b10ben_in                          => "1111",
         rxcommadeten_in                       => "1111",
         rxmcommaalignen_in                    => s_allignEnVec,
         rxpcommaalignen_in                    => s_allignEnVec,
         rxpolarity_in                         => "0000",
         rxusrclk_in                           => s_devClkVec,
         rxusrclk2_in                          => s_devClk2Vec,
         tx8b10ben_in                          => "1111",
         txctrl0_in                            => X"0000_0000_0000_0000",
         txctrl1_in                            => X"0000_0000_0000_0000",
         txctrl2_in                            => s_txDataK,
         txpd_in                               => "00000000",
         txpolarity_in                         => "0000",
         txusrclk_in                           => s_devClkVec,
         txusrclk2_in                          => s_devClk2Vec,
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

end mapping;
