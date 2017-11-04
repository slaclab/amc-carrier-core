-------------------------------------------------------------------------------
-- File       : RtmRfInterlockReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-06-21
-- Last update: 2016-06-21
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity RtmRfInterlockReg is
   generic (
   -- General Configurations
      TPD_G               : time                       := 1 ns;
      AXI_ERROR_RESP_G    : slv(1 downto 0)            := AXI_RESP_SLVERR_C;
      AXIL_ADDR_WIDTH_G   : positive                   := 10
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
 
   -- Dev Clk
      devClk_i          : in  sl;
      devRst_i          : in  sl;

   -- Registers
      mode_o       : out  sl;
      tuneSled_o   : out  sl;
      detuneSled_o : out  sl;
      -- Control Register
      softTrig_o   : out  sl;
      softClear_o  : out  sl;
      loadDelay_o  : out  sl;
      faultClear_o : out  sl;
      bypassMode_o : out  sl;
      
      -- Status Register
      rfOff_i      : in   sl;
      fault_i      : in   sl;
      adcLock_i    : in   sl;
      
      -- IDelay control
      curDelay_i : in Slv9Array(4 downto 0);
      setDelay_o : out  Slv9Array(4 downto 0)
   );
end RtmRfInterlockReg;

architecture rtl of RtmRfInterlockReg is

   type RegType is record
      -- 
      tuneSled    : sl;
      detuneSled  : sl;
      mode        : sl;
      control     : slv(4 downto 0);
      setDelay    : Slv9Array(4 downto 0);
     
      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;
   
   constant REG_INIT_C : RegType := (
      tuneSled    => '0', 
      detuneSled  => '0',      
      mode        => '0', 
      control     => (others => '0'),
      setDelay    => (others => (others =>'0')),
      
      -- AXI lite      
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   -- Integer address
   signal s_RdAddr: natural := 0;
   signal s_WrAddr: natural := 0;
   
   -- Read-only synced 
   signal s_status   : slv(2 downto 0);
   signal s_curDelay : Slv9Array(4 downto 0);
   -- 
begin
   
   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer( axilReadMaster.araddr(AXIL_ADDR_WIDTH_G-1 downto 2));
   s_WrAddr <= conv_integer( axilWriteMaster.awaddr(AXIL_ADDR_WIDTH_G-1 downto 2)); 
   
   comb : process (axilReadMaster, axilWriteMaster, r, axiRst_i, s_curDelay, s_RdAddr, s_WrAddr, s_status) is
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
               v.mode := axilWriteMaster.wdata(0);
            when 16#01# => -- ADDR (0x4)
               v.tuneSled     := axilWriteMaster.wdata(0);                
            when 16#02# => -- ADDR (0x8)
               v.detuneSled   := axilWriteMaster.wdata(0);
            when 16#03# => -- ADDR (0xC)
               v.control    := axilWriteMaster.wdata(r.control'range);
            when 16#20# to 16#2F# =>
               for i in 4 downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = i) then
                     v.setDelay(i) := axilWriteMaster.wdata(r.setDelay(i)'range);
                  end if;
               end loop;               
            when others =>
               axilWriteResp     := AXI_ERROR_RESP_G;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_ERROR_RESP_G);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>  -- ADDR (0x0)
               v.axilReadSlave.rdata(0)  := r.mode;
            when 16#01# =>  -- ADDR (0x4)
               v.axilReadSlave.rdata(0)  := r.tuneSled;               
            when 16#02# =>  -- ADDR (0x8)
               v.axilReadSlave.rdata(0)  := r.detuneSled;
            when 16#03# =>  -- ADDR (0xc)
               v.axilReadSlave.rdata(r.control'range) := r.control;                             
            when 16#10# =>  -- ADDR (0x40)
               v.axilReadSlave.rdata(s_status'range)  := s_status;
            when 16#20# to 16#2F# => -- ADDR (0x80)
               for i in 4 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata(r.setDelay(i)'range)  := r.setDelay(i);
                  end if;
               end loop;
            when 16#30# to 16#3F# => -- ADDR (0xC0)
               for i in 4 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata(s_curDelay(i)'range)  := s_curDelay(i);
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
   Sync_IN0 : entity work.SynchronizerVector
   generic map (
      TPD_G        => TPD_G,
      WIDTH_G      => s_status'length
   )
   port map (
      dataIn(0) => fault_i,
      dataIn(1) => adcLock_i,
      dataIn(2) => rfOff_i,      
      clk       => axiClk_i,
      dataOut   => s_status
   );
   
   GEN_IDELAY_IN : for i in 4 downto 0 generate
      Sync_IN1 : entity work.SynchronizerVector
      generic map (
         TPD_G        => TPD_G,
         WIDTH_G      => curDelay_i(i)'length
      )
      port map (
         clk       => axiClk_i,
         dataIn    => curDelay_i(i),   
         dataOut   => s_curDelay(i)
      );
   end generate GEN_IDELAY_IN;
      
   -- Output assignment and synchronization
   Sync_OUT0 : entity work.Synchronizer
   generic map (
      TPD_G        => TPD_G
   )
   port map (
      dataIn    => r.mode,
      clk       => devClk_i,
      dataOut   => mode_o
   );
   
   Sync_OUT1 : entity work.Synchronizer
   generic map (
      TPD_G        => TPD_G
   )
    port map (
      dataIn    => r.detuneSled,
      clk       => devClk_i,
      dataOut   => detuneSled_o
   );
   
   Sync_OUT2 : entity work.Synchronizer
   generic map (
      TPD_G        => TPD_G
   )
    port map (
      dataIn    => r.tuneSled,
      clk       => devClk_i,
      dataOut   => tuneSled_o
   );
   
   Sync_OUT3 : entity work.SynchronizerEdge
   generic map (
      TPD_G        => TPD_G
   )
   port map (
      clk    => devClk_i,   
      dataIn => r.control(0),  
      risingEdge => softTrig_o  -- Rising edge
   );
   
   Sync_OUT4 : entity work.SynchronizerEdge
   generic map (
      TPD_G        => TPD_G
   )
   port map (
      clk    => devClk_i,   
      dataIn => r.control(1),  
      risingEdge => softClear_o  -- Rising edge
   );  

   Sync_OUT5 : entity work.SynchronizerEdge
   generic map (
      TPD_G        => TPD_G
   )
   port map (
      clk    => devClk_i,   
      dataIn => r.control(2),  -- Only sync
      dataOut => loadDelay_o
   );

   Sync_OUT6 : entity work.SynchronizerOneShot
   generic map (
      TPD_G         => TPD_G,
      PULSE_WIDTH_G => 119 -- 1 us
   )
   port map (
      clk     => devClk_i,   
      dataIn  => r.control(3),  
      dataOut => faultClear_o -- Rising edge
   ); 

   Sync_OUT7 : entity work.SynchronizerEdge
   generic map (
      TPD_G        => TPD_G
   )
   port map (
      clk    => devClk_i,   
      dataIn => r.control(4),  -- Only sync
      dataOut => bypassMode_o
   );   
   
   GEN_IDELAY_OUT : for i in 4 downto 0 generate
      Sync_OUT4 : entity work.SynchronizerVector
      generic map (
         TPD_G        => TPD_G,
         WIDTH_G      => r.setDelay(i)'length
      )
      port map (
         dataIn => r.setDelay(i),  
         clk    => devClk_i,
         dataOut=> setDelay_o(i)
      );
   end generate GEN_IDELAY_OUT;
---------------------------------------------------------------------
end rtl;
