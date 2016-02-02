-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaAccumulator.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2016-01-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing BSA Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Timing BSA Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

entity BsaAccumulator is

   generic (
      TPD_G               : time                      := 1 ns;
      BSA_NUMBER_G        : integer range 0 to 64     := 0;
      BSA_ACCUM_FLOAT_G   : boolean                   := true;
      NUM_ACCUMULATIONS_G : integer range 1 to 32     := 28;
      FRAME_SIZE_BYTES_G  : integer range 128 to 4096 := 2048;
      AXIS_CONFIG_G       : AxiStreamConfigType       := ssiAxiStreamConfig(4));

   port (
      clk : in sl;
      rst : in sl;

      bsaInit        : in  sl;
      bsaActive      : in  sl;
      bsaAvgDone     : in  sl;
      bsaDone        : in  sl;
      bsaOverflow : out sl;
      diagnosticData : in  slv(31 downto 0);
      accumulateEn   : in  sl;
      setEn          : in  sl;
      lastEn         : in  sl;
      axisMaster     : out AxiStreamMasterType := axiStreamMasterInit(AXIS_CONFIG_G);
      axisSlave      : in  AxiStreamSlaveType);

end entity BsaAccumulator;

architecture rtl of BsaAccumulator is

   constant MAX_ENTRIES_C : integer := FRAME_SIZE_BYTES_G / (NUM_ACCUMULATIONS_G*4);
--   constant MAX_COUNT_G : integer := FRAME_SIZE_BYTES_G/4-1;

   type RegType is record
      count         : integer range 0 to MAX_ENTRIES_C-1;
      accumulations : Slv32Array(NUM_ACCUMULATIONS_G-1 downto 0);
      overflow : sl;
   end record RegType;


   signal r   : RegType := (count => 0, accumulations => (others => X"00000000"), overflow => '0');
   signal rin : RegType;

   -- Outputs from FB adder array
   signal adderEn      : sl;
   signal adderInA     : slv(31 downto 0);
   signal adderInALast : sl;
   signal adderInB     : slv(31 downto 0);
   signal adderOut     : slv(31 downto 0);
   signal adderValid   : sl;
   signal adderOutLast : sl;

   signal shiftEn : sl;
   signal shiftIn : slv(31 downto 0);

   signal axisMasterInt : AxiStreamMasterType := axiStreamMasterInit(AXIS_CONFIG_G);

   signal sAxisMaster : AxiStreamMasterType;
   signal sAxisSlave  : AxiStreamSlaveType;

   component BsaAddFpCore is
      port (
         aclk                 : in  sl;
         s_axis_a_tvalid      : in  sl;
         s_axis_a_tdata       : in  slv(31 downto 0);
         s_axis_a_tlast       : in  sl;
         s_axis_b_tvalid      : in  sl;
         s_axis_b_tdata       : in  slv(31 downto 0);
         m_axis_result_tvalid : out sl;
         m_axis_result_tdata  : out slv(31 downto 0);
         m_axis_result_tlast  : out sl);
   end component BsaAddFpCore;

   constant INT_AXI_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 4,
      TDEST_BITS_C  => 8,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

--    attribute srl_style : string;
--    attribute srl_style of r.accumulations : signal is "srl";

