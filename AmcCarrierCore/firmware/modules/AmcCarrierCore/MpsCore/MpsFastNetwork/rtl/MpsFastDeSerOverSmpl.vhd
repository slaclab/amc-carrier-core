-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsFastDeSerOverSmpl.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-15
-- Last update: 2015-06-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity MpsFastDeSerOverSmpl is
   generic (
      TPD_G           : time   := 1 ns;
      IODELAY_GROUP_G : string := "MPS_IODELAY_GRP");      
   port (
      -- Oversampling Serial Stream
      mpsFastIbP   : in  sl;
      mpsFastIbN   : in  sl;
      clk200MHz    : in  sl;
      clk200MHzInv : in  sl;
      -- Down Converted serial stream
      clk100MHz    : in  sl;
      rst100MHz    : in  sl;
      serialBit    : out sl);
end MpsFastDeSerOverSmpl;

architecture rtl of MpsFastDeSerOverSmpl is

   type StateType is (
      NORMAL_S,
      SLIP_WAIT_S);   

   type RegType is record
      armed       : sl;
      slip        : sl;
      index       : natural range 0 to 3;
      smpl        : slv(7 downto 0);
      cnt         : slv(3 downto 0);
      serialValid : sl;
      serialBit   : sl;
      state       : StateType;
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      armed       => '0',
      slip        => '0',
      index       => 0,
      smpl        => x"00",
      cnt         => x"0",
      serialValid => '0',
      serialBit   => '0',
      state       => NORMAL_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal mpsFastIb    : sl;
   signal mpsFastIbDly : sl;
   signal smpl         : slv(1 downto 0);

   attribute IODELAY_GROUP                  : string;
   attribute IODELAY_GROUP of IDELAYE3_Inst : label is IODELAY_GROUP_G;

begin

   IBUFDS_Inst : IBUFDS
      port map (
         I  => mpsFastIbP,
         IB => mpsFastIbN,
         O  => mpsFastIb);

   IDELAYE3_Inst : IDELAYE3
      generic map (
         CASCADE          => "NONE",    -- Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
         DELAY_FORMAT     => "COUNT",   -- Units of the DELAY_VALUE (COUNT, TIME)
         DELAY_SRC        => "IDATAIN",   -- Delay input (DATAIN, IDATAIN)
         DELAY_TYPE       => "VARIABLE",  -- Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
         DELAY_VALUE      => 0,         -- Input delay value setting
         IS_CLK_INVERTED  => '0',       -- Optional inversion for CLK
         IS_RST_INVERTED  => '0',       -- Optional inversion for RST
         REFCLK_FREQUENCY => 200.0,     -- IDELAYCTRL clock input frequency in MHz (200.0-2400.0)
         UPDATE_MODE      => "ASYNC")  -- Determines when updates to the delay will take effect (ASYNC, MANUAL, SYNC)
      port map (
         CASC_OUT    => open,          -- 1-bit output: Cascade delay output to ODELAY input cascade
         CNTVALUEOUT => open,           -- 9-bit output: Counter value output
         DATAOUT     => mpsFastIbDly,   -- 1-bit output: Delayed data output
         CASC_IN     => '0',  -- 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
         CASC_RETURN => '0',  -- 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
         CE          => r.slip,         -- 1-bit input: Active high enable increment/decrement input
         CLK         => clk200MHz,      -- 1-bit input: Clock input
         CNTVALUEIN  => (others => '0'),  -- 9-bit input: Counter value input
         DATAIN      => '0',            -- 1-bit input: Data input from the logic
         EN_VTC      => '0',            -- 1-bit input: Keep delay constant over VT
         IDATAIN     => mpsFastIb,      -- 1-bit input: Data input from the IOBUF
         INC         => '1',            -- 1-bit input: Increment / Decrement tap delay input
         LOAD        => '0',            -- 1-bit input: Load DELAY_VALUE input
         RST         => '0');           -- 1-bit input: Asynchronous Reset to the DELAY_VALUE

   IDDRE1_Inst : IDDRE1
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE")
      port map (
         C  => clk200MHz,
         CB => clk200MHzInv,
         R  => '0',
         D  => mpsFastIbDly,
         Q2 => smpl(1),
         Q1 => smpl(0));

   comb : process (r, smpl) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobing signals
      v.slip        := '0';
      v.serialValid := '0';

      -- Shift registers
      v.smpl(1 downto 0) := smpl;
      v.smpl(7 downto 2) := r.smpl(5 downto 0);

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when NORMAL_S =>
            -- Check the flag
            if r.serialValid = '0' then
               -- Set the flags
               v.serialValid := '1';
               v.armed       := '1';
               -- Latch the bit
               v.serialBit   := r.smpl(3);
               -- Check for locked code
               if (r.smpl(3 downto 0) = x"0") or (r.smpl(3 downto 0) = x"F") then
                  -- Set the index
                  v.index := 0;
               elsif (r.smpl(4 downto 1) = x"0") or (r.smpl(4 downto 1) = x"F") then
                  -- Set the index
                  v.index := 1;
               elsif (r.smpl(5 downto 2) = x"0") or (r.smpl(5 downto 2) = x"F") then
                  -- Set the index
                  v.index := 2;
               elsif (r.smpl(6 downto 3) = x"0") or (r.smpl(6 downto 3) = x"F") then
                  -- Set the index
                  v.index := 3;
               else
                  -- Set the flag
                  v.slip  := '1';
                  -- Next State
                  v.state := SLIP_WAIT_S;
               end if;
               -- Check for index slip
               if (r.armed = '1') and (r.index /= v.index) then
                  -- Set the flag
                  v.slip  := '1';
                  -- Next State
                  v.state := SLIP_WAIT_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when SLIP_WAIT_S =>
            -- Reset the flag
            v.armed := '0';
            -- Increment the counter
            v.cnt   := r.cnt + 1;
            -- Check the flag
            if r.cnt = x"F" then
               -- Reset the counter
               v.cnt   := x"0";
               -- Next State
               v.state := NORMAL_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Register the variable for next clock cycle
      rin <= v;
      
   end process comb;

   seq : process (clk200MHz) is
   begin
      if rising_edge(clk200MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   SynchronizerFifo_Inst : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 1)
      port map (
         rst     => rst100MHz,
         -- Write Ports (wr_clk domain)
         wr_clk  => clk200MHz,
         wr_en   => r.serialValid,
         din(0)  => r.serialBit,
         -- Read Ports (rd_clk domain)
         rd_clk  => clk100MHz,
         dout(0) => serialBit);    

end rtl;
