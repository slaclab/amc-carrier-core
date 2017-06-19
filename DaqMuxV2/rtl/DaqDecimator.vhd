-------------------------------------------------------------------------------
-- File       : DaqDecimator.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-15
-- Last update: 2016-05-24
-------------------------------------------------------------------------------
-- Description: Reduces the sample rate:
--                   averaging_i = '1':
--                         rateDiv_i (only powers of two)
--                         0 - SR, 1 - SR, 2 - SR/2, 4 - SR/4, 8 - SR/8 up to 2^15
--                         Averages the samples with the window size of rateDiv_i
--                   averaging_i = '0':
--                         rateDiv_i
--                         0 - SR, 1 - SR, 2 - SR/2, 3 - SR/3, 4 - SR/4 etc. up to 2^16-1             
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
      
      dec16or32_i       : in  sl;
      averaging_i       : in  sl;
      signed_i          : in  sl;
      
      rateDiv_i : in  slv(15 downto 0);
      trig_i    : in  sl;

      -- Divided rate clk
      rateClk_o : out sl
      );
end entity DaqDecimator;

architecture rtl of DaqDecimator is

   type RegType is record
      sampleData     : slv(sampleData_i'range);
      cnt            : slv(15 downto 0);
      divClk         : sl;
      shft           : slv(1 downto 0);
      prevFrame      : slv(15 downto 0);
      sum            : slv(63 downto 0);
      average        : slv(sampleData_i'range);
      rateClk        : sl;
      decSampleData  : slv(sampleData_i'range);
   end record RegType;

   constant REG_INIT_C : RegType := (
      sampleData     => (others => '0'),
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
   
   
   comb : process (r, rst, trig_i, rateDiv_i, s_countPeriod, sampleData_i, dec16or32_i, averaging_i, signed_i) is
      variable v        : RegType;
   begin
      v := r;
      
      -- Assign sample data according to different modes (or cases)
      if (rateDiv_i <= 1) then    -- No data manipulation
         v.sampleData := sampleData_i;
      elsif (dec16or32_i = '0') then -- Signed mode 32 bit (if signed convert to unsigned)
         v.sampleData := (sampleData_i(31) xor signed_i) & sampleData_i(30 downto 0);
      elsif (dec16or32_i = '1') then -- Signed mode 16 bit (if signed convert to unsigned)
         v.sampleData := (sampleData_i(31) xor signed_i) & sampleData_i(30 downto 16) &
                         (sampleData_i(15) xor signed_i) & sampleData_i(14 downto  0);
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
      
      -- Power of 2 Divide
      v.average := power2div(v.sum,rateDiv_i);
      
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
      elsif (dec16or32_i = '1') then -- 16 bit: if signed convert back to signed
         v.decSampleData := (v.average(15)   xor signed_i) & v.average(14 downto 0) &  
                            (r.prevFrame(15) xor signed_i) & r.prevFrame(14 downto 0);
      else -- 32 bit: if signed convert back to signed
         v.decSampleData := (v.average(31)   xor signed_i) & v.average(30 downto 0);
      end if;
            
      -- Register rate clock (decimated data strobe)
      if (r.divClk = '1' and r.shft = "10") then
         v.rateClk := '1';
      else
         v.rateClk := '0';
      end if;
      
      -- If disabled zero some of the data
      -- trig_i also resets the module and therefore syncs internal counters of all lanes
      if (trig_i = '1' and rateDiv_i > 1) then
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
