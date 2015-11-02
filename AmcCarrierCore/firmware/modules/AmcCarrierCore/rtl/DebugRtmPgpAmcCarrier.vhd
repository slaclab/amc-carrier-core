-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : DebugRtmPgpAmcCarrier.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-30
-- Last update: 2015-11-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.Pgp2bPkg.all;
use work.AmcCarrierPkg.all;

library unisim;
use unisim.vcomponents.all;

entity DebugRtmPgpAmcCarrier is
   generic (
      TPD_G             : time            := 1 ns;
      SIM_SPEEDUP_G     : boolean         := false;
      SIMULATION_G      : boolean         := false;
      FFB_CLIENT_SIZE_G : positive        := 1;
      DIAGNOSTIC_SIZE_G : positive        := 1;
      AXI_ERROR_RESP_G  : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Master AXI-Lite Interface
      mAxilReadMasters  : out AxiLiteReadMasterArray(3 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(3 downto 0);
      mAxilWriteMasters : out AxiLiteWriteMasterArray(3 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(3 downto 0);
      -- AXI-Lite Interface
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- FFB Outbound Interface
      ffbObMaster       : in  AxiStreamMasterType;
      ffbObSlave        : out AxiStreamSlaveType;
      -- Debug AXI stream Interface
      pgpClock          : out sl;
      pgpReset          : out sl;
      axisTxMasters     : in  AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      axisTxSlaves      : out AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      ----------------------
      -- Top Level Interface
      ----------------------
      -- FFB Inbound Interface (ffbClk domain)
      ffbClk            : in  sl;
      ffbRst            : in  sl;
      ffbBus            : out FfbBusType;
      ----------------
      -- Core Ports --
      ----------------   
      -- RTM PGP Ports
      rtmPgpRxP         : in  sl;
      rtmPgpRxN         : in  sl;
      rtmPgpTxP         : out sl;
      rtmPgpTxN         : out sl;
      rtmPgpClkP        : in  sl;
      rtmPgpClkN        : in  sl);
end DebugRtmPgpAmcCarrier;

architecture mapping of DebugRtmPgpAmcCarrier is

   signal pgpTxIn       : Pgp2bTxInType;
   signal pgpTxOut      : Pgp2bTxOutType;
   signal pgpRxIn       : Pgp2bRxInType;
   signal pgpRxOut      : Pgp2bRxOutType;
   signal pgpTxMasters  : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlaves   : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpRxMasters  : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxCtrl     : AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);
   signal pgpRefClkDiv2 : sl;
   signal pgpRefClk     : sl;
   signal pgpClk        : sl;
   signal pgpRst        : sl;

begin

   pgpClock <= pgpClk;
   pgpReset <= pgpRst;

   ffbBus     <= FFB_BUS_INIT_C;
   ffbObSlave <= AXI_STREAM_SLAVE_FORCE_C;

   mAxilReadMasters(3 downto 1)  <= (others => AXI_LITE_READ_MASTER_INIT_C);
   mAxilWriteMasters(3 downto 1) <= (others => AXI_LITE_WRITE_MASTER_INIT_C);

   U_IBUFDS_GTE3 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")      
      port map (
         I     => rtmPgpClkP,
         IB    => rtmPgpClkN,
         CEB   => '0',
         ODIV2 => pgpRefClkDiv2,        -- Divide by 1
         O     => pgpRefClk);

   U_BUFG_GT : BUFG_GT
      port map (
         I       => pgpRefClkDiv2,
         CE      => '1',
         CLR     => '0',
         CEMASK  => '1',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => pgpClk);

   U_PwrUpRst : entity work.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => pgpClk,
         rstOut => pgpRst);

   
   REAL_PGP : if (not SIMULATION_G) generate
      
      Pgp2bGthUltra_1 : entity work.DebugRtmPgp2bGthUltra
         generic map (
            TPD_G             => TPD_G,
            PAYLOAD_CNT_TOP_G => 7,
            VC_INTERLEAVE_G   => 0,
            NUM_VC_EN_G       => DIAGNOSTIC_SIZE_G+1)
         port map (
            stableClk        => axilClk,
            gtRefClk         => pgpRefClk,
            pgpGtTxP         => rtmPgpTxP,
            pgpGtTxN         => rtmPgpTxN,
            pgpGtRxP         => rtmPgpRxP,
            pgpGtRxN         => rtmPgpRxN,
            pgpTxReset       => pgpRst,
            pgpTxRecClk      => open,
            pgpTxClk         => pgpClk,
            pgpTxMmcmLocked  => '1',
            pgpRxReset       => pgpRst,
            pgpRxRecClk      => open,
            pgpRxClk         => pgpClk,
            pgpRxMmcmLocked  => '1',
            pgpRxIn          => pgpRxIn,
            pgpRxOut         => pgpRxOut,
            pgpTxIn          => pgpTxIn,
            pgpTxOut         => pgpTxOut,
            pgpTxMasters     => pgpTxMasters,
            pgpTxSlaves      => pgpTxSlaves,
            pgpRxMasters     => pgpRxMasters,
            pgpRxMasterMuxed => open,
            pgpRxCtrl        => pgpRxCtrl);

   end generate REAL_PGP;

   SIM_PGP : if (SIMULATION_G) generate
      PgpSimModel_1 : entity work.PgpSimModel
         generic map (
            TPD_G      => TPD_G,
            LANE_CNT_G => 2)
         port map (
            pgpTxClk         => pgpClk,
            pgpTxClkRst      => pgpRst,
            pgpTxIn          => pgpTxIn,
            pgpTxOut         => pgpTxOut,
            pgpTxMasters     => pgpTxMasters,
            pgpTxSlaves      => pgpTxSlaves,
            pgpRxClk         => pgpClk,
            pgpRxClkRst      => pgpRst,
            pgpRxIn          => pgpRxIn,
            pgpRxOut         => pgpRxOut,
            pgpRxMasters     => pgpRxMasters,
            pgpRxMasterMuxed => open,
            pgpRxCtrl        => pgpRxCtrl);
   end generate SIM_PGP;

   SsiAxiLiteMaster_1 : entity work.SsiAxiLiteMaster
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         EN_32BIT_ADDR_G     => true,
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 2**8,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk            => pgpClk,
         sAxisRst            => pgpRst,
         sAxisMaster         => pgpRxMasters(0),
         sAxisSlave          => open,
         sAxisCtrl           => pgpRxCtrl(0),
         mAxisClk            => pgpClk,
         mAxisRst            => pgpRst,
         mAxisMaster         => pgpTxMasters(0),
         mAxisSlave          => pgpTxSlaves(0),
         axiLiteClk          => axilClk,
         axiLiteRst          => axilRst,
         mAxiLiteWriteMaster => mAxilWriteMasters(0),
         mAxiLiteWriteSlave  => mAxilWriteSlaves(0),
         mAxiLiteReadMaster  => mAxilReadMasters(0),
         mAxiLiteReadSlave   => mAxilReadSlaves(0));

   ADC_AXI_STREAMS : for i in DIAGNOSTIC_SIZE_G-1 downto 0 generate
      pgpTxMasters(i+1) <= axisTxMasters(i);
      axisTxSlaves(i)   <= pgpTxSlaves(i+1);
   end generate ADC_AXI_STREAMS;

   Pgp2bAxi_1 : entity work.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => false,
         AXI_CLK_FREQ_G     => 156.25E+6,
         STATUS_CNT_WIDTH_G => 32,
         ERROR_CNT_WIDTH_G  => 16)
      port map (
         pgpTxClk        => pgpClk,
         pgpTxClkRst     => pgpRst,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         pgpRxClk        => pgpClk,
         pgpRxClkRst     => pgpRst,
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);         

end mapping;
