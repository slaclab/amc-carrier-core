-------------------------------------------------------------------------------
-- Title      : Memory Access Protocol (MAP) Protocol: https://confluence.slac.stanford.edu/x/dBmVD
-------------------------------------------------------------------------------
-- File       : SsiAxiMaster.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-- Block for Register protocol.
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
use surf.AxiPkg.all;
use surf.AxiDmaPkg.all;
use surf.AxiLitePkg.all;

entity SsiAxiMaster is
   generic (
      -- General Config
      TPD_G         : time                  := 1 ns;
      PIPE_STAGES_G : natural range 0 to 16 := 0;

      -- FIFO Config
      SLAVE_READY_EN_G    : boolean                    := true;
      MEMORY_TYPE_G       : string                     := "block";
      GEN_SYNC_FIFO_G     : boolean                    := false;
      FIFO_ADDR_WIDTH_G   : integer range 4 to 48      := 9;
      FIFO_PAUSE_THRESH_G : integer range 1 to (2**24) := 2**8;

      -- AXI IO Config
      AXI_STREAM_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16);  --AXI_STREAM_CONFIG_INIT_C;
      AXI_BUS_CONFIG_G    : AxiConfigType       := (ADDR_WIDTH_C => 33, DATA_BYTES_C => 4, ID_BITS_C => 1, LEN_BITS_C => 8);  --AXI_CONFIG_INIT_C;
      AXI_READ_EN_G       : boolean             := true;
      AXI_WRITE_EN_G      : boolean             := false);
   port (

      -- Streaming Slave (Rx) Interface (sAxisClk domain) 
      sAxisClk    : in  sl;
      sAxisRst    : in  sl := '0';
      sAxisMaster : in  AxiStreamMasterType;
      sAxisSlave  : out AxiStreamSlaveType;
      sAxisCtrl   : out AxiStreamCtrlType;

      -- Streaming Master (Tx) Data Interface (mAxisClk domain)
      mAxisClk    : in  sl;
      mAxisRst    : in  sl := '0';
      mAxisMaster : out AxiStreamMasterType;
      mAxisSlave  : in  AxiStreamSlaveType;

      -- AXI  Bus (axiClk domain)
      axiClk          : in  sl;
      axiRst          : in  sl;
      mAxiWriteMaster : out AxiWriteMasterType;
      mAxiWriteSlave  : in  AxiWriteSlaveType;
      mAxiReadMaster  : out AxiReadMasterType;
      mAxiReadSlave   : in  AxiReadSlaveType
      );

end SsiAxiMaster;