begin

   FLOAT_ADD_GEN : if (BSA_ACCUM_FLOAT_G) generate
      BSA_ADD_FP_CORE : BsaAddFpCore
         port map (
            aclk                 => clk,
            s_axis_a_tvalid      => adderEn,
            s_axis_a_tdata       => adderInA,
            s_axis_a_tlast       => adderInALast,
            s_axis_b_tvalid      => adderEn,
            s_axis_b_tdata       => adderInB,
            m_axis_result_tvalid => adderValid,
            m_axis_result_tdata  => adderOut,
            m_axis_result_tlast  => adderOutLast);
   end generate FLOAT_ADD_GEN;

   SIGNED_ADD_GEN : if (not BSA_ACCUM_FLOAT_G) generate
      add_proc : process (clk) is
      begin
         if (rising_edge(clk)) then
            adderOut     <= slv(signed(adderInA) + signed(adderInB));
            adderOutLast <= adderInALast;
            adderValid   <= adderEn;
         end if;
      end process add_proc;
   end generate SIGNED_ADD_GEN;

   adderInA     <= diagnosticData     when bsaActive = '1'               else X"00000000";
   adderInALast <= lastEn;
   adderInB     <= r.accumulations(0) when (bsaInit = '0' and setEn = '0') or bsaActive = '0' else X"00000000";
   adderEn      <= accumulateEn;

   shiftEn <= accumulateEn or adderValid;
   shiftIn <= adderOut when bsaAvgDone = '0' else X"00000000";

   sAxisMaster.tdata(127 downto 32) <= (others => '0');
   sAxisMaster.tdata(31 downto 0) <= adderOut;
   sAxisMaster.tvalid             <= adderValid and bsaAvgDone;
   sAxisMaster.tdest              <= toSlv(BSA_NUMBER_G, 8);
   sAxisMaster.tlast              <= adderOutLast and (toSl(r.count = (MAX_ENTRIES_C-1)) or bsaDone);
   sAxisMaster.tkeep              <= genTKeep(INT_AXI_STREAM_CONFIG_C);
   sAxisMaster.tStrb              <= (others => '1');
   sAxisMaster.tUser              <= (others => '0');
   sAxisMaster.tId                <= (others => '0');

   -- Maybe pass bsaDone on tUser so that we can track when it gets to ram.

   -- Note: For now, bsaDone must coincide with the last bsaAvgDone

   U_AxiStreamFifo_1 : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 0,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 0,
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 10,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1,
         LAST_FIFO_ADDR_WIDTH_G => 4,
         SLAVE_AXI_CONFIG_G  => INT_AXI_STREAM_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_G)
      port map (
         sAxisClk    => clk,            -- [in]
         sAxisRst    => rst,        -- [in]
         sAxisMaster => sAxisMaster,    -- [in]
         sAxisSlave  => sAxisSlave,     -- [out]
         sAxisCtrl   => open,           -- [out]
         mAxisClk    => clk,            -- [in]
         mAxisRst    => rst,            -- [in]
         mAxisMaster => axisMasterInt,  -- [out]
         mAxisSlave  => axisSlave,      -- [in]
         mTLastTUser => open);          -- [out]

   axisMaster.tValid <= axisMasterInt.tValid;
   axisMaster.tData  <= axisMasterInt.tData;
   axisMaster.tLast  <= axisMasterInt.tLast;
   axisMaster.tDest  <= toSlv(BSA_NUMBER_G, 8);

   comb : process (adderOutLast, r, rst, sAxisMaster, sAxisSlave, shiftEn, shiftIn) is
      variable v : RegType;

    begin
      v := r;

      if (shiftEn = '1') then
         v.accumulations(NUM_ACCUMULATIONS_G-1 downto 0) := shiftIn & r.accumulations(NUM_ACCUMULATIONS_G-1 downto 1);
      end if;

      -- Need to gracefully handle case when buffer backs up. Can't store half an entry.
      if (sAxisSlave.tReady = '0') then
         v.overflow := '1';      -- Latch overflow if tReady ever drops
      elsif (bsaInit = '1') then
         v.overflow := '0';             -- clear on init
      end if;

      --Count entries
      if (sAxisMaster.tvalid = '1' and sAxisSlave.tReady = '1' and adderOutLast = '1') then
         v.count := r.count + 1;
         if (r.count = MAX_ENTRIES_C-1) then
            v.count := 0;
         end if;
      end if;


      ----------------------------------------------------------------------------------------------
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (rst = '1') then
         v.count := 0;
         v.overflow := '0';
--         v.accumulations := (others => (others => '0'));
      end if;

      rin <= v;
      bsaOverflow <= r.overflow;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
