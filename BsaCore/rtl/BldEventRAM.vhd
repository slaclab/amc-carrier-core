-----------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : BldEventRAM.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2021-11-24
-- Last update: 2021-11-24
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 Timing Core', including this file,
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

entity BldEventRAM is

   generic (
      INIT_START_G : integer := 0 );
   port (
     clk   : in  sl;
     rst   : in  sl;
     addr  : in  slv( 8 downto 0);
     dout  : out slv(47 downto 0) );

end entity BldEventRAM;

architecture rtl of BldEventRAM is

  function INIT_VAL(iline : integer) return slv is
    variable k : integer;
    variable v : slv(255 downto 0) := (others=>'0');
  begin
    for i in 0 to 3 loop
      k := iline*4 + i;
      if k >= INIT_START_G and k<INIT_START_G+48 then
        v(64*i+k-INIT_START_G) := '1';
      end if;
    end loop;
    return v;
  end function;

  signal doutb : slv(63 downto 0);

begin

  U_RAM : RAMB36E2
    generic map ( CLOCK_DOMAINS => "COMMON",
                  DOA_REG       => 0,
                  DOB_REG       => 0,
                  INIT_00 => INIT_VAL(0),
                  INIT_01 => INIT_VAL(1),
                  INIT_02 => INIT_VAL(2),
                  INIT_03 => INIT_VAL(3),
                  INIT_04 => INIT_VAL(4),
                  INIT_05 => INIT_VAL(5),
                  INIT_06 => INIT_VAL(6),
                  INIT_07 => INIT_VAL(7),
                  INIT_08 => INIT_VAL(8),
                  INIT_09 => INIT_VAL(9),
                  INIT_0A => INIT_VAL(10),
                  INIT_0B => INIT_VAL(11),
                  INIT_0C => INIT_VAL(12),
                  INIT_0D => INIT_VAL(13),
                  INIT_0E => INIT_VAL(14),
                  INIT_0F => INIT_VAL(15),
                  INIT_10 => INIT_VAL(16),
                  INIT_11 => INIT_VAL(17),
                  INIT_12 => INIT_VAL(18),
                  INIT_13 => INIT_VAL(19),
                  INIT_14 => INIT_VAL(20),
                  INIT_15 => INIT_VAL(21),
                  INIT_16 => INIT_VAL(22),
                  INIT_17 => INIT_VAL(23),
                  INIT_18 => INIT_VAL(24),
                  INIT_19 => INIT_VAL(25),
                  INIT_1A => INIT_VAL(26),
                  INIT_1B => INIT_VAL(27),
                  INIT_1C => INIT_VAL(28),
                  INIT_1D => INIT_VAL(29),
                  INIT_1E => INIT_VAL(30),
                  INIT_1F => INIT_VAL(31),
                  INIT_20 => INIT_VAL(32),
                  INIT_21 => INIT_VAL(33),
                  INIT_22 => INIT_VAL(34),
                  INIT_23 => INIT_VAL(35),
                  INIT_24 => INIT_VAL(36),
                  INIT_25 => INIT_VAL(37),
                  INIT_26 => INIT_VAL(38),
                  INIT_27 => INIT_VAL(39),
                  INIT_28 => INIT_VAL(40),
                  INIT_29 => INIT_VAL(41),
                  INIT_2A => INIT_VAL(42),
                  INIT_2B => INIT_VAL(43),
                  INIT_2C => INIT_VAL(44),
                  INIT_2D => INIT_VAL(45),
                  INIT_2E => INIT_VAL(46),
                  INIT_2F => INIT_VAL(47),
                  INIT_30 => INIT_VAL(48),
                  INIT_31 => INIT_VAL(49),
                  INIT_32 => INIT_VAL(50),
                  INIT_33 => INIT_VAL(51),
                  INIT_34 => INIT_VAL(52),
                  INIT_35 => INIT_VAL(53),
                  INIT_36 => INIT_VAL(54),
                  INIT_37 => INIT_VAL(55),
                  INIT_38 => INIT_VAL(56),
                  INIT_39 => INIT_VAL(57),
                  INIT_3A => INIT_VAL(58),
                  INIT_3B => INIT_VAL(59),
                  INIT_3C => INIT_VAL(60),
                  INIT_3D => INIT_VAL(61),
                  INIT_3E => INIT_VAL(62),
                  INIT_3F => INIT_VAL(63),
                  INIT_40 => INIT_VAL(64),
                  INIT_41 => INIT_VAL(65),
                  INIT_42 => INIT_VAL(66),
                  INIT_43 => INIT_VAL(67),
                  INIT_44 => INIT_VAL(68),
                  INIT_45 => INIT_VAL(69),
                  INIT_46 => INIT_VAL(70),
                  INIT_47 => INIT_VAL(71),
                  READ_WIDTH_A  => 72 )
    port map (
      CASDIMUXA => '0',
      CASDIMUXB => '0',
      CASDINA   => (others=>'0'),
      CASDINB   => (others=>'0'),
      CASDINPA  => (others=>'0'),
      CASDINPB  => (others=>'0'),
      CASDOMUXA => '0',
      CASDOMUXB => '0',
      CASDOMUXEN_A => '0',
      CASDOMUXEN_B => '0',
      CASINDBITERR => '0',
      CASINSBITERR => '0',
      CASOREGIMUXA => '0',
      CASOREGIMUXB => '0',
      CASOREGIMUXEN_A => '0',
      CASOREGIMUXEN_B => '0',
      ECCPIPECE       => '0',
      INJECTDBITERR   => '0',
      INJECTSBITERR   => '0',
      SLEEP           => '0',
      ADDRARDADDR(14 downto  6) => addr,
      ADDRARDADDR( 5 downto  0) => toSlv(0,6),
      ADDRENA                   => '1',
      CLKARDCLK                 => clk,
      ENARDEN                   => '1',
      REGCEAREGCE               => '0',
      RSTRAMARSTRAM             => rst,
      RSTREGARSTREG             => rst,
      WEA                       => (others=>'0'),
      DINADIN                   => (others=>'0'),
      DINPADINP                 => (others=>'0'),
      DOUTADOUT                 => doutb(31 downto 0),
      DOUTPADOUTP               => open,
      ADDRBWRADDR               => (others=>'0'),
      ADDRENB                   => '0',
      CLKBWRCLK                 => '0',
      ENBWREN                   => '0',
      REGCEB                    => '0',
      RSTRAMB                   => '0',
      RSTREGB                   => '0',
      WEBWE                     => (others=>'0'),
      DINBDIN                   => (others=>'0'),
      DINPBDINP                 => (others=>'0'),
      DOUTBDOUT(31 downto  0)   => doutb(63 downto 32),
      DOUTPBDOUTP               => open );

  dout <= doutb(47 downto 0);

end rtl;
