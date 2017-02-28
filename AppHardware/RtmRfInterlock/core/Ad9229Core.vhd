-------------------------------------------------------------------------------
-- Title      : Ad9228 Readout Deserializer
-------------------------------------------------------------------------------
-- File       : Ad9228Core.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-08-09
-- Last update: 2016-08-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-- ADC Readout Controller
-- Receives ADC Data from an AD9592 chip.
-- Designed specifically for Ultrascale FPGAs
-- 
-------------------------------------------------------------------------------
-- This file is part of DeviceLib. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of DeviceLib including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

use work.StdRtlPkg.all;

entity Ad9229Core is
   generic (
      TPD_G           : time := 1 ns;
      IODELAY_GROUP_G : string:= "DEFAULT_GROUP";
      N_CHANNELS_G    : positive := 4 
   );
   port (
      -- Desired sample clock
      sampleClk : in sl;
      sampleRst : in sl;

      -- Direct To the Chip Interface IO
      fadcClkP_o : out sl;
      fadcClkN_o : out sl;

      fadcFrameClkP_i : in sl;
      fadcFrameClkN_i : in sl;

      fadcDataClkP_i : in sl;
      fadcDataClkN_i : in sl;

      serDataP_i : in slv(N_CHANNELS_G-1 downto 0);
      serDataN_i : in slv(N_CHANNELS_G-1 downto 0);
      
      -- Parallel data out
      parData_o : out Slv12Array(N_CHANNELS_G-1 downto 0);
      locked_o  : out sl;
      
      -- IDelay control
      curDelay_o : out Slv9Array(N_CHANNELS_G downto 0);
      setDelay_i : in  Slv9Array(N_CHANNELS_G downto 0);
      setValid_i : in  sl
   );
end Ad9229Core;

