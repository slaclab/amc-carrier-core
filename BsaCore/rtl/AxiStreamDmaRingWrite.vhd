-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaBufferControl.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2016-02-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.AxiDmaPkg.all;

entity AxiStreamDmaRingWrite is

   generic (
      TPD_G                : time                    := 1 ns;
      BUFFERS_G            : natural range 2 to 256  := 64;
      BURST_SIZE_BYTES_G   : natural range 4 to 4096 := 4096;
      AXI_LITE_BASE_ADDR_G : slv(31 downto 0)        := (others => '0');
      AXI_STREAM_CONFIG_G  : AxiStreamConfigType     := ssiAxiStreamConfig(8);
      AXI_WRITE_CONFIG_G   : AxiConfigType           := axiConfig(32, 8, 1, 8));
   port (
      -- AXI-Lite Interface for local registers 
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Axi Stream interface to be buffered
      axisClk          : in  sl;
      axisRst          : in  sl;
      axisDataMaster   : in  AxiStreamMasterType;
      axisDataSlave    : out AxiStreamSlaveType;
      axisStatusMaster : out AxiStreamMasterType;
      axisStatusSlave  : in  AxiStreamSlaveType;

      -- Low level buffer control
      bufferClear   : in  slv(log2(BUFFERS_G)-1 downto 0);
      bufferClearEn : in  sl;
      bufferFull    : out slv(BUFFERS_G-1 downto 0);
      bufferDone    : out slv(BUFFERS_G-1 downto 0);

      -- AXI4 Interface for DDR 
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiWriteMaster : out AxiWriteMasterType;
      axiWriteSlave  : in  AxiWriteSlaveType);

end entity AxiStreamDmaRingWrite;

architecture rtl of AxiStreamDmaRingWrite is

   -- Ram contents represent AXI address shifted by 2
   constant RAM_DATA_WIDTH_C : integer := AXI_WRITE_CONFIG_G.ADDR_WIDTH_C-2;
   constant RAM_ADDR_WIDTH_C : integer := log2(BUFFERS_G);

   constant AXIL_MASTERS_C : integer := 4;
--   constant LOCAL_AXIL_C   : integer := ;
   constant START_AXIL_C   : integer := 0;
   constant END_AXIL_C     : integer := 1;
   constant FIRST_AXIL_C   : integer := 2;
   constant LAST_AXIL_C    : integer := 3;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;

   type StateType is (WAIT_TVALID_S, LATCH_POINTERS_S, WAIT_DMA_DONE_S, INIT_FIRST_LAST_S);

   type RegType is record
      wrRamAddr     : slv(log2(BUFFERS_G)-1 downto 0);
      rdRamAddr     : slv(log2(BUFFERS_G)-1 downto 0);
      tmpRamAddr    : slv(log2(BUFFERS_G)-1 downto 0);
      initFirstLast : sl;
      bufferDone    : slv(BUFFERS_G-1 downto 0);
      bufferFull    : slv(BUFFERS_G-1 downto 0);
      ramWe         : sl;
      firstAddr     : slv(RAM_DATA_WIDTH_C-1 downto 0);
      lastAddr      : slv(RAM_DATA_WIDTH_C-1 downto 0);
      startAddr     : slv(RAM_DATA_WIDTH_C-1 downto 0);
      endAddr       : slv(RAM_DATA_WIDTH_C-1 downto 0);
      state         : StateType;
      dmaReq        : AxiWriteDmaReqType;
      trigger       : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      wrRamAddr     => (others => '0'),
      rdRamAddr     => (others => '0'),
      tmpRamAddr    => (others => '0'),
      initFirstLast => '0',
      bufferDone    => (others => '0'),
      bufferFull    => (others => '0'),
      ramWe         => '0',
      firstAddr     => (others => '0'),
      lastAddr      => (others => '0'),
      startAddr     => (others => '0'),
      endAddr       => (others => '0'),
      state         => WAIT_TVALID_S,
      dmaReq        => AXI_WRITE_DMA_REQ_INIT_C,
      trigger       => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal dmaAck       : AxiWriteDmaAckType;
   signal startRamDout : slv(RAM_DATA_WIDTH_C-1 downto 0);
   signal endRamDout   : slv(RAM_DATA_WIDTH_C-1 downto 0);
   signal firstRamDout : slv(RAM_DATA_WIDTH_C-1 downto 0);
   signal lastRamDout  : slv(RAM_DATA_WIDTH_C-1 downto 0);

