-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Note: Do not forget to configure the ATCA crate to drive the clock from the slot#2 MPS link node
-- For the 7-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
-- For the 16-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
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
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library amc_carrier_core;
use amc_carrier_core.AmcCarrierPkg.all;
use amc_carrier_core.AppMpsPkg.all;

entity MpsMsgCore is
   generic (
      TPD_G            : time    := 1 ns;
      SIM_ERROR_HALT_G : boolean := false);
   port (
      clk : in sl;
      rst : in sl;

      ready      : out sl;
      mpsMsgDrop : out sl;
      -- Inbound Message Value
      mpsMessage : in  MpsMessageType;

      -- Outbound MPS Interface
      mpsMaster : out AxiStreamMasterType;
      mpsSlave  : in  AxiStreamSlaveType);
end MpsMsgCore;

architecture rtl of MpsMsgCore is

   type StateType is (
      IDLE_S,
      HEADER_S,
      APP_ID_S,
      TIMESTAMP_S,
      PAYLOAD_S);

   type RegType is record
      cnt        : natural range 0 to 63;
      mpsMessage : MpsMessageType;
      mpsMaster  : AxiStreamMasterType;
      ready      : sl;
      mpsMsgDrop : sl;
      state      : StateType;
      stateDly   : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt        => 0,
      mpsMessage => MPS_MESSAGE_INIT_C,
      mpsMaster  => AXI_STREAM_MASTER_INIT_C,
      ready      => '0',
      mpsMsgDrop => '0',
      state      => IDLE_S,
      stateDly   => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";

begin

   comb : process (mpsMessage, mpsSlave, r, rst) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.mpsMsgDrop := '0';
      if mpsSlave.tReady = '1' then
         v.mpsMaster.tValid := '0';
         v.mpsMaster.tLast  := '0';
         v.mpsMaster.tUser  := (others => '0');
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Set ready
            v.ready := '1';
            -- Check for update
            if mpsMessage.valid = '1' and mpsMessage.msgSize > 0 then
               -- Reset ready
               v.ready      := '0';
               -- Latch the information
               v.mpsMessage := mpsMessage;
               -- Next state
               v.state      := HEADER_S;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the header
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(15)          := '0';  -- Mitigation Message flag has to be '0' (Will be checked at receiving end)
               v.mpsMaster.tData(14)          := r.mpsMessage.lcls;  -- Set the LCLS flag
               v.mpsMaster.tData(13)          := r.mpsMessage.inputType;  -- Set the input type A/D
               v.mpsMaster.tData(12 downto 8) := r.mpsMessage.version;  -- Set the message version
               v.mpsMaster.tData(7 downto 0)  := r.mpsMessage.msgSize+5;  -- Length in units of bytes
               -- Set SOF
               ssiSetUserSof(MPS_AXIS_CONFIG_C, v.mpsMaster, '1');
               -- Next state
               v.state                        := APP_ID_S;
            end if;
         ----------------------------------------------------------------------
         when APP_ID_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the application ID
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(15 downto 0) := r.mpsMessage.appId;
               -- Next state
               v.state                        := TIMESTAMP_S;
            end if;
         ----------------------------------------------------------------------
         when TIMESTAMP_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the timestamp
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(15 downto 0) := r.mpsMessage.timeStamp;
               -- Next state
               v.state                        := PAYLOAD_S;
            end if;
         ----------------------------------------------------------------------
         when PAYLOAD_S =>
            -- Check if ready to move data
            if v.mpsMaster.tValid = '0' then
               -- Send the payload
               v.mpsMaster.tValid             := '1';
               v.mpsMaster.tData(7 downto 0)  := r.mpsMessage.message(r.cnt);
               v.mpsMaster.tData(15 downto 8) := (others => '0');
               -- Increment the counter
               v.cnt                          := r.cnt + 1;

               -- Check if lower byte is tLast
               if v.cnt = r.mpsMessage.msgSize then
                  -- Reset the counter
                  v.cnt             := 0;
                  -- Set EOF
                  v.mpsMaster.tLast := '1';
                  -- Next state
                  v.state           := IDLE_S;
               else
                  -- Send the payload
                  v.mpsMaster.tData(15 downto 8) := r.mpsMessage.message(v.cnt);
                  -- Increment the counter
                  v.cnt                          := v.cnt + 1;
                  -- Check if lower byte is tLast
                  if v.cnt = r.mpsMessage.msgSize then
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

      -- Check for error conditions (real-time monitoring)
      if (mpsMessage.valid = '1') and (mpsMessage.msgSize > 0) and (r.state /= IDLE_S) then
         -- Strobe the error flag
         v.mpsMsgDrop := '1';
      end if;

      -- Check for error conditions (simulation monitoring)
      if SIM_ERROR_HALT_G then
         v.stateDly := r.state;  -- 1 cycle delay to make it easer to see in simulation GUI
         if (mpsMessage.valid = '1') and (mpsMessage.msgSize > 0) and (r.stateDly /= IDLE_S) then
            -- Check the simulation error printing
            report "AmcCarrierMpsMsg: Simulation Overflow Detected ...";
            report "APP ID = " & integer'image(conv_integer(mpsMessage.appId)) severity failure;
         end if;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      mpsMaster  <= r.mpsMaster;
      ready      <= v.ready;
      mpsMsgDrop <= r.mpsMsgDrop;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
