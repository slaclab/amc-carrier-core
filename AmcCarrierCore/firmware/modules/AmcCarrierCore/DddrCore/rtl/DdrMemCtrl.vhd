-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : DdrMemCtrl.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2015-08-06
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
use work.AxiLitePkg.all;
use work.AxiPkg.all;

entity DdrMemCtrl is
   generic (
      TPD_G         : time    := 1 ns;
      EXT_MEM_G     : boolean := true;
      FSBL_G        : boolean := false;
      SIM_SPEEDUP_G : boolean := false);
   port (
      -- AXI-Lite Interface
      axiClk             : in  sl;
      axiRst             : in  sl;
      axiLiteReadMaster  : in  AxiLiteReadMasterType;
      axiLiteReadSlave   : out AxiLiteReadSlaveType;
      axiLiteWriteMaster : in  AxiLiteWriteMasterType;
      axiLiteWriteSlave  : out AxiLiteWriteSlaveType;
      memReady           : out sl;
      memError           : out sl;
      -- Diagnostic Snapshot
      debugClk           : in  sl;
      debugRst           : in  sl;
      debugIbMaster      : in  AxiStreamMasterType;
      debugIbSlave       : out AxiStreamSlaveType;
      -- Beam Synchronization (BSA)
      bsaClk             : in  sl;
      bsaRst             : in  sl;
      bsaIbMaster        : in  AxiStreamMasterType;
      bsaIbSlave         : out AxiStreamSlaveType;
      -- DDR Memory Interface
      ddrClk             : in  sl;
      ddrRst             : in  sl;
      ddrCalDone         : in  sl;
      ddrWriteMaster     : out AxiWriteMasterType;
      ddrWriteSlave      : in  AxiWriteSlaveType;
      ddrReadMaster      : out AxiReadMasterType;
      ddrReadSlave       : in  AxiReadSlaveType;
      -- AXI Streaming Interface to Ethernet
      obDdrMaster        : out AxiStreamMasterType;
      obDdrSlave         : in  AxiStreamSlaveType;
      ibDdrMaster        : in  AxiStreamMasterType;
      ibDdrSlave         : out AxiStreamSlaveType);
end DdrMemCtrl;

architecture mapping of DdrMemCtrl is

   constant EXT_MEM_AXI_C : AxiConfigType := (
      ADDR_WIDTH_C => 33,
      DATA_BYTES_C => 64,
      ID_BITS_C    => 4);
   constant INT_MEM_AXI_C : AxiConfigType := (
      ADDR_WIDTH_C => 20,
      DATA_BYTES_C => 64,
      ID_BITS_C    => 4);

   constant AXI_CONFIG_C : AxiConfigType                             := ite(EXT_MEM_G, EXT_MEM_AXI_C, INT_MEM_AXI_C);
   constant START_ADDR_C : slv(AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '0');
   constant STOP_ADDR_C  : slv(AXI_CONFIG_C.ADDR_WIDTH_C-1 downto 0) := (others => '1');
   
begin

   U_AxiMemTester : entity work.AxiMemTester
      generic map (
         TPD_G        => TPD_G,
         START_ADDR_G => START_ADDR_C,
         STOP_ADDR_G  => ite(SIM_SPEEDUP_G, toSlv(8191, AXI_CONFIG_C.ADDR_WIDTH_C), STOP_ADDR_C),
         AXI_CONFIG_G => AXI_CONFIG_C)
      port map (
         -- AXI-Lite Interface
         axiLiteClk         => axiClk,
         axiLiteRst         => axiRst,
         axiLiteReadMaster  => axiLiteReadMaster,
         axiLiteReadSlave   => axiLiteReadSlave,
         axiLiteWriteMaster => axiLiteWriteMaster,
         axiLiteWriteSlave  => axiLiteWriteSlave,
         memReady           => memReady,
         memError           => memError,
         -- DDR Memory Interface
         axiClk             => ddrClk,
         axiRst             => ddrRst,
         start              => ddrCalDone,
         axiWriteMaster     => ddrWriteMaster,
         axiWriteSlave      => ddrWriteSlave,
         axiReadMaster      => ddrReadMaster,
         axiReadSlave       => ddrReadSlave);

   FSBL_GEN : if (FSBL_G = true) generate

      -- Terminate the buses
      obDdrMaster  <= AXI_STREAM_MASTER_INIT_C;
      ibDdrSlave   <= AXI_STREAM_SLAVE_FORCE_C;
      debugIbSlave <= AXI_STREAM_SLAVE_FORCE_C;
      bsaIbSlave   <= AXI_STREAM_SLAVE_FORCE_C;
      
   end generate;

   NORMAL_GEN : if (FSBL_G = false) generate

      -- Place holder for future development
      obDdrMaster  <= AXI_STREAM_MASTER_INIT_C;
      ibDdrSlave   <= AXI_STREAM_SLAVE_FORCE_C;
      debugIbSlave <= AXI_STREAM_SLAVE_FORCE_C;
      bsaIbSlave   <= AXI_STREAM_SLAVE_FORCE_C;
      
   end generate;
   
end mapping;
