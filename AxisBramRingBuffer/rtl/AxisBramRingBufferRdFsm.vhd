-------------------------------------------------------------------------------
-- File       : AxisBramRingBufferWrFsm.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-04-10
-- Last update: 2018-04-10
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

entity AxisBramRingBufferWrFsm is
   generic (
      TPD_G          : time     := 1 ns;
      NUM_CH_G       : positive := 1;
      BUFFER_WIDTH_G : positive := 10);
   port (
      clk    : in  sl;
      rst    : in  sl;
      valid  : in  slv(NUM_CH_G-1 downto 0);
      wrEn   : out sl;
      wrAddr : out slv(BUFFER_WIDTH_G-1 downto 0);
      req    : out sl;
      ack    : in  sl);
end AxisBramRingBufferWrFsm;

architecture mapping of AxisBramRingBufferWrFsm is

   type StateType is (
      IDLE_S);   

   type RegType is record
      wrEn   : sl;
      wrAddr : slv(BUFFER_WIDTH_G-1 downto 0);
      req    : sl;
            state      : StateType;
   end record;

   constant REG_INIT_C : RegType := (
      wrEn   => '0',
      wrAddr => (others => '0'),
      req    => '0',
      state      => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal ackSync : sl;

begin

   U_Sync : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => clk,
         dataIn  => ack,
         dataOut => ackSync);

   comb : process (r, rst) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.req := '0';

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------
         when IDLE_S =>
            NULL;
      ----------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      req    <= r.req;
      wrEn   <= r.wrEn;
      wrAddr <= r.wrAddr;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
