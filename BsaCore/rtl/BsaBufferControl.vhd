-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : BsaBufferControl.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-29
-- Last update: 2015-10-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 Timing BSA Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 Timing BSA Core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;
use work.TimingPkg.all;

entity BsaBufferControl is

   generic (
      TPD_G         : time                  := 1 ns;
      BSA_BUFFERS_G : natural range 1 to 64 := 64);

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

end entity BsaBufferControl;

architecture rtl of BsaBufferControl is

   -- AxiLite bus gets synchronized to axi4 clk
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(BSA_BUFFERS_G-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(BSA_BUFFERS_G-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(BSA_BUFFERS_G-1 downto 0);


   type BsaBufferEntryType is record
      accumulations : Slv32Array(31 downto 0);  -- 32 accumulator registers
   end record BsaBufferEntryType;

   constant BSA_BUFFER_ENTRY_INIT_C : BsaBufferEntryType := (
      accumulations => (others => (others => '0')));

   constant BSA_BUFFER_ENTRY_BITS_C      : integer := (32*32);
   constant BSA_BUFFER_ENTRY_BYTES_C     : integer := BSA_BUFFER_ENTRY_BITS_C/8;
   constant BSA_BUFFER_ENTRY_INCREMENT_C : integer := 64*2;  -- bursts cant cross 4k boundary

   function toSlv (entry : BsaBufferEntryType) return slv is
      variable vector : slv(BSA_BUFFER_ENTRY_BITS_C-1 downto 0);
      variable i      : integer := 0;
   begin
      for j in 0 to 31 loop
         assignSlv(i, vector, entry.accumulations(j));
      end loop;
      return vector;
   end function;

   type BsaBufferType is record
      -- Buffer size set by SW
      startAddr  : slv(31 downto 0);
      endAddr    : slv(31 downto 0);
      -- Registers set by firmware as BSA buffers are processed
      timeStamp  : slv(63 downto 0);    -- timeStamp of bsaInit
      firstEntry : slv(31 downto 0);    -- Address of first entry curerntly in ram
      lastEntry  : slv(31 downto 0);    -- Address of last entry currently in ram
      entry      : BsaBufferEntryType;  -- The entry being build
   end record BsaBufferType;

   type BsaBufferArray is array (natural range <>) of BsaBufferType;

   constant BSA_BUFFER_INIT_C : BsaBufferType := (
      startAddr  => (others => '0'),
      endAddr    => (others => '0'),
      timeStamp  => (others => '0'),
      firstEntry => (others => '0'),
      lastEntry  => (others => '0'),
      entry      => BSA_BUFFER_ENTRY_INIT_C);


   constant FIFO_WIDTH_C : integer := BSA_BUFFER_ENTRY_BITS_C + 6;  -- add wrAddr + buffer number

   constant AXI_WRSTB_NOM_C  : slv(127 downto 0) := slvZero(64) & slvOne(64);
   constant AXI_WRSTB_LAST_C : slv(127 downto 0) := slvZero(108) & slvOne(20);

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

      adderActive : sl;
      adderCount  : integer range 0 to 63;

      arbitrateActive : sl;
      arbitrateCount  : integer range 0 to BSA_BUFFERS_G-1;
      arbitrateDone   : sl;

      fifoWrData : slv(FIFO_WIDTH_C-1 downto 0);
      fifoWrEn   : sl;
      fifoRdEn   : sl;

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
      adderActive     => '0',
      adderCount      => 0,
      arbitrateActive => '0',
      arbitrateCount  => 0,
      arbitrateDone   => '0',
      fifoWrData      => (others => '0'),
      fifoWrEn        => '0',
      fifoRdEn        => '0',
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

   -- Outputs from FB adder array
   signal adderOut   : Slv32Array(BSA_BUFFERS_G-1 downto 0);
   signal adderValid : slv(BSA_BUFFERS_G-1 downto 0);

   -- FIFO outputs (data to be written to RAM)
   signal fifoRdData : slv(FIFO_WIDTH_C-1 downto 0);
   signal fifoValid  : sl;

   function bsaAddr (index : integer; offset : integer) return slv is
      variable ret : slv(11 downto 0);
   begin
      ret := toSlv(index+1, 6) & toSlv(offset, 4) & "00";
      return ret;
   end function bsaAddr;

   component BsaAddFpCore is
      port (
         aclk                 : in  sl;
         s_axis_a_tvalid      : in  sl;
         s_axis_a_tdata       : in  slv(31 downto 0);
         s_axis_b_tvalid      : in  sl;
         s_axis_b_tdata       : in  slv(31 downto 0);
         m_axis_result_tvalid : out sl;
         m_axis_result_tdata  : out slv(31 downto 0));
   end component BsaAddFpCore;

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

   FP_ADDERS : for b in BSA_BUFFERS_G-1 downto 0 generate
      BSA_ADD_FP_CORE : BsaAddFpCore
         port map (
            aclk                 => axiClk,
            s_axis_a_tvalid      => '1',
            s_axis_a_tdata       => r.bsaBuffers(b).entry.accumulations(0),
            s_axis_b_tvalid      => '1',
            s_axis_b_tdata       => r.diagnosticData(0),
            m_axis_result_tvalid => adderValid(b),
            m_axis_result_tdata  => adderOut(b));
   end generate FP_ADDERS;

   Fifo_2 : entity work.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         BRAM_EN_G       => true,
         FWFT_EN_G       => true,
         USE_DSP48_G     => "no",
         USE_BUILT_IN_G  => false,
--         SYNC_STAGES_G   => SYNC_STAGES_G,
--         PIPE_STAGES_G   => PIPE_STAGES_G,
         DATA_WIDTH_G    => FIFO_WIDTH_C,
         ADDR_WIDTH_G    => 10)
      port map (
         rst           => axiRst,
         wr_clk        => axiClk,
         wr_en         => r.fifoWrEn,
         din           => r.fifoWrData,
         wr_data_count => open,
         overflow      => open,
         full          => open,
         rd_clk        => axiClk,
         rd_en         => r.fifoRdEn,
         dout          => fifoRdData,
         valid         => fifoValid);

   comb : process (adderOut, axiRst, axiWriteSlave, diagnosticBus, diagnosticStrobeSync, fifoRdData,
                   fifoValid, locAxilReadMasters, locAxilWriteMasters, r) is
      variable v         : RegType;
      variable b3        : integer range 0 to BSA_BUFFERS_G-1;
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

      -- Wait for synchronized strobe signal, then latch the timing message onto the local clock
      v.strobe := '0';
      if (diagnosticStrobeSync = '1') then
         v.strobe         := '1';
         v.timingMessage  := diagnosticBus.timingMessage;
         v.diagnosticData := diagnosticBus.data;
      end if;


      if (r.strobe = '1') then
         v.adderActive    := '1';
         v.adderCount     := 0;
         v.arbitrateCount := 0;

         for b in BSA_BUFFERS_G-1 downto 0 loop

            -- Initialize each buffer on bsaInit
            v.bsaCompleteAxil(b) := r.bsaCompleteAxil(b) or r.timingMessage.bsaDone(b);
            if (r.timingMessage.bsaInit(b) = '1') then
               -- Reset ring buffers on init
               v.bsaInitAxil(b)           := '1';
               v.bsaBuffers(b).timeStamp  := r.timingMessage.timeStamp;
               v.bsaBuffers(b).firstEntry := r.bsaBuffers(b).startAddr;
               v.bsaBuffers(b).lastEntry  := r.bsaBuffers(b).startAddr;
            end if;

         end loop;
      end if;


      ----------------------------------------------------------------------------------------------
      -- Accumulation stage - shift new diagnostic data through the accumulator
      ----------------------------------------------------------------------------------------------
      if (r.adderActive = '1') then
         for b in BSA_BUFFERS_G-1 downto 0 loop
            -- When active, shift accumulation values through the FP adder and back around
            if (r.timingMessage.bsaActive(b) = '1') then
               for i in 0 to 30 loop
                  v.bsaBuffers(b).entry.accumulations(i) := r.bsaBuffers(b).entry.accumulations(i+1);
                  v.diagnosticData(i)                    := r.diagnosticData(i+1);
               end loop;
               v.bsaBuffers(b).entry.accumulations(31) := adderOut(b);

            end if;

         end loop;

         -- Increment the adder bsaBuffer each cycle
         -- Stop when done with all buffers
         v.adderCount := r.adderCount + 1;
         if (r.adderCount = 31 + 11) then
            v.adderCount      := r.adderCount;
            v.adderActive     := '0';
            v.arbitrateActive := '1';
         end if;
      end if;



      ----------------------------------------------------------------------------------------------
      -- FIFO Write stage - Arbitrate bsaBuffers with bsaAvgDone into the FIFO
      ----------------------------------------------------------------------------------------------
      v.arbitrateDone := '0';           -- pulsed
      v.fifoWrEn      := '0';
      v.fifoWrData :=
         toSlv(r.arbitrateCount, 6) &
         toSlv(r.bsaBuffers(r.arbitrateCount).entry);

      if (r.arbitrateActive = '1') then
         if (r.timingMessage.bsaAvgDone(r.arbitrateCount) = '1') then
            v.fifoWrEn := '1';
         end if;

         v.arbitrateCount := r.arbitrateCount + 1;
         if (r.arbitrateCount = BSA_BUFFERS_G-1) then
            v.arbitrateCount  := r.arbitrateCount;
            v.arbitrateActive := '0';
            v.arbitrateDone   := '1';
         end if;
      end if;

      -- Once all entries are in FIFO, reset accumulations of all buffers with bsaAvgDone at once.
      if (r.arbitrateDone = '1') then
         for b in BSA_BUFFERS_G-1 downto 0 loop
            if (r.timingMessage.bsaAvgDone(b) = '1') then
               v.bsaBuffers(b).entry.accumulations := (others => (others => '0'));
            end if;
         end loop;
      end if;

      ----------------------------------------------------------------------------------------------
      -- AXI4 Stage - Read entries from FIFO and write to RAM on AXI4 bus
      ----------------------------------------------------------------------------------------------

      -- default bus outputs
      v.axiWriteMaster.awid       := (others => '0');
      v.axiWriteMaster.awlen      := "00000010";  -- Burst size = 3
      v.axiWriteMaster.awsize     := "110";       -- 64 byte data bus
      v.axiWriteMaster.awburst    := "01";        -- Burst type = "INCR"
      v.axiWriteMaster.awlock     := (others => '0');
      v.axiWriteMaster.awprot     := (others => '0');
      v.axiWriteMaster.awcache    := "1111";      -- Write-back Read and Write-allocate      
      v.axiWriteMaster.awqos      := (others => '0');
      v.axiWriteMaster.bready     := '1';
      v.axiWriteMaster.wstrb      := AXI_WRSTB_NOM_C;
      v.axiWriteMaster.awaddr(32) := r.ramAddr32;

      -- Clear valids upon ready response
      if axiWriteSlave.awready = '1' then
         v.axiWriteMaster.awvalid := '0';
      end if;
      if axiWriteSlave.wready = '1' then
         v.axiWriteMaster.wvalid := '0';
         v.axiWriteMaster.wlast  := '0';
      end if;

      v.fifoRdEn := '0';

      b3 := conv_integer(r.axiBuffer);
      case (r.axiState) is
         when WAIT_FIFO_ENTRY_S =>
            -- If there is data and no active AXI txn, then read it out of the FIFO and start a new txn
            if (fifoValid = '1' and v.axiWriteMaster.awvalid = '0' and v.axiWriteMaster.wvalid = '0') then
               v.axiState      := ADDR_S;
               v.axiBurstCount := (others => '0');
               v.fifoRdEn      := '1';

               v.axiShiftReg            := fifoRdData(BSA_BUFFER_ENTRY_BITS_C-1 downto 0);
               v.axiBuffer              := fifoRdData(FIFO_WIDTH_C-1 downto FIFO_WIDTH_C-6);
               v.axiWriteMaster.awvalid := '0';
            end if;

         when ADDR_S =>
            v.axiWriteMaster.awaddr(31 downto 0) := r.bsaBuffers(b3).lastEntry + BSA_BUFFER_ENTRY_INCREMENT_C;
            if (r.bsaBuffers(b3).lastEntry = r.bsaBuffers(b3).endAddr - BSA_BUFFER_ENTRY_INCREMENT_C) then
               v.axiWriteMaster.awaddr(31 downto 0) := r.bsaBuffers(b3).startAddr;
            end if;
            v.axiWriteMaster.awvalid := '1';
            v.axiState               := DATA_S;

         when DATA_S =>
            -- put next 512 bits on the wr data bus and increment count
            if (v.axiWriteMaster.wvalid = '0') then
               v.axiWriteMaster.wdata(511 downto 0) := r.axiShiftReg(511 downto 0);
               v.axiWriteMaster.wvalid              := '1';
               v.axiShiftReg                        := slvZero(512) & r.axiShiftReg(BSA_BUFFER_ENTRY_BITS_C-1 downto 512);
               v.axiBurstCount                      := r.axiBurstCount + 1;
               if (r.axiBurstCount = 1) then
                  -- count 2 (3rd burst) is last burst
                  v.axiWriteMaster.wlast := '1';
                  v.axiWriteMaster.wstrb := AXI_WRSTB_LAST_C;
                  v.axiState             := RESP_S;
               end if;
            end if;

         when RESP_S =>
            -- When bvalid resp comes back, update lastEntry and firstEntry for the buffer
            if (axiWriteSlave.bvalid = '1') then
               v.axiState                 := WAIT_FIFO_ENTRY_S;
               v.bsaBuffers(b3).lastEntry := r.axiWriteMaster.awaddr(31 downto 0);
               if (v.bsaBuffers(b3).lastEntry = r.bsaBuffers(b3).firstEntry) then
                  v.bsaBuffers(b3).firstEntry := r.bsaBuffers(b3).firstEntry + BSA_BUFFER_ENTRY_INCREMENT_C;
               end if;
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



         -- This should lay out the currently building bsa entry with the same struct
         -- as seen when written to ram
         -- Might not ever use this but useful for debugging I think
--          for j in 0 to 31 loop
--             axiSlaveRegisterR(bsaAddr(i, j), 0, r.bsaBuffers(i).entry.accumulations(j));
--          end loop;
--          axiSlaveRegisterR(bsaAddr(i, 32), 0, r.bsaBuffers(i).entry.count);
--          axiSlaveRegisterR(bsaAddr(i, 33), 0, r.bsaBuffers(i).entry.firstPulseId(31 downto 0));
--          axiSlaveRegisterR(bsaAddr(i, 34), 0, r.bsaBuffers(i).entry.firstPulseId(63 downto 32));
--          axiSlaveRegisterR(bsaAddr(i, 35), 0, r.bsaBuffers(i).entry.lastPulseId(31 downto 0));
--          axiSlaveRegisterR(bsaAddr(i, 36), 0, r.bsaBuffers(i).entry.lastPulseId(63 downto 32));

         -- Buffer entry tracking follows (these are important)
         axiSlaveRegisterW(i, "000000", 0, v.bsaBuffers(i).startAddr);
         axiSlaveRegisterW(i, "000100", 0, v.bsaBuffers(i).endAddr);
         axiSlaveRegisterR(i, "001000", 0, r.bsaBuffers(i).timeStamp(31 downto 0));
         axiSlaveRegisterR(i, "001100", 0, r.bsaBuffers(i).timeStamp(63 downto 32));
--         axiSlaveRegisterR(i, "010000", 0, r.bsaBuffers(i).nextEntry);
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
