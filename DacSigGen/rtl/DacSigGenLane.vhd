-------------------------------------------------------------------------------
-- File       : DacSigGenLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-16
-- Last update: 2016-11-16
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
--
--               Data After trigger latency:
--               - 16bit Interface: 7x  jesdClk2x c-c
--               - 32bit Interface: 12x jesdClk c-c
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
      TPD_G        : time := 1 ns;
      ADDR_WIDTH_G : integer range 1 to 24 := 9;
      INTERFACE_G  : sl := '0' -- '0': 32 bit, '1': 16 bit
    );
   port (
      -- JESD devClk
      jesdClk         : in  sl;
      jesdRst         : in  sl;
      jesdClk2x       : in  sl;
      jesdRst2x       : in  sl; 
      
      -- AXI lite
      axilClk         : in sl;
      axilRst         : in sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Control generation (Cannot be altered when running)
      enable_i        : in  sl;
      mode_i          : in  sl;
      period_i        : in  slv(ADDR_WIDTH_G-1 downto 0);
      start_i         : in  sl;
      sign_i          : in  sl;
      --
      overflow_o      : out sl;
      underflow_o     : out sl;
      running_o       : out sl;
      valid_o         : out sl;
      dacSigValues_o  : out slv(31 downto 0)
   );
end DacSigGenLane;

architecture rtl of DacSigGenLane is
   
   type StateType is (
      IDLE_S,
      RUNNING_S
   );
   
   -- Register
   type RegType is record
      cnt       : slv(ADDR_WIDTH_G-1 downto 0);
      running   : sl;
      runningD1 : sl;
      state     : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cnt      => (others => '0'),
      running  => '0',
      runningD1=> '0',      
      state    => IDLE_S
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Signals
   signal s_rdEn : sl;
   signal s_ramData    : slv(15 downto 0);
   signal s_16bitData  : slv(15 downto 0);
   signal s_startRe    : sl;
   signal s_zeroData   : slv(15 downto 0);
  
begin
  
   -- Synchronize and detect rising edge on trigger
   U_Sync : entity work.SynchronizerEdge
   generic map (
      TPD_G        => TPD_G
   )
   port map (
      clk    => jesdClk2x,   
      dataIn => start_i,  
      risingEdge => s_startRe  -- Rising edge
   );
   
   -- Always read when enabled
   s_rdEn <= enable_i;
   
   AxiDualPortRam_INST: entity work.AxiDualPortRam
   generic map (
      TPD_G        => TPD_G,
      BRAM_EN_G    => true,
      REG_EN_G     => true,
      MODE_G       => "write-first",
      ADDR_WIDTH_G => ADDR_WIDTH_G,
      DATA_WIDTH_G => 16,
      INIT_G       => x"FFFF")
   port map (
      -- Axi clk domain
      axiClk         => axilClk,
      axiRst         => axilRst,
      axiReadMaster  => axilReadMaster,
      axiReadSlave   => axilReadSlave,
      axiWriteMaster => axilWriteMaster,
      axiWriteSlave  => axilWriteSlave,
      
      
      -- Dev clk domain
      clk            => jesdClk2x,
      rst            => jesdRst2x,
      en             => s_rdEn,
      addr           => r.cnt,
      dout           => s_ramData);
      
   -- Address counter
   comb : process (r, jesdRst2x, period_i, enable_i, mode_i, s_startRe) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r; 
      -- Delay to align with ram data
      v.runningD1 := r.running;
      
      -- State Machine
      StateMachine : case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            v.running := '0';
            v.cnt     := (others => '0');
            -- Wait for a trigger
            if (  (enable_i = '1' and mode_i = '1') or
                  (enable_i = '1' and mode_i = '0' and s_startRe = '1')
            ) then
               -- Next state
               v.state := RUNNING_S;
            end if;         
         when RUNNING_S =>
            v.running := '1';
            --
            if (r.cnt = period_i) then 
               v.cnt := (others => '0');
               if (enable_i = '0') then  -- Disabled go back to idle
                  -- Next state
                  v.state := IDLE_S;
               elsif (mode_i = '0') then -- Triggered mode go back to idle
                  -- Next state
                  v.state := IDLE_S;                  
               end if;
            else 
               v.cnt := r.cnt + 1;    
            end if;   
         
         ----------------------------------------------------------------------
         when others => null;

      ----------------------------------------------------------------------
      end case StateMachine;         
      
      if (jesdRst2x = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;
      
   end process comb;

   seq : process (jesdClk2x) is
   begin
      if (rising_edge(jesdClk2x)) then
         r <= rin after TPD_G;
      end if;
   end process seq; 
   
   -- Determine zero data according to sign format
   s_zeroData <= x"0000" when sign_i = '0' else
                 x"8000";
   -- Zero data if disabled
   s_16bitData <= s_ramData when r.runningD1 = '1' else 
                  s_zeroData;

   -- jesdClk domain
   GEN_32bit : if INTERFACE_G = '0' generate
      -- Output sync and assignment      
      U_Jesd16bTo32b: entity work.Jesd16bTo32b
      generic map (
         TPD_G => TPD_G)
      port map (
         wrClk    => jesdClk2x,
         wrRst    => jesdRst2x,
         validIn  => enable_i,
         dataIn   => s_16bitData,
         overflow => overflow_o,
         underflow=> underflow_o, 
         rdClk    => jesdClk,
         rdRst    => jesdRst,
         validOut => valid_o,
         dataOut  => dacSigValues_o);
      --
      U_Sync: entity work.Synchronizer
         generic map (
            TPD_G  => TPD_G)
         port map (
            clk     => jesdClk,
            rst     => jesdRst,
            dataIn  => r.runningD1,
            dataOut => running_o);
   end generate GEN_32bit;

   -- jesdClk2x domain
   GEN_16bit : if INTERFACE_G = '1' generate   
      -- Output assignment
      overflow_o   <= '0';
      underflow_o  <= '0';
      running_o    <= r.runningD1;
      valid_o      <= enable_i;
      dacSigValues_o(15 downto 0)  <= s_16bitData;
      dacSigValues_o(31 downto 16) <= (15 downto 0 => '0');
   end generate GEN_16bit;

end rtl;
