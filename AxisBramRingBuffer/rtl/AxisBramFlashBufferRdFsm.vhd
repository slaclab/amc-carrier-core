-------------------------------------------------------------------------------
-- File       : AxisBramFlashBufferRdFsm.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-04-10
-- Last update: 2018-04-20
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.EthMacPkg.all;

entity AxisBramFlashBufferRdFsm is
   generic (
      TPD_G              : time     := 1 ns;
      NUM_CH_G           : positive := 1;
      AXIS_TDATA_WIDTH_G : positive := 16;  -- units of bytes      
      BUFFER_WIDTH_G     : positive := 8);  -- units of bits
   port (
      -- Write FSM Interface (axisClk domain)
      req        : in  sl;
      valid      : in  slv(NUM_CH_G-1 downto 0);
      timestamp  : in  slv(63 downto 0);
      ack        : out sl;
      -- Ram Interface (axisClk domain)
      rdAddr     : out slv(BUFFER_WIDTH_G-1 downto 0);
      rdData     : in  Slv32Array(NUM_CH_G-1 downto 0);
      -- Software Interface (axilClk domain)
      axilClk    : in  sl;
      axilRst    : in  sl;
      tDest      : in  Slv8Array(NUM_CH_G-1 downto 0);
      -- AXI Stream Interface (axisClk domain)
      axisClk    : in  sl;
      axisRst    : in  sl;
      axisMaster : out AxiStreamMasterType;
      axisSlave  : in  AxiStreamSlaveType);
end AxisBramFlashBufferRdFsm;

architecture mapping of AxisBramFlashBufferRdFsm is

   constant SLAVE_AXI_CONFIG_C  : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8);
   constant MASTER_AXI_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(AXIS_TDATA_WIDTH_G, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8);

   constant MAX_CNT_C : slv(BUFFER_WIDTH_G-1 downto 0) := (others => '1');

   type StateType is (
      IDLE_S,
      HDR_S,
      PAYLOAD_S);

   type RegType is record
      ack      : sl;
      rdLatecy : natural range 0 to 3;
      idx      : natural range 0 to NUM_CH_G-1;
      eventId  : slv(47 downto 0);
      rdAddr   : slv(BUFFER_WIDTH_G-1 downto 0);
      txMaster : AxiStreamMasterType;
      state    : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      ack      => '0',
      rdLatecy => 0,
      idx      => 0,
      eventId  => (others => '0'),
      rdAddr   => (others => '0'),
      txMaster => AXI_STREAM_MASTER_INIT_C,
      state    => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal txSlave : AxiStreamSlaveType;

   signal tDestSync : Slv8Array(NUM_CH_G-1 downto 0);

begin

   comb : process (axisRst, r, rdData, req, tDestSync, timestamp, txSlave,
                   valid) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.ack := '0';
      if txSlave.tReady = '1' then
         v.txMaster.tValid := '0';
         v.txMaster.tLast  := '0';
         v.txMaster.tUser  := (others => '0');
      end if;

      -- Decrement the counter
      if (r.rdLatecy /= 0) then
         v.rdLatecy := r.rdLatecy - 1;
      end if;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Wait for request
            if (req = '1') then
               -- Reset the counter
               v.idx     := 0;
               v.rdAddr  := (others => '0');
               -- Increment the counter
               v.eventId := r.eventId + 1;
               -- Next state
               v.state   := HDR_S;
            end if;
         ----------------------------------------------------------------------
         when HDR_S =>
            -- Check if ready to move data
            if (v.txMaster.tValid = '0') then
               -- Move data
               v.txMaster.tValid               := valid(r.idx);
               v.txMaster.tData(7 downto 0)    := x"00";  -- Version = 0x0
               v.txMaster.tData(15 downto 8)   := toSlv(r.idx, 8);  -- Channel Index
               v.txMaster.tData(63 downto 16)  := r.eventId;        -- Event ID
               v.txMaster.tData(127 downto 64) := timestamp;
               -- Set the tDest field
               v.txMaster.tDest                := tDestSync(r.idx);
               -- Set SOF bit
               ssiSetUserSof(SLAVE_AXI_CONFIG_C, v.txMaster, '1');
               -- Next state
               v.state                         := PAYLOAD_S;
            end if;
         ----------------------------------------------------------------------
         when PAYLOAD_S =>
            -- Check if ready to move data
            if (v.txMaster.tValid = '0') and (v.rdLatecy = 0) then
               -- Increment the counter
               v.rdAddr := r.rdAddr + 1;
               -- Check the counter               
               if v.rdAddr(1 downto 0) = "00" then
                  -- Update the data bus
                  v.txMaster.tData(31 downto 0) := rdData(r.idx);
               elsif v.rdAddr(1 downto 0) = "01" then
                  -- Update the data bus
                  v.txMaster.tData(63 downto 32) := rdData(r.idx);
               elsif v.rdAddr(1 downto 0) = "10" then
                  -- Update the data bus
                  v.txMaster.tData(95 downto 64) := rdData(r.idx);
               else
                  -- Update the data bus
                  v.txMaster.tData(95 downto 64) := rdData(r.idx);
                  -- Move data
                  v.txMaster.tValid              := valid(r.idx);
                  -- Check for max. count
                  if (v.rdAddr = MAX_CNT_C) then
                     -- Set the EOF bit
                     v.txMaster.tLast := '1';
                     -- Check for last channel 
                     if (r.idx = (NUM_CH_G-1)) then
                        -- Set the request flag
                        v.ack   := '1';
                        -- Next state
                        v.state := IDLE_S;
                     else
                        -- Increment the index counter
                        v.idx   := r.idx + 1;
                        -- Next state
                        v.state := HDR_S;
                     end if;
                  end if;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for change in BRAM read address
      if (r.rdAddr /= v.rdAddr) then
         v.rdLatecy := 3;               -- read in 3 cycles
      end if;

      -- Synchronous Reset
      if (axisRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      ack    <= r.ack;
      rdAddr <= r.rdAddr;

   end process comb;

   seq : process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   GEN_SYNC : for i in NUM_CH_G-1 downto 0 generate
      U_SyncTdest : entity work.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 8)
         port map (
            clk     => axisClk,
            dataIn  => tDest(i),
            dataOut => tDestSync(i));
   end generate GEN_SYNC;

   GEN_RESIZE : if (AXIS_TDATA_WIDTH_G /= 16) generate
      U_Resize : entity work.AxiStreamResize
         generic map (
            TPD_G               => TPD_G,
            READY_EN_G          => true,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => SLAVE_AXI_CONFIG_C,
            MASTER_AXI_CONFIG_G => MASTER_AXI_CONFIG_C)
         port map (
            -- Clock and reset
            axisClk     => axisClk,
            axisRst     => axisRst,
            -- Slave Port
            sAxisMaster => r.txMaster,
            sAxisSlave  => txSlave,
            -- Master Port
            mAxisMaster => axisMaster,
            mAxisSlave  => axisSlave);
   end generate;

   BYP_RESIZE : if (AXIS_TDATA_WIDTH_G = 16) generate
      axisMaster <= r.txMaster;
      txSlave    <= axisSlave;
   end generate;

end mapping;