architecture rtl of SsiAxiMaster is

   -- Configuration in internal AxiStreams between FIFOs and AxiDma blocks
   -- Could maybe be TKEEP_FIXED_C
   constant INTERNAL_AXIS_CONFIG_C : AxiStreamConfigType :=
      ssiAxiStreamConfig(AXI_BUS_CONFIG_G.DATA_BYTES_C, TKEEP_COMP_C);

   -- Internal Fifo Streams
   signal sFifoAxisMaster : AxiStreamMasterType;
   signal sFifoAxisSlave  : AxiStreamSlaveType;
   signal mFifoAxisMaster : AxiStreamMasterType;
   signal mFifoAxisSlave  : AxiStreamSlaveType;
   signal mFifoAxisCtrl   : AxiStreamCtrlType;

   -- Dma Req/Ack signals
   signal rdDmaReq : AxiReadDmaReqType;
   signal rdDmaAck : AxiReadDmaAckType;
   signal wrDmaReq : AxiWriteDmaReqType;
   signal wrDmaAck : AxiWriteDmaAckType;

   -- Dma Stream signals
   signal wrDmaAxisMaster : AxiStreamMasterType;
   signal wrDmaAxisSlave  : AxiStreamSlaveType;
   signal rdDmaAxisMaster : AxiStreamMasterType;
   signal rdDmaAxisSlave  : AxiStreamSlaveType;


   type StateType is (IDLE_S, SIZE_S, ADDR_S, WRITE_S, READ_S);

   type RegType is record
      state           : StateType;
      gotTLast        : sl;
      gotBlank        : sl;
      rdDmaReq        : AxiReadDmaReqType;
      wrDmaReq        : AxiWriteDmaReqType;
      rdDmaAxisSlave  : AxiStreamSlaveType;
      wrDmaAxisMaster : AxiStreamMasterType;
      sFifoAxisSlave  : AxiStreamSlaveType;
      mFifoAxisMaster : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state           => IDLE_S,
      gotBlank        => '0',
      gotTLast        => '0',
      rdDmaReq        => AXI_READ_DMA_REQ_INIT_C,
      wrDmaReq        => AXI_WRITE_DMA_REQ_INIT_C,
      rdDmaAxisSlave  => AXI_STREAM_SLAVE_INIT_C,
      wrDmaAxisMaster => axiStreamMasterInit(INTERNAL_AXIS_CONFIG_C),
      sFifoAxisSlave  => AXI_STREAM_SLAVE_INIT_C,
      mFifoAxisMaster => axiStreamMasterInit(INTERNAL_AXIS_CONFIG_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   -- Assertions
   -- AXI_BUS_CONFIG_G.DATA_BYTES_C must be 4 (or 8?)

   ----------------------------------
   -- Input FIFO 
   ----------------------------------
   SlaveAxiStreamFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => PIPE_STAGES_G,
         SLAVE_READY_EN_G    => SLAVE_READY_EN_G,
         VALID_THOLD_G       => 1,      -- Must have entire frame
         MEMORY_TYPE_G       => MEMORY_TYPE_G,
         GEN_SYNC_FIFO_G     => GEN_SYNC_FIFO_G,
         FIFO_ADDR_WIDTH_G   => FIFO_ADDR_WIDTH_G,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => FIFO_PAUSE_THRESH_G,
         SLAVE_AXI_CONFIG_G  => AXI_STREAM_CONFIG_G,
         MASTER_AXI_CONFIG_G => INTERNAL_AXIS_CONFIG_C)
      port map (
         sAxisClk    => sAxisClk,
         sAxisRst    => sAxisRst,
         sAxisMaster => sAxisMaster,
         sAxisSlave  => sAxisSlave,
         sAxisCtrl   => sAxisCtrl,
         mAxisClk    => axiClk,
         mAxisRst    => axiRst,
         mAxisMaster => sFifoAxisMaster,
         mAxisSlave  => sFifoAxisSlave);

   ----------------------------------
   -- Output FIFO 
   ----------------------------------
   MasterAxiStreamFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => PIPE_STAGES_G,
         SLAVE_READY_EN_G    => true,   -- Use ready and not ctrl
         VALID_THOLD_G       => 1,
         MEMORY_TYPE_G       => MEMORY_TYPE_G,
         GEN_SYNC_FIFO_G     => GEN_SYNC_FIFO_G,
         FIFO_ADDR_WIDTH_G   => FIFO_ADDR_WIDTH_G,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => FIFO_PAUSE_THRESH_G,
         SLAVE_AXI_CONFIG_G  => INTERNAL_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXI_STREAM_CONFIG_G)
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => mFifoAxisMaster,
         sAxisSlave  => mFifoAxisSlave,
         sAxisCtrl   => mFifoAxisCtrl,
         mAxisClk    => mAxisClk,
         mAxisRst    => mAxisRst,
         mAxisMaster => mAxisMaster,
         mAxisSlave  => mAxisSlave);


   AXI_READ_ENABLED : if (AXI_READ_EN_G) generate
      U_AxiStreamDmaRead_1 : entity surf.AxiStreamDmaRead
         generic map (
            TPD_G           => TPD_G,
            AXIS_READY_EN_G => true,
            AXIS_CONFIG_G   => INTERNAL_AXIS_CONFIG_C,
            AXI_CONFIG_G    => AXI_BUS_CONFIG_G,
            AXI_BURST_G     => "01",                  -- INCR
            AXI_CACHE_G     => "1111")                -- Double check this
         port map (
            axiClk        => axiClk,                  -- [in]
            axiRst        => axiRst,                  -- [in]
            dmaReq        => rdDmaReq,                -- [in]
            dmaAck        => rdDmaAck,                -- [out]
            axisMaster    => rdDmaAxisMaster,         -- [out]
            axisSlave     => rdDmaAxisSlave,          -- [in]
            axisCtrl      => AXI_STREAM_CTRL_INIT_C,  -- [in]
            axiReadMaster => mAxiReadMaster,          -- [out]
            axiReadSlave  => mAxiReadSlave);          -- [in]
   end generate AXI_READ_ENABLED;

   AXI_READ_DISABLED : if (not AXI_READ_EN_G) generate
      rdDmaAck.done       <= '1';
      rdDmaAck.readError  <= '1';
      rdDmaAck.errorValue <= AXI_RESP_SLVERR_C;
      rdDmaAxisMaster     <= AXI_STREAM_MASTER_INIT_C;
      mAxiReadMaster      <= AXI_READ_MASTER_INIT_C;
   end generate AXI_READ_DISABLED;

   AXI_WRITE_ENABLED : if (AXI_WRITE_EN_G) generate
      U_AxiStreamDmaWrite_1 : entity surf.AxiStreamDmaWrite
         generic map (
            TPD_G          => TPD_G,
            AXI_READY_EN_G => true,
            AXIS_CONFIG_G  => INTERNAL_AXIS_CONFIG_C,
            AXI_CONFIG_G   => AXI_BUS_CONFIG_G,
            AXI_BURST_G    => "01",
            AXI_CACHE_G    => "1111")
         port map (
            axiClk         => axiClk,           -- [in]
            axiRst         => axiRst,           -- [in]
            dmaReq         => wrDmaReq,         -- [in]
            dmaAck         => wrDmaAck,         -- [out]
            axisMaster     => wrDmaAxisMaster,  -- [in]
            axisSlave      => wrDmaAxisSlave,   -- [out]
            axiWriteMaster => mAxiWriteMaster,  -- [out]
            axiWriteSlave  => mAxiWriteSlave,   -- [in]
            axiWriteCtrl   => open);            -- [in]
   end generate AXI_WRITE_ENABLED;

   AXI_WRITE_DISABLED : if (not AXI_WRITE_EN_G) generate
      wrDmaAck.done       <= '1';
      wrDmaAck.size       <= (others => '0');
      wrDmaAck.overflow   <= '0';
      wrDmaAck.writeError <= '1';
      wrDmaAck.errorValue <= AXI_RESP_SLVERR_C;
      wrDmaAxisSlave      <= AXI_STREAM_SLAVE_FORCE_C;
      mAxiWriteMaster     <= AXI_WRITE_MASTER_INIT_C;
   end generate AXI_WRITE_DISABLED;

   -------------------------------------
   -- Master State Machine
   -------------------------------------
   comb : process (axiRst, mFifoAxisSlave, r, rdDmaAck, rdDmaAxisMaster, sFifoAxisMaster, wrDmaAck,
                   wrDmaAxisSlave) is
      variable v : RegType;
   begin
      v := r;

      -- By default, don't read from input fifo or rdDma
      v.sFifoAxisSlave.tReady := '0';
      v.rdDmaAxisSlave.tReady := '0';

      -- Auto clear master tValids on slave tReadys
      if (mFifoAxisSlave.tReady = '1') then
         v.mFifoAxisMaster.tValid := '0';
      end if;

      if (wrDmaAxisSlave.tReady = '1') then
         v.wrDmaAxisMaster.tValid := '0';
      end if;

      -- State machine
      case r.state is

         -- Idle
         when IDLE_S =>
            v.gotTLast := '0';
            v.rdDmaReq := AXI_READ_DMA_REQ_INIT_C;
            v.wrDmaReq := AXI_WRITE_DMA_REQ_INIT_C;

            -- Frame is starting, echo word (TID)
            if (sFifoAxisMaster.tValid = '1' and v.mFifoAxisMaster.tValid = '0') then
               v.sFifoAxisSlave.tReady := '1';
               v.mFifoAxisMaster       := sFifoAxisMaster;

               if (AXI_BUS_CONFIG_G.DATA_BYTES_C = 16) then
                  v.mFifoAxisMaster.tLast         := '0';  -- Hold off tlast
                  v.wrDmaReq.maxSize(31 downto 2) := sFifoAxisMaster.tData(93 downto 64);
                  v.rdDmaReq.size(31 downto 2)    := sFifoAxisMaster.tData(93 downto 64);
                  v.wrDmaReq.address(32 downto 2) := sFifoAxisMaster.tData(126 downto 96);
                  v.rdDmaReq.address(32 downto 2) := sFifoAxisMaster.tData(126 downto 96);
                  if (sFifoAxisMaster.tData(127) = '0') then
                     v.rdDmaReq.request := '1';
                     v.state            := READ_S;
                  else
                     v.wrDmaReq.request := '1';
                     v.state            := WRITE_S;
                  end if;
               else
                  v.gotBlank := '1';
                  if (r.gotBlank = '1') then
                     v.state    := SIZE_S;
                     v.gotBlank := '0';
                  end if;

                  -- Guard against early frame termination
                  if (sFifoAxisMaster.tLast = '1') then
                     v.state := IDLE_S;
                  end if;
               end if;

            end if;


         when SIZE_S =>
            -- Accept next word when ready and echo (SIZE)
            if (sFifoAxisMaster.tValid = '1' and v.mFifoAxisMaster.tValid = '0') then
               v.sFifoAxisSlave.tReady := '1';
               v.mFifoAxisMaster       := sFifoAxisMaster;

               -- Grab size
               v.wrDmaReq.maxSize(31 downto 2) := sFifoAxisMaster.tData(29 downto 0);
               v.rdDmaReq.size(31 downto 2)    := sFifoAxisMaster.tData(29 downto 0);
               v.state                         := ADDR_S;

               -- Guard against early frame termination
               if sFifoAxisMaster.tLast = '1' then
                  v.state := IDLE_S;
               end if;
            end if;


         when ADDR_S =>
            -- Accept next word when ready and echo
            if (sFifoAxisMaster.tValid = '1' and v.mFifoAxisMaster.tValid = '0') then
               v.sFifoAxisSlave.tReady := '1';
               v.mFifoAxisMaster       := sFifoAxisMaster;
               v.mFifoAxisMaster.tLast := '0';  -- Suppress tLast

               -- Grab Address
               v.wrDmaReq.address(32 downto 2) := sFifoAxisMaster.tData(30 downto 0);
               v.rdDmaReq.address(32 downto 2) := sFifoAxisMaster.tData(30 downto 0);

               if (sFifoAxisMaster.tData(31) = '0') then
                  if (sFifoAxisMaster.tLast = '1') then  -- Handle EOFE?
                     v.rdDmaReq.request := '1';
                     v.state            := READ_S;
