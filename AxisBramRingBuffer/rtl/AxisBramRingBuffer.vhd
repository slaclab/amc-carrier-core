-------------------------------------------------------------------------------
-- File       : AxisBramRingBuffer.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2018-04-10
-- Last update: 2018-04-10
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

use work.StdRtlPkg.all;

entity AxisBramRingBuffer is
   generic (
      TPD_G          : time     := 1 ns;
      PIPE_STAGES_G  : natural  := 0;
      NUM_CH_G       : positive := 1;
      BUFFER_WIDTH_G : positive := 10);
   port (
      -- Input Data Interface (appClk domain)
      appClk          : in  sl;
      appRst          : in  sl;
      appValid        : in  slv(NUM_CH_G-1 downto 0);
      appData         : in  Slv32Array(NUM_CH_G-1 downto 0);
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
end AxisBramRingBuffer;

architecture mapping of AxisBramRingBuffer is

   constant TDEST_ROUTES_C : Slv8Array(NUM_CH_G-1 downto 0) := (others => "--------");

   type RegType is record
      swTrig : sl;
      tDest  : slv(NUM_CH_G-1 downto 0)
         axilReadSlave : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      swTrig         => '0',
      tDest          => (others => x"FF"),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal axisMasters : AxiStreamMasterArray(NUM_CH_G-1 downto 0);
   signal axisSlaves  : AxiStreamSlaveType(NUM_CH_G-1 downto 0);

   signal req : sl;
   signal ack : sl;

   signal wrEn   : sl;
   signal wrAddr : slv(BUFFER_WIDTH_G-1 downto 0);
   signal rdAddr : slv(BUFFER_WIDTH_G-1 downto 0);
   signal rdData : Slv32Array(NUM_CH_G-1 downto 0);

   signal swTrig : sl;
   signal tDest  : slv(NUM_CH_G-1 downto 0)

begin

   -----------------
   -- BRAM Write FSM
   -----------------
   U_WriteFsm : entity work.AxisBramRingBufferWrFsm
      generic map (
         TPD_G          => TPD_G,
         NUM_CH_G       => NUM_CH_G,
         BUFFER_WIDTH_G => BUFFER_WIDTH_G)
      port map (
         clk    => appClk,
         rst    => appRst,
         valid  => appValid,
         wrEn   => wrEn,
         wrAddr => wrAddr,
         req    => req,
         ack    => ack);

   ---------------
   -- BRAM Buffers
   ---------------
   GEN_BRAM : for i in NUM_CH_G-1 downto 0 generate
      U_BRAM : entity work.SimpleDualPortRam
         generic map (
            TPD_G        => TPD_G,
            BRAM_EN_G    => true,
            DOB_REG_G    => true,
            DATA_WIDTH_G => 32,
            ADDR_WIDTH_G => BUFFER_WIDTH_G)
         port map (
            -- Port A     
            clka  => appClk,
            wea   => wrEn,
            addra => wrAddr,
            dina  => appData(i),
            -- Port B
            clkb  => axisClk,
            rstb  => axisRst,
            addrb => rdAddr,
            doutb => rdData(i));
   end generate GEN_BRAM;

   -----------------
   -- BRAM Read FSM
   -----------------
   U_ReadFsm : entity work.AxisBramRingBufferRdFsm
      generic map (
         TPD_G          => TPD_G,
         NUM_CH_G       => NUM_CH_G,
         BUFFER_WIDTH_G => BUFFER_WIDTH_G)
      port map (
         clk         => axisClk,
         rst         => axisRst,
         rdAddr      => rdAddr,
         rdData      => rdData,
         tDest       => tDest,
         axisMasters => axisMasters,
         axisSlaves  => axisSlaves,
         req         => req,
         ack         => ack);

   -----------------
   -- AXI stream MUX
   -----------------
   U_AxiStreamMux : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         PIPE_STAGES_G  => PIPE_STAGES_G,
         NUM_SLAVES_G   => NUM_CH_G,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => TDEST_ROUTES_C)
      port map (
         -- Clock and reset
         axisClk      => axisClk,
         axisRst      => axisRst,
         -- Slaves
         sAxisMasters => axisMasters,
         sAxisSlaves  => axisSlaves,
         -- Master
         mAxisMaster  => axisMaster,
         mAxisSlave   => axisSlave);

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
         axiSlaveRegister(regCon, toSlv(8*i, 8), 0, r.tDest(i));
      end loop;
      axiSlaveRegister(regCon, x"FC", 0, v.swTrig);

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

   U_SyncSwTrig : entity work.SynchronizerOneShot
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axisClk,
         dataIn  => r.swTrig,
         dataOut => swTrig);

   GEN_SYNC : for i in NUM_CH_G-1 downto 0 generate
      U_SyncTdest : entity work.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 8)
         port map (
            clk     => axisClk,
            dataIn  => r.tDest(i),
            dataOut => tDest(i));
   end generate GEN_SYNC;

end mapping;
