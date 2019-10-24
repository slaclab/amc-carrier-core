-------------------------------------------------------------------------------
-- File       : AxisBramFlashBufferWrFsm.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-04-10
-- Last update: 2018-04-12
-------------------------------------------------------------------------------
-- Data Format:
--    DATA[0].BIT[7:0]    = protocol version (0x0)
--    DATA[0].BIT[15:8]   = channel index
--    DATA[0].BIT[63:16]  = event id
--    DATA[0].BIT[127:64] = timestamp
--    DATA[1] = BRAM[3] & BRAM[2] & BRAM[1] & BRAM[0];
--    DATA[2] = BRAM[7] & BRAM[6] & BRAM[5] & BRAM[4];
--    ................................................
--    ................................................
--    ................................................
--    DATA[1+N/4] = BRAM[N-1] & BRAM[N-2] & BRAM[N-3] & BRAM[N-4];
--
--       where N = 2**BUFFER_WIDTH_G
--
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

entity AxisBramFlashBufferWrFsm is
   generic (
      TPD_G          : time     := 1 ns;
      NUM_CH_G       : positive := 1;
      BUFFER_WIDTH_G : positive := 8);
   port (
      -- Input Data Interface (appClk domain)
      appClk          : in  sl;
      appRst          : in  sl;
      apptrig         : in  sl;
      appValid        : in  slv(NUM_CH_G-1 downto 0);
      appData         : in  Slv32Array(NUM_CH_G-1 downto 0);
      -- Input timing interface
      timingClk       : in  sl;
      timingRst       : in  sl;
      timingTimestamp : in  slv(63 downto 0);
      -- Ram Interface (appClk domain)
      wrEn            : out sl;
      wrAddr          : out slv(BUFFER_WIDTH_G-1 downto 0);
      wrData          : out Slv32Array(NUM_CH_G-1 downto 0);
      -- Software Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      enable          : in  sl;
      swtrig          : in  sl;
      -- Read FSM Interface (axisClk domain)
      axisClk         : in  sl;
      axisRst         : in  sl;
      req             : out sl;
      valid           : out slv(NUM_CH_G-1 downto 0);
      timestamp       : out slv(63 downto 0);
      ack             : in  sl);
end AxisBramFlashBufferWrFsm;

architecture mapping of AxisBramFlashBufferWrFsm is

   constant MAX_CNT_C : slv(BUFFER_WIDTH_G-1 downto 0) := (others => '1');

   type StateType is (
      IDLE_S,
      WRITE_RAM_S,
      HAND_SHAKE_S);

   type RegType is record
      trigDet : sl;
      wrEn    : sl;
      wrAddr  : slv(BUFFER_WIDTH_G-1 downto 0);
      wrData  : Slv32Array(NUM_CH_G-1 downto 0);
      req     : sl;
      valid   : slv(NUM_CH_G-1 downto 0);
      state   : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      trigDet => '0',
      wrEn    => '0',
      wrAddr  => (others => '0'),
      wrData  => (others => x"0000_0000"),
      req     => '0',
      valid   => (others => '0'),
      state   => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ackSync     : sl;
   signal axisRstSync : sl;
   signal swTrigSync  : sl;
   signal enableSync  : sl;
   signal trigDetSync : sl;

begin

   comb : process (ackSync, appData, appRst, appValid, apptrig, axisRstSync,
                   enableSync, r, swTrigSync) is
      variable v : RegType;
      variable i : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.req     := '0';
      v.wrEn    := '0';
      v.trigDet := '0';

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check if enable and waiting for trigger
            if (enableSync = '1') and ((apptrig = '1') or (swTrigSync = '1')) then
               -- Set the trigger detected flag
               v.trigDet := '1';
               -- Write the data
               v.wrEn    := '1';
               -- Reset the counter
               v.wrAddr  := (others => '0');
               -- Latch the valid values
               v.valid   := appValid;
               -- Next state
               v.state   := WRITE_RAM_S;
            end if;
         ----------------------------------------------------------------------
         when WRITE_RAM_S =>
            -- Write the data
            v.wrEn   := '1';
            -- Increment the counter
            v.wrAddr := r.wrAddr + 1;
            -- Check the valid flags
            for i in NUM_CH_G-1 downto 0 loop
               -- Check for valid missing gap
               if (appValid(i) = '0') then
                  -- Latch the error
                  v.valid(i) := '0';
               end if;
            end loop;
            -- Check for max. count
            if (v.wrAddr = MAX_CNT_C) then
               -- Set the request flag
               v.req   := '1';
               -- Next state
               v.state := HAND_SHAKE_S;
            end if;
         ----------------------------------------------------------------------
         when HAND_SHAKE_S =>
            -- Wait for the ACK flag
            if (ackSync = '1') then
               -- Next state
               v.state := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (appRst = '1') or (axisRstSync = '1') then
         v := REG_INIT_C;
      end if;

      -- Help with timing
      v.wrData := appData;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      wrEn   <= r.wrEn;
      wrAddr <= r.wrAddr;
      wrData <= r.wrData;

   end process comb;

   seq : process (appClk) is
   begin
      if (rising_edge(appClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_RstSync : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => appClk,
         asyncRst => axisRst,
         syncRst  => axisRstSync);

   U_SyncEnable : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => appClk,
         dataIn  => enable,
         dataOut => enableSync);

   U_SyncSwTrig : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => appClk,
         dataIn  => swTrig,
         dataOut => swTrigSync);

   U_SyncTrigDet : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => timingClk,
         dataIn  => r.trigDet,
         dataOut => trigDetSync);

   U_SyncTrigTimestamp : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 64)
      port map (
         -- Asynchronous Reset
         rst    => timingRst,
         -- Write Ports (wr_clk domain)
         wr_clk => timingClk,
         wr_en  => trigDetSync,
         din    => timingTimestamp,
         -- Read Ports (rd_clk domain)
         rd_clk => axisClk,
         dout   => timestamp);

   U_SyncOut : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => NUM_CH_G)
      port map (
         -- Asynchronous Reset
         rst    => axisRst,
         -- Write Ports (wr_clk domain)
         wr_clk => appClk,
         wr_en  => r.req,
         din    => r.valid,
         -- Read Ports (rd_clk domain)
         rd_clk => axisClk,
         valid  => req,
         dout   => valid);

   U_SyncIn : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => appClk,
         dataIn  => ack,
         dataOut => ackSync);

end mapping;
