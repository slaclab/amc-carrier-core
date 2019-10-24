-------------------------------------------------------------------------------
-- File       : AppMsgIb.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-01
-- Last update: 2018-04-20
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.EthMacPkg.all;

entity AppMsgIb is
   generic (
      TPD_G              : time     := 1 ns;
      HDR_SIZE_G         : positive := 1;
      DATA_SIZE_G        : positive := 1;
      EN_CRC_G           : boolean  := true;
      BRAM_EN_G          : boolean  := true;
      AXIS_TDATA_WIDTH_G : positive := 16;  -- units of bytes
      FIFO_ADDR_WIDTH_G  : positive := 9);  -- units of bits
   port (
      -- Application Messaging Interface (clk domain)      
      clk         : in  sl;
      rst         : in  sl;
      strobe      : out sl;
      header      : out Slv32Array(HDR_SIZE_G-1 downto 0);
      timeStamp   : out slv(63 downto 0);
      data        : out Slv32Array(DATA_SIZE_G-1 downto 0);
      -- Backplane Messaging Interface  (axilClk domain)
      axilClk     : in  sl;
      axilRst     : in  sl;
      ibMsgMaster : in  AxiStreamMasterType;
      ibMsgSlave  : out AxiStreamSlaveType);
end AppMsgIb;

architecture rtl of AppMsgIb is

   constant SIZE_C             : positive            := (2+HDR_SIZE_G+DATA_SIZE_G);  -- 64-bit timestamp + header + data
   constant DATA_WIDTH_G       : positive            := (32*SIZE_C);  -- 32-bit words
   constant AXIS_CONFIG_C      : AxiStreamConfigType := ssiAxiStreamConfig(4, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8);
   constant SLAVE_AXI_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(AXIS_TDATA_WIDTH_G, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8);

   type TxType is record
      hdr : Slv32Array(HDR_SIZE_G-1 downto 0);
      ts  : slv(63 downto 0);
      msg : Slv32Array(DATA_SIZE_G-1 downto 0);
   end record TxType;
   constant TX_INIT_C : TxType := (
      hdr => (others => (others => '0')),
      ts  => (others => '0'),
      msg => (others => (others => '0')));

   function fromSlv (dout : slv(DATA_WIDTH_G-1 downto 0)) return TxType is
      variable retVar : TxType;
      variable i      : natural;
      variable idx    : natural;
   begin
      -- Reset the variables
      retVar := TX_INIT_C;
      idx    := 0;

      -- Load the header array
      for i in 0 to (HDR_SIZE_G-1) loop
         retVar.hdr(i) := dout((idx*32)+31 downto (idx*32));
         idx           := idx + 1;
      end loop;

      -- Load the 64-bit time stamp
      for i in 0 to 1 loop
         retVar.ts((i*32)+31 downto (i*32)) := dout((idx*32)+31 downto (idx*32));
         idx                                := idx + 1;
      end loop;

      -- Load the message array
      for i in 0 to (DATA_SIZE_G-1) loop
         retVar.msg(i) := dout((idx*32)+31 downto (idx*32));
         idx           := idx + 1;
      end loop;

      return retVar;
   end function;

   type StateType is (
      IDLE_S,
      DATA_S,
      CRC_S);

   type RegType is record
      cnt      : natural range 0 to SIZE_C;
      crcRst   : sl;
      crcValid : sl;
      crcData  : slv(31 downto 0);
      fifoWr   : sl;
      fifoData : slv(DATA_WIDTH_G-1 downto 0);
      rxSlave  : AxiStreamSlaveType;
      state    : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt      => 0,
      crcRst   => '1',
      crcValid => '0',
      crcData  => (others => '0'),
      fifoWr   => '0',
      fifoData => (others => '0'),
      rxSlave  => AXI_STREAM_SLAVE_INIT_C,
      state    => IDLE_S);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rxMaster : AxiStreamMasterType;
   signal rxSlave  : AxiStreamSlaveType;
   signal tx       : TxType;

   signal fifoData  : slv(DATA_WIDTH_G-1 downto 0);
   signal crcResult : slv(31 downto 0) := (others => '0');

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   

