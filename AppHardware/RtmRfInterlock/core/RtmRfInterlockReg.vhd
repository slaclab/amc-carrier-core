-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:  Register decoding
--               0x00 (RW)- bit0 = mode
--               0x01 (RW)- bit0 = tune Sled
--               0x02 (RW)- bit0 = detune Sled
--               0x03 (RW)- bit0 = trigger buffer from sw (Re)
--                          bit1 = clear buffer (arm for the next hw trigger) (Re)
--                          bit2 = load the delays of 4 Fast ADC lanes + Frame clock.
--                          bit3 = Clear the Fault Latch (1 us pulse)
--                          bit4 = bypass Mode bit
--               0x10 (R) - bit0 = Fault Out status
--                        - bit1 = Fast ADC locked status
--               0x20-0x24
--                    (RW)- bit0-9 = Set value of the ADC iDelay
--               0x30-0x34
--                    (R)- bit0-9 = Get value of the ADC iDelay
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
use surf.AxiLitePkg.all;

entity RtmRfInterlockReg is
   generic (
      -- General Configurations
      TPD_G             : time     := 1 ns;
      AXIL_ADDR_WIDTH_G : positive := 10);
   port (
      -- AXI Clk
      axiClk_i : in sl;
      axiRst_i : in sl;

      -- Axi-Lite Register Interface (axiClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Dev Clk
      devClk_i : in sl;
      devRst_i : in sl;

      -- Registers
      mode_o       : out sl;
      tuneSled_o   : out sl;
      detuneSled_o : out sl;
      -- Control Register
      softTrig_o   : out sl;
      softClear_o  : out sl;
      loadDelay_o  : out sl;
      faultClear_o : out sl;
      bypassMode_o : out sl;
      streamEn_o   : out sl;

      -- Status Register
      rfOff_i        : in sl;
      fault_i        : in sl;
      adcLock_i      : in sl;
      writePointer_i : slv(10 downto 0);
      timestamp_i    : Slv64Array(3 downto 0);

      -- IDelay control
      curDelay_i : in  Slv9Array(4 downto 0);
      setDelay_o : out Slv9Array(4 downto 0)
      );
end RtmRfInterlockReg;

architecture rtl of RtmRfInterlockReg is

   type RegType is record
      --
      tuneSled   : sl;
      detuneSled : sl;
      mode       : sl;
      control    : slv(4 downto 0);
      setDelay   : Slv9Array(4 downto 0);
      streamEn   : sl;

      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      tuneSled   => '0',
      detuneSled => '0',
      mode       => '0',
      control    => (others => '0'),
      setDelay   => (others => (others => '0')),
      streamEn   => '0',

      -- AXI lite
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Integer address
   signal s_RdAddr : natural := 0;
   signal s_WrAddr : natural := 0;

   -- Read-only synced
   signal s_status   : slv(2 downto 0);
   signal s_curDelay : Slv9Array(4 downto 0);

   signal s_writePointer : slv(10 downto 0) := (others => '0');
   signal s_timestamp    : Slv32Array(7 downto 0) := (others => (others => '0'));
--
begin

   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer(axilReadMaster.araddr(AXIL_ADDR_WIDTH_G-1 downto 2));
   s_WrAddr <= conv_integer(axilWriteMaster.awaddr(AXIL_ADDR_WIDTH_G-1 downto 2));

   comb : process (axiRst_i, axilReadMaster, axilWriteMaster, r, s_RdAddr,
                   s_WrAddr, s_curDelay, s_status, s_writePointer, s_timestamp) is
      variable v             : RegType;
      variable axilStatus    : AxiLiteStatusType;
      variable axilWriteResp : slv(1 downto 0);
      variable axilReadResp  : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;

      ----------------------------------------------------------------------------------------------
      -- Axi-Lite interface
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axilStatus);

      if (axilStatus.writeEnable = '1') then
         axilWriteResp := ite(axilWriteMaster.awaddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         case (s_WrAddr) is
            when 16#00# =>              -- ADDR (0x0)
               v.mode := axilWriteMaster.wdata(0);
            when 16#01# =>              -- ADDR (0x4)
               v.tuneSled := axilWriteMaster.wdata(0);
            when 16#02# =>              -- ADDR (0x8)
               v.detuneSled := axilWriteMaster.wdata(0);
            when 16#03# =>              -- ADDR (0xC)
               v.control := axilWriteMaster.wdata(r.control'range);
            when 16#04# =>              -- ADDR (0x10)
               v.streamEn := axilWriteMaster.wdata(0);
            when 16#20# to 16#2F# =>
               for i in 4 downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = i) then
                     v.setDelay(i) := axilWriteMaster.wdata(r.setDelay(i)'range);
                  end if;
               end loop;
            when others =>
               axilWriteResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         case (s_RdAddr) is
            when 16#00# =>              -- ADDR (0x0)
               v.axilReadSlave.rdata(0) := r.mode;
            when 16#01# =>              -- ADDR (0x4)
               v.axilReadSlave.rdata(0) := r.tuneSled;
            when 16#02# =>              -- ADDR (0x8)
               v.axilReadSlave.rdata(0) := r.detuneSled;
            when 16#03# =>              -- ADDR (0xc)
               v.axilReadSlave.rdata(r.control'range) := r.control;
            when 16#04# =>              -- ADDR (0x10)
               v.axilReadSlave.rdata(0) := r.streamEn;
            when 16#10# =>              -- ADDR (0x40)
               v.axilReadSlave.rdata(s_status'range) := s_status;
            when 16#11# =>              -- ADDR (0x44)
               v.axilReadSlave.rdata(s_writePointer'range) := s_writePointer;
            when 16#20# to 16#2F# =>    -- ADDR (0x80)
               for i in 4 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata(r.setDelay(i)'range) := r.setDelay(i);
                  end if;
               end loop;
            when 16#30# to 16#3F# =>    -- ADDR (0xC0)
               for i in 4 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata(s_curDelay(i)'range) := s_curDelay(i);
                  end if;
               end loop;
            when 16#40# to 16#4F# =>    -- ADDR (0x100)
               for i in 7 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata(s_timestamp(i)'range) := s_timestamp(i);
                  end if;
               end loop;
            when others =>
               axilReadResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveReadResponse(v.axilReadSlave);
      end if;

      -- Reset
      if (axiRst_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

   end process comb;

   seq : process (axiClk_i) is
   begin
      if rising_edge(axiClk_i) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Input assignment and synchronization
   Sync_TIMESTAMP : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 256)
      port map (
         dataIn(63 downto 0)     => timestamp_i(0),
         dataIn(127 downto 64)   => timestamp_i(1),
         dataIn(191 downto 128)  => timestamp_i(2),
         dataIn(255 downto 192)  => timestamp_i(3),
         clk                     => axiClk_i,
         dataOut(31 downto 0)    => s_timestamp(0),
         dataOut(63 downto 32)   => s_timestamp(1),
         dataOut(95 downto 64)   => s_timestamp(2),
         dataOut(127 downto 96)  => s_timestamp(3),
         dataOut(159 downto 128) => s_timestamp(4),
         dataOut(191 downto 160) => s_timestamp(5),
         dataOut(223 downto 192) => s_timestamp(6),
         dataOut(255 downto 224) => s_timestamp(7));

   Sync_IN0 : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => s_status'length
         )
      port map (
         dataIn(0) => fault_i,
         dataIn(1) => adcLock_i,
         dataIn(2) => rfOff_i,
         clk       => axiClk_i,
         dataOut   => s_status
         );

   SYNC_IN1 : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => s_writePointer'length)
      port map (
         clk     => axiClk_i,
         dataIn  => writePointer_i,
         dataOut => s_writePointer);

   GEN_IDELAY_IN : for i in 4 downto 0 generate
      Sync_IN1 : entity surf.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => curDelay_i(i)'length
            )
         port map (
            clk     => axiClk_i,
            dataIn  => curDelay_i(i),
            dataOut => s_curDelay(i)
            );
   end generate GEN_IDELAY_IN;

   -- Output assignment and synchronization
   Sync_OUT0 : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         dataIn  => r.mode,
         clk     => devClk_i,
         dataOut => mode_o
         );

   Sync_OUT1 : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         dataIn  => r.detuneSled,
         clk     => devClk_i,
         dataOut => detuneSled_o
         );

   Sync_OUT2 : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         dataIn  => r.tuneSled,
         clk     => devClk_i,
         dataOut => tuneSled_o
         );

   Sync_OUT3 : entity surf.SynchronizerEdge
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk        => devClk_i,
         dataIn     => r.control(0),
         risingEdge => softTrig_o       -- Rising edge
         );

   Sync_OUT4 : entity surf.SynchronizerEdge
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk        => devClk_i,
         dataIn     => r.control(1),
         risingEdge => softClear_o      -- Rising edge
         );

   Sync_OUT5 : entity surf.SynchronizerEdge
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         dataIn  => r.control(2),       -- Only sync
         dataOut => loadDelay_o
         );

   Sync_OUT6 : entity surf.SynchronizerOneShot
      generic map (
         TPD_G         => TPD_G,
         PULSE_WIDTH_G => 119           -- 1 us
         )
      port map (
         clk     => devClk_i,
         dataIn  => r.control(3),
         dataOut => faultClear_o        -- Rising edge
         );

   Sync_OUT7 : entity surf.SynchronizerEdge
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         dataIn  => r.control(4),       -- Only sync
         dataOut => bypassMode_o
         );

   GEN_IDELAY_OUT : for i in 4 downto 0 generate
      Sync_OUT4 : entity surf.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => r.setDelay(i)'length
            )
         port map (
            dataIn  => r.setDelay(i),
            clk     => devClk_i,
            dataOut => setDelay_o(i)
            );
   end generate GEN_IDELAY_OUT;
---------------------------------------------------------------------
end rtl;
