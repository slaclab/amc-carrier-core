-------------------------------------------------------------------------------
-- File       : RtmCryoDetReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-11-03
-- Last update: 2017-11-06
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_13_CXX
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

entity RtmCryoDetReg is
   generic (
      TPD_G            : time            := 1 ns;
      CNT_WIDTH_G      : positive        := 8;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      jesdClk         : in  sl;
      jesdRst         : in  sl;
      jesdClkDiv      : out sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end RtmCryoDetReg;

architecture rtl of RtmCryoDetReg is

   type RegType is record
      lowCycle       : slv(CNT_WIDTH_G-1 downto 0);
      highCycle      : slv(CNT_WIDTH_G-1 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      lowCycle       => toSlv(2, CNT_WIDTH_G),  -- 3 cycles low by default (zero inclusive)
      highCycle      => toSlv(2, CNT_WIDTH_G),  -- 3 cycles low by default (zero inclusive)
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal lowCycle  : slv(CNT_WIDTH_G-1 downto 0);
   signal highCycle : slv(CNT_WIDTH_G-1 downto 0);

begin

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      axiSlaveRegister(regCon, x"0", 0, v.lowCycle);
      axiSlaveRegister(regCon, x"4", 0, v.highCycle);
      axiSlaveRegisterR(regCon, x"8", 0, toSlv(CNT_WIDTH_G, 32));

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   Sync_lowCycle : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => CNT_WIDTH_G)
      port map (
         clk     => jesdClk,
         dataIn  => r.lowCycle,
         dataOut => lowCycle);

   Sync_highCycle : entity work.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => CNT_WIDTH_G)
      port map (
         clk     => jesdClk,
         dataIn  => r.highCycle,
         dataOut => highCycle);

   U_ClkDiv : entity work.RtmCryoDetClkDiv
      generic map (
         TPD_G       => TPD_G,
         CNT_WIDTH_G => CNT_WIDTH_G)
      port map (
         jesdClk    => jesdClk,
         jesdRst    => jesdRst,
         jesdClkDiv => jesdClkDiv,
         lowCycle   => lowCycle,
         highCycle  => highCycle);

end rtl;
