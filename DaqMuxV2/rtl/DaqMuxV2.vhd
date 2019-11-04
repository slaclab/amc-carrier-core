-------------------------------------------------------------------------------
-- File       : DaqMuxV2.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-07-12
-- Last update: 2018-03-14
-------------------------------------------------------------------------------
-- Description: Data acquisition top module:
--              https://confluence.slac.stanford.edu/display/ppareg/AmcAxisDaqV2+Requirements
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
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library amc_carrier_core; 

entity DaqMuxV2 is
   generic (
      TPD_G                  : time                  := 1 ns;
      DECIMATOR_EN_G         : boolean               := true;
      WAVEFORM_TDATA_BYTES_G : positive range 4 to 8 := 4;
      FRAME_BWIDTH_G         : positive              := 10;  -- Axi stream frame size Dafault 10: 4096 byte frames
      BAY_INDEX_G            : sl;
      -- Number of data lanes
      N_DATA_IN_G            : positive              := 16;
      --Number of output Axi Stream Lanes
      N_DATA_OUT_G           : positive              := 4);
   port (

      -- Clocks and Resets
      axiClk : in sl;
      axiRst : in sl;

      -- Clocks and Resets   
      devClk_i : in sl;
      devRst_i : in sl;

      -- External DAQ trigger input
      trigHw_i : in sl;

      -- Cascaded Sw trigger for external connection between modules
      trigCasc_i : in  sl;
      trigCasc_o : out sl;

      -- Cascaded Arm trigger for external connection between modules      
      armCasc_i : in  sl := '0';
      armCasc_o : out sl;

      -- Freeze buffers
      freezeHw_i : in sl;

      -- Time-stamp and bsa (if enabled it will be added to start of data)
      timeStamp_i : in slv(63 downto 0)  := (others => '1');
      bsa_i       : in slv(127 downto 0) := (others => '1');
      dmod_i      : in slv(191 downto 0) := (others => '1');

      -- AXI-Lite Register Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Sample data input 
      sampleDataArr_i  : in slv32Array(N_DATA_IN_G-1 downto 0);
      sampleValidVec_i : in slv(N_DATA_IN_G-1 downto 0);
      linkReadyVec_i   : in slv(N_DATA_IN_G-1 downto 0);

      -- Output AXI Streaming Interface (Has to be synced with waveform clk)
      wfClk_i           : in  sl;
      wfRst_i           : in  sl;
      rxAxisMasterArr_o : out AxiStreamMasterArray(N_DATA_OUT_G-1 downto 0);
      rxAxisSlaveArr_i  : in  AxiStreamSlaveArray(N_DATA_OUT_G-1 downto 0);
      rxAxisCtrlArr_i   : in  AxiStreamCtrlArray(N_DATA_OUT_G-1 downto 0)
      );
end DaqMuxV2;

