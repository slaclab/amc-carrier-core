-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierFfbIbMsg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-21
-- Last update: 2015-09-30
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
use work.IpV4EnginePkg.all;

entity AmcCarrierFfbIbMsg is
   generic (
      TPD_G : time := 1 ns);      
   port (
      -- Clock and reset
      clk            : in  sl;
      rst            : in  sl;
      obServerMaster : in  AxiStreamMasterType;
      obServerSlave  : out AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- FFB Inbound Interface (ffbClk domain)
      ffbClk         : in  sl;
      ffbRst         : in  sl;
      ffbBus        : out FfbBusType);
end AmcCarrierFfbIbMsg;

architecture rtl of AmcCarrierFfbIbMsg is

   constant BUS_WIDTH_C : natural := 1112;

   function toSlv (ffbBus : FfbBusType) return slv is
      variable retVar : slv(BUS_WIDTH_C-1 downto 0);
      variable i      : natural;
   begin
      -- Reset the variable
      retVar := (others => '0');

      -- Load the message array
      for i in 31 downto 0 loop
         retVar((i*32)+31 downto (i*32)) := ffbBus.message(i);
      end loop;

      -- Load the time stamp
      retVar(1087 downto 1024) := ffbBus.timeStamp;

      -- Load the application ID
      retVar(1103 downto 1088) := ffbBus.appId;

      -- Load the test mode flag
      retVar(1104) := ffbBus.testMode;

      -- Load the application type
      retVar((AppType'length)+1104 downto 1105) := ffbBus.app;

      return retVar;
   end function;

   function fromSlv (valid : sl; dout : slv(BUS_WIDTH_C-1 downto 0)) return FfbBusType is
      variable retVar : FfbBusType;
      variable i      : natural;
   begin
      -- Reset the variable
      retVar := FFB_BUS_INIT_C;

      -- Load the valid
      retVar.valid := valid;

      -- Load the message array
      for i in 31 downto 0 loop
         retVar.message(i) := dout((i*32)+31 downto (i*32));
      end loop;

      -- Load the time stamp
      retVar.timeStamp := dout(1087 downto 1024);

      -- Load the application ID
      retVar.appId := dout(1103 downto 1088);

      -- Load the test mode flag
      retVar.testMode := dout(1104);

      -- Load the application type
      retVar.app := dout((AppType'length)+1104 downto 1105);

      return retVar;
   end function;
   
   type StateType is (
      IDLE_S,
      HEADER_S,
      PAYLOAD_S); 

   type RegType is record
      cnt           : natural range 0 to 63;
      cntSize       : slv(7 downto 0);
      obServerSlave : AxiStreamSlaveType;
      ffbBus       : FfbBusType;
      state         : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt           => 0,
      cntSize       => (others => '0'),
      obServerSlave => AXI_STREAM_SLAVE_INIT_C,
      ffbBus       => FFB_BUS_INIT_C,
      state         => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal valid : sl;
   signal din   : slv(BUS_WIDTH_C-1 downto 0);
   signal dout  : slv(BUS_WIDTH_C-1 downto 0);

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   comb : process (dout, obServerMaster, r, rst, valid) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.obServerSlave := AXI_STREAM_SLAVE_INIT_C;
      v.ffbBus.valid := '0';

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check for update
            if (obServerMaster.tValid = '1') then
               if (ssiGetUserSof(IP_ENGINE_CONFIG_C, obServerMaster) = '1') then
                  -- Next state
                  v.state := HEADER_S;
               else
                  -- Blowoff the data
                  v.obServerSlave.tReady := '1';
               end if;
            end if;
         ----------------------------------------------------------------------
         when HEADER_S =>
            -- Check if ready to move data
            if (obServerMaster.tValid = '1') then
               -- Accept the data
               v.obServerSlave.tReady         := '1';
               -- Latch the header and first 32-bit message word
               v.ffbBus.message(0)           := obServerMaster.tData(127 downto 96);
               v.ffbBus.timeStamp            := obServerMaster.tData(95 downto 32);
               v.ffbBus.appId                := obServerMaster.tData(31 downto 16);
               v.ffbBus.testMode             := obServerMaster.tData(15);
               v.ffbBus.app                  := obServerMaster.tData((AppType'length)+7 downto 8);
               v.cntSize                      := obServerMaster.tData(7 downto 0);
               --- Reset the other message data fields
               v.ffbBus.message(31 downto 1) := (others => (others => '0'));
               -- Check for EOF
               if obServerMaster.tLast = '1' then
                  -- Check for correct length
                  if v.cntSize = 1 then
                     -- Forward the message
                     v.ffbBus.valid := '1';
                  end if;
                  -- Next state
                  v.state := IDLE_S;
               -- Check for invalid cntSize
               elsif (v.cntSize > 32) or (v.cntSize = 0) then
                  -- Next state
                  v.state := IDLE_S;
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
            if (obServerMaster.tValid = '1') then
               -- Accept the data
               v.obServerSlave.tReady := '1';
               for i in 0 to 3 loop
                  -- Check the counter
                  if v.cnt /= r.cntSize then
                     -- Check the tKeep
                     if obServerMaster.tKeep((i*4)+3 downto (i*4)) = x"F" then
                        -- Latch the message
                        v.ffbBus.message(v.cnt) := obServerMaster.tData((i*32)+31 downto (i*32));
                     end if;
                     -- Increment the counter
                     v.cnt := v.cnt + 1;
                  end if;
               end loop;
               -- Check the counter
               if v.cnt = r.cntSize then
                  -- Check for EOF
                  if obServerMaster.tLast = '1' then
                     -- Forward the message
                     v.ffbBus.valid := '1';
                  end if;
                  -- Next state
                  v.state := IDLE_S;
               -- Check for SOF
               elsif (ssiGetUserSof(IP_ENGINE_CONFIG_C, obServerMaster) = '1') then
                  -- Next state
                  v.state := IDLE_S;
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs        
      obServerSlave <= v.obServerSlave;
      din           <= toSlv(r.ffbBus);
      ffbBus       <= fromSlv(valid, dout);

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => BUS_WIDTH_C)
      port map (
         -- Asynchronous Reset
         rst    => rst,
         -- Write Ports (wr_clk domain)
         wr_clk => clk,
         wr_en  => r.ffbBus.valid,
         din    => din,
         -- Read Ports (rd_clk domain)
         rd_clk => ffbClk,
         valid  => valid,
         dout   => dout);  

end rtl;
