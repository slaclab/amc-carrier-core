-------------------------------------------------------------------------------
-- File       : DaqLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-02
-- Last update: 2015-11-02
-------------------------------------------------------------------------------
-- Description:   This module sends sample data to a single Lane.
--                In non-continuous mode
--                - When data is requested by trig_i = '1' (Has to be 1 c-c).
--                - the module sends data a packet at the time to AXI stream FIFO.
--                Note: Tx pause must indicate that the AXI stream FIFO can hold the whole data packet.
--                Note: The data transmission is enabled only if JESD data is valid dataReady_i='1'.
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
      DECIMATOR_EN_G       : boolean         := true; -- Include or exclude decimator
      FRAME_BWIDTH_G       : positive        := 10;   -- Dafault 10: 4096 byte frames
      FREZE_BUFFER_TUSER_G : integer         := 2   
   );  
   port (
      enable_i : in sl;
      test_i   : in sl;
      
      -- JESD devClk
      devClk_i : in sl;
      devRst_i : in sl;

      -- Lane number AXI number to be inserted into AXI stream
      axiNum_i  : integer range 0 to 15;

      -- DAQ
      packetSize_i : in slv(31 downto 0); -- Min 4
      rateDiv_i    : in slv(15 downto 0); -- If averaging enabled then only powers of 2 should be used
      trig_i       : in sl:='0';          -- Must be 1 c-c pulse
      freeze_i     : in sl:='0';          -- Must be 1 c-c pulse
      averaging_i  : in sl:='0';          -- Enable decination averaging
      dec16or32_i  : in sl:='0';          -- Data format
      timeStamp_i  : in slv(63 downto 0); -- Connected from timing system
      bsa_i        : in slv(127 downto 0); -- Connected from timing system
      dmod_i       : in slv(191 downto 0); -- Connected from timing system
      headerEn_i   : in sl:='0';          
      header_i     : in slv(7 downto 0):=x"00";-- Additional/external header byte
      
      -- Sign extension
      signWidth_i  : in slv(4 downto 0);
      signed_i     : in sl;
      
      -- Mode of DAQ - '0'  - until packet size and needs trigger (used in new interface)
      --             - '1'  - sends the 4k frames continuously no trigger(used in new interface)
      mode_i       : in sl:='0';
     
      -- Axi Stream
      rxAxisCtrl_i      : in  AxiStreamCtrlType := AXI_STREAM_CTRL_UNUSED_C;
      rxAxisSlave_i     : in  AxiStreamSlaveType:= AXI_STREAM_SLAVE_FORCE_C;
      rxAxisMaster_o    : out AxiStreamMasterType;
      error_o           : out sl; -- Error if tReady drops
      busy_o            : out sl; -- Busy inhibits trigger in mode_i = '0'
      pctCnt_o          : out slv(25 downto 0); -- Number of 4096 byte frames 

      sampleData_i : in slv((GT_WORD_SIZE_C*8)-1 downto 0);
      dataReady_i  : in sl
      );
end DaqLane;

