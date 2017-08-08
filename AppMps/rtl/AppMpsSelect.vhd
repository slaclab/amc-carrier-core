-------------------------------------------------------------------------------
-- File       : AppMpsSelect.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-01
-- Last update: 2017-04-13
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AppMpsPkg.all;
use work.AmcCarrierPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppMpsSelect is
   generic (
      TPD_G        : time             := 1 ns;
      APP_TYPE_G   : AppType          := APP_NULL_TYPE_C;
      APP_CONFIG_G : MpsAppConfigType := MPS_APP_CONFIG_INIT_C);
   port (
      -- Inputs, diagnosticClk
      diagnosticClk : in  sl;
      diagnosticRst : in  sl;
      diagnosticBus : in  DiagnosticBusType;
      --Config, axilClk
      axilClk       : in  sl;
      axilRst       : in  sl;
      mpsReg        : in  MpsAppRegType;
      -- Outputs, axilClk
      mpsSelect     : out MpsSelectType);

end AppMpsSelect;

architecture mapping of AppMpsSelect is

   type RegType is record
      mpsMessage : MpsMessageType;
      mpsSelect  : MpsSelectType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsMessage => MPS_MESSAGE_INIT_C,
      mpsSelect  => MPS_SELECT_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal beamDestInt    : slv(15 downto 0);
   signal altDestInt     : slv(15 downto 0);
   signal mpsSelectDin   : slv(MPS_SELECT_BITS_C-1 downto 0);
   signal mpsSelectDout  : slv(MPS_SELECT_BITS_C-1 downto 0);
   signal mpsSelectValid : sl;

begin

   --------------------------------- 
   -- Config Sync
   --------------------------------- 
   U_SyncKickDet : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 32)
      port map (
         clk                   => diagnosticClk,
         rst                   => diagnosticRst,
         dataIn(15 downto 0)   => mpsReg.beamDestMask,
         dataIn(31 downto 16)  => mpsReg.altDestMask,
         dataOut(15 downto 0)  => beamDestInt,
         dataOut(31 downto 16) => altDestInt);

   --------------------------------- 
   -- Thresholds
   --------------------------------- 
   comb : process (altDestInt, beamDestInt, diagnosticBus, diagnosticRst, r) is
      variable v        : RegType;
      variable chan     : integer;
      variable thold    : integer;
      variable beamEn   : boolean;
      variable altEn    : boolean;
      variable beamDest : slv(15 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Init
      v.mpsSelect := MPS_SELECT_INIT_C;

      -- Data
      v.mpsSelect.valid     := diagnosticBus.strobe;
      v.mpsSelect.timeStamp := diagnosticBus.timingMessage.timeStamp;
      v.mpsSelect.chanData  := diagnosticBus.data(MPS_CHAN_COUNT_C-1 downto 0);
      v.mpsSelect.mpsIgnore := diagnosticBus.mpsIgnore(MPS_CHAN_COUNT_C-1 downto 0);

      for i in 0 to MPS_CHAN_COUNT_C-1 loop
         v.mpsSelect.mpsError(i) := ite(diagnosticBus.sevr(i) = 0, '0', '1');
      end loop;

      -- Set beam dest
      beamDest                                                                    := (others => '0');
      beamDest(conv_integer(diagnosticBus.timingMessage.beamRequest(7 downto 4))) := '1';

      -- Beam enable decode
      v.mpsSelect.selectIdle := ite(((beamDest and beamDestInt) /= 0),'0', '1');

      -- Alt table decode
      v.mpsSelect.selectAlt := ite(((beamDest and altDestInt) /= 0),'1','0');
      
      -- Digital APP
      if APP_CONFIG_G.DIGITAL_EN_C then
         v.mpsSelect.digitalBus(3 downto 0) := diagnosticBus.data(30)(3 downto 0);
         v.mpsSelect.digitalBus(7 downto 4) := diagnosticBus.data(31)(3 downto 0);
      end if;

      -- Synchronous Reset
      if (diagnosticRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (diagnosticClk) is
   begin
      if (rising_edge(diagnosticClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   ------------------------------------ 
   -- Output Synchronization Module
   ------------------------------------ 
   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => MPS_SELECT_BITS_C)
      port map (
         -- Asynchronous Reset
         rst    => diagnosticRst,
         -- Write Ports (wr_clk domain)
         wr_clk => diagnosticClk,
         wr_en  => r.mpsSelect.valid,
         din    => mpsSelectDin,
         rd_clk => axilClk,
         rd_en  => axilRst,
         valid  => mpsSelectValid,
         dout   => mpsSelectDout);

   mpsSelectDin <= toSlv (r.mpsSelect);
   mpsSelect    <= toMpsSelect (mpsSelectDout, mpsSelectValid);

end mapping;

