-------------------------------------------------------------------------------
-- Title      : Axi Lite register access for simple SPI chips (write only data no address)
-------------------------------------------------------------------------------
-- File       : AxiSerAttnMaster.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
--            : Uros Legat Modified <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-12
-- Last update: 2015-11-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:   This module handles SPI chips with only one setting (non addressable or readable over SPI)
--                Write only access to SPI
--                AXI lite value can be read back but only locally (not accessing the SPI chip)
--
--                For multiple chips on single bus connect multiple cores
--                to multiple AXI crossbar slaves and use Chip select outputs
--                (coreCsb) to multiplex select the addressed outputs (coreSDout and
--                coreSclk).
--                The coreCsb is active low. And active only if the corresponding 
--                Axi Crossbar Slave is addressed.
--
--                Outputs a latch enable signal (For Attenuator chips) after the data is written
--                the latch enable stays high for one SPI_CLK_PERIOD_CYCLES_C.
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 LLRF Development'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 LLRF Development', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
--use work.I2cPkg.all;

entity AxiSerAttnMaster is
   generic (
      TPD_G             : time            := 1 ns;
      AXI_ERROR_RESP_G  : slv(1 downto 0) := AXI_RESP_DECERR_C;
      DATA_SIZE_G       : natural         := 6;
      CLK_PERIOD_G      : real            := 10.0E-6;
      SPI_SCLK_PERIOD_G : real            := 100.0E-6
      );
   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      coreSclk  : out sl;
      coreSDin  : in  sl;
      coreSDout : out sl;
      coreCsb   : out sl;
      coreLEn   : out sl
      );
end entity AxiSerAttnMaster;

architecture rtl of AxiSerAttnMaster is

   -- Constants
   constant SPI_CLK_PERIOD_CYCLES_C : integer := integer((SPI_SCLK_PERIOD_G * 20.0)/CLK_PERIOD_G);

   signal rdEn   : sl;

   type StateType is (WAIT_AXI_TXN_S, WAIT_CYCLE_S, WAIT_SPI_TXN_DONE_S, HOLD_LATCH_1SPICC_S);

   -- Registers
   type RegType is record
      state         : StateType;
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      
      -- Adc Core Inputs
      wrData        : slv(DATA_SIZE_G-1 downto 0);
      wrEn          : sl;
      
      -- Latch enable
      latchEn       : sl;
      perCnt        : integer range 0 to SPI_CLK_PERIOD_CYCLES_C+1;      
   end record RegType;

   constant REG_INIT_C : RegType := (
      state         => WAIT_AXI_TXN_S,
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      
      -- Adc Core Inputs
      wrData        => (others => '0'),
      wrEn          => '0',
      
      -- Latch enable
      latchEn       => '0',
      perCnt        => 0
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   
begin

   comb : process (axiReadMaster, axiRst, axiWriteMaster, r, rdEn) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      case (r.state) is
         when WAIT_AXI_TXN_S =>
            v.perCnt  := 0;
            v.latchEn := '0';

            if (axiStatus.readEnable = '1') then
               -- Just return previously written value
               v.axiReadSlave.rdata                         := (others => '0');
               v.axiReadSlave.rdata(DATA_SIZE_G-1 downto 0) := r.wrData;
               axiSlaveReadResponse(v.axiReadSlave);
               
               v.wrEn     := '0';
               v.state    := WAIT_AXI_TXN_S;
            end if;
            
            if (axiStatus.writeEnable = '1') then          
               -- Write data to Attn chip 
               v.wrData  := axiWriteMaster.wdata(DATA_SIZE_G-1 downto 0);
               v.wrEn    := '1';
               v.state   := WAIT_CYCLE_S;
            end if;

         when WAIT_CYCLE_S =>
            v.perCnt  := 0;
            v.latchEn := '0';
            
            -- Wait 1 cycle for rdEn to drop
            v.wrEn  := '0';
            v.state := WAIT_SPI_TXN_DONE_S;

         when WAIT_SPI_TXN_DONE_S =>
            v.perCnt := 0;
            
            if (rdEn = '1') then
               v.latchEn := '1';            
               v.state   := HOLD_LATCH_1SPICC_S;
            end if;
         when HOLD_LATCH_1SPICC_S =>
            v.latchEn := '1';
            v.perCnt  := r.perCnt + 1;
            if (r.perCnt >= SPI_CLK_PERIOD_CYCLES_C) then   
               v.state := WAIT_AXI_TXN_S;
               
               -- Finish write
               axiSlaveWriteResponse(v.axiWriteSlave);               
            end if;               
         when others => null;
      end case;

      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
      
      -- Outputs
      axiWriteSlave <= r.axiWriteSlave;
      axiReadSlave  <= r.axiReadSlave;
      coreLEn       <= r.latchEn;
      
   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   SpiMaster_1 : entity work.SpiMaster
      generic map (
         TPD_G             => TPD_G,
         NUM_CHIPS_G       => 1,
         DATA_SIZE_G       => DATA_SIZE_G,
         CPHA_G            => '0',                -- Sample on leading edge
         CPOL_G            => '0',                -- Sample on rising edge
         CLK_PERIOD_G      => CLK_PERIOD_G,       -- 8.0E-9,
         SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G)  --ite(SIMULATION_G, 100.0E-9, 100.0E-6))
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
         spiSdo    => coreSDin);
end architecture rtl;
