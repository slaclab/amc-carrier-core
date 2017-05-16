-------------------------------------------------------------------------------
-- File       : AxiLiteGenRegItf.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-15
-- Last update: 2015-04-15
-------------------------------------------------------------------------------
-- Description:  Register decoding for Signal generator
--               0x00      (RW)- Enable channels. Example: 0x7F enables all 7 channels (also used to align the lane) (NUM_SIG_GEN_G-1 downto 0)
--               0x01      (RW)- Mode: 0 - Triggered Mode. 1 - Periodic Mode
--               0x02      (RW)- Sign: '0' - Signed 2's complement, '1' - Offset binary (Currently Applies only to zero data)
--               0x03      (RW)- Software triggers
--               0x08      (R) - Running status
--               0x09      (R) - 16bit to 32bit conversion underflow
--               0x0A      (R) - 16bit to 32bit conversion overflow
--               0x0B      (R) - Max Waveform size 
--               0x10-0x1x (RW)- WaveformSize: In Periodic mode: Period size (Zero inclusive).
--                                        In Triggered mode: Waveform size (Zero inclusive).
--                                        Separate values for separate channels.
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
use work.Jesd204bPkg.all;

entity DacSigGenReg is
   generic (
      TPD_G                      : time            := 1 ns;
      AXI_ERROR_RESP_G           : slv(1 downto 0) := AXI_RESP_SLVERR_C;
      AXI_ADDR_WIDTH_G    : positive               := 9;      
      ADDR_WIDTH_G : integer range 1 to (2**24)    := 9;
      -- Number of channels 
      NUM_SIG_GEN_G : natural range 1 to 10         := 6 -- 0 - Disabled
   );    
   port (
    -- AXI Clk
      axiClk_i : in sl;
      axiRst_i : in sl;

    -- Axi-Lite Register Interface (axiClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
 
    -- JESD devClk
      devClk_i        : in  sl;
      devRst_i        : in  sl;

   -- Registers   
      enable_o        : out slv(NUM_SIG_GEN_G-1 downto 0);
      mode_o          : out slv(NUM_SIG_GEN_G-1 downto 0);
      sign_o          : out slv(NUM_SIG_GEN_G-1 downto 0);
      trigSw_o        : out slv(NUM_SIG_GEN_G-1 downto 0);
      period_o        : out slv32Array(NUM_SIG_GEN_G-1 downto 0);
      running_i       : in  slv(NUM_SIG_GEN_G-1 downto 0);
      overflow_i      : in  slv(NUM_SIG_GEN_G-1 downto 0);
      underflow_i     : in  slv(NUM_SIG_GEN_G-1 downto 0)
   );   
end DacSigGenReg;

architecture rtl of DacSigGenReg is

   type RegType is record
      -- Control (RW)
      enable   : slv(NUM_SIG_GEN_G-1 downto 0);
      mode     : slv(NUM_SIG_GEN_G-1 downto 0); 
      sign     : slv(NUM_SIG_GEN_G-1 downto 0);      
      trigSw   : slv(NUM_SIG_GEN_G-1 downto 0);      
      period   : slv32Array(NUM_SIG_GEN_G-1 downto 0);
      
      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;
   
   constant REG_INIT_C : RegType := (
      -- enable       => (others=> '0'),
      -- mode         => (others=> '0'),
      -- sign         => (others=> '0'),      
      -- trigSw       => (others=> '0'),      
      -- period       => (others => (others=> '0')),
      enable       => (others=> '1'),
      mode         => (others=> '1'),
      sign         => (others=> '1'),      
      trigSw       => (others=> '0'),      
      period       => (others => toSlv(7,32)),      
      
 
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   -- Integer address
   signal s_RdAddr: natural := 0;
   signal s_WrAddr: natural := 0; 
   
   -- Status sync signals
   signal s_underflowSync : slv(NUM_SIG_GEN_G-1 downto 0);  
   signal s_overflowSync  : slv(NUM_SIG_GEN_G-1 downto 0);   
   signal s_runningSync   : slv(NUM_SIG_GEN_G-1 downto 0);
   
   
begin
   
   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= slvToInt( axilReadMaster.araddr(AXI_ADDR_WIDTH_G-1 downto 2));
   s_WrAddr <= slvToInt( axilWriteMaster.awaddr(AXI_ADDR_WIDTH_G-1 downto 2)); 
   
   comb : process (axilReadMaster, axilWriteMaster, r, axiRst_i, s_RdAddr, s_WrAddr, s_runningSync, s_underflowSync, s_overflowSync) is
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
         axilWriteResp := ite(axilWriteMaster.awaddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_ERROR_RESP_G);
         case (s_WrAddr) is
            when 16#00# => -- ADDR (0x0)
               v.enable  := axilWriteMaster.wdata(NUM_SIG_GEN_G-1 downto 0);
            when 16#01# => -- ADDR (0x4)
               v.mode    := axilWriteMaster.wdata(NUM_SIG_GEN_G-1 downto 0);              
            when 16#02# => -- ADDR (0x8)
               v.sign    := axilWriteMaster.wdata(NUM_SIG_GEN_G-1 downto 0);
            when 16#03# => -- ADDR (0xC)
               v.trigSw  := axilWriteMaster.wdata(NUM_SIG_GEN_G-1 downto 0);
            when 16#10# to 16#1F# => -- ADDR (0x40-0x7C)
               for i in NUM_SIG_GEN_G-1 downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = i) then
                     v.period(i) := axilWriteMaster.wdata;
                  end if;
               end loop; 
            when others =>
               axilWriteResp     := AXI_ERROR_RESP_G;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_ERROR_RESP_G);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>  -- ADDR (0x0)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := r.enable;
            when 16#01# =>  -- ADDR (0x4)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := r.mode;               
            when 16#02# =>  -- ADDR (0x8)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := r.sign;
            when 16#03# =>  -- ADDR (0xC)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := r.trigSw;
            when 16#08# =>  -- ADDR (0x20)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := s_runningSync;
            when 16#09# =>  -- ADDR (0x24)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := s_underflowSync;               
            when 16#0A# =>  -- ADDR (0x28)
               v.axilReadSlave.rdata(NUM_SIG_GEN_G-1 downto 0) := s_overflowSync;
            when 16#0B# =>  -- ADDR (0x2C)
               v.axilReadSlave.rdata                           := toSlv(2**ADDR_WIDTH_G, 32);               
            when 16#10# to 16#1F# => -- ADDR (0x40-0x7C) 
               for i in (NUM_SIG_GEN_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata := r.period(i);
                  end if;
               end loop;
            when others =>
               axilReadResp    := AXI_ERROR_RESP_G;
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
   SyncFifo_IN0 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
      )
   port map (
      wr_clk => devClk_i,
      din    => running_i,
      rd_clk => axiClk_i,
      dout   => s_runningSync
      );
      
   SyncFifo_IN1 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
      )
   port map (
      wr_clk => devClk_i,
      din    => underflow_i,
      rd_clk => axiClk_i,
      dout   => s_underflowSync
      );
      
   SyncFifo_IN2 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
      )
   port map (
      wr_clk => devClk_i,
      din    => overflow_i,
      rd_clk => axiClk_i,
      dout   => s_overflowSync
      );

   -- Output assignment and synchronization
   SyncFifo_OUT1 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.enable,
      rd_clk => devClk_i,
      dout   => enable_o
   );
   
   SyncFifo_OUT2 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.mode,
      rd_clk => devClk_i,
      dout   => mode_o
   );
   
   SyncFifo_OUT3 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.sign,
      rd_clk => devClk_i,
      dout   => sign_o
   );
   
   SyncFifo_OUT4 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => NUM_SIG_GEN_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.trigSw,
      rd_clk => devClk_i,
      dout   => trigSw_o
   );
   --
   GEN_PERIOD_OUT : for i in NUM_SIG_GEN_G-1 downto 0 generate
      SyncFifo_OUT5 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 32
      )
      port map (
         wr_clk => axiClk_i,
         din    => r.period(i),
         rd_clk => devClk_i,
         dout   => period_o(i)
      );
   end generate GEN_PERIOD_OUT;
---------------------------------------------------------------------
end rtl;
