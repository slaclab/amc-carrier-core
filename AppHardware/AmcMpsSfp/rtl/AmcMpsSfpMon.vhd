-------------------------------------------------------------------------------
-- File       : AmcMpsSfpMon.vhd
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMpsSfpMon is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- I2C Interface
      i2cScl          : inout sl;
      i2cSda          : inout sl;
      i2cRstL         : out   sl;
      i2cIntL         : in    sl;
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType);
end AmcMpsSfpMon;

architecture mapping of AmcMpsSfpMon is

begin

   i2cRstL <= not(axilRst);

   U_i2cScl : IOBUF
      port map (
         I  => '0',
         O  => open,
         IO => i2cScl,
         T  => '1');

   U_i2cSda : IOBUF
      port map (
         I  => '0',
         O  => open,
         IO => i2cSda,
         T  => '1');

   --------------------------------
   -- Placeholder for future module
   --------------------------------
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

end mapping;
