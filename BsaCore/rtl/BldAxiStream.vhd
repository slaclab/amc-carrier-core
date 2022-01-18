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
use ieee.std_logic_arith.all;

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
use amc_carrier_core.BldPkg.all;

entity BldAxiStream is

   generic (
      TPD_G       : time    := 1 ns;
      SVC_START_G : integer := 0;      -- Index of first EDEF
      NUM_EDEFS_G : integer := 1;      -- Num of EDEFs in stream
      BATCH_G     : boolean := true ); -- Batch events into fewer
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
      ibEthMsgMaster  : in  AxiStreamMasterType;
      ibEthMsgSlave   : out AxiStreamSlaveType;
      obEthMsgMaster  : out AxiStreamMasterType;
      obEthMsgSlave   : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_INIT_C);

end entity BldAxiStream;

architecture rtl of BldAxiStream is

   constant START_COUNT : slv(11 downto 0) := toSlv(960, 12);  -- MTU

   type BldConfigType is record
      enable      : sl;
      channelMask : slv (BSA_DIAGNOSTIC_OUTPUTS_C-1 downto 0);
      channelSevr : slv (63 downto 0);
      packetSize  : slv (11 downto 0);
      edefConfig  : EdefConfigArray(NUM_EDEFS_G-1 downto 0);
   end record;

   constant BLD_CONFIG_INIT_C : BldConfigType := (
      enable      => '0',
      channelMask => (others => '0'),
      channelSevr => (others => '0'),
      packetSize  => START_COUNT,
      edefConfig  => (others=>EDEF_CONFIG_INIT_C) );

   constant BLD_CONFIG_BITS_C : integer := BSA_DIAGNOSTIC_OUTPUTS_C + 77 + NUM_EDEFS_G*EDEF_CONFIG_BITS_C;

   function toSlv(r : BldConfigType) return slv is
      variable v : slv(BLD_CONFIG_BITS_C-1 downto 0) := (others=>'0');
      variable i,j : integer := 0;
   begin
      assignSlv(i, v, r.enable);
      assignSlv(i, v, r.channelMask);
      assignSlv(i, v, r.channelSevr);
      assignSlv(i, v, r.packetSize);
      for j in 0 to NUM_EDEFS_G-1 loop
         assignSlv(i, v, toSlv(r.edefConfig(j)) );
      end loop;
      return v;
   end function;

   function toBldConfig(v : slv) return BldConfigType is
      variable c : BldConfigType;
      variable w : slv(EDEF_CONFIG_BITS_C-1 downto 0);
      variable i,j : integer := 0;
   begin
      assignRecord(i, v, c.enable);
      assignRecord(i, v, c.channelMask);
      assignRecord(i, v, c.channelSevr);
      assignRecord(i, v, c.packetSize);
      for j in 0 to NUM_EDEFS_G-1 loop
         w := v(i+EDEF_CONFIG_BITS_C-1 downto i);
         c.edefConfig(j) := toEdefConfig(w);
         i := i+EDEF_CONFIG_BITS_C;
      end loop;
      return c;
   end function;

   type StateType is (IDLE_S,
                      TSL_S , TSU_S,
                      PIDL_S, PIDU_S,
                      CHM_S , DELT_S,
                      SVC_S , CHD_S,
                      END_S , INVALID_S);

   type BldStatusType is record
      state      : StateType;
      vstate     : slv (3 downto 0);
      pulseIdL   : slv (19 downto 0);
      timeStampL : slv (31 downto 0);
      delta      : slv (31 downto 0);
      count      : slv (11 downto 0);
      pause      : sl;
      packets    : slv (19 downto 0);
     depth       : slv       ( 3 downto 0);
   end record;

   constant BLD_STATUS_INIT_C : BldStatusType := (
      state      => IDLE_S,
      vstate     => (others => '0'),
      pulseIdL   => (others => '0'),
      timeStampL => (others => '0'),
      delta      => (others => '0'),
      count      => START_COUNT,
      pause      => '1',
      packets    => (others => '0'),
      depth       => (others=>'0') );

   constant BLD_STATUS_BITS_C : integer := 125;

   function toSlv(r : BldStatusType) return slv is
      variable v : slv(BLD_STATUS_BITS_C-1 downto 0) := (others=>'0');
      variable i : integer := 0;
      variable s : slv(3 downto 0);
   begin
      case r.state is
         when IDLE_S    => s := x"0";
        when TSL_S     => s := x"1";
        when TSU_S     => s := x"2";
        when PIDL_S    => s := x"3";
        when PIDU_S    => s := x"4";
        when CHM_S     => s := x"5";
        when DELT_S    => s := x"6";
        when SVC_S     => s := x"7";
        when CHD_S     => s := x"8";
        when END_S     => s := x"9";
        when INVALID_S => s := x"A";
      end case;
      assignSlv(i, v, s);
      assignSlv(i, v, r.pulseIdL);
      assignSlv(i, v, r.timeStampL);
      assignSlv(i, v, r.delta);
      assignSlv(i, v, r.count);
      assignSlv(i, v, r.pause);
      assignSlv(i, v, r.packets);
      assignSlv(i, v, r.depth);
      return v;
   end function;

   function toBldStatus(v : slv) return BldStatusType is
      variable c : BldStatusType;
      variable i : integer := 0;
   begin
      assignRecord(i, v, c.vstate);
      assignRecord(i, v, c.pulseIdL);
      assignRecord(i, v, c.timeStampL);
      assignRecord(i, v, c.delta);
      assignRecord(i, v, c.count);
      assignRecord(i, v, c.pause);
      assignRecord(i, v, c.packets);
      assignRecord(i, v, c.depth);
      return c;
   end function;

   type AxilRegType is record
      config      : BldConfigType;
      axilWriteS  : AxiLiteWriteSlaveType;
      axilReadS   : AxiLiteReadSlaveType;
   end record;

   constant AXIL_REG_INIT_C : AxilRegType := (
      config      => BLD_CONFIG_INIT_C,
      axilWriteS  => AXI_LITE_WRITE_SLAVE_INIT_C,
      axilReadS   => AXI_LITE_READ_SLAVE_INIT_C );

   signal c     : AxilRegType := AXIL_REG_INIT_C;
   signal cin   : AxilRegType;

   signal csync : BldConfigType;
   signal cv, csyncv : slv(BLD_CONFIG_BITS_C-1 downto 0);

   signal ssync : BldStatusType;
   signal sv, ssyncv : slv(BLD_STATUS_BITS_C-1 downto 0);

   type RegType is record
      -- data
     strobe        : slv       ( 1 downto 0);
     timingMessage : TimingMessageType;
     svcMask       : slv       (31 downto 0);
     svcTs         : Slv2Array (NUM_EDEFS_G-1 downto 0);
     svcReady      : slv       (NUM_EDEFS_G-1 downto 0);   -- updated for r.strobe(1)
     channelId     : integer range 0 to BSA_DIAGNOSTIC_OUTPUTS_C;
     channelMaskL  : slv       (BSA_DIAGNOSTIC_OUTPUTS_C-1 downto 0);
     channelValid  : slv       (BSA_DIAGNOSTIC_OUTPUTS_C-1 downto 0);
     status        : BldStatusType;
     master        : AxiStreamMasterType;
   end record;
   constant REG_INIT_C : RegType := (
      strobe        => (others=>'0'),
      timingMessage => TIMING_MESSAGE_INIT_C,
      svcMask       => (others=>'0'),
      svcTs         => (others=>"00"),
      svcReady      => (others=>'1'),
      channelId     => 0,
      channelMaskL  => (others=>'0'),
      channelValid  => (others=>'0'),
      status        => BLD_STATUS_INIT_C,
      master        => AXI_STREAM_MASTER_INIT_C );

   signal r    : RegType := REG_INIT_C;
   signal rin  : RegType;

   signal intSlave    : AxiStreamSlaveType;
   signal intAxisCtrl : AxiStreamCtrlType;

   constant axiStreamConfig : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 4,
      TDEST_BITS_C  => 8,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 4,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

   signal sAxisMasters : AxiStreamMasterArray(1 downto 0);
   signal sAxisSlaves  : AxiStreamSlaveArray(1 downto 0);

   signal eventStrobe  : sl;
   signal eventSel     : slv(NUM_EDEFS_G-1 downto 0);
   signal eventSel0Q   : sl;

   signal diagnClkFreq    : slv(31 downto 0);
   signal diagnStrobeRate : slv(31 downto 0);
   signal eventSel0Rate   : slv(31 downto 0);

