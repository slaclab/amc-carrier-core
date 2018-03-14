-------------------------------------------------------------------------------
-- File       : RtmCryoDetReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-11-03
-- Last update: 2018-03-14
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

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
      rampStartMode   : out sl;
      selRamp         : out sl;
      pulseWidth      : out slv(15 downto 0);
      debounceWidth   : out slv(15 downto 0);
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
      rampStartMode  : sl;
      selRamp        : sl;
      pulseWidth     : slv(15 downto 0);
      debounceWidth  : slv(15 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      lowCycle       => toSlv(2, CNT_WIDTH_G),  -- 3 cycles low by default (zero inclusive)
      highCycle      => toSlv(2, CNT_WIDTH_G),  -- 3 cycles low by default (zero inclusive)
      rampMaxCnt     => (others => '0'),
      enableRamp     => '0',
      rampStartMode  => '0',
      selRamp        => '0',
      pulseWidth     => (others => '0'),
      debounceWidth  => (others => '0'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal kRelaySync : slv(1 downto 0);
   signal lowCycle   : slv(CNT_WIDTH_G-1 downto 0);
   signal highCycle  : slv(CNT_WIDTH_G-1 downto 0);

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

   Sync_selRamp : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         clk        => jesdClk,
         dataIn(0)  => r.enableRamp,
         dataIn(1)  => r.rampStartMode,
         dataIn(2)  => r.selRamp,
         dataOut(0) => enableRamp,
         dataOut(1) => rampStartMode,
         dataOut(2) => selRamp);

   Sync_rampMaxCnt : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 32)
      port map (
         clk     => jesdClk,
         dataIn  => r.rampMaxCnt,
         dataOut => rampMaxCnt);

   Sync_pulseWidth : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => jesdClk,
         dataIn  => r.pulseWidth,
         dataOut => pulseWidth);

   Sync_debounceWidth : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => jesdClk,
         dataIn  => r.debounceWidth,
         dataOut => debounceWidth);

   Sync_kRelaySync : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk     => jesdClk,
         dataIn  => kRelay,
         dataOut => kRelaySync);

   Sync_lowCycle : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => CNT_WIDTH_G)
      port map (
         clk     => jesdClk,
         dataIn  => r.lowCycle,
         dataOut => lowCycle);

   Sync_highCycle : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => CNT_WIDTH_G)
      port map (
         clk     => jesdClk,
         dataIn  => r.highCycle,
         dataOut => highCycle);

   U_ClkDiv : entity work.RtmCryoDetClkDiv
      generic map (
         TPD_G       => TPD_G,
         CNT_WIDTH_G => CNT_WIDTH_G)
      port map (
         jesdClk    => jesdClk,
         jesdRst    => jesdRst,
         jesdClkDiv => jesdClkDiv,
         lowCycle   => lowCycle,
         highCycle  => highCycle);

end rtl;
