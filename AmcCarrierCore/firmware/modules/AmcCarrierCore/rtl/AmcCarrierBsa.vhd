-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsa.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-10-13
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
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;

entity AmcCarrierBsa is
   generic (
      TPD_G               : time                  := 1 ns;
      APP_TYPE_G          : AppType               := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G    : slv(1 downto 0)       := AXI_RESP_DECERR_C;
      BSA_BUFFERS_G       : integer range 1 to 64 := 32;
      DIAGNOSTIC_SIZE_G   : positive              := 1;
      DIAGNOSTIC_CONFIG_G : AxiStreamConfigType   := ssiAxiStreamConfig(4));
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;
      -- AXI4 Interface (axiClk domain)
      axiClk            : in  sl;
      axiRst            : in  sl;
      axiWriteMaster    : out AxiWriteMasterType;
      axiWriteSlave     : in  AxiWriteSlaveType;
      axiReadMaster     : out AxiReadMasterType;
      axiReadSlave      : in  AxiReadSlaveType;
      -- Ethernet Interface (axilClk domain)
      obBsaMaster       : in  AxiStreamMasterType;
      obBsaSlave        : out AxiStreamSlaveType;
      ibBsaMaster       : out AxiStreamMasterType;
      ibBsaSlave        : in  AxiStreamSlaveType;
      -- BSA Interface (bsaTimingClk domain)
      bsaTimingClk      : in  sl;
      bsaTimingRst      : in  sl;
      bsaTimingBus      : in  TimingBusType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Diagnostic Interface
      diagnosticClk     : in  sl;
      diagnosticRst     : in  sl;
      diagnosticBus     : in  DiagnosticBusType;
      diagnosticMasters : in  AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves  : out AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0));

end AmcCarrierBsa;

architecture mapping of AmcCarrierBsa is


begin

   --------------------------------------
   -- Place holder for future development
   --------------------------------------
   diagnosticSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);
   obBsaSlave       <= AXI_STREAM_SLAVE_FORCE_C;
   ibBsaMaster      <= AXI_STREAM_MASTER_INIT_C;


   AxiLiteEmpty_1: entity work.AxiLiteEmpty
      generic map (
         TPD_G           => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilClkRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);
   
   ------------------------------------------------------------------------------------------------
   -- Diagnostic Engine
   -- Create circular buffers in DDR Ram for dianostic data
   ------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- BSA buffers
   -------------------------------------------------------------------------------------------------
   
--    BsaBufferControl_1 : entity work.BsaBufferControl
--       generic map (
--          TPD_G         => TPD_G,
--          BSA_BUFFERS_G => 64)
--       port map (
--          axilClk         => axilClk,
--          axilRst         => axilRst,
--          axilReadMaster  => axilReadMaster,
--          axilReadSlave   => axilReadSlave,
--          axilWriteMaster => axilWriteMaster,
--          axilWriteSlave  => axilWriteSlave,
--          diagnosticClk   => diagnosticClk,
--          diagnosticRst   => diagnosticRst,
--          diagnosticBus   => diagnosticBus,
--          axiClk          => axiClk,
--          axiRst          => axiRst,
--          axiWriteMaster  => axiWriteMaster,
--          axiWriteSlave   => axiWriteSlave);
   axiWriteMaster <= AXI_WRITE_MASTER_INIT_C;
   axiReadMaster <= AXI_READ_MASTER_INIT_C;

   ------------------------------------------------------------------------------------------------
   -- DDR Engine
   -- Arbiter and DDR3 Controller
   ------------------------------------------------------------------------------------------------



end mapping;
