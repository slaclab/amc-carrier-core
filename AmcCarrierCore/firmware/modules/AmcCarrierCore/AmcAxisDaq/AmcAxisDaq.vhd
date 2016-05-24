-------------------------------------------------------------------------------
-- Title      : Single lane data acquisition control
-------------------------------------------------------------------------------
-- File       : AmcAxisDaq.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-04-02
-- Last update: 2015-11-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:   This module sends sample data to a single virtual Channel Lane.
--                In non-continuous mode
--                - When data is requested by trig_i = '1' (rising edge is detected on trig_i).
--                - the module sends data a packet at the time to AXI stream FIFO.
--                - Between packets the FSM waits until txCtrl_i.pause = '0'
--                  after that it is ready to receive the next trigger.
--                Note: Tx pause must indicate that the AXI stream FIFO can hold the whole data packet.
--                Note: The data transmission is enabled only if JESD data is valid dataReady_i='1'.
--                
--                In continuous mode:
--                - continuously sends 4k frames
--                - the packetSize_i, does not have any function
--                - the trig_i, does not have any function 
--                - The inputs should have the following values and can be left disconnected: overflow_i ='0', idle_i ='1', pause_i ='0', ready_i ='1'.
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

use work.Jesd204bPkg.all;

entity AmcAxisDaq is
   generic (
      -- General Configurations
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_SLVERR_C;
      FRAME_BWIDTH_G   : positive        := 10);
   port (
      enable_i : in sl;

      -- JESD devClk
      devClk_i : in sl;
      devRst_i : in sl;

      -- Lane number AXI number to be inserted into AXI stream
      laneNum_i : integer;
      axiNum_i  : integer range 0 to 15;

      -- DAQ
      packetSize_i : in slv(31 downto 0);
      rateDiv_i    : in slv(15 downto 0);
      trig_i       : in sl:='0';
      dec16or32_i  : in sl:='0';

      -- Mode of DAQ - '0'  - until packet size and needs trigger (used in new interface)
      --             - '1'  - sends the 4k frames continuously no trigger(used in new interface)
      mode_i       : in sl:='0';
      
      
      -- Axi Stream
      rxAxisMaster_o : out AxiStreamMasterType;
      error_o        : out sl;
      pctCnt_o       : out slv(25 downto 0);

      overflow_i : in sl:='0';
      idle_i     : in sl:='1';
      pause_i    : in sl:='0';
      ready_i    : in sl:='1';

      sampleData_i : in slv((GT_WORD_SIZE_C*8)-1 downto 0);
      dataReady_i  : in sl
      );
end AmcAxisDaq;

