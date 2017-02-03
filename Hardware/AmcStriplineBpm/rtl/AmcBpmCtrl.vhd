-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      AmcBpmCtrl.vhd - 
--
--      Copyright(c) SLAC National Accelerator Laboratory 2000
--
--      Author: Jeff Olsen
--      Created on: 2/8/2016 8:42:53 AM
--      Last change: JO  2/8/2016 8:42:53 AM
--
-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcBpmCtrl.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-10-29
-- Last update: 2016-07-12
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BPM Common'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 BPM Common', including this file, 
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
use work.BpmPkg.all;
use work.AmcCarrierPkg.all;

entity AmcBpmCtrl is
   generic (
      TPD_G                    : time                   := 1 ns;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10;
      AXI_CLK_FREQ_G           : real                   := 156.25E+6;
      AXI_ERROR_RESP_G         : slv(1 downto 0)        := AXI_RESP_DECERR_C);
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
      lmkClkSel       : out slv(1 downto 0);
      lmkRst          : out sl;
      lmkSync         : out sl;
      -- Analog Control Ports 
      attn1A          : out slv(4 downto 0);
      attn1B          : out slv(4 downto 0);
      attn2A          : out slv(4 downto 0);
      attn2B          : out slv(4 downto 0);
      attn3A          : out slv(4 downto 0);
      attn3B          : out slv(4 downto 0);
      attn4A          : out slv(4 downto 0);
      attn4B          : out slv(4 downto 0);
      attn5A          : out slv(4 downto 0);
      -- Calibration Ports
      clSw            : out slv(5 downto 0);
      clClkOe         : out sl;
      rfAmpOn         : out sl);
end AmcBpmCtrl;

