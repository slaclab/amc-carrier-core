-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsMsgCore.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2016-02-29
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierMpsMsgCore is
   generic (
      TPD_G            : time    := 1 ns;
      SIM_ERROR_HALT_G : boolean := false;
      APP_TYPE_G       : AppType := APP_NULL_TYPE_C);      
   port (
      clk       : in  sl;
      rst       : in  sl;
      -- Inbound Message Value
      validStrb : in  sl;
      timeStamp : in  slv(15 downto 0);
      testMode  : in  sl;
      appId     : in  slv(15 downto 0);
      message   : in  Slv8Array(31 downto 0);
      msgSize   : in  slv(7 downto 0);  -- In units of Bytes
      -- Outbound MPS Interface
      mpsMaster : out AxiStreamMasterType;
      mpsSlave  : in  AxiStreamSlaveType);   
end AmcCarrierMpsMsgCore;

architecture rtl of AmcCarrierMpsMsgCore is

   constant MPS_CHANNELS_C : natural range 0 to 32 := getMpsChCnt(APP_TYPE_G);
   
   type StateType is (
      IDLE_S,
      HEADER_S,
      APP_ID_S,
      TIMESTAMP_S,
      PAYLOAD_S); 

   type RegType is record
      cnt       : natural range 0 to 63;
      msgSize   : slv(7 downto 0);
      timeStamp : slv(15 downto 0);
      message   : Slv8Array(31 downto 0);
      mpsMaster : AxiStreamMasterType;
      state     : StateType;
      stateDly  : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt       => 0,
      msgSize   => (others => '0'),
      timeStamp => (others => '0'),
      message   => (others => (others => '0')),
      mpsMaster => AXI_STREAM_MASTER_INIT_C,
      state     => IDLE_S,
      stateDly  => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   comb : process (appId, message, mpsSlave, msgSize, r, rst, testMode, timeStamp, validStrb) is
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
            if (validStrb = '1')
               and (APP_TYPE_G /= APP_NULL_TYPE_C)
               and (MPS_CHANNELS_C /= 0)
               and (msgSize /= 0)
               and (msgSize      <= MPS_CHANNELS_C) then
               -- Reset tData
               v.mpsMaster.tData := (others => '0');
               -- Latch the information
               v.timeStamp       := timeStamp;
               v.message         := message;
               v.msgSize         := msgSize;
               -- Next state
               v.state           := HEADER_S;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the header 
               v.mpsMaster.tValid                              := '1';
               v.mpsMaster.tData(15)                           := testMode;
               v.mpsMaster.tData((AppType'length)+ 7 downto 8) := APP_TYPE_G;
               v.mpsMaster.tData(7 downto 0)                   := r.msgSize+5;  -- Length in units of bytes
               -- Set SOF               
               ssiSetUserSof(MPS_CONFIG_C, v.mpsMaster, '1');
               -- Next state
               v.state                                         := APP_ID_S;
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
               if v.cnt = r.msgSize then
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
                  if v.cnt = r.msgSize then
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
      v.stateDly := r.state;
      if (validStrb = '1') and (r.stateDly /= IDLE_S) then
         -- Check the simulation error printing
         if SIM_ERROR_HALT_G then
            report "AmcCarrierMpsMsg: Simulation Overflow Detected ...";
            report "APP_TYPE_G = " & integer'image(conv_integer(APP_TYPE_G));
            report "APP ID     = " & integer'image(conv_integer(appId)) severity failure;
         end if;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs        
      mpsMaster <= r.mpsMaster;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
