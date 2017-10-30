-------------------------------------------------------------------------------
-- File       : DaqLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-02
-- Last update: 2017-10-16
-------------------------------------------------------------------------------
-- Description:   This module sends sample data to a single Lane.
--                In non-continuous mode
--                - When data is requested by trig_i = '1' (Has to be 1 c-c).
--                - the module sends data a packet at the time to AXI stream FIFO.
--                Note: Tx pause must indicate that the AXI stream FIFO can hold the whole data packet.
--                Note: The data transmission is enabled only if JESD data is valid LinkReady_i='1'.
--                
--                In continuous mode:
--                - has to be triggered to start
--                - continuously sends 4k frames
--                - the packetSize_i, does not have any function
--                - the freeze_i inserts User bit that freezes the circular buffer 
--
--                More info: https://confluence.slac.stanford.edu/display/ppareg/AmcAxisDaqV2+Requirements
--
--                HeaderWord 0: timeStamp_i(63:32)
--                HeaderWord 1: timeStamp_i(31:0)
--                HeaderWord 2: packetSize_i
--                HeaderWord 3: header_i & dec16or32_i & averaging_i & test_i & '0' & axiNum_i & rateDiv_i
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.DaqMuxV2Pkg.all;

use work.Jesd204bPkg.all;

entity DaqLane is
   generic (
      -- General Configurations
      TPD_G                : time            := 1 ns;
      AXI_ERROR_RESP_G     : slv(1 downto 0) := AXI_RESP_SLVERR_C;
      DECIMATOR_EN_G       : boolean         := true;  -- Include or exclude decimator
      FRAME_BWIDTH_G       : positive        := 10;  -- Dafault 10: 4096 byte frames
      FREZE_BUFFER_TUSER_G : integer         := 2
      );
   port (
      enable_i : in sl;
      test_i   : in sl;

      -- JESD devClk
      devClk_i : in sl;
      devRst_i : in sl;

      -- Lane number AXI number to be inserted into AXI stream
      axiNum_i : integer range 0 to 15;

      -- DAQ
      packetSize_i : in slv(31 downto 0);  -- Min 4
      rateDiv_i    : in slv(15 downto 0);  -- If averaging enabled then only powers of 2 should be used
      trig_i       : in sl              := '0';  -- Must be 1 c-c pulse
      freeze_i     : in sl              := '0';  -- Must be 1 c-c pulse
      averaging_i  : in sl              := '0';  -- Enable decination averaging
      dec16or32_i  : in sl              := '0';  -- Data format
      timeStamp_i  : in slv(63 downto 0);  -- Connected from timing system
      bsa_i        : in slv(127 downto 0);  -- Connected from timing system
      dmod_i       : in slv(191 downto 0);  -- Connected from timing system
      headerEn_i   : in sl              := '0';
      header_i     : in slv(7 downto 0) := x"00";  -- Additional/external header byte

      -- Sign extension
      signWidth_i : in slv(4 downto 0);
      signed_i    : in sl;

      -- Mode of DAQ - '0'  - until packet size and needs trigger (used in new interface)
      --             - '1'  - sends the 4k frames continuously no trigger(used in new interface)
      mode_i : in sl := '0';

      -- Axi Stream
      rxAxisCtrl_i   : in  AxiStreamCtrlType  := AXI_STREAM_CTRL_UNUSED_C;
      rxAxisSlave_i  : in  AxiStreamSlaveType := AXI_STREAM_SLAVE_FORCE_C;
      rxAxisMaster_o : out AxiStreamMasterType;
      error_o        : out sl;          -- Error if tReady drops
      busy_o         : out sl;  -- Busy inhibits trigger in mode_i = '0'
      pctCnt_o       : out slv(25 downto 0);  -- Number of 4096 byte frames 

      sampleData_i  : in slv((GT_WORD_SIZE_C*8)-1 downto 0);
      sampleValid_i : in sl;
      LinkReady_i   : in sl);
end DaqLane;

