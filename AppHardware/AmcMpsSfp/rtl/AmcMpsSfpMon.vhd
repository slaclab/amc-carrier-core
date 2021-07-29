-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.I2cPkg.all;
use surf.I2cMuxPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMpsSfpMon is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_CLK_FREQ_G  : real             := 156.25E+6;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- I2C Interface
      i2cScl          : inout sl;
      i2cSda          : inout sl;
      i2cRstL         : out   sl;
      i2cIntL         : in    sl;
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType);
end AmcMpsSfpMon;

architecture mapping of AmcMpsSfpMon is

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(7 downto 0) := genAxiLiteConfig(8, AXI_BASE_ADDR_G, 16, 12);

   constant SFF8472_I2C_CONFIG_C : I2cAxiLiteDevArray(1 downto 0) := (
      0              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1010000",      -- 2 wire address 1010000X (A0h)
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '0',            -- Little endian
         repeatStart => '1'),           -- No repeat start
      1              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1010001",      -- 2 wire address 1010001X (A2h)
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '0',            -- Little endian
         repeatStart => '1'));          -- Repeat Start

   signal axilReadMasters  : AxiLiteReadMasterArray(7 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(7 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(7 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(7 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal i2ci : i2c_in_type;
   signal i2coVec : i2c_out_array(8 downto 0) := (
      others    => (
         scl    => '1',
         scloen => '1',
         sda    => '1',
         sdaoen => '1',
         enable => '0'));
   signal i2co : i2c_out_type;

   signal readSlave  : AxiLiteReadSlaveType;
   signal writeSlave : AxiLiteWriteSlaveType;

begin

   i2cRstL <= not(axilRst);

   RESP_FILTER : process (readSlave, writeSlave) is
      variable tmpRd : AxiLiteReadSlaveType;
      variable tmpWr : AxiLiteWriteSlaveType;
   begin
      -- Init
      tmpRd := readSlave;
      tmpWr := writeSlave;

      -- Force OK bus response (in case unconnected SFP)
      tmpRd.rresp := AXI_RESP_OK_C;
      tmpWr.bresp := AXI_RESP_OK_C;

      -- Outputs
      axilReadSlave  <= tmpRd;
      axilWriteSlave <= tmpWr;
   end process;


   U_XbarI2cMux : entity surf.AxiLiteCrossbarI2cMux
      generic map (
         TPD_G              => TPD_G,
         -- I2C MUX Generics
         MUX_DECODE_MAP_G   => I2C_MUX_DECODE_MAP_PCA9547_C,
         I2C_MUX_ADDR_G     => b"1110_000",
         I2C_SCL_FREQ_G     => 400.0E+3,  -- units of Hz
         AXIL_CLK_FREQ_G    => AXI_CLK_FREQ_G,
         -- AXI-Lite Crossbar Generics
         NUM_MASTER_SLOTS_G => 8,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
      port map (
         -- Clocks and Resets
         axilClk           => axilClk,
         axilRst           => axilRst,
         -- Slave AXI-Lite Interface
         sAxilWriteMaster  => axilWriteMaster,
         sAxilWriteSlave   => writeSlave,
         sAxilReadMaster   => axilReadMaster,
         sAxilReadSlave    => readSlave,
         -- Master AXI-Lite Interfaces
         mAxilWriteMasters => axilWriteMasters,
         mAxilWriteSlaves  => axilWriteSlaves,
         mAxilReadMasters  => axilReadMasters,
         mAxilReadSlaves   => axilReadSlaves,
         -- I2C MUX Ports
         i2ci              => i2ci,
         i2co              => i2coVec(8));

   GEN_VEC : for i in 7 downto 0 generate
      U_SFP : entity surf.AxiI2cRegMasterCore
         generic map (
            TPD_G          => TPD_G,
            I2C_SCL_FREQ_G => 400.0E+3,  -- units of Hz
            DEVICE_MAP_G   => SFF8472_I2C_CONFIG_C,
            AXI_CLK_FREQ_G => AXI_CLK_FREQ_G)
         port map (
            -- I2C Ports
            i2ci           => i2ci,
            i2co           => i2coVec(i),
            -- AXI-Lite Register Interface
            axiReadMaster  => axilReadMasters(i),
            axiReadSlave   => axilReadSlaves(i),
            axiWriteMaster => axilWriteMasters(i),
            axiWriteSlave  => axilWriteSlaves(i),
            -- Clocks and Resets
            axiClk         => axilClk,
            axiRst         => axilRst);
   end generate GEN_VEC;

   process(axilReadMasters, axilWriteMasters, i2coVec)
      variable tmp : i2c_out_type;
   begin
      -- Init
      tmp := i2coVec(8);
      -- Check for TXN after XBAR/I2C_MUX
      for i in 0 to 7 loop
         if (axilWriteMasters(i).awvalid = '1') or (axilReadMasters(i).arvalid = '1') then
            tmp := i2coVec(i);
         end if;
      end loop;
      -- Return result
      i2co <= tmp;
   end process;

   IOBUF_SCL : IOBUF
      port map (
         O  => i2ci.scl,
         IO => i2cScl,
         I  => i2co.scl,
         T  => i2co.scloen);

   IOBUF_SDA : IOBUF
      port map (
         O  => i2ci.sda,
         IO => i2cSda,
         I  => i2co.sda,
         T  => i2co.sdaoen);

end mapping;
