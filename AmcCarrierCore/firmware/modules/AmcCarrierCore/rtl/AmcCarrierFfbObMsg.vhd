-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierFfbObMsg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2015-09-18
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
use work.IpV4EnginePkg.all;

entity AmcCarrierFfbObMsg is
   generic (
      TPD_G            : time    := 1 ns;
      SIM_ERROR_HALT_G : boolean := false;
      APP_TYPE_G       : AppType := APP_NULL_TYPE_C);      
   port (
      -- Clock and reset
      clk       : in  sl;
      rst       : in  sl;
      -- Inbound Message Value
      enable    : in  sl;
      message   : in  Slv32Array(31 downto 0);
      timeStrb  : in  sl;
      timeStamp : in  slv(63 downto 0);
      testMode  : in  sl;
      appId     : in  slv(15 downto 0);
      -- FFB Interface
      ffbMaster : out AxiStreamMasterType;
      ffbSlave  : in  AxiStreamSlaveType);   
end AmcCarrierFfbObMsg;

architecture rtl of AmcCarrierFfbObMsg is

   constant FFB_CHANNELS_C : natural range 0 to 32 := getFfbChCnt(APP_TYPE_G);
   
   type StateType is (
      IDLE_S,
      HEADER_S,
      PAYLOAD_S); 

   type RegType is record
      cnt       : natural range 0 to 63;
      message   : Slv32Array(31 downto 0);
      timeStamp : slv(63 downto 0);
      ffbMaster : AxiStreamMasterType;
      state     : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt       => 0,
      message   => (others => (others => '0')),
      timeStamp => (others => '0'),
      ffbMaster => AXI_STREAM_MASTER_INIT_C,
      state     => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ibValid : sl;

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   ibValid <= timeStrb and enable;

   comb : process (appId, ffbSlave, ibValid, message, r, rst, testMode, timeStamp) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      if ffbSlave.tReady = '1' then
         v.ffbMaster.tValid := '0';
         v.ffbMaster.tLast  := '0';
         v.ffbMaster.tUser  := (others => '0');
         v.ffbMaster.tKeep  := (others => '0');
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check for update
            if (ibValid = '1') and (APP_TYPE_G /= APP_NULL_TYPE_C) and (FFB_CHANNELS_C /= 0) then
               -- Reset tData
               v.ffbMaster.tData := (others => '0');
               -- Latch the information
               v.timeStamp       := timeStamp;
               v.message         := message;
               -- Next state
               v.state           := HEADER_S;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if v.ffbMaster.tValid = '0' then
               -- Send the header and first 32-bit message word
               v.ffbMaster.tValid                             := '1';
               v.ffbMaster.tKeep                              := x"FFFF";
               v.ffbMaster.tData(127 downto 96)               := r.message(0);
               v.ffbMaster.tData(95 downto 32)                := r.timeStamp;
               v.ffbMaster.tData(31 downto 16)                := appId;
               v.ffbMaster.tData(15)                          := testMode;
               v.ffbMaster.tData((AppType'length)+7 downto 8) := APP_TYPE_G;
               v.ffbMaster.tData(7 downto 0)                  := toSlv(FFB_CHANNELS_C+11, 8);
               -- Set SOF
               ssiSetUserSof(IP_ENGINE_CONFIG_C, v.ffbMaster, '1');
               -- Check for EOF
               if FFB_CHANNELS_C = 1 then
                  -- Set EOF
                  v.ffbMaster.tLast := '1';
                  -- Next state
                  v.state           := IDLE_S;
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
            if v.ffbMaster.tValid = '0' then
               -- Send the payload 
               v.ffbMaster.tValid := '1';
               for i in 0 to 3 loop
                  -- Check the counter
                  if v.cnt /= FFB_CHANNELS_C then
                     -- Set the tData and tKeep
                     v.ffbMaster.tData((i*32)+31 downto (i*32)) := r.message(v.cnt);
                     v.ffbMaster.tKeep((i*4)+3 downto (i*4))    := x"F";
                     -- Increment the counter
                     v.cnt                                      := v.cnt + 1;
                  end if;
               end loop;
               -- Check the counter
               if v.cnt = FFB_CHANNELS_C then
                  -- Set EOF
                  v.ffbMaster.tLast := '1';
                  -- Next state
                  v.state           := IDLE_S;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for error condition
      if (ibValid = '1') and (r.state /= IDLE_S) then
         -- Check the simulation error printing
         if SIM_ERROR_HALT_G then
            report "AmcCarrierFfbObMsg: Simulation Overflow Detected ...";
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
      ffbMaster <= r.ffbMaster;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
