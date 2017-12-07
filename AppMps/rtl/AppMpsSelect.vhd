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

   -- Compute select record size
   -- 16 bits + 8 bits for digital
   -- 16 bits + 34 * byte count for analog
   constant MPS_SELECT_BITS_C : integer := 16 + ite(APP_CONFIG_G.DIGITAL_EN_C, 8, APP_CONFIG_G.BYTE_COUNT_C*34);

   type RegType is record
      mpsSelect  : MpsSelectType;
   end record;

   constant REG_INIT_C : RegType := (
      mpsSelect  => MPS_SELECT_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal beamDestInt : slv(15 downto 0);
   signal altDestInt  : slv(15 downto 0);
   signal mpsSelDin   : slv(MPS_SELECT_BITS_C-1 downto 0);
   signal mpsSelDout  : slv(MPS_SELECT_BITS_C-1 downto 0);
   signal mpsSelValid : sl;

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
      variable v         : RegType;
      variable chan      : integer;
      variable thold     : integer;
      variable beamEn    : boolean;
      variable altEn     : boolean;
      variable beamDest  : slv(15 downto 0);
   begin
      -- Latch the current value
      v := r;

      -- Init
      v.mpsSelect := MPS_SELECT_INIT_C;

      -- Data
      v.mpsSelect.valid     := diagnosticBus.strobe;
      v.mpsSelect.timeStamp := diagnosticBus.timingMessage.pulseId(15 downto 0);
      v.mpsSelect.chanData  := diagnosticBus.data(MPS_CHAN_COUNT_C-1 downto 0);
      v.mpsSelect.mpsIgnore := diagnosticBus.mpsIgnore(MPS_CHAN_COUNT_C-1 downto 0);

      for i in 0 to MPS_CHAN_COUNT_C-1 loop
         v.mpsSelect.mpsError(i) := ite(diagnosticBus.sevr(i) = 0, '0', '1');
      end loop;

      -- Set beam dest
      beamDest := (others => '0');
      beamDest(conv_integer(diagnosticBus.timingMessage.beamRequest(7 downto 4))) := '1';

      -- Beam enable decode
      v.mpsSelect.selectIdle := ite(((beamDest and beamDestInt) /= 0),'0', '1');

      -- Alt table decode
      v.mpsSelect.selectAlt := ite(((beamDest and altDestInt) /= 0),'1','0');
      
      -- Digital APP
      v.mpsSelect.digitalBus(3 downto 0) := diagnosticBus.data(30)(3 downto 0);
      v.mpsSelect.digitalBus(7 downto 4) := diagnosticBus.data(31)(3 downto 0);

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

   -- Data Input
   process(r.mpsSelect) is
      variable i   : integer;
      variable vec : slv(MPS_SELECT_BITS_C-1 downto 0);
   begin

      i   := 0;
      vec := (others=>'0');

      assignSlv(i,vec,r.mpsSelect.timeStamp);
      assignSlv(i,vec,r.mpsSelect.selectIdle);
      assignSlv(i,vec,r.mpsSelect.selectAlt);

      if APP_CONFIG_G.DIGITAL_EN_C then
         assignSlv(i,vec,r.mpsSelect.digitalBus);
      else
         for j in 0 to MPS_CHAN_COUNT_C-1 loop
            if APP_CONFIG_G.CHAN_CONFIG_C(j).THOLD_COUNT_C > 0 then
               assignSlv(i,vec,r.mpsSelect.mpsError(j));
               assignSlv(i,vec,r.mpsSelect.mpsIgnore(j));
               assignSlv(i,vec,r.mpsSelect.chanData(j));
            end if;
         end loop;
      end if;

      mpsSelDin <= vec;
   end process;

   -- FIFO
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
         din    => mpsSelDin,
         rd_clk => axilClk,
         valid  => mpsSelValid,
         dout   => mpsSelDout);

   -- Data Output
   process(mpsSelValid, mpsSelDout) is
      variable i : integer;
      variable m : MpsSelectType;
   begin

      i := 0;
      m := MPS_SELECT_INIT_C;
      m.valid := mpsSelvalid;

      assigRecord(i,mpsSelDout,m.timeStamp);
      assigRecord(i,mpsSelDout,m.selectIdle);
      assigRecord(i,mpsSelDout,m.selectAlt);

      if APP_CONFIG_G.DIGITAL_EN_C then
         assignRecord(i,mpsSelDout,m.digitalBus);
      else
         for j in 0 to MPS_CHAN_COUNT_C-1 loop
            if APP_CONFIG_G.CHAN_CONFIG_C(j).THOLD_COUNT_C > 0 then
               assignRecord(i,mpsSelDout,m.mpsError(j));
               assignRecord(i,mpsSelDout,m.mpsIgnore(j));
               assignRecord(i,mpsSelDout,m.chanData(j));
            end if;
         end loop;
      end if;

      mpsSelect <= m;
   end process;

end mapping;

