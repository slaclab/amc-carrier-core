-------------------------------------------------------------------------------
-- File       : DaqTestSig.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-15
-- Last update: 2016-05-24
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

use work.StdRtlPkg.all;
use work.DaqMuxV2Pkg.all;

entity DaqTestSig is
   generic (
      TPD_G : time     := 1 ns
      );
   port (
      clk : in sl;
      rst : in sl;

      -- Sample data I/O
      sampleData_i      : in  slv(31 downto 0);
      sampleData_o      : out slv(31 downto 0);
      
      test_i            : in  sl;
      dec16or32_i       : in  sl;
      
      trig_i    : in  sl
      );
end entity DaqTestSig;

architecture rtl of DaqTestSig is

   type RegType is record
      sampleData     : slv(sampleData_i'range);
      testDataCnt    : slv(sampleData_i'range); 
   end record RegType;

   constant REG_INIT_C : RegType := (
      sampleData     => (others => '0'),
      testDataCnt    => (others => '0')
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
begin
     
   comb : process (r, rst, trig_i, sampleData_i, dec16or32_i, test_i) is
      variable v        : RegType;
   begin
      v := r;
      
      -- Test data counter
      if (test_i = '0' or trig_i = '1') then 
         v.testDataCnt := (others=>'0');
      elsif (dec16or32_i = '0') then
         v.testDataCnt := r.testDataCnt + 1;
      else
         v.testDataCnt := r.testDataCnt + 2;
      end if;
      
      -- Assign sample data according to different modes (or cases)
      if (test_i = '1' and dec16or32_i = '0') then -- Test mode 32 bit
         v.sampleData := r.testDataCnt;
      elsif (test_i = '1' and dec16or32_i = '1') then -- Test mode 16 bit
         v.sampleData := r.testDataCnt(15 downto 0)+1 & r.testDataCnt(15 downto 0);
      else
         v.sampleData := sampleData_i;
      end if;
     
      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
      sampleData_o <= v.sampleData;
   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
---------------------------------------   
end architecture rtl;
