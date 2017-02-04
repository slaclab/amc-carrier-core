-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : AmcCarrierSysReg.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2016-07-13
-- Platform   :
-- Standard   : VHDL'93/02
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.I2cPkg.all;
use work.AmcCarrierPkg.all;
use work.AmcCarrierRegPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierSysReg is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C;
      FSBL_G           : boolean         := false);
   port (
      -- Primary AXI-Lite Interface
      axilClk           : in    sl;
      axilRst           : in    sl;
      sAxilReadMasters  : in    AxiLiteReadMasterArray(1 downto 0);
      sAxilReadSlaves   : out   AxiLiteReadSlaveArray(1 downto 0);
      sAxilWriteMasters : in    AxiLiteWriteMasterArray(1 downto 0);
      sAxilWriteSlaves  : out   AxiLiteWriteSlaveArray(1 downto 0);
      -- Timing AXI-Lite Interface
      timingReadMaster  : out   AxiLiteReadMasterType;
      timingReadSlave   : in    AxiLiteReadSlaveType;
      timingWriteMaster : out   AxiLiteWriteMasterType;
      timingWriteSlave  : in    AxiLiteWriteSlaveType;
      -- BSA AXI-Lite Interface
      bsaReadMaster     : out   AxiLiteReadMasterType;
      bsaReadSlave      : in    AxiLiteReadSlaveType;
      bsaWriteMaster    : out   AxiLiteWriteMasterType;
      bsaWriteSlave     : in    AxiLiteWriteSlaveType;
      -- XAUI PHY AXI-Lite Interface
      xauiReadMaster    : out   AxiLiteReadMasterType;
      xauiReadSlave     : in    AxiLiteReadSlaveType;
      xauiWriteMaster   : out   AxiLiteWriteMasterType;
      xauiWriteSlave    : in    AxiLiteWriteSlaveType;
      -- DDR PHY AXI-Lite Interface
      ddrReadMaster     : out   AxiLiteReadMasterType;
      ddrReadSlave      : in    AxiLiteReadSlaveType;
      ddrWriteMaster    : out   AxiLiteWriteMasterType;
      ddrWriteSlave     : in    AxiLiteWriteSlaveType;
      ddrMemReady       : in    sl;
      ddrMemError       : in    sl;
      -- MPS PHY AXI-Lite Interface
      mpsReadMaster     : out   AxiLiteReadMasterType;
      mpsReadSlave      : in    AxiLiteReadSlaveType;
      mpsWriteMaster    : out   AxiLiteWriteMasterType;
      mpsWriteSlave     : in    AxiLiteWriteSlaveType;
      -- Local Configuration
      localMac          : out   slv(47 downto 0);
      localIp           : out   slv(31 downto 0);
      localAppId        : out   slv(15 downto 0);
      ethLinkUp         : in    sl := '0';
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface
      regReadMaster     : out   AxiLiteReadMasterType;
      regReadSlave      : in    AxiLiteReadSlaveType;
      regWriteMaster    : out   AxiLiteWriteMasterType;
      regWriteSlave     : in    AxiLiteWriteSlaveType;
      -- BSI Interface
      bsiBus            : out   bsiBusType;
      ----------------
      -- Core Ports --
      ----------------
      -- Crossbar Ports
      xBarSin           : out   slv(1 downto 0);
      xBarSout          : out   slv(1 downto 0);
      xBarConfig        : out   sl;
      xBarLoad          : out   sl;
      -- IPMC Ports
      ipmcScl           : inout sl;
      ipmcSda           : inout sl;
      -- Configuration PROM Ports
      calScl            : inout sl;
      calSda            : inout sl;
      -- Clock Cleaner Ports
      timingClkScl      : inout sl;
      timingClkSda      : inout sl;
      -- DDR3L SO-DIMM Ports
      ddrScl            : inout sl;
      ddrSda            : inout sl;
      -- SYSMON Ports
      vPIn              : in    sl;
      vNIn              : in    sl);
end AmcCarrierSysReg;

