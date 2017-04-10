-------------------------------------------------------------------------------
-- File       : AppMpsSelect.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AppMpsPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsSelect is
   generic (
      TPD_G           : time             := 1 ns;
      APP_TYPE_G      : AppType          := APP_NULL_TYPE_C;
      APP_CONFIG_G    : MpsAppConfigType := MPS_APP_CONFIG_INIT);
   port (
      -- Clock
      diagnosticClk    : in  sl;
      diagnosticRst    : in  sl;
      -- Inputs
      diagnosticBusIn  : in  DiagnosticBusType;
      -- Outputs
      diagnosticBusOut : out DiagnosticBusType;
      selectIdle       : out sl;
      selectAlt        : out sl;
      digitalBus       : out slv(APP_CONFIG_C.BYTE_COUNT_C*8-1 downto 0);
      --Config
      mpsReg           : in MpsAppRegType);

end AppMpsSelect;

architecture mapping of AppMpsSelect is

   type RegType is record
      mpsMessage : MpsMessageType;
      diagOut    : DiagnosticBusType;
      selectIdle : sl;
      selectAlt  : sl;
      digitalBus : slv(APP_CONFIG_C.BYTE_COUNT_C*8-1 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
      mpsMessage => MPS_MESSAGE_INIT_C,
      diagOut    => DIAGNOSTIC_BUS_INIT_C,
      selectIdle => '0',
      selectAlt  => '0',
      digitalBus => (others=>'0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal beamDestInt : slv(15 downto 0);
   signal altDestInt  : slv(15 downto 0);

begin

   --------------------------------- 
   -- Config Sync
   --------------------------------- 
   U_SyncKickDet: entity work.SynchronizerVector 
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2 )
      port map (
         clk                   => diagnosticClk,
         rst                   => diagnosticRst,
         dataIn(15 downto  0)  => mpsReg.beamDestMask,
         dataIn(31 downto 16)  => mpsReg.altDestMask,
         dataOut(15 downto  0) => beamDestInt,
         dataOut(31 downto 16) => altDestInt);

   --------------------------------- 
   -- Thresholds
   --------------------------------- 
   comb : process (timeStrb, timeStamp, message, syncIdle, syncAlt, digSync, r) is
      variable v        : RegType;
      variable chan     : integer;
      variable thold    : integer;
      variable beamEn   : boolean;
      variable altEn    : boolean;
      variable beamDest : slv(3 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Pass diag bus through
      v.diagOut    := diagnosticBus;
      v.selectIdle := '0';
      v.selectAlt  := '0';

      -- Set beam dest
      beamDest := (others=>'0');
      beamDest(conv_integer(diagnosticBusIn.timingMessage.beamRequest(7 downto 4))) := '1';

      -- Beam enable decode
      beamEn = ((beamDest and beamDestInt) /= 0);

      -- Alt table decode
      altEn = ((beamDest and altDestInt) /= 0);

      -- BPM mode, alt = kick, idle = no beam
      if APP_TYPE_G = APP_BPM_STRIPLINE_TYPE_C or APP_TYPE_G = APP_BPM_CAVITY_TYPE_C then
         v.selectIdle := not beamEn;
         v.selectAlt  := altEn;

      -- Kicker mode, idle = no kick
      elsif APP_TYPE_G = APP_MPS_KICK_C then
         v.selectIdle := not beamEn;
      end if;

      -- LLRF is the only digital app right now
      if APP_TYPE_G = APP_CONFIG_G.DIGITAL_EN_C then
         digitalBus(3 downto 0) := diagnosticBus.data(30)(3 downto 0);
         digitalBus(7 downto 4) := diagnosticBus.data(31)(3 downto 0);
      end if;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      diagnosticBusOut <= r.diagOut;
      selectIdle       <= r.selectIdle;
      selectAlt        <= r.selectAlt;
      digitalBus       <= r.digitalBus;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;

