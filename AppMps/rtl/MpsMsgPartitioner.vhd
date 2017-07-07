-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsMsgPartitioner.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-29
-- Last update: 2016-02-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 MPS Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 MPS Firmware', including this file, 
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
use work.Pgp2bPkg.all;

entity MpsMsgPartitioner is
   generic (
      TPD_G                 : time                := 1 ns;
      SIM_ERROR_HALT_G      : boolean             := false;
      EN_BACKPRESS_G        : boolean             := false;
      -- Slave Configuration Configuration
      SLAVE_SYNC_FIFO_G     : boolean             := false;
      SLAVE_READY_EN_G      : boolean             := true;
      SLAVE_PIPE_STAGES_G   : natural             := 1;
      SLAVE_CASCADE_SIZE_G  : positive            := 1;
      SLAVE_AXI_CONFIG_G    : AxiStreamConfigType := ssiAxiStreamConfig(4);
      -- Master Configuration
      MASTER_SYNC_FIFO_G    : boolean             := false;
      MASTER_PIPE_STAGES_G  : natural             := 1;
      MASTER_CASCADE_SIZE_G : positive            := 1;
      MASTER_AXI_CONFIG_G   : AxiStreamConfigType := ssiAxiStreamConfig(4));
   port (
      -- Processing Interface
      clk         : in  sl;
      rst         : in  sl;
      pktDrop     : out sl;
      overflowDet : out sl;
      queueStatus : out sl;
      -- Slave Interface
      sAxisClk    : in  sl;
      sAxisRst    : in  sl;
      sAxisMaster : in  AxiStreamMasterType;
      sAxisSlave  : out AxiStreamSlaveType;
      sAxisCtrl   : out AxiStreamCtrlType;
      -- Master Interface
      mAxisClk    : in  sl;
      mAxisRst    : in  sl;
      mAxisMaster : out AxiStreamMasterType;
      mAxisSlave  : in  AxiStreamSlaveType;
      mTLastTUser : out slv(127 downto 0));       
end MpsMsgPartitioner;

architecture rtl of MpsMsgPartitioner is
   
   type StateType is (
      INIT_S,
      IDLE_S,
      MOVE_S,
      BLOWOFF_S); 

   type RegType is record
      sof      : sl;
      pktDrop  : sl;
      cnt      : slv(6 downto 0);
      cntSize  : slv(6 downto 0);
      rxSlave  : AxiStreamSlaveType;
      txMaster : AxiStreamMasterType;
      state    : StateType;
      stateDly : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      sof      => '1',
      pktDrop  => '0',
      cnt      => (others => '0'),
      cntSize  => (others => '0'),
      rxSlave  => AXI_STREAM_SLAVE_INIT_C,
      txMaster => AXI_STREAM_MASTER_INIT_C,
      state    => INIT_S,
      stateDly => INIT_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal sCtrl : AxiStreamCtrlType;

   signal rxMaster     : AxiStreamMasterType;
   signal rxSlave      : AxiStreamSlaveType;
   signal rxCtrl       : AxiStreamCtrlType;
   signal rxTLastTUser : AxiStreamMasterType;

   signal txMaster : AxiStreamMasterType;
   signal txSlave  : AxiStreamSlaveType;
   signal txCtrl   : AxiStreamCtrlType;

   