architecture rtl of DaqLane is

   constant SSI_CONFIG_C      : AxiStreamConfigType := ssiAxiStreamConfig(GT_WORD_SIZE_C, TKEEP_FIXED_C, TUSER_FIRST_LAST_C, 4, 3);
   constant TSTRB_C           : slv(15 downto 0)    := (15 downto GT_WORD_SIZE_C => '0') & (GT_WORD_SIZE_C-1 downto 0 => '1');
   constant KEEP_C            : slv(15 downto 0)    := (15 downto GT_WORD_SIZE_C => '0') & (GT_WORD_SIZE_C-1 downto 0 => '1');
   -- Header size constant (so the header size could be quickly adjusted)
   constant HEADER_SIZE_C     : positive := 14;
   
   type StateType is (
      IDLE_S,
      HEADER_S,
      SOF_S,
      DATA_S);  

   type RegType is record
      packetSize   : slv(31 downto 0);
      maxSize      : slv(31 downto 0);
      dataCnt      : slv(packetSize_i'range);
      txAxisMaster : AxiStreamMasterType;
      error        : sl;
      freeze       : sl;
      busy         : sl;      
      pctCnt       : slv(pctCnt_o'range);
      trig         : sl;
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
      pctCnt       => (others => '0'),
      trig         => '0',
      rateDiv      => (others => '0'),
      averaging    => '0',
      dec16or32    => '0',
      headerEn     => '0',
      signWidth    => (others => '0'),
      signed       => '0',
      state        => IDLE_S);

   signal r                : RegType := REG_INIT_C;
   signal rin              : RegType;
   signal s_rateClk        : sl;
   signal s_trigDecimator  : sl;
   signal s_sampleDataReg  : slv((GT_WORD_SIZE_C*8)-1 downto 0);  
   signal s_sampDataExt    : slv((GT_WORD_SIZE_C*8)-1 downto 0);
   signal s_sampDataTst    : slv((GT_WORD_SIZE_C*8)-1 downto 0);    
   signal s_decSampData    : slv((GT_WORD_SIZE_C*8)-1 downto 0);

begin
   -- Do not trigger decimator when busy
   -- because it will zero s_rateClk and data will be missed
   s_trigDecimator <= trig_i and not r.busy;
   
   -- Register the data at the beginning to ease timing
   U_Register: entity work.SlvDelay
      generic map (
         TPD_G          => TPD_G,
         WIDTH_G        => (GT_WORD_SIZE_C*8))
      port map (
         clk   => devClk_i,
         rst   => devRst_i,
         delay => "1",
         din   => sampleData_i,
         dout  => s_sampleDataReg);

   -- Sign extension
   signEx_comb : process (s_sampleDataReg, r.signed, r.dec16or32, r.signWidth) is       
   begin
      if (r.signed = '0') then
         s_sampDataExt <=  s_sampleDataReg;
      elsif (r.dec16or32 = '0') then
         s_sampDataExt <= extSign(s_sampleDataReg, conv_integer(r.signWidth));     
      else
         s_sampDataExt(15 downto 0)  <= extSign(s_sampleDataReg(15 downto 0), conv_integer(r.signWidth));         
         s_sampDataExt(31 downto 16) <= extSign(s_sampleDataReg(31 downto 16), conv_integer(r.signWidth)); 
      end if;

   end process signEx_comb;
   
   -- Applies test data if enabled  
   DaqTestSig_INST: entity work.DaqTestSig
      generic map (
         TPD_G => TPD_G)
      port map (
         clk          => devClk_i,
         rst          => devRst_i,
         sampleData_i => s_sampDataExt,
         sampleData_o => s_sampDataTst,
         test_i       => test_i,
         dec16or32_i  => r.dec16or32,
         trig_i       => s_trigDecimator);
   
   -- Rate divider module:
   -- Decimates data,
   -- Averages decimated data
   GEN_DEC : if (DECIMATOR_EN_G = true) generate
      Decimator_INST : entity work.DaqDecimator
         generic map (
            TPD_G => TPD_G
            )
         port map (
            clk           => devClk_i,
            rst           => devRst_i,
            sampleData_i  => s_sampDataTst,
            decSampData_o => s_decSampData,
            dec16or32_i   => r.dec16or32,
            rateDiv_i     => r.rateDiv,
            signed_i      => r.signed,
            trig_i        => s_trigDecimator,
            averaging_i   => r.averaging,
            rateClk_o     => s_rateClk);
   end generate GEN_DEC;

   GEN_N_DEC : if (DECIMATOR_EN_G = false) generate
   
      U_Register: entity work.SlvDelay
      generic map (
         TPD_G          => TPD_G,
         WIDTH_G        => (GT_WORD_SIZE_C*8))
      port map (
         clk   => devClk_i,
         rst   => devRst_i,
         delay => "1",
         din   => s_sampDataTst,
         dout  => s_decSampData);

      s_rateClk <= '1';
   end generate GEN_N_DEC;   
   
   comb : process (r, axiNum_i, dataReady_i, devRst_i, enable_i, packetSize_i, mode_i, freeze_i,dmod_i, dec16or32_i, averaging_i, test_i, rateDiv_i,signWidth_i, signed_i,
                   rxAxisCtrl_i, rxAxisSlave_i, s_decSampData, s_rateClk, trig_i, headerEn_i, timeStamp_i, header_i, bsa_i) is
      variable v             : RegType;
      variable axilStatus    : AxiLiteStatusType;
      variable axilWriteResp : slv(1 downto 0);
      variable axilReadResp  : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;
      
      
      -- Register trigger
      v.trig := trig_i;
      
      -- Reset strobing signals
      ssiResetFlags(v.txAxisMaster);
      v.txAxisMaster.tData := (others => '0');

      -- Latch the configuration
      v.txAxisMaster.tKeep := KEEP_C;
      v.txAxisMaster.tStrb := TSTRB_C;
      
      -- Latch Freeze buffers flag if applied
      if (freeze_i = '1') then
         v.freeze  := '1';
      else
         v.freeze := r.freeze;
      end if;
      

      -- State Machine
      StateMachine : case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>

            -- Put packet data count to zero 
            v.dataCnt := (others => '0');
            v.error   := r.error;
            v.busy    := '0';
            
            -- Register values      
            v.packetSize := packetSize_i;
            v.maxSize    := (packetSize_i-1);
            v.rateDiv    := rateDiv_i;
            v.averaging  := averaging_i;
            v.dec16or32  := dec16or32_i;
            v.headerEn   := headerEn_i;
            v.signWidth  := signWidth_i;
            v.signed     := signed_i;            

            -- No data sent 
            v.txAxisMaster.tvalid := '0';
            v.txAxisMaster.tData  := (others => '0');
            v.txAxisMaster.tLast  := '0';
            v.txAxisMaster.tDest  := toSlv(axiNum_i, 8);

            -- Check if fifo and JESD is ready
            if (rxAxisCtrl_i.pause = '0' and enable_i = '1' and rxAxisSlave_i.tReady = '1' and dataReady_i = '1' and trig_i = '1') then
               
               -- Clear error at the beginning of transmission
               v.error  := '0';
               -- 
               if (mode_i = '0') then
                  v.pctCnt := toSlv(1,pctCnt_o'length);
                  v.state  := HEADER_S; -- Next State when in triggered mode
               else   
                  v.state  := SOF_S;      -- Next State when in continuous mode
               end if;              
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
             
            v.busy   := '1';          
            
            -- Set the SOF bit if at first header word
            if (r.dataCnt = 0) then
               ssiSetUserSof(SSI_CONFIG_C, v.txAxisMaster, '1');
            end if;            
            
            -- Increment the counter
            -- and sample data on s_rateClk rate
            if s_rateClk = '1' then
               if (r.dataCnt /= r.maxSize) then
                  v.dataCnt             := r.dataCnt + 1;
               end if;
               v.txAxisMaster.tvalid := '1';
            else
               v.dataCnt             := r.dataCnt;
               v.txAxisMaster.tvalid := '0';
            end if;

            -- Error if tReady or dataReady drops 
            if (rxAxisSlave_i.tReady = '0' or dataReady_i = '0') then
               v.error := '1';
            else
               v.error := r.error;
            end if;

            -- Insert header words depending on which it is
            if (r.headerEn = '1') then
               Header : case (r.dataCnt) is
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
                     v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := header_i & r.dec16or32 & r.averaging & test_i & '0' & toSlv(axiNum_i, 4) & r.rateDiv ;            
                  when others =>
                     v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := (others=>'0');                  
               end case Header;    
            else
               v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
            end if;
            
            v.txAxisMaster.tLast := '0';
            v.txAxisMaster.tDest := toSlv(axiNum_i, 8);
             
            -- Insert tLast at the end of header and EOFE if packetSize less or equal to HEADER_SIZE_C 
            if ((r.dataCnt = (HEADER_SIZE_C-1)) and (r.packetSize <= HEADER_SIZE_C)) then
               -- Set the EOF(tlast) bit       
               v.txAxisMaster.tLast := '1';
               -- Set the EOFE bit in tUser if error occurred during packet transmission
               ssiSetUserEofe(SSI_CONFIG_C, v.txAxisMaster, r.error);
            end if; 
             
             
            -- Go further after next data
            if s_rateClk = '1' then
               if (r.dataCnt = (HEADER_SIZE_C-1) and r.packetSize <= HEADER_SIZE_C) then
                  v.state := IDLE_S;     -- End packet
               elsif (r.dataCnt = (HEADER_SIZE_C-1)) then              
                  v.state := DATA_S;
               else
                  v.state := HEADER_S;
               end if;
            end if;
         ----------------------------------------------------------------------         
         when SOF_S =>
         
            -- Busy only if in trigger mode        
            v.busy := '1'; 
            
            -- Increment the counter
            -- and sample data on s_rateClk rate
            if s_rateClk = '1' then
               if (r.dataCnt /= r.maxSize) then
                  v.dataCnt             := r.dataCnt + 1;
               end if;
               v.txAxisMaster.tvalid := '1';
            else
               v.dataCnt             := r.dataCnt;
               v.txAxisMaster.tvalid := '0';
            end if;

            -- Error if tReady or dataReady drops 
            if (rxAxisSlave_i.tReady = '0' or dataReady_i = '0') then
               v.error := '1';
            else
               v.error := r.error;
            end if;

            -- Send the JESD data
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
            v.txAxisMaster.tLast                                := '0';

            v.txAxisMaster.tDest := toSlv(axiNum_i, 8);

            -- Set the SOF bit
            ssiSetUserSof(SSI_CONFIG_C, v.txAxisMaster, '1');
            
            -- Set the tLast bit            
            if (r.dataCnt = r.maxSize and mode_i = '0') then
               v.txAxisMaster.tLast := '1';
               -- Set the EOFE bit in tUser if error occurred during packet transmission
               ssiSetUserEofe(SSI_CONFIG_C, v.txAxisMaster, r.error);
               -- Set the freeze buffer tUser bit 
               -- if the trigger occurred during the packet the EOF will contain freeze buffer bit 
               axiStreamSetUserBit(SSI_CONFIG_C, v.txAxisMaster, FREZE_BUFFER_TUSER_G, r.freeze);
            end if;

            -- Go further after next data
            if (s_rateClk = '1') then
               v.pctCnt := r.pctCnt+1;
               if (r.dataCnt = r.maxSize and mode_i = '0') then
                  -- Clear freeze flag (but apply it if the freeze_i occurs at this very moment)
                  if (freeze_i = '1') then
                     v.freeze := '1';
                  else
                     v.freeze := '0';
                  end if;
                  v.state := IDLE_S;
               else
                  v.state := DATA_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when DATA_S =>
         
            -- Busy only if in trigger mode        
            v.busy := '1'; 
            
            -- Increment the counter
            -- and sample data on s_rateClk rate
            if s_rateClk = '1' then
               if (r.dataCnt /= r.maxSize) then
                  v.dataCnt             := r.dataCnt + 1;
               end if;
               v.txAxisMaster.tvalid := '1';
            else
               v.dataCnt             := r.dataCnt;
               v.txAxisMaster.tvalid := '0';
            end if;

            -- Error if tReady or dataReady drops 
            if (rxAxisSlave_i.tReady = '0' or dataReady_i = '0') then
               v.error := '1';
            else
               v.error := r.error;
            end if;

            -- Send the JESD data 
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
            
            v.txAxisMaster.tDest := toSlv(axiNum_i, 8);            
            v.txAxisMaster.tLast := '0';
            
            -- Set the tLast bit            
            if ((r.dataCnt = r.maxSize and mode_i = '0') or
                (r.dataCnt(FRAME_BWIDTH_G-1 downto 0) = (2**FRAME_BWIDTH_G-1)) or
                (r.error = '1')
            ) then
               v.txAxisMaster.tLast := '1';
               -- Set the EOFE bit in tUser if error occurred during packet transmission
               ssiSetUserEofe(SSI_CONFIG_C, v.txAxisMaster, r.error);
               -- Set the freeze buffer tUser bit 
               -- if the trigger occurred during the packet the EOF will contain freeze buffer bit 
               axiStreamSetUserBit(SSI_CONFIG_C, v.txAxisMaster, FREZE_BUFFER_TUSER_G, r.freeze);
            end if;

            -- Next state conditioning
            if (s_rateClk = '1') then
               if ((r.error = '1') or                               -- Immediately stop sending data if error occurs
                   (r.dataCnt = r.maxSize and mode_i = '0') -- Stop sending data if packet size reached 
               ) then                                                -- Do not stop sending data if in continuous mode

                  v.freeze := '0';
                  v.state := IDLE_S;                   
               elsif (r.dataCnt(FRAME_BWIDTH_G-1 downto 0) = (2**FRAME_BWIDTH_G-1)) then -- Finish a frame if frame size reached
                  if enable_i = '1' then
                     v.state := SOF_S;                              -- Go to next frame                 
                  else
                     v.state := IDLE_S;                             -- End packet if disabled                             
                  end if;
                  
                  -- Clear freeze flag (but apply it if the freeze_i occurs at this very moment)
                  if (freeze_i = '1') then
                     v.freeze := '1';
                  else
                     v.freeze := '0';
                  end if;
                  ---------------------------
               end if;
            end if;
         ----------------------------------------------------------------------
         when others => null;

      ----------------------------------------------------------------------
      end case StateMachine;

      -- Reset
      if (devRst_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;
      
   end process comb;

   seq : process (devClk_i) is
   begin
      if rising_edge(devClk_i) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Output assignment
   rxAxisMaster_o <= r.txAxisMaster;
   error_o        <= r.error;
   pctCnt_o       <= r.pctCnt;
   busy_o         <= r.busy and not mode_i;

end rtl;
