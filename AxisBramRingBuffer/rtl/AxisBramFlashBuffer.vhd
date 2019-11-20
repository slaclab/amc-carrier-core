-------------------------------------------------------------------------------
-- File       : AxisBramFlashBuffer.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-04-10
-- Last update: 2019-11-20
-------------------------------------------------------------------------------
-- Data Format:
--    DATA[0].BIT[7:0]    = protocol version (0x0)
--    DATA[0].BIT[15:8]   = channel index
--    DATA[0].BIT[63:16]  = event id
--    DATA[0].BIT[127:64] = timestamp
--    DATA[1] = BRAM[3] & BRAM[2] & BRAM[1] & BRAM[0];
--    DATA[2] = BRAM[7] & BRAM[6] & BRAM[5] & BRAM[4];
--    ................................................
--    ................................................
--    ................................................
--    DATA[1+N/4] = BRAM[N-1] & BRAM[N-2] & BRAM[N-3] & BRAM[N-4];
--
--       where N = 2**BUFFER_WIDTH_G
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library amc_carrier_core;

entity AxisBramFlashBuffer is
   generic (
      TPD_G              : time     := 1 ns;
      NUM_CH_G           : positive := 1;
      AXIS_TDATA_WIDTH_G : positive := 8;   -- units of bytes            
      BUFFER_WIDTH_G     : positive := 8);  -- DEPTH_G = 2**WIDTH_G
   port (
      -- Input Data Interface (appClk domain)
      appClk          : in  sl;
      appRst          : in  sl;
      apptrig         : in  sl;
      appValid        : in  slv(NUM_CH_G-1 downto 0);
      appData         : in  Slv32Array(NUM_CH_G-1 downto 0);
      -- Input timing interface (timingClk domain)
      timingClk       : in  sl;
      timingRst       : in  sl;
      timingTimestamp : in  slv(63 downto 0);
      -- Output AXIS Interface (axisClk domain)
      axisClk         : in  sl;
      axisRst         : in  sl;
      axisMaster      : out AxiStreamMasterType;
      axisSlave       : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end AxisBramFlashBuffer;

architecture mapping of AxisBramFlashBuffer is

   type RegType is record
      enable         : sl;
      swTrig         : sl;
      tDest          : Slv8Array(NUM_CH_G-1 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      enable         => '0',
      swTrig         => '0',
      tDest          => (others => x"FF"),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal wrEn   : sl;
   signal wrAddr : slv(BUFFER_WIDTH_G-1 downto 0);
   signal rdAddr : slv(BUFFER_WIDTH_G-1 downto 0);
   signal wrData : Slv32Array(NUM_CH_G-1 downto 0);
   signal rdData : Slv32Array(NUM_CH_G-1 downto 0);

   signal req       : sl;
   signal ack       : sl;
   signal valid     : slv(NUM_CH_G-1 downto 0);
   signal timestamp : slv(63 downto 0);

begin

   assert (BUFFER_WIDTH_G >= 8) report "BUFFER_WIDTH_G must be >= 8" severity failure;

   -----------------
   -- BRAM Write FSM
   -----------------
   U_WriteFsm : entity amc_carrier_core.AxisBramFlashBufferWrFsm
      generic map (
         TPD_G          => TPD_G,
         NUM_CH_G       => NUM_CH_G,
         BUFFER_WIDTH_G => BUFFER_WIDTH_G)
      port map (
         -- Input Data Interface (appClk domain)
         appClk          => appClk,
         appRst          => appRst,
         apptrig         => apptrig,
         appValid        => appValid,
         appData         => appData,
         -- Input timing interface (timingClk domain)
         timingClk       => timingClk,
         timingRst       => timingRst,
         timingTimestamp => timingTimestamp,
         -- Ram Interface (appClk domain)
         wrEn            => wrEn,
         wrAddr          => wrAddr,
         wrData          => wrData,
         -- Software Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         enable          => r.enable,
         swtrig          => r.swtrig,
         -- Read FSM Interface (axisClk domain)
         axisClk         => axisClk,
         axisRst         => axisRst,
         req             => req,
         valid           => valid,
         timestamp       => timestamp,
         ack             => ack);

   ---------------
   -- BRAM Buffers
   ---------------
   GEN_BRAM : for i in NUM_CH_G-1 downto 0 generate
      U_BRAM : entity surf.SimpleDualPortRam
         generic map (
            TPD_G         => TPD_G,
            MEMORY_TYPE_G => "block",
            DOB_REG_G     => true,      -- 2 cycle latency
            DATA_WIDTH_G  => 32,
            ADDR_WIDTH_G  => BUFFER_WIDTH_G)
         port map (
            -- Port A     
            clka  => appClk,
            wea   => wrEn,
            addra => wrAddr,
            dina  => wrData(i),
            -- Port B
            clkb  => axisClk,
            rstb  => axisRst,
            addrb => rdAddr,
            doutb => rdData(i));
   end generate GEN_BRAM;

   -----------------
   -- BRAM Read FSM
   -----------------
   U_ReadFsm : entity amc_carrier_core.AxisBramFlashBufferRdFsm
      generic map (
         TPD_G              => TPD_G,
         NUM_CH_G           => NUM_CH_G,
         AXIS_TDATA_WIDTH_G => AXIS_TDATA_WIDTH_G,
         BUFFER_WIDTH_G     => BUFFER_WIDTH_G)
      port map (
         -- Write FSM Interface (axisClk domain)
         req        => req,
         valid      => valid,
         timestamp  => timestamp,
         ack        => ack,
         -- Ram Interface (axisClk domain)
         rdAddr     => rdAddr,
         rdData     => rdData,
         -- Software Interface (axilClk domain)
         axilClk    => axilClk,
         axilRst    => axilRst,
         tDest      => r.tDest,
         -- AXI Stream Interface (axisClk domain)
         axisClk    => axisClk,
         axisRst    => axisRst,
         axisMaster => axisMaster,
         axisSlave  => axisSlave);

   --------------------- 
   -- AXI Lite Interface
   --------------------- 
   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobing signals
      v.swTrig := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read registers
      for i in NUM_CH_G-1 downto 0 loop
         axiSlaveRegister(regCon, toSlv(4*i, 8), 0, v.tDest(i));
      end loop;
      axiSlaveRegister(regCon, x"F8", 0, v.swTrig);
      axiSlaveRegister(regCon, x"FC", 0, v.enable);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
