-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsFastSerialTb.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-15
-- Last update: 2015-06-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the MPS Fast Network module
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

entity MpsFastSerialTb is end MpsFastSerialTb;

architecture testbed of MpsFastSerialTb is

   constant SLOW_PERIOD_C : time := 10 ns;
   constant FAST_PERIOD_C : time := (SLOW_PERIOD_C/2);
   constant TPD_C         : time := 1 ns;

   constant BREAK_ON_ERROR : boolean := true;
   constant BREAK_ON_CNT   : boolean := true;

   -- constant DRIFT_C       : time := 1 ps;
   constant DRIFT_C : time := 0 ps;

   signal remoteClk100MHz : sl := '0';
   signal remoteRst100MHz : sl := '0';
   signal locClk100MHz    : sl := '0';
   signal locRst100MHz    : sl := '0';
   signal locClk200MHz    : sl := '0';
   signal locRst200MHz    : sl := '0';
   signal locClk200MHzInv : sl := '1';

   signal cnt       : slv(15 downto 0) := (others => '0');
   signal faultSent : sl               := '0';
   signal mpsFastP  : sl               := '0';
   signal mpsFastN  : sl               := '1';

   signal linkUp       : sl               := '0';
   signal linkDown     : sl               := '0';
   signal fault        : slv(15 downto 0) := (others => '0');
   signal faultUpdated : sl               := '0';
   signal errDetected  : sl               := '0';
   signal errDecode    : sl               := '0';
   signal errDisparity : sl               := '0';
   signal errComma     : sl               := '0';
   signal errDataK     : sl               := '0';
   signal errCheckSum  : sl               := '0';
   signal errSeqCnt    : sl               := '0';

   signal passed    : sl := '0';
   signal failed    : sl := '0';
   signal passedDly : sl := '0';
   signal failedDly : sl := '0';

   signal driftCnt : slv(3 downto 0) := (others => '0');
   signal drift    : time            := (SLOW_PERIOD_C/2.0);
   
begin

   -----------------------------
   -- Generate clocks and resets
   -----------------------------
   process is
   begin
      wait for 8.8 ns;                  -- Random start phase
      while (true) loop
         remoteClk100MHz <= '1';
         wait for SLOW_PERIOD_C/2.0;
         remoteClk100MHz <= '0';
         wait for drift;
      end loop;
   end process;

   process(remoteClk100MHz)
      variable i : natural;
   begin
      if rising_edge(remoteClk100MHz) then
         -- Check for reset
         if remoteRst100MHz = '1' then
            cnt      <= (others => '0')     after TPD_C;
            driftCnt <= (others => '0')     after TPD_C;
            drift    <= (SLOW_PERIOD_C/2.0) after TPD_C;
         else
            -- Increment the counter
            driftCnt <= driftCnt + 1 after TPD_C;
            -- Check the counter
            if driftCnt = x"F" then
               -- Drift by 1 ps
               drift <= ((SLOW_PERIOD_C/2.0) + DRIFT_C) after TPD_C;
            else
               -- Don't drift the frequency
               drift <= (SLOW_PERIOD_C/2.0) after TPD_C;
            end if;
            if faultSent = '1' then
               -- Increment the counter
               cnt <= cnt + 1 after TPD_C;
            end if;
         end if;
      end if;
   end process;

   RstSync_Inst : entity work.RstSync
      generic map (
         TPD_G => TPD_C)
      port map (
         clk      => remoteClk100MHz,
         asyncRst => locRst100MHz,
         syncRst  => remoteRst100MHz); 

   ClkRst_Local_Slow : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => SLOW_PERIOD_C,
         RST_START_DELAY_G => 0 ns,     -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => locClk100MHz,
         clkN => open,
         rst  => locRst100MHz,
         rstL => open);          

   ClkRst_Local_Fast : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => FAST_PERIOD_C,
         RST_START_DELAY_G => 0 ns,     -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => locClk200MHz,
         clkN => locClk200MHzInv,
         rst  => locRst200MHz,
         rstL => open);      

   MpsFastDelayCtrl_Inst : entity work.MpsFastDelayCtrl
      generic map (
         TPD_G => TPD_C)
      port map (
         ready     => open,
         clk200MHz => locClk200MHz,
         rst200MHz => locRst200MHz); 

   ----------------------------------------
   -- MpsFastSer (VHDL module to be tested)
   ----------------------------------------
   MpsFastSer_Inst : entity work.MpsFastSer
      generic map (
         TPD_G => TPD_C)
      port map (
         -- Fault Message
         fault      => cnt,
         faultSent  => faultSent,
         -- TX Serial Stream
         mpsFastObP => mpsFastP,
         mpsFastObN => mpsFastN,
         mpsFastOb  => open,
         -- Clock and Reset
         clk100MHz  => remoteClk100MHz,
         rst100MHz  => remoteRst100MHz);   

   ------------------------------------------
   -- MpsFastDeSer (VHDL module to be tested)
   ------------------------------------------
   MpsFastDeSer_Inst : entity work.MpsFastDeSer
      generic map (
         TPD_G => TPD_C)
      port map (
         -- Fault Message
         clk100MHz    => locClk100MHz,
         rst100MHz    => locRst100MHz,
         linkUp       => linkUp,
         linkDown     => linkDown,
         fault        => fault,
         faultUpdated => faultUpdated,
         errDetected  => errDetected,
         errDecode    => errDecode,
         errDisparity => errDisparity,
         errComma     => errComma,
         errDataK     => errDataK,
         errCheckSum  => errCheckSum,
         errSeqCnt    => errSeqCnt,
         -- RX Serial Stream
         mpsFastIbP   => mpsFastP,
         mpsFastIbN   => mpsFastN,
         clk200MHz    => locClk200MHz,
         clk200MHzInv => locClk200MHzInv,
         rst200MHz    => locRst200MHz);         

   process(locClk100MHz)
      variable i : natural;
   begin
      if rising_edge(locClk100MHz) then
         passedDly <= passed after TPD_C;
         failedDly <= failed after TPD_C;
         -- Check for reset
         if locRst100MHz = '1' then
            passed <= '0' after TPD_C;
            failed <= '0' after TPD_C;
         else
            -- Check for failure
            if BREAK_ON_ERROR and (errDetected = '1') then
               failed <= '1' after TPD_C;
            end if;
            if BREAK_ON_CNT and (faultUpdated = '1') and (linkUp = '1') and (fault = x"FFFF") then
               passed <= '1' after TPD_C;
            end if;
         end if;
      end if;
   end process;

   process(failedDly, passedDly)
   begin
      if failedDly = '1' then
         assert false
            report "Simulation Failed!" severity failure;
      end if;
      if passedDly = '1' then
         assert false
            report "Simulation Passed!" severity failure;
      end if;
   end process;

end testbed;