architecture rtl of AmcBpmCtrl is

   constant STATUS_SIZE_C : positive := 5;

   type RegType is record
      iattn1A         : slv(4 downto 0);
      iattn1B         : slv(4 downto 0);
      iattn2A         : slv(4 downto 0);
      iattn2B         : slv(4 downto 0);
      iattn3A         : slv(4 downto 0);
      iattn3B         : slv(4 downto 0);
      iattn4A         : slv(4 downto 0);
      iattn4B         : slv(4 downto 0);
      iattn5A         : slv(4 downto 0);
      TRIG2AMP        : slv(19 downto 0);
      AMP2RF1         : slv(19 downto 0);
      RF12RF2         : slv(19 downto 0);
      RFWIDTH         : slv(19 downto 0);
      OFFTIME         : slv(19 downto 0);
      Trig2Beam       : slv(19 downto 0);
      RF2Red          : slv(19 downto 0);
      RF2Green        : slv(19 downto 0);
      OSCMode         : slv(1 downto 0);
      CalMode         : slv(1 downto 0);
      calReq          : sl;
      dacVcoEnable    : sl;
      dacVcoSckConfig : slv(15 downto 0);
      lmkClkSel       : slv(1 downto 0);
      lmkRst          : sl;
      lmkSync         : sl;
      softTrig        : sl;
      softClear       : sl;
      cntRst          : sl;
      rollOverEn      : slv(STATUS_SIZE_C-1 downto 0);
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      iattn1A         => "11111",                                           -- 31dB Default
      iattn1B         => "11111",                                           -- 31dB Default
      iattn2A         => "11111",                                           -- 31dB Default
      iattn2B         => "11111",                                           -- 31dB Default
      iattn3A         => "11111",                                           -- 31dB Default
      iattn3B         => "11111",                                           -- 31dB Default
      iattn4A         => "11111",                                           -- 31dB Default
      iattn4B         => "11111",                                           -- 31dB Default
      iattn5A         => "11111",                                           -- 31dB Default
      TRIG2AMP        => toslv(getTimeRatio(AXI_CLK_FREQ_G, 2.0E3), 20),    -- 1/500us   = 2.0E3
      AMP2RF1         => toslv(getTimeRatio(AXI_CLK_FREQ_G, 208.3E3), 20),  -- 1/4.8us  = 208.3E3
      RF12RF2         => toslv(getTimeRatio(AXI_CLK_FREQ_G, 500.0E3), 20),  -- 1/2us    = 500.0E3
      RFWIDTH         => toslv(getTimeRatio(AXI_CLK_FREQ_G, 3.33E6), 20),   -- 1/300ns   = 3.33E6
      OFFTIME         => toslv(getTimeRatio(AXI_CLK_FREQ_G, 500.0E3), 20),  -- 1/2us    = 500.0E3
      Trig2Beam       => toslv(getTimeRatio(AXI_CLK_FREQ_G, 10.0E6), 20),   -- 1/100ns  = 310E6
      RF2Red          => toslv(getTimeRatio(AXI_CLK_FREQ_G, 3.33E6), 20),   -- 1/300ns    = 3.33E6
      RF2Green        => toslv(getTimeRatio(AXI_CLK_FREQ_G, 3.33E6), 20),   -- 1/300ns  = 3.33E6
      OSCMode         => "00",
      CalMode         => "11",
      calReq          => '0',
      dacVcoEnable    => '0',
      dacVcoSckConfig => (others => '1'),
      lmkClkSel       => (others => '0'),
      lmkRst          => '0',
      lmkSync         => '0',
      softTrig        => '0',
      softClear       => '0',
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
   signal softTrig       : sl;
   signal softClear      : sl;

   signal ADCTrigger : sl;
   signal CALDone    : sl;

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

   Synchronizer_DebugTrig : entity work.RingBufferCtrl
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

   comb : process (CalDone, adcDataSync, amcClkFreq, axilReadMaster, axilRst, axilWriteMaster,
                   dacVcoCtrlSync, r, statusCnt, statusOut) is
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

      procedure axiSlaveRegisterWSat(addr : in slv; offset : in integer; reg : inout slv; min : integer; Max : integer) is
      begin
         axiSlaveRegisterSat(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, addr, offset, reg, min, Max);
      end procedure;

   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus);

      -- Reset the strobes
      v.cntRst    := '0';
      v.softTrig  := '0';
      v.softClear := '0';

      -- Reset data bus on AXI-Lite ACK
      if (axilReadMaster.rready = '1') then
         v.axilReadSlave.rdata := (others => '0');
      end if;

      -- Reset on calibration ACK
      if (CalDone = '1') then
         v.calReq := '0';
      end if;

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
      axiSlaveRegisterR(x"1F8", 0, dacVcoCtrlSync);
      axiSlaveRegisterR(x"1FC", 0, amcClkFreq);

      -- Map the read/write registers
      axiSlaveRegisterW(x"200", 0, v.lmkClkSel);
      axiSlaveRegisterW(x"204", 0, v.lmkRst);
      axiSlaveRegisterW(x"208", 0, v.lmkSync);

      ----------------------------------------------------------
      -- Note:  Attenuator States
      -- attn[0]  attn[1]  attn[2]  attn[3]  attn[4]  ATT. State
      -- HIGH     HIGH     HIGH     HIGH     HIGH     Insertion Loss
      -- HIGH     HIGH     HIGH     HIGH     LOW      1dB
      -- HIGH     HIGH     HIGH     LOW      HIGH     2dB
      -- HIGH     HIGH     LOW      HIGH     HIGH     4dB
      -- HIGH     LOW      HIGH     HIGH     HIGH     8dB
      -- LOW      HIGH     HIGH     HIGH     HIGH     16dB
      -- LOW      LOW      LOW      LOW      LOW      31dB
      ----------------------------------------------------------
      axiSlaveRegisterWSat(x"210", 0, v.iattn1A, 31, 0);
      axiSlaveRegisterWSat(x"214", 0, v.iattn1B, 31, 0);
      axiSlaveRegisterWSat(x"218", 0, v.iattn2A, 31, 0);
      axiSlaveRegisterWSat(x"21C", 0, v.iattn2B, 31, 0);
      axiSlaveRegisterWSat(x"220", 0, v.iattn3A, 31, 0);
      axiSlaveRegisterWSat(x"224", 0, v.iattn3B, 31, 0);
      axiSlaveRegisterWSat(x"228", 0, v.iattn4A, 31, 0);
      axiSlaveRegisterWSat(x"22C", 0, v.iattn4B, 31, 0);
      axiSlaveRegisterWSat(x"230", 0, v.iattn5A, 31, 6);

      axiSlaveRegisterW(x"234", 0, v.TRIG2AMP);
      axiSlaveRegisterW(x"238", 0, v.AMP2RF1);
      axiSlaveRegisterW(x"23C", 0, v.RF12RF2);
      axiSlaveRegisterW(x"240", 0, v.RFWIDTH);
      axiSlaveRegisterW(x"244", 0, v.OFFTIME);

      axiSlaveRegisterW(x"248", 0, v.Trig2Beam);
      axiSlaveRegisterW(x"24C", 0, v.RF2Red);
      axiSlaveRegisterW(x"250", 0, v.RF2Green);
      axiSlaveRegisterW(x"254", 0, v.OscMode);
      axiSlaveRegisterW(x"258", 0, v.CalMode);
      axiSlaveRegisterW(x"25C", 0, v.calReq);

      axiSlaveRegisterW(x"300", 0, v.softTrig);
      axiSlaveRegisterW(x"304", 0, v.softClear);
      axiSlaveRegisterW(x"308", 0, v.dacVcoSckConfig);
      axiSlaveRegisterW(x"30C", 0, v.dacVcoEnable);

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
      attn1A         <= not(r.iattn1A(0) & r.iattn1A(1) & r.iattn1A(2) & r.iattn1A(3) & r.iattn1A(4));
      attn1B         <= not(r.iattn1B(0) & r.iattn1B(1) & r.iattn1B(2) & r.iattn1B(3) & r.iattn1B(4));
      attn2A         <= not(r.iattn2A(0) & r.iattn2A(1) & r.iattn2A(2) & r.iattn2A(3) & r.iattn2A(4));
      attn2B         <= not(r.iattn2B(0) & r.iattn2B(1) & r.iattn2B(2) & r.iattn2B(3) & r.iattn2B(4));
      attn3A         <= not(r.iattn3A(0) & r.iattn3A(1) & r.iattn3A(2) & r.iattn3A(3) & r.iattn3A(4));
      attn3B         <= not(r.iattn3B(0) & r.iattn3B(1) & r.iattn3B(2) & r.iattn3B(3) & r.iattn3B(4));
      attn4A         <= not(r.iattn4A(0) & r.iattn4A(1) & r.iattn4A(2) & r.iattn4A(3) & r.iattn4A(4));
      attn4B         <= not(r.iattn4B(0) & r.iattn4B(1) & r.iattn4B(2) & r.iattn4B(3) & r.iattn4B(4));
      attn5A         <= not(r.iattn5A(0) & r.iattn5A(1) & r.iattn5A(2) & r.iattn5A(3) & r.iattn5A(4));

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_Cal_Seq : cal_seq
      port map (
         Clock       => axilClk,
         Reset       => axilRst,
         Clk_Ok      => '1',
         Cal_Trigger => debugTrig,
         Cal_En      => r.calReq,
         ModeSel     => r.CalMode,
         OscMode     => r.OscMode,
         TRIG2AMP    => r.TRIG2AMP,
         AMP2RF1     => r.AMP2RF1,
         RF12RF2     => r.RF12RF2,
         RFWIDTH     => r.RFWIDTH,
         OFFTIME     => r.OFFTIME,
         Trig2Beam   => r.TRIG2BEAM,
         RF2Red      => r.RF2RED,
         RF2Green    => r.RF2GREEN,
         CAL_SW      => CLSW,
         Osc_En      => CLCLKOe,
         AMP_On      => rfAmpOn,
         ADCTrigger  => ADCTrigger,
         CALDone     => CALDone);        

end rtl;
