-------------------------------------------------------------------------------
-- File       : LvdsDacLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-29
-- Last update: 2019-10-14
-------------------------------------------------------------------------------
-- Description:  Single lane arbitrary periodic signal generator
--               The module contains a AXI-Lite accessible block RAM where the 
--               signal is defined.
--               When the module is enabled it periodically reads the block RAM contents 
--               and outputs the contents.
--               The signal period is defined in user register.
--               Signal has to be disabled while the periodSize_i or RAM contents is being changed.
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
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

entity LvdsDacLane is
   generic (
      TPD_G        : time     := 1 ns;
      ADDR_WIDTH_G : positive := 10);
   port (
      -- devClk2x Reference
      devClk2x_i      : in  sl;
      devRst2x_i      : in  sl;
      -- AXI-Lite Interface (axilClk_i domain)
      axilClk_i       : in  sl;
      axilRst_i       : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DAC Interface (devClk_i domain)
      -- Note: 2x 16-bit samples per 32-bit word
      --       32-bit is little-endian & none byte-swapped
      devClk_i        : in  sl;
      devRst_i        : in  sl;
      extData_i       : in  slv(31 downto 0);
      -- Control generation  (devClk_i domain)
      enable_i        : in  sl;
      periodSize_i    : in  slv(ADDR_WIDTH_G-1 downto 0);
      -- Parallel data out  (devClk_i domain)
      sampleData_o    : out Slv2Array(15 downto 0));
end LvdsDacLane;

architecture rtl of LvdsDacLane is

   type RegType is record
      ramData    : slv(31 downto 0);
      periodSize : slv(ADDR_WIDTH_G-1 downto 0);
      addr       : slv(ADDR_WIDTH_G-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      ramData    => (others => '0'),
      periodSize => (others => '0'),
      addr       => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal f_ramData  : slv(15 downto 0);
   signal s_ramData  : slv(31 downto 0);
   signal ramDataReg : slv(31 downto 0);

begin

   U_RAM : entity surf.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         ADDR_WIDTH_G => ADDR_WIDTH_G,
         DATA_WIDTH_G => 16,
         INIT_G       => "0")
      port map (
         -- AXI-Lite Interface
         axiClk         => axilClk_i,
         axiRst         => axilRst_i,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave,
         -- Signal Generator Interface
         clk            => devClk2x_i,
         rst            => devRst2x_i,
         addr           => r.addr,
         dout           => f_ramData);

   comb : process (devRst2x_i, periodSize_i, r) is
      variable v : RegType;
      variable i : natural;
   begin
      -- Latch the current value
      v := r;

      -- Keep a delayed copy
      v.periodSize := periodSize_i;

      -- Increment the counter
      if (r.addr = r.periodSize) or (r.periodSize /= periodSize_i) then
         v.addr := (others => '0');
      else
         v.addr := r.addr + 1;
      end if;

      -- Synchronous Reset
      if (devRst2x_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (devClk2x_i) is
   begin
      if (rising_edge(devClk2x_i)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_Jesd16bTo32b : entity surf.Jesd16bTo32b
      generic map (
         TPD_G => TPD_G)
      port map (
         -- 16-bit Write Interface
         wrClk   => devClk2x_i,
         wrRst   => devRst2x_i,
         validIn => '1',
         dataIn  => f_ramData,
         -- 32-bit Read Interface
         rdClk   => devClk_i,
         rdRst   => devRst_i,
         dataOut => s_ramData);

   process (devClk_i) is
   begin
      if (rising_edge(devClk_i)) then
         -- Help with timing
         ramDataReg <= s_ramData after TPD_G;
      end if;
   end process;

   GEN_VEC :
   for i in 15 downto 0 generate
      sampleData_o(i)(0) <= extData_i(i+0)  when(enable_i = '0') else ramDataReg(i+0);  -- ODDR's D1 port
      sampleData_o(i)(1) <= extData_i(i+16) when(enable_i = '0') else ramDataReg(i+16);  -- ODDR's D2 port 
   end generate GEN_VEC;

end rtl;
