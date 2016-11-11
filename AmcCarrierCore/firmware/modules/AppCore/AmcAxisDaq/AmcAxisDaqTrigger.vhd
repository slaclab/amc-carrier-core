-------------------------------------------------------------------------------
-- Title      : Handles DAQ triggers
-------------------------------------------------------------------------------
-- File       : AmcAxisDaqTrigger.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2016-05-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
--          Trigger Status
--              bit0: Software Trigger Status (Registered on first trigger until cleared by TriggerControl(4))
--              bit1: Cascade Trigger Status (Registered on first trigger until cleared by TriggerControl(4))
--              bit2: Hardware Trigger Status (Registered on first trigger until cleared by TriggerControl(4))
--              bit3: Hardware Trigger Armed Status (Registered on rising edge TriggerControl(3) and cleared when Hw trigger occurs)
--              bit4: Combined Trigger Status (Registered when trigger condition is met until cleared by TriggerControl(4))
--              
--              
--              
--              
--              
--              
--              
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


entity AmcAxisDaqTrigger is
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
      
      -- Register controls
      trigCascMask_i    : in sl;
      trigHwAutoRearm_i : in sl;
      trigHwArm_i       : in sl;
      clearTrigStatus_i : in sl;
      trigMode_i        : in sl;
      
      -- Busy in
      daqBusy_i         : in sl;
      
      -- Status
      trigStatus_o      : out  slv(4 downto 0);      

      -- Trigger output (1 cc)
      trig_o  : out  sl
   );
end entity AmcAxisDaqTrigger;

architecture rtl of AmcAxisDaqTrigger is

   type RegType is record
      trigSwReg   : sl;
      trigCascReg : sl;
      trigHwReg   : sl;
      armedReg    : sl;
      trigReg     : sl;
      trig        : sl;

      
   end record RegType;

   constant REG_INIT_C : RegType := (
      trigSwReg   => '0',
      trigCascReg => '0',
      trigHwReg   => '0',
      armedReg    => '0',
      trigReg     => '0',
      trig        => '0'
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   signal s_trigSwRe   : sl;
   signal s_trigCascRe : sl;
   signal s_trigHwRe   : sl;
   signal s_armRe      : sl;
   signal s_clearRe    : sl;   
   
begin
   -- Sync one shots
   U_SyncOneShotSw: entity work.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigSw_i,
      dataOut => s_trigSwRe);

   U_SyncOneShotCasc: entity work.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigCasc_i,
      dataOut => s_trigCascRe);      

   U_SyncOneShotHw: entity work.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigHw_i,
      dataOut => s_trigHwRe);      
 
   -- One shots 
   U_SyncOneShotArm: entity work.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => true) -- No need to sync
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => trigHwArm_i,
      dataOut => s_armRe);      

   U_SyncOneShotClear: entity work.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => true) -- No need to sync
   port map (
      clk     => clk,
      rst     => rst,
      dataIn  => clearTrigStatus_i,
      dataOut => s_clearRe);
   
   
   comb : process (r, rst, s_trigSwRe, s_trigCascRe, s_trigHwRe, s_armRe, s_clearRe, trigCascMask_i, daqBusy_i, trigHwAutoRearm_i, trigMode_i ) is
      variable v        : RegType;

   begin
      v := r;
      
      -- Set Reset Register 0
      if (s_trigSwRe = '1') then
         v.trigSwReg := '1';
      elsif (s_clearRe = '1') then
         v.trigSwReg := '0';
      else
         v.trigSwReg := r.trigSwReg;
      end if;

      -- Set Reset Register 1
      if (s_trigCascRe = '1') then
         v.trigCascReg := '1';
      elsif (s_clearRe = '1') then
         v.trigCascReg := '0';
      else
         v.trigCascReg := r.trigCascReg;
      end if;

      -- Set Reset Register 2
      if (s_trigHwRe = '1') then
         v.trigHwReg := '1';
      elsif (s_clearRe = '1') then
         v.trigHwReg := '0';
      else
         v.trigHwReg := r.trigHwReg;
      end if;
      
      -- Set Reset Register 3
      if (s_armRe = '1') then
         v.armedReg := '1';
      elsif (s_trigHwRe = '1') then
         v.armedReg := '0';
      else
         v.armedReg := r.armedReg;
      end if;

      -- Set Reset Register 4
      if (r.trig = '1') then
         v.trigReg := '1';
      elsif (s_clearRe = '1') then
         v.trigReg := '0';
      else
         v.trigReg := r.trigReg;
      end if;      
      
      -- Trigger output condition
      if (daqBusy_i = '1' or trigMode_i = '1') then      
         v.trig := '0';      
      elsif (
         -- Software trigger
         (s_trigSwRe = '1' ) or
         -- Cascade trigger        
         (s_trigCascRe = '1' and trigCascMask_i = '1') or      
         -- Hardware trigger       
         (s_trigHwRe = '1' and (r.armedReg = '1' or trigHwAutoRearm_i = '1'))
      ) then
         v.trig := '1';
      else
         v.trig := '0';
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
   trigStatus_o <= r.trigReg & r.armedReg & r.trigHwReg & r.trigCascReg & r.trigSwReg;
   trig_o       <= r.trig;
---------------------------------------   
end architecture rtl;