architecture rtl of DaqLane is

   constant SSI_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(GT_WORD_SIZE_C, TKEEP_FIXED_C, TUSER_FIRST_LAST_C, 4, 3);

   -- Header size constant (so the header size could be quickly adjusted)
   constant HEADER_SIZE_C : positive := 14;

   type StateType is (
      IDLE_S,
      HEADER_S,
      DATA_S);

   type RegType is record
      packetSize   : slv(31 downto 0);
      maxSize      : slv(31 downto 0);
      dataCnt      : slv(packetSize_i'range);
      txAxisMaster : AxiStreamMasterType;
      error        : sl;
      freeze       : sl;
      busy         : sl;
      sof          : sl;
      pctCnt       : slv(pctCnt_o'range);
      trigSh       : slv(3 downto 0);
      rateDiv      : slv(15 downto 0);
      averaging    : sl;
      dec16or32    : sl;
      headerEn     : sl;
      signWidth    : slv(4 downto 0);
      signed       : sl;
      state        : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      packetSize   => (others => '0'),
      maxSize      => (others => '0'),
      dataCnt      => (others => '0'),
      txAxisMaster => AXI_STREAM_MASTER_INIT_C,
      error        => '0',
      freeze       => '0',
      busy         => '0',
      sof          => '1',
      pctCnt       => (others => '0'),
      trigSh       => (others => '0'),
      rateDiv      => (others => '0'),
      averaging    => '0',
      dec16or32    => '0',
      headerEn     => '0',
      signWidth    => (others => '0'),
      signed       => '0',
      state        => IDLE_S);

   signal r               : RegType := REG_INIT_C;
   signal rin             : RegType;
   signal s_rateClk       : sl;
   signal s_trigDecimator : sl;
   signal s_sampValidTst  : sl;
   signal s_sampDataTst   : slv((GT_WORD_SIZE_C*8)-1 downto 0);
   signal s_decSampData   : slv((GT_WORD_SIZE_C*8)-1 downto 0);

   signal packetSizeVar : slv(31 downto 0);
   signal compCheck     : sl;

begin
   -- Do not trigger decimator when busy
   -- because it will zero s_rateClk and data will be missed
   s_trigDecimator <= trig_i and not r.busy;

   -- Applies test data if enabled  
   U_DaqTestSig : entity work.DaqTestSig
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and reset
         clk           => devClk_i,
         rst           => devRst_i,
         -- Configuration
         test_i        => test_i,
         signed_i      => r.signed,
         dec16or32_i   => r.dec16or32,
         signWidth_i   => r.signWidth,
         trig_i        => s_trigDecimator,
         -- Sample data I/O
         sampleData_i  => sampleData_i,
         sampleValid_i => sampleValid_i,
         sampleData_o  => s_sampDataTst,
         sampleValid_o => s_sampValidTst);

   -- Rate divider module:
   -- Decimates data,
   -- Averages decimated data
   GEN_DEC : if (DECIMATOR_EN_G = true) generate
      Decimator_INST : entity work.DaqDecimator
         generic map (
            TPD_G => TPD_G)
         port map (
            clk           => devClk_i,
            rst           => devRst_i,
            sampleData_i  => s_sampDataTst,
            sampleValid_i => s_sampValidTst,
            decSampData_o => s_decSampData,
            dec16or32_i   => r.dec16or32,
            rateDiv_i     => r.rateDiv,
            signed_i      => r.signed,
            trig_i        => s_trigDecimator,
            averaging_i   => r.averaging,
            rateClk_o     => s_rateClk);
   end generate GEN_DEC;

   GEN_N_DEC : if (DECIMATOR_EN_G = false) generate
      s_decSampData <= s_sampDataTst;
      s_rateClk     <= s_sampValidTst;
   end generate GEN_N_DEC;

   U_DspComparator : entity work.DspComparator
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 32)
      port map (
         clk  => devClk_i,
         ain  => packetSizeVar,
         bin  => toSlv(HEADER_SIZE_C, 32),
         lsEq => compCheck);  -- less than or equal to (a <= b) --- (r.packetSize <= HEADER_SIZE_C)  

   comb : process (LinkReady_i, averaging_i, axiNum_i, bsa_i, compCheck,
                   dec16or32_i, devRst_i, dmod_i, enable_i, freeze_i,
                   headerEn_i, header_i, mode_i, packetSize_i, r, rateDiv_i,
                   rxAxisCtrl_i, rxAxisSlave_i, s_decSampData, s_rateClk,
                   signWidth_i, signed_i, test_i, timeStamp_i, trig_i) is
      variable v             : RegType;
      variable axilStatus    : AxiLiteStatusType;
      variable axilWriteResp : slv(1 downto 0);
      variable axilReadResp  : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Register trigger
      v.trigSh := r.trigSh(2 downto 0) & trig_i;

      -- Reset strobing signals
      v.txAxisMaster.tValid := '0';
      v.txAxisMaster.tLast  := '0';
      v.txAxisMaster.tUser  := (others => '0');

      -- Latch Freeze buffers flag if applied
      if (freeze_i = '1') then
         v.freeze := '1';
      else
         v.freeze := r.freeze;
      end if;

      -- Check if not in the IDLE state
      if (r.state /= IDLE_S) then
         -- Error if tReady or dataReady drops 
         if (rxAxisSlave_i.tReady = '0') or (LinkReady_i = '0') then
            v.error := '1';
         end if;
      end if;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Register values      
            v.packetSize         := packetSize_i;
            v.maxSize            := (packetSize_i-1);
            v.rateDiv            := rateDiv_i;
            v.averaging          := averaging_i;
            v.dec16or32          := dec16or32_i;
            v.headerEn           := headerEn_i;
            v.signWidth          := signWidth_i;
            v.signed             := signed_i;
            v.txAxisMaster.tDest := toSlv(axiNum_i, 8);
            -- Check if FIFO and JESD is ready
            if (rxAxisCtrl_i.pause = '0')
               and (enable_i = '1')
               and (rxAxisSlave_i.tReady = '1')
               and (LinkReady_i = '1')
               and (r.trigSh(2) = '1') then
               -- Clear error at the beginning of transmission
               v.error := '0';
               -- Set the debug flag
               v.busy  := '1';
               -- Check the mode
               if (mode_i = '0') then
                  v.pctCnt := toSlv(1, pctCnt_o'length);
                  v.state  := HEADER_S;  -- Next State when in triggered mode
               else
                  v.state := DATA_S;    -- Next State when in continuous mode
               end if;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Sample data on s_rateClk rate
            if (s_rateClk = '1') then
               -- Move data
               v.txAxisMaster.tvalid := '1';
               -- Set the SOF bit
               ssiSetUserSof(SSI_CONFIG_C, v.txAxisMaster, r.sof);
               v.sof                 := '0';
               -- Check the counter
               if (r.dataCnt /= r.maxSize) then
                  -- Increment the counter
                  v.dataCnt := r.dataCnt + 1;
               end if;
               -- Insert header words depending on which it is
               if (r.headerEn = '1') then
                  case (r.dataCnt) is
                     when toSlv(0, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := dmod_i(31 downto 0);
                     when toSlv(1, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := dmod_i(63 downto 32);
                     when toSlv(2, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := dmod_i(95 downto 64);
                     when toSlv(3, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := dmod_i(127 downto 96);
                     when toSlv(4, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := dmod_i(159 downto 128);
                     when toSlv(5, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := dmod_i(191 downto 160);
                     when toSlv(6, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := timeStamp_i(31 downto 0);
                     when toSlv(7, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := timeStamp_i(63 downto 32);
                     when toSlv(8, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := bsa_i(127 downto 96);
                     when toSlv(9, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := bsa_i(95 downto 64);
                     when toSlv(10, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := bsa_i(63 downto 32);
                     when toSlv(11, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := bsa_i(31 downto 0);
                     when toSlv(12, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := r.packetSize;
                     when toSlv(13, 32) =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := header_i & r.dec16or32 & r.averaging & test_i & '0' & toSlv(axiNum_i, 4) & r.rateDiv;
                     when others =>
                        v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := (others => '0');
                  end case;
               else
                  -- Send the JESD data
                  v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
               end if;
               -- Check if packet length error
               if (r.dataCnt = (HEADER_SIZE_C-1)) and (compCheck = '1') then
                  -- Set the EOF bit
                  v.txAxisMaster.tLast := '1';
                  -- Set the EOFE bit
                  ssiSetUserEofe(SSI_CONFIG_C, v.txAxisMaster, '1');
                  -- Next state
                  v.state              := IDLE_S;
               -- Check if header has been sent
               elsif (r.dataCnt = (HEADER_SIZE_C-1)) then
                  -- Next state
                  v.state := DATA_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when DATA_S =>
            -- Sample data on s_rateClk rate
            if (s_rateClk = '1') then
               -- Move data
               v.txAxisMaster.tvalid := '1';
               -- Set the SOF bit
               ssiSetUserSof(SSI_CONFIG_C, v.txAxisMaster, r.sof);
               v.sof                 := '0';
               -- Check the counter
               if (r.dataCnt /= r.maxSize) then
                  -- Increment the counter
                  v.dataCnt := r.dataCnt + 1;
               end if;
               -- Send the JESD data 
               v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
               -- Check for EOF condition
               if (r.dataCnt = r.maxSize and mode_i = '0')  -- Stop sending data if packet size reached  
                                          or (v.error = '1')  -- Immediately stop sending data if error occurs
                                          or (r.dataCnt(FRAME_BWIDTH_G-1 downto 0) = (2**FRAME_BWIDTH_G-1)) then  -- end of frame condition
                  -- Set the EOF bit
                  v.txAxisMaster.tLast := '1';
                  -- Set the EOFE bit
                  ssiSetUserEofe(SSI_CONFIG_C, v.txAxisMaster, v.error);
                  -- Set the freeze buffer tUser bit 
                  -- if the trigger occurred during the packet the EOF will contain freeze buffer bit 
                  axiStreamSetUserBit(SSI_CONFIG_C, v.txAxisMaster, FREZE_BUFFER_TUSER_G, r.freeze);
               end if;
               -- Check if need to stop sending data if in continuous mode or error detected
               if (r.dataCnt = r.maxSize and mode_i = '0')  -- Stop sending data if packet size reached  
                              or (v.error = '1') then  -- Immediately stop sending data if error occurs                                      
                  -- Clear the flag
                  v.freeze := '0';
                  -- Next state
                  v.state  := IDLE_S;
               -- Check if finished a frame
               elsif (r.dataCnt(FRAME_BWIDTH_G-1 downto 0) = (2**FRAME_BWIDTH_G-1)) then  -- end of frame condition
                  -- Check if still enabled
                  if (enable_i = '1') then
                     -- Go to next frame                 
                     v.sof := '1';
                  else
                     -- Next state
                     v.state := IDLE_S;  -- End packet if disabled                             
                  end if;
                  -- Clear freeze flag (but apply it if the freeze_i occurs at this very moment)
                  if (freeze_i = '1') then
                     v.freeze := '1';
                  else
                     v.freeze := '0';
                  end if;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check if next cycle is IDLE state
      if (v.state = IDLE_S) then
         -- Set the flags
         v.busy    := '0';
         v.sof     := '1';
         -- Reset the counter
         v.dataCnt := (others => '0');
      end if;

      -- Reset
      if (devRst_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Output assignment
      packetSizeVar  <= v.packetSize;
      rxAxisMaster_o <= r.txAxisMaster;
      error_o        <= r.error;
      pctCnt_o       <= r.pctCnt;
      busy_o         <= r.busy and not mode_i;

   end process comb;

   seq : process (devClk_i) is
   begin
      if rising_edge(devClk_i) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
