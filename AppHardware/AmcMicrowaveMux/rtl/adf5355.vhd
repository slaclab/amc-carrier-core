-------------------------------------------------------------------------------
-- File       : adf5355.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-05-26
-- Last update: 2017-10-03
-------------------------------------------------------------------------------
-- Description: SPI Master Wrapper for ADI ADF5355 IC
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity adf5355 is
   generic (
      TPD_G             : time            := 1 ns;
      AXI_ERROR_RESP_G  : slv(1 downto 0) := AXI_RESP_DECERR_C;
      CLK_PERIOD_G      : real            := (1.0/156.25E+6);
      SPI_SCLK_PERIOD_G : real            := (1.0/10.0E+6));
   port (
      -- Clock and Reset
      axiClk         : in  sl;
      axiRst         : in  sl;
      -- AXI-Lite Interface
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      -- Multiple Chip Support
      busyIn         : in  sl;
      busyOut        : out sl;
      -- SPI Interface
      coreSclk       : out sl;
      coreSDout      : out sl;
      coreCsb        : out sl);
end entity adf5355;

architecture rtl of adf5355 is

   type StateType is (
      WAIT_AXI_TXN_S,
      RD_RESP_S,
      WAIT_CYCLE_S,
      WAIT_SPI_TXN_DONE_S);

   type RegType is record
      busyOut       : sl;
      cacheWr       : sl;
      wrEn          : sl;
      wrData        : slv(31 downto 0);
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      state         : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      busyOut       => '0',
      cacheWr       => '0',
      wrEn          => '0',
      wrData        => (others => '0'),
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      state         => WAIT_AXI_TXN_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rdEn      : sl;
   signal cacheData : slv(31 downto 0);

begin

   comb : process (axiReadMaster, axiRst, axiWriteMaster, busyIn, cacheData, r,
                   rdEn) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.cacheWr := '0';

      -- Check for AXI-Lite transaction
      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------            
         when WAIT_AXI_TXN_S =>
            -- Reset the flag
            v.busyOut := '0';
            -- Check for a write transaction and SPI bus not busy
            if (axiStatus.writeEnable = '1') and (busyIn = '0') then
               -- Decode the data/address bus
               v.wrData(3 downto 0)  := axiWriteMaster.awaddr(5 downto 2);  -- control bits
               v.wrData(31 downto 4) := axiWriteMaster.wdata(31 downto 4);  -- data bits
               -- Set the flags
               v.wrEn                := '1';
               v.cacheWr             := '1';
               v.busyOut             := '1';
               -- Send the write response
               axiSlaveWriteResponse(v.axiWriteSlave);
               -- Next state
               v.state               := WAIT_CYCLE_S;
            end if;
            -- Check for a read transaction
            if (axiStatus.readEnable = '1') then
               -- Next state
               v.state := RD_RESP_S;
            end if;
         ----------------------------------------------------------------------            
         when RD_RESP_S =>
            -- Reade the bit
            v.axiReadSlave.rdata := cacheData;
            -- Send the response 
            axiSlaveReadResponse(v.axiReadSlave);
            -- Next state
            v.state              := WAIT_AXI_TXN_S;
         ----------------------------------------------------------------------            
         when WAIT_CYCLE_S =>
            -- Wait for rdEn to drop
            if (rdEn = '0') then
               -- Reset the flag
               v.wrEn  := '0';
               -- Next state
               v.state := WAIT_SPI_TXN_DONE_S;
            end if;
         ----------------------------------------------------------------------            
         when WAIT_SPI_TXN_DONE_S =>
            -- Check for read completion 
            if (rdEn = '1') then
               -- Next state
               v.state := WAIT_AXI_TXN_S;
            end if;
      ----------------------------------------------------------------------            
      end case;

      -- Reset      
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle      
      rin <= v;

      -- Outputs            
      axiWriteSlave <= r.axiWriteSlave;
      axiReadSlave  <= r.axiReadSlave;
      busyOut       <= r.busyOut;

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
         CPHA_G            => '0',
         CPOL_G            => '0',
         CLK_PERIOD_G      => CLK_PERIOD_G,
         SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G)
      port map (
         clk       => axiClk,
         sRst      => axiRst,
         chipSel   => "0",
         wrEn      => r.wrEn,
         wrData    => r.wrData,
         rdEn      => rdEn,
         rdData    => open,
         spiCsL(0) => coreCsb,
         spiSclk   => coreSclk,
         spiSdi    => coreSDout,
         spiSdo    => '1');

   U_Cache : entity work.SimpleDualPortRam
      generic map(
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         DOB_REG_G    => false,
         DATA_WIDTH_G => 28,
         ADDR_WIDTH_G => 4)
      port map (
         -- Port A
         clka  => axiClk,
         wea   => r.cacheWr,
         addra => r.wrData(3 downto 0),
         dina  => r.wrData(31 downto 4),
         -- Port B
         clkb  => axiClk,
         addrb => axiReadMaster.araddr(5 downto 2),
         doutb => cacheData(31 downto 4));

   cacheData(3 downto 0) <= axiReadMaster.araddr(5 downto 2);

end architecture rtl;
