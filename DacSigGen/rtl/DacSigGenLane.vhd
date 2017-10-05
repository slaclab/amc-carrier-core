-------------------------------------------------------------------------------
-- File       : DacSigGenLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-16
-- Last update: 2017-08-24
-------------------------------------------------------------------------------
-- Description:  Single lane arbitrary periodic signal generator
--               The module contains a AXI-Lite accessible block RAM where the 
--               signal is defined.
--               It has two modes:
--               Triggered and Periodic:
--               Triggered:
--                 When triggered the waveform is output once up to the buffer size
--                 Rising edge is detected on the trigger
--               Periodic: 
--                 When the module is enabled it periodically reads the block RAM contents 
--                 and outputs the contents.
--                 
--               Signal has to be disabled while the period_i or RAM contents is being changed.
--               When disabled is outputs signal ZERO data according to sign format (sign_i)
--                      Sign: '0' - Signed 2's complement, '1' - Offset binary
--               INTERFACE_G defines the JESD DAC 32-bit interface vs. LVDS DAC 16-bit interface
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

use work.Jesd204bPkg.all;

entity DacSigGenLane is
   generic (
      -- General Configurations
      TPD_G        : time                  := 1 ns;
      ADDR_WIDTH_G : integer range 1 to 24 := 9;
      INTERFACE_G  : sl                    := '0';  -- '0': 32 bit,    '1': 16 bit
      RAM_CLK_G    : sl                    := '0');  -- '0': jesdClk2x, '1': jesdClk
   port (
      -- JESD Clocks and Resets
      jesdClk         : in  sl;
      jesdRst         : in  sl;
      jesdClk2x       : in  sl;
      jesdRst2x       : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Control (Cannot be altered when running)
      enable_i        : in  sl;
      mode_i          : in  sl;
      period_i        : in  slv(ADDR_WIDTH_G-1 downto 0);
      start_i         : in  sl;
      sign_i          : in  sl;
      holdLast_i      : in  sl;
      -- Status
      overflow_o      : out sl;
      underflow_o     : out sl;
      running_o       : out sl;
      sow_o           : out sl;
      valid_o         : out sl;
      dacSigValues_o  : out slv(31 downto 0));
end DacSigGenLane;

architecture rtl of DacSigGenLane is

   constant WIDTH_C : positive := ite((RAM_CLK_G = '0'), 16, 32);

   constant ZERO_SIGNED_16B_C   : slv(15 downto 0) := x"0000";
   constant ZERO_UNSIGNED_16B_C : slv(15 downto 0) := x"8000";
   constant ZERO_SIGNED_32B_C   : slv(31 downto 0) := x"00000000";
   constant ZERO_UNSIGNED_32B_C : slv(31 downto 0) := x"80008000";

   constant ZERO_SIGNED_C   : slv(WIDTH_C-1 downto 0) := ite((RAM_CLK_G = '0'), ZERO_SIGNED_16B_C, ZERO_SIGNED_32B_C);
   constant ZERO_UNSIGNED_C : slv(WIDTH_C-1 downto 0) := ite((RAM_CLK_G = '0'), ZERO_UNSIGNED_16B_C, ZERO_UNSIGNED_32B_C);
   constant RAM_INIT_C      : slv(WIDTH_C-1 downto 0) := ite((RAM_CLK_G = '0'), x"FFFF", x"FFFFFFFF");

   type StateType is (
      IDLE_S,
      RUNNING_S);

   -- Register
   type RegType is record
      cnt       : slv(ADDR_WIDTH_G-1 downto 0);
      sow       : sl;
      running   : sl;
      runningD1 : sl;
      state     : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cnt       => (others => '0'),
      sow       => '0',
      running   => '0',
      runningD1 => '0',
      state     => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal devClk     : sl;
   signal devRst     : sl;
   signal s_startRe  : sl;
   signal s_ramData  : slv(WIDTH_C-1 downto 0);
   signal s_dacData  : slv(WIDTH_C-1 downto 0);
   signal s_zeroData : slv(WIDTH_C-1 downto 0);

