-------------------------------------------------------------------------------
-- Title         : BldEventSelect
-- Project       : LCLS-II Timing Pattern Generator
-------------------------------------------------------------------------------
-- File          : BldEventSelect.vhd
-- Author        : Matt Weaver, weaver@slac.stanford.edu
-- Created       : 11/24/2021
-------------------------------------------------------------------------------
-- Description:
-- Translation of BSA DEF to control bits in timing pattern
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Timing Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
-- Modification history:
-- 07/17/2015: created.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;

library lcls_timing_core;
--use lcls_timing_core.TPGPkg.all;
use lcls_timing_core.TimingPkg.all;

library amc_carrier_core;
use amc_carrier_core.BldPkg.all;

library unisim;
use unisim.vcomponents.all;

entity BldEventSelect is
  generic ( NUM_EDEFS_G : integer := 1 );
  port (
      clk        : in  sl;
      rst        : in  sl;
      config     : in  EdefConfigArray(NUM_EDEFS_G-1 downto 0);
      strobeIn   : in  sl;
      dataIn     : in  TimingMessageType;
      strobeOut  : out sl;
      selectOut  : out slv            (NUM_EDEFS_G-1 downto 0) );
end BldEventSelect;

architecture BldEventSelect of BldEventSelect is

   signal ramData          : slv(48*6-1 downto 0) := (others=>'0');
   signal controlWord      : slv(48*6-1 downto 0) := (others=>'0');
   signal noMatch          : slv(5 downto 0);

   type RegType is record
     idef      : integer range 0 to NUM_EDEFS_G;
     bdef      : integer range 0 to NUM_EDEFS_G;
     cdef      : integer range 0 to NUM_EDEFS_G;
     addr      : slv(8 downto 0);
     strobe    : slv(NUM_EDEFS_G+1 downto 0);
     selectOut : slv(NUM_EDEFS_G-1 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
     idef      => 0,
     bdef      => 0,
     cdef      => 0,
     addr      => (others=>'0'),
     strobe    => (others=>'0'),
     selectOut => (others=>'0') );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
begin

  GEN_CONTROL : for i in 0 to 16 generate
    controlWord(16*i+15 downto 16*i) <= dataIn.control(i);
  end generate;
  
  GEN_BLOCK : for i in 0 to 5 generate
    --
    --  Setup double wide single port ram to provide (1<<i) for i in 0 to 271,
    --
    U_RAM : entity amc_carrier_core.BldEventRAM
      generic map ( INIT_START_G => i*48 )
      port map ( clk    => clk,
                 rst    => rst,
                 addr   => rin.addr,
                 dout   => ramData(48*i+47 downto 48*i) );
    --
    --  Use DSP to do AND against (1<<i), result on PATTERN
    --
    U_AND : DSP48E2
      generic map ( ACASCREG   => 0,  -- unused
                    ADREG      => 0,
                    ALUMODEREG => 0,
                    AREG       => 0,  -- no regs before ADD
                    BCASCREG   => 0,
                    BREG       => 0,
                    CARRYINREG => 0,
                    CARRYINSELREG => 0,
                    CREG       => 0,
                    DREG       => 0,
                    INMODEREG  => 0,
                    MASK       => (others=>'0'),
                    MREG       => 0,
                    OPMODEREG  => 0,
                    PATTERN    => (others=>'0'),
                    USE_MULT   => "NONE",
                    USE_PATTERN_DETECT => "PATDET" )
      port map (
        A          (29 downto  0)    => ramData(48*i+47 downto 48*i+18),
        ACIN                         => (others=>'0'),
        ALUMODE                      => "1100", -- X AND Z
        B          (17 downto  0)    => ramData(48*i+17 downto 48*i),
        BCIN                         => (others=>'0'),
        C          (47 downto  0)    => controlWord(48*i+47 downto 48*i),
        CARRYCASCIN                  => '0',
        CARRYIN                      => '0',
        CARRYINSEL                   => "000",
        CEA1                         => '0',
        CEA2                         => '0',
        CEAD                         => '0',
        CEALUMODE                    => '1',
        CEB1                         => '0',
        CEB2                         => '0',
        CEC                          => '0',
        CECARRYIN                    => '0',
        CECTRL                       => '1',
        CED                          => '0',
        CEINMODE                     => '1',
        CEM                          => '0',
        CEP                          => '1',
        CLK                          => clk,
        D                            => (others=>'0'),
        INMODE                       => "00000",
        MULTSIGNIN                   => '0',
        OPMODE      (8 downto 4)     => "00011",        -- Z = C
        OPMODE      (3 downto 2)     => "00",           -- unused
        OPMODE      (1 downto 0)     => "11",           -- X = A|B
        PCIN                         => (others=>'0'),  -- unused
        PATTERNDETECT                => noMatch(i),
        RSTA                         => '0',
        RSTALLCARRYIN                => '0',
        RSTALUMODE                   => '0',
        RSTB                         => '0',
        RSTC                         => '0',
        RSTCTRL                      => '0',
        RSTD                         => '0',
        RSTINMODE                    => '0',
        RSTM                         => '0',
        RSTP                         => rst
        );
  end generate;
    
  comb : process ( r, rst, strobeIn, dataIn, noMatch, config ) is
    variable       v : RegType;
    variable rateType : slv(1 downto 0);
    variable rateSel : sl;
    variable destSel : sl;
    variable c        : EdefConfigType;
  begin
    v := r;

    if r.idef = 0 then
      if strobeIn = '1' then
        v.idef := 1;
      end if;
    elsif r.idef = NUM_EDEFS_G-1 then
      v.idef := 0;
    else  
      v.idef := r.idef + 1;
    end if;

    v.bdef := r.idef;
    v.cdef := r.bdef;
    
    v.addr := config(r.idef).rateSel(8 downto 0);
    c      := config(r.cdef);

    rateType := c.rateSel(12 downto 11);
    case rateType is
      when "00" => rateSel := dataIn.fixedRates(conv_integer(c.rateSel(3 downto 0)));
      when "01" =>
        if (c.rateSel(conv_integer(dataIn.acTimeSlot)+3-1) = '0') then
          -- acTS counts from "1"
          rateSel := '0';
        else
          rateSel := dataIn.acRates(conv_integer(c.rateSel(2 downto 0)));
        end if;
      when "10"   => rateSel := not uAnd(noMatch);
      when others => rateSel := '0';
    end case;

    destSel := '0';
    case c.destSel(17 downto 16) is
      when "10" => destSel := '1';
      when "01" => if not (dataIn.beamRequest(0)='1' and c.destSel(conv_integer(dataIn.beamRequest(7 downto 4)))='1') then
                     destSel := '1';
                   end if;    
      when "00" => if (dataIn.beamRequest(0)='1' and c.destSel(conv_integer(dataIn.beamRequest(7 downto 4)))='1') then
                     destSel := '1';
                   end if;    
      when others => null;
    end case;
               
    v.strobe := r.strobe(r.strobe'left-1 downto 0) & strobeIn;

    if r.strobe(r.strobe'left-1 downto 1) /= 0 then
      v.selectOut := (c.enable and rateSel and destSel) & r.selectOut(r.selectOut'left downto 1);
    end if;  
    
    if rst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;

    strobeOut <= r.strobe(r.strobe'left);
    selectOut <= r.selectOut;
  end process comb;

  seq: process (clk) is
   begin
      if rising_edge(clk) then
        r <= rin;
      end if;
  end process seq;

end BldEventSelect;

