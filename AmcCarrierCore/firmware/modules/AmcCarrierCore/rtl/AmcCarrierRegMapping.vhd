-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierRegMapping.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2015-08-04
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
use work.I2cPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierRegMapping is
   generic (
      TPD_G  : time    := 1 ns;
      FSBL_G : boolean := false);
   port (
      -- Primary AXI-Lite Interface
      axiClk               : in    sl;
      axiRst               : in    sl;
      sAxiReadMaster       : in    AxiLiteReadMasterArray(1 downto 0);
      sAxiReadSlave        : out   AxiLiteReadSlaveArray(1 downto 0);
      sAxiWriteMaster      : in    AxiLiteWriteMasterArray(1 downto 0);
      sAxiWriteSlave       : out   AxiLiteWriteSlaveArray(1 downto 0);
      -- Timing AXI-Lite Interface
      timingAxiReadMaster  : out   AxiLiteReadMasterType;
      timingAxiReadSlave   : in    AxiLiteReadSlaveType;
      timingAxiWriteMaster : out   AxiLiteWriteMasterType;
      timingAxiWriteSlave  : in    AxiLiteWriteSlaveType;
      -- XAUI AXI-Lite Interface
      xauiAxiReadMaster    : out   AxiLiteReadMasterType;
      xauiAxiReadSlave     : in    AxiLiteReadSlaveType;
      xauiAxiWriteMaster   : out   AxiLiteWriteMasterType;
      xauiAxiWriteSlave    : in    AxiLiteWriteSlaveType;
      -- DDR AXI-Lite Interface
      ddrAxiReadMaster     : out   AxiLiteReadMasterType;
      ddrAxiReadSlave      : in    AxiLiteReadSlaveType;
      ddrAxiWriteMaster    : out   AxiLiteWriteMasterType;
      ddrAxiWriteSlave     : in    AxiLiteWriteSlaveType;
      -- AXI-Lite Interface (regClk domain)
      regClk               : in    sl;
      regRst               : in    sl;
      regAxiReadMaster     : out   AxiLiteReadMasterType;
      regAxiReadSlave      : in    AxiLiteReadSlaveType;
      regAxiWriteMaster    : out   AxiLiteWriteMasterType;
      regAxiWriteSlave     : in    AxiLiteWriteSlaveType;
      -- Boot Prom AXI Streaming Interface (Optional)
      obPromMaster         : out   AxiStreamMasterType;
      obPromSlave          : in    AxiStreamSlaveType;
      ibPromMaster         : in    AxiStreamMasterType;
      ibPromSlave          : out   AxiStreamSlaveType;
      ----------------
      -- Core Ports --
      ----------------   
      -- Crossbar Ports
      xBarSin              : out   slv(1 downto 0);
      xBarSout             : out   slv(1 downto 0);
      xBarConfig           : out   sl;
      xBarLoad             : out   sl;
      -- IPMC Ports
      ipmcScl              : inout sl;
      ipmcSda              : inout sl;
      -- Configuration PROM Ports
      calScl               : inout sl;
      calSda               : inout sl;
      -- Clock Cleaner Ports
      timingClkScl         : inout sl;
      timingClkSda         : inout sl;
      -- DDR3L SO-DIMM Ports
      ddrScl               : inout sl;
      ddrSda               : inout sl;
      -- SYSMON Ports
      vPIn                 : in    sl;
      vNIn                 : in    sl);         
end AmcCarrierRegMapping;

