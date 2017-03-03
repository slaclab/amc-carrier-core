-------------------------------------------------------------------------------
-- File       : AppMsgTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-01
-- Last update: 2017-03-02
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;

entity AppMsgTb is end AppMsgTb;

architecture testbed of AppMsgTb is

   constant CLK_PERIOD_C : time := 6.4 ns;
   constant TPD_C        : time := CLK_PERIOD_C/4;

   constant HDR_SIZE_C  : positive := 1;
   constant DATA_SIZE_C : positive := 8;
   constant EN_CRC_C    : boolean  := true;

   type RegType is record
      cnt       : slv(7 downto 0);
      strobe    : sl;
      header    : Slv32Array(HDR_SIZE_C-1 downto 0);
      timeStamp : slv(63 downto 0);
      data      : Slv32Array(DATA_SIZE_C-1 downto 0);
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt       => (others => '0'),
      strobe    => '0',
      header    => (others => (others => '0')),
      timeStamp => (others => '0'),
      data      => (others => (others => '0')));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   signal rx  : RegType := REG_INIT_C;

   signal clk : sl := '0';
   signal rst : sl := '1';

   signal master : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal slave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

begin

   -----------------------------
   -- Generate clocks and resets
   -----------------------------
   U_ClkRst : entity work.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_PERIOD_C,
         RST_START_DELAY_G => 0 ns,  -- Wait this long into simulation before asserting reset
         RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
      port map (
         clkP => clk,
         rst  => rst);

   ------------
   -- TX Module
   ------------
   U_TX : entity work.AppMsgOb
      generic map (
         TPD_G       => TPD_C,
         HDR_SIZE_G  => HDR_SIZE_C,
         DATA_SIZE_G => DATA_SIZE_C,
         EN_CRC_G    => EN_CRC_C)
      port map (
         -- Application Messaging Interface (clk domain)      
         clk         => clk,
         rst         => rst,
         strobe      => r.strobe,
         header      => r.header,
         timeStamp   => r.timeStamp,
         data        => r.data,
         tDest       => r.timeStamp(7 downto 0),         
         -- Backplane Messaging Interface  (axilClk domain)
         axilClk     => clk,
         axilRst     => rst,
         obMsgMaster => master,
         obMsgSlave  => slave);

   ------------
   -- RX Module
   ------------
   U_RX : entity work.AppMsgIb
      generic map (
         TPD_G       => TPD_C,
         HDR_SIZE_G  => HDR_SIZE_C,
         DATA_SIZE_G => DATA_SIZE_C,
         EN_CRC_G    => EN_CRC_C)
      port map (
         -- Application Messaging Interface (clk domain)      
         clk         => clk,
         rst         => rst,
         strobe      => rx.strobe,
         header      => rx.header,
         timeStamp   => rx.timeStamp,
         data        => rx.data,
         -- Backplane Messaging Interface  (axilClk domain)
         axilClk     => clk,
         axilRst     => rst,
         ibMsgMaster => master,
         ibMsgSlave  => slave);

   comb : process (r, rst) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.strobe := '0';

      -- Increment the counter
      v.cnt := r.cnt + 1;

      -- Check the counter
      if r.cnt = x"FF" then
         -- Reset the flags
         v.strobe    := '1';
         -- Increment the counter
         v.timeStamp := r.timeStamp + 1;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_C;
      end if;
   end process seq;

end testbed;
