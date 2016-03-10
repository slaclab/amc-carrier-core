-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaAccumulator.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2016-03-01
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
use work.TextUtilPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity BsaAccumulator is

   generic (
      TPD_G               : time                      := 1 ns;
      BSA_NUMBER_G        : integer range 0 to 64     := 0;
      BSA_ACCUM_FLOAT_G   : boolean                   := true;
      NUM_ACCUMULATIONS_G : integer range 1 to 32     := 32;
      FRAME_SIZE_BYTES_G  : integer range 128 to 4096 := 2048;
      AXIS_CONFIG_G       : AxiStreamConfigType       := ssiAxiStreamConfig(4));

   port (
      clk : in sl;
      rst : in sl;

      bsaInit        : in  sl;
      bsaActive      : in  sl;
      bsaAvgDone     : in  sl;
      bsaDone        : in  sl;
      bsaOverflow    : out sl;
      diagnosticData : in  slv(31 downto 0);
      accumulateEn   : in  sl;
      setEn          : in  sl;
      lastEn         : in  sl;
      axisMaster     : out AxiStreamMasterType := axiStreamMasterInit(AXIS_CONFIG_G);
      axisSlave      : in  AxiStreamSlaveType);

end entity BsaAccumulator;

architecture rtl of BsaAccumulator is

   constant MAX_ENTRIES_C : integer := FRAME_SIZE_BYTES_G / ((NUM_ACCUMULATIONS_G)*4);
--   constant MAX_COUNT_G : integer := FRAME_SIZE_BYTES_G/4-1;

   type StateType is (WAIT_FULL_S, DRAIN_S);

   type RegType is record
      count         : slv(7 downto 0);
      accumulations : Slv32Array(NUM_ACCUMULATIONS_G-1 downto 0);
      overflow      : sl;
      tValid        : sl;
      tLast         : sl;
      done          : sl;
   end record RegType;


   signal r : RegType := (
      count         => (others => '0'),
      accumulations => (others => X"00000000"),
      overflow      => '0',
      tValid        => '0',
      tLast         => '0',
      done          => '0');

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

   signal fifoRst       : sl;
   signal fifoDin       : slv(63 downto 0) := (others => '0');
   signal fifoDinP      : slv(7 downto 0)  := (others => '0');
   signal fifoWrEn      : sl;
   signal fifoFull      : sl;
   signal fifoProgFull  : sl;
   signal fifoWrCount   : slv(13 downto 0);
   signal fifoDout      : slv(63 downto 0);
   signal fifoDoutP     : slv(7 downto 0)  := (others => '0');
   signal fifoRdEn      : sl;
   signal fifoEmpty     : sl;
   signal fifoProgEmpty : sl;
   signal fifoRdCount   : slv(13 downto 0);


