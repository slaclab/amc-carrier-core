-------------------------------------------------------------------------------
-- File       : AmcCarrierPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Common AMC Carrier Core VHDL package
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

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

use work.TimingPkg.all;

package AmcCarrierPkg is

   ----------------
   -- Revision Log:
   ----------------
   -- 04/15/2016 (0x00000001): Initial Build
   -- 04/19/2016 (0x00000002): Added ETH status to BSI interface
   -- 04/19/2016 (0x00000003): Added 10 second WDT to ETH Link Up
   -- 04/19/2016 (0x00000004): In AmcCarrierEth, separating the RSSI's memory access and data paths 
   --                          from the ASYNC messaging and register access as a work around until 
   --                          AXIS packetizer (A.K.A. "chunker") supports interleaving of TDEST frames 
   -- 04/19/2016 (0x00000005): In AmcCarrierRegPkg, defaulting MPS Link node's XBAR configurations to XBAR_TIME_GEN_C 
   -- 04/21/2016 (0x00000006): Increased gtTxDiffCtrl from 0.95 Vppd to 1.08 Vppd
   -- 04/21/2016 (0x00000007): Added Ethernet Uptime counter in the BSI interface
   -- 07/08/2016 (0x00000008): Updated the I2C device configurations
   -- 09/01/2016 (0x00000009): Backing up to 1.2 TAG
   -- 12/05/2016 (0x0000000A): Adding more application types
   -- 03/02/2017 (0x0000000B): Migration to GIT
   -- 11/08/2017 (0x02000400): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.0.4
   -- 11/14/2017 (0x02000500): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.0.5
   -- 11/17/2017 (0x02000600): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.0.6
   -- 12/04/2017 (0x02000700): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.0.7
   -- 12/11/2017 (0x02000700): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.0.8
   -- 12/15/2017 (0x02010000): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.0
   -- 12/22/2017 (0x02010100): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.1
   -- 12/23/2017 (0x02010200): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.2
   -- 01/08/2018 (0x02010300): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.3
   -- 01/11/2018 (0x02010400): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.4
   -- 01/11/2018 (0x02010500): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.5
   -- 02/12/2018 (0x02010600): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.1.6
   -- 02/26/2018 (0x02020000): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.2.0
   -- 02/27/2018 (0x02020100): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.2.1
   -- 03/02/2018 (0x02020200): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.2.2
   -- 03/08/2018 (0x02020300): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.2.3
   -- 03/11/2018 (0x02020400): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.2.4
   -- 03/16/2018 (0x02030000): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.3.0
   -- 04/02/2018 (0x02030100): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.3.1
   -- 04/03/2018 (0x02030200): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.3.2
   -- 04/04/2018 (0x02030300): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.3.3
   -- 04/11/2018 (0x02030400): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.3.4
   -- 04/18/2018 (0x02040000): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.0 
   -- 04/21/2018 (0x02040100): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.1   
   -- 04/23/2018 (0x02040200): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.2
   -- 04/23/2018 (0x02040300): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.3
   -- 04/26/2018 (0x02040400): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.4
   -- 05/10/2018 (0x02040500): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.5
   -- 05/17/2018 (0x02040600): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.6
   -- 06/22/2018 (0x02040700): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.7
   -- 07/21/2018 (0x02040800): https://github.com/slaclab/amc-carrier-core/releases/tag/v2.4.8
   constant AMC_CARRIER_CORE_VERSION_C : slv(31 downto 0) := x"02_04_08_00";

   -----------------------------------------------------------
   -- Application: Configurations, Constants and Records Types
   -----------------------------------------------------------
   subtype AppType is slv(6 downto 0);  -- Max. Size is 7-bits

   constant APP_NULL_TYPE_C       : AppType := toSlv(0, AppType'length);
   constant APP_DEBUG_TYPE_C      : AppType := toSlv(1, AppType'length);
   constant APP_TIME_GEN_TYPE_C   : AppType := toSlv(10, AppType'length);  --Timing Generator with local reference
   constant APP_BCM_TYPE_C        : AppType := toSlv(11, AppType'length);
   constant APP_BLEN_TYPE_C       : AppType := toSlv(12, AppType'length);
   constant APP_LLRF_TYPE_C       : AppType := toSlv(13, AppType'length);
   constant APP_EXTREF_GEN_TYPE_C : AppType := toSlv(14, AppType'length);  --Timing Generator with external reference

   constant APP_BPM_STRIPLINE_TYPE_C : AppType := toSlv(100, AppType'length);
   constant APP_BPM_CAVITY_TYPE_C    : AppType := toSlv(101, AppType'length);

   constant APP_MPS_24CH_TYPE_C : AppType := toSlv(120, AppType'length);
   constant APP_MPS_6CH_TYPE_C  : AppType := toSlv(121, AppType'length);

   -------------------------------------
   -- Common Platform: General Constants
   -------------------------------------

   constant TIMING_MODE_186MHZ_C : boolean := true;  -- true = LCLS-II timing
   constant TIMING_MODE_119MHZ_C : boolean := ite(TIMING_MODE_186MHZ_C, false, true);

   constant AXI_CLK_FREQ_C   : real := 156.25E+6;             -- In units of Hz
   constant AXI_CLK_PERIOD_C : real := (1.0/AXI_CLK_FREQ_C);  -- In units of seconds      

   constant APP_REG_BASE_ADDR_C : slv(31 downto 0) := x"80000000";

   -------------------------------------------------------------------------------------------------
   -- Ethernet stream configurations
   -------------------------------------------------------------------------------------------------
   constant ETH_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(8, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8);  -- Use 8 tDest bits

   -- BSA stream indicies
   constant BSA_MEM_AXIS_INDEX_C             : integer := 0;
   constant BSA_BSA_STATUS_AXIS_INDEX_C      : integer := 1;
   constant BSA_WAVEFORM_STATUS_AXIS_INDEX_C : integer := 2;
   constant BSA_WAVEFORM_DATA_AXIS_INDEX_C   : integer := 3;

   -------------------------------------------------------------------------------------------------
   -- BSA configuration
   -------------------------------------------------------------------------------------------------
   constant BSA_BUFFERS_C            : integer := 64;
   constant BSA_DIAGNOSTIC_OUTPUTS_C : integer := 31;
   constant BSA_STREAM_BYTE_WIDTH_C  : integer := 8;
   constant BSA_BURST_BYTES_C        : integer := 2048;  -- Bytes in each burst of BSA data

   constant WAVEFORM_STREAMS_C     : integer := 8;
   constant WAVEFORM_TRIGGER_BIT_C : integer := 2;

   subtype WaveformMasterType is AxiStreamMasterArray(3 downto 0);
   type WaveformMasterArrayType is array (1 downto 0) of WaveformMasterType;

   constant WAVEFORM_MASTER_ARRAY_INIT_C : WaveformMasterArrayType := (others => (others => AXI_STREAM_MASTER_INIT_C));

   type WaveformSlaveRecType is record
      slave : AxiStreamSlaveType;
      ctrl  : AxiStreamCtrlType;
   end record;
   type WaveformSlaveType is array (3 downto 0) of WaveformSlaveRecType;
   type WaveformSlaveArrayType is array (1 downto 0) of WaveformSlaveType;

   constant WAVEFORM_SLAVE_REC_INIT_C : WaveformSlaveRecType := (
      slave => AXI_STREAM_SLAVE_INIT_C,
      ctrl  => AXI_STREAM_CTRL_INIT_C);
   constant WAVEFORM_SLAVE_ARRAY_INIT_C : WaveformSlaveArrayType := (others => (others => WAVEFORM_SLAVE_REC_INIT_C));

   constant WAVEFORM_SLAVE_REC_FORCE_C : WaveformSlaveRecType := (
      slave => AXI_STREAM_SLAVE_FORCE_C,
      ctrl  => AXI_STREAM_CTRL_UNUSED_C);
   constant WAVEFORM_SLAVE_ARRAY_FORCE_C : WaveformSlaveArrayType := (others => (others => WAVEFORM_SLAVE_REC_FORCE_C));

   ---------------------------------------------------
   -- BSI: Configurations, Constants and Records Types
   ---------------------------------------------------
   constant BSI_MAC_SIZE_C : natural := 4;

   type BsiBusType is record
      slotNumber : slv(7 downto 0);
      crateId    : slv(15 downto 0);
      macAddress : Slv48Array(BSI_MAC_SIZE_C-1 downto 1);  --  big-Endian format 
   end record;
   constant BSI_BUS_INIT_C : BsiBusType := (
      slotNumber => x"00",
      crateId    => x"0000",
      macAddress => (others => (others => '0')));

   type DiagnosticBusType is record
      strobe        : sl;
      data          : Slv32Array(31 downto 0);
      sevr          : Slv2Array (31 downto 0);  -- (0=NONE, 1=MINOR, 2=MAJOR, 3=INVALID)
      fixed         : slv (31 downto 0);        -- do not add/average (static)
      mpsIgnore     : slv (31 downto 0);        -- MPS ignores value
      timingMessage : TimingMessageType;
   end record;
   type DiagnosticBusArray is array (natural range <>) of DiagnosticBusType;
   constant DIAGNOSTIC_BUS_INIT_C : DiagnosticBusType := (
      strobe        => '0',
      data          => (others => (others => '0')),
      sevr          => (others => (others => '1')),
      fixed         => (others => '0'),
      mpsIgnore     => (others => '0'),
      timingMessage => TIMING_MESSAGE_INIT_C);

   constant DIAGNOSTIC_BUS_BITS_C : integer := 1 + 32*36 + TIMING_MESSAGE_BITS_C;

   function toSlv (b             : DiagnosticBusType) return slv;
   function toDiagnosticBus (vec : slv) return DiagnosticBusType;

end package AmcCarrierPkg;

package body AmcCarrierPkg is

   function toSlv (b : DiagnosticBusType) return slv is
      variable vector : slv(DIAGNOSTIC_BUS_BITS_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
   begin
      vector(TIMING_MESSAGE_BITS_C-1 downto 0) := toSlv(b.timingMessage);
      i                                        := TIMING_MESSAGE_BITS_C;
      for j in 0 to 31 loop
         assignSlv(i, vector, b.data (j));
         assignSlv(i, vector, b.sevr (j));
         assignSlv(i, vector, b.fixed (j));
         assignSlv(i, vector, b.mpsIgnore(j));
      end loop;
      assignSlv(i, vector, b.strobe);
      return vector;
   end function;

   function toDiagnosticBus (vec : slv) return DiagnosticBusType is
      variable b : DiagnosticBusType;
      variable i : integer := 0;
   begin
      b.timingMessage := toTimingMessageType(vec(TIMING_MESSAGE_BITS_C-1 downto 0));
      i               := TIMING_MESSAGE_BITS_C;
      for j in 0 to 31 loop
         assignRecord(i, vec, b.data (j));
         assignRecord(i, vec, b.sevr (j));
         assignRecord(i, vec, b.fixed (j));
         assignRecord(i, vec, b.mpsIgnore(j));
      end loop;
      assignRecord(i, vec, b.strobe);
      return b;
   end function;

end package body AmcCarrierPkg;
