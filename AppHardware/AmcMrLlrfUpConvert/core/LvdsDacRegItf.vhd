-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:  Register decoding for Signal generator
--               0x00 (RW)- Control Register
--                              Bit0: Enable DAC signal generator
--                              Bit1: Load TAP delays from registers tapDelayIn_o
--               0x01 (RW)- Polarity of the corresponding LVDS output (15 downto 0)
--                            - '0' Regular
--                            - '1' Inverted
--               0x02 (RW)- Signal period size. In number of Block RAM addresses (two samples per address). Zero inclusive.
--                          Example for 16 sample period write 7.
--               0x1X (RW)- Set tap delay values for corresponding LVDS DAC outputs
--               0x2X (R) - Current tap delay values
--
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity LvdsDacRegItf is
   generic (
      -- General Configurations
      TPD_G        : time     := 1 ns;
      ADDR_WIDTH_G : positive := 9);
   port (
      -- devClk2x Reference (devClk2x_i domain)
      devClk2x_i      : in  sl;
      devRst2x_i      : in  sl;
      periodSize_o    : out slv(ADDR_WIDTH_G-1 downto 0);
      -- AXI-Lite Interface (axilClk_i domain)
      axilClk_i       : in  sl;
      axilRst_i       : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Control generation  (devClk_i domain)
      devClk_i        : in  sl;
      devRst_i        : in  sl;
      enable_o        : out sl;
      polarityMask_o  : out slv(15 downto 0);
      -- Delay control (devClk_i domain)
      load_o          : out slv(15 downto 0);
      tapDelaySet_o   : out Slv9Array(15 downto 0);
      tapDelayStat_i  : in  Slv9Array(15 downto 0));
end LvdsDacRegItf;

architecture rtl of LvdsDacRegItf is

   type RegType is record
      control        : slv(0 downto 0);
      periodSize     : slv(ADDR_WIDTH_G-1 downto 0);
      polarityMask   : slv(15 downto 0);
      load           : slv(15 downto 0);
      tapDelaySet    : Slv9Array(15 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      control        => "0",
      periodSize     => toSlv(16, ADDR_WIDTH_G),
      polarityMask   => x"fff4",
      load           => (others => '0'),
      tapDelaySet    => (others => (others => '0')),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal s_RdAddr       : natural := 0;
   signal s_WrAddr       : natural := 0;
   signal s_tapDelayStat : Slv9Array(15 downto 0);

begin

   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer(axilReadMaster.araddr(9 downto 2));
   s_WrAddr <= conv_integer(axilWriteMaster.awaddr(9 downto 2));

   comb : process (axilReadMaster, axilRst_i, axilWriteMaster, r, s_RdAddr,
                   s_WrAddr, s_tapDelayStat) is
      variable v             : RegType;
      variable axilStatus    : AxiLiteStatusType;
      variable axilWriteResp : slv(1 downto 0);
      variable axilReadResp  : slv(1 downto 0);
   begin
      -- Latch the current value
      v := r;

      ----------------------------------------------------------------------------------------------
      -- Axi-Lite interface
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axilStatus);

      if (axilStatus.writeEnable = '1') then
         axilWriteResp := ite(axilWriteMaster.awaddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         case (s_WrAddr) is
            when 16#00# =>              -- ADDR (0)
               v.control := axilWriteMaster.wdata(0 downto 0);
            when 16#01# =>              -- ADDR (8)
               v.polarityMask := axilWriteMaster.wdata(15 downto 0);
            when 16#02# =>              -- ADDR (12)
               v.periodSize := axilWriteMaster.wdata(ADDR_WIDTH_G-1 downto 0);
            when 16#03# =>              -- ADDR (16)
               v.load := axilWriteMaster.wdata(15 downto 0);
            when 16#10# to 16#1F# =>
               for I in 15 downto 0 loop
                  if (axilWriteMaster.awaddr(5 downto 2) = I) then
                     v.tapDelaySet(I) := axilWriteMaster.wdata(8 downto 0);
                  end if;
               end loop;
            when others =>
               axilWriteResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>              -- ADDR (0)
               v.axilReadSlave.rdata(0 downto 0) := r.control;
            when 16#01# =>              -- ADDR (8)
               v.axilReadSlave.rdata(15 downto 0) := r.polarityMask;
            when 16#02# =>              -- ADDR (12)
               v.axilReadSlave.rdata(ADDR_WIDTH_G-1 downto 0) := r.periodSize;
            when 16#03# =>              -- ADDR (16)
               v.axilReadSlave.rdata(15 downto 0) := r.load;
            when 16#10# to 16#1F# =>
               for I in 15 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(8 downto 0) := r.tapDelaySet(I);
                  end if;
               end loop;
            when 16#20# to 16#2F# =>
               for I in 15 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = I) then
                     v.axilReadSlave.rdata(8 downto 0) := s_tapDelayStat(I);
                  end if;
               end loop;
            when others =>
               axilReadResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveReadResponse(v.axilReadSlave);
      end if;

      -- Reset
      if (axilRst_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

   end process comb;

   seq : process (axilClk_i) is
   begin
      if rising_edge(axilClk_i) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   GEN_0 : for i in 15 downto 0 generate

      Sync_tapDelayStat : entity surf.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 9)
         port map (
            clk     => axilClk_i,
            dataIn  => tapDelayStat_i(i),
            dataOut => s_tapDelayStat(i));

   end generate GEN_0;

   Sync_enable : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => r.control(0),
         dataOut => enable_o);

   Sync_load : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => devClk_i,
         dataIn  => r.load,
         dataOut => load_o);

   Sync_periodSize : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => ADDR_WIDTH_G)
      port map (
         clk     => devClk2x_i,
         dataIn  => r.periodSize,
         dataOut => periodSize_o);

   Sync_polarityMask : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 16)
      port map (
         clk     => devClk_i,
         dataIn  => r.polarityMask,
         dataOut => polarityMask_o);

   GEN_1 : for i in 15 downto 0 generate

      Sync_tapDelaySet : entity surf.SynchronizerVector
         generic map (
            TPD_G   => TPD_G,
            WIDTH_G => 9)
         port map (
            clk     => devClk_i,
            dataIn  => r.tapDelaySet(i),
            dataOut => tapDelaySet_o(i));

   end generate GEN_1;

end rtl;
