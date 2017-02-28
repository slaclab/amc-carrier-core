-------------------------------------------------------------------------------
-- File       : AmcMpsSfpHsRepeater.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-28
-- Last update: 2017-02-28
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMpsSfpHsRepeater is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- I2C Interface
      i2cScl  : inout slv(2 downto 0);
      i2cSda  : inout slv(2 downto 0);
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end AmcMpsSfpHsRepeater;

architecture mapping of AmcMpsSfpHsRepeater is

begin

   GEN_VEC :
   for i in 2 downto 0 generate

      U_i2cScl : IOBUF
         port map (
            I  => '0',
            O  => open,
            IO => i2cScl(i),
            T  => '1');
            
      U_i2cSda : IOBUF
         port map (
            I  => '0',
            O  => open,
            IO => i2cSda(i),
            T  => '1');         

   end generate GEN_VEC;         
         
   --------------------------------
   -- Placeholder for future module
   --------------------------------
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

end mapping;
