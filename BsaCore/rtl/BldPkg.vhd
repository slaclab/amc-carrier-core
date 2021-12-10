-----------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : BldPkg.vhd
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

library surf;
use surf.StdRtlPkg.all;

package BldPkg is

  type EdefConfigType is record
    enable   : sl;
    rateSel  : slv(12 downto 0);
    destSel  : slv(18 downto 0);
    tsUpdate : slv( 4 downto 0);  -- update once per change in ts bit
  end record;

  constant EDEF_CONFIG_INIT_C : EdefConfigType := (
    enable   => '0',
    rateSel  => (others=>'0'),
    destSel  => (others=>'0'),
    tsUpdate => toSlv(27,5) );

  constant EDEF_CONFIG_BITS_C : integer := 38;

  type EdefConfigArray is array (natural range<>) of EdefConfigType;

  function toSlv(r : EdefConfigType) return slv;

  function toEdefConfig(v : slv) return EdefConfigType;

end BldPkg;

package body BldPkg is

  function toSlv(r : EdefConfigType) return slv is
    variable v : slv(EDEF_CONFIG_BITS_C-1 downto 0) := (others=>'0');
    variable i : integer := 0;
  begin
    assignSlv(i, v, r.enable);
    assignSlv(i, v, r.rateSel);
    assignSlv(i, v, r.destSel);
    assignSlv(i, v, r.tsUpdate);
    return v;
  end function;

  function toEdefConfig(v : slv) return EdefConfigType is
    variable c : EdefConfigType;
    variable i : integer := 0;
  begin
    assignRecord(i, v, c.enable);
    assignRecord(i, v, c.rateSel);
    assignRecord(i, v, c.destSel);
    assignRecord(i, v, c.tsUpdate);
    return c;
  end function;

end package body;
