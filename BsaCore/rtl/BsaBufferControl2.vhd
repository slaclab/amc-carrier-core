-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaBufferControl.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2015-10-20
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
use ieee.math_real.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;

use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;
use work.TimingPkg.all;

entity BsaBufferControl2 is

   generic (
      TPD_G             : time                      := 1 ns;
      BSA_BUFFERS_G     : natural range 1 to 64     := 32;
      BSA_STREAM_BYTES_G : integer range 4 to 128 := 8;
      DDR_BURST_BYTES_G : integer range 128 to 4096 := 2048;
      DDR_DATA_BYTES_G  : integer range 1 to 128    := 8);

   port (
      -- AXI-Lite Interface for local registers 
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Diagnostic Interface from application
      diagnosticClk : in sl;
      diagnosticRst : in sl;
      diagnosticBus : in DiagnosticBusType;

      -- AXI4 Interface for DDR 
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiWriteMaster : out AxiWriteMasterType;
      axiWriteSlave  : in  AxiWriteSlaveType);

end entity BsaBufferControl2;

architecture rtl of BsaBufferControl2 is

   -- AxiLite bus gets synchronized to axi4 clk
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(BSA_BUFFERS_G-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(BSA_BUFFERS_G-1 downto 0);

   constant AXI_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => BSA_STREAM_BYTES_G,
      TDEST_BITS_C  => 8,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_NONE_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   constant DDR_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => DDR_DATA_BYTES_G,
      TDEST_BITS_C  => 8,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_NONE_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   constant INT_AXIS_COUNT_C : integer := integer(ceil(real(BSA_BUFFERS_G)/8.0));

   signal bsaAxisMasters : AxiStreamMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal bsaAxisSlaves  : AxiStreamSlaveArray(BSA_BUFFERS_G-1 downto 0);
   signal intAxisMasters : AxiStreamMasterArray(INT_AXIS_COUNT_C-1 downto 0);
   signal intAxisSlaves  : AxiStreamSlaveArray(INT_AXIS_COUNT_C-1 downto 0);
   signal lastAxisMaster : AxiStreamMasterType;
   signal lastAxisSlave  : AxiStreamSlaveType;
   signal ddrAxisMaster  : AxiStreamMasterType;
   signal ddrAxisSlave   : AxiStreamSlaveType;

   constant BSA_BUFFER_ENTRY_BITS_C      : integer := 1024;
   constant BSA_BUFFER_ENTRY_BYTES_C     : integer := BSA_BUFFER_ENTRY_BITS_C/8;
   constant BSA_BUFFER_ENTRY_INCREMENT_C : integer := 64*2;  -- bursts cant cross 4k boundary



   type BsaBufferType is record
      startAddr  : slv(31 downto 0);
      endAddr    : slv(31 downto 0);
      timeStamp  : slv(63 downto 0);    -- timeStamp of bsaInit
      firstEntry : slv(31 downto 0);    -- Address of first entry curerntly in ram
      lastEntry  : slv(31 downto 0);    -- Address of last entry currently in ram
      nextEntry  : slv(31 downto 0);
   end record BsaBufferType;

   type BsaBufferArray is array (natural range <>) of BsaBufferType;

   constant BSA_BUFFER_INIT_C : BsaBufferType := (
      startAddr  => (others => '0'),
      endAddr    => (others => '0'),
      timeStamp  => (others => '0'),
      firstEntry => (others => '0'),
      lastEntry  => (others => '0'),
      nextEntry  => (others => '0'));

   type AxiStateType is (WAIT_FIFO_ENTRY_S, ADDR_S, DATA_S, RESP_S);

   type RegType is record
      -- Just register the whole timing message
      strobe          : sl;
      timingMessage   : TimingMessageType;
      diagnosticData  : Slv32Array(31 downto 0);
      bsaInitAxil     : slv(63 downto 0);
      bsaCompleteAxil : slv(63 downto 0);

      ramAddr32  : sl;
      bsaBuffers : BsaBufferArray(BSA_BUFFERS_G-1 downto 0);

      accumulateEn : sl;
      adderCount   : integer range 0 to 63;

      ddrAxisSlave : AxiStreamSlaveType;

      axiShiftReg    : slv(BSA_BUFFER_ENTRY_BITS_C-1 downto 0);
      axiState       : AxiStateType;
      axiBurstCount  : slv(1 downto 0);
      axiBuffer      : slv(5 downto 0);
      axiWriteMaster : AxiWriteMasterType;

      axilWriteSlaves : AxiLiteWriteSlaveArray(BSA_BUFFERS_G-1 downto 0);
      axilReadSlaves  : AxiLiteReadSlaveArray(BSA_BUFFERS_G-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      strobe          => '0',
      timingMessage   => TIMING_MESSAGE_INIT_C,
      diagnosticData  => (others => (others => '0')),
      bsaInitAxil     => (others => '0'),
      bsaCompleteAxil => (others => '0'),
      ramAddr32       => '0',
      bsaBuffers      => (others => BSA_BUFFER_INIT_C),
      accumulateEn    => '0',
      adderCount      => 0,
      ddrAxisSlave    => AXI_STREAM_SLAVE_INIT_C,
      axiShiftReg     => (others => '0'),
      axiState        => WAIT_FIFO_ENTRY_S,
      axiBurstCount   => (others => '0'),
      axiBuffer       => (others => '0'),
      axiWriteMaster  => AXI_WRITE_MASTER_INIT_C,
      axilWriteSlaves => (others => AXI_LITE_WRITE_SLAVE_INIT_C),
      axilReadSlaves  => (others => AXI_LITE_READ_SLAVE_INIT_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


   -- signals that new diagnostic data is available
   signal diagnosticStrobeSync : sl;


begin

   -- Synchronize Axi-Lite bus to axiClk (ddrClk)
   AxiLiteAsync_1 : entity work.AxiLiteAsync
      generic map (
         TPD_G           => TPD_G,
         NUM_ADDR_BITS_G => 32,
         PIPE_STAGES_G   => 1)
      port map (
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         mAxiClk         => axiClk,
         mAxiClkRst      => axiRst,
         mAxiReadMaster  => syncAxilReadMaster,
         mAxiReadSlave   => syncAxilReadSlave,
         mAxiWriteMaster => syncAxilWriteMaster,
         mAxiWriteSlave  => syncAxilWriteSlave);

   U_AxiLiteCrossbar_1 : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => BSA_BUFFERS_G,
         DEC_ERROR_RESP_G   => AXI_RESP_DECERR_C,
         MASTERS_CONFIG_G   => genAxiLiteConfig(BSA_BUFFERS_G, BSA_ADDR_C, 12, 6),
         DEBUG_G            => true)
      port map (
         axiClk              => axiClk,               -- [in]
         axiClkRst           => axiRst,               -- [in]
         sAxiWriteMasters(0) => syncAxilWriteMaster,  -- [in]
         sAxiWriteSlaves(0)  => syncAxilWriteSlave,   -- [out]
         sAxiReadMasters(0)  => syncAxilReadMaster,   -- [in]
         sAxiReadSlaves(0)   => syncAxilReadSlave,    -- [out]
         mAxiWriteMasters    => locAxilWriteMasters,  -- [out]
         mAxiWriteSlaves     => locAxilWriteSlaves,   -- [in]
         mAxiReadMasters     => locAxilReadMasters,   -- [out]
         mAxiReadSlaves      => locAxilReadSlaves);   -- [in]

   SynchronizerFifo_1 : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         DATA_WIDTH_G => 1)
      port map (
         rst    => diagnosticRst,
         wr_clk => diagnosticClk,
         wr_en  => diagnosticBus.strobe,
         din    => "1",
         rd_clk => axiClk,
         valid  => diagnosticStrobeSync);

   BsaAccumulator_GEN : for i in BSA_BUFFERS_G-1 downto 0 generate
      U_BsaAccumulator_1 : entity work.BsaAccumulator
         generic map (
            TPD_G              => TPD_G,
            BSA_NUMBER_G       => i,
            FRAME_SIZE_BYTES_G => DDR_BURST_BYTES_G,
            AXIS_CONFIG_G      => AXI_STREAM_CONFIG_C)
         port map (
            clk            => axiClk,                         -- [in]
            rst            => axiRst,                         -- [in]
            bsaInit        => r.timingMessage.bsaInit(i),     -- [in]
            bsaActive      => r.timingMessage.bsaActive(i),   -- [in]
            bsaAvgDone     => r.timingMessage.bsaAvgDone(i),  -- [in]
            diagnosticData => r.diagnosticData(0),            -- [in]
            accumulateEn   => r.accumulateEn,                 -- [in]
            axisMaster     => bsaAxisMasters(i),              -- [out]
            axisSlave      => bsaAxisSlaves(i));              -- [in]
   end generate;

   AxiStreamMux_GEN : for i in INT_AXIS_COUNT_C-1 downto 0 generate
      U_AxiStreamMux_1 : entity work.AxiStreamMux
         generic map (
            TPD_G         => TPD_G,
            NUM_SLAVES_G  => 8,
            PIPE_STAGES_G => 0,
            TDEST_HIGH_G  => 7,
            TDEST_LOW_G   => 0,
            KEEP_TDEST_G  => true)
         port map (
            sAxisMasters => bsaAxisMasters(i*8+8-1 downto i*8),  -- [in]
            sAxisSlaves  => bsaAxisSlaves(i*8+8-1 downto i*8),  -- [out]
            mAxisMaster  => intAxisMasters(i),  -- [out]
            mAxisSlave   => intAxisSlaves(i),   -- [in]
            axisClk      => axiClk,     -- [in]
            axisRst      => axiRst);    -- [in]
   end generate;

   U_AxiStreamMux_2 : entity work.AxiStreamMux
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => INT_AXIS_COUNT_C,
         PIPE_STAGES_G => 1,
         TDEST_HIGH_G  => 7,
         TDEST_LOW_G   => 0,
         KEEP_TDEST_G  => true)
      port map (
         sAxisMasters => intAxisMasters,  -- [in]
         sAxisSlaves  => intAxisSlaves,   -- [out]
         mAxisMaster  => lastAxisMaster,  -- [out]
         mAxisSlave   => lastAxisSlave,   -- [in]
         axisClk      => axiClk,          -- [in]
         axisRst      => axiRst);         -- [in]

   U_AxiStreamFifo_1 : entity work.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 0,
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => true,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 10,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1,
         CASCADE_PAUSE_SEL_G => 0,
         SLAVE_AXI_CONFIG_G  => AXI_STREAM_CONFIG_C,
         MASTER_AXI_CONFIG_G => DDR_STREAM_CONFIG_C)
      port map (
         sAxisClk    => axiClk,           -- [in]
         sAxisRst    => axiRst,           -- [in]
         sAxisMaster => lastAxisMaster,   -- [in]
         sAxisSlave  => lastAxisSlave,    -- [out]
         sAxisCtrl   => open,
         mAxisClk    => axiClk,           -- [in]
         mAxisRst    => axiRst,           -- [in]
         mAxisMaster => ddrAxisMaster,    -- [out]
         mAxisSlave  => r.ddrAxisSlave);  -- [in]


   comb : process (axiRst, axiWriteSlave, ddrAxisMaster, diagnosticBus, diagnosticStrobeSync,
                   locAxilReadMasters, locAxilWriteMasters, r) is
      variable v         : RegType;
      variable b         : integer range 0 to BSA_BUFFERS_G-1;
      variable axiStatus : AxiLiteStatusType;

      -- Wrapper procedures to make calls cleaner.
      procedure axiSlaveRegisterW (index : in integer; addr : in slv; offset : in integer; reg : inout slv) is
      begin
         axiSlaveRegister(locAxilWriteMasters(index), locAxilReadMasters(index), v.axilWriteSlaves(index), v.axilReadSlaves(index), axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterR (index : in integer; addr : in slv; offset : in integer; reg : in slv) is
      begin
         axiSlaveRegister(locAxilReadMasters(index), v.axilReadSlaves(index), axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterW (index : in integer; addr : in slv; offset : in integer; reg : inout sl) is
      begin
         axiSlaveRegister(locAxilWriteMasters(index), locAxilReadMasters(index), v.axilWriteSlaves(index), v.axilReadSlaves(index), axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveRegisterR (index : in integer; addr : in slv; offset : in integer; reg : in sl) is
      begin
         axiSlaveRegister(locAxilReadMasters(index), v.axilReadSlaves(index), axiStatus, addr, offset, reg);
      end procedure;

      procedure axiSlaveDefault (
         index   : in integer;
         axiResp : in slv(1 downto 0)) is
      begin
         axiSlaveDefault(locAxilWriteMasters(index), locAxilReadMasters(index), v.axilWriteSlaves(index), v.axilReadSlaves(index), axiStatus, axiResp);
      end procedure;

   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- Synchronization
      -- Wait for synchronized strobe signal, then latch the timing message onto the local clock      
      ----------------------------------------------------------------------------------------------
      v.strobe := '0';
      if (diagnosticStrobeSync = '1') then
         v.strobe         := '1';
         v.timingMessage  := diagnosticBus.timingMessage;
         v.diagnosticData := diagnosticBus.data;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Grab timestamp
      ----------------------------------------------------------------------------------------------
      if (r.strobe = '1') then
         v.accumulateEn := '1';
         v.adderCount   := 0;

         for b in BSA_BUFFERS_G-1 downto 0 loop
            -- Initialize each buffer on bsaInit
            v.bsaCompleteAxil(b) := r.bsaCompleteAxil(b) or r.timingMessage.bsaDone(b);
            if (r.timingMessage.bsaInit(b) = '1') then
               -- Reset ring buffers on init
               v.bsaInitAxil(b)          := '1';
               v.bsaBuffers(b).timeStamp := r.timingMessage.timeStamp;
            end if;
         end loop;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Accumulation stage - shift new diagnostic data through the accumulator
      ----------------------------------------------------------------------------------------------
      if (r.accumulateEn = '1') then
         v.diagnosticData(31)          := X"00000000";
         v.diagnosticData(30 downto 0) := r.diagnosticData(31 downto 1);

         -- Stop when done with all buffers
         v.adderCount := r.adderCount + 1;
         if (r.adderCount = 31) then
            v.adderCount   := 0;
            v.accumulateEn := '0';
         end if;
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI4 Stage - Read entries from FIFO and write to RAM on AXI4 bus
      ----------------------------------------------------------------------------------------------

      -- default bus outputs
      v.axiWriteMaster.awid       := (others => '0');
      v.axiWriteMaster.awlen      := toSlv(DDR_BURST_BYTES_G/DDR_DATA_BYTES_G-1, 8);  -- 64 bytes per burst txn
      v.axiWriteMaster.awsize     := toSlv(log2(DDR_DATA_BYTES_G), 3);  -- 64 byte data bus
      v.axiWriteMaster.awburst    := "01";    -- Burst type = "INCR"
      v.axiWriteMaster.awlock     := (others => '0');
      v.axiWriteMaster.awprot     := (others => '0');
      v.axiWriteMaster.awcache    := "1111";  -- Write-back Read and Write-allocate      
      v.axiWriteMaster.awqos      := (others => '0');
      v.axiWriteMaster.bready     := '1';
      v.axiWriteMaster.wstrb      := (others => '1');
      v.axiWriteMaster.awaddr(32) := r.ramAddr32;

      -- Clear valids upon ready response
      if axiWriteSlave.awready = '1' then
         v.axiWriteMaster.awvalid := '0';
      end if;
      if axiWriteSlave.wready = '1' then
         v.axiWriteMaster.wvalid := '0';
         v.axiWriteMaster.wlast  := '0';
      end if;

      v.ddrAxisSlave.tready := '0';

      v.axiWriteMaster.wdata(DDR_DATA_BYTES_G*8-1 downto 0) := ddrAxisMaster.tdata(DDR_DATA_BYTES_G*8-1 downto 0);


      b := conv_integer(r.axiBuffer);
      case (r.axiState) is
         when WAIT_FIFO_ENTRY_S =>
            -- If there is data and no active AXI txn, then read it out of the FIFO and start a new txn
            if (ddrAxisMaster.tvalid = '1' and v.axiWriteMaster.awvalid = '0' and v.axiWriteMaster.wvalid = '0') then
               v.axiState               := ADDR_S;
               v.axiBuffer              := ddrAxisMaster.tdest(5 downto 0);
               v.axiWriteMaster.awvalid := '0';
               v.axiWriteMaster.wvalid  := '0';
               v.ddrAxisSlave.tready    := '0';
            end if;

         when ADDR_S =>
            -- Send address and first data word.
            v.axiWriteMaster.awaddr(31 downto 0) := r.bsaBuffers(b).nextEntry;
            v.bsaBuffers(b).nextEntry            := r.bsaBuffers(b).nextEntry + DDR_BURST_BYTES_G;
            if (r.bsaBuffers(b).nextEntry = r.bsaBuffers(b).endAddr - DDR_BURST_BYTES_G) then
               v.bsaBuffers(b).nextEntry := r.bsaBuffers(b).startAddr;
            end if;

            if (r.bsaBuffers(b).nextEntry = r.bsaBuffers(b).firstEntry and
                r.bsaBuffers(b).lastEntry /= r.bsaBuffers(b).firstEntry) then
               v.bsaBuffers(b).firstEntry := r.bsaBuffers(b).firstEntry + DDR_BURST_BYTES_G;
            end if;


            v.axiWriteMaster.awvalid := '1';
            v.axiWriteMaster.wvalid  := '1';
            v.ddrAxisSlave.tready    := '1';
            v.axiState               := DATA_S;

         when DATA_S =>
            -- put next 512 bits on the wr data bus and increment count
            if (v.axiWriteMaster.wvalid = '0') then
               v.ddrAxisSlave.tready   := '1';
               v.axiWriteMaster.wvalid := '1';
               if (ddrAxisMaster.tlast = '1') then
                  v.axiWriteMaster.wlast := '1';
                  v.axiState             := RESP_S;
               end if;
            end if;

         when RESP_S =>
            -- When bvalid resp comes back, update lastEntry and firstEntry for the buffer
            if (axiWriteSlave.bvalid = '1') then
               v.axiState                := WAIT_FIFO_ENTRY_S;
               v.bsaBuffers(b).lastEntry := r.axiWriteMaster.awaddr(31 downto 0) +
                                            DDR_BURST_BYTES_G -
                                            BSA_BUFFER_ENTRY_INCREMENT_C;
            end if;

      end case;


      ----------------------------------------------------------------------------------------------
      -- AXI-Lite bus for register access
      ----------------------------------------------------------------------------------------------
      for i in 0 to BSA_BUFFERS_G-1 loop
         axiSlaveWaitTxn(locAxilWriteMasters(i), locAxilReadMasters(i), v.axilWriteSlaves(i), v.axilReadSlaves(i), axiStatus);
         v.axilReadSlaves(i).rdata := (others => '0');

--      axiSlaveRegisterW(i, X"00", 0, v.ramAddr32);

         -- Special logic for clear on read status registers
--       if (axiStatus.readEnable = '1') then
--          if (locAxilReadMaster.araddr(11 downto 0) = X"004") then
--             v.axilReadSlave.rdata := v.bsaInitAxil;
--             v.bsaInitAxil         := (others => '0');
--          elsif (locAxilReadMaster.araddr(11 downto 0) = X"008") then
--             v.axilReadSlave.rdata := v.bsaCompleteAxil;
--             v.bsaCompleteAxil     := (others => '0');
--          end if;
--       end if;

         -- Buffer entry tracking follows (these are important)
         axiSlaveRegisterW(i, "000000", 0, v.bsaBuffers(i).startAddr);
         axiSlaveRegisterW(i, "000100", 0, v.bsaBuffers(i).endAddr);
         axiSlaveRegisterR(i, "001000", 0, r.bsaBuffers(i).timeStamp(31 downto 0));
         axiSlaveRegisterR(i, "001100", 0, r.bsaBuffers(i).timeStamp(63 downto 32));
         axiSlaveRegisterR(i, "010000", 0, r.bsaBuffers(i).nextEntry);
         axiSlaveRegisterR(i, "010100", 0, r.bsaBuffers(i).firstEntry);
         axiSlaveRegisterR(i, "011000", 0, r.bsaBuffers(i).lastEntry);




         axiSlaveDefault(i, AXI_RESP_OK_C);
      end loop;

      ----------------------------------------------------------------------------------------------
      -- Reset and output assignment
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiWriteMaster     <= r.axiWriteMaster;
      locAxilWriteSlaves <= r.axilWriteSlaves;
      locAxilReadSlaves  <= r.axilReadSlaves;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
