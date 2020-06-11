-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: SPI DAC LUT Module
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

entity RtmCryoDacLut is
   generic (
      TPD_G            : time             := 1 ns;
      NUM_CH_G         : positive         := 2;
      ADDR_WIDTH_G     : positive         := 11;  -- 2^11 = 2ksamples
      SYNTH_MODE_G     : string           := "inferred";
      MEMORY_TYPE_G    : string           := "block";
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      hwTrig           : in  sl;
      -- Clock and Reset
      axilClk          : in  sl;
      axilRst          : in  sl;
      -- Slave AXI-Lite Interface
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Slave AXI-Lite Interface
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType);
end entity RtmCryoDacLut;

architecture rtl of RtmCryoDacLut is

   constant NUM_AXIL_MASTERS_C : positive := NUM_CH_G+1;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   type StateType is (
      IDLE_S,
      WAIT_S,
      REQ_S,
      ACK_S);

   type RegType is record
      swTrig         : sl;
      cntRst         : sl;
      busy           : sl;
      continuous     : sl;
      ramAddr        : slv(ADDR_WIDTH_G-1 downto 0);
      maxAddr        : slv(ADDR_WIDTH_G-1 downto 0);
      enableCh       : slv(NUM_CH_G-1 downto 0);
      dacAxilAddr    : Slv32Array(NUM_CH_G-1 downto 0);
      trigCnt        : slv(15 downto 0);
      dropTrigCnt    : slv(15 downto 0);
      timerSize      : slv(23 downto 0);
      timer          : slv(23 downto 0);
      eventCnt       : slv(15 downto 0);
      errorCnt       : slv(15 downto 0);
      rdLat          : natural range 0 to 4;
      index          : natural range 0 to NUM_CH_G-1;
      req            : AxiLiteReqType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      state          : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      swTrig         => '0',
      cntRst         => '0',
      busy           => '0',
      continuous     => '0',
      ramAddr        => (others => '0'),
      maxAddr        => (others => '1'),
      enableCh       => (others => '1'),
      dacAxilAddr    => (others => (others => '0')),
      trigCnt        => (others => '0'),
      dropTrigCnt    => (others => '0'),
      timerSize      => x"00FFFF",
      timer          => (others => '0'),
      eventCnt       => (others => '0'),
      errorCnt       => (others => '0'),
      rdLat          => 0,
      index          => 0,
      req            => AXI_LITE_REQ_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      state          => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ack     : AxiLiteAckType;
   signal ramData : Slv32Array(NUM_CH_G-1 downto 0);