begin

   sAxisCtrl   <= sCtrl;
   overflowDet <= rxCtrl.overflow;
   queueStatus <= txCtrl.pause;

   RX_FIFO : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,    
         -- General Configurations
         PIPE_STAGES_G       => SLAVE_PIPE_STAGES_G,
         SLAVE_READY_EN_G    => SLAVE_READY_EN_G,
         VALID_THOLD_G       => 0,      -- = 0 = only when frame ready
         -- FIFO configurations
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => SLAVE_SYNC_FIFO_G,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 500,
         CASCADE_SIZE_G      => SLAVE_CASCADE_SIZE_G,
         CASCADE_PAUSE_SEL_G => SLAVE_CASCADE_SIZE_G-1,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => SLAVE_AXI_CONFIG_G,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C) 
      port map(
         -- Slave Port
         sAxisClk    => sAxisClk,
         sAxisRst    => sAxisRst,
         sAxisMaster => sAxisMaster,
         sAxisSlave  => sAxisSlave,
         sAxisCtrl   => sCtrl,
         -- Master Port
         mAxisClk    => clk,
         mAxisRst    => rst,
         mAxisMaster => rxMaster,
         mAxisSlave  => rxSlave,
         mTLastTUser => rxTLastTUser.tUser(7 downto 0));  

   GEN_SYNC_SLAVE : if (SLAVE_SYNC_FIFO_G = true) generate
      rxCtrl <= sCtrl;
   end generate;

   GEN_ASYNC_SLAVE : if (SLAVE_SYNC_FIFO_G = false) generate
      Sync_Ctrl : entity work.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 2,
            INIT_G  => "11")
         port map (
            clk        => clk,
            rst        => rst,
            dataIn(0)  => sCtrl.pause,
            dataIn(1)  => sCtrl.idle,
            dataOut(0) => rxCtrl.pause,
            dataOut(1) => rxCtrl.idle);   
      Sync_Overflow : entity work.SynchronizerOneShot
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => clk,
            rst     => rst,
            dataIn  => sCtrl.overflow,
            dataOut => rxCtrl.overflow);            
   end generate;

   comb : process (r, rst, rxCtrl, rxMaster, rxTLastTUser, txSlave) is
      variable v        : RegType;
      variable validSof : sl;

   begin
      -- Latch the current value
      v := r;

      -- Reset the flags    
      v.pktDrop := '0';
      validSof  := '0';
      v.rxSlave := AXI_STREAM_SLAVE_INIT_C;
      if txSlave.tReady = '1' then
         v.txMaster.tValid := '0';
         v.txMaster.tLast  := '0';
         v.txMaster.tUser  := (others => '0');
      end if;

      -- Check for valid SOF bit, no EOFE, and no EOF
      if (ssiGetUserSof(SSI_PGP2B_CONFIG_C, rxMaster) = r.sof)
         and (ssiGetUserEofe(SSI_PGP2B_CONFIG_C, rxTLastTUser) = '0')
         and (rxMaster.tLast = '0') then
         -- Set the flag
         validSof := '1';
      end if;

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when INIT_S =>
            -- Wait for FIFO reset sequence to complete
            if rxCtrl.pause = '0' then
               -- Next state
               v.state := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check for full frame in the FIFO (VALID_THOLD_G = 0)
            if (v.txMaster.tValid = '0') and (rxMaster.tValid = '1') then
               -- Check for valid SOF bit and no EOFE
               if (validSof = '1') then
                  -- Check for valid message length (in units of byte)
                  if (rxMaster.tData(7 downto 0) >= 6)
                     and (rxMaster.tData(7 downto 0) <= 37) then
                     -- Accept the data
                     v.rxSlave.tReady                := '1';
                     -- Set the TX bus
                     v.txMaster                      := rxMaster;
                     -- Force the SOF on TX bus
                     ssiSetUserSof(SSI_PGP2B_CONFIG_C, v.txMaster, '1');
                     -- Reset the flag
                     v.sof                           := '0';
                     -- Set the message size (in units of 16-bit words)
                     v.cntSize                       := rxMaster.tData(7 downto 1);
                     -- Reset the counter
                     v.cnt                           := toSlv(0, 7);
                     -- Next state
                     v.state                         := MOVE_S;
                  else
                     -- Next state
                     v.state := BLOWOFF_S;
                  end if;
               else
                  -- Next state
                  v.state := BLOWOFF_S;
               end if;
            elsif (rxCtrl.pause = '1') and (EN_BACKPRESS_G = false) then
               -- Next state
               v.state := BLOWOFF_S;
            end if;
         ----------------------------------------------------------------------
         when MOVE_S =>
            -- Check if ready to move data
            if (v.txMaster.tValid = '0') and (rxMaster.tValid = '1') then
               -- Accept the data
               v.rxSlave.tReady := '1';
               -- Set the TX bus
               v.txMaster       := rxMaster;
               -- Increment the counter
               v.cnt            := r.cnt + 1;
               -- Check for last word
               if (v.cnt = r.cntSize) or (rxMaster.tLast = '1') then
                  -- Force the EOF on TX bus
                  v.txMaster.tLast := '1';
                  -- Refresh the flag
                  v.sof            := rxMaster.tLast;
                  -- Next state
                  v.state          := IDLE_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when BLOWOFF_S =>
            -- Accept the data
            v.rxSlave.tReady := '1';
            -- Check for EOF
            if rxMaster.tLast = '1' then
               -- Set the flag
               v.pktDrop := '1';
               -- Reset the flag
               v.sof     := '1';
               -- Next state
               v.state   := IDLE_S;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Check for error condition
      v.stateDly := r.state;
      if (r.stateDly = BLOWOFF_S) then
         -- Check the simulation error printing
         if SIM_ERROR_HALT_G then
            report "MpsMsgPartitioner: Error Detected" severity failure;
         end if;
      end if;

      -- Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs        
      rxSlave  <= v.rxSlave;
      txMaster <= r.txMaster;
      pktDrop  <= r.pktDrop;

   end process comb;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   TX_FIFO : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         -- General Configurations
         PIPE_STAGES_G       => MASTER_PIPE_STAGES_G,
         INT_PIPE_STAGES_G   => 1, 
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,      -- = 0 = only when frame ready
         -- FIFO configurations
         BRAM_EN_G           => true,
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => MASTER_SYNC_FIFO_G,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 3,-- Used to check if frame is available during concentrator's MOVE_S 
         CASCADE_SIZE_G      => MASTER_CASCADE_SIZE_G,
         CASCADE_PAUSE_SEL_G => 0,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
         MASTER_AXI_CONFIG_G => MASTER_AXI_CONFIG_G) 
      port map (
         -- Slave Port
         sAxisClk    => clk,
         sAxisRst    => rst,
         sAxisMaster => r.txMaster,
         sAxisSlave  => txSlave,
         sAxisCtrl   => txCtrl,
         -- Master Port
         mAxisClk    => mAxisClk,
         mAxisRst    => mAxisRst,
         mAxisMaster => mAxisMaster,
         mAxisSlave  => mAxisSlave,
         mTLastTUser => mTLastTUser); 

end rtl;
