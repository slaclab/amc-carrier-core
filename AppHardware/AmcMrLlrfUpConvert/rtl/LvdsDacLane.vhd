-------------------------------------------------------------------------------
-- Title      : Single lane signal generator
-------------------------------------------------------------------------------
-- File       : LvdsDacLane.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-01-29
-- Last update: 2015-01-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Single lane arbitrary periodic signal generator
--               The module contains a AXI-Lite accessible block RAM where the 
--               signal is defined.
--               When the module is enabled it periodically reads the block RAM contents 
--               and outputs the contents.
--               The signal period is defined in user register.
--               Signal has to be disabled while the periodSize_i or RAM contents is being changed.
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

entity LvdsDacLane is
   generic (
      -- General Configurations
      TPD_G             : time                  := 1 ns;
      ADDR_WIDTH_G : integer range 1 to (2**24) := 12;
      DATA_WIDTH_G : integer range 1 to 32      := 16
   );
   port (
      -- AXI Clk
      axiClk_i : in sl;
      axiRst_i : in sl;
      
      -- devClk 2x - DAC sampling rate
      devClk2x_i          : in  sl;
      devRst2x_i          : in  sl;
      
      -- devClk - DAC sampling rate/2 (External data rate)
      devClk_i          : in  sl;
      devRst_i          : in  sl;
      
      -- External sample data input 
      -- 2 samples per c-c
      -- Should be little-endian none byte-swapped
      extData_i    : in  slv((2*DATA_WIDTH_G)-1 downto 0);
      overflow_o   : out sl;
      underflow_o  : out sl;
      
      -- Lane number AXI number to be inserted into AXI stream
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Control generation
      enable_i        : in  sl;
      periodSize_i    : in  slv(ADDR_WIDTH_G-1 downto 0);

      -- Parallel data out 
      sampleData_o    : out  slv(DATA_WIDTH_G-1 downto 0)
   );
end LvdsDacLane;

architecture rtl of LvdsDacLane is

   -- Register
   type RegType is record
      sampleData : slv(sampleData_o'range);
      cnt   : slv(ADDR_WIDTH_G-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      sampleData  => (others => '0'),
      cnt         => (others => '0')
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Signal generator
   signal s_rdEn : sl;
   signal s_ramData : slv(DATA_WIDTH_G-1 downto 0); 
   signal s_ramOut  : slv(31 downto 0);
   
   -- External data AxiStreamFifo
   signal s_extDataSync : slv(DATA_WIDTH_G-1 downto 0);
   --
   
begin
   
   s_rdEn <= enable_i;
   
   Jesd32bTo16b_INST: entity work.Jesd32bTo16b
   generic map (
      TPD_G => TPD_G)
   port map (
      wrClk    => devClk_i,
      wrRst    => devRst_i,
      validIn  => '1',
      overflow => overflow_o,
      underflow=> underflow_o,     
      dataIn   => extData_i,
      rdClk    => devClk2x_i,
      rdRst    => devRst2x_i,
      validOut => open,
      dataOut  => s_extDataSync);

   -- Dual port RAM accessible from axiLite
   -- This is where the signal period is defined in
   AxiDualPortRam_INST: entity work.AxiDualPortRam
   generic map (
      TPD_G        => TPD_G,
      BRAM_EN_G    => true,
      REG_EN_G     => true,
      MODE_G       => "write-first",
      ADDR_WIDTH_G => ADDR_WIDTH_G,
      DATA_WIDTH_G => 16,
      INIT_G       => "0")
   port map (
      -- Axi clk domain
      axiClk         => axiClk_i,
      axiRst         => axiRst_i,
      axiReadMaster  => axilReadMaster,
      axiReadSlave   => axilReadSlave,
      axiWriteMaster => axilWriteMaster,
      axiWriteSlave  => axilWriteSlave,

      -- Dev clk domain
      clk            => devClk2x_i,
      rst            => devRst2x_i,
      en             => s_rdEn,
      addr           => r.cnt,
      dout           => s_ramData);
       
   -- Address counter
   comb : process (r, devRst2x_i, periodSize_i, enable_i, s_extDataSync, s_ramData) is
      variable v : RegType;
   begin
      -- rateDiv clock generator 
      -- divClk is aligned to trig on rising edge of trig_i. 
      if (enable_i = '0' ) then
         v.cnt  := (others => '0');
      elsif (r.cnt = periodSize_i) then
         v.cnt  := (others => '0');
      else 
         v.cnt := r.cnt + 1;    
      end if;

      -- Register sample data before outputting
      -- If signal generator is disabled output external data
      if (enable_i = '0' ) then
         v.sampleData := s_extDataSync;
      else
         v.sampleData := s_ramData;
      end if;
      
      if (devRst2x_i = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
   end process comb;

   seq : process (devClk2x_i) is
   begin
      if (rising_edge(devClk2x_i)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
           
   sampleData_o <= r.sampleData;

end rtl;
