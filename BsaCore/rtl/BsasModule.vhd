-----------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 Timing Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.EthMacPkg.all;
use surf.SsiPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;
use amc_carrier_core.BsasPkg.all;

entity BsasModule is

   generic (
      TPD_G       : time    := 1 ns;
      SVC_G       : integer := 0;   -- Index of EDEF
      BASE_ADDR_G : slv(31 downto 0) := x"00000000" );
   port (
      -- Diagnostic data interface
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;
      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Timing ETH MSG Interface (axilClk domain)
      obEthMsgMaster  : out AxiStreamMasterType;
      obEthMsgSlave   : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_INIT_C);

end entity BsasModule;

architecture rtl of BsasModule is

   constant INT_STREAM_CONFIG_C : AxiStreamConfigType := (
     TSTRB_EN_C    => false,
     TDATA_BYTES_C => 24,
     TDEST_BITS_C  => EMAC_AXIS_CONFIG_C.TDEST_BITS_C,
     TID_BITS_C    => EMAC_AXIS_CONFIG_C.TID_BITS_C,
     TKEEP_MODE_C  => EMAC_AXIS_CONFIG_C.TKEEP_MODE_C,
     TUSER_BITS_C  => EMAC_AXIS_CONFIG_C.TUSER_BITS_C,
     TUSER_MODE_C  => EMAC_AXIS_CONFIG_C.TUSER_MODE_C );

   signal config : BsasConfigType;
   signal csync  : BsasConfigType;
   signal cv, csyncv : slv(BSAS_CONFIG_BITS_C-1 downto 0);

   constant NCHAN_C : integer := BSA_DIAGNOSTIC_OUTPUTS_C;

   type StateType is (IDLE_S, HEADER_S, DATA_S, FORWARD_S, SINK_S);

   type RegType is record
      state          : StateType;
      init           : sl;
      count          : slv ( 3 downto 0);
      row            : slv (15 downto 0);
      rowStarted     : sl;
      rowTimestamp   : slv (63 downto 0);
      rowPulseId     : slv (63 downto 0);
      header         : Slv64Array(2 downto 0);
      strobe         : sl;
      acquire        : sl;
      sample         : sl;
      flush          : sl;
      diagnosticData : Slv32Array(NCHAN_C-1 downto 0);
      diagnosticSevr : slv (NCHAN_C-1 downto 0);
      diagnosticFixd : slv (NCHAN_C-1 downto 0);
      dataSquare     : slv (47 downto 0);
      excSquare      : sl;
      accumulateEn   : sl;
      channel        : slv(5 downto 0);
      remaining      : slv(NCHAN_C-1 downto 0);
      master         : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state          => IDLE_S,
      init           => '0',
      count          => (others => '0'),
      row            => (others => '1'),
      rowStarted     => '0',
      rowTimestamp   => (others=>'0'),
      rowPulseId     => (others=>'0'),
      header         => (others=>(others=>'0')),
      strobe         => '0',
      acquire        => '0',
      sample         => '0',
      flush          => '0',
      diagnosticData => (others => (others => '0')),
      diagnosticSevr => (others => '0'),
      diagnosticFixd => (others => '0'),
      dataSquare     => (others => '0'),
      excSquare      => '0',
      accumulateEn   => '0',
      channel        => (others => '0'),
      remaining      => (others => '0'),
      master         => axiStreamMasterInit(INT_STREAM_CONFIG_C) );

   signal r    : RegType := REG_INIT_C;
   signal rin  : RegType;

   signal accAxisMaster : AxiStreamMasterType;
   signal accAxisSlave  : AxiStreamSlaveType;

   constant CROSSBAR_CONFIG : AxiLiteCrossbarMasterConfigArray(1 downto 0) :=
     genAxiLiteConfig(2,BASE_ADDR_G,11,10);

   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray (1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray  (1 downto 0);

   signal axilWriteRegs    : Slv32Array(3 downto 0);

   signal acquire, rowReset, rowAdvance : sl;
   signal trigRatesArray : SlVectorArray(2 downto 0,31 downto 0);
   signal trigRatesVec   : Slv32Array(2 downto 0);

   signal ready : sl;

begin

   U_AxiLiteXbar : entity surf.AxiLiteCrossbar
     generic map (
       NUM_SLAVE_SLOTS_G  => 1,
       NUM_MASTER_SLOTS_G => CROSSBAR_CONFIG'length,
       MASTERS_CONFIG_G   => CROSSBAR_CONFIG )
     port map (
       axiClk              => axilClk,
       axiClkRst           => axilRst,
       sAxiWriteMasters(0) => axilWriteMaster,
       sAxiWriteSlaves (0) => axilWriteSlave,
       sAxiReadMasters (0) => axilReadMaster,
       sAxiReadSlaves  (0) => axilReadSlave,
       mAxiWriteMasters    => axilWriteMasters,
       mAxiWriteSlaves     => axilWriteSlaves,
       mAxiReadMasters     => axilReadMasters,
       mAxiReadSlaves      => axilReadSlaves );

   U_Axil_Base : entity surf.AxiLiteRegs
     generic map (
       NUM_WRITE_REG_G => 4 )
     port map (
       axiClk         => axilClk,
       axiClkRst      => axilRst,
       axiWriteMaster => axilWriteMasters(0),
       axiWriteSlave  => axilWriteSlaves (0),
       axiReadMaster  => axilReadMasters (0),
       axiReadSlave   => axilReadSlaves  (0),
       writeRegister  => axilWriteRegs);

   config.enable      <= axilWriteRegs(0)(0);
   config.channelMask <= resize(axilWriteRegs(1),NCHAN_C);
   config.channelSevr <= axilWriteRegs(3) & axilWriteRegs(2);

   U_Axil_Evr : entity lcls_timing_core.EvrV2ChannelReg
     generic map (
       NCHANNELS_G => 3 )
     port map (
       axiClk          => axilClk,
       axiRst          => axilRst,
       axilWriteMaster => axilWriteMasters(1),
       axilWriteSlave  => axilWriteSlaves (1),
       axilReadMaster  => axilReadMasters (1),
       axilReadSlave   => axilReadSlaves  (1),
       channelConfig   => config.channels,
       eventCount      => trigRatesVec );

   U_FIFO : entity surf.AxiStreamFifoV2
     generic map ( FIFO_ADDR_WIDTH_G   => 11,
                   FIFO_PAUSE_THRESH_G => 1024,
                   VALID_THOLD_G       => 0,   -- only when a full frame is ready
                   SLAVE_AXI_CONFIG_G  => INT_STREAM_CONFIG_C,
                   MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C )
     port map ( sAxisClk     => diagnosticClk,
                sAxisRst     => diagnosticRst,
                sAxisMaster  => r.master,
                sAxisSlave   => open,
                sAxisCtrl    => open,
                mAxisClk     => axilClk,
                mAxisRst     => axilRst,
                mAxisMaster  => obEthMsgMaster,
                mAxisSlave   => obEthMsgSlave );

   U_Stats : entity amc_carrier_core.BsasAccumulator
     generic map (
       TPD_G          => TPD_G,
       NUM_CHANNELS_G => NCHAN_C,
       AXIS_CONFIG_G  => INT_STREAM_CONFIG_C )
     port map (
       clk            => diagnosticClk,
       rst            => diagnosticRst,
       valid          => r.accumulateEn,
       acquire        => r.acquire,
       sample         => r.sample,
       flush          => r.flush,
       diagnosticData => r.diagnosticData(NCHAN_C-1),          -- [in]
       diagnosticSqr  => r.dataSquare,                                   -- [in]
       diagnosticFixd => r.diagnosticFixd(NCHAN_C-1),          -- [in]
       diagnosticSevr => r.diagnosticSevr(NCHAN_C-1),          -- [in]
       diagnosticExc  => r.excSquare,                                    -- [in]
       ready          => ready,
       axisMaster     => accAxisMaster,
       axisSlave      => accAxisSlave );

   U_SyncConfig : entity surf.SynchronizerVector
     generic map (
       WIDTH_G => BSAS_CONFIG_BITS_C )
     port map (
       clk     => diagnosticClk,
       dataIn  => cv,
       dataOut => csyncv );

   cv    <= toSlv(config);
   csync <= toBsasConfigType(csyncv);

   -- Signal to latch data for this pulse
   U_Acquire : entity lcls_timing_core.EvrV2EventSelect
     port map (
       clk       => diagnosticClk,
       rst       => diagnosticRst,
       config    => csync.channels(0),
       strobeIn  => diagnosticBus.strobe,
       dataIn    => diagnosticBus.timingMessage,
       selectOut => acquire );

   -- Signal to flush the row previously accumulated
   U_RowAdvance : entity lcls_timing_core.EvrV2EventSelect
     port map (
       clk       => diagnosticClk,
       rst       => diagnosticRst,
       config    => csync.channels(1),
       strobeIn  => diagnosticBus.strobe,
       dataIn    => diagnosticBus.timingMessage,
       selectOut => rowAdvance );

   -- Signal to reset the row number
   U_RowReset : entity lcls_timing_core.EvrV2EventSelect
     port map (
       clk       => diagnosticClk,
       rst       => diagnosticRst,
       config    => csync.channels(2),
       strobeIn  => diagnosticBus.strobe,
       dataIn    => diagnosticBus.timingMessage,
       selectOut => rowReset );

   U_AcquireRate : entity surf.SyncTrigRateVector
     generic map (
       COMMON_CLK_G   => true,
       ONE_SHOT_G     => true,
       REF_CLK_FREQ_G => 156.25E+6,
       WIDTH_G        => 3 )
     port map (
       trigIn(0)      => acquire,
       trigIn(1)      => rowAdvance,
       trigIn(2)      => rowReset,
       trigRateOut    => trigRatesArray,
       locClk         => axilClk,
       refClk         => axilClk );

   trigRatesVec(0) <= muxSlVectorArray(trigRatesArray,0);
   trigRatesVec(1) <= muxSlVectorArray(trigRatesArray,1);
   trigRatesVec(2) <= muxSlVectorArray(trigRatesArray,2);

   comb: process(r, diagnosticRst, diagnosticBus, acquire, rowAdvance, rowReset, csync,
                 accAxisMaster, ready) is
     variable v       : RegType;
     variable start   : sl;
     variable advance : sl;
     variable sample  : sl;
     variable ichan   : integer;
   begin
     v := r;

     ichan := conv_integer(r.channel);

     v.strobe        := diagnosticBus.strobe;

     --  Not the usual axi-stream master/slave handshake
     --  We're on a fixed schedule, so can't handle backpressure
     v.master.tValid := '0';
     v.master.tLast  := '0';
     ssiSetUserSof ( INT_STREAM_CONFIG_C, v.master, '0' );
     ssiSetUserEofe( INT_STREAM_CONFIG_C, v.master, '0' );

     if ready = '1' then
       v.accumulateEn := '0';
     end if;

     start   := '0';
     advance := '0';
     sample  := '0';

     --
     --  States:
     --    HEADER_S : write row header before sending old data and
     --               processing new data
     --    DATA_S : r.flush (stream data out and reset)
     --             r.acquire ( accumulate stats )
     --             r.sample  ( and latch one sample data )
     case r.state is
       when IDLE_S => -- Wait for diagnostic strobe, check for acquire/advance
         if r.strobe = '1' then -- triggers are valid
           -- capture them
           v.acquire := acquire;
           v.sample  := '0';
           v.flush   := rowAdvance or rowReset;
           v.channel := (others=>'0');
           v.remaining := resize(csync.channelMask,NCHAN_C);
           if r.init = '0' then
             -- uninitialized
             if rowReset = '0' then
               -- still uninitialized
               v.state := IDLE_S;
             else -- rowReset
               -- first row ever
               v.init   := '1';
               v.flush  := '1';  -- zero and sink
               start    := '1';
               sample   := '1';
               v.state  := DATA_S;
             end if; -- rowReset
           else -- r.init
             if (rowReset = '1' or rowAdvance = '1') and r.rowStarted = '1' then
               -- (1<<31) | 11 rsvd | 4b table id | 16b row number
               v.header(2) := '1' & toSlv(0,7) & toSlv(SVC_G,4) & r.count &
                              r.row & resize(csync.channelMask,32);
               v.header(1) := r.rowPulseId;
               v.header(0) := r.rowTimestamp;
               v.row     := r.row + 1;
               sample    := '1';
               v.state   := HEADER_S;
             else
               if r.rowStarted = '0' then
                 sample  := '1';
               end if;
               start   := '1';
               v.state := DATA_S;
             end if;
           end if; -- r.init
           if rowReset = '1' then
             v.count := r.count+1;
             v.row   := (others=>'0');
           end if;
         end if; -- r.strobe
       when HEADER_S => -- Shift header into FIFO
         ssiSetUserSof ( INT_STREAM_CONFIG_C, v.master, '1' );
         v.master.tValid              := r.rowStarted;
         v.master.tData(191 downto 0) := r.header(2) & r.header(1) & r.header(0);
         start                        := '1';
         v.state                      := DATA_S;
       when DATA_S   => -- Shift data into FIFO
         if (v.accumulateEn = '0') then
           if r.channel = NCHAN_C then
             if r.flush = '1' then
               v.rowStarted := '0';
             end if;
             if r.acquire = '1' then
               v.rowStarted := '1';
             end if;
             v.state := IDLE_S;
           else
             v.accumulateEn := '1';
             advance := '1';
             if (r.flush = '1') then
               if (r.rowStarted = '1' and csync.channelMask(ichan)='1') then
                 v.remaining(ichan) := '0';
                 v.state := FORWARD_S;
               else
                 v.state := SINK_S;
               end if;
             end if;
           end if;
         end if;
       when FORWARD_S =>
         v.master := accAxisMaster;
         if accAxisMaster.tValid = '1' and accAxisMaster.tLast = '1' then
           -- repeat for remaining channels
           v.state := DATA_S;
           if r.remaining /= 0 then
             v.master.tLast := '0';
           end if;
         end if;
       when SINK_S =>
         if accAxisMaster.tValid = '1' and accAxisMaster.tLast = '1' then
           -- repeat for remaining channels
           v.state := DATA_S;
         end if;
     end case;

     if sample = '1' and acquire = '1' then
       -- capture the sample, timestamp
       v.sample       := '1';  -- latch the first sample in a row
       v.rowTimestamp := diagnosticBus.timingMessage.timeStamp;
       v.rowPulseId   := diagnosticBus.timingMessage.pulseId;
     end if;

     ----------------------------------------------------------------------------------------------
     -- Accumulation stage - shift new diagnostic data through the accumulators
     ----------------------------------------------------------------------------------------------
     if advance = '1' then

       v.channel := r.channel + 1;

       v.diagnosticData := r.diagnosticData(0) & r.diagnosticData(r.diagnosticData'left downto 1);
       v.diagnosticSevr := r.diagnosticSevr(0) & r.diagnosticSevr(r.diagnosticSevr'left downto 1);
       v.diagnosticFixd := r.diagnosticFixd(0) & r.diagnosticFixd(r.diagnosticFixd'left downto 1);

       v.dataSquare := x"000" &
                       slv(signed(r.diagnosticData(0)(17 downto 0))*
                           signed(r.diagnosticData(0)(17 downto 0)));
       if (allBits(r.diagnosticData(0)(31 downto 17), '0') or
           allBits(r.diagnosticData(0)(31 downto 17), '1')) then
         v.excSquare := '0';
       else
         v.excSquare := '1';
       end if;

     end if;

     ----------------------------------------------------------------------------------------------
     -- Synchronization
     -- Wait for synchronized strobe signal, then latch the timing message onto the local clock
     ----------------------------------------------------------------------------------------------
     if start = '1' then
       --  Channel data
       v.dataSquare := x"000" &
                       slv(signed(diagnosticBus.data(0)(17 downto 0)) *
                           signed(diagnosticBus.data(0)(17 downto 0)));
       if (allBits(diagnosticBus.data(0)(31 downto 17), '0') or
           allBits(diagnosticBus.data(0)(31 downto 17), '1')) then
         v.excSquare := '0';
       else
         v.excSquare := '1';
       end if;

       v.diagnosticData(NCHAN_C-1 downto 0) := diagnosticBus.data (NCHAN_C-1 downto 0);
       v.diagnosticFixd(NCHAN_C-1 downto 0) := diagnosticBus.fixed(NCHAN_C-1 downto 0);

       for i in 0 to NCHAN_C-1 loop
         if diagnosticBus.sevr(i) <= csync.channelSevr(i*2+1 downto i*2) then
           v.diagnosticSevr(i) := '0';
         else
           v.diagnosticSevr(i) := '1';
         end if;
       end loop;

       v.channel    := (others => '0');
     end if;

     if diagnosticRst = '1' then
       v := REG_INIT_C;
     end if;

     rin <= v;
   end process comb;

   seq: process(diagnosticClk) is
   begin
     if rising_edge(diagnosticClk) then
       r <= rin after TPD_G;
     end if;
   end process;

end rtl;
