-------------------------------------------------------------------------------
-- File       : RtmRfInterlock.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-17
-- Last update: 2017-04-04
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_19_C00
------------------------------------------------------------------------------
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmRfInterlock is
   generic (
      TPD_G            : time             := 1 ns;
      IODELAY_GROUP_G  : string           := "RTM_DELAY_GROUP";
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0');
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      -- Recovered EVR clock
      recClk          : in    sl;
      recRst          : in    sl;
      -- Timing triggers
      stndbyTrig      : in    sl;
      accelTrig       : in    sl;
      dataTrig        : in    sl;
      -- AXI-Lite
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- RTM's Low Speed Ports
      rtmLsP          : inout slv(53 downto 0);
      rtmLsN          : inout slv(53 downto 0);
      --  RTM's Clock Reference
      genClkP         : in    sl;
      genClkN         : in    sl);
end RtmRfInterlock;

architecture mapping of RtmRfInterlock is

   -- High speed ADC status data (data rate is 6x recClk DDR)
   signal hsAdcBeamIP    : sl;
   signal hsAdcBeamIN    : sl;
   signal hsAdcBeamVP    : sl;
   signal hsAdcBeamVN    : sl;
   signal hsAdcFwdPwrP   : sl;
   signal hsAdcFwdPwrN   : sl;
   signal hsAdcReflPwrP  : sl;
   signal hsAdcReflPwrN  : sl;
   signal hsAdcFrameClkP : sl;
   signal hsAdcFrameClkN : sl;
   signal hsAdcDataClkP  : sl;
   signal hsAdcDataClkN  : sl;
   signal hsAdcClkP      : sl;
   signal hsAdcClkN      : sl;
   signal hsAdcTest      : sl;
   -- Thresholds SPI
   signal klyThrCs       : sl;
   signal modThrCs       : sl;
   signal potSck         : sl;
   signal potSdi         : sl;
   signal potSdiL        : sl;
   -- Low Speed ADC SPI
   signal adcCnv         : sl;
   signal adcCnvL        : sl;
   signal adcSck         : sl;
   signal adcSdi         : sl;
   signal adcSdo         : sl;
   -- CPLD SPI
   signal cpldCsb        : sl;
   signal cpldSck        : sl;
   signal cpldSdi        : sl;
   signal cpldSdo        : sl;
   -- Timing triggers
   signal stndbyTrigL    : sl;
   -- SLED and MODE
   signal detuneSled     : sl;
   signal tuneSled       : sl;
   signal tuneSledL      : sl;
   signal mode           : sl;
   signal modeL          : sl;
   signal bypassMode     : sl;
   signal rfOff          : sl;
   signal fault          : sl;
   signal faultClear     : sl;

   signal stndbyTrigLReg : sl;
   signal accelTrigReg   : sl;

