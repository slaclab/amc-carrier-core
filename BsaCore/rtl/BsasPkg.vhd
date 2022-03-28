-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'Bsa Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS Timing Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

library lcls_timing_core;
use lcls_timing_core.EvrV2Pkg.all;

package BsasPkg is

   type BsasConfigType is record
      enable      : sl;
      channelMask : slv (30 downto 0);
      channelSevr : slv (63 downto 0);
      channels    : EvrV2ChannelConfigArray(2 downto 0); -- 0=Acquire, 1=Advance
   end record;

   constant BSAS_CONFIG_INIT_C : BsasConfigType := (
      enable      => '0',
      channelMask => (others => '0'),
      channelSevr => (others => '0'),
      channels    => (others => EVRV2_CHANNEL_CONFIG_INIT_C) );

   constant BSAS_CONFIG_BITS_C : integer := 96 + 3*EVRV2_CHANNEL_CONFIG_BITS_C;

   function toSlv(r : BsasConfigType) return slv;
   function toBsasConfigType(v : slv) return BsasConfigType;

end BsasPkg;

package body BsasPkg is
  
   function toSlv(r : BsasConfigType) return slv is
      variable v : slv(BSAS_CONFIG_BITS_C-1 downto 0) := (others=>'0');
      variable i : integer := 0;
   begin
      assignSlv(i, v, r.enable);
      assignSlv(i, v, r.channelMask);
      assignSlv(i, v, r.channelSevr);
      for j in 0 to 2 loop
        assignSlv(i, v, toSlv(r.channels(j)));
      end loop;
      return v;
   end function;

   function toBsasConfigType(v : slv) return BsasConfigType is
      variable c : BsasConfigType;
      variable t : slv(EVRV2_CHANNEL_CONFIG_BITS_C-1 downto 0);
      variable i : integer := 0;
   begin
      assignRecord(i, v, c.enable);
      assignRecord(i, v, c.channelMask);
      assignRecord(i, v, c.channelSevr);
      for j in 0 to 2 loop
        assignRecord(i, v, t);
        c.channels(j) := toChannelConfig(t);
      end loop;
      return c;
   end function;

end package body;

  
