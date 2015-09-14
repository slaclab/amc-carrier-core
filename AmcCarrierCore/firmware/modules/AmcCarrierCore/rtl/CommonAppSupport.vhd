-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : CommonAppSupport.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-14
-- Last update: 2015-09-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Common Module for Application Support.  
-- 
--  Note: This module assumes that sysClk is the same clock for 
--        regClk, timingClk, bsiClk, and mpsClk.  
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AmcCarrierPkg.all;
use work.TimingPkg.all;

entity CommonAppSupport is
   generic (
      TPD_G      : time            := 1 ns;
      MPS_TYPE_G : slv(4 downto 0) := MPS_NULL_TYPE_C;
      MPS_LEN_G  : positive        := MPS_NULL_LEN_C);
   port (
      -- User Interface
      sysClk       : in  sl;
      sysRst       : in  sl;
      testMode     : in  sl;
      mpsMsg       : in  Slv8Array(MPS_LEN_G-1 downto 0);
      -- AXI-Lite Interface
      regClk       : out sl;
      regRst       : out sl;
      -- Timing Interface
      timingClk    : out sl;
      timingRst    : out sl;
      timingData   : in  TimingDataType;
      -- BSI Interface
      bsiClk       : out sl;
      bsiRst       : out sl;
      bsiData      : in  BsiDataType;
      -- MPS Interface
      mpsClk       : out sl;
      mpsRst       : out sl;
      mpsIbMaster  : out AxiStreamMasterType;
      mpsIbSlave   : in  AxiStreamSlaveType;
      mpsObMasters : in  AxiStreamMasterArray(14 downto 1);
      mpsObSlaves  : out AxiStreamSlaveArray(14 downto 1));   
end CommonAppSupport;

architecture mapping of CommonAppSupport is

begin

   regClk      <= sysClk;
   regRst      <= sysRst;
   timingClk   <= sysClk;
   timingRst   <= sysRst;
   bsiClk      <= sysClk;
   bsiRst      <= sysRst;
   mpsClk      <= sysClk;
   mpsRst      <= sysRst;
   mpsObSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);

   U_MpsMsg : entity work.AmcCarrierMpsMsg
      generic map (
         TPD_G      => TPD_G,
         MPS_TYPE_G => MPS_TYPE_G,
         MPS_LEN_G  => MPS_LEN_G)
      port map (
         -- User Interface
         clk         => sysClk,
         rst         => sysRst,
         testMode    => testMode,
         mpsMsg      => mpsMsg,
         appId       => bsiData.slotNumber(4 downto 0),
         -- Timing Interface
         timingData  => timingData,
         -- BSI Interface      
         bsiData     => bsiData,
         -- MPS Interface
         mpsIbMaster => mpsIbMaster,
         mpsIbSlave  => mpsIbSlave);      

end mapping;
