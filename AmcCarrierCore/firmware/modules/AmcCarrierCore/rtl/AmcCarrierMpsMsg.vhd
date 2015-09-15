-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsMsg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2015-09-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;
use work.TimingPkg.all;

entity AmcCarrierMpsMsg is
   generic (
      TPD_G            : time            := 1 ns;
      SIM_ERROR_HALT_G : boolean         := false;
      MPS_TYPE_G       : slv(4 downto 0) := MPS_NULL_TYPE_C;
      MPS_LEN_G        : positive        := MPS_NULL_LEN_C);
   port (
      -- User Interface
      clk         : in  sl;
      rst         : in  sl;
      testMode    : in  sl;
      mpsMsg      : in  Slv8Array(MPS_LEN_G-1 downto 0);
      appId       : in  slv(4 downto 0);
      -- Timing Interface
      timingData  : in  TimingDataType;
      -- BSI Interface      
      bsiData     : in  BsiDataType;
      -- MPS Interface
      mpsIbMaster : out AxiStreamMasterType;
      mpsIbSlave  : in  AxiStreamSlaveType);   
end AmcCarrierMpsMsg;

architecture rtl of AmcCarrierMpsMsg is

   type StateType is (
      IDLE_S,
      TIMESTAMP_S,
      HEADER_S,
      PAYLOAD_S); 

   type RegType is record
      cnt         : natural range 0 to MPS_LEN_G;
      timeStamp   : slv(15 downto 0);
      appId       : slv(4 downto 0);
      testMode    : sl;
      mpsMsg      : Slv8Array(MPS_LEN_G-1 downto 0);
      mpsIbMaster : AxiStreamMasterType;
      state       : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt         => 0,
      timeStamp   => (others => '0'),
      appId       => (others => '0'),
      testMode    => '0',
      mpsMsg      => (others => (others => '0')),
      mpsIbMaster => AXI_STREAM_MASTER_INIT_C,
      state       => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   comb : process (appId, mpsIbSlave, mpsMsg, r, rst, testMode, timingData) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      if mpsIbSlave.tReady = '1' then
         v.mpsIbMaster.tValid := '0';
         v.mpsIbMaster.tLast  := '0';
         v.mpsIbMaster.tUser  := (others => '0');
         v.mpsIbMaster.tData  := (others => '0');
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check for update
            if (timingData.strb = '1') and (MPS_TYPE_G /= MPS_NULL_TYPE_C) then
               -- Latch the timestamp and message
               v.timeStamp := timingData.msg.timeStamp(15 downto 0);
               v.appId     := appId;
               v.testMode  := testMode;
               v.mpsMsg    := mpsMsg;
               -- Next state
               v.state     := TIMESTAMP_S;
            end if;
         ----------------------------------------------------------------------
         when TIMESTAMP_S =>
            -- Check if ready to move data
            if v.mpsIbMaster.tValid = '0' then
               -- Send the timestamp 
               v.mpsIbMaster.tValid             := '1';
               v.mpsIbMaster.tData(15 downto 0) := r.timeStamp;
               ssiSetUserSof(MPS_CONFIG_C, v.mpsIbMaster, '1');
               -- Next state
               v.state                          := HEADER_S;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if v.mpsIbMaster.tValid = '0' then
               -- Send the header 
               v.mpsIbMaster.tValid              := '1';
               v.mpsIbMaster.tData(15 downto 11) := toSlv(MPS_LEN_G, 5);
               v.mpsIbMaster.tData(10 downto 6)  := MPS_TYPE_G;
               v.mpsIbMaster.tData(5 downto 1)   := r.appId;
               v.mpsIbMaster.tData(0)            := r.testMode;
               -- Next state
               v.state                           := PAYLOAD_S;
            end if;
         ----------------------------------------------------------------------
         when PAYLOAD_S =>
            -- Check if ready to move data
            if v.mpsIbMaster.tValid = '0' then
               -- Send the payload 
               v.mpsIbMaster.tValid            := '1';
               v.mpsIbMaster.tData(7 downto 0) := r.mpsMsg(r.cnt);
               -- Increment the counter
               v.cnt                           := r.cnt + 1;
               -- Check if lower byte is tLast
               if v.cnt = MPS_LEN_G then
                  -- Reset the counter
                  v.cnt               := 0;
                  -- Set EOF
                  v.mpsIbMaster.tLast := '1';
                  -- Next state
                  v.state             := IDLE_S;
               else
                  -- Send the payload 
                  v.mpsIbMaster.tData(15 downto 8) := r.mpsMsg(v.cnt);
                  -- Increment the counter
                  v.cnt                            := v.cnt + 1;
                  -- Check if lower byte is tLast
                  if v.cnt = MPS_LEN_G then
                     -- Reset the counter
                     v.cnt               := 0;
                     -- Set EOF
                     v.mpsIbMaster.tLast := '1';
                     -- Next state
                     v.state             := IDLE_S;
                  end if;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for error condition
      if (timingData.strb = '1') and (r.state /= IDLE_S) then
         if SIM_ERROR_HALT_G then
            -- Check the simulation error printing
            report "AmcCarrierMpsMsg: Simulation Overflow Detected ...";
            report "MPS_TYPE_G = " & integer'image(conv_integer(MPS_TYPE_G));
            report "Crate ID   = " & integer'image(conv_integer(bsiData.crateId));
            report "Slot ID    = " & integer'image(conv_integer(bsiData.slotNumber));
            report "APP ID     = " & integer'image(conv_integer(r.appId)) severity failure;
         end if;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs        
      mpsIbMaster <= r.mpsIbMaster;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
