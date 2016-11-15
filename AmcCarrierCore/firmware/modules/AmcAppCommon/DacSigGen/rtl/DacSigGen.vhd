-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : DacSigGen.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-11-11
-- Last update: 2016-11-15
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BAM Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 BAM Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.jesd204bpkg.all;
use work.AppTopPkg.all;

entity DacSigGen is
   generic (
      TPD_G         : time                 := 1 ns;
      NUM_SIG_GEN_G : natural range 0 to 7 := 0);      
   port (
      -- DAC Signal Generator Interface
      jesdClk         : in  sl;
      jesdRst         : in  sl;
      dacSigCtrl      : in  DacSigCtrlType;
      dacSigStatus    : out DacSigStatusType;
      dacSigValids    : out slv(6 downto 0);
      dacSigValues    : out sampleDataArray(6 downto 0);
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end DacSigGen;

architecture mapping of DacSigGen is

begin

   dacSigStatus <= DAC_SIG_STATUS_INIT_C;
   dacSigValids <= (others => '0');
   dacSigValues <= (others => x"0000_0000");

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Bus
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);

end mapping;
