-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsFastSer.vhd
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
use work.MpsFastPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity MpsFastSer is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Fault Message
      fault      : in  slv(15 downto 0);
      faultSent  : out sl;              -- Debugging only
      -- TX Serial Stream
      mpsFastObP : out sl;              -- Diff. pair
      mpsFastObN : out sl;              -- Diff. pair
      mpsFastOb  : out sl;              -- Single Ended
      -- Clock and Reset
      clk100MHz  : in  sl;
      rst100MHz  : in  sl);
end MpsFastSer;

architecture rtl of MpsFastSer is

   constant CLK_PATTERN_C : slv(39 downto 0) := x"AAAAAAAAAA";

   type RegType is record
      tx        : sl;
      faultSent : sl;
      fault     : slv(15 downto 0);
      seqCnt    : slv(3 downto 0);
      checkSum  : slv(3 downto 0);
      cnt       : natural range 0 to 39;
      message   : slv(39 downto 0);
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      tx        => '0',
      faultSent => '0',
      fault     => (others => '0'),
      seqCnt    => (others => '0'),
      checkSum  => (others => '0'),
      cnt       => 0,
      message   => CLK_PATTERN_C);

   signal r       : RegType := REG_INIT_C;
   signal rin     : RegType;
   signal message : slv(39 downto 0);
   
begin

   OBUFDS_Inst : OBUFDS
      port map (
         I  => r.tx,
         O  => mpsFastObP,
         OB => mpsFastObN);

   Encoder8b10b_Inst : entity work.Encoder8b10b
      generic map (
         TPD_G       => TPD_G,
         NUM_BYTES_G => 4)
      port map (
         clkEn                => r.faultSent,
         clk                  => clk100MHz,
         rst                  => '0',
         dataIn(31 downto 24) => MPS_FAST_COMMA_8B_C,
         dataIn(23 downto 8)  => r.fault,
         dataIn(7 downto 4)   => r.seqCnt,
         dataIn(3 downto 0)   => r.checkSum,
         dataKIn              => MPS_FAST_DATAK_C,
         dataOut              => message); 

   comb : process (fault, message, r, rst100MHz) is
      variable v : RegType;
      variable i : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.faultSent := '0';

      -- Increment the counter
      v.cnt := r.cnt + 1;

      if r.cnt = 0 then
         -- Set the flag
         v.faultSent := '1';
         -- Sample the input fault message
         v.fault     := fault;
         -- Increment the sequence counter
         v.seqCnt    := r.seqCnt + 1;
         -- Calculate the 4-bit checksum
         v.checkSum  := v.seqCnt;
         v.checkSum  := v.checkSum + fault(15 downto 12);
         v.checkSum  := v.checkSum + fault(11 downto 8);
         v.checkSum  := v.checkSum + fault(7 downto 4);
         v.checkSum  := v.checkSum + fault(3 downto 0);
      end if;

      -- Check the counter
      if r.cnt = 39 then
         -- Preset the counter
         v.cnt     := 0;
         -- Update the encode message
         v.message := message;
      end if;

      -- Serialize the data (LSB first)
      v.tx := r.message(r.cnt);

      if rst100MHz = '1' then
         v.message := CLK_PATTERN_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs 
      mpsFastOb <= r.tx;
      faultSent <= r.faultSent and not(rst100MHz);
      
   end process comb;

   seq : process (clk100MHz) is
   begin
      if rising_edge(clk100MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
