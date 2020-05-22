-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 MPS Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 MPS Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2bPkg.all;

entity MpsPgpFrontEndGth is
   generic (
      TPD_G             : time                 := 1 ns;
      PGP_RX_ENABLE_G   : boolean              := true;
      PGP_TX_ENABLE_G   : boolean              := true;
      PAYLOAD_CNT_TOP_G : integer              := 7;  -- Top bit for payload counter
      VC_INTERLEAVE_G   : integer              := 1;  -- Interleave Frames
      NUM_VC_EN_G       : integer range 1 to 4 := 4);
   port (
      -- System Signals
      pgpClk         : in  sl;
      pgpRst         : in  sl;
      stableClk      : in  sl;
      gtRefClk       : in  sl;
      -- GT Tuning Interface
      gtTxPreCursor  : in  slv(4 downto 0) := "00111";  -- 1.67 dB
      gtTxPostCursor : in  slv(4 downto 0) := "01111";  -- 4.08 dB
      gtTxDiffCtrl   : in  slv(3 downto 0) := "1111";   -- 1080 mV
      gtTxPolarity   : in  sl              := '0';
      gtRxPolarity   : in  sl              := '0';
      -- GT Ports
      gtTxP          : out sl;
      gtTxN          : out sl;
      gtRxP          : in  sl;
      gtRxN          : in  sl;
      -- Non VC Rx Signals
      pgpRxIn        : in  Pgp2bRxInType;
      pgpRxOut       : out Pgp2bRxOutType;
      -- Non VC Tx Signals
      pgpTxIn        : in  Pgp2bTxInType;
      pgpTxOut       : out Pgp2bTxOutType;
      -- Frame Transmit Interface - 1 Lane, Array of 4 VCs
      pgpTxMasters   : in  AxiStreamMasterArray(3 downto 0);
      pgpTxSlaves    : out AxiStreamSlaveArray(3 downto 0);
      -- Frame Receive Interface - 1 Lane, Array of 4 VCs
      pgpRxMasters   : out AxiStreamMasterArray(3 downto 0);
      pgpRxCtrl      : in  AxiStreamCtrlArray(3 downto 0));
end MpsPgpFrontEndGth;

architecture mapping of MpsPgpFrontEndGth is

   component MpsPgpGthCore
      port (
         gtwiz_userclk_tx_active_in         : in  std_logic_vector(0 downto 0);
         gtwiz_userclk_rx_active_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_clk_freerun_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_all_in                 : in  std_logic_vector(0 downto 0);
         gtwiz_reset_tx_pll_and_datapath_in : in  std_logic_vector(0 downto 0);
         gtwiz_reset_tx_datapath_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_rx_pll_and_datapath_in : in  std_logic_vector(0 downto 0);
         gtwiz_reset_rx_datapath_in         : in  std_logic_vector(0 downto 0);
         gtwiz_reset_rx_cdr_stable_out      : out std_logic_vector(0 downto 0);
         gtwiz_reset_tx_done_out            : out std_logic_vector(0 downto 0);
         gtwiz_reset_rx_done_out            : out std_logic_vector(0 downto 0);
         gtwiz_userdata_tx_in               : in  std_logic_vector(15 downto 0);
         gtwiz_userdata_rx_out              : out std_logic_vector(15 downto 0);
         drpclk_in                          : in  std_logic_vector(0 downto 0);
         gthrxn_in                          : in  std_logic_vector(0 downto 0);
         gthrxp_in                          : in  std_logic_vector(0 downto 0);
         gtrefclk0_in                       : in  std_logic_vector(0 downto 0);
         loopback_in                        : in  std_logic_vector(2 downto 0);
         rx8b10ben_in                       : in  std_logic_vector(0 downto 0);
         rxbufreset_in                      : in  std_logic_vector(0 downto 0);
         rxcommadeten_in                    : in  std_logic_vector(0 downto 0);
         rxmcommaalignen_in                 : in  std_logic_vector(0 downto 0);
         rxpcommaalignen_in                 : in  std_logic_vector(0 downto 0);
         rxpolarity_in                      : in  std_logic_vector(0 downto 0);
         rxusrclk_in                        : in  std_logic_vector(0 downto 0);
         rxusrclk2_in                       : in  std_logic_vector(0 downto 0);
         tx8b10ben_in                       : in  std_logic_vector(0 downto 0);
         txctrl0_in                         : in  std_logic_vector(15 downto 0);
         txctrl1_in                         : in  std_logic_vector(15 downto 0);
         txctrl2_in                         : in  std_logic_vector(7 downto 0);
         txdiffctrl_in                      : in  std_logic_vector(3 downto 0);
         txpolarity_in                      : in  std_logic_vector(0 downto 0);
         txpostcursor_in                    : in  std_logic_vector(4 downto 0);
         txprecursor_in                     : in  std_logic_vector(4 downto 0);
         txusrclk_in                        : in  std_logic_vector(0 downto 0);
         txusrclk2_in                       : in  std_logic_vector(0 downto 0);
         gthtxn_out                         : out std_logic_vector(0 downto 0);
         gthtxp_out                         : out std_logic_vector(0 downto 0);
         rxbufstatus_out                    : out std_logic_vector(2 downto 0);
         rxbyteisaligned_out                : out std_logic_vector(0 downto 0);
         rxbyterealign_out                  : out std_logic_vector(0 downto 0);
         rxclkcorcnt_out                    : out std_logic_vector(1 downto 0);
         rxcommadet_out                     : out std_logic_vector(0 downto 0);
         rxctrl0_out                        : out std_logic_vector(15 downto 0);
         rxctrl1_out                        : out std_logic_vector(15 downto 0);
         rxctrl2_out                        : out std_logic_vector(7 downto 0);
         rxctrl3_out                        : out std_logic_vector(7 downto 0);
         rxoutclk_out                       : out std_logic_vector(0 downto 0);
         rxpmaresetdone_out                 : out std_logic_vector(0 downto 0);
         txoutclk_out                       : out std_logic_vector(0 downto 0);
         txpmaresetdone_out                 : out std_logic_vector(0 downto 0)
         );
   end component;

   signal gtRxUserReset : sl;
   signal phyRxLaneIn   : Pgp2bRxPhyLaneInType;
   signal phyRxLaneOut  : Pgp2bRxPhyLaneOutType;
   signal phyRxReady    : sl;
   signal phyRxInit     : sl;

   signal gtTxUserReset : sl;
   signal phyTxLaneOut  : Pgp2bTxPhyLaneOutType;
   signal phyTxReady    : sl;