begin

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => sAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   GEN_LUT :
   for i in NUM_CH_G-1 downto 0 generate
      U_LUT : entity surf.AxiDualPortRam
         generic map (
            TPD_G         => TPD_G,
            SYNTH_MODE_G  => SYNTH_MODE_G,
            MEMORY_TYPE_G => MEMORY_TYPE_G,
            COMMON_CLK_G  => true,
            ADDR_WIDTH_G  => ADDR_WIDTH_G,
            DATA_WIDTH_G  => 32)
         port map (
            -- Axi Port
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(i+1),
            axiReadSlave   => axilReadSlaves(i+1),
            axiWriteMaster => axilWriteMasters(i+1),
            axiWriteSlave  => axilWriteSlaves(i+1),
            -- Standard Port
            clk            => axilClk,
            addr           => r.ramAddr,
            dout           => ramData(i));
   end generate GEN_LUT;

   comb : process (ack, axilReadMasters, axilRst, axilWriteMasters, hwTrig, r,
                   ramData) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.swTrig := '0';
      v.cntRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMasters(0), axilReadMasters(0), v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in NUM_CH_G-1 downto 0 loop
         axiSlaveRegister(axilEp, toSlv((4*i), 8), 0, v.dacAxilAddr(i));
      end loop;

      axiSlaveRegisterR(axilEp, x"20", 0, toSlv(NUM_CH_G, 8));
      axiSlaveRegisterR(axilEp, x"20", 8, toSlv(ADDR_WIDTH_G, 8));
      axiSlaveRegisterR(axilEp, x"20", 16, r.busy);
      axiSlaveRegisterR(axilEp, x"24", 0, r.trigCnt);
      axiSlaveRegisterR(axilEp, x"28", 0, r.dropTrigCnt);
      axiSlaveRegisterR(axilEp, x"2C", 0, r.eventCnt);
      axiSlaveRegisterR(axilEp, x"30", 0, r.errorCnt);

      axiSlaveRegister (axilEp, x"40", 0, v.continuous);
      axiSlaveRegister (axilEp, x"44", 0, v.maxAddr);
      axiSlaveRegister (axilEp, x"48", 0, v.timerSize);
      axiSlaveRegister (axilEp, x"4C", 0, v.enableCh);

      axiSlaveRegister (axilEp, x"F8", 0, v.swTrig);
      axiSlaveRegister (axilEp, x"FC", 0, v.cntRst);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Decrement the timers
      if (r.timer /= 0) then
         v.timer := r.timer -1;
      end if;
      if (r.rdLat /= 0) then
         v.rdLat := r.rdLat -1;
      end if;

      -- Count the dropped triggers
      if ((r.state /= IDLE_S) or (r.continuous = '1')) and ((r.swTrig = '1') or (hwTrig = '1')) then
         v.dropTrigCnt := r.dropTrigCnt + 1;
      end if;

      -- Update the status flag
      if (r.state = IDLE_S) then
         v.busy := '0';
      else
         v.busy := '1';
      end if;

      -- State Machine
      case (r.state) is
         -------------------------------------------------------------------------------
         when IDLE_S =>
            -- Check for trigger or continuous mode
            if (r.swTrig = '1') or (hwTrig = '1') or (r.continuous = '1')then

               -- Check if not continuous mode
               if (r.continuous = '0') then
                  -- Increment the trigger counter
                  v.trigCnt := r.trigCnt + 1;
               end if;

               -- Count each iteration
               v.eventCnt := r.eventCnt + 1;

               -- Next state
               v.state := WAIT_S;

            end if;
         ----------------------------------------------------------------------
         when WAIT_S =>
            -- Check for timeout
            if (r.timer = 0) then
               -- Next state
               v.state := REQ_S;
            end if;
         ----------------------------------------------------------------------
         when REQ_S =>
            -- Check if ready for next transaction
            if (ack.done = '0') and (r.rdLat = 0) then

               -- Setup the AXI-Lite Master request
               v.req.request := r.enableCh(r.index);
               v.req.rnw     := '0';    -- 0: write
               v.req.address := r.dacAxilAddr(r.index);
               v.req.wrData  := ramData(r.index);

               -- Check if we need to arm the timer
               if (r.index = 0) then
                  -- Arm the timer
                  v.timer := r.timerSize;
               end if;

               -- Next state
               v.state := ACK_S;

            end if;
         ----------------------------------------------------------------------
         when ACK_S =>
            -- Wait for DONE to set or no request
            if (ack.done = '1') or (r.req.request = '0') then

               -- Reset the flag
               v.req.request := '0';

               if (r.req.request = '1') and (ack.resp /= AXI_RESP_OK_C) then
                  -- Increment the address
                  v.errorCnt := r.errorCnt + 1;
               end if;

               -- Check if last channel
               if (r.index = NUM_CH_G-1) then

                  -- Reset the index
                  v.index := 0;

                  -- Check if last address
                  if (r.ramAddr = r.maxAddr) then

                     -- Reset the address
                     v.ramAddr := (others => '0');

                     -- Next state
                     v.state := IDLE_S;

                  else
                     -- Increment the address
                     v.ramAddr := r.ramAddr + 1;

                     -- Next state
                     v.state := WAIT_S;

                  end if;

               else

                  -- Increment the index
                  v.index := r.index + 1;

                  -- Next state
                  v.state := REQ_S;

               end if;

            end if;
      -------------------------------------------------------------------------------
      end case;

      -- Check for address change
      if (r.ramAddr /= v.ramAddr) then
         v.rdLat := 4;
      end if;

      -- Check for timer Size change
      if (r.timerSize /= v.timerSize) then
         v.timer := (others => '0');
      end if;

      -- Check for counter reset
      if (r.cntRst = '1') then
         v.trigCnt     := (others => '0');
         v.dropTrigCnt := (others => '0');
         v.eventCnt    := (others => '0');
         v.errorCnt    := (others => '0');
      end if;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlaves(0) <= r.axilWriteSlave;
      axilReadSlaves(0)  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_AxiLiteMaster : entity surf.AxiLiteMaster
      generic map (
         TPD_G => TPD_G)
      port map (
         req             => r.req,
         ack             => ack,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilWriteMaster => mAxilWriteMaster,
         axilWriteSlave  => mAxilWriteSlave,
         axilReadMaster  => open,
         axilReadSlave   => AXI_LITE_READ_SLAVE_EMPTY_OK_C);

end rtl;
