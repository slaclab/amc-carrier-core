-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for Signal generator control  
-------------------------------------------------------------------------------
-- File       : LvdsDacRegItf.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2015-04-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Register decoding for Signal generator
--               0x00 (RW)- Control Register
--                              Bit0: Enable DAC signal generator
--                              Bit1: Load TAP delays from registers tapDelayIn_o
--               0x01 (RW)- Polarity of the corresponding LVDS output (15 downto 0) 
--                            - '0' Regular
--                            - '1' Inverted
--               0x02 (RW)- Signal period size. In number of Block RAM addresses (two samples per address). Zero inclusive.
--                          Example for 16 sample period write 7.
--               0x1X (RW)- Set tap delay values for corresponding LVDS DAC outputs
--               0x2X (R) - Current tap delay values
--
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 LLRF Development'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 LLRF Development', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity LvdsDacRegItf is
   generic (
   -- General Configurations
      TPD_G               : time                       := 1 ns;
      AXI_ERROR_RESP_G    : slv(1 downto 0)            := AXI_RESP_SLVERR_C; 
      DATA_WIDTH_G        : integer range 1 to 32      := 16;      
      ADDR_WIDTH_G        : integer range 1 to (2**24) := 9
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
 
   -- Sample Clk
      devClk_i          : in  sl;
      devRst_i          : in  sl;

   -- Registers
      enable_o          : out sl;
      periodSize_o      : out slv(ADDR_WIDTH_G-1 downto 0);
      polarityMask_o    : out slv(DATA_WIDTH_G-1 downto 0);
      
   --  
      load_o         : out slv(DATA_WIDTH_G-1 downto 0);  
      tapDelaySet_o  : out Slv9Array(DATA_WIDTH_G-1 downto 0);   
      tapDelayStat_i : in  Slv9Array(DATA_WIDTH_G-1 downto 0);
      overflow_i     : in  sl;
      underflow_i    : in  sl
   );   
end LvdsDacRegItf;

architecture rtl of LvdsDacRegItf is

   type RegType is record
      -- JESD Control (RW)
      control      : slv(0 downto 0);
      periodSize   : slv(ADDR_WIDTH_G-1 downto 0);
      polarityMask : slv(DATA_WIDTH_G-1 downto 0);
      load         : slv(DATA_WIDTH_G-1 downto 0);
      --
      tapDelaySet  : Slv9Array(DATA_WIDTH_G-1 downto 0);   

      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;
   
   constant REG_INIT_C : RegType := (
      control      => "0",
      periodSize   => toSlv(16, ADDR_WIDTH_G),
      polarityMask => x"fff4",
      load         => (others =>'0'),      
      tapDelaySet  => (others => (others =>'0') ),
 
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   -- Integer address
   signal s_RdAddr: natural := 0;
   signal s_WrAddr: natural := 0;
   signal s_statusCnt : SlVectorArray(1 downto 0, 31 downto 0);
   signal s_errors    : slv(1 downto 0);
   -- Status
   signal s_tapDelayStat : Slv9Array(DATA_WIDTH_G-1 downto 0); 
begin
   
   s_errors <= overflow_i & underflow_i;
   
   U_SyncStatusVector : entity work.SyncStatusVector
   generic map (
      TPD_G          => TPD_G,
      OUT_POLARITY_G => '1',
      CNT_RST_EDGE_G => true,
      CNT_WIDTH_G    => 32,
      WIDTH_G        => 2)
   port map (
      -- Input Status bit Signals (wrClk domain)
      statusIn  => s_errors,
      -- Output Status bit Signals (rdClk domain)  
      statusOut => open,
      -- Status Bit Counters Signals (rdClk domain) 
      cntRstIn  => '0',
      cntOut    => s_statusCnt,
      -- Clocks and Reset Ports
      wrClk     => devClk_i,
      rdClk     => axiClk_i);
         
   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer( axilReadMaster.araddr(9 downto 2));
   s_WrAddr <= conv_integer( axilWriteMaster.awaddr(9 downto 2)); 
   
   comb : process (axilReadMaster, axilWriteMaster, r, axiRst_i, s_RdAddr, s_WrAddr, s_tapDelayStat, s_statusCnt) is
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
            when 16#00# => -- ADDR (0)
               v.control      := axilWriteMaster.wdata(0 downto 0);
            when 16#01# => -- ADDR (8)
               v.polarityMask  := axilWriteMaster.wdata(DATA_WIDTH_G-1 downto 0);                
            when 16#02# => -- ADDR (12)
               v.periodSize  := axilWriteMaster.wdata(ADDR_WIDTH_G-1 downto 0);
            when 16#03# => -- ADDR (16)
               v.load  := axilWriteMaster.wdata(DATA_WIDTH_G-1 downto 0);               
            when 16#10# to 16#1F# =>
               for I in 15 downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = I) then
                     v.tapDelaySet(I) := axilWriteMaster.wdata(8 downto 0);
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
            when 16#00# =>  -- ADDR (0)
               v.axilReadSlave.rdata(0 downto 0)                := r.control;
            when 16#01# =>  -- ADDR (8)
               v.axilReadSlave.rdata(DATA_WIDTH_G-1 downto 0)   := r.polarityMask;               
            when 16#02# =>  -- ADDR (12)
               v.axilReadSlave.rdata(ADDR_WIDTH_G-1 downto 0)   := r.periodSize;
            when 16#03# =>  -- ADDR (16)
               v.axilReadSlave.rdata(DATA_WIDTH_G-1 downto 0)   := r.load;                 
            when 16#10# to 16#1F# =>
               for I in 15 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(8 downto 0) := r.tapDelaySet(I);
                  end if;
               end loop;   
            when 16#20# to 16#2F# =>
               for I in 15 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(8 downto 0) := s_tapDelayStat(I);
                  end if;
               end loop;
            when 16#30# to 16#3F# =>
               for I in 1 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     for J in 31 downto 0 loop
                        v.axilReadSlave.rdata(J) := s_statusCnt(I, J);
                     end loop;
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
   
   -- Input assignment and synchronisation
   GEN_0 : for I in 15 downto 0 generate
      SyncFifo_IN0 : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 9
            )
         port map (
            wr_clk => devClk_i,
            din    => tapDelayStat_i(I),
            rd_clk => axiClk_i,
            dout   => s_tapDelayStat(I)
         );
   end generate GEN_0;
   
   -- Output assignment and synchronization
   Sync_OUT0 : entity work.Synchronizer
   generic map (
      TPD_G => TPD_G
   )
   port map (
      clk     => devClk_i,
      rst     => devRst_i,
      dataIn  => r.control(0),
      dataOut => enable_o
   );

   SyncFifo_OUT1 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => DATA_WIDTH_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.load,
      rd_clk => devClk_i,
      dout   => load_o
   );
      
   SyncFifo_OUT2 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => ADDR_WIDTH_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.periodSize,
      rd_clk => devClk_i,
      dout   => periodSize_o
   );
   
   SyncFifo_OUT3 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => DATA_WIDTH_G
   )
   port map (
      wr_clk => axiClk_i,
      din    => r.polarityMask,
      rd_clk => devClk_i,
      dout   => polarityMask_o
   );
   
   GEN_1 : for I in 15 downto 0 generate
      SyncFifo_OUT4 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 9
         )
      port map (
         wr_clk => axiClk_i,
         din    => r.tapDelaySet(I),
         rd_clk => devClk_i,
         dout   => tapDelaySet_o(I)
      );
  end generate GEN_1;   
   
---------------------------------------------------------------------
end rtl;
