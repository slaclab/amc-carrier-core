-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsi.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-08-03
-- Last update: 2015-08-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.i2cPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierBsi is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- I2C Ports
      scl            : inout sl;
      sda            : inout sl;
      -- AXI-Lite Register Interface
      axiReadMaster  : in    AxiLiteReadMasterType;
      axiReadSlave   : out   AxiLiteReadSlaveType;
      axiWriteMaster : in    AxiLiteWriteMasterType;
      axiWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl);  
end AmcCarrierBsi;

architecture mapping of AmcCarrierBsi is

   signal i2cBramWr   : sl;
   signal i2cBramAddr : slv(15 downto 0);
   signal i2cBramDout : slv(7 downto 0);
   signal i2cBramDin  : slv(7 downto 0);
   signal bramDout    : slv(7 downto 0);
   signal i2cIn       : i2c_in_type;
   signal i2cOut      : i2c_out_type;

begin

   ------------
   -- I2c Slave
   ------------
   U_i2cb : entity work.i2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => 73,    -- "1001001";
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => 4,
         ADDR_SIZE_G          => 2,     -- in bytes
         DATA_SIZE_G          => 1,     -- in bytes
         ENDIANNESS_G         => 0)     -- 0=LE, 1=BE
      port map (
         clk    => axiClk,
         sRst   => axiRst,
         aRst   => '0',
         addr   => i2cBramAddr,
         wrEn   => i2cBramWr,
         wrData => i2cBramDin,
         rdEn   => open,
         rdData => i2cBramDout,
         i2ci   => i2cIn,
         i2co   => i2cOut);

   U_I2cScl : IOBUF
      port map (
         IO => scl,
         I  => i2cOut.scl,
         O  => i2cIn.scl,
         T  => i2cOut.scloen);

   U_I2cSda : IOBUF
      port map (
         IO => sda,
         I  => i2cOut.sda,
         O  => i2cIn.sda,
         T  => i2cOut.sdaoen);

   ----------------
   -- Dual port ram
   ----------------   
   U_RAM : entity work.DualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => true,
         REG_EN_G     => true,
         MODE_G       => "read-first",
         DATA_WIDTH_G => 8,
         ADDR_WIDTH_G => 11,
         INIT_G       => "0")
      port map (
         -- Port A     
         clka  => axiClk,
         ena   => '1',
         wea   => i2cBramWr,
         rsta  => '0',
         addra => i2cBramAddr(10 downto 0),
         dina  => i2cBramDin,
         douta => bramDout,
         -- Port B
         clkb  => axiClk,
         enb   => '1',
         rstb  => '0',
         addrb => (others => '0'),
         doutb => open);   

   i2cBramDout <= bramDout when(i2cBramAddr(15 downto 11) = 0) else (others => '0');

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axiClk,
         axiClkRst      => axiRst,
         axiReadMaster  => axiReadMaster,
         axiReadSlave   => axiReadSlave,
         axiWriteMaster => axiWriteMaster,
         axiWriteSlave  => axiWriteSlave);   

end mapping;