begin

   hsAdcBeamIP    <= rtmLsP(9);
   hsAdcBeamIN    <= rtmLsN(9);
   hsAdcBeamVP    <= rtmLsP(14);
   hsAdcBeamVN    <= rtmLsN(14);
   hsAdcFwdPwrP   <= rtmLsP(13);
   hsAdcFwdPwrN   <= rtmLsN(13);
   hsAdcReflPwrP  <= rtmLsP(19);
   hsAdcReflPwrN  <= rtmLsN(19);
   hsAdcFrameClkP <= rtmLsP(18);
   hsAdcFrameClkN <= rtmLsN(18);
   hsAdcDataClkP  <= rtmLsP(3);
   hsAdcDataClkN  <= rtmLsN(3);
   rtmLsP(8)      <= hsAdcClkP;
   rtmLsN(8)      <= hsAdcClkN;

   U_fastTest : OBUFDS
      port map (
         I  => hsAdcTest,
         O  => rtmLsP(34),
         OB => rtmLsN(34));

   U_potSdiL : OBUFDS
      port map (
         I  => potSdiL,
         O  => rtmLsP(35),
         OB => rtmLsN(35));

   U_potSck : OBUFDS
      port map (
         I  => potSck,
         O  => rtmLsP(36),
         OB => rtmLsN(36));

   U_klyThrCs : OBUFDS
      port map (
         I  => klyThrCs,
         O  => rtmLsP(37),
         OB => rtmLsN(37));

   U_modThrCs : OBUFDS
      port map (
         I  => modThrCs,
         O  => rtmLsP(38),
         OB => rtmLsN(38));

   U_adcSdi : OBUFDS
      port map (
         I  => adcSdi,
         O  => rtmLsP(40),
         OB => rtmLsN(40));

   U_adcSck : OBUFDS
      port map (
         I  => adcSck,
         O  => rtmLsP(41),
         OB => rtmLsN(41));

   U_adcSdo : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => rtmLsP(39),
         IB => rtmLsN(39),
         O  => adcSdo);

   U_adcCnvL : OBUFDS
      port map (
         I  => adcCnvL,
         O  => rtmLsP(42),
         OB => rtmLsN(42));

   U_cpldSdo : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => rtmLsP(50),
         IB => rtmLsN(50),
         O  => cpldSdo);

   U_cpldSdi : OBUFDS
      port map (
         I  => cpldSdi,
         O  => rtmLsP(51),
         OB => rtmLsN(51));

   U_cpldSck : OBUFDS
      port map (
         I  => cpldSck,
         O  => rtmLsP(53),
         OB => rtmLsN(53));

   U_cpldCsb : OBUFDS
      port map (
         I  => cpldCsb,
         O  => rtmLsP(52),
         OB => rtmLsN(52));

   U_stndbyTrigReg : ODDRE1
      port map (
         C  => recClk,
         Q  => stndbyTrigLReg,
         D1 => stndbyTrigL,
         D2 => stndbyTrigL,
         SR  => '0');

   U_stndbyTrigL : OBUFDS
      port map (
         I  => stndbyTrigLReg,
         O  => rtmLsP(45),
         OB => rtmLsN(45));

   U_accelTrigReg : ODDRE1
      port map (
         C  => recClk,
         Q  => accelTrigReg,
         D1 => accelTrig,
         D2 => accelTrig,
         SR => '0');

   U_accelTrig : OBUFDS
      port map (
         I  => accelTrigReg,
         O  => rtmLsP(46),
         OB => rtmLsN(46));

   U_detuneSled : OBUFDS
      port map (
         I  => detuneSled,
         O  => rtmLsP(44),
         OB => rtmLsN(44));

   U_tuneSledL : OBUFDS
      port map (
         I  => tuneSledL,
         O  => rtmLsP(43),
         OB => rtmLsN(43));

   U_modeL : OBUFDS
      port map (
         I  => modeL,
         O  => rtmLsP(49),
         OB => rtmLsN(49));

   U_bypassMode : OBUFDS
      port map (
         I  => bypassMode,
         O  => rtmLsP(2),
         OB => rtmLsN(2));

   U_fault : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => rtmLsP(48),
         IB => rtmLsN(48),
         O  => fault);

   U_rfOff : IBUFDS
      generic map (
         DIFF_TERM => true)
      port map (
         I  => rtmLsP(5),               -- 47 -> 5 (changed due to DRC)
         IB => rtmLsN(5),               -- 47 -> 5 (changed due to DRC)
         O  => rfOff);

   U_faultClear : OBUFDS
      port map (
         I  => faultClear,
         O  => rtmLsP(4),
         OB => rtmLsN(4));

   ----------------------------------
   -- Note inverted because of HW bug   
   ----------------------------------
   stndbyTrigL <= not(stndbyTrig);
   tuneSledL   <= not(tuneSled);
   modeL       <= not(mode);
   adcCnvL     <= not(adcCnv);
   potSdiL     <= not(potSdi);

   -------
   -- Core
   -------
   U_CORE : entity work.RtmRfInterlockCore
      generic map (
         TPD_G            => TPD_G,
         IODELAY_GROUP_G  => IODELAY_GROUP_G,
         AXIL_BASE_ADDR_G => AXIL_BASE_ADDR_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- Recovered EVR clock
         recClk          => recClk,
         recRst          => recRst,
         -- Timing triggers
         dataTrig        => dataTrig,
         -- AXI-Lite
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- High speed ADC status data (data rate is 6x recClk DDR)
         hsAdcBeamIP     => hsAdcBeamIP,
         hsAdcBeamIN     => hsAdcBeamIN,
         hsAdcBeamVP     => hsAdcBeamVP,
         hsAdcBeamVN     => hsAdcBeamVN,
         hsAdcFwdPwrP    => hsAdcFwdPwrP,
         hsAdcFwdPwrN    => hsAdcFwdPwrN,
         hsAdcReflPwrP   => hsAdcReflPwrP,
         hsAdcReflPwrN   => hsAdcReflPwrN,
         hsAdcFrameClkP  => hsAdcFrameClkP,
         hsAdcFrameClkN  => hsAdcFrameClkN,
         hsAdcDataClkP   => hsAdcDataClkP,
         hsAdcDataClkN   => hsAdcDataClkN,
         hsAdcClkP       => hsAdcClkP,
         hsAdcClkN       => hsAdcClkN,
         hsAdcTest       => hsAdcTest,
         -- Thresholds SPI
         klyThrCs        => klyThrCs,
         modThrCs        => modThrCs,
         potSck          => potSck,
         potSdi          => potSdi,
         -- Low Speed ADC SPI
         adcCnv          => adcCnv,
         adcSck          => adcSck,
         adcSdi          => adcSdi,
         adcSdo          => adcSdo,
         -- CPLD SPI
         cpldCsb         => cpldCsb,
         cpldSck         => cpldSck,
         cpldSdi         => cpldSdi,
         cpldSdo         => cpldSdo,
         -- SLED and MODE
         detuneSled      => detuneSled,
         tuneSled        => tuneSled,
         mode            => mode,
         bypassMode      => bypassMode,
         rfOff           => rfOff,
         fault           => fault,
         faultClear      => faultClear);

end architecture mapping;
