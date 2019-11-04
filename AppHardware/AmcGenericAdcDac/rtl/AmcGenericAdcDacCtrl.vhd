-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacCtrl.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.jesd204bpkg.all;

entity AmcGenericAdcDacCtrl is
   generic (
      TPD_G                    : time                   := 1 ns;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10;
      AXI_CLK_FREQ_G           : real                   := 156.25E+6);
   port (
      -- Pass through Interfaces
      smaTrig         : in  sl;
      adcCal          : in  sl;
      lemoDin         : in  slv(1 downto 0);
      lemoDout        : in  slv(1 downto 0);
      bcm             : in  sl;
      -- AMC Debug Signals
      clk             : in  sl;
      rst             : in  sl;
      adcValids       : in  slv(3 downto 0);
      adcValues       : in  sampleDataArray(3 downto 0);
      dacValues       : in  sampleDataArray(1 downto 0);
      dacVcoCtrl      : in  slv(15 downto 0);
      dacVcoEnable    : out sl;
      dacVcoSckConfig : out slv(15 downto 0);
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
      lmkMuxSel       : out sl;
      lmkClkSel       : out slv(1 downto 0);
      lmkStatus       : in  slv(1 downto 0);
      lmkRst          : out sl;
      lmkSync         : out slv(1 downto 0));
end AmcGenericAdcDacCtrl;

architecture rtl of AmcGenericAdcDacCtrl is

   constant STATUS_SIZE_C : positive := 11;

   type RegType is record
      cntRst          : sl;
      rollOverEn      : slv(STATUS_SIZE_C-1 downto 0);
      dacVcoEnable    : sl;
      dacVcoSckConfig : slv(15 downto 0);
      lmkClkSel       : slv(1 downto 0);
      lmkRst          : sl;
      lmkSync         : sl;
      lmkMuxSel       : sl;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cntRst          => '1',
      rollOverEn      => (others => '0'),
      dacVcoEnable    => '0',
      dacVcoSckConfig => (others => '1'),
      lmkClkSel       => (others => '0'),
      lmkRst          => '0',
      lmkSync         => '0',
      lmkMuxSel       => '0',
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal statusOut      : slv(STATUS_SIZE_C-1 downto 0);
   signal adcDataSync    : Slv16Array(3 downto 0);
   signal dacDataSync    : Slv16Array(1 downto 0);
   signal dacVcoCtrlSync : slv(15 downto 0);
   signal amcClkFreq     : slv(31 downto 0);
   signal statusCnt      : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);
   signal adcValidsSync  : slv(3 downto 0);
   signal softTrig       : sl;
   signal softClear      : sl;

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";

begin

   GEN_ADC :
   for i in 3 downto 0 generate
      Sync_Adc : entity surf.SynchronizerFifo
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

   GEN_DAC :
   for i in 1 downto 0 generate
      Sync_Dac : entity surf.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 16)
         port map (
            -- Write Ports (wr_clk domain)
            wr_clk => clk,
            din    => dacValues(i)(15 downto 0),
            -- Read Ports (rd_clk domain)
            rd_clk => axilClk,
            dout   => dacDataSync(i));
   end generate GEN_DAC;

   Sync_DacVco : entity surf.SynchronizerFifo
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

   U_SyncClockFreq : entity surf.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => AXI_CLK_FREQ_G,
         REFRESH_RATE_G => 1.0,         -- 1 Hz
         CNT_WIDTH_G    => 32)
      port map (
         freqOut => amcClkFreq,
         clkIn   => clk,
         locClk  => axilClk,
         refClk  => axilClk);

   Sync_Config : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         clk        => clk,
         dataIn(0)  => r.dacVcoEnable,
         dataOut(0) => dacVcoEnable);

   Sync_DacVcoSckConfig : entity surf.SynchronizerFifo
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

   U_SyncStatusVector : entity surf.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(10)         => smaTrig,
         statusIn(9)          => adcCal,
         statusIn(8)          => bcm,
         statusIn(7 downto 6) => lemoDin,
         statusIn(5 downto 4) => lemoDout,
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
                   axilWriteMaster, dacDataSync, dacVcoCtrlSync, lmkStatus, r,
                   statusCnt, statusOut) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
      variable i      : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.cntRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      for i in STATUS_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(regCon, toSlv(4*i, 12), 0, muxSlVectorArray(statusCnt, i));
      end loop;
      axiSlaveRegisterR(regCon, x"0FC", 0, statusOut);
      axiSlaveRegisterR(regCon, x"100", 0, adcDataSync(0));
      axiSlaveRegisterR(regCon, x"104", 0, adcDataSync(1));
      axiSlaveRegisterR(regCon, x"108", 0, adcDataSync(2));
      axiSlaveRegisterR(regCon, x"10C", 0, adcDataSync(3));
      axiSlaveRegisterR(regCon, x"110", 0, dacDataSync(0));
      axiSlaveRegisterR(regCon, x"114", 0, dacDataSync(1));

      axiSlaveRegisterR(regCon, x"1F8", 0, dacVcoCtrlSync);
      axiSlaveRegisterR(regCon, x"1FC", 0, amcClkFreq);

      -- Map the read/write registers
      axiSlaveRegister(regCon, x"200", 0, v.lmkClkSel);
      axiSlaveRegister(regCon, x"204", 0, v.lmkRst);
      axiSlaveRegister(regCon, x"208", 0, v.lmkSync);
      axiSlaveRegisterR(regCon, x"20C", 0, lmkStatus);
      axiSlaveRegister(regCon, x"214", 0, v.lmkMuxSel);
      axiSlaveRegister(regCon, x"220", 0, v.dacVcoSckConfig);
      axiSlaveRegister(regCon, x"224", 0, v.dacVcoEnable);

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
      lmkSync        <= (others => r.lmkSync);
      lmkMuxSel      <= r.lmkMuxSel;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
