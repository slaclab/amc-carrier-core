-------------------------------------------------------------------------------
-- File       : AppMpsSalt.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2017-09-29
-------------------------------------------------------------------------------
-- Description: 
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;
use work.AppMpsPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsSalt is
   generic (
      TPD_G            : time            := 1 ns;
      APP_TYPE_G       : AppType         := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C;
      MPS_SLOT_G       : boolean         := false);
   port (
      -- SALT Reference clocks
      mps125MHzClk    : in  sl;
      mps125MHzRst    : in  sl;
      mps312MHzClk    : in  sl;
      mps312MHzRst    : in  sl;
      mps625MHzClk    : in  sl;
      mps625MHzRst    : in  sl;
      mpsPllLocked    : in  sl;
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
      mpsPktCnt      : Slv32Array(14 downto 0);
      rollOverEn     : slv(STATUS_SIZE_C-1 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cntRst         => '1',
      rollOverEn     => (others => '0'),
      mpsPktCnt      => (others => (others => '0')),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal iDelayCtrlRdy : sl;
   signal mpsTxLinkUp   : sl;
   signal mpsTxPktSent  : sl;
   signal mpsRxLinkUp   : slv(14 downto 1);
   signal mpsRxPktRcvd  : slv(14 downto 1);
   signal statusOut     : slv(STATUS_SIZE_C-1 downto 0);
   signal cntOut        : SlVectorArray(STATUS_SIZE_C-1 downto 0, 31 downto 0);

begin

   APP_UNDEFINED : if (APP_TYPE_G = APP_NULL_TYPE_C) generate

      mpsTxLinkUp  <= '0';
      mpsTxPktSent <= '0';
      mpsRxLinkUp  <= (others => '0');
      mpsRxPktRcvd <= (others => '0');
      mpsObMasters <= (others => AXI_STREAM_MASTER_INIT_C);
      mpsIbSlave   <= AXI_STREAM_SLAVE_FORCE_C;

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
      mpsObMasters <= (others => AXI_STREAM_MASTER_INIT_C);

      U_SaltUltraScale : entity work.SaltUltraScale
         generic map (
            TPD_G               => TPD_G,
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
            txPktSent     => mpsTxPktSent,
            rxPktRcvd     => open,
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

      U_SaltDelayCtrl : entity work.SaltDelayCtrl
         generic map (
            TPD_G           => TPD_G,
            SIM_DEVICE_G    => "ULTRASCALE",
            IODELAY_GROUP_G => "MPS_IODELAY_GRP")
         port map (
            iDelayCtrlRdy => iDelayCtrlRdy,
            refClk        => mps625MHzClk,
            refRst        => mps625MHzRst);

      mpsTxLinkUp     <= '0';
      mpsObMasters(0) <= mpsIbMaster;
      mpsIbSlave      <= mpsObSlaves(0);

      U_OBUFDS : OBUFDS
         port map (
            I  => '0',
            O  => mpsTxP,
            OB => mpsTxN);

      GEN_VEC :
      for i in 14 downto 1 generate
         U_SaltUltraScale : entity work.SaltUltraScale
            generic map (
               TPD_G               => TPD_G,
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
               rst125MHz     => mps125MHzRst,
               clk312MHz     => mps312MHzClk,
               clk625MHz     => mps625MHzClk,
               iDelayCtrlRdy => iDelayCtrlRdy,
               linkUp        => mpsRxLinkUp(i),
               txPktSent     => open,
               rxPktRcvd     => mpsRxPktRcvd(i),
               -- Slave Port
               sAxisClk      => axilClk,
               sAxisRst      => axilRst,
               sAxisMaster   => AXI_STREAM_MASTER_INIT_C,
               sAxisSlave    => open,
               -- Master Port
               mAxisClk      => axilClk,
               mAxisRst      => axilRst,
               mAxisMaster   => mpsObMasters(i),
               mAxisSlave    => mpsObSlaves(i));
      end generate GEN_VEC;

   end generate;

   comb : process (axilReadMaster, axilRst, axilWriteMaster, cntOut,
                   mpsPllLocked, mpsRxPktRcvd, mpsTxPktSent, r, statusOut) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
      variable i      : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobe signals
      v.cntRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in STATUS_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(regCon, toSlv(4*i, 12), 0, muxSlVectorArray(cntOut, i));
      end loop;

      for i in STATUS_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(regCon, toSlv(((4*i)+128), 12), 0, r.mpsPktCnt(i));
      end loop;

      axiSlaveRegisterR(regCon, x"700", 0, statusOut);
      axiSlaveRegisterR(regCon, x"704", 0, ite(MPS_SLOT_G, x"00000001", x"00000000"));
      axiSlaveRegisterR(regCon, x"708", 0, APP_TYPE_G);
      axiSlaveRegisterR(regCon, x"714", 0, mpsPllLocked);

      -- Map the write registers
      axiSlaveRegister(regCon, x"FF0", 0, v.rollOverEn);
      axiSlaveRegister(regCon, x"FF4", 0, v.cntRst);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);


      if (r.cntRst = '1') then
         v.mpsPktCnt := (others => (others => '0'));
      else
         if (mpsTxPktSent = '1') then
            v.mpsPktCnt(0) := r.mpsPktCnt(0) + 1;
         end if;
         for i in STATUS_SIZE_C-1 downto 1 loop
            if (mpsRxPktRcvd(i) = '1') then
               v.mpsPktCnt(i) := r.mpsPktCnt(i) + 1;
            end if;
         end loop;
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

   SyncStatusVec_Inst : entity work.SyncStatusVector
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