begin

   add_proc : process (clk) is
   begin
      if (rising_edge(clk)) then
         adderOut     <= slv(signed(adderInA) + signed(adderInB));
         adderOutLast <= adderInALast;
         adderValid   <= adderEn;
      end if;
   end process add_proc;

   adderInA     <= diagnosticData     when bsaActive = '1'                                    else X"00000000";
   adderInALast <= lastEn;
   adderInB     <= r.accumulations(0) when (bsaInit = '0' and setEn = '0') or bsaActive = '0' else X"00000000";
   adderEn      <= accumulateEn;

   shiftEn <= accumulateEn or adderValid;
   shiftIn <= adderOut when bsaAvgDone = '0' else X"00000000";

   fifoDin(31 downto 0) <= adderOut;
   fifoWrEn             <= adderValid and bsaAvgDone;
   fifoDinP(0)          <= adderOutLast and bsaDone;

   -- Maybe pass bsaDone on tUser so that we can track when it gets to ram.

   -- Note: For now, bsaDone must coincide with the last bsaAvgDone

   fifoRst <= rst or bsaInit;
   FIFO36E2_inst : FIFO36E2
      generic map (
         CASCADE_ORDER           => "NONE",                 -- FIRST, LAST, MIDDLE, NONE, PARALLEL
         CLOCK_DOMAINS           => "COMMON",               -- COMMON, INDEPENDENT
         EN_ECC_PIPE             => "FALSE",                -- ECC pipeline register, (FALSE, TRUE)
         EN_ECC_READ             => "FALSE",                -- Enable ECC decoder, (FALSE, TRUE)
         EN_ECC_WRITE            => "FALSE",                -- Enable ECC encoder, (FALSE, TRUE)
         FIRST_WORD_FALL_THROUGH => "TRUE",                 -- FALSE, TRUE
         INIT                    => X"000000000000000000",  -- Initial values on output port
         PROG_EMPTY_THRESH       => 3,                      -- Programmable Empty Threshold
         PROG_FULL_THRESH        => 511,                    -- Programmable Full Threshold
         -- Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
         IS_RDCLK_INVERTED       => '0',                    -- Optional inversion for RDCLK
         IS_RDEN_INVERTED        => '0',                    -- Optional inversion for RDEN
         IS_RSTREG_INVERTED      => '0',                    -- Optional inversion for RSTREG
         IS_RST_INVERTED         => '0',                    -- Optional inversion for RST
         IS_WRCLK_INVERTED       => '0',                    -- Optional inversion for WRCLK
         IS_WREN_INVERTED        => '0',                    -- Optional inversion for WREN
         RDCOUNT_TYPE            => "RAW_PNTR",             -- EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
         READ_WIDTH              => 72,                     -- 18-9
         REGISTER_MODE           => "REGISTERED",         -- DO_PIPELINED, REGISTERED, UNREGISTERED
         RSTREG_PRIORITY         => "RSTREG",               -- REGCE, RSTREG
         SLEEP_ASYNC             => "FALSE",                -- FALSE, TRUE
         SRVAL                   => X"000000000000000000",  -- SET/reset value of the FIFO outputs
         WRCOUNT_TYPE            => "RAW_PNTR",             -- EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
         WRITE_WIDTH             => 36                      -- 18-9
         )
      port map (
         -- Cascade Signals outputs: Multi-FIFO cascade signals
         CASDOUT       => open,                             -- 64-bit output: Data cascade output bus
         CASDOUTP      => open,                             -- 8-bit output: Parity data cascade output bus
         CASNXTEMPTY   => open,                             -- 1-bit output: Cascade next empty
         CASPRVRDEN    => open,                             -- 1-bit output: Cascade previous read enable
         -- ECC Signals outputs: Error Correction Circuitry ports
         DBITERR       => open,                             -- 1-bit output: Double bit error status
         ECCPARITY     => open,                             -- 8-bit output: Generated error correction parity
         SBITERR       => open,                             -- 1-bit output: Single bit error status
         -- Read Data outputs: Read output data
         DOUT          => fifoDout,                         -- 64-bit output: FIFO data output bus
         DOUTP         => fifoDoutP,                        -- 8-bit output: FIFO parity output bus.
         -- Status outputs: Flags and other FIFO status outputs
         EMPTY         => fifoEmpty,                        -- 1-bit output: Empty
         FULL          => fifoFull,                         -- 1-bit output: Full
         PROGEMPTY     => fifoProgEmpty,                    -- 1-bit output: Programmable empty
         PROGFULL      => fifoProgFull,                     -- 1-bit output: Programmable full
         RDCOUNT       => fifoRdCount,                      -- 14-bit output: Read count
         RDERR         => open,                             -- 1-bit output: Read error
         RDRSTBUSY     => open,                             -- 1-bit output: Reset busy (sync to RDCLK)
         WRCOUNT       => fifoWrCount,                      -- 14-bit output: Write count
         WRERR         => open,                             -- 1-bit output: Write Error
         WRRSTBUSY     => open,                             -- 1-bit output: Reset busy (sync to WRCLK)
         -- Cascade Signals inputs: Multi-FIFO cascade signals
         CASDIN        => (others => '0'),                  -- 64-bit input: Data cascade input bus
         CASDINP       => (others => '0'),                  -- 8-bit input: Parity data cascade input bus
         CASDOMUX      => '0',                              -- 1-bit input: Cascade MUX select input
         CASDOMUXEN    => '0',                              -- 1-bit input: Enable for cascade MUX select
         CASNXTRDEN    => '0',                              -- 1-bit input: Cascade next read enable
         CASOREGIMUX   => '0',                              -- 1-bit input: Cascade output MUX select
         CASOREGIMUXEN => '0',                              -- 1-bit input: Cascade output MUX select enable
         CASPRVEMPTY   => '0',                              -- 1-bit input: Cascade previous empty
         -- ECC Signals inputs: Error Correction Circuitry ports
         INJECTDBITERR => '0',                              -- 1-bit input: Inject a double bit error
         INJECTSBITERR => '0',                              -- 1-bit input: Inject a single bit error
         -- Read Control Signals inputs: Read clock, enable and reset input signals
         RDCLK         => clk,                              -- 1-bit input: Read clock
         RDEN          => fifoRdEn,                         -- 1-bit input: Read enable
         REGCE         => '1',                              -- 1-bit input: Output register clock enable
         RSTREG        => fifoRst,                          -- 1-bit input: Output register reset
         SLEEP         => '0',                              -- 1-bit input: Sleep Mode
         -- Write Control Signals inputs: Write clock and enable input signals
         RST           => fifoRst,                          -- 1-bit input: Reset
         WRCLK         => clk,                              -- 1-bit input: Write clock
         WREN          => fifoWrEn,                         -- 1-bit input: Write enable
         -- Write Data inputs: Write input data
         DIN           => fifoDin,                          -- 64-bit input: FIFO data input bus
         DINP          => fifoDinP                          -- 8-bit input: FIFO parity input bus
         );


   fifoRdEn <= r.tValid and axisSlave.tReady;

   assert (r.overflow = '0') report "BsaAccumulator " & str(BSA_NUMBER_G) & " overflowed." severity error;

   comb : process (adderOutLast, adderValid, axisSlave, bsaAvgDone, bsaDone, bsaInit, fifoDout,
                   fifoDoutP, fifoFull, fifoProgEmpty, fifoProgFull, fifoRdCount, r, rst, shiftEn,
                   shiftIn) is
      variable v : RegType;

   begin
      v := r;

      -- SRL to hold accumulations
      if (shiftEn = '1') then
         v.accumulations(NUM_ACCUMULATIONS_G-1 downto 0) := shiftIn & r.accumulations(NUM_ACCUMULATIONS_G-1 downto 1);
      end if;

      -- Need to gracefully handle case when buffer backs up. Can't store half an entry.
      if (fifoFull = '1' and bsaAvgDone = '1') then
         v.overflow := '1';             -- Latch overflow if tReady ever drops
      end if;



      -- Start a readout when progFull (2k Bytes) reached      
      if (r.tValid = '0' and fifoProgFull = '1') then
         v.tValid := '1';
      end if;

      -- Alternately, start a readout when bsaDone      
      if (adderValid = '1' and adderOutLast = '1' and bsaDone = '1') then
         v.tValid := '1';
         v.done   := '1';
      end if;

      -- Done forces tValid so that bsaDone readout doesn't get lost if it arrives right after a normal readout
      if (r.done = '1') then
         v.tValid := '1';
      end if;

      -- Send tLast when 2k Bytes have been read out
      if (r.tValid = '1' and (fifoRdCount(7 downto 0) = X"00") and axisSlave.tReady = '1') then
         v.tLast := '1';
      end if;

      -- Done indicates a partial burst is possible. Fifo must be read empty.
      if (r.tValid = '1' and r.done = '1' and fifoProgEmpty = '1') then
         v.tLast := '1';
         v.done  := '0';
      end if;

      -- Clear valid when tLast has been read
      if (r.tValid = '1' and r.tLast = '1' and axisSlave.tReady = '1') then
         v.tValid := r.done;            -- bsaDone readout might have stacked
         v.tLast  := '0';
      end if;


      axisMaster.tValid             <= r.tValid;
      axisMaster.tData(63 downto 0) <= fifoDout;
      axisMaster.tLast              <= r.tLast;
      axisMaster.tDest              <= toSlv(BSA_NUMBER_G, 8);
      axisMaster.tKeep              <= X"00FF";
      axisMaster.tStrb              <= X"00FF";
      axisMaster.tUser(7)           <= uOr(fifoDoutP);

      ----------------------------------------------------------------------------------------------
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (rst = '1' or bsaInit = '1') then
         v.count    := (others => '0');
         v.overflow := '0';
--         v.accumulations := (others => (others => '0'));
         v.tValid   := '0';
         v.tLast    := '0';
         v.done     := '0';
      end if;

      rin         <= v;
      bsaOverflow <= r.overflow;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
