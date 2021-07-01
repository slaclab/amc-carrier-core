-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application MPS SALT PHY Wrapper
-------------------------------------------------------------------------------
-- Note: Do not forget to configure the ATCA crate to drive the clock from the slot#2 MPS link node
-- For the 7-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
-- For the 16-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;
use amc_carrier_core.AppMpsPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsSalt is
   generic (
      TPD_G        : time    := 1 ns;
      SIMULATION_G : boolean := false;
      APP_TYPE_G   : AppType := APP_NULL_TYPE_C;
      MPS_SLOT_G   : boolean := false);
   port (
      -- SALT Reference clocks
      mps125MHzClk    : in  sl;
      mps125MHzRst    : in  sl;
      mps312MHzClk    : in  sl;
      mps312MHzRst    : in  sl;
      mps625MHzClk    : in  sl;
      mps625MHzRst    : in  sl;
      mpsPllLocked    : in  sl;
      mpsPllRst       : out sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- MPS Interface
      mpsIbClk        : in  sl;
      mpsIbRst        : in  sl;
      mpsIbMaster     : in  AxiStreamMasterType;
      mpsIbSlave      : out AxiStreamSlaveType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk   : in  sl;
      diagnosticRst   : in  sl;
      diagnosticBus   : in  DiagnosticBusType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- MPS Interface
      mpsObMasters    : out AxiStreamMasterArray(14 downto 0);
      mpsObSlaves     : in  AxiStreamSlaveArray(14 downto 0);
      ----------------
      -- Core Ports --
      ----------------
      -- Backplane MPS Ports
      mpsBusRxP       : in  slv(14 downto 1);
      mpsBusRxN       : in  slv(14 downto 1);
      mpsTxP          : out sl;
      mpsTxN          : out sl);
end AppMpsSalt;

