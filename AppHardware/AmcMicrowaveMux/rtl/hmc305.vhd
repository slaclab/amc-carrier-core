-------------------------------------------------------------------------------
-- File       : hmc305.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-05-26
-- Last update: 2018-07-24
-------------------------------------------------------------------------------
-- Description: SPI Master Wrapper for ADI HMC305 IC + 74HC238PWR MUX for LE
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

entity hmc305 is
   generic (
      TPD_G             : time := 1 ns;
      CLK_PERIOD_G      : real := (1.0/156.25E+6);
      SPI_SCLK_PERIOD_G : real := (1.0/1.0E+6));
   port (
      -- Clock and Reset
      axiClk         : in  sl;
      axiRst         : in  sl;
      -- AXI-Lite Interface
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;
      -- HMC305 Interface
      spiSck         : out sl;
      spiSdi         : out sl;
      devLe          : out sl;
      devAddr        : out slv(2 downto 0));
end entity hmc305;

architecture rtl of hmc305 is

   constant MAX_CNT_C : integer := integer(SPI_SCLK_PERIOD_G / CLK_PERIOD_G);

   type StateType is (
      IDLE_S,
      REQ_S,
      ACK_S,
      LE_HIGH_S,
      LE_LOW_S);

   type RegType is record
      cnt           : natural range 0 to MAX_CNT_C;
      data          : Slv5Array(2 downto 0);
      devAddr       : slv(2 downto 0);
      devLe         : sl;
      wrEn          : sl;
      wrData        : slv(4 downto 0);
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      state         : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cnt           => 0,
      data          => (others => (others => '0')),
      devAddr       => (others => '0'),
      devLe         => '0',
      wrEn          => '0',
      wrData        => (others => '0'),
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      state         => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rdEn      : sl;
   signal cacheData : slv(31 downto 0);

begin

   comb : process (axiReadMaster, axiRst, axiWriteMaster, r, rdEn) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
      variable wrAddr    : natural;
      variable rdAddr    : natural;
   begin
      -- Latch the current value
      v := r;

      -- Update the variables
      wrAddr := conv_integer(axiWriteMaster.awaddr(4 downto 2));
      rdAddr := conv_integer(axiReadMaster.araddr(4 downto 2));

      -- Check for AXI-Lite transaction
      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- Check for a read transaction
      if (axiStatus.readEnable = '1') then
         -- Read back the cache
         v.axiReadSlave.rdata(4 downto 0) := r.data(rdAddr);
         -- Send the response 
         axiSlaveReadResponse(v.axiReadSlave);
      end if;

      -- State Machine
      case (r.state) is
         ----------------------------------------------------------------------            
         when IDLE_S =>
            -- Check for a write transaction
            if (axiStatus.writeEnable = '1') then
               -- Latch the data
               v.data(wrAddr) := axiWriteMaster.wdata(4 downto 0);
               -- Start the SPI transaction
               v.wrEn         := '1';
               v.wrData       := bitReverse(not(axiWriteMaster.wdata(4 downto 0)));
               -- Setup the address bus
               v.devAddr      := axiWriteMaster.awaddr(4 downto 2);
               -- Send the write response
               axiSlaveWriteResponse(v.axiWriteSlave);
               -- Next state
               v.state        := REQ_S;
            end if;
         ----------------------------------------------------------------------            
         when REQ_S =>
            -- Wait for rdEn to drop
            if (rdEn = '0') then
               -- Reset the flag
               v.wrEn  := '0';
               -- Next state
               v.state := ACK_S;
            end if;
         ----------------------------------------------------------------------            
         when ACK_S =>
            -- Check for read completion 
            if (rdEn = '1') then
               -- Next state
               v.state := LE_HIGH_S;
            end if;
         ----------------------------------------------------------------------            
         when LE_HIGH_S =>
            -- Set the flag
            v.devLe := '1';
            -- Increment the counter
            if (r.cnt = MAX_CNT_C) then
               -- Reset the counter
               v.cnt   := 0;
               -- Next state
               v.state := LE_LOW_S;
            else
               v.cnt := r.cnt + 1;
            end if;
         ----------------------------------------------------------------------            
         when LE_LOW_S =>
            -- Set the flag
            v.devLe := '0';
            -- Increment the counter
            if (r.cnt = MAX_CNT_C) then
               -- Reset the counter
               v.cnt   := 0;
               -- Next state
               v.state := IDLE_S;
            else
               v.cnt := r.cnt + 1;
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
      devAddr       <= r.devAddr;
      devLe         <= r.devLe;

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
         DATA_SIZE_G       => 5,
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
         spiCsL(0) => open,
         spiSclk   => spiSck,
         spiSdi    => spiSdi,
         spiSdo    => '1');

end architecture rtl;
