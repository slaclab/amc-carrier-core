-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:   
--    The acquisition is continuous. Conversion time is defined by N_SPI_CYCLES_G. 
--    The AXI lite reads Inputs using internal sequencer mode one at a time.
--    First two reads after power up are invalid. 
--    Reading/writing after conversion (RAC)
--    Default configuration is s_cfgReg[15:0] = 0xFFFC
--    
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

library unisim;
use unisim.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library amc_carrier_core; 

entity AxiSpiAd7682 is
   generic (
      TPD_G             : time     := 1 ns;
      DATA_SIZE_G       : natural  := 16;
      CLK_PERIOD_G      : real     := 6.4E-9;
      SPI_SCLK_PERIOD_G : real     := 100.0E-6;
      N_INPUTS_G        : positive := 4;  -- 4-AD7682, 8-AD7689
      N_SPI_CYCLES_G    : positive := 32  -- Number of SPI clock cycles between two acquisitions      
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
      coreCnv   : out sl
      );
end entity AxiSpiAd7682;

architecture rtl of AxiSpiAd7682 is

   -- Constants
   constant SPI_CLK_PERIOD_CYCLES_C : integer := integer((SPI_SCLK_PERIOD_G)/CLK_PERIOD_G);

   type StateType is (INIT_S, WAIT_CYCLE_S, WAIT_SPI_TXN_DONE_S, WAIT_N_SCK_S);

   -- Registers
   type RegType is record

      -- Inputs
      wrData    : slv(DATA_SIZE_G-1 downto 0);
      wrEn      : sl;
      inDataArr : slv16array(N_INPUTS_G-1 downto 0);
      writeCfg  : sl;
      perCnt    : integer range 0 to SPI_CLK_PERIOD_CYCLES_C;
      sckCnt    : integer range 0 to N_SPI_CYCLES_G;
      inDataCnt : integer range 0 to N_INPUTS_G;
      --      
      state     : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (

      -- Inputs
      wrData    => (others => '0'),
      wrEn      => '0',
      inDataArr => (others => (others => '0')),
      writeCfg  => '0',
      -- 
      perCnt    => 0,
      sckCnt    => 0,
      inDataCnt => 2,  -- To align data at powerup since first two acquisitions are invalid
      --
      state     => INIT_S
      );

   signal r        : RegType := REG_INIT_C;
   signal rin      : RegType;
   --
   signal s_rdData : slv(DATA_SIZE_G-1 downto 0);
   signal s_cfgReg : slv(DATA_SIZE_G-1 downto 0);

   signal s_rdEn : sl;
   signal s_we   : sl;

begin


   U_AxiSpiAd7682Reg : entity amc_carrier_core.AxiSpiAd7682Reg
      generic map (
         TPD_G             => TPD_G,
         AXIL_ADDR_WIDTH_G => 8,
         N_INPUTS_G        => N_INPUTS_G)
      port map (
         axiClk_i        => axiClk,
         axiRst_i        => axiRst,
         axilReadMaster  => axiReadMaster,
         axilReadSlave   => axiReadSlave,
         axilWriteMaster => axiWriteMaster,
         axilWriteSlave  => axiWriteSlave,
         cfgReg_o        => s_cfgReg,
         inDataArr_i     => r.inDataArr,
         we_o            => s_we);


   comb : process (axiRst, r, s_cfgReg, s_rdData, s_rdEn, s_we) is
      variable v : RegType;
   begin
      v := r;

      if (s_we = '1') then
         v.writeCfg := '1';
      end if;

      case (r.state) is
         when INIT_S =>
            v.perCnt := 0;
            v.sckCnt := 0;

            -- Write initiate SpiMaster write of s_cfgReg
            v.wrData := v.writeCfg & s_cfgReg(DATA_SIZE_G-2 downto 0);
            v.wrEn   := '1';
            v.state  := WAIT_CYCLE_S;

         when WAIT_CYCLE_S =>
            if (r.writeCfg = '1') then
               v.writeCfg  := '0';
               v.inDataCnt := 2;
            end if;
            -- Wait 1 cycle for rdEn to drop
            v.wrEn  := '0';
            v.state := WAIT_SPI_TXN_DONE_S;

         when WAIT_SPI_TXN_DONE_S =>

            if (s_rdEn = '1') then
               v.inDataArr(r.inDataCnt) := s_rdData;
               v.state                  := WAIT_N_SCK_S;
            end if;
         when WAIT_N_SCK_S =>
            v.perCnt := r.perCnt + 1;
            if (r.perCnt = SPI_CLK_PERIOD_CYCLES_C-1) then
               v.perCnt := 0;
               v.sckCnt := r.sckCnt + 1;
            elsif (r.sckCnt = N_SPI_CYCLES_G-1) then
               if (r.inDataCnt = N_INPUTS_G-1) then
                  v.inDataCnt := 0;
               else
                  v.inDataCnt := r.inDataCnt + 1;
               end if;

               v.state := INIT_S;
            end if;
         when others => null;
      end case;

      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   SpiMaster_1 : entity surf.SpiMaster
      generic map (
         TPD_G             => TPD_G,
         NUM_CHIPS_G       => 1,
         DATA_SIZE_G       => DATA_SIZE_G,
         CPHA_G            => '0',      -- Sample on leading edge
         CPOL_G            => '0',      -- Sample on rising edge
         CLK_PERIOD_G      => CLK_PERIOD_G,       -- 8.0E-9,
         SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G)  --ite(SIMULATION_G, 100.0E-9, 100.0E-6))
      port map (
         clk       => axiClk,
         sRst      => axiRst,
         chipSel   => "0",
         wrEn      => r.wrEn,
         wrData    => r.wrData,
         rdEn      => s_rdEn,
         rdData    => s_rdData,
         spiCsL(0) => coreCnv,
         spiSclk   => coreSclk,
         spiSdi    => coreSDout,
         spiSdo    => coreSDin);
end architecture rtl;