begin

   devClk <= jesdClk2x when(RAM_CLK_G = '0') else jesdClk;
   devRst <= jesdRst2x when(RAM_CLK_G = '0') else jesdRst;

   U_Sync : entity work.SynchronizerEdge
      generic map (
         TPD_G => TPD_G)
      port map (
         clk        => devClk,
         dataIn     => start_i,
         risingEdge => s_startRe);      -- Rising edge

   AxiDualPortRam_INST : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => true,
         REG_EN_G     => true,
         MODE_G       => "write-first",
         ADDR_WIDTH_G => ADDR_WIDTH_G,
         DATA_WIDTH_G => WIDTH_C,
         INIT_G       => RAM_INIT_C)
      port map (
         -- Axi clk domain
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave,
         -- Dev clk domain
         clk            => devClk,
         rst            => devRst,
         en             => enable_i,    -- Always read when enabled
         addr           => r.cnt,
         dout           => s_ramData);

   comb : process (devRst, enable_i, mode_i, period_i, r, s_startRe) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobes
      v.sow := '0';

      -- Delay to align with ram data
      v.runningD1 := r.running;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Reset the signals
            v.running := '0';
            v.cnt     := (others => '0');
            -- Check if periodic mode or triggered
            if (enable_i = '1' and mode_i = '1') or (enable_i = '1' and mode_i = '0' and s_startRe = '1') then
               -- Next state
               v.state := RUNNING_S;
            end if;
         ----------------------------------------------------------------------
         when RUNNING_S =>
            -- Update the status
            v.running := '1';
            -- Check for start of waveform
            if (r.cnt = 0) then
               v.sow := '1';
            end if;
            -- Check the counter
            if (r.cnt = period_i) then
               -- Reset the counter
               v.cnt := (others => '0');
               -- Check if module gets disabled
               if (enable_i = '0') then
                  -- Next state
                  v.state := IDLE_S;
               -- Check if triggered mode go back to idle
               elsif (mode_i = '0') then
                  -- Next state
                  v.state := IDLE_S;
               end if;
            else
               -- Increment the counter
               v.cnt := r.cnt + 1;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for reset
      if (devRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (devClk) is
   begin
      if (rising_edge(devClk)) then
         r <= rin after TPD_G;
         -- Determine zero data according to sign format
         if (sign_i = '0') then
            s_zeroData <= ZERO_SIGNED_C after TPD_G;
         else
            s_zeroData <= ZERO_UNSIGNED_C after TPD_G;
         end if;
         -- Check if running
         if (r.runningD1 = '1') then
            s_dacData <= s_ramData after TPD_G;
         -- Check if not holding last value
         elsif (holdLast_i = '0') then
            -- Set data to 0 volts
            s_dacData <= s_zeroData after TPD_G;
         end if;
      end if;
   end process seq;

   GEN_RAM_CLK_MODE0 : if (RAM_CLK_G = '0') generate

      -- jesdClk domain
      GEN_32bit : if (INTERFACE_G = '0') generate

         -- Output sync and assignment      
         U_Jesd16bTo32b : entity work.Jesd16bTo32b
            generic map (
               TPD_G => TPD_G)
            port map (
               wrClk     => jesdClk2x,
               wrRst     => jesdRst2x,
               validIn   => enable_i,
               dataIn    => s_dacData,
               overflow  => overflow_o,
               underflow => underflow_o,
               rdClk     => jesdClk,
               rdRst     => jesdRst,
               validOut  => valid_o,
               dataOut   => dacSigValues_o);

         U_Sync : entity work.Synchronizer
            generic map (
               TPD_G => TPD_G)
            port map (
               clk     => jesdClk,
               rst     => jesdRst,
               dataIn  => r.runningD1,
               dataOut => running_o);

         U_SyncOneShot : entity work.SynchronizerOneShot
            generic map (
               TPD_G => TPD_G)
            port map (
               clk     => jesdClk,
               rst     => jesdRst,
               dataIn  => r.sow,
               dataOut => sow_o);

      end generate GEN_32bit;

      -- jesdClk2x domain
      GEN_16bit : if (INTERFACE_G = '1') generate
         -- Output assignment
         overflow_o                   <= '0';
         underflow_o                  <= '0';
         running_o                    <= r.runningD1;
         sow_o                        <= r.sow;
         valid_o                      <= enable_i;
         dacSigValues_o(15 downto 0)  <= s_dacData(15 downto 0);
         dacSigValues_o(31 downto 16) <= (others => '0');
      end generate GEN_16bit;

   end generate GEN_RAM_CLK_MODE0;

   -- jesdClk domain
   GEN_RAM_CLK_MODE1 : if (RAM_CLK_G = '1') generate
      -- Output assignment
      overflow_o     <= '0';
      underflow_o    <= '0';
      running_o      <= r.runningD1;
      sow_o          <= r.sow;
      valid_o        <= enable_i;
      dacSigValues_o <= s_dacData;
   end generate GEN_RAM_CLK_MODE1;

end rtl;
