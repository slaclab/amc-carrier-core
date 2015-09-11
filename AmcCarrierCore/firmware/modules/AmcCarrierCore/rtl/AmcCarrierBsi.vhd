-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsi.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-08-03
-- Last update: 2015-09-11
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
use work.AmcCarrierPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierBsi is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- Local Configuration
      localMac        : out   slv(47 downto 0);
      localIp         : out   slv(31 downto 0);
      -- Application Interface
      bsiClk          : in    sl;
      bsiRst          : in    sl;
      bsiData         : out   BsiDataType;
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
      rdEn           : slv(1 downto 0);
      addr           : slv(7 downto 0);
      slotNumber     : slv(7 downto 0);
      crateId        : slv(15 downto 0);
      macAddress     : Slv48Array(15 downto 0);
      localIp        : slv(31 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      rdEn           => "11",
      addr           => x"00",
      slotNumber     => x"00",
      crateId        => x"0000",
      macAddress     => (others => (others => '0')),
      localIp        => x"0000000A",
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal i2cBramWr   : sl;
   signal i2cBramAddr : slv(7 downto 0);
   signal i2cBramDout : slv(7 downto 0);
   signal i2cBramDin  : slv(7 downto 0);
   signal bramDout    : slv(7 downto 0);
   signal ramData     : slv(7 downto 0);
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
         ADDR_SIZE_G          => 1,     -- in bytes
         DATA_SIZE_G          => 1,     -- in bytes
         ENDIANNESS_G         => 1)     -- 0=LE, 1=BE
      port map (
         clk    => axilClk,
         sRst   => axilRst,
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
         ADDR_WIDTH_G => 8)
      port map (
         -- Port A     
         clka  => axilClk,
         wea   => i2cBramWr,
         addra => i2cBramAddr,
         dina  => i2cBramDin,
         douta => i2cBramDout,
         -- Port B
         clkb  => axilClk,
         addrb => r.addr,
         doutb => ramData);   

   --------------------- 
   -- AXI Lite Interface
   --------------------- 
   comb : process (axilReadMaster, axilRst, axilWriteMaster, r, ramData) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
      variable i         : natural;
      variable index     : natural;

      -- Wrapper procedures to make calls cleaner.
      procedure axiSlaveRegisterW (addr : in slv; offset : in integer; reg : inout slv; cA : in boolean := false; cV : in slv := "0") is
      begin
         axiSlaveRegister(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, addr, offset, reg, cA, cV);
      end procedure;

      procedure axiSlaveRegisterR (addr : in slv; offset : in integer; reg : in slv) is
      begin
         axiSlaveRegister(axilReadMaster, v.axilReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterW (addr : in slv; offset : in integer; reg : inout sl) is
      begin
         axiSlaveRegister(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterR (addr : in slv; offset : in integer; reg : in sl) is
      begin
         axiSlaveRegister(axilReadMaster, v.axilReadSlave, axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveDefault (
         axiResp : in slv(1 downto 0)) is
      begin
         axiSlaveDefault(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus, axiResp);
      end procedure;

   begin
      -- Latch the current value
      v := r;

      -- Shift Register
      v.rdEn(0) := '0';
      v.rdEn(1) := r.rdEn(0);

      -- Update the index
      index := conv_integer(r.addr(7 downto 4));

      -- Check if read is completed
      if r.rdEn = "00" then
         -- Increment the counter
         v.addr := r.addr + 1;
         -- Set the flag
         v.rdEn := "11";
         -- Check for ATCA slot number
         if r.addr = x"FF" then
            v.slotNumber := ramData;
         -- Check for ATCA Crate ID (upper byte)
         elsif r.addr = x"FE" then
            v.crateId(15 downto 8) := ramData;
         -- Check for ATCA Crate ID (lower byte)
         elsif r.addr = x"FD" then
            v.crateId(7 downto 0) := ramData;
         else
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
      end if;

      -- Update the local IP addresses
      v.localIp(15 downto 8)  := r.crateId(15 downto 8);
      v.localIp(23 downto 16) := r.crateId(7 downto 0);
      v.localIp(31 downto 24) := (100 + r.slotNumber);

      -- Determine the transaction type
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus);

      -- Map the read registers
      for i in BSI_MAC_SIZE_C-1 downto 0 loop
         axiSlaveRegisterR(toSlv(8*i+0, 8), 0, r.macAddress(i)(47 downto 32));
         axiSlaveRegisterR(toSlv(8*i+4, 8), 0, r.macAddress(i)(31 downto 0));
      end loop;
      axiSlaveRegisterR(x"80", 0, r.crateId);
      axiSlaveRegisterR(x"84", 0, r.slotNumber);

      -- Set the Slave's response
      axiSlaveDefault(AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      localMac       <= ConvertEndianness(r.macAddress(0));
      localIp        <= r.localIp;
      
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
         dout   => bsiData.slotNumber); 

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
         dout   => bsiData.crateId);  

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
            dout   => bsiData.macAddress(i));     

   end generate GEN_VEC;
   
end rtl;