architecture mapping of AmcCarrierSysReg is

   -- FSBL Timeout Duration
   constant TIMEOUT_C : integer := integer(10.0 / AXI_CLK_PERIOD_C);

   constant NUM_AXI_MASTERS_C : natural := 14;

   constant VERSION_INDEX_C    : natural := 0;
   constant SYSMON_INDEX_C     : natural := 1;
   constant BOOT_MEM_INDEX_C   : natural := 2;
   constant XBAR_INDEX_C       : natural := 3;
   constant CONFIG_I2C_INDEX_C : natural := 4;
   constant CLK_I2C_INDEX_C    : natural := 5;
   constant DDR_I2C_INDEX_C    : natural := 6;
   constant IPMC_INDEX_C       : natural := 7;
   constant TIMING_INDEX_C     : natural := 8;
   constant BSA_INDEX_C        : natural := 9;
   constant XAUI_INDEX_C       : natural := 10;
   constant DDR_INDEX_C        : natural := 11;
   constant MPS_INDEX_C        : natural := 12;
   constant APP_INDEX_C        : natural := 13;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      VERSION_INDEX_C    => (
         baseAddr        => VERSION_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      SYSMON_INDEX_C     => (
         baseAddr        => SYSMON_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      BOOT_MEM_INDEX_C   => (
         baseAddr        => BOOT_MEM_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      XBAR_INDEX_C       => (
         baseAddr        => XBAR_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      CONFIG_I2C_INDEX_C => (
         baseAddr        => CONFIG_I2C_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      CLK_I2C_INDEX_C    => (
         baseAddr        => CLK_I2C_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      DDR_I2C_INDEX_C    => (
         baseAddr        => DDR_I2C_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      IPMC_INDEX_C       => (
         baseAddr        => IPMC_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      XAUI_INDEX_C       => (
         baseAddr        => XAUI_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      TIMING_INDEX_C     => (
         baseAddr        => TIMING_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      BSA_INDEX_C        => (
         baseAddr        => BSA_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      DDR_INDEX_C        => (
         baseAddr        => DDR_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      MPS_INDEX_C        => (
         baseAddr        => MPS_ADDR_C,
         addrBits        => 24,
         connectivity    => x"FFFF"),
      APP_INDEX_C        => (
         baseAddr        => APP_ADDR_C,
         addrBits        => 31,
         connectivity    => x"FFFF"));

   constant TIME_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 0) := (
      0             => MakeI2cAxiLiteDevType(
         i2cAddress => "1010100",
         dataSize   => 16,              -- in units of bits
         addrSize   => 16,              -- in units of bits
         endianness => '1'));           -- Big endian

   constant DDR_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 0) := (
      0              => MakeI2cAxiLiteDevType(
         i2cAddress  => "1010000",      -- SRD Memory (1010) (Lookup tool at www.micron.com/spd)
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness => '1'));           -- Big endian

   signal mAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal bootCsL  : sl;
   signal bootSck  : sl;
   signal bootMosi : sl;
   signal bootMiso : sl;
   signal di       : slv(3 downto 0);
   signal do       : slv(3 downto 0);

   signal axilRstL  : sl;
   signal bootRdy   : sl;
   signal bootArmed : sl;
   signal bootstart : sl;
   signal bootReq   : sl;
   signal bootAddr  : slv(31 downto 0);
   signal upTimeCnt : slv(31 downto 0);

begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk           => axilClk,
         axiClkRst        => axilRst,
         sAxiWriteMasters => sAxilWriteMasters,
         sAxiWriteSlaves  => sAxilWriteSlaves,
         sAxiReadMasters  => sAxilReadMasters,
         sAxiReadSlaves   => sAxilReadSlaves,
         mAxiWriteMasters => mAxilWriteMasters,
         mAxiWriteSlaves  => mAxilWriteSlaves,
         mAxiReadMasters  => mAxilReadMasters,
         mAxiReadSlaves   => mAxilReadSlaves);

   --------------------------
   -- AXI-Lite Version Module
   --------------------------
   U_Version : entity work.AxiVersion
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         CLK_PERIOD_G     => 6.4E-9,
         XIL_DEVICE_G     => "ULTRASCALE",
         EN_DEVICE_DNA_G  => true,
         EN_DS2411_G      => false,
         EN_ICAP_G        => false,
         AUTO_RELOAD_EN_G => false)
      port map (
         -- AXI-Lite Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         upTimeCnt      => upTimeCnt,
         userValues     => (others => AMC_CARRIER_CORE_VERSION_C),
         axiReadMaster  => mAxilReadMasters(VERSION_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(VERSION_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(VERSION_INDEX_C));

   bootRdy <= ddrMemReady and not(ddrMemError);

   process(axilClk)
   begin
      if rising_edge(axilClk) then
         -- Check for reset
         if axilRst = '1' then
            bootArmed <= '0' after TPD_G;
            bootstart <= '0' after TPD_G;
         else
            -- Reset the flag
            bootstart <= '0' after TPD_G;
            -- Check for boot request
            if bootReq = '1' then
               bootArmed <= '1' after TPD_G;
            -- Check if DDR passed and armed
            elsif (bootRdy = '1') and (bootArmed = '1') then
               -- Set the flag
               bootstart <= '1' after TPD_G;
               -- Reset the flag
               bootArmed <= '0' after TPD_G;
            end if;
         end if;
      end if;
   end process;

   U_Iprog : entity work.Iprog
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => "ULTRASCALE")
      port map (
         clk         => axilClk,
         rst         => axilRst,
         start       => bootstart,
         bootAddress => bootAddr);

   --------------------------
   -- AXI-Lite: SYSMON Module
   --------------------------
   U_SysMon : entity work.AmcCarrierSysMon
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- SYSMON Ports
         vPIn            => vPIn,
         vNIn            => vNIn,
         -- AXI-Lite Register Interface
         axilReadMaster  => mAxilReadMasters(SYSMON_INDEX_C),
         axilReadSlave   => mAxilReadSlaves(SYSMON_INDEX_C),
         axilWriteMaster => mAxilWriteMasters(SYSMON_INDEX_C),
         axilWriteSlave  => mAxilWriteSlaves(SYSMON_INDEX_C),
         -- Clocks and Resets
         axilClk         => axilClk,
         axilRst         => axilRst);

   ------------------------------
   -- AXI-Lite: Boot Flash Module
   ------------------------------
   U_BootProm : entity work.AxiMicronN25QCore
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         MEM_ADDR_MASK_G  => x"00000000",           -- Using hardware write protection
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C,        -- units of Hz
         SPI_CLK_FREQ_G   => (AXI_CLK_FREQ_C/4.0))  -- units of Hz
      port map (
         -- FLASH Memory Ports
         csL            => bootCsL,
         sck            => bootSck,
         mosi           => bootMosi,
         miso           => bootMiso,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxilReadMasters(BOOT_MEM_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(BOOT_MEM_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(BOOT_MEM_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(BOOT_MEM_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   U_STARTUPE3 : STARTUPE3
      generic map (
         PROG_USR      => "FALSE",  -- Activate program event security feature. Requires encrypted bitstreams.
         SIM_CCLK_FREQ => 0.0)          -- Set the Configuration Clock Frequency(ns) for simulation
      port map (
         CFGCLK    => open,             -- 1-bit output: Configuration main clock output
         CFGMCLK   => open,  -- 1-bit output: Configuration internal oscillator clock output
         DI        => di,               -- 4-bit output: Allow receiving on the D[3:0] input pins
         EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,             -- 1-bit output: PROGRAM request to fabric output
         DO        => do,               -- 4-bit input: Allows control of the D[3:0] pin outputs
         DTS       => "1110",           -- 4-bit input: Allows tristate of the D[3:0] pins
         FCSBO     => bootCsL,          -- 1-bit input: Contols the FCS_B pin for flash access
         FCSBTS    => '0',              -- 1-bit input: Tristate the FCS_B pin
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',              -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => bootSck,          -- 1-bit input: User CCLK input
         USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => axilRstL,         -- 1-bit input: User DONE pin output control
         USRDONETS => '0');             -- 1-bit input: User DONE 3-state enable output

   axilRstL <= not(axilRst);            -- IPMC uses DONE to determine if FPGA is ready
   do       <= "111" & bootMosi;
   bootMiso <= di(1);

   ----------------------------------
   -- AXI-Lite: Clock Crossbar Module
   ----------------------------------
   U_Sy56040 : entity work.AxiSy56040Reg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         XBAR_DEFAULT_G   => XBAR_APP_NODE_C,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C)
      port map (
         -- XBAR Ports
         xBarSin        => xBarSin,
         xBarSout       => xBarSout,
         xBarConfig     => xBarConfig,
         xBarLoad       => xBarLoad,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxilReadMasters(XBAR_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(XBAR_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(XBAR_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(XBAR_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   ----------------------------------------
   -- AXI-Lite: Configuration Memory Module
   ----------------------------------------
   AxiI2cRegMaster_0 : entity work.AxiI2cEeprom
      generic map (
         TPD_G            => TPD_G,
         ADDR_WIDTH_G     => 13,
         I2C_ADDR_G       => "1010000",
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl             => calScl,
         sda             => calSda,
         -- AXI-Lite Register Interface
         axilReadMaster  => mAxilReadMasters(CONFIG_I2C_INDEX_C),
         axilReadSlave   => mAxilReadSlaves(CONFIG_I2C_INDEX_C),
         axilWriteMaster => mAxilWriteMasters(CONFIG_I2C_INDEX_C),
         axilWriteSlave  => mAxilWriteSlaves(CONFIG_I2C_INDEX_C),
         -- Clocks and Resets
         axilClk         => axilClk,
         axilRst         => axilRst);

   ---------------------------------
   -- AXI-Lite: Clock Cleaner Module
   ---------------------------------
   AxiI2cRegMaster_1 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         I2C_SCL_FREQ_G   => 10.0E+3, -- 10k clk
         DEVICE_MAP_G     => TIME_DEVICE_MAP_C,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl            => timingClkScl,
         sda            => timingClkSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxilReadMasters(CLK_I2C_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(CLK_I2C_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(CLK_I2C_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(CLK_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   -------------------------------
   -- AXI-Lite: DDR Monitor Module
   -------------------------------
   AxiI2cRegMaster_2 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         DEVICE_MAP_G     => DDR_DEVICE_MAP_C,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl            => ddrScl,
         sda            => ddrSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxilReadMasters(DDR_I2C_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(DDR_I2C_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(DDR_I2C_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(DDR_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   -----------------------
   -- AXI-Lite: BSI Module
   -----------------------
   U_Bsi : entity work.AmcCarrierBsi
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- DDR Memory Status
         ddrMemReady     => ddrMemReady,
         ddrMemError     => ddrMemError,
         -- Local Configurations
         localMac        => localMac,
         localIp         => localIp,
         localAppId      => localAppId,
         ethLinkUp       => ethLinkUp,
         bootReq         => bootReq,
         bootAddr        => bootAddr,
         upTimeCnt       => upTimeCnt,
         -- Application Interface
         bsiBus          => bsiBus,
         -- I2C Ports
         scl             => ipmcScl,
         sda             => ipmcSda,
         -- AXI-Lite Register Interface
         axilReadMaster  => mAxilReadMasters(IPMC_INDEX_C),
         axilReadSlave   => mAxilReadSlaves(IPMC_INDEX_C),
         axilWriteMaster => mAxilWriteMasters(IPMC_INDEX_C),
         axilWriteSlave  => mAxilWriteSlaves(IPMC_INDEX_C),
         -- Clocks and Resets
         axilClk         => axilClk,
         axilRst         => axilRst);

   --------------------------------------
   -- Map the AXI-Lite to Timing Firmware
   --------------------------------------
   timingReadMaster                 <= mAxilReadMasters(TIMING_INDEX_C);
   mAxilReadSlaves(TIMING_INDEX_C)  <= timingReadSlave;
   timingWriteMaster                <= mAxilWriteMasters(TIMING_INDEX_C);
   mAxilWriteSlaves(TIMING_INDEX_C) <= timingWriteSlave;

   --------------------------------------
   -- Map the AXI-Lite to BSA Firmware
   --------------------------------------
   bsaReadMaster                 <= mAxilReadMasters(BSA_INDEX_C);
   mAxilReadSlaves(BSA_INDEX_C)  <= bsaReadSlave;
   bsaWriteMaster                <= mAxilWriteMasters(BSA_INDEX_C);
   mAxilWriteSlaves(BSA_INDEX_C) <= bsaWriteSlave;

   ----------------------------------------
   -- Map the AXI-Lite to XAUI PHY Firmware
   ----------------------------------------
   xauiReadMaster                 <= mAxilReadMasters(XAUI_INDEX_C);
   mAxilReadSlaves(XAUI_INDEX_C)  <= xauiReadSlave;
   xauiWriteMaster                <= mAxilWriteMasters(XAUI_INDEX_C);
   mAxilWriteSlaves(XAUI_INDEX_C) <= xauiWriteSlave;

   ---------------------------------------
   -- Map the AXI-Lite to DDR PHY Firmware
   ---------------------------------------
   ddrReadMaster                 <= mAxilReadMasters(DDR_INDEX_C);
   mAxilReadSlaves(DDR_INDEX_C)  <= ddrReadSlave;
   ddrWriteMaster                <= mAxilWriteMasters(DDR_INDEX_C);
   mAxilWriteSlaves(DDR_INDEX_C) <= ddrWriteSlave;

   ---------------------------------------
   -- Map the AXI-Lite to MPS PHY Firmware
   ---------------------------------------
   mpsReadMaster                 <= mAxilReadMasters(MPS_INDEX_C);
   mAxilReadSlaves(MPS_INDEX_C)  <= mpsReadSlave;
   mpsWriteMaster                <= mAxilWriteMasters(MPS_INDEX_C);
   mAxilWriteSlaves(MPS_INDEX_C) <= mpsWriteSlave;

   -------------------------------------------
   -- Map the AXI-Lite to Application Firmware
   -------------------------------------------
   regReadMaster                 <= mAxilReadMasters(APP_INDEX_C);
   mAxilReadSlaves(APP_INDEX_C)  <= regReadSlave;
   regWriteMaster                <= mAxilWriteMasters(APP_INDEX_C);
   mAxilWriteSlaves(APP_INDEX_C) <= regWriteSlave;

end mapping;
