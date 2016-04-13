-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsi.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-08-03
-- Last update: 2016-04-13
-- Platform   : 
-- Standard   : VHDL'93/02
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
use work.i2cPkg.all;
use work.AmcCarrierPkg.all;
use work.Version.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierBsi is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- DDR Memory Status
      ddrMemReady     : in    sl;
      ddrMemError     : in    sl;
      -- Local Configuration
      localMac        : out   slv(47 downto 0);
      localIp         : out   slv(31 downto 0);
      localAppId      : out   slv(15 downto 0);
      bootReq         : out   sl;
      bootAddr        : out   slv(31 downto 0);
      upTimeCnt       : in    slv(31 downto 0);
      -- Application Interface
      bsiClk          : in    sl;
      bsiRst          : in    sl;
      bsiBus          : out   BsiBusType;
      -- I2C Ports
      scl             : inout sl;
      sda             : inout sl;
      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Clocks and Resets
      axilClk         : in    sl;
      axilRst         : in    sl);  
end AmcCarrierBsi;

architecture rtl of AmcCarrierBsi is

   constant BSI_MAJOR_VERSION_C : slv(7 downto 0) := x"01";
   constant BSI_MINOR_VERSION_C : slv(7 downto 0) := x"01";

   type RomType is array (0 to 255) of slv(7 downto 0);

   function makeStringRom return RomType is
      variable ret : RomType := (others => (others => '0'));
      variable c   : character;
   begin
      for i in BUILD_STAMP_C'range loop
         c      := BUILD_STAMP_C(i);
         ret(i) := toSlv(character'pos(c), 8);
      end loop;
      return ret;
   end function makeStringRom;

   signal stringRom : RomType := makeStringRom;

   function ConvertEndianness (word : slv(47 downto 0)) return slv is
      variable retVar : slv(47 downto 0);
   begin
      retVar(47 downto 40) := word(7 downto 0);
      retVar(39 downto 32) := word(15 downto 8);
      retVar(31 downto 24) := word(23 downto 16);
      retVar(23 downto 16) := word(31 downto 24);
      retVar(15 downto 8)  := word(39 downto 32);
      retVar(7 downto 0)   := word(47 downto 40);
      return retVar;
   end function;

   type RegType is record
      cnt            : slv(3 downto 0);
      addr           : slv(7 downto 0);
      we             : sl;
      ramData        : slv(7 downto 0);
      bootReq        : sl;
      bootAddr       : slv(31 downto 0);
      slotNumber     : slv(7 downto 0);
      crateId        : slv(15 downto 0);
      macAddress     : Slv48Array(BSI_MAC_SIZE_C-1 downto 0);
      localIp        : slv(31 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      cnt            => x"0",
      addr           => x"00",
      we             => '0',
      ramData        => x"00",
      bootReq        => '0',
      bootAddr       => x"00000000",
      slotNumber     => x"00",
      crateId        => x"0000",
      macAddress     => (others => (others => '0')),
      localIp        => x"0000000A",
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal i2cBramWr   : slv(1 downto 0);
   signal i2cBramAddr : Slv8Array(1 downto 0);
   signal i2cBramDout : Slv8Array(1 downto 0);
   signal i2cBramDin  : Slv8Array(1 downto 0);
   signal bramDout    : slv(7 downto 0);
   signal ramData     : slv(7 downto 0);
   signal slaveIn     : i2c_in_array(1 downto 0);
   signal slaveOut    : i2c_out_array(1 downto 0);
   signal i2cIn       : i2c_in_type;
   signal i2cOut      : i2c_out_type;

begin

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

   -------------------------
   -- MUX I2C Slave together
   -------------------------
   slaveIn(0).scl <= i2cIn.scl;
   slaveIn(1).scl <= i2cIn.scl;
   slaveIn(0).sda <= i2cIn.sda;
   slaveIn(1).sda <= i2cIn.sda;

   i2cOut.scl    <= '0';
   i2cOut.scloen <= slaveOut(0).scloen and slaveOut(1).scloen;
   i2cOut.sda    <= '0';
   i2cOut.sdaoen <= slaveOut(0).sdaoen and slaveOut(1).sdaoen;

   -------------------
   -- I2c Slave @ 0x49
   -------------------
   U_I2C_SLAVE_0x49 : entity work.i2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => 73,    -- "1001001";
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => 4,
         ADDR_SIZE_G          => 1,     -- in bytes
         DATA_SIZE_G          => 1,     -- in bytes
         ENDIANNESS_G         => 1)     -- 0=LE, 1=BE
      port map (
         clk    => axilClk,
         sRst   => axilRst,
         aRst   => '0',
         addr   => i2cBramAddr(0),
         wrEn   => i2cBramWr(0),
         wrData => i2cBramDin(0),
         rdEn   => open,
         rdData => i2cBramDout(0),
         i2ci   => slaveIn(0),
         i2co   => slaveOut(0)); 

   -------------------
   -- I2c Slave @ 0x51
   -------------------
   U_I2C_SLAVE_0x51 : entity work.i2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => 81,    -- "1010001";
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => 4,
         ADDR_SIZE_G          => 1,     -- in bytes
         DATA_SIZE_G          => 1,     -- in bytes
         ENDIANNESS_G         => 1)     -- 0=LE, 1=BE
      port map (
         clk    => axilClk,
         sRst   => axilRst,
         aRst   => '0',
         addr   => i2cBramAddr(1),
         wrEn   => i2cBramWr(1),
         wrData => i2cBramDin(1),
         rdEn   => open,
         rdData => i2cBramDout(1),
         i2ci   => slaveIn(1),
         i2co   => slaveOut(1));          

   ----------------
   -- Dual port RAM
   ----------------   
   U_RAM : entity work.TrueDualPortRam
      generic map (
         TPD_G        => TPD_G,
         MODE_G       => "read-first",
         DATA_WIDTH_G => 8,
         ADDR_WIDTH_G => 8)
      port map (
         -- Port A     
         clka  => axilClk,
         wea   => i2cBramWr(0),
         addra => i2cBramAddr(0),
         dina  => i2cBramDin(0),
         douta => i2cBramDout(0),
         -- Port B
         clkb  => axilClk,
         web   => r.we,
         addrb => r.addr,
         dinb  => r.ramData,
         doutb => ramData);   

   ------------------
   -- Single port ROM
   ------------------ 
   process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         i2cBramDout(1) <= stringRom(conv_integer(i2cBramAddr(1))) after TPD_G;
      end if;
   end process;

   --------------------- 
   -- AXI Lite Interface
   --------------------- 
   comb : process (axilReadMaster, axilRst, axilWriteMaster, ddrMemError, ddrMemReady, r, ramData,
                   upTimeCnt) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
      variable i      : natural;
      variable index  : natural;
   begin
      -- Latch the current value
      v := r;

      -- Reset the strobe
      v.we := '0';

      -- Increment the counter
      v.cnt := r.cnt + 1;

      -- Update the index
      index := conv_integer(r.addr(7 downto 4));

      -- Check counter phase
      if r.cnt = x"0" then
         -- Increment the address
         v.addr := r.addr + 1;
      elsif r.cnt = x"8" then
         -- Reset the data bus
         v.ramData := x"00";
         -- Check the address bus
         case (r.addr) is
            ---------------------------------------
            -- Check for ATCA slot number
            ---------------------------------------
            when x"FF" => v.slotNumber           := ramData;
            ---------------------------------------
            -- Check for ATCA Crate ID
            ---------------------------------------
            when x"FE" => v.crateId(15 downto 8) := ramData;
            when x"FD" => v.crateId(7 downto 0)  := ramData;
            ---------------------------------------
            -- Check for BSI Version
            ---------------------------------------
            when x"FC" =>
               v.we      := '1';
               v.ramData := BSI_MINOR_VERSION_C;
            when x"FB" =>
               v.we      := '1';
               v.ramData := BSI_MAJOR_VERSION_C;
            ---------------------------------------
            -- Check for start boot
            ---------------------------------------
            when x"FA" =>
               -- Sample the LSB of the memory byte
               v.bootReq := ramData(0);
               -- Reset memory
               v.we      := '1';
               v.ramData := x"00";
            ---------------------------------------
            -- Check for boot address
            ---------------------------------------
            when x"F9" => v.bootAddr(31 downto 24) := ramData;
            when x"F8" => v.bootAddr(23 downto 16) := ramData;
            when x"F7" => v.bootAddr(15 downto 8)  := ramData;
            when x"F6" => v.bootAddr(7 downto 0)   := ramData;
            ---------------------------------------
            -- Check for FPGA_VERSION_C
            ---------------------------------------            
            when x"F5" =>
               v.we      := '1';
               v.ramData := FPGA_VERSION_C(31 downto 24);
            when x"F4" =>
               v.we      := '1';
               v.ramData := FPGA_VERSION_C(23 downto 16);
            when x"F3" =>
               v.we      := '1';
               v.ramData := FPGA_VERSION_C(15 downto 8);
            when x"F2" =>
               v.we      := '1';
               v.ramData := FPGA_VERSION_C(7 downto 0);
            ---------------------------------------
            -- Check for DDR Memory Status
            ---------------------------------------               
            when x"F1" =>
               v.we         := '1';
               v.ramData(0) := ddrMemError;
            when x"F0" =>
               v.we         := '1';
               v.ramData(0) := ddrMemReady;
            ----------------------------------------
            -- Check for AxiVersion's Uptime Counter
            ----------------------------------------            
            when x"EF" =>
               v.we      := '1';
               v.ramData := upTimeCnt(31 downto 24);
            when x"EE" =>
               v.we      := '1';
               v.ramData := upTimeCnt(23 downto 16);
            when x"ED" =>
               v.we      := '1';
               v.ramData := upTimeCnt(15 downto 8);
            when x"EC" =>
               v.we      := '1';
               v.ramData := upTimeCnt(7 downto 0);
            ---------------------------------------
            when others =>
               if (index < BSI_MAC_SIZE_C) then
                  -- Check for available MAC addresses
                  case (r.addr(3 downto 0)) is
                     when x"0"   => v.macAddress(index)(7 downto 0)   := ramData;
                     when x"1"   => v.macAddress(index)(15 downto 8)  := ramData;
                     when x"2"   => v.macAddress(index)(23 downto 16) := ramData;
                     when x"3"   => v.macAddress(index)(31 downto 24) := ramData;
                     when x"4"   => v.macAddress(index)(39 downto 32) := ramData;
                     when x"5"   => v.macAddress(index)(47 downto 40) := ramData;
                     when others => null;
                  end case;
               end if;
         end case;
      end if;

      -- Update the local IP addresses
      v.localIp(15 downto 8)  := r.crateId(15 downto 8);
      v.localIp(23 downto 16) := r.crateId(7 downto 0);
      v.localIp(31 downto 24) := (100 + r.slotNumber);

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in BSI_MAC_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(regCon, toSlv(8*i+0, 8), 0, r.macAddress(i)(31 downto 0));
         axiSlaveRegisterR(regCon, toSlv(8*i+4, 8), 0, r.macAddress(i)(47 downto 32));
         axiSlaveRegisterR(regCon, toSlv(8*i+4, 8), 16, x"0000");
      end loop;
      axiSlaveRegisterR(regCon, x"80", 0, r.crateId);
      axiSlaveRegisterR(regCon, x"84", 0, r.slotNumber);
      axiSlaveRegisterR(regCon, x"88", 0, r.bootAddr);
      axiSlaveRegisterR(regCon, x"8C", 0, BSI_MINOR_VERSION_C);
      axiSlaveRegisterR(regCon, x"90", 8, BSI_MAJOR_VERSION_C);

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
      bootReq        <= r.bootReq;
      bootAddr       <= r.bootAddr;

      localAppId(3 downto 0)  <= r.slotNumber(3 downto 0);
      localAppId(15 downto 4) <= r.crateId(15 downto 4);

      localMac <= ConvertEndianness(r.macAddress(0));
      localIp  <= r.localIp;
      
   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   Sync_slotNumber : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 8)
      port map (
         -- Write Ports (wr_clk domain)
         wr_clk => axilClk,
         din    => r.slotNumber,
         -- Read Ports (rd_clk domain)
         rd_clk => bsiClk,
         dout   => bsiBus.slotNumber); 

   Sync_crateId : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 16)
      port map (
         -- Write Ports (wr_clk domain)
         wr_clk => axilClk,
         din    => r.crateId,
         -- Read Ports (rd_clk domain)
         rd_clk => bsiClk,
         dout   => bsiBus.crateId);  

   GEN_VEC :
   for i in BSI_MAC_SIZE_C-1 downto 1 generate
      
      Sync_macAddress : entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => 48)
         port map (
            -- Write Ports (wr_clk domain)
            wr_clk => axilClk,
            din    => ConvertEndianness(r.macAddress(i)),
            -- Read Ports (rd_clk domain)
            rd_clk => bsiClk,
            dout   => bsiBus.macAddress(i));     

   end generate GEN_VEC;
   
end rtl;
