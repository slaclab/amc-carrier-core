-------------------------------------------------------------------------------
-- Title      : Sample rate decimation circuit
-------------------------------------------------------------------------------
-- File       : DaqDecimator.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2016-05-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Reduces the sample rate:
--                   test_i = '1' : Output counter test data
--                   test_i = '0' : Output sample data
--                   averaging_i = '1':
--                         rateDiv_i (only powers of two)
--                         0 - SR, 1 - SR, 2 - SR/2, 4 - SR/4, 8 - SR/8 up to 2^12
--                         Averages the samples with the window size of rateDiv_i
--                   averaging_i = '0':
--                         rateDiv_i
--                         0 - SR, 1 - SR, 2 - SR/2, 3 - SR/3, 4 - SR/4 etc. up to 2^16-1
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


entity DaqDecimator is
   generic (
      TPD_G : time     := 1 ns
      );
   port (
      clk : in sl;
      rst : in sl;

      -- Sample data I/O
      sampleData_i      : in  slv(31 downto 0);
      decSampData_o     : out slv(31 downto 0);
      
      test_i            : in  sl;
      dec16or32_i       : in  sl;
      averaging_i       : in  sl;

      rateDiv_i : in  slv(15 downto 0);
      trig_i    : in  sl;

      -- Divided rate clk
      rateClk_o : out sl
      );
end entity DaqDecimator;

architecture rtl of DaqDecimator is

   type RegType is record
      sampleData     : slv(sampleData_i'range);
      testDataCnt    : slv(sampleData_i'range); 
      cnt            : slv(15 downto 0);
      divClk         : sl;
      shft           : slv(1 downto 0);
      prevFrame      : slv(15 downto 0);
      sum            : slv(63 downto 0);
      average        : slv(sampleData_i'range);
      rateClk         : sl;
      decSampleData  : slv(sampleData_i'range);
   end record RegType;

   constant REG_INIT_C : RegType := (
      sampleData     => (others => '0'),
      testDataCnt    => (others => '0'),
      cnt            => (others => '0'),
      divClk         => '0',
      shft           => "01",
      prevFrame      => (others => '0'),      
      sum            => (others => '0'),
      average        => (others => '0'),
      rateClk        => '0',
      decSampleData  => (others => '0')
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   signal s_countPeriod : slv(rateDiv_i'range);
   
   
begin
   
   -- Divide count period by 2 if 16-bit
   s_countPeriod <= rateDiv_i when dec16or32_i = '0' else '0'& rateDiv_i(rateDiv_i'left downto 1);
   
   
   comb : process (r, rst, trig_i, rateDiv_i, s_countPeriod, sampleData_i, dec16or32_i, averaging_i, test_i) is
      variable v        : RegType;
      variable vSum     : slv(r.sum'range);
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
      
      -- Assign sample data according to different modes
      if (test_i = '1' and dec16or32_i = '0') then
        v.sampleData := r.testDataCnt;
      elsif (test_i = '1' and dec16or32_i = '1') then
        v.sampleData := r.testDataCnt(15 downto 0)+1 & r.testDataCnt(15 downto 0);
      else
        v.sampleData := sampleData_i;
      end if;

      -- rateDiv clock generator 
      if (s_countPeriod = (s_countPeriod'range => '0') or (rateDiv_i <= 1)) then
         v.cnt    := (others => '0');
         v.divClk := '1';
      elsif (r.cnt >= s_countPeriod-1) then
         v.cnt    := (others => '0');
         v.divClk := '1';
      else
         v.cnt    := r.cnt + 1;
         v.divClk := '0';
      end if;

      -- Make a shifted control signal that indicates when to save and when to sample data
      if (dec16or32_i = '0' or (rateDiv_i <= 1)) then
         -- Shift and store disabled
         v.shft := "10";
      elsif (r.divClk = '1') then
         v.shft := r.shft(0) & r.shft(1);
      else
         v.shft := r.shft;
      end if;

      -- Sum data
      if (dec16or32_i = '0') then
         v.sum := r.sum+r.sampleData;
      else
         v.sum := r.sum+r.sampleData(31 downto 16)+r.sampleData(15 downto 0);
      end if;
      
      vSum := v.sum;
      
      -- Power of 2 Divide (reduced to 12 to see if improves timing)
      for i in 0 to 12 loop
         if (rateDiv_i(i)= '1') then
            v.average := vSum(v.average'range);            
         else 
            vSum := '0' & vSum(v.sum'left downto 1);
         end if;
      end loop;
      
      -- Zero data if period reached
      -- so next sum starts fresh
      if (r.divClk = '1') then
         v.sum := (others => '0');
      end if;
      
      -- Bypass average if disabled 
      if (averaging_i ='0') then
         v.average := r.sampleData;
      end if;      
      
      -- Save frame
      if (r.divClk = '1' and r.shft = "01") then
         v.prevFrame := v.average(15 downto 0);
      else
         v.prevFrame := r.prevFrame;
      end if;
      
      -- Register decimated Sample data
      if (rateDiv_i <= 1) then
         v.decSampleData := r.sampleData;
      elsif (dec16or32_i = '1') then
         v.decSampleData := v.average(15 downto 0) & r.prevFrame;
      else
         v.decSampleData := v.average;
      end if;
            
      -- Register rate clock (decimated data strobe)
      if (r.divClk = '1' and r.shft = "10") then
         v.rateClk := '1';
      else
         v.rateClk := '0';
      end if;
      
      -- If disabled zero some of the data
      -- trig_i also resets the module and therefore syncs internal counters of all lanes
      if (trig_i = '1') then
         v.divClk    := '0';
         v.rateClk   := '0';
         v.cnt       := (others => '0');
         v.prevFrame := (others => '0');
         v.shft      := "01";
         v.sum       := (others => '0');
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
   rateClk_o      <= r.rateClk;
   decSampData_o  <= r.decSampleData;
---------------------------------------   
end architecture rtl;
