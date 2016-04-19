-------------------------------------------------------------------------------
-- Title      : DAQ for JESD ADC
-------------------------------------------------------------------------------
-- File       : AmcAxisDaqMux.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-14
-- Last update: 2016-03-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Data acquisition top module:
--     Choose 2 (L_AXI_G) out of 6 (L_G) Channels for DAQ.
--     Module handles AXI stream data acquisition on two AXI Stream lanes.       
--     Each AXI stream contains a multiplexer for channel selection.
--     According to s_muxSel value the multiplexer works as follows:
--         0 - Disabled, 1 - Ch1, 2 - Ch2, 3 - Ch3, 4 - Ch4, 5 - Ch5, 6 - Ch6    
--     
--     Module has its own AxiLite register interface.
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

use work.Jesd204bPkg.all;

entity AmcAxisDaqMux is
   generic (
      TPD_G : time := 1 ns;

      -- AXI Lite and stream generics
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C;

      --Number of data lanes
      L_G : positive := 6;

      --Number of AXIS lanes (1 to 2)
      L_AXI_G : positive := 2);
   port (

      -- Clocks and Resets
      axiClk : in sl;
      axiRst : in sl;

      -- Clocks and Resets   
      devClk_i : in sl;
      devRst_i : in sl;

      -- External DAQ trigger input
      trigHw_i : in sl;
      
      -- Sw trigger output for external connect between modules
      trigSw_o : out sl;
      
      -- AXI-Lite Register Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Sample data input 
      sampleDataArr_i : in sampleDataArray(L_G-1 downto 0);
      dataValidVec_i  : in slv(L_G-1 downto 0);

      -- AXI Streaming Interface (combine two channels and send over AXI Stream)
      rxAxisMasterArr_o : out AxiStreamMasterArray(L_AXI_G-1 downto 0);
      rxAxisSlaveArr_i  : in  AxiStreamSlaveArray(L_AXI_G-1 downto 0);
      rxAxisCtrlArr_i   : in  AxiStreamCtrlArray(L_AXI_G-1 downto 0)
      );
end AmcAxisDaqMux;

architecture rtl of AmcAxisDaqMux is

   -- Internal signals

   -- DAQ signals 
   signal s_enAxi             : slv(L_AXI_G-1 downto 0);
   signal s_sampleDataArrMux  : sampleDataArray(L_AXI_G-1 downto 0) := (others => (others => '0'));
   signal s_dataValidVecMux   : slv(L_AXI_G-1 downto 0)             := (others => '0');
   signal s_axisPacketSizeReg : slv(31 downto 0);
   signal s_laneNum           : IntegerArray(L_AXI_G-1 downto 0);
   signal s_muxSel            : Slv4Array(L_AXI_G-1 downto 0);
   signal s_rateDiv           : slv(15 downto 0);

   -- Axi Stream

   -- Trigger conditioning
   signal s_trigHwMask  : sl;
   signal s_trigHw      : sl;   
   signal s_trigSw      : sl;
   signal s_trigSwSync  : sl;
   signal s_mode        : sl;
   signal s_trigComb    : sl;

   -- Generate pause signal logic OR
   signal s_pauseVec    : slv(L_AXI_G-1 downto 0);
   signal s_overflowVec : slv(L_AXI_G-1 downto 0);
   signal s_idleVec     : slv(L_AXI_G-1 downto 0);
   signal s_errorVec    : slv(L_AXI_G-1 downto 0);
   signal s_pause       : sl;
   signal s_idle        : sl;
   signal s_overflow    : sl;
   signal s_error       : sl;
   signal s_status      : Slv32Array(L_AXI_G-1 downto 0);
   signal s_pctCntVec   : Slv26Array(L_AXI_G-1 downto 0);
   
   