begin

   gtRxUserReset <= phyRxInit or pgpRst or pgpRxIn.resetRx;
   gtTxUserReset <= pgpRst;

   U_Pgp2bLane : entity surf.Pgp2bLane
      generic map (
         LANE_CNT_G        => 1,
         VC_INTERLEAVE_G   => VC_INTERLEAVE_G,
         PAYLOAD_CNT_TOP_G => PAYLOAD_CNT_TOP_G,
         NUM_VC_EN_G       => NUM_VC_EN_G,
         TX_ENABLE_G       => PGP_TX_ENABLE_G,
         RX_ENABLE_G       => PGP_RX_ENABLE_G)
      port map (
         pgpTxClk         => pgpClk,
         pgpTxClkRst      => pgpRst,
         pgpTxIn          => pgpTxIn,
         pgpTxOut         => pgpTxOut,
         pgpTxMasters     => pgpTxMasters,
         pgpTxSlaves      => pgpTxSlaves,
         phyTxLanesOut(0) => phyTxLaneOut,
         phyTxReady       => phyTxReady,
         pgpRxClk         => pgpClk,
         pgpRxClkRst      => pgpRst,
         pgpRxIn          => pgpRxIn,
         pgpRxOut         => pgpRxOut,
         pgpRxMasters     => pgpRxMasters,
         pgpRxCtrl        => pgpRxCtrl,
         phyRxLanesOut(0) => phyRxLaneOut,
         phyRxLanesIn(0)  => phyRxLaneIn,
         phyRxReady       => phyRxReady,
         phyRxInit        => phyRxInit);

   U_MpsPgpGthCore : MpsPgpGthCore
      port map (
         gtwiz_userclk_tx_active_in(0)         => '1',
         gtwiz_userclk_rx_active_in(0)         => '1',
         gtwiz_reset_clk_freerun_in (0)        => stableClk,
         gtwiz_reset_all_in(0)                 => '0',
         gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
         gtwiz_reset_tx_datapath_in(0)         => gtTxUserReset,
         gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
         gtwiz_reset_rx_datapath_in(0)         => gtRxUserReset,
         gtwiz_reset_rx_cdr_stable_out(0)      => open,
         gtwiz_reset_tx_done_out(0)            => phyTxReady,
         gtwiz_reset_rx_done_out(0)            => phyRxReady,
         gtwiz_userdata_tx_in                  => phyTxLaneOut.data,
         gtwiz_userdata_rx_out                 => phyRxLaneIn.data,
         drpclk_in(0)                          => stableClk,
         gthrxn_in(0)                          => gtRxN,
         gthrxp_in(0)                          => gtRxP,
         gtrefclk0_in(0)                       => gtRefClk,
         loopback_in                           => pgpRxIn.loopback,
         rx8b10ben_in(0)                       => '1',
         rxbufreset_in(0)                      => '0',
         rxcommadeten_in(0)                    => '1',
         rxmcommaalignen_in(0)                 => '1',
         rxpcommaalignen_in(0)                 => '1',
         rxpolarity_in(0)                      => gtRxPolarity,
         rxusrclk_in(0)                        => pgpClk,
         rxusrclk2_in(0)                       => pgpClk,
         tx8b10ben_in(0)                       => '1',
         txctrl0_in                            => X"0000",
         txctrl1_in                            => X"0000",
         txctrl2_in(1 downto 0)                => phyTxLaneOut.dataK,
         txctrl2_in(7 downto 2)                => (others => '0'),
         txdiffctrl_in                         => gtTxDiffCtrl,
         txpolarity_in(0)                      => gtTxPolarity,
         txpostcursor_in                       => gtTxPostCursor,
         txprecursor_in                        => gtTxPreCursor,
         txusrclk_in(0)                        => pgpClk,
         txusrclk2_in(0)                       => pgpClk,
         gthtxn_out(0)                         => gtTxN,
         gthtxp_out(0)                         => gtTxP,
         rxbufstatus_out                       => open,
         rxbyteisaligned_out                   => open,
         rxbyterealign_out                     => open,
         rxclkcorcnt_out                       => open,
         rxcommadet_out                        => open,
         rxctrl0_out(1 downto 0)               => phyRxLaneIn.dataK,
         rxctrl0_out(15 downto 2)              => open,
         rxctrl1_out(1 downto 0)               => phyRxLaneIn.dispErr,
         rxctrl1_out(15 downto 2)              => open,
         rxctrl2_out                           => open,
         rxctrl3_out(1 downto 0)               => phyRxLaneIn.decErr,
         rxctrl3_out(7 downto 2)               => open,
         rxoutclk_out(0)                       => open,
         rxpmaresetdone_out(0)                 => open,
         txoutclk_out(0)                       => open,
         txpmaresetdone_out(0)                 => open);

end mapping;