--                   else
--                      v.state := BURN_S;
                  end if;
               else
                  v.wrDmaReq.request := '1';
                  v.state            := WRITE_S;
               end if;
            end if;

         when READ_S =>
            -- Accept read word when ready and push to output fifo
            if (rdDmaAxisMaster.tValid = '1' and v.mFifoAxisMaster.tValid = '0') then
               v.rdDmaAxisSlave.tReady := '1';
               v.mFifoAxisMaster       := rdDmaAxisMaster;
               v.mFifoAxisMaster.tLast := '0';              -- Suppress tLast
               v.mFifoAxisMaster.tUser := (others => '0');  -- No tUser
               v.mFifoAxisMaster.tKeep := genTKeep(INTERNAL_AXIS_CONFIG_C.TDATA_BYTES_C);  -- tLast might have smaller tkeep but override
            end if;

            -- Write a tail word to output fifo when rdDma is done
            if (rdDmaAck.done = '1' and v.mFifoAxisMaster.tValid = '0') then
               -- Tail
               v.mFifoAxisMaster.tValid            := '1';
               v.mFifoAxisMaster.tLast             := '1';
               v.mFifoAxisMaster.tData             := (others => '0');
               v.mFifoAxisMaster.tData(0)          := rdDmaAck.readError;
               v.mFifoAxisMaster.tData(2 downto 1) := rdDmaAck.errorValue;
               v.rdDmaReq.request                  := '0';
               v.state                             := IDLE_S;
            end if;

         when WRITE_S =>
            -- Accpet input word when ready and push to wrDma
            if (sFifoAxisMaster.tValid = '1' and v.wrDmaAxisMaster.tValid = '0') then
               v.sFifoAxisSlave.tReady := '1';
               v.wrDmaAxisMaster       := sFifoAxisMaster;
               v.wrDmaAxisMaster.tUser := (others => '0');
               v.wrDmaAxisMaster.tKeep := genTKeep(4);

               -- Last txn into wrDma must have proper tKeep
               -- Currently only allow 32-bit word sizes, so not a concern
               if (sFifoAxisMaster.tLast = '1') then
                  v.gotTLast := '1';