architecture rtl of DaqMuxV2 is

   -- Internal signals
   signal s_sampleDataArr     : slv32Array(N_DATA_IN_G-1 downto 0)  := (others => (others => '0'));
   signal s_sampleValidVec    : slv(N_DATA_IN_G-1 downto 0)         := (others => '0');
   signal s_LinkReadyVec      : slv(N_DATA_IN_G-1 downto 0)         := (others => '0');
   signal s_sampleDataArrMux  : slv32Array(N_DATA_OUT_G-1 downto 0) := (others => (others => '0'));
   signal s_sampleValidVecMux : slv(N_DATA_OUT_G-1 downto 0)        := (others => '0');
   signal s_LinkReadyVecMux   : slv(N_DATA_OUT_G-1 downto 0)        := (others => '0');

   -- DAQ signals 
   signal s_enAxi         : slv(N_DATA_OUT_G-1 downto 0);
   signal s_enTest        : slv(N_DATA_OUT_G-1 downto 0);
   signal s_dataSize      : slv(31 downto 0);
   signal s_muxSel        : Slv5Array(N_DATA_OUT_G-1 downto 0);
   signal s_rateDiv       : slv(15 downto 0);
   signal s_timeStampSync : slv(63 downto 0);
   signal s_bsaSync       : slv(127 downto 0);
   signal s_dmodSync      : slv(191 downto 0);

   -- Trigger related signals
   signal s_trigCascMask    : sl;
   signal s_trigHwAutoRearm : sl;
   signal s_trigHwArm       : sl;
   signal s_clearTrigStatus : sl;
   signal s_trigMode        : sl;
   signal s_daqBusy         : sl;
   signal s_trigStatus      : slv(5 downto 0);
   signal s_trigHeader      : slv(2 downto 0);
   signal s_header          : slv(7 downto 0);
   signal s_trigSw          : sl;
   signal s_trig            : sl;
   signal s_freezeSw        : sl;
   signal s_freezeHwMask    : sl;
   signal s_freeze          : sl;
   signal s_headerEn        : sl;
   signal s_clearStatus     : sl;
   
   signal devRst : sl;

   -- Data Format
   signal s_data16or32 : slv(N_DATA_OUT_G-1 downto 0);
   signal s_averaging  : slv(N_DATA_OUT_G-1 downto 0);
   signal s_signed     : slv(N_DATA_OUT_G-1 downto 0);
   signal s_signWidth  : Slv5Array(N_DATA_OUT_G-1 downto 0);

   -- Generate pause signal logic OR
   signal s_daqBusyVec : slv(N_DATA_OUT_G-1 downto 0);
   signal s_errorVec   : slv(N_DATA_OUT_G-1 downto 0);

   signal s_daqStatus : Slv32Array(N_DATA_OUT_G-1 downto 0);
   signal s_pctCntVec : Slv26Array(N_DATA_OUT_G-1 downto 0);

   -- Axi Stream synchronization to external interface
   signal s_rxAxisMasterArr : AxiStreamMasterArray(N_DATA_OUT_G-1 downto 0);
   signal s_rxAxisSlaveArr  : AxiStreamSlaveArray(N_DATA_OUT_G-1 downto 0);
   signal s_rxAxisCtrlArr   : AxiStreamCtrlArray(N_DATA_OUT_G-1 downto 0);

