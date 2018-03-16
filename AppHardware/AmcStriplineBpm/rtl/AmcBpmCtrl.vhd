-------------------------------------------------------------------------------
-- File       : AmcBpmCtrl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-29
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_03_CXX
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
use work.jesd204bpkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcBpmCtrl is
   generic (
      TPD_G          : time := 1 ns;
      AXI_CLK_FREQ_G : real := 156.25E+6);
   port (
      -- Debug Signals
      amcClk          : in  sl;
      clk             : in  sl;
      rst             : in  sl;
      adcValids       : in  slv(3 downto 0);
      adcValues       : in  sampleDataArray(3 downto 0);
      dacVcoCtrl      : in  slv(15 downto 0);
      dacVcoEnable    : out sl;
      dacVcoSckConfig : out slv(15 downto 0);
      lemoTrig        : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- LMK Ports
      lmkClkSel       : out slv(1 downto 0);
      lmkRst          : out sl;
      lmkSync         : out sl);
end AmcBpmCtrl;

architecture rtl of AmcBpmCtrl is

   constant STATUS_SIZE_C : positive := 5;

   type RegType is record
      dacVcoEnable    : sl;
      dacVcoSckConfig : slv(15 downto 0);
      lmkClkSel       : slv(1 downto 0);
      lmkRst          : sl;
      lmkSync         : sl;
      cntRst          : sl;
      rollOverEn      : slv(STATUS_SIZE_C-1 downto 0);
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      dacVcoEnable    => '0',
      dacVcoSckConfig => (others => '1'),
      lmkClkSel       => (others => '0'),
      lmkRst          => '0',
      lmkSync         => '0',
      cntRst          => '1',
      rollOverEn      => (others => '0'),
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal statusOut      : slv(STATUS_SIZE_C-1 downto 0);
   signal adcDataSync    : Slv16Array(3 downto 0);
   signal dacVcoCtrlSync : slv(15 downto 0);
   signal amcClkFreq     : slv(31 downto 0);
   signal statusCnt      : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);
   signal adcValidsSync  : slv(3 downto 0);

   -- attribute dont_touch      : string;
   -- attribute dont_touch of r : signal is "TRUE";

begin

   GEN_ADC :
   for i in 3 downto 0 generate
      Sync_Adc : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 16)
         port map (
            -- Write Ports (wr_clk domain)
            wr_clk => clk,
            din    => adcValues(i)(15 downto 0),
            -- Read Ports (rd_clk domain)
            rd_clk => axilClk,
            dout   => adcDataSync(i));
   end generate GEN_ADC;

   Sync_DacVco : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 16)
      port map (
         -- Write Ports (wr_clk domain)
         wr_clk => clk,
         din    => dacVcoCtrl,
         -- Read Ports (rd_clk domain)
         rd_clk => axilClk,
         dout   => dacVcoCtrlSync);

   U_SyncClockFreq : entity work.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_G,
         REFRESH_RATE_G => 1.0,         -- 1 Hz
         CNT_WIDTH_G    => 32)
      port map (
         freqOut => amcClkFreq,
         clkIn   => amcClk,
         locClk  => axilClk,
         refClk  => axilClk);

   Sync_Config : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         clk        => clk,
         dataIn(0)  => r.dacVcoEnable,
         dataOut(0) => dacVcoEnable);

   Sync_DacVcoSckConfig : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 16)
      port map (
         -- Write Ports (wr_clk domain)
         wr_clk => axilClk,
         din    => r.dacVcoSckConfig,
         -- Read Ports (rd_clk domain)
         rd_clk => clk,
         dout   => dacVcoSckConfig);

   U_SyncStatusVector : entity work.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(4)          => lemoTrig,
         statusIn(3 downto 0) => adcValids,
         -- Output Status bit Signals (rdClk domain)  
         statusOut            => statusOut,
         -- Status Bit Counters Signals (rdClk domain) 
         cntRstIn             => r.cntRst,
         rollOverEnIn         => r.rollOverEn,
         cntOut               => statusCnt,
         -- Clocks and Reset Ports
         wrClk                => clk,
         rdClk                => axilClk);

   comb : process (adcDataSync, amcClkFreq, axilReadMaster, axilRst,
                   axilWriteMaster, dacVcoCtrlSync, r, statusCnt, statusOut) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.cntRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers      
      axiSlaveRegisterR(regCon, x"000", 0, muxSlVectorArray(statusCnt, 0));
      axiSlaveRegisterR(regCon, x"004", 0, muxSlVectorArray(statusCnt, 1));
      axiSlaveRegisterR(regCon, x"008", 0, muxSlVectorArray(statusCnt, 2));
      axiSlaveRegisterR(regCon, x"00C", 0, muxSlVectorArray(statusCnt, 3));
      axiSlaveRegisterR(regCon, x"010", 0, muxSlVectorArray(statusCnt, 4));
      axiSlaveRegisterR(regCon, x"0FC", 0, statusOut);
      axiSlaveRegisterR(regCon, x"100", 0, adcDataSync(0));
      axiSlaveRegisterR(regCon, x"104", 0, adcDataSync(1));
      axiSlaveRegisterR(regCon, x"108", 0, adcDataSync(2));
      axiSlaveRegisterR(regCon, x"10C", 0, adcDataSync(3));
      axiSlaveRegisterR(regCon, x"1F8", 0, dacVcoCtrlSync);
      axiSlaveRegisterR(regCon, x"1FC", 0, amcClkFreq);

      -- Map the read/write registers
      axiSlaveRegister(regCon, x"200", 0, v.lmkClkSel);
      axiSlaveRegister(regCon, x"204", 0, v.lmkRst);
      axiSlaveRegister(regCon, x"208", 0, v.lmkSync);

      axiSlaveRegister(regCon, x"308", 0, v.dacVcoSckConfig);
      axiSlaveRegister(regCon, x"30C", 0, v.dacVcoEnable);

      axiSlaveRegister(regCon, x"3F8", 0, v.rollOverEn);
      axiSlaveRegister(regCon, x"3FC", 0, v.cntRst);

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
      lmkClkSel      <= r.lmkClkSel;
      lmkRst         <= r.lmkRst;
      lmkSync        <= r.lmkSync;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