begin
   -- Assert that stream config has enough tdest bits for the number of buffers being tracked

   -- Crossbar
   U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_MASTERS_C,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         MASTERS_CONFIG_G   => genAxiLiteConfig(AXIL_MASTERS_C, AXI_LITE_BASE_ADDR_G,
                                              RAM_ADDR_WIDTH_C+6, RAM_ADDR_WIDTH_C+2),
         DEBUG_G            => true)
      port map (
         axiClk              => axilClk,              -- [in]
         axiClkRst           => axilRst,              -- [in]
         sAxiWriteMasters(0) => axilWriteMaster,      -- [in]
         sAxiWriteSlaves(0)  => axilWriteSlave,       -- [out]
         sAxiReadMasters(0)  => axilReadMaster,       -- [in]
         sAxiReadSlaves(0)   => axilReadSlave,        -- [out]
         mAxiWriteMasters    => locAxilWriteMasters,  -- [out]
         mAxiWriteSlaves     => locAxilWriteSlaves,   -- [in]
         mAxiReadMasters     => locAxilReadMasters,   -- [out]
         mAxiReadSlaves      => locAxilReadSlaves);   -- [in]

   -------------------------------------------------------------------------------------------------
   -- AXI RAMs store buffer information
   -------------------------------------------------------------------------------------------------
   -- Start Addresses. AXIL writeable
   U_AxiDualPortRam_Start : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => true,
         SYS_WR_EN_G  => false,
         ADDR_WIDTH_G => RAM_ADDR_WIDTH_C,
         DATA_WIDTH_G => RAM_DATA_WIDTH_C)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(START_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(START_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(START_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(START_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         addr           => r.rdRamAddr,
         dout           => startRamDout);

   -- End Addresses. AXIL writeable
   U_AxiDualPortRam_End : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => true,
         SYS_WR_EN_G  => false,
         ADDR_WIDTH_G => RAM_ADDR_WIDTH_C,
         DATA_WIDTH_G => RAM_DATA_WIDTH_C)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(END_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(END_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(END_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(END_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         addr           => r.rdRamAddr,
         dout           => endRamDout);

   -- First Addresses. System writeable
   U_AxiDualPortRam_First : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => false,
         SYS_WR_EN_G  => true,
         ADDR_WIDTH_G => RAM_ADDR_WIDTH_C,
         DATA_WIDTH_G => RAM_DATA_WIDTH_C)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(FIRST_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(FIRST_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(FIRST_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(FIRST_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         we             => r.ramWe,
         addr           => r.wrRamAddr,
         din            => r.firstAddr,
         dout           => firstRamDout);

   -- Last Addresses. System writeable
   U_AxiDualPortRam_Last : entity work.AxiDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         AXI_WR_EN_G  => false,
         SYS_WR_EN_G  => true,
         ADDR_WIDTH_G => RAM_ADDR_WIDTH_C,
         DATA_WIDTH_G => RAM_DATA_WIDTH_C)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(LAST_AXIL_C),
         axiReadSlave   => locAxilReadSlaves(LAST_AXIL_C),
         axiWriteMaster => locAxilWriteMasters(LAST_AXIL_C),
         axiWriteSlave  => locAxilWriteSlaves(LAST_AXIL_C),
         clk            => axiClk,
         rst            => axiRst,
         we             => r.ramWe,
         addr           => r.wrRamAddr,
         din            => r.lastAddr,
         dout           => lastRamDout);



   -- DMA Write block
   U_AxiStreamDmaWrite_1 : entity work.AxiStreamDmaWrite
      generic map (
         TPD_G          => TPD_G,
         AXI_READY_EN_G => true,
         AXIS_CONFIG_G  => AXI_STREAM_CONFIG_G,
         AXI_CONFIG_G   => AXI_WRITE_CONFIG_G,
         AXI_BURST_G    => "01",            -- INCR
         AXI_CACHE_G    => "1111")          -- Cacheable
      port map (
         axiClk         => axiClk,          -- [in]
         axiRst         => axiRst,          -- [in]
         dmaReq         => r.dmaReq,        -- [in]
         dmaAck         => dmaAck,          -- [out]
         axisMaster     => axisDataMaster,  -- [in]
         axisSlave      => axisDataSlave,   -- [out]
         axiWriteMaster => axiWriteMaster,  -- [out]
         axiWriteSlave  => axiWriteSlave);  -- [in]

   comb : process (axiRst, axisDataMaster, bufferClear, bufferClearEn, dmaAck, endRamDout, firstRamDout,
                   lastRamDout, r, startRamDout) is
      variable v : RegType;
   begin
      v := r;

      v.ramWe          := '0';
      v.dmaReq.maxSize := toSlv(BURST_SIZE_BYTES_G, 32);
      v.initFirstLast  := '0';
      v.bufferDone     := (others => '0');

      if (axisDataMaster.tValid = '1' and axisDataMaster.tLast = '1' and
          axiStreamGetUserBit(AXI_STREAM_CONFIG_G, axisDataMaster, 0) = '1') then
         v.trigger := '1';
      end if;


      case (r.state) is
         when WAIT_TVALID_S =>
            -- Only final burst before readout can be short, so no need to worry about next
            -- burst wrapping awkwardly. Whole thing will be reset after readout.
            -- Don't do anything if in the middle of a buffer address clear
            if (axisDataMaster.tvalid = '1') then
               v.wrRamAddr := axisDataMaster.tdest(RAM_ADDR_WIDTH_C-1 downto 0);
               v.rdRamAddr := axisDataMaster.tdest(RAM_ADDR_WIDTH_C-1 downto 0);
               v.state     := LATCH_POINTERS_S;
            end if;

            -- Don't allow dma req to start if a buffer neads to be init
            if (bufferClearEn = '1') then
--               print("bsaInit in WAIT_TVALID_S: " & str(conv_integer(r.adderCount)));
               v.initFirstLast := '1';
               v.rdRamAddr     := bufferClear;
               v.wrRamAddr     := r.rdRamAddr;
               v.state         := WAIT_TVALID_S;
            end if;

         when LATCH_POINTERS_S =>
            -- Latch pointers
            v.startAddr := startRamDout;
            v.endAddr   := endRamDout;
            v.firstAddr := firstRamDout;
            v.lastAddr  := lastRamDout;

            v.dmaReq.address(AXI_WRITE_CONFIG_G.ADDR_WIDTH_C-1 downto 0) := lastRamDout & "00";
            v.dmaReq.request                                             := '1';
            v.state                                                      := WAIT_DMA_DONE_S;

            -- Init request might interrupt things
            if (bufferClearEn = '1') then
               v.initFirstLast := '1';
               v.rdRamAddr     := bufferClear;
               v.wrRamAddr     := bufferClear;
               v.tmpRamAddr    := r.rdRamAddr;
               v.state         := INIT_FIRST_LAST_S;
            end if;

         when INIT_FIRST_LAST_S =>
            if (bufferClearEn = '1') then
--               print("bsaInit in INIT_FIRST_LAST_S: " & str(conv_integer(r.adderCount)));
               v.initFirstLast := '1';
               v.rdRamAddr     := bufferClear;
               v.wrRamAddr     := r.rdRamAddr;
               v.state         := INIT_FIRST_LAST_S;
            else
               v.rdRamAddr := r.tmpRamAddr;
               v.wrRamAddr := r.tmpRamAddr;
               v.state     := LATCH_POINTERS_S;
            end if;


         when WAIT_DMA_DONE_S =>
            -- Must check that buffer not being cleared so as not to step on the addresses
            if (bufferClearEn = '1') then
--               print("bsaInit in WAIT_DMA_DONE_S: " & str(conv_integer(r.adderCount)));
               v.initFirstLast := '1';
               v.rdRamAddr     := bufferClear;
               v.wrRamAddr     := bufferClear;
               v.tmpRamAddr    := r.rdRamAddr;
               v.state         := INIT_FIRST_LAST_S;

            elsif (dmaAck.done = '1') then
               v.dmaReq.request := '0';

               v.bufferDone(conv_integer(r.rdRamAddr)) := r.trigger;
               v.trigger                               := '0';

               v.ramWe := '1';

               -- Increment address of last burst in buffer.
               -- Wrap back to start when it hits the end of the buffer.
               v.lastAddr := r.lastAddr + dmaAck.size(31 downto 2);  --(BURST_SIZE_BYTES_G/4); --
               if (v.lastAddr = r.endAddr) then
                  v.bufferFull(conv_integer(r.rdRamAddr)) := '1';
                  v.lastAddr                              := r.startAddr;
               end if;

               -- If the buffer is full, increment the first addr too
               if (v.lastAddr = r.firstAddr) then
                  v.firstAddr := r.firstAddr + (BURST_SIZE_BYTES_G/4);
               end if;

               v.state := WAIT_TVALID_S;
            end if;
      end case;

      if (r.initFirstLast = '1') then
         v.bufferFull(conv_integer(r.rdRamAddr)) := '0';
         v.firstAddr                             := startRamDout;
         v.lastAddr                              := startRamDout;
         v.ramWe                                 := '1';
      end if;



      ----------------------------------------------------------------------------------------------
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      bufferDone <= r.bufferDone;
      bufferFull <= r.bufferFull;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;