begin

   U_DIAGNCLKFREQ : entity surf.SyncClockFreq
     generic map ( REF_CLK_FREQ_G    => 156.25E+6,
                   CLK_LOWER_LIMIT_G => 180.0E+6,
                   CLK_UPPER_LIMIT_G => 220.0E+6 )
     port map ( freqOut    => diagnClkFreq,
                clkIn      => diagnosticClk,
                locClk     => axilClk,
                refClk     => axilClk );

   U_DIAGNSTRRATE : entity surf.SyncTrigRate
     generic map ( COMMON_CLK_G      => false,
                   REF_CLK_FREQ_G    => 156.25E+6 )
     port map ( trigIn     => diagnosticBus.strobe,
                trigRateOut=> diagnStrobeRate,
                locClk     => diagnosticClk,
                refClk     => axilClk );

   eventSel0Q <= eventSel(0) and eventStrobe;
   U_EVENTSELRATE : entity surf.SyncTrigRate
     generic map ( COMMON_CLK_G      => false,
                   REF_CLK_FREQ_G    => 156.25E+6 )
     port map ( trigIn     => eventSel0Q,
                trigRateOut=> eventSel0Rate,
                locClk     => diagnosticClk,
                refClk     => axilClk );

   axilReadSlave  <= cin.axilReadS;
   axilWriteSlave <= cin.axilWriteS;

   sAxisMasters(0) <= ibEthMsgMaster;
   ibEthMsgSlave   <= sAxisSlaves(0);

   U_FIFO : entity surf.AxiStreamFifoV2
     generic map ( FIFO_ADDR_WIDTH_G   => 11,
                   FIFO_PAUSE_THRESH_G => 1900,
                   VALID_THOLD_G       => 0,   -- only when a full frame is ready
                   SLAVE_AXI_CONFIG_G  => axiStreamConfig,
                   MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C )
     port map ( sAxisClk     => diagnosticClk,
                sAxisRst     => diagnosticRst,
                sAxisMaster  => r.master,
                sAxisSlave   => intSlave,
                sAxisCtrl    => intAxisCtrl,
                mAxisClk     => axilClk,
                mAxisRst     => axilRst,
                mAxisMaster  => sAxisMasters(1),
                mAxisSlave   => sAxisSlaves (1) );

   reg_comb: process(c, axilRst, ssync, axilReadMaster, axilWriteMaster,
                     diagnClkFreq, diagnStrobeRate, eventSel0Rate ) is
     variable v   : AxilRegType;
     variable ep  : AxiLiteEndPointType;
   begin
     v := c;

     -----------------------------
     -- Register access
     -----------------------------

     -- Start transaction block
     axiSlaveWaitTxn(ep, axilWriteMaster, axilReadMaster, v.axilWriteS, v.axilReadS);

     axiSlaveRegister(ep, x"000", 0, v.config.packetSize);
     axiSlaveRegister(ep, x"000",31, v.config.enable);
     axiSlaveRegister(ep, x"004", 0, v.config.channelMask);
     axiSlaveRegister(ep, x"008", 0, v.config.channelSevr(31 downto 0));
     axiSlaveRegister(ep, x"00C", 0, v.config.channelSevr(63 downto 32));
     axiSlaveRegisterR(ep, x"010", 0, ssync.count);
     axiSlaveRegisterR(ep, x"010",16, ssync.vstate);
     axiSlaveRegisterR(ep, x"014", 0, ssync.pulseIdL);
     axiSlaveRegisterR(ep, x"018", 0, ssync.timeStampL);
     axiSlaveRegisterR(ep, x"01C", 0, ssync.delta);
     axiSlaveRegisterR(ep, x"020", 0, ssync.packets);
     axiSlaveRegisterR(ep, x"020",31, ssync.pause);
     axiSlaveRegisterR(ep, x"024", 0, ssync.depth);
     axiSlaveRegisterR(ep, x"028", 0, diagnClkFreq);
     axiSlaveRegisterR(ep, x"02C", 0, diagnStrobeRate);
     axiSlaveRegisterR(ep, x"030", 0, eventSel0Rate);
     for i in 0 to NUM_EDEFS_G-1 loop
       axiSlaveRegister (ep, toSlv(64+i*8, 12),  0, v.config.edefConfig(i).rateSel);
       axiSlaveRegister (ep, toSlv(64+i*8, 12), 13, v.config.edefConfig(i).destSel);
       axiSlaveRegister (ep, toSlv(68+i*8, 12),  0, v.config.edefConfig(i).tsUpdate);
       axiSlaveRegister (ep, toSlv(68+i*8, 12), 31, v.config.edefConfig(i).enable);
     end loop;

     axiSlaveDefault (ep, v.axilWriteS, v.axilReadS);

     if axilRst = '1' then
       v := AXIL_REG_INIT_C;
     end if;

     cin <= v;
   end process;

   reg_seq: process(axilClk) is
   begin
     if rising_edge(axilClk) then
       c <= cin;
     end if;
   end process;

   cv    <= toSlv      (c.config);
   csync <= toBldConfig(csyncv);

   U_CSYNC : entity surf.SynchronizerVector
     generic map ( WIDTH_G => BLD_CONFIG_BITS_C )
     port map ( clk     => diagnosticClk,
                dataIn  => cv,
                dataOut => csyncv );

   sv    <= toSlv      (r.status);
   ssync <= toBldStatus(ssyncv);

   U_SSYNC : entity surf.SynchronizerVector
     generic map ( WIDTH_G => BLD_STATUS_BITS_C )
     port map ( clk     => axilClk,
                dataIn  => sv,
                dataOut => ssyncv );

   U_EVENTSEL : entity amc_carrier_core.BldEventSelect
     generic map ( NUM_EDEFS_G => NUM_EDEFS_G )
     port map ( clk       => diagnosticClk,
                rst       => diagnosticRst,
                config    => csync.edefConfig,
                strobeIn  => r.strobe(0),
                dataIn    => r.timingMessage,
                strobeOut => eventStrobe,
                selectOut => eventSel );

   comb: process(r, csync,
                 diagnosticRst, diagnosticBus, eventSel, eventStrobe,
                 intSlave, intAxisCtrl ) is
     variable v         : RegType;
     variable sevr      : Slv2Array(BSA_DIAGNOSTIC_OUTPUTS_C-1 downto 0);
     variable deltaPID  : slv(19 downto 0);
     variable deltaTS   : slv(31 downto 0);
     variable eventSelQ : slv(eventSel'range);
     variable j         : integer;
   begin
     if BATCH_G then
       eventSelQ := eventSel;
     else
       eventSelQ := eventSel and r.svcReady;
     end if;

     -- Dont start a new frame if not enough space in the fifo
     if intAxisCtrl.pause = '1' then
       eventSelQ := (others=>'0');
     end if;

     v := r;

     if diagnosticBus.strobe = '1' then
       v.timingMessage := diagnosticBus.timingMessage;
     end if;

     v.strobe := r.strobe(r.strobe'left-1 downto 0) & diagnosticBus.strobe;

     --  Reset svcReady when appropriate ts bits change
     if r.strobe(0) = '1' then
       for i in 0 to NUM_EDEFS_G-1 loop
         j := conv_integer(csync.edefConfig(i).tsUpdate);
         if r.svcTs(i) /= r.timingMessage.timeStamp(j+1 downto j) then
           v.svcReady(i) := '1';
         end if;
       end loop;
     end if;

     for i in 0 to BSA_DIAGNOSTIC_OUTPUTS_C-1 loop
       sevr(i) := csync.channelSevr(2*i+1 downto 2*i);
     end loop;

     if intSlave.tReady = '1' then
       v.master.tValid := '0';
     end if;

     if v.master.tValid = '0' then
       ssiSetUserSof ( axiStreamConfig, v.master, '0' );
       ssiSetUserEofe( axiStreamConfig, v.master, '0' );

       v.master.tValid := '1';
       v.master.tLast  := '0';

       case r.status.state is
         -- Full event header
         when TSL_S  => v.status.count              := csync.packetSize;
                        v.master.tData(31 downto 0) := r.timingMessage.timeStamp(31 downto 0);
                        v.status.timeStampL         := r.timingMessage.timeStamp(31 downto 0);
                        v.status.state              := TSU_S;
                        ssiSetUserSof( axiStreamConfig, v.master, '1' );
         when TSU_S  => v.master.tData(31 downto 0) := r.timingMessage.timeStamp(63 downto 32);
                        v.status.count              := r.status.count-1;
                        v.status.state              := PIDL_S;
         when PIDL_S => v.master.tData(31 downto 0) := r.timingMessage.pulseId  (31 downto 0);
                        v.status.count              := r.status.count-1;
                        v.status.pulseIdL           := r.timingMessage.pulseId  (19 downto 0);
                        v.status.state              := PIDU_S;
         when PIDU_S => v.master.tData(31 downto 0) := r.timingMessage.pulseId   (63 downto 32);
                        v.status.count              := r.status.count-1;
                        v.status.state              := CHM_S;
         when CHM_S  => v.master.tData(31 downto 0) := resize(r.channelMaskL,32);
                        v.status.count              := r.status.count-1;
                        v.status.state              := SVC_S;
         -- Reduced event header
         when DELT_S => v.master.tData(31 downto 0) := r.status.delta;
                        v.status.count              := r.status.count-1;
                        v.status.state              := SVC_S;
         when SVC_S  => v.master.tData(31 downto 0) := r.svcMask;
                        v.status.count              := r.status.count-1;
                        v.channelId                 := 0;
                        v.channelValid              := (others=>'0');
                        v.status.state              := CHD_S;
         -- Channel data
         when CHD_S  => if r.channelId < BSA_DIAGNOSTIC_OUTPUTS_C then
                          --  Only include channels in header's mask
                          v.master.tValid := '0';
                          v.channelId     := r.channelId + 1;
                          v.channelValid  := '0' & r.channelValid(r.channelValid'left downto 1);
                          if r.channelMaskL(r.channelId) = '1' then
                            v.master.tValid := '1';
                            v.master.tData(31 downto 0)  := diagnosticBus.data(r.channelId);
                            v.status.count               := r.status.count-1;
                            if diagnosticBus.sevr(r.channelId) <= sevr(r.channelId) then
                              v.channelValid  := '1' & r.channelValid(r.channelValid'left downto 1);
                            end if;
                          end if;
                        else
                          v.master.tValid := '0';
                          v.status.state  := END_S;
                        end if;
         -- Event trailer: hold until next strobe; decide to append or open a new packet
         when END_S  => if not BATCH_G then
                          v.master.tData(31 downto 0) := resize(r.channelValid,32);
                          v.master.tLast              := '1';
                          v.status.packets            := r.status.packets + 1;
                          v.status.state              := IDLE_S;
                        elsif eventStrobe = '1' then
                          v.master.tData(31 downto 0) := resize(r.channelValid,32);
                          --
                          -- Check the duration and size of this frame
                          --
                          v.status.count  := r.status.count-1;
                          deltaPID := r.timingMessage.pulseId  (19 downto 0) - r.status.pulseIdL;
                          deltaTS  := r.timingMessage.timeStamp(31 downto 0) - r.status.timeStampL;
                          if (deltaTS (31 downto 20)/=0 or
                              r.status.count(r.status.count'left)='1') then
                            --  Close the packet and start a new one
                            v.master.tLast := '1';
                            v.status.packets := r.status.packets + 1;
                            if (eventSelQ = 0) then
                              v.status.state := IDLE_S;
                            else
                              v.status.state  := TSL_S;
                            end if;
                          elsif eventSelQ /= 0 then
                            --  Append to the current packet
                            v.svcMask(eventSelQ'left+SVC_START_G downto SVC_START_G) := eventSelQ;
                            v.status.delta := resize(deltaPID,12) & resize(deltaTS,20);
                            v.status.state := DELT_S;
                          else
                            --  Keep waiting
                            v.status.count  := r.status.count;
                            v.master.tValid := '0';
                          end if;
                        else
                          v.master.tValid := '0';
                        end if;
         when INVALID_S => v.master.tLast := '1';
                           ssiSetUserEofe( axiStreamConfig, v.master, '1' );
                           v.status.state := IDLE_S;
         when IDLE_S => v.master.tValid := '0';
                        if ( csync.enable = '1' and
                             eventStrobe  = '1' and
                             eventSelQ   /= 0 ) then
                          if not BATCH_G then
                            --  latch the EDEFs and start the timer
                            v.svcReady     := r.svcReady and not eventSelQ;
                            for i in 0 to NUM_EDEFS_G-1 loop
                              if eventSelQ(i)='1' then
                                j := conv_integer(csync.edefConfig(i).tsUpdate);
                                v.svcTs(i) := diagnosticBus.timingMessage.timeStamp(j+1 downto j);
                              end if;
                            end loop;
                          end if;
                          v.svcMask(eventSelQ'left+SVC_START_G downto SVC_START_G) := eventSelQ;
                          v.channelMaskL   := csync.channelMask;
                          v.status.state   := TSL_S;
                        end if;
       end case;

       --  Close prematurely if disable requested
       if ( csync.enable = '0' and v.status.state /= IDLE_S ) then
         v.status.state := INVALID_S;
       end if;


     --  Output FIFO refused to acknowledge data
     elsif (v.status.state /= IDLE_S) then
       v.status.state := INVALID_S;
     end if;

     if diagnosticRst = '1' then
       v := REG_INIT_C;
     end if;

     rin <= v;
   end process;

   seq: process(diagnosticClk) is
   begin
     if rising_edge(diagnosticClk) then
       r <= rin;
     end if;
   end process;

   U_Mux : entity surf.AxiStreamMux
     generic map ( NUM_SLAVES_G => 2 )
     port map ( axisClk      => axilClk,
                axisRst      => axilRst,
                sAxisMasters => sAxisMasters,
                sAxisSlaves  => sAxisSlaves,
                mAxisMaster  => obEthMsgMaster,
                mAxisSlave   => obEthMsgSlave );

end rtl;
