-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacCtrl.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2016-01-26
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
      TPD_G            : time            := 1 ns;
      AXI_CLK_FREQ_G   : real            := 156.25E+6;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- AMC Debug Signals
      amcClk          : in  sl;
      clk             : in  sl;
      rst             : in  sl;
      adcValids       : in  slv(3 downto 0);
      adcValues       : in  sampleDataArray(3 downto 0);
      dacValues       : in  sampleDataArray(1 downto 0);
      dacVcoCtrl      : in  slv(15 downto 0);
      loopback        : out sl;
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
      lmkStatus       : in  slv(1 downto 0);
      lmkRst          : out sl;
      lmkSync         : out sl);
end AmcGenericAdcDacCtrl;

architecture rtl of AmcGenericAdcDacCtrl is

   constant MAX_CNT_C     : natural  := getTimeRatio(AXI_CLK_FREQ_G, 1.0);
   constant STATUS_SIZE_C : positive := 4;

   type RegType is record
      cntRst         : sl;
      rollOverEn     : slv(STATUS_SIZE_C-1 downto 0);
      loopback       : sl;
      cnt            : natural range 0 to MAX_CNT_C;
      update         : sl;
      lmkClkSel      : slv(1 downto 0);
      lmkRst         : sl;
      lmkSync        : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cntRst         => '1',
      rollOverEn     => (others => '0'),
      loopback       => '0',
      cnt            => 0,
      update         => '0',
      lmkClkSel      => (others => '0'),
      lmkRst         => '0',
      lmkSync        => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal statusCnt     : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);
   signal adcValidsSync : slv(3 downto 0);

   signal update     : sl;
   signal cnt        : Slv4Array(3 downto 0);
   signal amcClkFreq : slv(31 downto 0);
   signal dacVco     : slv(15 downto 0);
   signal adcSmpl    : Slv16VectorArray(3 downto 0, 3 downto 0);
   signal dacSmpl    : Slv16VectorArray(1 downto 0, 3 downto 0);
   signal adc        : Slv16VectorArray(3 downto 0, 3 downto 0);
   signal dac        : Slv16VectorArray(1 downto 0, 3 downto 0);

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";
   -- attribute dont_touch of update     : signal is "TRUE";
   -- attribute dont_touch of cnt        : signal is "TRUE";
   -- attribute dont_touch of amcClkFreq : signal is "TRUE";
   -- attribute dont_touch of dacVco     : signal is "TRUE";
   -- attribute dont_touch of adcSmpl    : signal is "TRUE";
   -- attribute dont_touch of dacSmpl    : signal is "TRUE";
   -- attribute dont_touch of adc        : signal is "TRUE";
   -- attribute dont_touch of dac        : signal is "TRUE";
   
