-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for DaqMuxV2
------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Common Carrier Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 Common Carrier Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library amc_carrier_core;

entity DaqMuxV2Tb is
end entity;

architecture testbed of DaqMuxV2Tb is

   constant CLK_PERIOD_C : time     := 10 ns;
   constant TPD_G        : time     := 1 ns;
   constant N_DATA_IN_G  : positive := 2;
   constant N_DATA_OUT_G : positive := 2;

   signal clk_i           : sl := '0';
   signal rst_i           : sl := '0';
   signal dec16or32_i     : sl := '1';
   signal s_cnt           : slv(31 downto 0);
   signal sampleDataArr_i : slv32Array(N_DATA_IN_G-1 downto 0);

   signal trigHw_i   : sl := '0';
   signal freezeHw_i : sl := '0';
   signal trigCasc_i : sl := '0';
   signal trigCasc_o : sl := '0';

   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;
   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;

   signal rxAxisMasterArr_o : AxiStreamMasterArray(N_DATA_OUT_G-1 downto 0);
   signal rxAxisSlaveArr_i  : AxiStreamSlaveArray(N_DATA_OUT_G-1 downto 0) := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal rxAxisCtrlArr_i   : AxiStreamCtrlArray(N_DATA_OUT_G-1 downto 0)  := (others => AXI_STREAM_CTRL_UNUSED_C);

begin

   U_ClkRst : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 1 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk_i,
         rst  => rst_i);

   ----------------------
   -- Module to be tested
   ----------------------
   U_DaqMuxV2 : entity amc_carrier_core.DaqMuxV2
      generic map (
         TPD_G                  => TPD_G,
         N_DATA_IN_G            => N_DATA_IN_G,
         N_DATA_OUT_G           => N_DATA_OUT_G,
         DECIMATOR_EN_G         => true,
         WAVEFORM_TDATA_BYTES_G => 8,
         FRAME_BWIDTH_G         => 4)
      port map (
         axiClk            => clk_i,
         axiRst            => rst_i,
         devClk_i          => clk_i,
         devRst_i          => rst_i,
         wfClk_i           => clk_i,
         wfRst_i           => rst_i,
         trigHw_i          => trigHw_i,
         freezeHw_i        => freezeHw_i,
         trigCasc_i        => trigCasc_i,
         trigCasc_o        => trigCasc_o,
         timeStamp_i       => x"DEADBEEF_BA5EBA11",
         bsa_i             => x"B0B0B0B0_B1B1B1B1_B2B2B2B2_B3B3B3B3",
         axilReadMaster    => axilReadMaster,
         axilReadSlave     => axilReadSlave,
         axilWriteMaster   => axilWriteMaster,
         axilWriteSlave    => axilWriteSlave,
         sampleDataArr_i   => sampleDataArr_i,
         sampleValidVec_i  => (others => '1'),
         linkReadyVec_i    => (others => '1'),
         rxAxisMasterArr_o => rxAxisMasterArr_o,
         rxAxisSlaveArr_i  => rxAxisSlaveArr_i,
         rxAxisCtrlArr_i   => rxAxisCtrlArr_i);

   seq : process (clk_i) is
   begin
      if (rising_edge(clk_i)) then
         if (rst_i = '1') then
            s_cnt <= (others => '0');
         elsif dec16or32_i = '0' then
            s_cnt <= s_cnt + 1 after TPD_G;
         else
            s_cnt <= s_cnt + 2 after TPD_G;
         end if;
      end if;
   end process seq;

   genInLanes : for I in N_DATA_IN_G-1 downto 0 generate
      sampleDataArr_i(I) <= s_cnt(15 downto 0)+1 & s_cnt(15 downto 0) when dec16or32_i = '1' else s_cnt;
   end generate genInLanes;

   StimuliProcess : process
   begin
      wait for CLK_PERIOD_C;
      wait until rst_i = '0';

      wait for CLK_PERIOD_C*100;

      rxAxisSlaveArr_i(0) <= AXI_STREAM_SLAVE_INIT_C;

      ---------------------------------------------------------
      -- TriggerSw          = 0x0            (BIT0)
      -- TriggerCascMask    = Enabled        (BIT1)
      -- TriggerHwAutoRearm = Enabled        (BIT2)
      -- TriggerHwArm       = 0x0            (BIT3)
      -- TriggerClearStatus = 0x0            (BIT4)
      -- DaqMode            = TriggeredMode  (BIT5)
      -- PacketHeaderEn     = Disabled       (BIT6)
      -- FreezeSw           = 0x0            (BIT7)
      -- FreezeHwMask       = Enabled        (BIT8)
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_0000", x"0000_0106");

      ---------------------------------------------------------
      -- DataBufferSize = 0x200
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_000C", x"0000_0200");

      ---------------------------------------------------------
      -- LANE[0] = Test
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_0040", x"0000_0001");

      ---------------------------------------------------------
      -- LANE[1] = CH0
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_0044", x"0000_0002");

      ---------------------------------------------------------
      -- LANE[0].FormatSignWidth       = 0x0       (BIT4:BIT0)
      -- LANE[0].FormatDataWidth       = D16-bit   (BIT5)
      -- LANE[0].FormatSign            = Unsigned  (BIT6)
      -- LANE[0].DecimationAveraging   = Disabled  (BIT7)
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_00C0", x"0000_0020");

      ---------------------------------------------------------
      -- LANE[1].FormatSignWidth       = 0xC       (BIT4:BIT0)
      -- LANE[1].FormatDataWidth       = D16-bit   (BIT5)
      -- LANE[1].FormatSign            = Signed    (BIT6)
      -- LANE[1].DecimationAveraging   = Enabled   (BIT7)
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_00C4", x"0000_00ec");

      wait for CLK_PERIOD_C*200;
      trigHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';

      wait for CLK_PERIOD_C*500;
      rxAxisSlaveArr_i(0) <= AXI_STREAM_SLAVE_FORCE_C;

      wait for CLK_PERIOD_C*500;
      trigHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';

      wait for CLK_PERIOD_C*100;
      freezeHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      freezeHw_i <= '0';

      wait for CLK_PERIOD_C*1000;
      trigHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';

      wait for CLK_PERIOD_C*100;
      freezeHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      freezeHw_i <= '0';


      wait for CLK_PERIOD_C*100;
      freezeHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      freezeHw_i <= '0';

      wait for CLK_PERIOD_C*1000;
      trigHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';

      wait for CLK_PERIOD_C*5000;
      trigCasc_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigCasc_i <= '0';

      wait for CLK_PERIOD_C*500;

      ---------------------------------------------------------
      -- Decimation 2
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_0008", x"0000_0002");

      wait for CLK_PERIOD_C*1000;
      trigHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';
      wait for CLK_PERIOD_C*500;

      ---------------------------------------------------------
      -- Decimation 4
      ---------------------------------------------------------
      axiLiteBusSimWrite(clk_i, axilWriteMaster, axilWriteSlave, x"0000_0008", x"0000_0004");

      wait for CLK_PERIOD_C*1000;
      trigHw_i <= '1';
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';

      wait;
   end process StimuliProcess;

end testbed;
