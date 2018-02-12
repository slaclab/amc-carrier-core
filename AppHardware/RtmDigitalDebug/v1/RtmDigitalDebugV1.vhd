-------------------------------------------------------------------------------
-- File       : RtmDigitalDebugV1.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-23
-- Last update: 2018-02-12
-------------------------------------------------------------------------------
-- https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_10_CXX
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
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity RtmDigitalDebugV1 is
   generic (
      TPD_G            : time             := 1 ns;
      REG_DOUT_EN_G    : slv(15 downto 0) := x"0000";  -- '1' = registered, '0' = unregistered
      REG_DOUT_MODE_G  : slv(15 downto 0) := x"0000");  -- If registered enabled, '1' = clk output, '0' = data output
   port (
      -- Digital I/O Interface
      dout            : in    slv(15 downto 0);
      doutClk         : in    slv(15 downto 0)       := x"0000";
      din             : out   slv(15 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl                     := '0';
      axilRst         : in    sl                     := '0';
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
end RtmDigitalDebugV1;

architecture mapping of RtmDigitalDebugV1 is

   type RegType is record
      doutDisable    : slv(15 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      doutDisable    => x"0000",
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal doutReg  : slv(15 downto 0);
   signal doutComb : slv(15 downto 0);

begin

   GEN_VEC :
   for i in 15 downto 0 generate

      NON_REG : if (REG_DOUT_EN_G(i) = '0') generate

         doutComb(i) <= dout(i) and not(r.doutDisable(i));

         U_OBUFDS : OBUFDS
            port map (
               I  => doutComb(i),
               O  => rtmLsP(i+16),
               OB => rtmLsN(i+16));

      end generate;

      REG_OUT : if (REG_DOUT_EN_G(i) = '1') generate

         REG_DATA : if (REG_DOUT_MODE_G(i) = '0') generate
            U_ODDR : ODDRE1
               port map (
                  C  => doutClk(i),
                  Q  => doutReg(i),
                  D1 => dout(i),
                  D2 => dout(i),
                  SR => r.doutDisable(i));
            U_OBUFDS : OBUFDS
               port map (
                  I  => doutReg(i),
                  O  => rtmLsP(i+16),
                  OB => rtmLsN(i+16));
         end generate;

         REG_CLK : if (REG_DOUT_MODE_G(i) = '1') generate
            U_CLK : entity work.ClkOutBufDiff
               generic map (
                  TPD_G          => TPD_G,
                  RST_POLARITY_G => '1',
                  XIL_DEVICE_G   => "ULTRASCALE")
               port map (
                  rstIn   => r.doutDisable(i),
                  clkIn   => doutClk(i),
                  clkOutP => rtmLsP(i+16),
                  clkOutN => rtmLsN(i+16));
         end generate;

      end generate;

      U_IBUFDS : IBUFDS
         port map (
            I  => rtmLsP(i+0),
            IB => rtmLsN(i+0),
            O  => din(i));

   end generate GEN_VEC;


   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the registers 
      axiSlaveRegister(axilEp, x"0", 0, v.doutDisable);
      axiSlaveRegisterR(axilEp, x"8", 0, x"00000000");  -- Added this register to be forward compatible with v2

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end mapping;
