-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_19_CXX
------------------------------------------------------------------------------
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
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.EthMacPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

library amc_carrier_core;

entity RtmRfInterlockFaultBuffer is
   generic (
      TPD_G              : time                := 1 ns;
      BUFFER_ADDR_SIZE_G : natural             := 9;
      TDEST_G            : slv(7 downto 0)     := x"00";
      AXIS_CONFIG_G      : AxiStreamConfigType := EMAC_AXIS_CONFIG_C);
   port (
      -- AXI interface
      axiClk          : in  sl;
      axiRst          : in  sl;
      axiReadMasters  : in  AxiLiteReadMasterArray(1 downto 0);
      axiReadSlaves   : out AxiLiteReadSlaveArray(1 downto 0);
      axiWriteMasters : in  AxiLiteWriteMasterArray(1 downto 0);
      axiWriteSlaves  : out AxiLiteWriteSlaveArray(1 downto 0);
      -- RTM interface
      clk             : in  sl;
      rst             : in  sl := '0';
      fault           : in  sl;
      trig            : in  sl;
      timestamp       : in  slv(63 downto 0);
      streamEnable    : in  sl;
      bufferData      : Slv32Array(1 downto 0);
      writePointer    : out slv(BUFFER_ADDR_SIZE_G+2-1 downto 0);
      timestampBuffer : out Slv64Array(3 downto 0);
      -- AXI Stream Interface (axisClk domain)
      axisClk         : in  sl;
      axisRst         : in  sl;
      axisMaster      : out AxiStreamMasterType;
      axisSlave       : in  AxiStreamSlaveType);
end RtmRfInterlockFaultBuffer;

architecture mapping of RtmRfInterlockFaultBuffer is

   constant BRAM_SIZE_C        : natural := BUFFER_ADDR_SIZE_G + 2;  -- Fit x4 buffers
   constant MAX_PAGE_CNT_C     : unsigned(BUFFER_ADDR_SIZE_G - 1 downto 0) := (others => '1');

   constant AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8);  -- 64-bit AXIS interface

   type StateType is (
       IDLE_S,
       FILL_S,
       SEND_PKT_S,
       FAULT_S);

   type RegType is record
       we           : sl;
       writePointer : unsigned(BRAM_SIZE_C - 1 downto 0);
       timestamp    : Slv64Array(3 downto 0);
       txMaster     : AxiStreamMasterType;
       state        : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      we           => '0',
      writePointer => (others => '0'),
      timestamp    => (others => (others => '0')),
      txMaster     => AXI_STREAM_MASTER_INIT_C,
      state        => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal txCtrl           : AxiStreamCtrlType;
   signal streamData       : Slv32Array(1 downto 0) := (others => (others => '0'));
   signal faultSync        : sl := '0';
   signal streamEnableSync : sl := '0';
   signal trigOs           : sl := '0';

begin

   U_SYNC_OS_TRIG : entity surf.SynchronizerOneShot
      generic map (
         TPD_G   => TPD_G)
      port map (
         clk     => clk,
	 dataIn  => trig,
	 dataOut => trigOs);

   U_SYNC_FAULT : entity surf.Synchronizer
      generic map (
         TPD_G   => TPD_G)
      port map (
         clk     => clk,
         dataIn  => fault,
         dataOut => faultSync);

   U_SYNC_EN : entity surf.Synchronizer
      generic map (
         TPD_G   => TPD_G)
      port map (
         clk     => clk,
         dataIn  => streamEnable,
         dataOut => streamEnableSync);

   GEN_RING_BUF : for i in 1 downto 0 generate
      U_RAM : entity surf.AxiDualPortRam
         generic map (
            TPD_G         => TPD_G,
            MEMORY_TYPE_G => "block",
            AXI_WR_EN_G   => false,
            SYS_WR_EN_G   => true,
            DATA_WIDTH_G  => 32,
            ADDR_WIDTH_G  => BRAM_SIZE_C)
         port map (
            axiClk         => axiClk,
            axiRst         => axiRst,
            axiReadMaster  => axiReadMasters(i),
            axiReadSlave   => axiReadSlaves(i),
            axiWriteMaster => axiWriteMasters(i),
            axiWriteSlave  => axiWriteSlaves(i),
            -- Standard port
            clk            => clk,
            we             => r.we,
            addr           => std_logic_vector(r.writePointer),
            din            => bufferData(i));
   end generate GEN_RING_BUF;


   -- Small OB FIFO
   U_ObFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,  -- Using pause flow control
         VALID_THOLD_G       => 0,      -- 0 = store then forward the packet
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1,
         INT_WIDTH_SELECT_G  => "CUSTOM", -- Enforcing a fixed width (not auto-selected from widest bus)
         INT_DATA_WIDTH_G    => 8, -- Enforcing 64-bit (8 byte) wide internal bus
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_G)
      port map (
         -- Slave Interface
         sAxisClk    => clk,
         sAxisRst    => rst,
         sAxisMaster => r.txMaster,
         sAxisCtrl   => txCtrl,
         -- Master Interface
         mAxisClk    => axisClk,
         mAxisRst    => axisRst,
         mAxisMaster => axisMaster,
         mAxisSlave  => axisSlave);

comb : process(trigOs, faultSync, txCtrl, timestamp, streamEnableSync, r) is
   variable v   : RegType;
   variable idx : natural;
begin
   -- Latch the current value
   v := r;

   idx := to_integer(r.writePointer(BUFFER_ADDR_SIZE_G - 1 downto 0));

   v.txMaster.tDest  := TDEST_G;
   v.txMaster.tValid := '0';
   v.txMaster.tLast  := '0';

   case (r.state) is
      when IDLE_S  =>
         if (faultSync = '1') then
            -- send packet letting SW know about fault
            if (streamEnableSync = '1') then
               v.state := SEND_PKT_S;
            else
               v.state := FAULT_S;
            end if;
         elsif (trigOs = '1') then
            v.txMaster.tData(63 downto 0) := timestamp;
            v.timestamp(idx)              := timestamp;
            v.we    := '1';
            v.state := FILL_S;
         end if;
          
      when FILL_S  =>
         v.writePointer := r.writePointer + 1;
         if r.writePointer(BUFFER_ADDR_SIZE_G - 1 downto 0) = MAX_PAGE_CNT_C then
             v.we    := '0';
             v.state := IDLE_S;
         else
             v.we    := '1';
         end if;

      when SEND_PKT_S =>
         -- tData latched when triggered
         -- wait here until FIFO is ready to accept data
         if (txCtrl.pause = '0') then
            v.txMaster.tValid := '1';
            v.txMaster.tlast  := '1';
            ssiSetUserSof(AXIS_CONFIG_C, v.txMaster, '1');
            v.state := FAULT_S;
          end if;

      when FAULT_S =>
         -- Don't return to IDLE_S until fault is clear
         if (faultSync = '0') then
            v.state := IDLE_S;
         end if;

      when others  =>
          v.state := IDLE_S;
          
   end case;

-- Register the variable for the next clock cycle
   rin <= v;

-- outputs
   writePointer    <= std_logic_vector(r.writePointer);
   timestampBuffer <= r.timestamp;

end process comb;

seq : process(clk) is
begin
   if (rising_edge(clk)) then
      r <= rin after TPD_G;
   end if;
end process seq;

end mapping;
