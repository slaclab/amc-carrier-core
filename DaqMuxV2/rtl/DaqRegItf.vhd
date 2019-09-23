-------------------------------------------------------------------------------
-- File       : DaqRegItf.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-15
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description:  Register decoding for DAQ
--
--               Register map table is here:
--               https://confluence.slac.stanford.edu/display/ppareg/AmcAxisDaqV2+Requirements
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
use work.AxiLitePkg.all;

entity DaqRegItf is
   generic (
      -- General Configurations
      TPD_G            : time     := 1 ns;
      AXI_ADDR_WIDTH_G : positive := 10;
      N_DATA_IN_G      : positive := 16;
      N_DATA_OUT_G     : positive := 4
      );
   port (
      -- Axi-Lite Clk
      axiClk_i : in sl;
      axiRst_i : in sl;

      -- Axi-Lite Register Interface (locClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Device Clk
      devClk_i : in sl;
      devRst_i : in sl;

      -- Status Registers
      daqStatus_i   : in Slv32Array(N_DATA_OUT_G-1 downto 0);
      trigStatus_i  : in slv(5 downto 0);
      timeStamp_i   : in slv(63 downto 0);
      bsa_i         : in slv(127 downto 0);
      sampleValid_i : in slv(N_DATA_IN_G-1 downto 0);
      linkReady_i   : in slv(N_DATA_IN_G-1 downto 0);

      -- Trigger pulse for the trigger counter
      trig_i : in sl;

      -- Control
      trigSw_o          : out sl;
      trigCascMask_o    : out sl;
      trigHwAutoRearm_o : out sl;
      trigHwArm_o       : out sl;
      freezeSw_o        : out sl;
      freezeHwMask_o    : out sl;

      clearStatus_o : out sl;
      trigMode_o    : out sl;
      headerEn_o    : out sl;

      -- DAQ parameters      
      dataSize_o : out slv(31 downto 0);
      rateDiv_o  : out slv(15 downto 0);
      muxSel_o   : out Slv5Array(N_DATA_OUT_G-1 downto 0);

      --
      signWidth_o  : out Slv5Array(N_DATA_OUT_G-1 downto 0);
      data16or32_o : out slv(N_DATA_OUT_G-1 downto 0);
      signed_o     : out slv(N_DATA_OUT_G-1 downto 0);
      averaging_o  : out slv(N_DATA_OUT_G-1 downto 0)
      );
end DaqRegItf;

architecture rtl of DaqRegItf is

   type RegType is record
      -- Registers Control (RW)
      control    : slv(8 downto 0);
      rateDiv    : slv(15 downto 0);
      dataSize   : slv(31 downto 0);
      muxSel     : Slv5Array(N_DATA_OUT_G-1 downto 0);
      dataFormat : Slv8Array(N_DATA_OUT_G-1 downto 0);

      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      control    => "101000010",
      rateDiv    => x"0001",
      dataSize   => x"0000_0800",
      muxSel     => (others => (others => '0')),
      dataFormat => (others => "00100000"),

      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Integer address
   signal s_RdAddr : natural := 0;
   signal s_WrAddr : natural := 0;

   signal s_trigCnt     : SlVectorArray(0 downto 0, 31 downto 0);
   signal s_trigStatus  : slv(trigStatus_i'range);
   signal s_daqStatus   : slv32Array(N_DATA_OUT_G-1 downto 0);
   signal s_timeStamp   : slv(63 downto 0);
   signal s_bsa         : slv(127 downto 0);
   signal s_sampleValid : slv(N_DATA_IN_G-1 downto 0) := (others => '0');
   signal s_linkReady   : slv(N_DATA_IN_G-1 downto 0) := (others => '0');

begin

   U_SyncSampleValid : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => N_DATA_IN_G)
      port map (
         clk     => axiClk_i,
         dataIn  => sampleValid_i,
         dataOut => s_sampleValid);

   U_SyncLinkReady : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => N_DATA_IN_G)
      port map (
         clk     => axiClk_i,
         dataIn  => linkReady_i,
         dataOut => s_linkReady);

   -- Counts the number of trigger pulses
   U_SyncStatusVector : entity work.SyncStatusVector
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '1',
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32,
         WIDTH_G        => 1)
      port map (
         -- Input Status bit Signals (wrClk domain)
         statusIn(0) => trig_i,
         -- Output Status bit Signals (rdClk domain)  
         statusOut   => open,
         -- Status Bit Counters Signals (rdClk domain) 
         cntRstIn    => r.control(4),
         cntOut      => s_trigCnt,
         -- Clocks and Reset Ports
         wrClk       => devClk_i,
         rdClk       => axiClk_i);

   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer(axilReadMaster.araddr(AXI_ADDR_WIDTH_G-1 downto 2));
   s_WrAddr <= conv_integer(axilWriteMaster.awaddr(AXI_ADDR_WIDTH_G-1 downto 2));

   comb : process (axiRst_i, axilReadMaster, axilWriteMaster, r, s_RdAddr,
                   s_WrAddr, s_bsa, s_daqStatus, s_linkReady, s_sampleValid,
                   s_timeStamp, s_trigCnt, s_trigStatus) is
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
            when 16#00# =>              -- ADDR (0)
               v.control := axilWriteMaster.wdata(r.control'range);
            when 16#02# =>              -- ADDR (8)
               v.rateDiv := axilWriteMaster.wdata(r.rateDiv'range);
            when 16#03# =>              -- ADDR (12)
               v.dataSize := axilWriteMaster.wdata(r.dataSize'range);
            when 16#10# to 16#1F# =>
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = I) then
                     v.muxSel(I) := axilWriteMaster.wdata(r.muxSel(I)'range);
                  end if;
               end loop;
            when 16#30# to 16#3F# =>
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = I) then
                     v.dataFormat(I) := axilWriteMaster.wdata(r.dataFormat(I)'range);
                  end if;
               end loop;
            when others =>
               axilWriteResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>              -- ADDR (0x0)
               v.axilReadSlave.rdata(r.control'range) := r.control;
            when 16#01# =>              -- ADDR (0x4)
               v.axilReadSlave.rdata(trigStatus_i'range) := s_trigStatus;
            when 16#02# =>              -- ADDR (0x8)
               v.axilReadSlave.rdata(r.rateDiv'range) := r.rateDiv;
            when 16#03# =>              -- ADDR (0xc)
               v.axilReadSlave.rdata(r.dataSize'range) := r.dataSize;
            when 16#04# =>              -- ADDR (0x10)
               v.axilReadSlave.rdata := s_timeStamp(63 downto 32);
            when 16#05# =>              -- ADDR (0x14)
               v.axilReadSlave.rdata := s_timeStamp(31 downto 0);
            when 16#06# =>              -- ADDR (0x18)
               v.axilReadSlave.rdata := s_bsa(127 downto 96);
            when 16#07# =>              -- ADDR (0x1c)
               v.axilReadSlave.rdata := s_bsa(95 downto 64);
            when 16#08# =>              -- ADDR (0x20)
               v.axilReadSlave.rdata := s_bsa(63 downto 32);
            when 16#09# =>              -- ADDR (0x24)
               v.axilReadSlave.rdata := s_bsa(31 downto 0);
            when 16#0a# =>              -- ADDR (0x28)
               for j in 31 downto 0 loop
                  v.axilReadSlave.rdata(j) := s_trigCnt(0, j);
               end loop;
            when 16#0b# =>              -- ADDR (0x2C)
               v.axilReadSlave.rdata(N_DATA_IN_G-1 downto 0) := s_sampleValid;
            when 16#0c# =>              -- ADDR (0x30)
               v.axilReadSlave.rdata(N_DATA_IN_G-1 downto 0) := s_linkReady;
            when 16#0d# =>              -- ADDR (0x34)
               v.axilReadSlave.rdata(7 downto 0)   := toSlv(AXI_ADDR_WIDTH_G,8);
               v.axilReadSlave.rdata(15 downto 8)  := toSlv(N_DATA_IN_G,8);
               v.axilReadSlave.rdata(23 downto 16) := toSlv(N_DATA_OUT_G,8);
               v.axilReadSlave.rdata(31 downto 24) := x"00";               
            when 16#10# to 16#1F# =>    -- ADDR (0x40)
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(r.muxSel(I)'range) := r.muxSel(I);
                  end if;
               end loop;
            when 16#20# to 16#2F# =>    -- ADDR (128)
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(s_daqStatus(I)'range) := s_daqStatus(I);
                  end if;
               end loop;
            when 16#30# to 16#3F# =>    -- ADDR (192)
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(r.dataFormat(I)'range) := r.dataFormat(I);
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
   GEN_IN_0 : for I in N_DATA_OUT_G-1 downto 0 generate
      SyncFifo_IN : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 32)
         port map (
            wr_clk => devClk_i,
            din    => daqStatus_i(I),
            rd_clk => axiClk_i,
            dout   => s_daqStatus(I));
   end generate GEN_IN_0;

   SyncFifo_IN0 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 6)
      port map (
         wr_clk => devClk_i,
         din    => trigStatus_i,
         rd_clk => axiClk_i,
         dout   => s_trigStatus);

   SyncFifo_IN1 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 64)
      port map (
         wr_clk => devClk_i,
         din    => timeStamp_i,
         rd_clk => axiClk_i,
         dout   => s_timeStamp);

   SyncFifo_IN2 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 128)
      port map (
         wr_clk => devClk_i,
         din    => bsa_i,
         rd_clk => axiClk_i,
         dout   => s_bsa);

   ------------------------------------------------
   -- Output assignment and synchronization
   ------------------------------------------------   
   Sync_OUT0 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(0),
         dataOut => trigSw_o);

   Sync_OUT1 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(1),
         dataOut => trigCascMask_o);

   Sync_OUT2 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(2),
         dataOut => trigHwAutoRearm_o);

   Sync_OUT3 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(3),
         dataOut => trigHwArm_o);

   Sync_OUT4 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(4),
         dataOut => clearStatus_o);

   Sync_OUT5 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(5),
         dataOut => trigMode_o);

   Sync_OUT6 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(6),
         dataOut => headerEn_o);

   Sync_OUT7 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(7),
         dataOut => freezeSw_o);

   Sync_OUT8 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(8),
         dataOut => freezeHwMask_o);

   SyncFifo_OUT0 : entity work.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 1,
         DATA_WIDTH_G  => dataSize_o'length)
      port map (
         wr_clk => axiClk_i,
         din    => r.dataSize,
         rd_clk => devClk_i,
         dout   => dataSize_o);

   SyncFifo_OUT1 : entity work.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 1,
         DATA_WIDTH_G  => 16)
      port map (
         wr_clk => axiClk_i,
         din    => r.rateDiv,
         rd_clk => devClk_i,
         dout   => rateDiv_o);

   GEN_OUT_0 : for I in N_DATA_OUT_G-1 downto 0 generate
      SyncFifo_OUT : entity work.SynchronizerFifo
         generic map (
            TPD_G         => TPD_G,
            PIPE_STAGES_G => 1,
            DATA_WIDTH_G  => 5)
         port map (
            wr_clk => axiClk_i,
            din    => r.muxSel(I),
            rd_clk => devClk_i,
            dout   => muxSel_o(I));
   end generate GEN_OUT_0;


   GEN_OUT_1 : for I in N_DATA_OUT_G-1 downto 0 generate
      SyncFifo_OUT : entity work.SynchronizerFifo
         generic map (
            TPD_G         => TPD_G,
            PIPE_STAGES_G => 1,
            DATA_WIDTH_G  => 5)
         port map (
            wr_clk => axiClk_i,
            din    => r.dataFormat(I)(4 downto 0),
            rd_clk => devClk_i,
            dout   => signWidth_o(I));

      Sync_OUT0 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => devClk_i,
            rst     => devRst_i,
            dataIn  => r.dataFormat(I)(5),
            dataOut => data16or32_o(I));

      Sync_OUT1 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => devClk_i,
            rst     => devRst_i,
            dataIn  => r.dataFormat(I)(6),
            dataOut => signed_o(I));

      Sync_OUT2 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => devClk_i,
            rst     => devRst_i,
            dataIn  => r.dataFormat(I)(7),
            dataOut => averaging_o(I));

   end generate GEN_OUT_1;

end rtl;