--                   if (r.wrDmaReq.maxSize(1 downto 0) = 0) then
--                      v.wrDmaAxisMaster.tKeep := genTKeep(conv_integer(r.wrDmaReq.maxSize(1 downto 0)));
--                   end if;
               end if;
            end if;

            -- Write a tail word to output fifo when wrDma is done
            if (wrDmaAck.done = '1' and v.mFifoAxisMaster.tValid = '0' and r.gotTLast = '1') then
               -- Tail
               v.mFifoAxisMaster.tValid            := '1';
               v.mFifoAxisMaster.tLast             := '1';
               v.mFifoAxisMaster.tData(0)          := wrDmaAck.writeError;
               v.mFifoAxisMaster.tData(2 downto 1) := wrDmaAck.errorValue;
               v.mFifoAxisMaster.tData(3)          := wrDmaAck.overflow;
               v.wrDmaReq.request                  := '0';
               v.state                             := IDLE_S;
            end if;

         when others =>
            v.state := IDLE_S;

      end case;

      -- Combinatorial outputs before the reset
      rdDmaAxisSlave <= v.rdDmaAxisSlave;
      sFifoAxisSlave <= v.sFifoAxisSlave;

      -- Reset
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Registered Outputs
      rdDmaReq        <= r.rdDmaReq;
      wrDmaReq        <= r.wrDmaReq;
      wrDmaAxisMaster <= r.wrDmaAxisMaster;
      mFifoAxisMaster <= r.mFifoAxisMaster;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
