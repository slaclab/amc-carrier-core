-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_13_CXX
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

library amc_carrier_core;

entity RtmCryoDetReg is
   generic (
      TPD_G       : time     := 1 ns;
      CNT_WIDTH_G : positive := 8);
   port (
      jesdClk         : in  sl;
      jesdRst         : in  sl;
      jesdClkDiv      : out sl;
      kRelay          : in  slv(1 downto 0);
      rampMaxCnt      : out slv(31 downto 0);
      enableRamp      : out sl;
      rampStartMode   : out slv(1 downto 0);
      selRamp         : out sl;
      pulseWidth      : out slv(15 downto 0);
      debounceWidth   : out slv(15 downto 0);
      rtmReset        : out sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end RtmCryoDetReg;

architecture rtl of RtmCryoDetReg is

   type RegType is record
      lowCycle       : slv(CNT_WIDTH_G-1 downto 0);
      highCycle      : slv(CNT_WIDTH_G-1 downto 0);
      rampMaxCnt     : slv(31 downto 0);
      enableRamp     : sl;
      rampStartMode  : slv(1 downto 0);
      selRamp        : sl;
      pulseWidth     : slv(15 downto 0);
      debounceWidth  : slv(15 downto 0);
      rtmReset       : sl;
      rtmClockDelay  : slv(2 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      lowCycle       => toSlv(2, CNT_WIDTH_G),  -- 3 cycles low by default (zero inclusive)
      highCycle      => toSlv(2, CNT_WIDTH_G),  -- 3 cycles low by default (zero inclusive)
      rampMaxCnt     => (others => '0'),
      enableRamp     => '0',
      rampStartMode  => (others => '0'),
      selRamp        => '0',
      pulseWidth     => (others => '0'),
      debounceWidth  => (others => '0'),
      rtmReset       => '1',
      rtmClockDelay  => "011",
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal kRelaySync : slv(1 downto 0);
   signal lowCycle   : slv(CNT_WIDTH_G-1 downto 0);
   signal highCycle  : slv(CNT_WIDTH_G-1 downto 0);

   signal rtmClockDelay : slv(2 downto 0) := (others => '0');

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, kRelaySync, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      axiSlaveRegister(regCon, x"00", 0, v.lowCycle);
      axiSlaveRegister(regCon, x"04", 0, v.highCycle);
      axiSlaveRegisterR(regCon, x"08", 0, toSlv(CNT_WIDTH_G, 32));
      axiSlaveRegisterR(regCon, x"0C", 0, kRelaySync);

      axiSlaveRegister(regCon, x"10", 0, v.rampMaxCnt);
      axiSlaveRegister(regCon, x"14", 0, v.selRamp);
      axiSlaveRegister(regCon, x"14", 1, v.enableRamp);
      axiSlaveRegister(regCon, x"14", 2, v.rampStartMode);
      axiSlaveRegister(regCon, x"18", 0, v.pulseWidth);
      axiSlaveRegister(regCon, x"1C", 0, v.debounceWidth);
      axiSlaveRegister(regCon, x"20", 0, v.rtmReset);
      axiSlaveRegister(regCon, x"20", 1, v.rtmClockDelay);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   Sync_selRamp : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 8)
      port map (
         clk                  => jesdClk,
         dataIn(0)            => r.enableRamp,
         dataIn(2 downto 1)   => r.rampStartMode,
         dataIn(3)            => r.selRamp,
         dataIn(4)            => r.rtmReset,
         dataIn(7 downto 5)   => r.rtmClockDelay,
         dataOut(0)           => enableRamp,
         dataOut(2 downto 1)  => rampStartMode,
         dataOut(3)           => selRamp,
         dataOut(4)           => rtmReset,
         dataOut(7 downto 5)  => rtmClockDelay);

   Sync_rampMaxCnt : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 32)
      port map (
         clk     => jesdClk,
         dataIn  => r.rampMaxCnt,
         dataOut => rampMaxCnt);

   Sync_pulseWidth : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => jesdClk,
         dataIn  => r.pulseWidth,
         dataOut => pulseWidth);

   Sync_debounceWidth : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => jesdClk,
         dataIn  => r.debounceWidth,
         dataOut => debounceWidth);

   Sync_kRelaySync : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk     => axilClk,
         dataIn  => kRelay,
         dataOut => kRelaySync);

   Sync_lowCycle : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => CNT_WIDTH_G)
      port map (
         clk     => jesdClk,
         dataIn  => r.lowCycle,
         dataOut => lowCycle);

   Sync_highCycle : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => CNT_WIDTH_G)
      port map (
         clk     => jesdClk,
         dataIn  => r.highCycle,
         dataOut => highCycle);

   U_ClkDiv : entity amc_carrier_core.RtmCryoDetClkDiv
      generic map (
         TPD_G       => TPD_G,
         CNT_WIDTH_G => CNT_WIDTH_G)
      port map (
         jesdClk       => jesdClk,
         jesdRst       => jesdRst,
         rtmClockDelay => rtmClockDelay,
         jesdClkDiv    => jesdClkDiv,
         lowCycle      => lowCycle,
         highCycle     => highCycle);

end rtl;
