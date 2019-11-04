-------------------------------------------------------------------------------
-- File       : AmcMpsSfpHsRepeater.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-28
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
use surf.I2cPkg.all;

entity AmcMpsSfpHsRepeater is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- I2C Interface
      i2cScl          : inout slv(2 downto 0);
      i2cSda          : inout slv(2 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType);
end AmcMpsSfpHsRepeater;

architecture mapping of AmcMpsSfpHsRepeater is

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(2 downto 0) := genAxiLiteConfig(3, AXI_BASE_ADDR_G, 16, 12);

   constant I2C_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 0) := (
      0             => MakeI2cAxiLiteDevType(
         i2cAddress => "1011000",  -- AD[3:0] = 0x0 == Address Bytes = 0xB0 ('industrial standard')
         dataSize   => 8,
         addrSize   => 8,
         endianness => '1'));

   signal axilWriteMasters : AxiLiteWriteMasterArray(2 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(2 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(2 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(2 downto 0);

begin

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 3,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   GEN_VEC :
   for i in 2 downto 0 generate

      U_I2C : entity surf.AxiI2cRegMaster
         generic map (
            TPD_G          => TPD_G,
            I2C_SCL_FREQ_G => 100.0E+3,  -- units of Hz
            DEVICE_MAP_G   => I2C_DEVICE_MAP_C,
            AXI_CLK_FREQ_G => AXI_CLK_FREQ_G)
         port map (
            -- I2C Ports
            scl            => i2cScl(i),
            sda            => i2cSda(i),
            -- AXI-Lite Register Interface
            axiReadMaster  => axilReadMasters(i),
            axiReadSlave   => axilReadSlaves(i),
            axiWriteMaster => axilWriteMasters(i),
            axiWriteSlave  => axilWriteSlaves(i),
            -- Clocks and Resets
            axiClk         => axilClk,
            axiRst         => axilRst);

   end generate GEN_VEC;

end mapping;