begin

   process(clk)
      variable i : natural;
   begin
      if rising_edge(clk) then
         if update = '1' then
            cnt <= (others => x"0") after TPD_G;
         else
            -- Loop through the channel
            for i in 3 downto 0 loop
               -- Check for valid
               if adcValids(i) = '1' then
                  -- Check for max. sampling range
                  if cnt(i) < 4 then
                     -- Sample the ADC
                     adcSmpl(i, conv_integer(cnt(i))+1) <= adcValues(i)(31 downto 16) after TPD_G;
                     adcSmpl(i, conv_integer(cnt(i))+0) <= adcValues(i)(15 downto 0)  after TPD_G;
                     -- Check for DAC 
                     if i < 2 then
                        -- Sample the DAC
                        dacSmpl(i, conv_integer(cnt(i))+1) <= dacValues(i)(31 downto 16) after TPD_G;
                        dacSmpl(i, conv_integer(cnt(i))+0) <= dacValues(i)(15 downto 0)  after TPD_G;
                     end if;
                     -- Increment the counter
                     cnt(i) <= cnt(i) + 2 after TPD_G;
                  end if;
               end if;
            end loop;
         end if;
      end if;
   end process;

   GEN_ADC :
   for i in 3 downto 0 generate
      GEN_ADC_SMPL :
      for j in 3 downto 0 generate
         Sync_Adc : entity work.SynchronizerFifo
            generic map (
               TPD_G        => TPD_G,
               DATA_WIDTH_G => 16)
            port map (
               -- Write Ports (wr_clk domain)
               wr_clk => clk,
               din    => adcSmpl(i, j),
               -- Read Ports (rd_clk domain)
               rd_clk => axilClk,
               dout   => adc(i, j));
      end generate GEN_ADC_SMPL;
   end generate GEN_ADC;

   GEN_DAC :
   for i in 1 downto 0 generate
      GEN_DAC_SMPL :
      for j in 3 downto 0 generate
         Sync_Dac : entity work.SynchronizerFifo
            generic map (
               TPD_G        => TPD_G,
               DATA_WIDTH_G => 16)
            port map (
               -- Write Ports (wr_clk domain)
               wr_clk => clk,
               din    => dacSmpl(i, j),
               -- Read Ports (rd_clk domain)
               rd_clk => axilClk,
               dout   => dac(i, j));
      end generate GEN_DAC_SMPL;
   end generate GEN_DAC;

   Sync_Update : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => clk,
         dataIn  => r.update,
         dataOut => update);

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
         dout   => dacVco);   

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

   Sync_loopback : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => clk,
         dataIn  => r.loopback,
         dataOut => loopback);         

   U_SyncStatusVector : entity work.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)     
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(3 downto 0)  => adcValids,
         -- Output Status bit Signals (rdClk domain)  
         statusOut(3 downto 0) => adcValidsSync,
         -- Status Bit Counters Signals (rdClk domain) 
         cntRstIn              => r.cntRst,
         rollOverEnIn          => r.rollOverEn,
         cntOut                => statusCnt,
         -- Clocks and Reset Ports
         wrClk                 => clk,
         rdClk                 => axilClk);              

   comb : process (adc, adcValidsSync, amcClkFreq, axilReadMaster, axilRst, axilWriteMaster, dac,
                   dacVco, lmkStatus, r, statusCnt) is
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
      v.update := '0';
      v.cntRst := '0';

      -- Increment the counter
      v.cnt := r.cnt + 1;

      -- Check for timeout
      if r.cnt = (MAX_CNT_C-1) then
         -- Reset the counter
         v.cnt    := 0;
         -- Set the flag
         v.update := '1';
      end if;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus);

      -- Map the read only registers
      axiSlaveRegisterR(x"000", 0, muxSlVectorArray(statusCnt, 0));
      axiSlaveRegisterR(x"004", 0, muxSlVectorArray(statusCnt, 1));
      axiSlaveRegisterR(x"008", 0, muxSlVectorArray(statusCnt, 2));
      axiSlaveRegisterR(x"00C", 0, muxSlVectorArray(statusCnt, 3));
      axiSlaveRegisterR(x"0FC", 0, adcValidsSync);
      axiSlaveRegisterR(x"100", 0, adc(0, 0));
      axiSlaveRegisterR(x"104", 0, adc(0, 1));
      axiSlaveRegisterR(x"108", 0, adc(0, 2));
      axiSlaveRegisterR(x"10C", 0, adc(0, 3));
      axiSlaveRegisterR(x"110", 0, adc(1, 0));
      axiSlaveRegisterR(x"114", 0, adc(1, 1));
      axiSlaveRegisterR(x"118", 0, adc(1, 2));
      axiSlaveRegisterR(x"11C", 0, adc(1, 3));
      axiSlaveRegisterR(x"120", 0, adc(2, 0));
      axiSlaveRegisterR(x"124", 0, adc(2, 1));
      axiSlaveRegisterR(x"128", 0, adc(2, 2));
      axiSlaveRegisterR(x"12C", 0, adc(2, 3));
      axiSlaveRegisterR(x"130", 0, adc(3, 0));
      axiSlaveRegisterR(x"134", 0, adc(3, 1));
      axiSlaveRegisterR(x"138", 0, adc(3, 2));
      axiSlaveRegisterR(x"13C", 0, adc(3, 3));
      axiSlaveRegisterR(x"140", 0, dac(0, 0));
      axiSlaveRegisterR(x"144", 0, dac(0, 1));
      axiSlaveRegisterR(x"148", 0, dac(0, 2));
      axiSlaveRegisterR(x"14C", 0, dac(0, 3));
      axiSlaveRegisterR(x"150", 0, dac(1, 0));
      axiSlaveRegisterR(x"154", 0, dac(1, 1));
      axiSlaveRegisterR(x"158", 0, dac(1, 2));
      axiSlaveRegisterR(x"15C", 0, dac(1, 3));

      axiSlaveRegisterR(x"1F8", 0, dacVco);
      axiSlaveRegisterR(x"1FC", 0, amcClkFreq);

      -- Map the read/write registers
      axiSlaveRegisterW(x"200", 0, v.lmkClkSel);
      axiSlaveRegisterW(x"204", 0, v.lmkRst);
      axiSlaveRegisterW(x"208", 0, v.lmkSync);
      axiSlaveRegisterR(x"20C", 0, lmkStatus);
      axiSlaveRegisterW(x"210", 0, v.loopback);
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
      lmkSync        <= r.lmkSync;
      
   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
