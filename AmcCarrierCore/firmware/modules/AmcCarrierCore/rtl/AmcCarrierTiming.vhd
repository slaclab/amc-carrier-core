-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierTiming.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-09-11
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;

entity AmcCarrierTiming is
   generic (
      TPD_G               : time                := 1 ns;
      AXI_ERROR_RESP_G    : slv(1 downto 0)     := AXI_RESP_DECERR_C;
      STANDALONE_TIMING_G : boolean             := false;  -- true = LCLS-I timing only
      DIAGNOSTIC_SIZE_G   : positive            := 1;
      DIAGNOSTIC_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(4));
   port (
      -- AXI-Lite Interface
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- AXI4 Interface
      axiClk            : in  sl;
      axiRst            : in  sl;
      axiWriteMaster    : out AxiWriteMasterType;
      axiWriteSlave     : in  AxiWriteSlaveType;
      axiReadMaster     : out AxiReadMasterType;
      axiReadSlave      : in  AxiReadSlaveType;
      -- BSA Ethernet Client Interface (axilClk domain)
      obBsaMaster       : in  AxiStreamMasterType;
      obBsaSlave        : out AxiStreamSlaveType;
      ibBsaMaster       : out AxiStreamMasterType;
      ibBsaSlave        : in  AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Timing Interface 
      refTimingClk      : out sl;
      refTimingRst      : out sl;
      timingClk         : in  sl;
      timingRst         : in  sl;
      timingData        : out TimingDataType;
      -- Diagnostic Interface
      diagnosticClk     : in  sl;
      diagnosticRst     : in  sl;
      diagnosticMessage : in  Slv32Array(31 downto 0);
      diagnosticMasters : in  AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves  : out AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      ----------------
      -- Core Ports --
      ----------------   
      -- LCLS Timing Ports
      timingRxP         : in  sl;
      timingRxN         : in  sl;
      timingTxP         : out sl;
      timingTxN         : out sl;
      timingClkInP      : in  sl;
      timingClkInN      : in  sl;
      timingClkOutP     : out sl;
      timingClkOutN     : out sl;
      timingClkSel      : out sl);    
end AmcCarrierTiming;

architecture mapping of AmcCarrierTiming is

   component GthUltraScaleDummy
      port (
         s_axi_tx_tdata     : in  std_logic_vector(0 to 15);
         s_axi_tx_tvalid    : in  std_logic;
         s_axi_tx_tready    : out std_logic;
         m_axi_rx_tdata     : out std_logic_vector(0 to 15);
         m_axi_rx_tvalid    : out std_logic;
         hard_err           : out std_logic;
         soft_err           : out std_logic;
         channel_up         : out std_logic;
         lane_up            : out std_logic_vector(0 downto 0);
         txp                : out std_logic_vector(0 downto 0);
         txn                : out std_logic_vector(0 downto 0);
         reset              : in  std_logic;
         gt_reset           : in  std_logic;
         loopback           : in  std_logic_vector(2 downto 0);
         rxp                : in  std_logic_vector(0 downto 0);
         rxn                : in  std_logic_vector(0 downto 0);
         gt0_drpaddr        : in  std_logic_vector(8 downto 0);
         gt0_drpen          : in  std_logic;
         gt0_drpdi          : in  std_logic_vector(15 downto 0);
         gt0_drprdy         : out std_logic;
         gt0_drpdo          : out std_logic_vector(15 downto 0);
         gt0_drpwe          : in  std_logic;
         power_down         : in  std_logic;
         tx_lock            : out std_logic;
         tx_resetdone_out   : out std_logic;
         rx_resetdone_out   : out std_logic;
         link_reset_out     : out std_logic;
         init_clk_in        : in  std_logic;
         user_clk_out       : out std_logic;
         pll_not_locked_out : out std_logic;
         sys_reset_out      : out std_logic;
         gt_refclk1_p       : in  std_logic;
         gt_refclk1_n       : in  std_logic;
         sync_clk_out       : out std_logic;
         gt_reset_out       : out std_logic;
         gt_refclk1_out     : out std_logic);
   end component;

   signal timingRecClk : sl;
   
begin

   refTimingClk <= timingRecClk;
   refTimingRst <= '0';

   -- Drive the external CLK MUX to standalone or dual timing mode
   timingClkSel <= ite(STANDALONE_TIMING_G, '1', '0');

   -- Send a copy of the timing clock to the AMC's clock cleaner
   ClkOutBufDiff_Inst : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => timingRecClk,
         clkOutP => timingClkOutP,
         clkOutN => timingClkOutN);  

   --------------------------------------
   -- Place holder for future development
   --------------------------------------
   timingRecClk     <= '0';
   timingData       <= TIMING_DATA_INIT_C;
   diagnosticSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);
   axiWriteMaster   <= AXI_WRITE_MASTER_INIT_C;
   axiReadMaster    <= AXI_READ_MASTER_INIT_C;
   obBsaSlave       <= AXI_STREAM_SLAVE_FORCE_C;
   ibBsaMaster      <= AXI_STREAM_MASTER_INIT_C;

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);       

   U_GthUltraScaleDummy : GthUltraScaleDummy
      port map (
         s_axi_tx_tdata     => (others => '0'),
         s_axi_tx_tvalid    => '0',
         s_axi_tx_tready    => open,
         m_axi_rx_tdata     => open,
         m_axi_rx_tvalid    => open,
         hard_err           => open,
         soft_err           => open,
         channel_up         => open,
         lane_up            => open,
         txp(0)             => timingTxP,
         txn(0)             => timingTxN,
         reset              => '1',
         gt_reset           => '1',
         loopback           => (others => '0'),
         rxp(0)             => timingRxP,
         rxn(0)             => timingRxN,
         gt0_drpaddr        => (others => '0'),
         gt0_drpen          => '0',
         gt0_drpdi          => (others => '0'),
         gt0_drprdy         => open,
         gt0_drpdo          => open,
         gt0_drpwe          => '0',
         power_down         => '1',
         tx_lock            => open,
         tx_resetdone_out   => open,
         rx_resetdone_out   => open,
         link_reset_out     => open,
         init_clk_in        => '0',
         user_clk_out       => open,
         pll_not_locked_out => open,
         sys_reset_out      => open,
         gt_refclk1_p       => timingClkInP,
         gt_refclk1_n       => timingClkInN,
         sync_clk_out       => open,
         gt_reset_out       => open,
         gt_refclk1_out     => open);         

end mapping;
