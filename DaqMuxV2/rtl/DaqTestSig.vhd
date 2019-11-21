-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Reduces the sample rate:
--                   test_i = '1' : Output counter test data
--                   test_i = '0' : Output sample data           
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

library amc_carrier_core;
use amc_carrier_core.DaqMuxV2Pkg.all;

entity DaqTestSig is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and reset
      clk           : in  sl;
      rst           : in  sl;
      -- Configuration
      test_i        : in  sl;
      signed_i      : in  sl;
      dec16or32_i   : in  sl;
      signWidth_i   : in  slv(4 downto 0);
      trig_i        : in  sl;
      -- Sample data I/O
      sampleData_i  : in  slv(31 downto 0);
      sampleValid_i : in  sl;
      sampleData_o  : out slv(31 downto 0);
      sampleValid_o : out sl);
end entity DaqTestSig;

architecture rtl of DaqTestSig is

   type RegType is record
      sampleValid : sl;
      sampleData  : slv(sampleData_i'range);
      testDataCnt : slv(sampleData_i'range);
   end record RegType;

   constant REG_INIT_C : RegType := (
      sampleValid => '0',
      sampleData  => (others => '0'),
      testDataCnt => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (dec16or32_i, r, rst, sampleData_i, sampleValid_i,
                   signWidth_i, signed_i, test_i, trig_i) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobe
      v.sampleValid := '0';

      -- Check for inbound valid
      if (sampleValid_i = '1') then
      
         -- Set the flag
         v.sampleValid := '1';

         -- Check for unsigned data
         if (signed_i = '0') then
            v.sampleData := sampleData_i;
         -- Check for signed 32-bit data
         elsif (dec16or32_i = '0') then
            v.sampleData := extSign(sampleData_i, conv_integer(signWidth_i));
         -- Else it's signed 16-bit data
         else
            v.sampleData(15 downto 0)  := extSign(sampleData_i(15 downto 0), conv_integer(signWidth_i));
            v.sampleData(31 downto 16) := extSign(sampleData_i(31 downto 16), conv_integer(signWidth_i));
         end if;

         -- Test data counter
         if (test_i = '0') or (trig_i = '1') then
            v.testDataCnt := (others => '0');
         elsif (dec16or32_i = '0') then
            v.testDataCnt := r.testDataCnt + 1;
         else
            v.testDataCnt := r.testDataCnt + 2;
         end if;

         -- Assign sample data according to different modes (or cases)
         if (test_i = '1' and dec16or32_i = '0') then     -- Test mode 32 bit
            v.sampleData := r.testDataCnt;
         elsif (test_i = '1' and dec16or32_i = '1') then  -- Test mode 16 bit
            v.sampleData := r.testDataCnt(15 downto 0)+1 & r.testDataCnt(15 downto 0);
         end if;

      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Output assignment
      sampleData_o  <= r.sampleData;
      sampleValid_o <= r.sampleValid;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
