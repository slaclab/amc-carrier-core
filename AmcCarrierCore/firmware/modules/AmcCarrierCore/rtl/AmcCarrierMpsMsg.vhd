-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsMsg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2015-10-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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
use work.AmcCarrierPkg.all;

entity AmcCarrierMpsMsg is
   generic (
      TPD_G            : time             := 1 ns;
      SIM_ERROR_HALT_G : boolean          := false;
      APP_TYPE_G       : AppType          := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));      
   port (
      -- AXI-Lite Interface: [AXI_BASE_ADDR_G+0x00000000:AXI_BASE_ADDR_G+0x00007FFF]
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Inbound Message Value
      enable          : in  sl;
      message         : in  Slv32Array(31 downto 0);
      timeStrb        : in  sl;
      timeStamp       : in  slv(15 downto 0);
      testMode        : in  sl;
      appId           : in  slv(15 downto 0);
      -- MPS Interface
      mpsMaster       : out AxiStreamMasterType;
      mpsSlave        : in  AxiStreamSlaveType);   
end AmcCarrierMpsMsg;

architecture rtl of AmcCarrierMpsMsg is

   constant MPS_CHANNELS_C    : natural range 0 to 32  := getMpsChCnt(APP_TYPE_G);
   constant MPS_THRESHOLD_C   : natural range 0 to 256 := getMpsThresholdCnt(APP_TYPE_G);
   constant NUM_AXI_MASTERS_C : natural                := ite((MPS_CHANNELS_C = 0), 1, MPS_CHANNELS_C);

   function genConfig (baseAddr : slv(31 downto 0)) return AxiLiteCrossbarMasterConfigArray is
      variable retVar : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0);
      variable i      : natural;
   begin
      for i in NUM_AXI_MASTERS_C-1 downto 0 loop
         retVar(i).baseAddr     := baseAddr + toSlv((i*1024), 32);
         retVar(i).addrBits     := 10;
         retVar(i).connectivity := X"0001";
      end loop;
      return retVar;
   end function;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genConfig(AXI_BASE_ADDR_G);

   signal ramWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   
   type StateType is (
      IDLE_S,
      HEADER_S,
      APP_ID_S,
      TIMESTAMP_S,
      PAYLOAD_S); 

   type RegType is record
      cnt       : natural range 0 to 63;
      timeStamp : slv(15 downto 0);
      message   : Slv8Array(31 downto 0);
      mpsMaster : AxiStreamMasterType;
      state     : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt       => 0,
      timeStamp => (others => '0'),
      message   => (others => (others => '0')),
      mpsMaster => AXI_STREAM_MASTER_INIT_C,
      state     => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ibValid : sl;
   signal obValid : slv(31 downto 0);
   signal obValue : Slv8Array(31 downto 0);

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   ibValid <= timeStrb and enable;

   DONT_SYNTH : if (MPS_CHANNELS_C = 0) generate

      obValid <= (others => '0');
      obValue <= (others => (others => '0'));

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave);

   end generate;

   MPS_SYNTH : if (MPS_CHANNELS_C /= 0) generate

      U_XBAR : entity work.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
            MASTERS_CONFIG_G   => AXI_CONFIG_C)
         port map (
            axiClk              => axilClk,
            axiClkRst           => axilRst,
            sAxiWriteMasters(0) => axilWriteMaster,
            sAxiWriteSlaves(0)  => axilWriteSlave,
            sAxiReadMasters(0)  => axilReadMaster,
            sAxiReadSlaves(0)   => axilReadSlave,
            mAxiWriteMasters    => ramWriteMasters,
            mAxiWriteSlaves     => ramWriteSlaves,
            mAxiReadMasters     => ramReadMasters,
            mAxiReadSlaves      => ramReadSlaves);  

      GEN_VEC :
      for i in NUM_AXI_MASTERS_C-1 downto 0 generate
         
         U_Encoder : entity work.AmcCarrierMpsEncoder
            generic map (
               TPD_G            => TPD_G,
               MPS_THRESHOLD_G  => MPS_THRESHOLD_C,
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
               AXI_BASE_ADDR_G  => AXI_CONFIG_C(i).baseAddr)
            port map (
               -- AXI-Lite Interface
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => ramReadMasters(i),
               axilReadSlave   => ramReadSlaves(i),
               axilWriteMaster => ramWriteMasters(i),
               axilWriteSlave  => ramWriteSlaves(i),
               -- Inbound Message Value
               ibValid         => ibValid,
               ibValue         => message(i),
               -- Outbound Encode MPS Value
               obValid         => obValid(i),
               obValue         => obValue(i));

      end generate GEN_VEC;
      
   end generate;

   comb : process (appId, axilRst, mpsSlave, obValid, obValue, r, testMode, timeStamp) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      if mpsSlave.tReady = '1' then
         v.mpsMaster.tValid := '0';
         v.mpsMaster.tLast  := '0';
         v.mpsMaster.tUser  := (others => '0');
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check for update
            if (obValid(0) = '1') and (APP_TYPE_G /= APP_NULL_TYPE_C) and (MPS_CHANNELS_C /= 0) then
               -- Reset tData
               v.mpsMaster.tData := (others => '0');
               -- Latch the information
               v.timeStamp       := timeStamp;
               v.message         := obValue;
               -- Next state
               v.state           := HEADER_S;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the header 
               v.mpsMaster.tValid                             := '1';
               v.mpsMaster.tData(15 downto 8)                 := toSlv(MPS_CHANNELS_C+5, 8);
               v.mpsMaster.tData(7)                           := testMode;
               v.mpsMaster.tData((AppType'length)-1 downto 0) := APP_TYPE_G;
               -- Set SOF               
               ssiSetUserSof(MPS_CONFIG_C, v.mpsMaster, '1');
               -- Next state
               v.state                                        := APP_ID_S;
            end if;
         ----------------------------------------------------------------------
         when APP_ID_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the application ID 
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(15 downto 0) := appId;
               -- Next state
               v.state                        := TIMESTAMP_S;
            end if;
         ----------------------------------------------------------------------
         when TIMESTAMP_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the timestamp 
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(15 downto 0) := r.timeStamp;
               -- Next state
               v.state                        := PAYLOAD_S;
            end if;
         ----------------------------------------------------------------------
         when PAYLOAD_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the payload 
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(7 downto 0)  := r.message(r.cnt);
               v.mpsMaster.tData(15 downto 8) := (others => '0');
               -- Increment the counter
               v.cnt                          := r.cnt + 1;
               -- Check if lower byte is tLast
               if v.cnt = MPS_CHANNELS_C then
                  -- Reset the counter
                  v.cnt             := 0;
                  -- Set EOF
                  v.mpsMaster.tLast := '1';
                  -- Next state
                  v.state           := IDLE_S;
               else
                  -- Send the payload 
                  v.mpsMaster.tData(15 downto 8) := r.message(v.cnt);
                  -- Increment the counter
                  v.cnt                          := v.cnt + 1;
                  -- Check if lower byte is tLast
                  if v.cnt = MPS_CHANNELS_C then
                     -- Reset the counter
                     v.cnt             := 0;
                     -- Set EOF
                     v.mpsMaster.tLast := '1';
                     -- Next state
                     v.state           := IDLE_S;
                  end if;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for error condition
      if (obValid(0) = '1') and (r.state /= IDLE_S) then
         -- Check the simulation error printing
         if SIM_ERROR_HALT_G then
            report "AmcCarrierMpsMsg: Simulation Overflow Detected ...";
            report "APP_TYPE_G = " & integer'image(conv_integer(APP_TYPE_G));
            report "APP ID     = " & integer'image(conv_integer(appId)) severity failure;
         end if;
      end if;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs        
      mpsMaster <= r.mpsMaster;

   end process comb;

   seq : process (axilClk) is
   begin
      if rising_edge(axilClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
