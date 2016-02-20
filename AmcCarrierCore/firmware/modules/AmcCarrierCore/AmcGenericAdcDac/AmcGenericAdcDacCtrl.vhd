-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacCtrl.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2016-02-19
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
use work.jesd204bpkg.all;

entity AmcGenericAdcDacCtrl is
   generic (
      TPD_G                    : time                   := 1 ns;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10;
      AXI_CLK_FREQ_G           : real                   := 156.25E+6;
      AXI_ERROR_RESP_G         : slv(1 downto 0)        := AXI_RESP_DECERR_C);
   port (
      -- AMC Debug Signals
      amcClk          : in  sl;
      clk             : in  sl;
      rst             : in  sl;
      adcValids       : in  slv(3 downto 0);
      adcValues       : in  sampleDataArray(3 downto 0);
      dacValues       : in  sampleDataArray(1 downto 0);
      dacVcoCtrl      : in  slv(15 downto 0);
      dacVcoEnable    : out sl;
      dacVcoSckConfig : out slv(15 downto 0);
      loopback        : out sl;
      debugTrig       : in  sl;
      debugLogEn      : out sl;
      debugLogClr     : out sl;
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

   constant STATUS_SIZE_C : positive := 5;

   type RegType is record
      cntRst          : sl;
      rollOverEn      : slv(STATUS_SIZE_C-1 downto 0);
      loopback        : sl;
      dacVcoEnable    : sl;
      dacVcoSckConfig : slv(15 downto 0);
      lmkClkSel       : slv(1 downto 0);
      lmkRst          : sl;
      lmkSync         : sl;
      lmkMuxSel       : sl;
      softTrig        : sl;
      softClear       : sl;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cntRst          => '1',
      rollOverEn      => (others => '0'),
      loopback        => '0',
      dacVcoEnable    => '0',
      dacVcoSckConfig => (others => '1'),
      lmkClkSel       => (others => '0'),
      lmkRst          => '0',
      lmkSync         => '0',
      lmkMuxSel       => '0',
      softTrig        => '0',
      softClear       => '0',
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

   GEN_DAC :
   for i in 1 downto 0 generate
      Sync_Dac : entity work.SynchronizerFifo
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
         WIDTH_G => 2)
      port map (
         clk        => clk,
         dataIn(0)  => r.loopback,
         dataIn(1)  => r.dacVcoEnable,
         dataOut(0) => loopback,
         dataOut(1) => dacVcoEnable);    

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

   Synchronizer_softTrig : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => clk,
         dataIn  => r.softTrig,
         dataOut => softTrig);

   Synchronizer_softClear : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => clk,
         dataIn  => r.softClear,
         dataOut => softClear);     

   Synchronizer_DebugTrig : entity work.AmcGenericAdcDacSyncTrig
      generic map (
         TPD_G                    => TPD_G,
         RING_BUFFER_ADDR_WIDTH_G => RING_BUFFER_ADDR_WIDTH_G)
      port map (
         clk         => clk,
         rst         => rst,
         softTrig    => softTrig,
         softClear   => softClear,
         debugTrig   => debugTrig,
         debugLogEn  => debugLogEn,
         debugLogClr => debugLogClr);

   U_SyncStatusVector : entity work.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)     
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(4)          => debugTrig,
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

   comb : process (adcDataSync, amcClkFreq, axilReadMaster, axilRst, axilWriteMaster, dacDataSync,
                   dacVcoCtrlSync, lmkStatus, r, statusCnt, statusOut) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;

      -- Wrapper procedures to make calls cleaner.
      procedure axiSlaveRegisterW (addr : in slv; offset : in integer; reg : inout slv; cA : in boolean := false; cV : in slv := "0") is
      begin
         axiSlaveRegister(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, addr, offset, reg, cA, cV);
      end procedure;

      procedure axiSlaveRegisterR (addr : in slv; offset : in integer; reg : in slv) is
      begin
         axiSlaveRegister(axilReadMaster, v.axilReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterW (addr : in slv; offset : in integer; reg : inout sl) is
      begin
         axiSlaveRegister(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterR (addr : in slv; offset : in integer; reg : in sl) is
      begin
         axiSlaveRegister(axilReadMaster, v.axilReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveDefault (
         axiResp : in slv(1 downto 0)) is
      begin
         axiSlaveDefault(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, axiResp);
      end procedure;

   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.cntRst    := '0';
      v.softTrig  := '0';
      v.softClear := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus);

      -- Map the read only registers
      axiSlaveRegisterR(x"000", 0, muxSlVectorArray(statusCnt, 0));
      axiSlaveRegisterR(x"004", 0, muxSlVectorArray(statusCnt, 1));
      axiSlaveRegisterR(x"008", 0, muxSlVectorArray(statusCnt, 2));
      axiSlaveRegisterR(x"00C", 0, muxSlVectorArray(statusCnt, 3));
      axiSlaveRegisterR(x"010", 0, muxSlVectorArray(statusCnt, 4));
      axiSlaveRegisterR(x"0FC", 0, statusOut);
      axiSlaveRegisterR(x"100", 0, adcDataSync(0));
      axiSlaveRegisterR(x"104", 0, adcDataSync(1));
      axiSlaveRegisterR(x"108", 0, adcDataSync(2));
      axiSlaveRegisterR(x"10C", 0, adcDataSync(3));
      axiSlaveRegisterR(x"110", 0, dacDataSync(0));
      axiSlaveRegisterR(x"114", 0, dacDataSync(1));

      axiSlaveRegisterR(x"1F8", 0, dacVcoCtrlSync);
      axiSlaveRegisterR(x"1FC", 0, amcClkFreq);

      -- Map the read/write registers
      axiSlaveRegisterW(x"200", 0, v.lmkClkSel);
      axiSlaveRegisterW(x"204", 0, v.lmkRst);
      axiSlaveRegisterW(x"208", 0, v.lmkSync);
      axiSlaveRegisterR(x"20C", 0, lmkStatus);
      axiSlaveRegisterW(x"210", 0, v.loopback);
      axiSlaveRegisterW(x"214", 0, v.lmkMuxSel);
      axiSlaveRegisterW(x"218", 0, v.softTrig);
      axiSlaveRegisterW(x"21C", 0, v.softClear);
      axiSlaveRegisterW(x"220", 0, v.dacVcoSckConfig);
      axiSlaveRegisterW(x"224", 0, v.dacVcoEnable);

      axiSlaveRegisterW(x"3F8", 0, v.rollOverEn);
      axiSlaveRegisterW(x"3FC", 0, v.cntRst);

      -- Set the Slave's response
      axiSlaveDefault(AXI_ERROR_RESP_G);

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
