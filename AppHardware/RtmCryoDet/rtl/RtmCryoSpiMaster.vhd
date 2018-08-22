-------------------------------------------------------------------------------
-- File       : RtmCryoSpiMaster.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-07-27
-- Last update: 2018-07-27
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity RtmCryoSpiMaster is
   generic (
      TPD_G             : time := 1 ns;
      CPHA_G            : sl   := '0';
      CPOL_G            : sl   := '0';
      CLK_PERIOD_G      : real := 6.4E-9;
      SPI_SCLK_PERIOD_G : real := 100.0E-6);
   port (
      -- AXI-Lite Interface
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      -- SPI Interface
      coreSclk       : out sl;
      coreSDin       : in  sl;
      coreSDout      : out sl;
      coreCsb        : out sl);
end entity RtmCryoSpiMaster;

architecture rtl of RtmCryoSpiMaster is

   type StateType is (
      WAIT_AXI_TXN_S,
      WAIT_CYCLE_S,
      WAIT_SPI_TXN_DONE_S);

   type RegType is record
      wrEn          : sl;
      wrData        : slv(31 downto 0);
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      state         : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      wrEn          => '0',
      wrData        => (others => '0'),
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      state         => WAIT_AXI_TXN_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rdEn   : sl;
   signal rdData : slv(31 downto 0);

begin

   comb : process (axiReadMaster, axiRst, axiWriteMaster, r, rdData, rdEn) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- State Machine
      case (r.state) is
         -------------------------------------------------------------------------------
         when WAIT_AXI_TXN_S =>
            -- Check for write transaction
            if (axiStatus.writeEnable = '1') then
               -- Start the SPI transaction
               v.wrEn   := '1';
               v.wrData := axiWriteMaster.wdata;
               -- Closeout the transaction
               axiSlaveWriteResponse(v.axiWriteSlave);
               -- Next state
               v.state  := WAIT_CYCLE_S;
            end if;
            -- Check for read transaction
            if (axiStatus.readEnable = '1') then
               -- Return the SPI read data from the last transaction
               v.axiReadSlave.rdata := rdData;
               -- Closeout the transaction
               axiSlaveReadResponse(v.axiReadSlave);
            end if;
         -------------------------------------------------------------------------------
         when WAIT_CYCLE_S =>
            -- Wait for rdEn to drop
            if (rdEn = '0') then
               -- Reset the flag
               v.wrEn  := '0';
               -- Next state
               v.state := WAIT_SPI_TXN_DONE_S;
            end if;
         -------------------------------------------------------------------------------
         when WAIT_SPI_TXN_DONE_S =>
            -- Wait for rdEn to assert
            if (rdEn = '1') then
               -- Next state
               v.state := WAIT_AXI_TXN_S;
            end if;
      -------------------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axiWriteSlave <= r.axiWriteSlave;
      axiReadSlave  <= r.axiReadSlave;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_SpiMaster : entity work.SpiMaster
      generic map (
         TPD_G             => TPD_G,
         NUM_CHIPS_G       => 1,
         DATA_SIZE_G       => 32,
         CPHA_G            => CPHA_G,
         CPOL_G            => CPOL_G,
         CLK_PERIOD_G      => CLK_PERIOD_G,
         SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G)
      port map (
         clk       => axiClk,
         sRst      => axiRst,
         chipSel   => (others => '0'),
         wrEn      => r.wrEn,
         wrData    => r.wrData,
         rdEn      => rdEn,
         rdData    => rdData,
         spiCsL(0) => coreCsb,
         spiSclk   => coreSclk,
         spiSdi    => coreSDout,
         spiSdo    => coreSDin);

end architecture rtl;
