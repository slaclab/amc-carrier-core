-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_13_CXX
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

library unisim;
use unisim.vcomponents.all;

entity AmcGenericAdcDacVcoSpi is
   generic (
      TPD_G : time := 1 ns);
   port (
      clk             : in  sl;
      rst             : in  sl;
      dacVcoEnable    : in  sl;
      dacVcoCtrl      : in  slv(15 downto 0);
      dacVcoSckConfig : in  slv(15 downto 0);
      -- Slow DAC's SPI Ports
      dacVcoCsP       : out sl;
      dacVcoCsN       : out sl;
      dacVcoSckP      : out sl;
      dacVcoSckN      : out sl;
      dacVcoDinP      : out sl;
      dacVcoDinN      : out sl);
end AmcGenericAdcDacVcoSpi;

architecture rtl of AmcGenericAdcDacVcoSpi is

   type StateType is (
      IDLE_S,
      SCK_LO_S,
      SCK_HI_S,
      CS_HIGH_S);    

   type RegType is record
      csL        : sl;
      sck        : sl;
      din        : sl;
      dacValue   : slv(15 downto 0);
      halfPeriod : slv(15 downto 0);
      cnt        : slv(15 downto 0);
      bitCnt     : slv(3 downto 0);
      state      : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      csL        => '1',
      sck        => '0',
      din        => '0',
      dacValue   => (others => '0'),
      halfPeriod => (others => '0'),
      cnt        => (others => '0'),
      bitCnt     => (others => '0'),
      state      => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";
   
begin

   OBUFDS_DacVcoCs : OBUFDS
      port map (
         I  => r.csL,
         O  => dacVcoCsP,
         OB => dacVcoCsN);   

   OBUFDS_DacVcoSck : OBUFDS
      port map (
         I  => r.sck,
         O  => dacVcoSckP,
         OB => dacVcoSckN);

   OBUFDS_DacVcoDin : OBUFDS
      port map (
         I  => r.din,
         O  => dacVcoDinP,
         OB => dacVcoDinN);      

   comb : process (dacVcoCtrl, dacVcoEnable, dacVcoSckConfig, r, rst) is
      variable v : regType;
   begin
      -- Latch the current value
      v := r;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Set flags
            v.csL := '1';
            v.sck := '0';
            -- Wait for enable
            if (dacVcoEnable = '1') then
               -- Sample the DAC value and half period configuration
               v.dacValue   := dacVcoCtrl;
               v.halfPeriod := dacVcoSckConfig;
               -- Next state
               v.state      := SCK_LO_S;
            end if;
         ----------------------------------------------------------------------
         when SCK_LO_S =>
            -- Set flags
            v.csL := '0';
            v.sck := '0';
            -- Set the serial bit
            v.din := r.dacValue(15);
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = r.halfPeriod then
               -- Reset the counter
               v.cnt   := (others => '0');
               -- Next state
               v.state := SCK_HI_S;
            end if;
         ----------------------------------------------------------------------
         when SCK_HI_S =>
            -- Set flags
            v.csL := '0';
            v.sck := '1';
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = r.halfPeriod then
               -- Reset the counter
               v.cnt      := (others => '0');
               -- Shift the data bus
               v.dacValue := r.dacValue(14 downto 0) & '0';
               -- Increment the counter
               v.bitCnt   := r.bitCnt + 1;
               -- Check the counter
               if r.bitCnt = x"F" then
                  -- Reset the counter
                  v.bitCnt := (others => '0');
                  -- Next state
                  v.state  := CS_HIGH_S;
               else
                  -- Next state
                  v.state := SCK_LO_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when CS_HIGH_S =>
            -- Set flags
            v.csL := '1';
            v.sck := '1';
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = r.halfPeriod then
               -- Reset the counter
               v.cnt   := (others => '0');
               -- Reset the SCK flag
               v.sck   := '0';
               -- Next state
               v.state := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;
      
   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
   
end rtl;
