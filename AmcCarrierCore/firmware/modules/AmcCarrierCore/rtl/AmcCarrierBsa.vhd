-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierBsa.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-09-28
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

entity AmcCarrierBsa is
   generic (
      TPD_G               : time                := 1 ns;
      APP_TYPE_G          : AppType             := APP_NULL_TYPE_C;
      AXI_ERROR_RESP_G    : slv(1 downto 0)     := AXI_RESP_DECERR_C;
      DIAGNOSTIC_SIZE_G   : positive            := 1;
      DIAGNOSTIC_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(4));
   port (
      -- AXI-Lite Interface
      axilClk             : in  sl;
      axilRst             : in  sl;
      axilReadMaster      : in  AxiLiteReadMasterType;
      axilReadSlave       : out AxiLiteReadSlaveType;
      axilWriteMaster     : in  AxiLiteWriteMasterType;
      axilWriteSlave      : out AxiLiteWriteSlaveType;
      -- AXI4 Interface
      axiClk              : in  sl;
      axiRst              : in  sl;
      axiWriteMaster      : out AxiWriteMasterType;
      axiWriteSlave       : in  AxiWriteSlaveType;
      axiReadMaster       : out AxiReadMasterType;
      axiReadSlave        : in  AxiReadSlaveType;
      -- BSA Ethernet Interface (axilClk domain)
      obBsaMaster         : in  AxiStreamMasterType;
      obBsaSlave          : out AxiStreamSlaveType;
      ibBsaMaster         : out AxiStreamMasterType;
      ibBsaSlave          : in  AxiStreamSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Diagnostic Interface
      diagnosticClk       : in  sl;
      diagnosticRst       : in  sl;
      diagnosticValid     : in  sl;
      diagnosticTimeStamp : in  slv(63 downto 0);
      diagnosticMessage   : in  Slv32Array(31 downto 0);
      diagnosticMasters   : in  AxiStreamMasterArray(DIAGNOSTIC_SIZE_G-1 downto 0);
      diagnosticSlaves    : out AxiStreamSlaveArray(DIAGNOSTIC_SIZE_G-1 downto 0));

end AmcCarrierBsa;

architecture mapping of AmcCarrierBsa is


begin

   --------------------------------------
   -- Place holder for future development
   --------------------------------------
   diagnosticSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);
   obBsaSlave       <= AXI_STREAM_SLAVE_FORCE_C;
   ibBsaMaster      <= AXI_STREAM_MASTER_INIT_C;

   -------------------------------------------------------------------------------------------------
   -- AxiLiteCrossbar
   -------------------------------------------------------------------------------------------------
   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave);


    ------------------------------------------------------------------------------------------------
    -- Diagnostic Engine
    -- Create circular buffers in DDR Ram for dianostic data
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    -- BSA engine
    -- Manage BSA buffers
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    -- DDR Engine
    -- Arbiter and DDR3 Controller
    ------------------------------------------------------------------------------------------------



end mapping;