architecture mapping of AppMpsSalt is

   constant STATUS_SIZE_C : natural := 15;

   type RegType is record
      cntRst         : sl;
      mpsPllRst      : sl;
      mpsPktCnt      : Slv32Array(14 downto 0);
      mpsErrCnt      : Slv32Array(14 downto 0);
      mpsChEnable    : slv(14 downto 0);
      srobeCnt       : slv(31 downto 0);
      rollOverEn     : slv(STATUS_SIZE_C-1 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cntRst         => '1',
      mpsPllRst      => '0',
      rollOverEn     => (others => '0'),
      mpsPktCnt      => (others => (others => '0')),
      mpsErrCnt      => (others => (others => '0')),
      mpsChEnable    => (others => '0'),  -- Disable all channels by default
      srobeCnt       => (others => '0'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal iDelayCtrlRdy : sl;

   signal mpsTxLinkUp  : sl;
   signal txPktSent    : sl;
   signal mpsTxPktSent : sl;

   signal txEofeSent    : sl;
   signal mpsTxEofeSent : sl;

   signal mpsReset    : slv(14 downto 1);
   signal mpsRst      : slv(14 downto 1);
   signal mpsChRst    : slv(14 downto 1);
   signal mpsRxLinkUp : slv(14 downto 1);

   signal rxPktRcvd    : slv(14 downto 1);
   signal mpsRxPktRcvd : slv(14 downto 1);

   signal rxErrDet    : slv(14 downto 1);
   signal mpsRxErrDet : slv(14 downto 1);

   signal statusOut : slv(STATUS_SIZE_C-1 downto 0);
   signal cntOut    : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);

   signal diagnosticstrobe : sl;

   signal pktPeriod    : Slv32Array(14 downto 0);
   signal pktPeriodMax : Slv32Array(14 downto 0);
   signal pktPeriodMin : Slv32Array(14 downto 0);

begin

   U_diagnosticstrobe : entity surf.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => diagnosticBus.strobe,
         dataOut => diagnosticstrobe);

   APP_UNDEFINED : if (APP_TYPE_G = APP_NULL_TYPE_C) generate

      mpsTxLinkUp   <= '0';
      mpsTxPktSent  <= '0';
      mpsTxEofeSent <= '0';
      mpsRxLinkUp   <= (others => '0');
      mpsRxPktRcvd  <= (others => '0');
      mpsRxErrDet   <= (others => '0');
      mpsObMasters  <= (others => AXI_STREAM_MASTER_INIT_C);
      mpsIbSlave    <= AXI_STREAM_SLAVE_FORCE_C;

      U_OBUFDS : OBUFDS
         port map (
            I  => '0',
            O  => mpsTxP,
            OB => mpsTxN);

      GEN_VEC :
      for i in 14 downto 1 generate
         U_IBUFDS : IBUFDS
            generic map (
               DIFF_TERM => true)
            port map(
               I  => mpsBusRxP(i),
               IB => mpsBusRxN(i),
               O  => open);
      end generate GEN_VEC;

   end generate;

   APP_SLOT : if (MPS_SLOT_G = false) and (APP_TYPE_G /= APP_NULL_TYPE_C) generate

      mpsRxLinkUp  <= (others => '0');
      mpsRxPktRcvd <= (others => '0');
      mpsRxErrDet  <= (others => '0');
      mpsObMasters <= (others => AXI_STREAM_MASTER_INIT_C);

      U_SaltUltraScale : entity surf.SaltUltraScale
         generic map (
            TPD_G               => TPD_G,
            SIMULATION_G        => SIMULATION_G,
            TX_ENABLE_G         => true,   -- TX only
            RX_ENABLE_G         => false,  -- Not using RX path
            COMMON_TX_CLK_G     => false,
            COMMON_RX_CLK_G     => false,
            SLAVE_AXI_CONFIG_G  => MPS_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => MPS_AXIS_CONFIG_C)
         port map (
            -- TX Serial Stream
            txP           => mpsTxP,
            txN           => mpsTxN,
            -- RX Serial Stream
            rxP           => '0',          -- Not using RX path
            rxN           => '1',          -- Not using RX path
            -- Reference Signals
            clk125MHz     => mps125MHzClk,
            rst125MHz     => mps125MHzRst,
            clk312MHz     => mps312MHzClk,
            clk625MHz     => mps625MHzClk,
            iDelayCtrlRdy => '1',          -- Not using RX path
            linkUp        => mpsTxLinkUp,
            txPktSent     => txPktSent,
            txEofeSent    => txEofeSent,
            rxPktRcvd     => open,
            rxErrDet      => open,
            -- Slave Port
            sAxisClk      => mpsIbClk,
            sAxisRst      => mpsIbRst,
            sAxisMaster   => mpsIbMaster,
            sAxisSlave    => mpsIbSlave,
            -- Master Port
            mAxisClk      => axilClk,
            mAxisRst      => axilRst,
            mAxisMaster   => open,
            mAxisSlave    => AXI_STREAM_SLAVE_FORCE_C);

      U_mpsTxPktSent : entity surf.SynchronizerOneShot
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => axilClk,
            dataIn  => txPktSent,
            dataOut => mpsTxPktSent);

      U_mpsTxEofeSent : entity surf.SynchronizerOneShot
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => axilClk,
            dataIn  => txEofeSent,
            dataOut => mpsTxEofeSent);

      GEN_VEC :
      for i in 14 downto 1 generate
         U_IBUFDS : IBUFDS
            generic map (
               DIFF_TERM => true)
            port map(
               I  => mpsBusRxP(i),
               IB => mpsBusRxN(i),
               O  => open);
      end generate GEN_VEC;

   end generate;

   MPS_SLOT : if (MPS_SLOT_G = true) and (APP_TYPE_G /= APP_NULL_TYPE_C) generate

      U_SaltDelayCtrl : entity surf.SaltDelayCtrl
         generic map (
            TPD_G           => TPD_G,
            SIM_DEVICE_G    => "ULTRASCALE",
            IODELAY_GROUP_G => "MPS_IODELAY_GRP")
         port map (
            iDelayCtrlRdy => iDelayCtrlRdy,
            refClk        => mps625MHzClk,
            refRst        => mps625MHzRst);

      LN_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 1,
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => false,
            FIFO_ADDR_WIDTH_G   => 9,
            SLAVE_AXI_CONFIG_G  => MPS_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => MPS_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => mpsIbClk,
            sAxisRst    => mpsIbRst,
            sAxisMaster => mpsIbMaster,
            sAxisSlave  => mpsIbSlave,
            -- Master Port
            mAxisClk    => axilClk,
            mAxisRst    => axilRst,
            mAxisMaster => mpsObMasters(0),
            mAxisSlave  => mpsObSlaves(0));

      mpsTxLinkUp   <= '0';
      mpsTxPktSent  <= '0';
      mpsTxEofeSent <= '0';

      U_OBUFDS : OBUFDS
         port map (
            I  => '0',
            O  => mpsTxP,
            OB => mpsTxN);

      GEN_VEC :
      for i in 14 downto 1 generate
         U_SaltUltraScale : entity surf.SaltUltraScale
            generic map (
               TPD_G               => TPD_G,
               SIMULATION_G        => SIMULATION_G,
               TX_ENABLE_G         => false,
               RX_ENABLE_G         => true,
               COMMON_TX_CLK_G     => false,
               COMMON_RX_CLK_G     => false,
               SLAVE_AXI_CONFIG_G  => MPS_AXIS_CONFIG_C,
               MASTER_AXI_CONFIG_G => MPS_AXIS_CONFIG_C)
            port map (
               -- TX Serial Stream
               txP           => open,
               txN           => open,
               -- RX Serial Stream
               rxP           => mpsBusRxP(i),
               rxN           => mpsBusRxN(i),
               -- Reference Signals
               clk125MHz     => mps125MHzClk,
               rst125MHz     => mpsRst(i),
               clk312MHz     => mps312MHzClk,
               clk625MHz     => mps625MHzClk,
               iDelayCtrlRdy => iDelayCtrlRdy,
               linkUp        => mpsRxLinkUp(i),
               txPktSent     => open,
               txEofeSent    => open,
               rxPktRcvd     => rxPktRcvd(i),
               rxErrDet      => rxErrDet(i),
               -- Slave Port
               sAxisClk      => axilClk,
               sAxisRst      => axilRst,
               sAxisMaster   => AXI_STREAM_MASTER_INIT_C,
               sAxisSlave    => open,
               -- Master Port
               mAxisClk      => axilClk,
               mAxisRst      => mpsChRst(i),
               mAxisMaster   => mpsObMasters(i),
               mAxisSlave    => mpsObSlaves(i));

         mpsChRst(i) <= axilRst or not(r.mpsChEnable(i));
         mpsReset(i) <= mps125MHzRst or not(r.mpsChEnable(i));

         U_mpsRst : entity surf.RstSync
            generic map (
               TPD_G => TPD_G)
            port map (
               clk      => mps125MHzClk,
               asyncRst => mpsReset(i),
               syncRst  => mpsRst(i));

         U_mpsRxPktRcvd : entity surf.SynchronizerOneShot
            generic map (
               TPD_G => TPD_G)
            port map (
               clk     => axilClk,
               dataIn  => rxPktRcvd(i),
               dataOut => mpsRxPktRcvd(i));

         U_mpsRxErrDet : entity surf.SynchronizerOneShot
            generic map (
               TPD_G => TPD_G)
            port map (
               clk     => axilClk,
               dataIn  => rxErrDet(i),
               dataOut => mpsRxErrDet(i));

      end generate GEN_VEC;

   end generate;

   comb : process (axilReadMaster, axilRst, axilWriteMaster, cntOut,
                   diagnosticstrobe, mpsPllLocked, mpsRxErrDet, mpsRxPktRcvd,
                   mpsTxEofeSent, mpsTxPktSent, pktPeriod, pktPeriodMax,
                   pktPeriodMin, r, statusOut) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
      variable i      : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobe signals
      v.cntRst    := '0';
      v.mpsPllRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in STATUS_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(regCon, toSlv(4*i, 12), 0, muxSlVectorArray(cntOut, i));
         axiSlaveRegisterR(regCon, toSlv(((4*i)+128), 12), 0, r.mpsPktCnt(i));
         axiSlaveRegisterR(regCon, toSlv(((4*i)+256), 12), 0, r.mpsErrCnt(i));
         axiSlaveRegisterR(regCon, toSlv(((4*i)+384), 12), 0, pktPeriod(i));
         axiSlaveRegisterR(regCon, toSlv(((4*i)+512), 12), 0, pktPeriodMax(i));
         axiSlaveRegisterR(regCon, toSlv(((4*i)+640), 12), 0, pktPeriodMin(i));
      end loop;

      axiSlaveRegisterR(regCon, x"700", 0, statusOut);
      axiSlaveRegisterR(regCon, x"704", 0, ite(MPS_SLOT_G, x"00000001", x"00000000"));
      axiSlaveRegisterR(regCon, x"708", 0, APP_TYPE_G);
      axiSlaveRegisterR(regCon, x"714", 0, mpsPllLocked);
      axiSlaveRegisterR(regCon, x"718", 0, r.srobeCnt);

      -- Map the write registers
      axiSlaveRegister(regCon, x"FEC", 0, v.mpsChEnable);
      axiSlaveRegister(regCon, x"FF0", 0, v.rollOverEn);
      axiSlaveRegister(regCon, x"FF4", 0, v.cntRst);
      axiSlaveRegister(regCon, x"FF8", 0, v.mpsPllRst);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      if (r.cntRst = '1') then
         v.mpsPktCnt := (others => (others => '0'));
         v.mpsErrCnt := (others => (others => '0'));
         v.srobeCnt  := (others => '0');
      else
         if (mpsTxPktSent = '1') then
            v.mpsPktCnt(0) := r.mpsPktCnt(0) + 1;
         end if;
         if (mpsTxEofeSent = '1') then
            v.mpsErrCnt(0) := r.mpsErrCnt(0) + 1;
         end if;
         for i in STATUS_SIZE_C-1 downto 1 loop
            if (mpsRxPktRcvd(i) = '1') then
               v.mpsPktCnt(i) := r.mpsPktCnt(i) + 1;
            end if;
            if (mpsRxErrDet(i) = '1') then
               v.mpsErrCnt(i) := r.mpsErrCnt(i) + 1;
            end if;
         end loop;
         if (diagnosticstrobe = '1') then
            v.srobeCnt := r.srobeCnt + 1;
         end if;
      end if;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_PktStats : entity surf.SyncTrigPeriod
      generic map (
         TPD_G        => TPD_G,
         COMMON_CLK_G => true)
      port map (
         -- Trigger Input (trigClk domain)
         trigClk   => axilClk,
         trigRst   => axilRst,
         trigIn    => mpsTxPktSent,
         -- Trigger Period Output (locClk domain)
         locClk    => axilClk,
         locRst    => axilRst,
         resetStat => r.cntRst,
         period    => pktPeriod(0),
         periodMax => pktPeriodMax(0),
         periodMin => pktPeriodMin(0));

   GEN_STATS :
   for i in 14 downto 1 generate
      U_PktStats : entity surf.SyncTrigPeriod
         generic map (
            TPD_G        => TPD_G,
            COMMON_CLK_G => true)
         port map (
            -- Trigger Input (trigClk domain)
            trigClk   => axilClk,
            trigRst   => axilRst,
            trigIn    => mpsRxPktRcvd(i),
            -- Trigger Period Output (locClk domain)
            locClk    => axilClk,
            locRst    => axilRst,
            resetStat => r.cntRst,
            period    => pktPeriod(i),
            periodMax => pktPeriodMax(i),
            periodMin => pktPeriodMin(i));
   end generate GEN_STATS;

   U_mpsPllRst : entity surf.PwrUpRst
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIMULATION_G,
         DURATION_G    => 125000000)
      port map (
         arst   => r.mpsPllRst,
         clk    => axilClk,
         rstOut => mpsPllRst);

   SyncStatusVec_Inst : entity surf.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => STATUS_SIZE_C)
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(14 downto 1) => mpsRxLinkUp,
         statusIn(0)           => mpsTxLinkUp,
         -- Output Status bit Signals (rdClk domain)
         statusOut             => statusOut,
         -- Status Bit Counters Signals (rdClk domain)
         cntRstIn              => r.cntRst,
         rollOverEnIn          => r.rollOverEn,
         cntOut                => cntOut,
         -- Clocks and Reset Ports
         wrClk                 => mps125MHzClk,
         rdClk                 => axilClk);

end mapping;
