-------------------------------------------------------------------------------
-- File       : DaqMuxV2Pkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-15
-- Last update: 2016-05-24
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

use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;

package DaqMuxV2Pkg is

-- Functions
--------------------------------------------------------------------------  
   -- Divide the slv
   function power2div(data : slv(63 downto 0); rateDiv : slv(15 downto 0)) return slv;
   -- Extend sign
   function extSign(data : slv; position : natural) return slv;
  
end DaqMuxV2Pkg;

package body DaqMuxV2Pkg is

-- Functions
--------------------------------------------------------------------------  
   -- Extend sign   
   function extSign(data : slv; position : natural) return slv is
      variable vSign : sl;
      variable vData : slv(data'range);
   begin
      -- 
      for i in data'right to data'left loop
         if (i = (data'right + position)) then 
            vSign := data(i);
            vData(i) := data(i);
         elsif (i > (data'right + position)) then 
            vData(i) := vSign;      
         else 
            vData(i) := data(i); 
         end if;         
      end loop;
      
      return vData;
      --
   end extSign;
   
   
   -- Divide the slv
   function power2div(data : slv(63 downto 0); rateDiv : slv(15 downto 0)) return slv is
   
   variable vData : slv(63 downto 0);
   
   begin
   
      case rateDiv is
      when x"0002" =>
         vData := '0' & data(63 downto 1);
        	return vData(31 downto 0);
      when x"0004" =>
         vData := "00" & data(63 downto 2);
        	return vData(31 downto 0);
      when x"0008" =>
         vData := "000" & data(63 downto 3);
        	return vData(31 downto 0);
      when x"0010" =>
         vData := "0000" & data(63 downto 4);
        	return vData(31 downto 0);
      when x"0020" =>
         vData := "00000" & data(63 downto 5);
        	return vData(31 downto 0);
      when x"0040" =>
         vData := "000000" & data(63 downto 6);
        	return vData(31 downto 0);
      when x"0080" =>
         vData := "0000000" & data(63 downto 7);
        	return vData(31 downto 0);          
      when x"0100" =>
         vData := "00000000" & data(63 downto 8);
        	return vData(31 downto 0); 
      when x"0200" =>
         vData := "000000000" & data(63 downto 9);
        	return vData(31 downto 0); 
      when x"0400" =>
         vData := "0000000000" & data(63 downto 10);
        	return vData(31 downto 0);
      when x"0800" =>
         vData := "00000000000" & data(63 downto 11);
        	return vData(31 downto 0);  
      when x"1000" =>
         vData := "000000000000" & data(63 downto 12);
        	return vData(31 downto 0); 
      when x"2000" =>
         vData := "0000000000000" & data(63 downto 13);
        	return vData(31 downto 0);    
      when x"4000" =>
         vData := "00000000000000" & data(63 downto 14);
        	return vData(31 downto 0);      
      when x"8000" =>
         vData := "000000000000000" & data(63 downto 15);
        	return vData(31 downto 0);
      when others =>  
         vData := data(63 downto 0);
        	return vData(31 downto 0);     
      end case;
   end power2div;

--------------------------------------------------------------------------------------------
end package body DaqMuxV2Pkg;
