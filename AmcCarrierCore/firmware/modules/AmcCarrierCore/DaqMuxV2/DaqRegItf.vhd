-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for DAQ register access  V2
-------------------------------------------------------------------------------
-- File       : DaqRegItf.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2015-11-02
-- Platform   : 
-- Standard   : VHDL'93/02
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
      TPD_G : time := 1 ns;

      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C;

      -- Number of Axi lanes (1 to 16)
      N_DATA_OUT_G : positive := 8
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

      -- Registers
      daqStatus_i      : in  Slv32Array(N_DATA_OUT_G-1 downto 0);
      trigStatus_i     : in  slv(5 downto 0);
      timeStamp_i      : in slv(64-1 downto 0);
      
      -- Control
      trigSw_o          : out sl;
      trigCascMask_o    : out sl;
      trigHwAutoRearm_o : out sl;
      trigHwArm_o       : out sl;
      freezeSw_o        : out sl;
      freezeHwMask_o    : out sl;
      
      clearStatus_o     : out sl;
      trigMode_o        : out sl;
      headerEn_o        : out sl;      
      
      -- DAQ parameters      
      dataSize_o        : out slv(31 downto 0);
      rateDiv_o         : out slv(15 downto 0);
      muxSel_o          : out Slv5Array(N_DATA_OUT_G-1 downto 0);

      --
      signWidth_o       : out Slv5Array(N_DATA_OUT_G-1 downto 0);
      data16or32_o      : out slv(N_DATA_OUT_G-1 downto 0);
      signed_o          : out slv(N_DATA_OUT_G-1 downto 0);
      averaging_o       : out slv(N_DATA_OUT_G-1 downto 0)
   );   
end DaqRegItf;