architecture Behavioral of Ad9229Core is

   -- Alignment mechanism
   type RegType is record
      slip       : sl;
      count      : slv(8 downto 0);
      locked     : sl;
      parData    : Slv12Array(N_CHANNELS_G-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      slip       => '0',
      count      => (others => '0'),
      locked     => '0',
      parData => (others => (others => '0'))
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   signal x_serClk  : sl;
   signal x_serClkB : sl;   
   signal s_serClk  : sl;
   signal s_serClkB : sl;
   signal s_serClkG : sl;
   signal s_serRstG : sl;
   signal s_serDiv2Clk : sl;   
   signal s_serDiv2Rst : sl; 
   
   signal s_serData : slv(N_CHANNELS_G-1 downto 0);
   signal s_parData : Slv12Array(N_CHANNELS_G-1 downto 0);
   
   -- Alignment mechanism
   signal s_frameClk : sl;   
   signal s_parFrame : Slv(11 downto 0);   
   
   
   attribute keep : string;

   attribute IODELAY_GROUP                          : string;
   attribute IODELAY_GROUP of U_IDELAYCTRL : label is IODELAY_GROUP_G;

   -- attribute KEEP_HIERARCHY                          : string;
   -- attribute KEEP_HIERARCHY of U_IDELAYCTRL : label is "TRUE";
   
begin
   
   ----------------------------------------------------
   -- Clock out 
   ----------------------------------------------------   
   U_ClkOutBufDiff : entity work.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clkIn   => sampleClk,      
         rstIn   => sampleRst,
         clkOutP => fadcClkP_o,
         clkOutN => fadcClkN_o);
         
   ----------------------------------------------------
   -- Fast Serial Clock
   ----------------------------------------------------   
   -- Fast Serial Clock Differential input buffer
   U_IBUFDS_DIFF : IBUFDS_DIFF_OUT
   port map (
      I  => fadcDataClkP_i, -- 1-bit input: Diff_p buffer input (connect directly to top-level port)
      IB => fadcDataClkN_i,
      O  => x_serClk,      -- 1-bit output: Buffer diff_p output
      OB => x_serClkB);    -- 1-bit output: Buffer diff_n output
   
   U_serClk : BUFG
      port map (
         I => x_serClk,
         O => s_serClk);  

   U_serClkB : BUFG
      port map (
         I => x_serClkB,
         O => s_serClkB);           
   
   -- Divide by 2
   U_BUFGCE_DIV : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)
      port map (
         I  => x_serClk, -- 1-bit output: Buffer
         CE => '1', -- 1-bit input: Buffer enable
         CLR=> '0', -- 1-bit input: Asynchronous clear
         O  => s_serDiv2Clk);

   -- Divide clock reset sync
   U_rstSync0 : entity work.RstSync
      generic map (
         TPD_G           => TPD_G,
         RELEASE_DELAY_G => 5)
      port map (
         clk      => s_serDiv2Clk,
         asyncRst => sampleRst,
         syncRst  => s_serDiv2Rst);
   
   ----------------------------------------------------   
   -- Delay controller group
   ----------------------------------------------------
   -- U_BUFG : BUFG
   -- port map (
      -- I  => s_serClk, -- 1-bit output: Buffer
      -- O  => s_serClkG);
      
   -- -- Fast Serial Clock reset sync
   -- U_rstSync1 : entity work.RstSync
      -- generic map (
         -- TPD_G           => TPD_G,
         -- RELEASE_DELAY_G => 5)
      -- port map (
         -- clk      => s_serClkG,
         -- asyncRst => sampleRst,
         -- syncRst  => s_serRstG);
   
   U_IDELAYCTRL : IDELAYCTRL
      generic map (
         SIM_DEVICE => "ULTRASCALE")
      port map (
         RDY => open, -- 1-bit output: Ready output
         REFCLK => s_serDiv2Clk, -- 1-bit input: Reference clock input
         RST => s_serDiv2Rst); -- 1-bit input: Active high reset input
      
   ----------------------------------------------------   
   -- Data Deserializers
   ----------------------------------------------------     
   GEN_DATA : for i in N_CHANNELS_G-1 downto 0 generate
      -- Data input
      U_DataIn : IBUFDS
         generic map (
            DIFF_TERM => true)
         port map (
            I  => serDataP_i(i),
            IB => serDataN_i(i),
            O  => s_serData(i));
 
      Ad9229Deserializer_INST: entity work.Ad9229Deserializer
         generic map (
            TPD_G             => TPD_G,
            IODELAY_GROUP_G   => IODELAY_GROUP_G,
            IDELAYCTRL_FREQ_G => 367.0)
         port map (
            clkSerP    => s_serClk,
            clkSerN    => s_serClkB,
            idelayClk  => s_serDiv2Clk,
            idelayRst  => s_serDiv2Rst,         
            clkSerDiv2 => s_serDiv2Clk,
            rstSerDiv2 => s_serDiv2Rst,
            clkPar     => sampleClk,
            rstPar     => sampleRst,
            slip       => r.slip,
            curDelay   => curDelay_o(i),
            setDelay   => setDelay_i(i),
            setValid   => setValid_i,
            iData      => s_serData(i),
            oData      => s_parData(i));
  end generate GEN_DATA;

   -- Frame signal input
   U_FrameIn : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => fadcFrameClkP_i,
         IB => fadcFrameClkN_i,
         O  => s_frameClk);
         
   ----------------------------------------------------   
   -- Frame clock Deserializer
   ---------------------------------------------------- 
   Ad9229Deserializer_INST: entity work.Ad9229Deserializer
      generic map (
         TPD_G             => TPD_G,
         IODELAY_GROUP_G   => IODELAY_GROUP_G,
         IDELAYCTRL_FREQ_G => 357.0)
      port map (
         clkSerP    => s_serClk,
         clkSerN    => s_serClkB,
         idelayClk  => s_serDiv2Clk,
         idelayRst  => s_serDiv2Rst,
         clkSerDiv2 => s_serDiv2Clk,
         rstSerDiv2 => s_serDiv2Rst,
         clkPar     => sampleClk,
         rstPar     => sampleRst,
         slip       => r.slip,
         curDelay   => curDelay_o(N_CHANNELS_G),
         setDelay   => setDelay_i(N_CHANNELS_G),
         setValid   => setValid_i,
         iData      => s_frameClk,
         oData      => s_parFrame);


   -------------------------------------------------------------------------------------------------
   -- ADC Bit Clocked Logic
   -------------------------------------------------------------------------------------------------      
   comb : process (r, s_parFrame, s_parData, sampleRst) is
      variable v : RegType;
   begin
      v := r;
      -------------------
      ----------------------------------------------------------------------------------------------
      -- Slip bits until correct alignment seen
      ----------------------------------------------------------------------------------------------
      v.slip := '0';

      if (r.count = 0) then
         if (s_parFrame = "111111000000") then
            v.locked := '1';
         else
            v.locked := '0';
            v.slip   := '1';
            v.count  := r.count + 1;
         end if;
      end if;
      
      -- Wait for 255 c-c. Until next slip
      if (r.count /= 0) then
         v.count := r.count + 1;
      end if;

      ----------------------------------------------------------------------------------------------
      -- ZERO the data if not locked
      ----------------------------------------------------------------------------------------------
      for i in N_CHANNELS_G-1 downto 0 loop
         if (r.locked = '1' and s_parFrame = "111111000000") then
            -- Locked, output adc data
            v.parData(i) := s_parData(i);
         else
            -- Not locked
            v.parData(i) := (others => '0');
         end if;
      end loop;
     
      if (sampleRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
      
   end process comb;

   seq : process (sampleClk) is
   begin
      if (rising_edge(sampleClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
   
   -- Output assignment
   parData_o <= r.parData;
   locked_o  <= r.locked;
   
end Behavioral;

