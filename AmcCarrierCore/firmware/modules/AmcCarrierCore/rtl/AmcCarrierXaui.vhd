-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierXaui.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-07-10
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.XauiPkg.all;

entity AmcCarrierXaui is
   generic (
      TPD_G : time := 1 ns);
   port (
      axiClk             : in  sl;
      axiRst             : in  sl;
      -- Master AXI-Lite Interface
      mAxiReadMaster     : out AxiLiteReadMasterType;
      mAxiReadSlave      : in  AxiLiteReadSlaveType;
      mAxiWriteMaster    : out AxiLiteWriteMasterType;
      mAxiWriteSlave     : in  AxiLiteWriteSlaveType;
      -- Slave AXI-Lite Interface
      xauiAxiReadMaster  : in  AxiLiteReadMasterType;
      xauiAxiReadSlave   : out AxiLiteReadSlaveType;
      xauiAxiWriteMaster : in  AxiLiteWriteMasterType;
      xauiAxiWriteSlave  : out AxiLiteWriteSlaveType;
      -- DDR AXI Streaming Interface
      obDdrMaster        : in  AxiStreamMasterType;
      obDdrSlave         : out AxiStreamSlaveType;
      ibDdrMaster        : out AxiStreamMasterType;
      ibDdrSlave         : in  AxiStreamSlaveType;
      -- Boot Prom AXI Streaming Interface (Optional)
      obPromMaster       : in  AxiStreamMasterType;
      obPromSlave        : out AxiStreamSlaveType;
      ibPromMaster       : out AxiStreamMasterType;
      ibPromSlave        : in  AxiStreamSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- XAUI Ports
      xauiRxP            : in  slv(3 downto 0);
      xauiRxN            : in  slv(3 downto 0);
      xauiTxP            : out slv(3 downto 0);
      xauiTxN            : out slv(3 downto 0);
      xauiClkP           : in  sl;
      xauiClkN           : in  sl);  
end AmcCarrierXaui;

architecture mapping of AmcCarrierXaui is

   signal dmaIbMaster : AxiStreamMasterType;
   signal dmaIbSlave  : AxiStreamSlaveType;
   signal dmaObMaster : AxiStreamMasterType;
   signal dmaObSlave  : AxiStreamSlaveType;

begin

   ----------------------
   -- 10 GigE XAUI Module
   ----------------------
   XauiGthUltraScaleWrapper_Inst : entity work.XauiGthUltraScaleWrapper
      generic map (
         TPD_G         => TPD_G,
         -- AXI Streaming Configurations
         AXIS_CONFIG_G => ssiAxiStreamConfig(8))  
      port map (
         -- Streaming DMA Interface 
         dmaClk             => axiClk,
         dmaRst             => axiRst,
         dmaIbMaster        => dmaIbMaster,
         dmaIbSlave         => dmaIbSlave,
         dmaObMaster        => dmaObMaster,
         dmaObSlave         => dmaObSlave,
         -- Slave AXI-Lite Interface 
         axiLiteClk         => axiClk,
         axiLiteRst         => axiRst,
         axiLiteReadMaster  => xauiAxiReadMaster,
         axiLiteReadSlave   => xauiAxiReadSlave,
         axiLiteWriteMaster => xauiAxiWriteMaster,
         axiLiteWriteSlave  => xauiAxiWriteSlave,
         -- MGT Clock Port (156.25 MHz)
         gtClkP             => xauiClkP,
         gtClkN             => xauiClkN,
         -- MGT Ports
         gtTxP              => xauiTxP,
         gtTxN              => xauiTxN,
         gtRxP              => xauiRxP,
         gtRxN              => xauiRxN);  

   ----------------------------
   -- Loopback the DMA buses
   ----------------------------
   RawEthLoopBack_Inst : entity work.RawEthLoopBack
      generic map (
         TPD_G => TPD_G)
      port map (
         clk         => axiClk,
         rst         => axiRst,
         sAxisMaster => dmaIbMaster,
         sAxisSlave  => dmaIbSlave,
         mAxisMaster => dmaObMaster,
         mAxisSlave  => dmaObSlave);  

   -- Place holder for future development
   mAxiReadMaster  <= AXI_LITE_READ_MASTER_INIT_C;
   mAxiWriteMaster <= AXI_LITE_WRITE_MASTER_INIT_C;
   obDdrSlave      <= AXI_STREAM_SLAVE_FORCE_C;
   ibDdrMaster     <= AXI_STREAM_MASTER_INIT_C;
   obPromSlave     <= AXI_STREAM_SLAVE_FORCE_C;
   ibPromMaster    <= AXI_STREAM_MASTER_INIT_C;
   
end mapping;
