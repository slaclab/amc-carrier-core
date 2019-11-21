-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-- ADC Readout Controller
-- Receives ADC Data from an AD9592 chip.
-- Designed specifically for Ultrascale FPGAs
-- 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;

library amc_carrier_core; 

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

architecture rtl of Ad9229Core is

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
      parData => (others => (others => '0')));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   signal fadcDataClk  : sl;
   signal s_serClk     : sl;
   signal s_serDiv2Clk : sl;   
   signal s_serDiv2Rst : sl; 
   
   signal s_serData : slv(N_CHANNELS_G-1 downto 0);
   signal s_parData : Slv12Array(N_CHANNELS_G-1 downto 0);
   
   signal s_frameClk : sl;   
   signal s_parFrame : Slv(11 downto 0);   
   
begin
   
   ----------------------------------------------------
   -- Clock out 
   ----------------------------------------------------   
   U_ClkOutBufDiff : entity surf.ClkOutBufDiff
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
   U_IBUFDS : IBUFDS
      port map (
         I  => fadcDataClkP_i,
         IB => fadcDataClkN_i,
         O  => fadcDataClk); 
   
   U_serClk : BUFG
      port map (
         I => fadcDataClk,
         O => s_serClk);  

   -- Divide by 2
   U_BUFGCE_DIV : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 2)
      port map (
         I  => fadcDataClk, -- 1-bit output: Buffer
         CE => '1', -- 1-bit input: Buffer enable
         CLR=> '0', -- 1-bit input: Asynchronous clear
         O  => s_serDiv2Clk);

   -- Divide clock reset sync
   U_rstSync0 : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         RELEASE_DELAY_G => 5)
      port map (
         clk      => s_serDiv2Clk,
         asyncRst => sampleRst,
         syncRst  => s_serDiv2Rst);
      
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
 
      Ad9229Deserializer_INST: entity amc_carrier_core.Ad9229Deserializer
         generic map (
            TPD_G             => TPD_G,
            IODELAY_GROUP_G   => IODELAY_GROUP_G,
            IDELAYCTRL_FREQ_G => 370.0)
         port map (
            clkSer     => s_serClk,
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
   Ad9229Deserializer_INST: entity amc_carrier_core.Ad9229Deserializer
      generic map (
         TPD_G             => TPD_G,
         IODELAY_GROUP_G   => IODELAY_GROUP_G,
         IDELAYCTRL_FREQ_G => 370.0)
      port map (
         clkSer     => s_serClk,
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
   
end rtl;
