-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBpMsgOb.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2016-02-23
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
use work.EthMacPkg.all;

entity AmcCarrierBpMsgOb is
   generic (
      TPD_G            : time    := 1 ns;
      SIM_ERROR_HALT_G : boolean := false;
      APP_TYPE_G       : AppType := APP_NULL_TYPE_C);      
   port (
      -- Clock and reset
      clk         : in  sl;
      rst         : in  sl;
      -- Inbound Message Value
      enable      : in  sl;
      message     : in  Slv32Array(31 downto 0);
      timeStrb    : in  sl;
      timeStamp   : in  slv(63 downto 0);
      testMode    : in  sl;
      appId       : in  slv(15 downto 0);
      -- Backplane Messaging Outbound Interface
      bpMsgMaster : out AxiStreamMasterType;
      bpMsgSlave  : in  AxiStreamSlaveType);   
end AmcCarrierBpMsgOb;

architecture rtl of AmcCarrierBpMsgOb is

   constant BP_MSG_CHANNELS_C : natural range 0 to 32 := getBpMsgChCnt(APP_TYPE_G);
   
   type StateType is (
      IDLE_S,
      HEADER_S,
      PAYLOAD_S); 

   type RegType is record
      cnt         : natural range 0 to 63;
      message     : Slv32Array(31 downto 0);
      timeStamp   : slv(63 downto 0);
      bpMsgMaster : AxiStreamMasterType;
      state       : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt         => 0,
      message     => (others => (others => '0')),
      timeStamp   => (others => '0'),
      bpMsgMaster => AXI_STREAM_MASTER_INIT_C,
      state       => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ibValid : sl;

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   ibValid <= timeStrb and enable;

   comb : process (appId, bpMsgSlave, ibValid, message, r, rst, testMode, timeStamp) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      if bpMsgSlave.tReady = '1' then
         v.bpMsgMaster.tValid := '0';
         v.bpMsgMaster.tLast  := '0';
         v.bpMsgMaster.tUser  := (others => '0');
         v.bpMsgMaster.tKeep  := (others => '0');
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check for update
            if (ibValid = '1') and (APP_TYPE_G /= APP_NULL_TYPE_C) and (BP_MSG_CHANNELS_C /= 0) then
               -- Reset tData
               v.bpMsgMaster.tData := (others => '0');
               -- Latch the information
               v.timeStamp         := timeStamp;
               v.message           := message;
               -- Next state
               v.state             := HEADER_S;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if v.bpMsgMaster.tValid = '0' then
               -- Send the header and first 32-bit message word
               v.bpMsgMaster.tValid                             := '1';
               v.bpMsgMaster.tKeep                              := x"FFFF";
               v.bpMsgMaster.tData(127 downto 96)               := r.message(0);
               v.bpMsgMaster.tData(95 downto 32)                := r.timeStamp;
               v.bpMsgMaster.tData(31 downto 16)                := appId;
               v.bpMsgMaster.tData(15)                          := testMode;
               v.bpMsgMaster.tData((AppType'length)+7 downto 8) := APP_TYPE_G;
               v.bpMsgMaster.tData(7 downto 0)                  := toSlv(BP_MSG_CHANNELS_C, 8);
               -- Set SOF
               ssiSetUserSof(EMAC_AXIS_CONFIG_C, v.bpMsgMaster, '1');
               -- Check for EOF
               if BP_MSG_CHANNELS_C = 1 then
                  -- Set EOF
                  v.bpMsgMaster.tLast := '1';
                  -- Next state
                  v.state             := IDLE_S;
               else
                  -- Preset the counter
                  v.cnt   := 1;
                  -- Next state
                  v.state := PAYLOAD_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when PAYLOAD_S =>
            -- Check if ready to move data
            if v.bpMsgMaster.tValid = '0' then
               -- Send the payload 
               v.bpMsgMaster.tValid := '1';
               for i in 0 to 3 loop
                  -- Check the counter
                  if v.cnt /= BP_MSG_CHANNELS_C then
                     -- Set the tData and tKeep
                     v.bpMsgMaster.tData((i*32)+31 downto (i*32)) := r.message(v.cnt);
                     v.bpMsgMaster.tKeep((i*4)+3 downto (i*4))    := x"F";
                     -- Increment the counter
                     v.cnt                                        := v.cnt + 1;
                  end if;
               end loop;
               -- Check the counter
               if v.cnt = BP_MSG_CHANNELS_C then
                  -- Set EOF
                  v.bpMsgMaster.tLast := '1';
                  -- Next state
                  v.state             := IDLE_S;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for error condition
      if (ibValid = '1') and (r.state /= IDLE_S) then
         -- Check the simulation error printing
         if SIM_ERROR_HALT_G then
            report "AmcCarrierBpMsgOb: Simulation Overflow Detected ...";
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
      bpMsgMaster <= r.bpMsgMaster;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
