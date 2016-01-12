-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierRegMapping.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-11-02
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

entity AmcCarrierRegMapping is
   generic (
      TPD_G               : time            := 1 ns;
      AXI_ERROR_RESP_G    : slv(1 downto 0) := AXI_RESP_DECERR_C;
      APP_TYPE_G          : AppType         := APP_NULL_TYPE_C;
      STANDALONE_TIMING_G : boolean         := false;  -- false = Normal Operation, = LCLS-I timing only
      FSBL_G              : boolean         := false);
   port (
      -- Primary AXI-Lite Interface
      axilClk           : in    sl;
      axilRst           : in    sl;
      sAxilReadMasters  : in    AxiLiteReadMasterArray(0 downto 0);
      sAxilReadSlaves   : out   AxiLiteReadSlaveArray(0 downto 0);
      sAxilWriteMasters : in    AxiLiteWriteMasterArray(0 downto 0);
      sAxilWriteSlaves  : out   AxiLiteWriteSlaveArray(0 downto 0);
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
      -- Misc.
      debugReset        : out   sl;
      ----------------------
      -- Top Level Interface
      ----------------------           
      -- AXI-Lite Interface
      regClk            : in    sl;
      regRst            : in    sl;
      regReadMaster     : out   AxiLiteReadMasterType;
      regReadSlave      : in    AxiLiteReadSlaveType;
      regWriteMaster    : out   AxiLiteWriteMasterType;
      regWriteSlave     : in    AxiLiteWriteSlaveType;
      -- BSI Interface
      bsiClk            : in    sl;
      bsiRst            : in    sl;
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
end AmcCarrierRegMapping;

architecture mapping of AmcCarrierRegMapping is

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

   constant CONFIG_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 0) := (
      0             => (
         i2cAddress => "0001010000",
         i2cTenbit  => '0',
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1'));           -- Big endian  

   constant TIME_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 0) := (
      0             => (
         i2cAddress => "0001010100",
         i2cTenbit  => '0',
         dataSize   => 16,              -- in units of bits
         addrSize   => 16,              -- in units of bits
         endianness => '1'));           -- Big endian     

   constant DDR_DEVICE_MAP_C : I2cAxiLiteDevArray(0 to 2) := (
      0             => (
         i2cAddress => "0001010000",    -- EEPROM memory array (1010)
         i2cTenbit  => '0',
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1'),            -- Big endian  
      1             => (
         i2cAddress => "0000110000",    -- Write protect settings (0110)
         i2cTenbit  => '0',
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1'),            -- Big endian  
      2             => (
         i2cAddress => "0000011000",    -- Temperature sensor (0011)
         i2cTenbit  => '0',
         dataSize   => 8,               -- in units of bits
         addrSize   => 8,               -- in units of bits
         endianness => '1'));           -- Big endian           

   signal mAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal bootCsL      : sl;
   signal bootSck      : sl;
   signal bootMosi     : sl;
   signal bootMiso     : sl;
   signal fpgaEnReload : sl;
   
begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
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
         TPD_G              => TPD_G,
         AXI_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         CLK_PERIOD_G       => AXI_CLK_PERIOD_C,
         XIL_DEVICE_G       => "ULTRASCALE",
         EN_DEVICE_DNA_G    => true,
         EN_DS2411_G        => false,
         EN_ICAP_G          => true,
         AUTO_RELOAD_EN_G   => FSBL_G,
         AUTO_RELOAD_TIME_G => 3.17,  -- Total of 5 seconds: 1.87 seconds for Memory Test and 3.17 second in AxiVersion
         AUTO_RELOAD_ADDR_G => x"04000000")  -- LCLS-II Image by default
      port map (
         -- AXI-Lite Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         masterReset    => debugReset,
         axiReadMaster  => mAxilReadMasters(VERSION_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(VERSION_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(VERSION_INDEX_C),
         -- Optional: FPGA Reloading Interface
         fpgaEnReload   => fpgaEnReload);

   fpgaEnReload <= ddrMemReady and not(ddrMemError);

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
         MEM_ADDR_MASK_G  => x"00000000",     -- Using hardware write protection
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C)  -- units of Hz
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
         DI(0)     => open,             -- 1-bit output: Allow receiving on the D0 input pin
         DI(1)     => bootMiso,         -- 1-bit output: Allow receiving on the D1 input pin
         DI(2)     => open,             -- 1-bit output: Allow receiving on the D2 input pin
         DI(3)     => open,             -- 1-bit output: Allow receiving on the D3 input pin
         EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,             -- 1-bit output: PROGRAM request to fabric output
         DO(0)     => bootMosi,         -- 1-bit input: Allows control of the D0 pin output
         DO(1)     => '1',              -- 1-bit input: Allows control of the D1 pin output
         DO(2)     => '1',              -- 1-bit input: Allows control of the D2 pin output
         DO(3)     => '1',              -- 1-bit input: Allows control of the D3 pin output
         DTS(0)    => '0',              -- 1-bit input: Allows tristate of the D0 pin
         DTS(1)    => '1',              -- 1-bit input: Allows tristate of the D1 pin
         DTS(2)    => '1',              -- 1-bit input: Allows tristate of the D2 pin
         DTS(3)    => '1',              -- 1-bit input: Allows tristate of the D3 pin
         FCSBO     => bootCsL,          -- 1-bit input: Contols the FCS_B pin for flash access
         FCSBTS    => '0',              -- 1-bit input: Tristate the FCS_B pin
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',              -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => bootSck,          -- 1-bit input: User CCLK input
         USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => '1',              -- 1-bit input: User DONE pin output control
         USRDONETS => '1');             -- 1-bit input: User DONE 3-state enable output     

   ----------------------------------
   -- AXI-Lite: Clock Crossbar Module
   ----------------------------------
   U_Sy56040 : entity work.AxiSy56040Reg
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         XBAR_DEFAULT_G   => xbarDefault(APP_TYPE_G, STANDALONE_TIMING_G),
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
   AxiI2cRegMaster_0 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         DEVICE_MAP_G     => CONFIG_DEVICE_MAP_C,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl            => calScl,
         sda            => calSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxilReadMasters(CONFIG_I2C_INDEX_C),
         axiReadSlave   => mAxilReadSlaves(CONFIG_I2C_INDEX_C),
         axiWriteMaster => mAxilWriteMasters(CONFIG_I2C_INDEX_C),
         axiWriteSlave  => mAxilWriteSlaves(CONFIG_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst); 

   ---------------------------------
   -- AXI-Lite: Clock Cleaner Module
   ---------------------------------
   AxiI2cRegMaster_1 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
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
         -- Local Configurations
         localMac        => localMac,
         localIp         => localIp,
         localAppId      => localAppId,
         -- Application Interface
         bsiClk          => bsiClk,
         bsiRst          => bsiRst,
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
   U_AxiLiteAsync : entity work.AxiLiteAsync
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Slave Port
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => mAxilReadMasters(APP_INDEX_C),
         sAxiReadSlave   => mAxilReadSlaves(APP_INDEX_C),
         sAxiWriteMaster => mAxilWriteMasters(APP_INDEX_C),
         sAxiWriteSlave  => mAxilWriteSlaves(APP_INDEX_C),
         -- Master Port
         mAxiClk         => regClk,
         mAxiClkRst      => regRst,
         mAxiReadMaster  => regReadMaster,
         mAxiReadSlave   => regReadSlave,
         mAxiWriteMaster => regWriteMaster,
         mAxiWriteSlave  => regWriteSlave);     

end mapping;