begin
   -- Check JESD generics
   assert (1 <= N_DATA_IN_G and N_DATA_IN_G <= 29) report "N_DATA_IN_G must be between 1 and 29" severity failure;
   assert (1 <= N_DATA_OUT_G and N_DATA_OUT_G <= 16) report "N_DATA_OUT_G must be between 1 and 16"severity failure;

   -- Help with timing
   U_rst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => devClk_i,
         rstIn  => devRst_i,
         rstOut => devRst);   
   
   -----------------------------------------------------------
   -- Synchronize timestamp_i and bsa
   -- Warning: Not optimal Sync vector used instead of fifo because no input fifo clock available here.
   -- Rationale: The timeStamp and the bsa are registered between the two timing strobes. So this signal is static for 1/360s.
   -----------------------------------------------------------    
   U_SyncTimestamp : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 64)
      port map (
         clk     => devClk_i,
         dataIn  => timeStamp_i,
         dataOut => s_timeStampSync);

   U_SyncBsa : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 128)
      port map (
         clk     => devClk_i,
         dataIn  => bsa_i,
         dataOut => s_bsaSync);

   U_SyncDmd : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 192)
      port map (
         clk     => devClk_i,
         dataIn  => dmod_i,
         dataOut => s_dmodSync);

   -----------------------------------------------------------
   -- AXI lite
   ----------------------------------------------------------- 
   -- axiLite register interface
   U_DaqRegItf : entity amc_carrier_core.DaqRegItf
      generic map (
         TPD_G        => TPD_G,
         N_DATA_IN_G  => N_DATA_IN_G,
         N_DATA_OUT_G => N_DATA_OUT_G)
      port map (
         axiClk_i => axiClk,
         axiRst_i => axiRst,

         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,

         -- DevClk domain
         devClk_i          => devClk_i,
         devRst_i          => devRst,
         -- Status
         daqStatus_i       => s_daqStatus,
         trigStatus_i      => s_trigStatus,
         bsa_i             => s_bsaSync,
         timeStamp_i       => s_timeStampSync,
         trig_i            => s_trig,
         sampleValid_i     => sampleValidVec_i,
         linkReady_i       => linkReadyVec_i,
         -- Config
         trigSw_o          => s_trigSw,
         trigCascMask_o    => s_trigCascMask,
         trigHwAutoRearm_o => s_trigHwAutoRearm,
         trigHwArm_o       => s_trigHwArm,
         freezeSw_o        => s_freezeSw,
         freezeHwMask_o    => s_freezeHwMask,
         clearStatus_o     => s_clearStatus,
         trigMode_o        => s_trigMode,
         headerEn_o        => s_headerEn,
         dataSize_o        => s_dataSize,
         rateDiv_o         => s_rateDiv,
         muxSel_o          => s_muxSel,
         signWidth_o       => s_signWidth,
         data16or32_o      => s_data16or32,
         signed_o          => s_signed,
         averaging_o       => s_averaging);

   -----------------------------------------------------------
   -- Trigger and rate
   -----------------------------------------------------------
   U_DaqTrigger : entity amc_carrier_core.DaqTrigger
      generic map (
         TPD_G => TPD_G)
      port map (
         clk               => devClk_i,
         rst               => devRst,
         trigSw_i          => s_trigSw,
         trigHw_i          => trigHw_i,
         trigCasc_i        => trigCasc_i,
         trigCascMask_i    => s_trigCascMask,
         trigHwAutoRearm_i => s_trigHwAutoRearm,
         trigHwArm_i       => s_trigHwArm,
         armCasc_i         => armCasc_i,

         freezeSw_i     => s_freezeSw,
         freezeHw_i     => freezeHw_i,
         freezeHwMask_i => s_freezeHwMask,

         clearTrigStatus_i => s_clearStatus,
         trigMode_i        => s_trigMode,
         daqBusy_i         => s_daqBusy,
         trigStatus_o      => s_trigStatus,
         trigHeader_o      => s_trigHeader,
         trig_o            => s_trig,
         freeze_o          => s_freeze
         );

   -- Sw trigger goes directly out to Cascade so it is aligned with the next nodule as much as possible
   trigCasc_o <= s_trigSw;
   armCasc_o  <= s_trigHwArm;
   -----------------------------------------------------------
   -- Sync MULTIPLEXER logic
   -----------------------------------------------------------    
   sync : process (devClk_i) is
   begin
      if rising_edge(devClk_i) then
         for i in N_DATA_IN_G-1 downto 0 loop
            -- Register to help with timing
            s_sampleDataArr(i)  <= sampleDataArr_i(i)  after TPD_G;
            s_sampleValidVec(i) <= sampleValidVec_i(i) after TPD_G;
            s_LinkReadyVec(i)   <= linkReadyVec_i(i)   after TPD_G;
         end loop;
         for i in N_DATA_OUT_G-1 downto 0 loop
            -- Data mode
            if (s_muxSel(i) < (N_DATA_IN_G+2) and s_muxSel(i) > 1) then
               s_sampleDataArrMux(i)  <= s_sampleDataArr(conv_integer(s_muxSel(i))-2)  after TPD_G;
               s_sampleValidVecMux(i) <= s_sampleValidVec(conv_integer(s_muxSel(i))-2) after TPD_G;
               s_LinkReadyVecMux(i)   <= s_LinkReadyVec(conv_integer(s_muxSel(i))-2)   after TPD_G;
               s_enAxi(i)             <= '1'                                           after TPD_G;
               s_enTest(i)            <= '0'                                           after TPD_G;
            -- Test mode
            elsif (s_muxSel(i) = 1) then
               s_sampleDataArrMux(i)  <= (others => '0') after TPD_G;
               s_sampleValidVecMux(i) <= '1'             after TPD_G;
               s_LinkReadyVecMux(i)   <= '1'             after TPD_G;
               s_enAxi(i)             <= '1'             after TPD_G;
               s_enTest(i)            <= '1'             after TPD_G;
            -- Disabled
            else
               s_sampleDataArrMux(i)  <= (others => '0') after TPD_G;
               s_sampleValidVecMux(i) <= '0'             after TPD_G;
               s_LinkReadyVecMux(i)   <= '0'             after TPD_G;
               s_enAxi(i)             <= '0'             after TPD_G;
               s_enTest(i)            <= '0'             after TPD_G;
            end if;
         end loop;
      end if;
   ----------------------
   end process sync;

   s_header <= "00000" & s_trigHeader;

   -- AXI stream interface two parallel lanes 
   GEN_OUT_LANES : for i in N_DATA_OUT_G-1 downto 0 generate
      U_DaqLane : entity amc_carrier_core.DaqLane
         generic map (
            TPD_G          => TPD_G,
            BAY_INDEX_G    => BAY_INDEX_G,
            DECIMATOR_EN_G => DECIMATOR_EN_G,
            FRAME_BWIDTH_G => FRAME_BWIDTH_G)
         port map (

            devClk_i => devClk_i,
            devRst_i => devRst,

            -- Controls from registers
            enable_i     => s_enAxi(i),
            test_i       => s_enTest(i),
            timeStamp_i  => s_timeStampSync,
            bsa_i        => s_bsaSync,
            dmod_i       => s_dmodSync,
            headerEn_i   => s_headerEn,
            header_i     => s_header,
            axiNum_i     => i,
            packetSize_i => s_dataSize,
            rateDiv_i    => s_rateDiv,
            trig_i       => s_trig,
            freeze_i     => s_freeze,
            dec16or32_i  => s_data16or32(i),
            mode_i       => s_trigMode,
            averaging_i  => s_averaging(i),

            -- Sign extension
            signWidth_i => s_signWidth(i),
            signed_i    => s_signed(i),

            -- Status 
            error_o  => s_errorVec(i),
            pctCnt_o => s_pctCntVec(i),
            busy_o   => s_daqBusyVec(i),

            -- DAQ flow and data
            sampleData_i  => s_sampleDataArrMux(i),
            sampleValid_i => s_sampleValidVecMux(i),
            LinkReady_i   => s_LinkReadyVecMux(i),

            -- Axi stream out
            rxAxisCtrl_i   => s_rxAxisCtrlArr(i),
            rxAxisSlave_i  => s_rxAxisSlaveArr(i),
            rxAxisMaster_o => s_rxAxisMasterArr(i)
            );

      -- Status register assignment
      s_daqStatus(i) <= s_pctCntVec(i) & s_enAxi(i) & s_LinkReadyVecMux(i) & s_errorVec(i) & rxAxisCtrlArr_i(i).overflow & rxAxisSlaveArr_i(i).tReady & rxAxisCtrlArr_i(i).pause;

      -- Synchronize stream with the output waveform clock
      U_AsyncOutFifo : entity surf.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 1,
            BRAM_EN_G           => true,
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            CASCADE_PAUSE_SEL_G => 0,
            FIFO_ADDR_WIDTH_G   => 5,
            FIFO_FIXED_THRESH_G => true,
            INT_PIPE_STAGES_G   => 0,
            PIPE_STAGES_G       => 1,
            SLAVE_AXI_CONFIG_G  => ssiAxiStreamConfig(4, TKEEP_FIXED_C, TUSER_FIRST_LAST_C, 0, 3),  -- No tdest bits, 3 tUser bits
            MASTER_AXI_CONFIG_G => ssiAxiStreamConfig(WAVEFORM_TDATA_BYTES_G, TKEEP_FIXED_C, TUSER_FIRST_LAST_C, 0, 3))  -- Must match AmcCarrierCore.WAVEFORM_TDATA_BYTES_G generic configuration
         port map (
            sAxisClk    => devClk_i,
            sAxisRst    => devRst,
            sAxisMaster => s_rxAxisMasterArr(i),
            sAxisSlave  => s_rxAxisSlaveArr(i),
            mAxisClk    => wfClk_i,
            mAxisRst    => wfRst_i,
            mAxisMaster => rxAxisMasterArr_o(i),
            mAxisSlave  => rxAxisSlaveArr_i(i));
      -----------------------------------------------------------------

      -- Separately synchronize AXI Stream control
      Sync_0 : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => devClk_i,
            dataIn  => rxAxisCtrlArr_i(i).pause,
            dataOut => s_rxAxisCtrlArr(i).pause);

      Sync_1 : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => devClk_i,
            dataIn  => rxAxisCtrlArr_i(i).overflow,
            dataOut => s_rxAxisCtrlArr(i).overflow);

      Sync_2 : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => devClk_i,
            dataIn  => rxAxisCtrlArr_i(i).idle,
            dataOut => s_rxAxisCtrlArr(i).idle);
   end generate GEN_OUT_LANES;
   ----------------------------------------
   s_daqBusy <= uOr(s_daqBusyVec);


------------------------------------- 
end rtl;