architecture rtl of DaqRegItf is

   type RegType is record
      -- Registers Control (RW)
      control        : slv(8 downto 0);
      rateDiv        : slv(15 downto 0);
      dataSize       : slv(31 downto 0);
      muxSel         : Slv5Array(N_DATA_OUT_G-1 downto 0);
      dataFormat     : Slv8Array(N_DATA_OUT_G-1 downto 0);

      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;
   
   constant REG_INIT_C : RegType := (
      control        => "101000110",
      rateDiv        => x"0001",      
      dataSize       => x"0000_0800",
      muxSel         => (others => (others =>'0')), --(1 => '0'&x"1"  ,0 => '0'&x"3"),
      dataFormat     => (others => "00100000"),    --(1 => "00000000",0 => "00100000"),
      
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Integer address
   signal s_RdAddr : natural := 0;
   signal s_WrAddr : natural := 0;
   
   signal s_trigStatus     : slv(trigStatus_i'range);
   signal s_daqStatus      : slv32Array(N_DATA_OUT_G-1 downto 0);
   signal s_timeStamp      : slv(64-1 downto 0);
   
begin

   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer(axilReadMaster.araddr(9 downto 2));
   s_WrAddr <= conv_integer(axilWriteMaster.awaddr(9 downto 2));

   comb : process (axiRst_i, axilReadMaster, axilWriteMaster, r, s_RdAddr, s_WrAddr, s_daqStatus, s_trigStatus, s_timeStamp) is
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
               axilWriteResp := AXI_ERROR_RESP_G;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_ERROR_RESP_G);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>              -- ADDR (0)
               v.axilReadSlave.rdata(r.control'range) := r.control;
            when 16#01# =>              -- ADDR (4)
               v.axilReadSlave.rdata(trigStatus_i'range) := s_trigStatus;               
            when 16#02# =>              -- ADDR (8)
               v.axilReadSlave.rdata(r.rateDiv'range) := r.rateDiv;
            when 16#03# =>              -- ADDR (12)
               v.axilReadSlave.rdata(r.dataSize'range) := r.dataSize;
            when 16#04# =>              -- ADDR (12)
               v.axilReadSlave.rdata(r.dataSize'range) := s_timeStamp(64-1 downto 32);
            when 16#05# =>              -- ADDR (12)
               v.axilReadSlave.rdata(r.dataSize'range) := s_timeStamp(32-1 downto 0);
            when 16#10# to 16#1F# =>    -- ADDR (64)
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(r.muxSel(I)'range) := r.muxSel(I);
                  end if;
               end loop;
            when 16#20# to 16#2F# =>     -- ADDR (128)
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(s_daqStatus(I)'range)  := s_daqStatus(I);
                  end if;
               end loop;
            when 16#30# to 16#3F# =>    -- ADDR (192)
               for I in (N_DATA_OUT_G-1) downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(r.dataFormat(I)'range) := r.dataFormat(I);
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
   GEN_IN_0: for I in N_DATA_OUT_G-1 downto 0 generate
      SyncFifo_IN : entity work.SynchronizerFifo
      generic map (
        TPD_G        => TPD_G,
        DATA_WIDTH_G => 32
      )
      port map (
        wr_clk => devClk_i,
        din    => daqStatus_i(I),
        rd_clk => axiClk_i,
        dout   => s_daqStatus(I) 
      );
   end generate GEN_IN_0;
   
   SyncFifo_IN0 : entity work.SynchronizerFifo
   generic map (
     TPD_G        => TPD_G,
     DATA_WIDTH_G => 6
   )
   port map (
     wr_clk => devClk_i,
     din    => trigStatus_i,
     rd_clk => axiClk_i,
     dout   => s_trigStatus 
   );

   SyncFifo_IN1 : entity work.SynchronizerFifo
   generic map (
     TPD_G        => TPD_G,
     DATA_WIDTH_G => 64
   )
   port map (
     wr_clk => devClk_i,
     din    => timeStamp_i,
     rd_clk => axiClk_i,
     dout   => s_timeStamp
   );


   ------------------------------------------------
   -- Output assignment and synchronisation
   ------------------------------------------------   
   Sync_OUT0 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(0),
         dataOut => trigSw_o
         );
         
   Sync_OUT1 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(1),
         dataOut => trigCascMask_o
         );      
   
   Sync_OUT2 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(2),
         dataOut => trigHwAutoRearm_o
         );
         
   Sync_OUT3 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(3),
         dataOut => trigHwArm_o
         );   
         
   Sync_OUT4 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(4),
         dataOut => clearStatus_o
         );
         
   Sync_OUT5 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(5),
         dataOut => trigMode_o
         );

   Sync_OUT6 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(6),
         dataOut => headerEn_o
         );

   Sync_OUT7 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(7),
         dataOut => freezeSw_o
         );         

   Sync_OUT8 : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G
         )
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(8),
         dataOut => freezeHwMask_o
         );       
         
         
         
   SyncFifo_OUT0 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => dataSize_o'length
         )
      port map (
         wr_clk => axiClk_i,
         din    => r.dataSize,
         rd_clk => devClk_i,
         dout   => dataSize_o
         );

   SyncFifo_OUT1 : entity work.SynchronizerFifo
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
   
   GEN_OUT_0 : for I in N_DATA_OUT_G-1 downto 0 generate
      SyncFifo_OUT : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 5
            )
         port map (
            wr_clk => axiClk_i,
            din    => r.muxSel(I),
            rd_clk => devClk_i,
            dout   => muxSel_o(I)
            );
   end generate GEN_OUT_0;
   
   
   GEN_OUT_1 : for I in N_DATA_OUT_G-1 downto 0 generate
      SyncFifo_OUT : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 5
            )
         port map (
            wr_clk => axiClk_i,
            din    => r.dataFormat(I)(4 downto 0),
            rd_clk => devClk_i,
            dout   => signWidth_o(I)
            );
      
      Sync_OUT0 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G
            )
         port map (
            clk     => devClk_i,
            rst     => devRst_i,
            dataIn  => r.dataFormat(I)(5),
            dataOut => data16or32_o(I)
            );
            
      Sync_OUT1 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G
            )
         port map (
            clk     => devClk_i,
            rst     => devRst_i,
            dataIn  => r.dataFormat(I)(6),
            dataOut => signed_o(I)
            );            
            
      Sync_OUT2 : entity work.Synchronizer
         generic map (
            TPD_G => TPD_G
            )
         port map (
            clk     => devClk_i,
            rst     => devRst_i,
            dataIn  => r.dataFormat(I)(7),
            dataOut => averaging_o(I)
            );
      
   end generate GEN_OUT_1;

---------------------------------------------------------------------
end rtl;