architecture mapping of AmcCarrierRegMapping is

   constant AXI_CLK_FREQ_C : real := 156.25E+6;

   constant NUM_AXI_MASTERS_C : natural := 13;

   constant DEVICE_TREE_INDEX_C : natural := 0;
   constant VERSION_INDEX_C     : natural := 1;
   constant SYSMON_INDEX_C      : natural := 2;
   constant BOOT_MEM_INDEX_C    : natural := 3;
   constant XBAR_INDEX_C        : natural := 4;
   constant CONFIG_I2C_INDEX_C  : natural := 5;
   constant CLK_I2C_INDEX_C     : natural := 6;
   constant DDR_I2C_INDEX_C     : natural := 7;
   constant IPMC_INDEX_C        : natural := 8;
   constant TIMING_INDEX_C      : natural := 9;
   constant XAUI_INDEX_C        : natural := 10;
   constant DDR_INDEX_C         : natural := 11;
   constant APP_INDEX_C         : natural := 12;

   constant DEVICE_TREE_ADDR_C : slv(31 downto 0) := X"00000000";
   constant VERSION_ADDR_C     : slv(31 downto 0) := X"01000000";
   constant SYSMON_ADDR_C      : slv(31 downto 0) := X"02000000";
   constant BOOT_MEM_ADDR_C    : slv(31 downto 0) := X"03000000";
   constant XBAR_ADDR_C        : slv(31 downto 0) := X"04000000";
   constant CONFIG_I2C_ADDR_C  : slv(31 downto 0) := X"05000000";
   constant CLK_I2C_ADDR_C     : slv(31 downto 0) := X"06000000";
   constant DDR_I2C_ADDR_C     : slv(31 downto 0) := X"07000000";
   constant IPMC_ADDR_C        : slv(31 downto 0) := X"08000000";
   constant TIMING_ADDR_C      : slv(31 downto 0) := X"09000000";
   constant XAUI_ADDR_C        : slv(31 downto 0) := X"0A000000";
   constant DDR_ADDR_C         : slv(31 downto 0) := X"0B000000";
   constant APP_ADDR_C         : slv(31 downto 0) := X"80000000";
   
   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DEVICE_TREE_INDEX_C => (
         baseAddr         => DEVICE_TREE_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      VERSION_INDEX_C     => (
         baseAddr         => VERSION_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      SYSMON_INDEX_C      => (
         baseAddr         => SYSMON_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      BOOT_MEM_INDEX_C    => (
         baseAddr         => BOOT_MEM_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      XBAR_INDEX_C        => (
         baseAddr         => XBAR_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      CONFIG_I2C_INDEX_C  => (
         baseAddr         => CONFIG_I2C_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0003"),
      CLK_I2C_INDEX_C     => (
         baseAddr         => CLK_I2C_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      DDR_I2C_INDEX_C     => (
         baseAddr         => DDR_I2C_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      IPMC_INDEX_C        => (
         baseAddr         => IPMC_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0001"),
      XAUI_INDEX_C        => (
         baseAddr         => XAUI_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0002"),
      TIMING_INDEX_C      => (
         baseAddr         => TIMING_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0002"),
      DDR_INDEX_C         => (
         baseAddr         => DDR_ADDR_C,
         addrBits         => 24,
         connectivity     => X"0002"),
      APP_INDEX_C         => (
         baseAddr         => APP_ADDR_C,
         addrBits         => 32,
         connectivity     => X"0001"));   

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

   signal mAxiWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxiWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxiReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal mAxiReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal bootCsL  : sl;
   signal bootSck  : sl;
   signal bootMosi : sl;
   signal bootMiso : sl;
   
begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------  
   AxiLiteCrossbar_Inst : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk           => axiClk,
         axiClkRst        => axiRst,
         sAxiWriteMasters => sAxiWriteMaster,
         sAxiWriteSlaves  => sAxiWriteSlave,
         sAxiReadMasters  => sAxiReadMaster,
         sAxiReadSlaves   => sAxiReadSlave,
         mAxiWriteMasters => mAxiWriteMasters,
         mAxiWriteSlaves  => mAxiWriteSlaves,
         mAxiReadMasters  => mAxiReadMasters,
         mAxiReadSlaves   => mAxiReadSlaves);

   -----------------------------------           
   -- AXI-Lite: Device Tree ROM Module
   -----------------------------------           
   AxiDeviceTree_Inst : entity work.AxiLiteEmpty
      generic map (
         TPD_G => TPD_G)
      port map (
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(DEVICE_TREE_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(DEVICE_TREE_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(DEVICE_TREE_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(DEVICE_TREE_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiClkRst      => axiRst);         

   --------------------------
   -- AXI-Lite Version Module
   --------------------------          
   AxiVersion_Inst : entity work.AxiVersion
      generic map (
         TPD_G           => TPD_G,
         XIL_DEVICE_G    => "ULTRASCALE",
         EN_DEVICE_DNA_G => true,
         EN_ICAP_G       => true)
      port map (
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(VERSION_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(VERSION_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(VERSION_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);  

   --------------------------
   -- AXI-Lite: SYSMON Module
   --------------------------
   AmcCarrierSysMon_Inst : entity work.AmcCarrierSysMon
      generic map (
         TPD_G => TPD_G)
      port map (
         -- SYSMON Ports
         vPIn           => vPIn,
         vNIn           => vNIn,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(SYSMON_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(SYSMON_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(SYSMON_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(SYSMON_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);  

   ------------------------------
   -- AXI-Lite: Boot Flash Module
   ------------------------------
   AxiMicronN25QCore_Inst : entity work.AxiMicronN25QCore
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_C)  -- units of Hz
      port map (
         -- FLASH Memory Ports
         csL            => bootCsL,
         sck            => bootSck,
         mosi           => bootMosi,
         miso           => bootMiso,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(BOOT_MEM_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(BOOT_MEM_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(BOOT_MEM_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(BOOT_MEM_INDEX_C),
         -- AXI Streaming Interface (Optional)
         mAxisMaster    => obPromMaster,
         mAxisSlave     => obPromSlave,
         sAxisMaster    => ibPromMaster,
         sAxisSlave     => ibPromSlave,
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);

   STARTUPE3_Inst : STARTUPE3
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
   AxiSy56040Reg_Inst : entity work.AxiSy56040Reg
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_C) 
      port map (
         -- XBAR Ports 
         xBarSin        => xBarSin,
         xBarSout       => xBarSout,
         xBarConfig     => xBarConfig,
         xBarLoad       => xBarLoad,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(XBAR_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(XBAR_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(XBAR_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(XBAR_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);  

   ----------------------------------------
   -- AXI-Lite: Configuration Memory Module
   ----------------------------------------
   AxiI2cRegMaster_0 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G          => TPD_G,
         DEVICE_MAP_G   => CONFIG_DEVICE_MAP_C,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl            => calScl,
         sda            => calSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(CONFIG_I2C_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(CONFIG_I2C_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(CONFIG_I2C_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(CONFIG_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst); 

   ---------------------------------
   -- AXI-Lite: Clock Cleaner Module
   ---------------------------------
   AxiI2cRegMaster_1 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G          => TPD_G,
         DEVICE_MAP_G   => TIME_DEVICE_MAP_C,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl            => timingClkScl,
         sda            => timingClkSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(CLK_I2C_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(CLK_I2C_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(CLK_I2C_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(CLK_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);    

   -------------------------------
   -- AXI-Lite: DDR Monitor Module
   -------------------------------
   AxiI2cRegMaster_2 : entity work.AxiI2cRegMaster
      generic map (
         TPD_G          => TPD_G,
         DEVICE_MAP_G   => DDR_DEVICE_MAP_C,
         AXI_CLK_FREQ_G => AXI_CLK_FREQ_C)
      port map (
         -- I2C Ports
         scl            => ddrScl,
         sda            => ddrSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(DDR_I2C_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(DDR_I2C_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(DDR_I2C_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(DDR_I2C_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);             

   -----------------------
   -- AXI-Lite: BSI Module
   -----------------------  
   AmcCarrierBsi_Inst : entity work.AmcCarrierBsi
      generic map (
         TPD_G => TPD_G)
      port map (
         -- I2C Ports
         scl            => ipmcScl,
         sda            => ipmcSda,
         -- AXI-Lite Register Interface
         axiReadMaster  => mAxiReadMasters(IPMC_INDEX_C),
         axiReadSlave   => mAxiReadSlaves(IPMC_INDEX_C),
         axiWriteMaster => mAxiWriteMasters(IPMC_INDEX_C),
         axiWriteSlave  => mAxiWriteSlaves(IPMC_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);    

   --------------------------------------
   -- Map the AXI-Lite to Timing Firmware
   --------------------------------------
   timingAxiReadMaster             <= mAxiReadMasters(TIMING_INDEX_C);
   mAxiReadSlaves(TIMING_INDEX_C)  <= timingAxiReadSlave;
   timingAxiWriteMaster            <= mAxiWriteMasters(TIMING_INDEX_C);
   mAxiWriteSlaves(TIMING_INDEX_C) <= timingAxiWriteSlave;

   ------------------------------------
   -- Map the AXI-Lite to XAUI Firmware
   ------------------------------------
   xauiAxiReadMaster             <= mAxiReadMasters(XAUI_INDEX_C);
   mAxiReadSlaves(XAUI_INDEX_C)  <= xauiAxiReadSlave;
   xauiAxiWriteMaster            <= mAxiWriteMasters(XAUI_INDEX_C);
   mAxiWriteSlaves(XAUI_INDEX_C) <= xauiAxiWriteSlave;

   ------------------------------------------
   -- Map the AXI-Lite to DDR Memory Firmware
   ------------------------------------------
   ddrAxiReadMaster             <= mAxiReadMasters(DDR_INDEX_C);
   mAxiReadSlaves(DDR_INDEX_C)  <= ddrAxiReadSlave;
   ddrAxiWriteMaster            <= mAxiWriteMasters(DDR_INDEX_C);
   mAxiWriteSlaves(DDR_INDEX_C) <= ddrAxiWriteSlave;

   -------------------------------------------
   -- Map the AXI-Lite to Application Firmware
   -------------------------------------------
   AxiLiteAsync_Inst : entity work.AxiLiteAsync
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Slave Port
         sAxiClk         => axiClk,
         sAxiClkRst      => axiRst,
         sAxiReadMaster  => mAxiReadMasters(APP_INDEX_C),
         sAxiReadSlave   => mAxiReadSlaves(APP_INDEX_C),
         sAxiWriteMaster => mAxiWriteMasters(APP_INDEX_C),
         sAxiWriteSlave  => mAxiWriteSlaves(APP_INDEX_C),
         -- Master Port
         mAxiClk         => regClk,
         mAxiClkRst      => regRst,
         mAxiReadMaster  => regAxiReadMaster,
         mAxiReadSlave   => regAxiReadSlave,
         mAxiWriteMaster => regAxiWriteMaster,
         mAxiWriteSlave  => regAxiWriteSlave);     

end mapping;
