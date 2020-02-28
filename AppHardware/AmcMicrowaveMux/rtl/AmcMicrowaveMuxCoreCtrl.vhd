-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_30_CXX
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
use surf.jesd204bpkg.all;

entity AmcMicrowaveMuxCoreCtrl is
   generic (
      TPD_G : time := 1 ns);
   port (
      jesdClk         : in  sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- AMC Debug Signals
      rxSync          : in  sl;
      txSyncRaw       : in  slv(1 downto 0);
      txSync          : in  slv(1 downto 0);
      txSyncMask      : out slv(1 downto 0);
      -- DAC reset
      dacReset        : out slv(1 downto 0);
      dacJtagReset    : out sl;
      dacSpiMode      : out sl;
      -- LMK Sync
      lmkSync         : out sl);
end AmcMicrowaveMuxCoreCtrl;

architecture rtl of AmcMicrowaveMuxCoreCtrl is

   type RegType is record
      txSyncMask     : slv(1 downto 0);
      dacReset       : slv(1 downto 0);
      dacJtagReset   : sl;
      lmkSync        : sl;
      dacSpiMode     : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      txSyncMask     => (others => '0'),
      dacReset       => (others => '0'),
      dacJtagReset   => '0',
      lmkSync        => '0',
      dacSpiMode     => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rxSyncSync    : sl;
   signal txSyncSync    : slv(1 downto 0);
   signal txSyncRawSync : slv(1 downto 0);

begin

   Sync_rxSync : entity surf.Synchronizer
      generic map (
         TPD_G   => TPD_G)
      port map (
         clk     => axilClk,
         dataIn  => rxSync,
         dataOut => rxSyncSync);

   Sync_txSync : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk     => axilClk,
         dataIn  => txSync,
         dataOut => txSyncSync);

   Sync_txSyncRaw : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk     => axilClk,
         dataIn  => txSyncRaw,
         dataOut => txSyncRawSync);

   Sync_txSyncMask : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk     => jesdClk,
         dataIn  => r.txSyncMask,
         dataOut => txSyncMask);

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r, rxSyncSync, txSyncSync,
                   txSyncRawSync) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      axiSlaveRegisterR(regCon, x"7F0", 0, txSyncRawSync);
      axiSlaveRegisterR(regCon, x"7F4", 0, txSyncSync);
      axiSlaveRegisterR(regCon, x"7F8", 0, rxSyncSync);

      -- Map the read/write registers
      axiSlaveRegister(regCon, x"800", 0, v.txSyncMask);
      axiSlaveRegister(regCon, x"800", 2, v.dacReset);
      axiSlaveRegister(regCon, x"800", 4, v.dacJtagReset);
      axiSlaveRegister(regCon, x"800", 5, v.lmkSync);
      axiSlaveRegister(regCon, x"800", 6, v.dacSpiMode);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      dacReset       <= r.dacReset;
      dacJtagReset   <= r.dacJtagReset;
      lmkSync        <= r.lmkSync;
      dacSpiMode     <= r.dacSpiMode;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