begin

   RX_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => BRAM_EN_G,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => FIFO_ADDR_WIDTH_G,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => SLAVE_AXI_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => ibMsgMaster,
         sAxisSlave  => ibMsgSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => rxMaster,
         mAxisSlave  => rxSlave);

   comb : process (axilRst, crcResult, r, rxMaster) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset the flags
      v.fifoWr   := '0';
      v.crcRst   := '0';
      v.crcValid := '0';
      v.rxSlave  := AXI_STREAM_SLAVE_INIT_C;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Reset the counter
            v.cnt := 0;
            -- Check for update
            if (rxMaster.tValid = '1') then
               if (ssiGetUserSof(AXIS_CONFIG_C, rxMaster) = '1') then
                  -- Next state
                  v.state := DATA_S;
               else
                  -- Blowoff the data
                  v.rxSlave.tReady := '1';
               end if;
            end if;
         ----------------------------------------------------------------------
         when DATA_S =>
            -- Check if ready to move data
            if (rxMaster.tValid = '1') then
               -- Accept the data
               v.rxSlave.tReady                            := '1';
               v.fifoData((32*r.cnt)+31 downto (32*r.cnt)) := rxMaster.tData(31 downto 0);
               -- Update the CRC engine
               v.crcValid                                  := '1';
               v.crcData                                   := rxMaster.tData(31 downto 0);
               -- Increment the counter
               v.cnt                                       := r.cnt + 1;
               -- Check if CRC is enabled
               if (EN_CRC_G = true) then
                  -- Check for last FIFO word
                  if (r.cnt = (SIZE_C-1)) then
                     -- Reset the counter
                     v.cnt   := 0;
                     -- Next state
                     v.state := CRC_S;
                  end if;
                  -- Check for framing error
                  if (rxMaster.tLast = '1') then
                     -- Reset the CRC engine
                     v.crcRst := '1';
                     -- Next state
                     v.state  := IDLE_S;
                  end if;
               else
                  -- Check for EOF or aligned
                  if (rxMaster.tLast = '1') or (r.cnt = (SIZE_C-1)) then
                     -- Check for no EOFE and aligned and EOF
                     if (ssiGetUserEofe(AXIS_CONFIG_C, rxMaster) = '0')
                        and (r.cnt = (SIZE_C-1))
                        and (rxMaster.tLast = '1') then
                        v.fifoWr := '1';
                     end if;
                     -- Next state
                     v.state := IDLE_S;
                  end if;
               end if;
            end if;
         ----------------------------------------------------------------------
         when CRC_S =>
            -- Increment the counter
            if (r.cnt /= 3) then
               v.cnt := r.cnt + 1;
            end if;
            -- Check if ready to move data
            if (rxMaster.tValid = '1') and (r.cnt = 3) then
               -- Accept the data
               v.rxSlave.tReady := '1';
               -- Check for no EOFE and CRC match and EOF
               if (ssiGetUserEofe(AXIS_CONFIG_C, rxMaster) = '0')
                  and (rxMaster.tData(31 downto 0) = crcResult)
                  and (rxMaster.tLast = '1') then
                  v.fifoWr := '1';
               end if;
               -- Reset the CRC engine
               v.crcRst := '1';
               -- Next state
               v.state  := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Combinatorial outputs before the reset   
      rxSlave <= v.rxSlave;

      -- Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (axilClk) is
   begin
      if rising_edge(axilClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   GEN_CRC : if (EN_CRC_G = true) generate
      U_Crc32 : entity surf.Crc32Parallel
         generic map (
            TPD_G        => TPD_G,
            BYTE_WIDTH_G => 4)
         port map (
            crcClk       => axilClk,
            crcReset     => r.crcRst,
            crcDataWidth => "011",      -- 4 bytes 
            crcDataValid => r.crcValid,
            crcIn        => r.crcData,
            crcOut       => crcResult);
   end generate;

   TX_FIFO : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => DATA_WIDTH_G)
      port map (
         rst    => axilRst,
         -- Write Ports
         wr_clk => axilClk,
         wr_en  => r.fifoWr,
         din    => r.fifoData,
         -- Read Ports
         rd_clk => clk,
         valid  => strobe,
         dout   => fifoData);

   tx        <= fromSlv(fifoData);
   header    <= tx.hdr;
   timeStamp <= tx.ts;
   data      <= tx.msg;

end rtl;
