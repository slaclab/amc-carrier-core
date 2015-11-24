-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for DAQ register access  
-------------------------------------------------------------------------------
-- File       : AmcAxiLiteDaqRegItf.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2015-11-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Register decoding for DAQ
--               0x00 (W) - Trigger data acquisition on both AXI stream channels. Note: This is an Auto clear register!
--               0x02 (RW)- Sample rate divider(Decimator): 
--                                  0 = Sample rate,
--                                  1 = Sample rate/2,
--                                  2 = Sample rate/4,
--                                  3 = Sample rate/8, etc.
--               0x03 (RW) - DAQ packet size (24 bit) (max 0x30000)
--               0x1X (RW) - M
--                   bit 7-4: Stream 1 Channel select Multiplexer(0 - Disabled, 1 - Ch1, 2 - Ch2, 3 - Ch3, etc.)
--                   bit 3-0: Stream 0 Channel select Multiplexer(0 - Disabled, 1 - Ch1, 2 - Ch2, 3 - Ch3, etc.)
--               0x2X (R) - Status register
--                   bit 31-15: - Number of packets (frames) sent
--                   bit 5: - AXI stream enabled
--                   bit 4: - Jesd lane valid
--                   bit 3: - Error during last Acquisition
--                   bit 2: - Buffer overflow
--                   bit 1: - Ready for new trigger
--                   bit 0: - Busy
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.Jesd204bPkg.all;

entity AmcAxiLiteDaqRegItf is
   generic (
      -- General Configurations
      TPD_G : time := 1 ns;

      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C;

      -- Number of Axi lanes (0 to 1)
      L_AXI_G : positive := 2
      );    
   port (
      -- AXI Clk
      axiClk_i : in sl;
      axiRst_i : in sl;

      -- Axi-Lite Register Interface (locClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- JESD devClk
      devClk_i : in sl;
      devRst_i : in sl;

      -- JESD registers
      status_i         : in  Slv32Array(L_AXI_G-1 downto 0);

      -- Control
      trigSw_o         : out sl;
      axisPacketSize_o : out slv(31 downto 0);
      rateDiv_o        : out slv(15 downto 0);
      muxSel_o         : out Slv4Array(L_AXI_G-1 downto 0)
      );   
end AmcAxiLiteDaqRegItf;

architecture rtl of AmcAxiLiteDaqRegItf is

   type RegType is record
      -- JESD Control (RW)
      commonCtrl     : slv(0 downto 0);
      axisPacketSize : slv(axisPacketSize_o'range);
      rateDiv        : slv(15 downto 0);
      muxSel         : Slv4Array(L_AXI_G-1 downto 0);

      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;
   
   constant REG_INIT_C : RegType := (
      commonCtrl     => "0",
      axisPacketSize => x"0030_0000",
      rateDiv        => x"0000",
      muxSel         => (x"2", x"1"),

      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Integer address
   signal s_RdAddr : natural := 0;
   signal s_WrAddr : natural := 0;

   signal s_status : Slv32Array(L_AXI_G-1 downto 0);
   
begin

   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= slvToInt(axilReadMaster.araddr(9 downto 2));
   s_WrAddr <= slvToInt(axilWriteMaster.awaddr(9 downto 2));

   comb : process (axiRst_i, axilReadMaster, axilWriteMaster, r, s_RdAddr, s_WrAddr, s_status) is
      variable v             : RegType;
      variable axilStatus    : AxiLiteStatusType;
      variable axilWriteResp : slv(1 downto 0);
      variable axilReadResp  : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Auto clear (trigger register) TODO check in simulation
      v.commonCtrl := "0";
      ----------------------------------------------------------------------------------------------
      -- Axi-Lite interface
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axilStatus);

      if (axilStatus.writeEnable = '1') then
         axilWriteResp := ite(axilWriteMaster.awaddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_ERROR_RESP_G);
         case (s_WrAddr) is
            when 16#00# =>              -- ADDR (0)
               v.commonCtrl := axilWriteMaster.wdata(0 downto 0);
            when 16#02# =>              -- ADDR (8)
               v.rateDiv := axilWriteMaster.wdata(15 downto 0);
            when 16#03# =>              -- ADDR (12)
               v.axisPacketSize := axilWriteMaster.wdata(axisPacketSize_o'range);
            when 16#10# to 16#1F# =>
               for I in (L_AXI_G-1) downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = I) then
                     v.muxSel(I) := axilWriteMaster.wdata(3 downto 0);
                  end if;
               end loop;
            when others =>
               axilWriteResp := AXI_ERROR_RESP_G;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_ERROR_RESP_G);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>              -- ADDR (0)
               v.axilReadSlave.rdata(0 downto 0) := r.commonCtrl;
            when 16#02# =>              -- ADDR (8)
               v.axilReadSlave.rdata(15 downto 0) := r.rateDiv;
            when 16#03# =>              -- ADDR (12)
               v.axilReadSlave.rdata(axisPacketSize_o'range) := r.axisPacketSize;
            when 16#10# to 16#1F# =>    -- ADDR (64)
               for I in (L_AXI_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(3 downto 0) := r.muxSel(I);
                  end if;
               end loop;
            when 16#20# to 16#2F# =>     -- ADDR (128)
               for I in (L_AXI_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(31 downto 0)  := s_status(I);
                  end if;
               end loop;
            when others =>
               axilReadResp := AXI_ERROR_RESP_G;
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
   GEN_0: for I in L_AXI_G-1 downto 0 generate
      SyncFifo_IN0 : entity work.SynchronizerFifo
      generic map (
        TPD_G        => TPD_G,
        DATA_WIDTH_G => 32
      )
      port map (
        wr_clk => devClk_i,
        din    => status_i(I),
        rd_clk => axiClk_i,
        dout   => s_status(I) 
      );
   end generate GEN_0;

   -- Output assignment and synchronisation
   Sync_OUT1 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.commonCtrl(0),
         dataOut => trigSw_o
         );

   SyncFifo_OUT2 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => axisPacketSize_o'length
         )
      port map (
         wr_clk => axiClk_i,
         din    => r.axisPacketSize,
         rd_clk => devClk_i,
         dout   => axisPacketSize_o
         );

   SyncFifo_OUT3 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 16
         )
      port map (
         wr_clk => axiClk_i,
         din    => r.rateDiv,
         rd_clk => devClk_i,
         dout   => rateDiv_o
         );

   GEN_1 : for I in L_AXI_G-1 downto 0 generate
      SyncFifo_OUT0 : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 4
            )
         port map (
            wr_clk => axiClk_i,
            din    => r.muxSel(I),
            rd_clk => devClk_i,
            dout   => muxSel_o(I)
            );
   end generate GEN_1;
---------------------------------------------------------------------
end rtl;