begin
   -- Check JESD generics
   assert (1 <= L_G and L_G <= 16) report "L_G must be between 1 and 16" severity failure;
   assert (1 <= L_AXI_G and L_AXI_G <= 2) report "L_AXI_G must be between 1 and 2"severity failure;

   -----------------------------------------------------------
   -- AXI lite
   ----------------------------------------------------------- 

   -- axiLite register interface
   AxiLiteRegItf_INST : entity work.AmcAxiLiteDaqRegItf
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         L_AXI_G          => L_AXI_G)
      port map (
         axiClk_i => axiClk,
         axiRst_i => axiRst,

         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,

         -- DevClk domain
         devClk_i => devClk_i,
         devRst_i => devRst_i,

         status_i => s_status,

         trigSw_o         => s_trigSw,
         trigHwMask_o     => s_trigHwMask,
         rateDiv_o        => s_rateDiv,
         axisPacketSize_o => s_axisPacketSizeReg,
         muxSel_o         => s_muxSel,
         mode_o           => s_mode
         );
   -----------------------------------------------------------
   -- Trigger and rate
   -----------------------------------------------------------

   -- Synchronise external HW trigger input to devClk_i
   U_SynchronizerHW : entity work.Synchronizer
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         OUT_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 2,
         BYPASS_SYNC_G  => false,
         INIT_G         => "0")
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => trigHW_i,
         dataOut => s_trigHw
         );
   
   -- Synchronise SW trigger to equalize the delay between modules
   U_SynchronizerSW : entity work.Synchronizer
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         OUT_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 2,
         BYPASS_SYNC_G  => false,
         INIT_G         => "0")
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => trigHW_i,
         dataOut => s_trigSwSync
         );

   -- Combine both SW and HW triggers
   s_trigComb <= (s_trigHw and s_trigHwMask) or s_trigSwSync;
   trigSw_o   <= s_trigSw;
   
   -----------------------------------------------------------
   -- MULTIPLEXER logic
   -----------------------------------------------------------    
   comb : process (dataValidVec_i, s_muxSel, sampleDataArr_i) is
   begin
      for I in L_AXI_G-1 downto 0 loop
         if (s_muxSel(I) <= L_G and s_muxSel(I) > 0) then
            s_sampleDataArrMux(I) <= sampleDataArr_i(conv_integer(s_muxSel(I))-1);
            s_dataValidVecMux(I)  <= dataValidVec_i(conv_integer(s_muxSel(I))-1);
            s_enAxi(I)            <= '1';
            s_laneNum(I)          <= conv_integer(s_muxSel(I));
         else
            s_sampleDataArrMux(I) <= (others => '0');
            s_dataValidVecMux(I)  <= '0';
            s_enAxi(I)            <= '0';
            s_laneNum(I)          <= 0;
         end if;
      end loop;
   ----------------------
   end process comb;

   -----------------------------------------------------------
   -- AXI stream and DAQ
   ----------------------------------------------------------- 
   -- AXI stream interface one module per lane
   -- The DDR burst interface should be able to receive up to 100 Gb/s
   genPauseSignal : for I in L_AXI_G-1 downto 0 generate
      s_pauseVec(I)    <= rxAxisCtrlArr_i(I).pause;
      s_overflowVec(I) <= rxAxisCtrlArr_i(I).overflow;
      s_idleVec(I)     <= rxAxisCtrlArr_i(I).idle;
      
   end generate genPauseSignal;

   -- Start the next AXI stream packet transfer transfer when all FIFOs are empty  
   s_pause    <= uOr(s_pauseVec);
   s_overflow <= uOr(s_overflowVec);
   s_idle     <= uAnd(s_idleVec);
   s_error    <= uOr(s_errorVec);

   -- AXI stream interface two parallel lanes 
   genAxiStreamLanes : for I in L_AXI_G-1 downto 0 generate
      AxiStreamDaq_INST : entity work.AmcAxisDaq
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            enable_i       => s_enAxi(I),
            devClk_i       => devClk_i,
            devRst_i       => devRst_i,
            laneNum_i      => s_laneNum(I),
            axiNum_i       => I,
            packetSize_i   => s_axisPacketSizeReg,
            rateDiv_i      => s_rateDiv,
            trig_i         => s_trigComb,
            mode_i         => s_mode,
            rxAxisMaster_o => rxAxisMasterArr_o(I),
            error_o        => s_errorVec(I),
            pctCnt_o       => s_pctCntVec(I),
            pause_i        => s_pause,
            overflow_i     => s_overflow,
            idle_i         => s_idle,
            ready_i        => rxAxisSlaveArr_i(I).tReady,
            sampleData_i   => s_sampleDataArrMux(I),
            dataReady_i    => s_dataValidVecMux(I)
          );
          
      -- Status register assignment
      s_status(I) <= s_pctCntVec(I) & s_enAxi(I) & s_dataValidVecMux(I) & s_errorVec(I) & s_overflowVec(I) & rxAxisSlaveArr_i(I).tReady & s_pauseVec(I);
      --
   end generate genAxiStreamLanes;
------------------------------------- 
end rtl;