architecture rtl of AmcAxisDaq is

   constant JESD_SSI_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(GT_WORD_SIZE_C, TKEEP_COMP_C);
   constant TSTRB_C           : slv(15 downto 0)    := (15 downto GT_WORD_SIZE_C => '0') & (GT_WORD_SIZE_C-1 downto 0 => '1');
   constant KEEP_C            : slv(15 downto 0)    := (15 downto GT_WORD_SIZE_C => '0') & (GT_WORD_SIZE_C-1 downto 0 => '1');

   type StateType is (
      IDLE_S,
      FIRST_SOF_S,
      SOF_S,
      DATA_S,
      EOF_S,
      LAST_EOF_S
      );  

   type RegType is record
      dataCnt      : slv(packetSize_i'range);
      txAxisMaster : AxiStreamMasterType;
      error        : sl;
      pctCnt       : slv(pctCnt_o'range);
      state        : StateType;
   end record;
   
   constant REG_INIT_C : RegType := (
      dataCnt      => (others => '0'),
      txAxisMaster => AXI_STREAM_MASTER_INIT_C,
      error        => '0',
      pctCnt       => (others => '0'),
      state        => IDLE_S
      );

   signal r             : RegType := REG_INIT_C;
   signal rin           : RegType;
   signal s_num         : slv((GT_WORD_SIZE_C*8)-1 downto 0);
   signal s_footer      : slv((GT_WORD_SIZE_C*8)-1 downto 0);
   signal s_rateClk     : sl;
   signal s_trigRe      : sl;
   signal s_decSampData : slv((GT_WORD_SIZE_C*8)-1 downto 0);
   
   
begin

   -- Rate divider module
   Decimator_INST : entity work.AmcAxisDaqMuxDecimator
      generic map (
         TPD_G => TPD_G,
         F_G   => 2
         )
      port map (
         clk           => devClk_i,
         rst           => devRst_i,
         sampleData_i  => sampleData_i,
         decSampData_o => s_decSampData,
         dec16or32_i   => dec16or32_i,
         rateDiv_i     => rateDiv_i,
         trig_i        => trig_i,
         trigRe_o      => s_trigRe,
         rateClk_o     => s_rateClk);


   comb : process (axiNum_i, dataReady_i, devRst_i, enable_i, idle_i, overflow_i, packetSize_i,
                   pause_i, r, ready_i, s_decSampData, s_rateClk, s_trigRe) is
      variable v             : RegType;
      variable axilStatus    : AxiLiteStatusType;
      variable axilWriteResp : slv(1 downto 0);
      variable axilReadResp  : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Reset strobing signals
      ssiResetFlags(v.txAxisMaster);
      v.txAxisMaster.tData := (others => '0');

      -- Latch the configuration
      v.txAxisMaster.tKeep := KEEP_C;
      v.txAxisMaster.tStrb := TSTRB_C;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>

            -- Put packet data count to zero 
            v.dataCnt := (others => '0');
            v.error   := r.error;
            v.pctCnt  := r.pctCnt;


            -- No data sent 
            v.txAxisMaster.tvalid := '0';
            v.txAxisMaster.tData  := (others => '0');
            v.txAxisMaster.tLast  := '0';
            v.txAxisMaster.tDest  := intToSlv(axiNum_i, 8);

            -- Check if fifo and JESD is ready
            if (pause_i = '0' and enable_i = '1' and ready_i = '1' and dataReady_i = '1' and  (s_trigRe = '1' or mode_i = '1') ) then
               -- Next State
               v.state := FIRST_SOF_S;
            end if;
         ----------------------------------------------------------------------
         when FIRST_SOF_S =>

            -- Increment the counter
            -- and sample data on s_rateClk rate
            v.dataCnt             := r.dataCnt + 1;
            v.txAxisMaster.tvalid := '1';

            -- Clear error at the begining of transmission
            v.error := '0';

            v.pctCnt := (others => '0');

            -- Insert the axi and lane number at the first packet data word (byte swapped so it is transferred correctly)
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;

            v.txAxisMaster.tLast := '0';
            v.txAxisMaster.tDest := intToSlv(axiNum_i, 8);

            -- Set the SOF bit
            ssiSetUserSof(JESD_SSI_CONFIG_C, v.txAxisMaster, '1');

            v.state := DATA_S;
            
         when SOF_S =>

            -- Increment the counter
            -- and sample data on s_rateClk rate
            if s_rateClk = '1' then
               v.dataCnt             := r.dataCnt + 1;
               v.txAxisMaster.tvalid := '1';
            else
               v.dataCnt             := r.dataCnt;
               v.txAxisMaster.tvalid := '0';
            end if;

            -- Error if overflow or pause
            if pause_i = '1' or overflow_i = '1' or ready_i = '0' or dataReady_i = '0' then
               v.error := '1';
            else
               v.error := r.error;
            end if;

            v.pctCnt := r.pctCnt;

            -- Send the JESD data
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
            v.txAxisMaster.tLast                                := '0';

            v.txAxisMaster.tDest := intToSlv(axiNum_i, 8);

            -- Set the SOF bit
            ssiSetUserSof(JESD_SSI_CONFIG_C, v.txAxisMaster, '1');

            -- Go further after next data
            if s_rateClk = '1' then
               v.state := DATA_S;
            end if;
         ----------------------------------------------------------------------
         when DATA_S =>

            -- Increment the counter
            -- and sample data on s_rateClk rate
            if s_rateClk = '1' then
               v.dataCnt             := r.dataCnt + 1;
               v.txAxisMaster.tvalid := '1';
            else
               v.dataCnt             := r.dataCnt;
               v.txAxisMaster.tvalid := '0';
            end if;

            -- Error if overflow or pause
            if ready_i = '0' or dataReady_i = '0' then
               v.error := '1';
            else
               v.error := r.error;
            end if;

            v.txAxisMaster.tDest := intToSlv(axiNum_i, 8);

            v.pctCnt := r.pctCnt;

            -- Send the JESD data 
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;
            v.txAxisMaster.tLast                                := '0';

            -- Wait until the whole packet is sent, error or frame
            if (r.dataCnt >= (packetSize_i-2) and mode_i = '0') then  -- Stop sending data if packet size reached 
               v.state := LAST_EOF_S;                                         -- Do not stop sending data if in continuous mode
            elsif (r.error = '1') then               -- Stop sending data if error occurs
               v.state := LAST_EOF_S;
            elsif (r.dataCnt(FRAME_BWIDTH_G-1 downto 0) = (2**FRAME_BWIDTH_G-2)) then
               if enable_i = '1' then
                  v.state := EOF_S;
               else
                  v.state := LAST_EOF_S;             -- Stop sending data if disabled
               end if;
            end if;
         ----------------------------------------------------------------------
         when EOF_S =>

            -- Increment the counter
            -- and sample data on s_rateClk rate
            if s_rateClk = '1' then
               v.dataCnt             := r.dataCnt + 1;
               v.txAxisMaster.tvalid := '1';
            else
               v.dataCnt             := r.dataCnt;
               v.txAxisMaster.tvalid := '0';
            end if;

            -- Error if overflow or pause
            if ready_i = '0' then
               v.error := '1';
            else
               v.error := r.error;
            end if;

            v.pctCnt := r.pctCnt+1;

            -- Send the JESD data            
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;

            -- Set the EOF(tlast) bit       
            v.txAxisMaster.tLast := '1';

            v.txAxisMaster.tDest := intToSlv(axiNum_i, 8);

            -- Set the EOFE bit ERROR bit
            ssiSetUserEofe(JESD_SSI_CONFIG_C, v.txAxisMaster, r.error);

            -- Go back to SOF after next data
            if s_rateClk = '1' then
               v.state := SOF_S;
            end if;
         ----------------------------------------------------------------------
         when LAST_EOF_S =>

            -- Put packet data count to zero 
            v.dataCnt := (others => '0');
            v.error   := r.error;
            v.pctCnt  := r.pctCnt+1;

            -- Send zeros as footer
            v.txAxisMaster.tvalid                               := '1';
            v.txAxisMaster.tData((GT_WORD_SIZE_C*8)-1 downto 0) := s_decSampData;

            -- Set the EOF(tlast) bit       
            v.txAxisMaster.tLast := '1';

            v.txAxisMaster.tDest := intToSlv(axiNum_i, 8);

            -- Set the EOFE bit ERROR bit
            ssiSetUserEofe(JESD_SSI_CONFIG_C, v.txAxisMaster, r.error);

            --
            v.state := IDLE_S;
         ----------------------------------------------------------------------
         when others => null;

      ----------------------------------------------------------------------
      end case;

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

end rtl;
