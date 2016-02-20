-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcGenericAdcDacSyncTrig.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-19
-- Last update: 2016-02-19
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

entity AmcGenericAdcDacSyncTrig is
   generic (
      TPD_G                    : time                   := 1 ns;
      RING_BUFFER_ADDR_WIDTH_G : positive range 1 to 14 := 10);
   port (
      clk         : in  sl;
      rst         : in  sl;
      softTrig    : in  sl;
      softClear   : in  sl;
      debugTrig   : in  sl;
      debugLogEn  : out sl;
      debugLogClr : out sl);
end AmcGenericAdcDacSyncTrig;

architecture rtl of AmcGenericAdcDacSyncTrig is

   constant TIMEOUT_C : natural := (2**RING_BUFFER_ADDR_WIDTH_G)-1;
   
   type StateType is (
      IDLE_S,
      LOG_S,
      DONE_S);    

   type RegType is record
      cnt        : natural range 0 to TIMEOUT_C;
      debugLogEn : sl;
      state      : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      cnt        => 0,
      debugLogEn => '0',
      state      => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";
   
begin

   comb : process (debugTrig, r, rst, softClear, softTrig) is
      variable v : regType;
   begin
      -- Latch the current value
      v := r;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Wait for a trigger
            if (softTrig = '1') or (debugTrig = '1') then
               -- Next state
               v.state := LOG_S;
            end if;
         ----------------------------------------------------------------------
         when LOG_S =>
            -- Set the flag
            v.debugLogEn := '1';
            -- Check for timeout
            if r.cnt = TIMEOUT_C then
               -- Next state
               v.state := LOG_S;
            else
               -- Increment the counter
               v.cnt := r.cnt + 1;
            end if;
         ----------------------------------------------------------------------
         when DONE_S =>
            -- Reset the flag 
            -- Note: Blocking triggers until the reset or clear
            v.debugLogEn := '0';
      ----------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (rst = '1') or (softClear = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      debugLogEn  <= r.debugLogEn;
      debugLogClr <= softClear;
      
   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
   
end rtl;
