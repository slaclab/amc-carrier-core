-------------------------------------------------------------------------------
-- File       : DaqTrigger.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: 
--          Trigger Status
--              bit0: Software Trigger Status (Registered on first trigger until cleared by TriggerControl(4))
--              bit1: Cascade Trigger Status (Registered on first trigger until cleared by TriggerControl(4))
--              bit2: Hardware Trigger Status (Registered on first trigger until cleared by TriggerControl(4))
--              bit3: Hardware Trigger Armed Status (Registered on rising edge TriggerControl(3) and cleared when Hw trigger occurs)
--              bit4: Combined Trigger Status (Registered when trigger condition is met until cleared by TriggerControl(4))
--              bit5: Freeze buffer occurred (Registered on first freeze until cleared by Control(4))      
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


library surf;
use surf.StdRtlPkg.all;


entity DaqTrigger is
   generic (
      TPD_G : time     := 1 ns
   );
   port (
      clk : in sl;
      rst : in sl;

      -- Raw trigger inputs
      trigSw_i    : in  sl;
      trigHw_i    : in  sl;
      trigCasc_i  : in  sl;
      armCasc_i   : in  sl;
      
      -- Raw freeze inputs
      freezeSw_i  : in  sl;
      freezeHw_i  : in  sl;      
      
      -- Register controls
      trigCascMask_i    : in sl;
      trigHwAutoRearm_i : in sl;
      trigHwArm_i       : in sl;
      clearTrigStatus_i : in sl;
      trigMode_i        : in sl;
      freezeHwMask_i    : in  sl;
      
      -- Busy in
      daqBusy_i         : in sl;
      
      -- Status
      trigStatus_o      : out  slv(5 downto 0);
      trigHeader_o      : out  slv(2 downto 0);

      -- Trigger output (1 cc)
      trig_o  : out  sl;
      freeze_o: out  sl
   );
end entity DaqTrigger;

architecture rtl of DaqTrigger is

   type RegType is record
      trig        : sl;
      freeze      : sl;
      busyDly     : sl;
      trigStatusReg : slv(trigStatus_o'range);      
      trigHeaderReg : slv(trigHeader_o'range);
   end record RegType;

   constant REG_INIT_C : RegType := (   
      trig        => '0',
      freeze      => '0', 
      busyDly     => '0', 
      trigStatusReg  => (others =>'0'),      
      trigHeaderReg  => (others =>'0')  
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   signal s_trigSwRe   : sl;
   signal s_trigCascRe : sl;
   signal s_trigHwRe   : sl;
   signal s_freezeSwRe : sl;
   signal s_freezeHwRe : sl;
   signal s_armRe      : sl;
   signal s_armCascRe  : sl;   
   signal s_clearRe    : sl;   
   
begin
   -- Sync one shots
   U_SyncOneShotSw: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigSw_i,
      dataOut => s_trigSwRe);

   U_SyncOneShotCasc: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigCasc_i,
      dataOut => s_trigCascRe);      

   U_SyncOneShotHw: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigHw_i,
      dataOut => s_trigHwRe);
      
   U_SyncOneShotFreezeSw: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => freezeSw_i,
      dataOut => s_freezeSwRe);

   U_SyncOneShotFreezeHw: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => freezeHw_i,
      dataOut => s_freezeHwRe);  

   -- One shots 
   U_SyncOneShotArm: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => true) -- No need to sync
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigHwArm_i,
      dataOut => s_armRe);
      
   -- One shots 
   U_SyncOneShotArmCasc: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => true) -- No need to sync
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => armCasc_i,
      dataOut => s_armCascRe); 
      
   U_SyncOneShotClear: entity surf.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => true) -- No need to sync
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => clearTrigStatus_i,
      dataOut => s_clearRe);
   
   
   comb : process (r, rst, s_trigSwRe, s_trigCascRe, s_trigHwRe, s_freezeHwRe, s_freezeSwRe, s_armRe, s_armCascRe, s_clearRe, trigCascMask_i, freezeHwMask_i, daqBusy_i, trigHwAutoRearm_i, trigMode_i ) is
      variable v           : RegType;
      variable vTrigHeader : slv(trigHeader_o'range); 
   begin
      v := r;
      
      v.busyDly := daqBusy_i;

      -- Trig status Register 0
      if (s_trigSwRe = '1') then
         v.trigStatusReg(0) := '1';
      elsif (s_clearRe = '1') then
         v.trigStatusReg(0) := '0';
      else
         v.trigStatusReg(0) := r.trigStatusReg(0);
      end if;

      -- Trig status Register 1
      if (s_trigCascRe = '1') then
         v.trigStatusReg(1) := '1';
      elsif (s_clearRe = '1') then
         v.trigStatusReg(1) := '0';
      else
         v.trigStatusReg(1) := r.trigStatusReg(1);
      end if;

      -- Trig status Register 2
      if (s_trigHwRe = '1') then
         v.trigStatusReg(2) := '1';
      elsif (s_clearRe = '1') then
         v.trigStatusReg(2) := '0';
      else
         v.trigStatusReg(2) := r.trigStatusReg(2);
      end if;
      
      -- Trig status Register 3
      if (s_armRe = '1' or s_armCascRe='1') then
         v.trigStatusReg(3) := '1';
      elsif (s_trigHwRe = '1') then
         v.trigStatusReg(3) := '0';
      else
         v.trigStatusReg(3) := r.trigStatusReg(3);
      end if;

      -- Trig status Register 4
      if (r.trig = '1') then
         v.trigStatusReg(4) := '1';
      elsif (s_clearRe = '1') then
         v.trigStatusReg(4) := '0';
      else
         v.trigStatusReg(4) := r.trigStatusReg(4);
      end if;

      -- Trig status Register 5
      if (r.freeze = '1') then
         v.trigStatusReg(5) := '1';
      elsif (s_clearRe = '1') then
         v.trigStatusReg(5) := '0';
      else
         v.trigStatusReg(5) := r.trigStatusReg(5);
      end if;
      
      -- Trig header status Register (register triggers until busy)
      vTrigHeader := s_trigHwRe & s_trigCascRe & s_trigSwRe;
      
      for i in trigHeader_o'range loop
         if (vTrigHeader(i) = '1') then
            v.trigHeaderReg(i) := '1';
         elsif (r.busyDly = '1' and daqBusy_i = '0') then -- Clear after on falling edge of busy
            v.trigHeaderReg(i) := '0';
         else
            v.trigHeaderReg(i) := r.trigHeaderReg(i);
         end if;
      end loop;
      
      -- Trigger output condition
      if (daqBusy_i = '1') then      
         v.trig := '0';      
      elsif (
         -- Software trigger
         (s_trigSwRe = '1' ) or
         -- Cascade trigger        
         (s_trigCascRe = '1' and trigCascMask_i = '1') or      
         -- Hardware trigger       
         (s_trigHwRe = '1' and (r.trigStatusReg(3) = '1' or trigHwAutoRearm_i = '1'))
      ) then
         v.trig := '1';
      else
         v.trig := '0';
      end if;
      
      -- Freeze output condition
      if (
         -- Software freeze
         (s_freezeSwRe = '1' ) or
         -- Hardware freeze        
         (s_freezeHwRe = '1' and freezeHwMask_i = '1')
      ) then
         v.freeze := '1';
      else
         v.freeze := '0';
      end if;
 
      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Output assignment
   trigStatus_o <= r.trigStatusReg;
   trigHeader_o <= r.trigHeaderReg;   
   trig_o       <= r.trig;
   freeze_o     <= r.freeze;
---------------------------------------   
end architecture rtl;
