-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:  Registers 
--               0x00(RW)- CFG register - Default 0xFFFC(AD7682/AD7689 Data-sheet, Table 11)
--                   bit15-CFG
--                   bit14-INCC
--                   bit13-INCC
--                   bit12-INCC
--                   bit11-INx
--                   bit10-INx
--                   bit09-INx
--                   bit08-BW
--                   bit07-REF
--                   bit06-REF
--                   bit05-REF
--                   bit04-SEQ
--                   bit03-SEQ
--                   bit02-RB
--                   bit01-XX
--                   bit00-XX
--
--               0x10-1X(RO)- ADC values (0-3)
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

entity AxiSpiAd7682Reg is
   generic (
      -- General Configurations
      TPD_G             : time     := 1 ns;
      AXIL_ADDR_WIDTH_G : positive := 8;
      N_INPUTS_G        : positive := 4  -- 4-AD7682, 8-AD7689
      );
   port (
      -- AXI Clk
      axiClk_i : in sl;
      axiRst_i : in sl;

      -- Axi-Lite Register Interface (axiClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Registers
      we_o        : out sl;
      cfgReg_o    : out slv(15 downto 0);
      inDataArr_i : in  slv16Array(N_INPUTS_G-1 downto 0)
      );
end AxiSpiAd7682Reg;

architecture rtl of AxiSpiAd7682Reg is

   type RegType is record
      -- 
      cfgReg : slv(cfgReg_o'range);
      we     : sl;

      -- AXI lite
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      --
      cfgReg         => x"FFFC",
      we             => '0',
      -- AXI lite 
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Integer address
   signal s_RdAddr : natural := 0;
   signal s_WrAddr : natural := 0;

begin

   -- Convert address to integer (lower two bits of address are always '0')
   s_RdAddr <= conv_integer(axilReadMaster.araddr(AXIL_ADDR_WIDTH_G-1 downto 2));
   s_WrAddr <= conv_integer(axilWriteMaster.awaddr(AXIL_ADDR_WIDTH_G-1 downto 2));

   comb : process (axiRst_i, axilReadMaster, axilWriteMaster, inDataArr_i, r,
                   s_RdAddr, s_WrAddr) is
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

      -- Register we
      v.we := axilStatus.writeEnable;

      if (axilStatus.writeEnable = '1') then
         axilWriteResp := ite(axilWriteMaster.awaddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         case (s_WrAddr) is
            when 16#00# =>              -- ADDR (0x0)
               v.cfgReg := axilWriteMaster.wdata(cfgReg_o'range);
            when others =>
               axilWriteResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveWriteResponse(v.axilWriteSlave);
      end if;

      if (axilStatus.readEnable = '1') then
         axilReadResp          := ite(axilReadMaster.araddr(1 downto 0) = "00", AXI_RESP_OK_C, AXI_RESP_DECERR_C);
         v.axilReadSlave.rdata := (others => '0');
         case (s_RdAddr) is
            when 16#00# =>              -- ADDR (0x0)
               v.axilReadSlave.rdata(cfgReg_o'range) := r.cfgReg;
            when 16#10# to 16#1F# =>    -- ADDR (0x40)
               for i in N_INPUTS_G-1 downto 0 loop
                  if (axilReadMaster.araddr(5 downto 2) = i) then
                     v.axilReadSlave.rdata(inDataArr_i(i)'range) := inDataArr_i(i);
                  end if;
               end loop;
            when others =>
               axilReadResp := AXI_RESP_DECERR_C;
         end case;
         axiSlaveReadResponse(v.axilReadSlave);
      end if;

      -- Reset
      if (axiRst_i = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;
      cfgReg_o       <= r.cfgReg;
      we_o           <= r.we;
   end process comb;

   seq : process (axiClk_i) is
   begin
      if rising_edge(axiClk_i) then
         r <= rin after TPD_G;
      end if;
   end process seq;


---------------------------------------------------------------------
end rtl;
