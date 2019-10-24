-------------------------------------------------------------------------------
-- File       : AmcMrLlrfDownConvertDacMux.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-27
-- Last update: 2018-03-14
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMrLlrfDownConvertDacMux is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- External AXI-Module interface
      clk             : in  sl;
      rst             : in  sl;
      dacValues       : in  Slv16Array(2 downto 0);
      dacSclk_i       : in  sl;
      dacSdi_i        : in  sl;
      dacCsL_i        : in  slv(2 downto 0);
      -- Slow DAC's SPI Ports
      dacSclk_o       : out sl;
      dacSdi_o        : out sl;
      dacCsL_o        : out slv(2 downto 0));
end AmcMrLlrfDownConvertDacMux;

architecture rtl of AmcMrLlrfDownConvertDacMux is

   type StateType is (
      IDLE_S,
      SCK_LO_S,
      SCK_HI_S,
      CS_HIGH_S);

   type RegType is record
      csL       : slv(2 downto 0);
      sck       : sl;
      din       : sl;
      chIndex   : natural range 0 to 2;
      shift     : slv(15 downto 0);
      dacValues : Slv16Array(2 downto 0);
      cnt       : slv(15 downto 0);
      bitCnt    : slv(3 downto 0);
      state     : StateType;
   end record;
   constant REG_INIT_C : RegType := (
      csL       => (others => '1'),
      sck       => '0',
      din       => '0',
      chIndex   => 0,
      shift     => (others => '0'),
      dacValues => (others => (others => '0')),
      cnt       => (others => '0'),
      bitCnt    => (others => '0'),
      state     => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal enable     : sl;
   signal halfPeriod : slv(15 downto 0);

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";

begin

   dacCsL_o  <= dacCsL_i  when(enable = '0') else r.csL;
   dacSclk_o <= dacSclk_i when(enable = '0') else r.sck;
   dacSdi_o  <= dacSdi_i  when(enable = '0') else r.din;

   U_Reg : entity work.AmcMrLlrfDownConvertDacMuxReg
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- JESD Interface
         clk             => clk,
         enable          => enable,
         halfPeriod      => halfPeriod);

   comb : process (dacValues, enable, halfPeriod, r, rst) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Set flags
            v.csL := (others => '1');
            v.sck := '0';
            -- Wait for enable
            if (enable = '1') then
               -- Set flags and latch values only if the values are different
               -- from previously written
               if (r.dacValues(r.chIndex) /= dacValues(r.chIndex)) then
                  v.csL(r.chIndex) := '0';

                  -- Latch the value with respect to channel index
                  -- Latch the value to be shifter in and the value for 
                  -- comparison
                  v.shift                := dacValues(r.chIndex);
                  v.dacValues(r.chIndex) := dacValues(r.chIndex);
               end if;

               -- Next state
               v.state := SCK_LO_S;
            end if;
         ----------------------------------------------------------------------
         when SCK_LO_S =>
            -- Set flags
            v.sck := '0';
            -- Set the serial bit (gated with chip select)
            v.din := r.shift(15) and not r.csL(r.chIndex);
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = halfPeriod then
               -- Reset the counter
               v.cnt   := (others => '0');
               -- Next state
               v.state := SCK_HI_S;
            end if;
         ----------------------------------------------------------------------
         when SCK_HI_S =>
            -- Set clock (gated with chip select) 
            v.sck := not r.csL(r.chIndex);
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = halfPeriod then
               -- Reset the counter
               v.cnt    := (others => '0');
               -- Shift the data bus
               v.shift  := r.shift(14 downto 0) & '0';
               -- Increment the counter
               v.bitCnt := r.bitCnt + 1;
               -- Check the counter
               if r.bitCnt = x"F" then
                  -- Reset the counter
                  v.bitCnt := (others => '0');
                  -- Next state
                  v.state  := CS_HIGH_S;
               else
                  -- Next state
                  v.state := SCK_LO_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when CS_HIGH_S =>
            -- Set flags
            v.csL := (others => '1');
            v.sck := '1';
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = halfPeriod then
               -- Increment the channel index
               if r.chIndex = 2 then
                  v.chIndex := 0;
               else
                  v.chIndex := r.chIndex + 1;
               end if;

               -- Reset the counter
               v.cnt   := (others => '0');
               -- Reset the SCK flag
               v.sck   := '0';
               -- Next state
               v.state := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
