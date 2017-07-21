-------------------------------------------------------------------------------
-- File       : DacSigGen.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2017-07-20
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.jesd204bpkg.all;
use work.AppTopPkg.all;

entity DacSigGen is
   generic (
      TPD_G                : time                            := 1 ns;
      AXI_BASE_ADDR_G      : slv(31 downto 0)                := (others => '0');
      AXI_ERROR_RESP_G     : slv(1 downto 0)                 := AXI_RESP_DECERR_C;
      SIG_GEN_SIZE_G       : natural range 0 to 10           := 0;  -- 0 = Disabled
      SIG_GEN_ADDR_WIDTH_G : positive range 1 to 24          := 9;
      SIG_GEN_LANE_MODE_G  : slv(DAC_SIG_WIDTH_C-1 downto 0) := (others => '0');  -- '0': 32 bit, '1': 16 bit
      SIG_GEN_RAM_CLK_G    : slv(DAC_SIG_WIDTH_C-1 downto 0) := (others => '0'));  -- '0': jesdClk2x, '1': jesdClk
   port (
      -- DAC Signal Generator Interface
      jesdClk         : in  sl;
      jesdRst         : in  sl;
      jesdClk2x       : in  sl;
      jesdRst2x       : in  sl;
      dacSigCtrl      : in  DacSigCtrlType;
      dacSigStatus    : out DacSigStatusType;
      dacSigValids    : out slv(DAC_SIG_WIDTH_C-1 downto 0);
      dacSigValues    : out sampleDataArray(DAC_SIG_WIDTH_C-1 downto 0);
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end DacSigGen;

architecture mapping of DacSigGen is

   constant NUM_AXI_MASTERS_C : natural := SIG_GEN_SIZE_G+1;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 28, 24);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   -- Internal signals
   signal s_enable    : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_mode      : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_sign      : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_trigSw    : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_holdLast  : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_trig      : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_overflow  : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_underflow : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_running   : slv(DAC_SIG_WIDTH_C-1 downto 0);
   signal s_period    : slv32Array(DAC_SIG_WIDTH_C-1 downto 0);

begin

   GEN_EMPTY : if SIG_GEN_SIZE_G = 0 generate
      dacSigStatus <= DAC_SIG_STATUS_INIT_C;
      dacSigValids <= (others => '0');
      dacSigValues <= (others => x"0000_0000");

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G => TPD_G)
         port map (
            -- AXI-Lite Bus
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave);
   end generate GEN_EMPTY;

   GEN_SIGGEN : if SIG_GEN_SIZE_G /= 0 generate
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

      -- DAQ control register interface
      U_DacSigGenReg : entity work.DacSigGenReg
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            ADDR_WIDTH_G     => SIG_GEN_ADDR_WIDTH_G,
            NUM_SIG_GEN_G    => SIG_GEN_SIZE_G)
         port map (
            axiClk_i        => axilClk,
            axiRst_i        => axilRst,
            devClk_i        => jesdClk2x,
            devRst_i        => jesdRst2x,
            axilReadMaster  => axilReadMasters(0),
            axilReadSlave   => axilReadSlaves(0),
            axilWriteMaster => axilWriteMasters(0),
            axilWriteSlave  => axilWriteSlaves(0),
            enable_o        => s_enable(SIG_GEN_SIZE_G-1 downto 0),
            mode_o          => s_mode(SIG_GEN_SIZE_G-1 downto 0),
            sign_o          => s_sign(SIG_GEN_SIZE_G-1 downto 0),
            trigSw_o        => s_trigSw(SIG_GEN_SIZE_G-1 downto 0),
            holdLast_o      => s_holdLast(SIG_GEN_SIZE_G-1 downto 0),
            period_o        => s_period(SIG_GEN_SIZE_G-1 downto 0),
            running_i       => s_running(SIG_GEN_SIZE_G-1 downto 0),
            overflow_i      => s_overflow(SIG_GEN_SIZE_G-1 downto 0),
            underflow_i     => s_underflow(SIG_GEN_SIZE_G-1 downto 0));

      -----------------------------------------------------------
      -- Signal generator lanes
      ----------------------------------------------------------- 
      GEN_CHS : for i in SIG_GEN_SIZE_G-1 downto 0 generate
         -- Triggers
         s_trig(i) <= dacSigCtrl.start(i) or s_trigSw(i);

         U_DacSigGenLane : entity work.DacSigGenLane
            generic map (
               TPD_G        => TPD_G,
               ADDR_WIDTH_G => SIG_GEN_ADDR_WIDTH_G,
               INTERFACE_G  => SIG_GEN_LANE_MODE_G(i),
               RAM_CLK_G    => SIG_GEN_RAM_CLK_G(i))
            port map (
               jesdClk         => jesdClk,
               jesdRst         => jesdRst,
               jesdClk2x       => jesdClk2x,
               jesdRst2x       => jesdRst2x,
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => axilReadMasters(1+i),
               axilReadSlave   => axilReadSlaves(1+i),
               axilWriteMaster => axilWriteMasters(1+i),
               axilWriteSlave  => axilWriteSlaves(1+i),
               enable_i        => s_enable(i),
               mode_i          => s_mode(i),
               sign_i          => s_sign(i),
               period_i        => s_period(i)(SIG_GEN_ADDR_WIDTH_G-1 downto 0),
               holdLast_i      => s_holdLast(i),
               start_i         => s_trig(i),
               overflow_o      => s_overflow(i),
               underflow_o     => s_underflow(i),
               running_o       => s_running(i),
               valid_o         => dacSigValids(i),
               dacSigValues_o  => dacSigValues(i));
      end generate GEN_CHS;

      -- Assign out
      dacSigStatus.running <= s_running;
   ------
   end generate GEN_SIGGEN;
-----------------------------------
end mapping;
