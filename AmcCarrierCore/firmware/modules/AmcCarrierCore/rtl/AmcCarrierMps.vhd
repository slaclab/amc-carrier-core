-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMps.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-04
-- Last update: 2015-09-04
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierMps is
   generic (
      TPD_G        : time                := 1 ns;
      MPS_SLOT_G   : boolean             := false;
      MPS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(4));
   port (
      mps125MHzClk : in  sl;
      mps125MHzRst : in  sl;
      mps312MHzClk : in  sl;
      mps312MHzRst : in  sl;
      mps625MHzClk : in  sl;
      mps625MHzRst : in  sl;
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;      
      ----------------------
      -- Top Level Interface
      ----------------------
      -- MPS Interface
      mpsClk       : in  sl;
      mpsRst       : in  sl;
      mpsIbMaster  : in  AxiStreamMasterType;
      mpsIbSlave   : out AxiStreamSlaveType;
      mpsObMasters : out AxiStreamMasterArray(14 downto 1);
      mpsObSlaves  : in  AxiStreamSlaveArray(14 downto 1);
      mpsTxLinkUp  : out sl;
      mpsRxLinkUp  : out slv(14 downto 1);
      ----------------
      -- Core Ports --
      ----------------
      -- Backplane MPS Ports
      mpsBusRxP    : in  slv(14 downto 1);
      mpsBusRxN    : in  slv(14 downto 1);
      mpsBusTxP    : out  slv(14 downto 1);
      mpsBusTxN    : out  slv(14 downto 1);      
      mpsTxP       : out sl;
      mpsTxN       : out sl);
end AmcCarrierMps;

architecture mapping of AmcCarrierMps is

   signal iDelayCtrlRdy : sl;
   
   signal dummyTxP       : slv(14 downto 1);
   signal dummyTxN       : slv(14 downto 1);

begin

   U_SaltDelayCtrl : entity work.SaltDelayCtrl
      generic map (
         TPD_G           => TPD_G,
         IODELAY_GROUP_G => "SALT_IODELAY_GRP")
      port map (
         iDelayCtrlRdy => iDelayCtrlRdy,
         refClk        => mps625MHzClk,
         refRst        => mps625MHzRst);    

   APP_SLOT : if (MPS_SLOT_G = false) generate
      
      mpsRxLinkUp  <= (others => '0');
      mpsObMasters <= (others => AXI_STREAM_MASTER_INIT_C);

      U_SaltUltraScale : entity work.SaltUltraScale
         generic map (
            TPD_G               => TPD_G,
            TX_ENABLE_G         => true,
            RX_ENABLE_G         => false,
            COMMON_TX_CLK_G     => false,
            COMMON_RX_CLK_G     => false,
            SLAVE_AXI_CONFIG_G  => MPS_CONFIG_G,
            MASTER_AXI_CONFIG_G => MPS_CONFIG_G)
         port map (
            -- TX Serial Stream
            txP           => mpsTxP,
            txN           => mpsTxN,
            -- RX Serial Stream
            rxP           => '0',
            rxN           => '1',
            -- Reference Signals
            clk125MHz     => mps125MHzClk,
            rst125MHz     => mps125MHzRst,
            clk312MHz     => mps312MHzClk,
            clk625MHz     => mps625MHzClk,
            iDelayCtrlRdy => iDelayCtrlRdy,
            linkUp        => mpsTxLinkUp,
            -- Slave Port
            sAxisClk      => mpsClk,
            sAxisRst      => mpsRst,
            sAxisMaster   => mpsIbMaster,
            sAxisSlave    => mpsIbSlave,
            -- Master Port
            mAxisClk      => mpsClk,
            mAxisRst      => mpsRst,
            mAxisMaster   => open,
            mAxisSlave    => AXI_STREAM_SLAVE_FORCE_C);            
            
      GEN_VEC :
      for i in 14 downto 1 generate
         U_IBUFDS : IBUFDS
            generic map ( 
               DIFF_TERM => false ) 
            port map(
               I      => mpsBusRxP(i),
               IB     => mpsBusRxN(i),
               O      => open);
      end generate GEN_VEC;
      
   end generate;


   MPS_SLOT : if (MPS_SLOT_G = true) generate
      
      mpsTxLinkUp <= '0';
      mpsIbSlave  <= AXI_STREAM_SLAVE_FORCE_C;

      U_OBUFDS : OBUFTDS
         port map (
            I  => '0',
            T  => '1',
            O  => mpsTxP,
            OB => mpsTxN);      

      GEN_VEC :
      for i in 14 downto 1 generate
         U_SaltUltraScale : entity work.SaltUltraScale
            generic map (
               TPD_G               => TPD_G,
               TX_ENABLE_G         => false,
               RX_ENABLE_G         => true,
               COMMON_TX_CLK_G     => false,
               COMMON_RX_CLK_G     => false,
               SLAVE_AXI_CONFIG_G  => MPS_CONFIG_G,
               MASTER_AXI_CONFIG_G => MPS_CONFIG_G)
            port map (
               -- TX Serial Stream
               txP           => mpsBusTxP(i),
               txN           => mpsBusTxN(i),
               -- RX Serial Stream
               rxP           => mpsBusRxP(i),
               rxN           => mpsBusRxN(i),
               -- Reference Signals
               clk125MHz     => mps125MHzClk,
               rst125MHz     => mps125MHzRst,
               clk312MHz     => mps312MHzClk,
               clk625MHz     => mps625MHzClk,
               iDelayCtrlRdy => iDelayCtrlRdy,
               linkUp        => mpsRxLinkUp(i),
               -- Slave Port
               sAxisClk      => mpsClk,
               sAxisRst      => mpsRst,
               sAxisMaster   => AXI_STREAM_MASTER_INIT_C,
               sAxisSlave    => open,
               -- Master Port
               mAxisClk      => mpsClk,
               mAxisRst      => mpsRst,
               mAxisMaster   => mpsObMasters(i),
               mAxisSlave    => mpsObSlaves(i));             
      end generate GEN_VEC;
      
   end generate;

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
         
end mapping;
