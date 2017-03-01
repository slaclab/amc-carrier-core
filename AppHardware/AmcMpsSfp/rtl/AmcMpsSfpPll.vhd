-------------------------------------------------------------------------------
-- File       : AmcMpsSfpPll.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2017-02-28
-------------------------------------------------------------------------------
-- Description: https://confluence.slac.stanford.edu/display/AIRTRACK/PC_379_396_13_CXX
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AmcMpsSfpPll is
   generic (
      TPD_G            : time            := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- PLL Parallel Interface
      pllRst          : out   sl;
      pllInc          : out   sl;
      pllDec          : out   sl;
      pllDbly2By      : out   sl;
      pllFrqTbl       : inout sl;
      pllRate         : inout slv(1 downto 0);
      pllSFout        : inout slv(1 downto 0);
      pllBwSel        : inout slv(1 downto 0);
      pllFrqSel       : inout slv(3 downto 0);
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType);
end AmcMpsSfpPll;

architecture rtl of AmcMpsSfpPll is

   type RegType is record
      pllRst         : sl;
      pllInc         : sl;
      pllDec         : sl;
      pllDbly2By     : sl;
      pllFrqTbl      : sl;
      pllFrqTblTri   : sl;
      pllRate        : slv(1 downto 0);
      pllRateTri     : slv(1 downto 0);
      pllSFout       : slv(1 downto 0);
      pllSFoutTri    : slv(1 downto 0);
      pllBwSel       : slv(1 downto 0);
      pllBwSelTri    : slv(1 downto 0);
      pllFrqSel      : slv(3 downto 0);
      pllFrqSelTri   : slv(3 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      pllRst         => '0',
      pllInc         => '0',
      pllDec         => '0',
      -- Default: DBLY_BY  : L       
      pllDbly2By     => '0',
      -- Default: FrqTbl   : M
      pllFrqTbl      => '1',
      pllFrqTblTri   => '1',
      -- Default: RateSel  : MM
      pllRate        => "11",
      pllRateTri     => "11",
      -- Default: SFout    : HM
      pllSFout       => "11",
      pllSFoutTri    => "01",
      -- Default: BwSel    : LL
      pllBwSel       => "00",
      pllBwSelTri    => "00",
      -- Default: FrqSel   : HMMH
      pllFrqSel      => "1111",
      pllFrqSelTri   => "0110",
      -- AXI-Lite
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- attribute dont_touch               : string;
   -- attribute dont_touch of r          : signal is "TRUE";

begin

   U_pllFrqTbl : IOBUF
      port map (
         I  => r.pllFrqTbl,
         O  => open,
         IO => pllFrqTbl,
         T  => r.pllFrqTblTri);

   GEN_2B :
   for i in 1 downto 0 generate

      U_pllRate : IOBUF
         port map (
            I  => r.pllRate(i),
            O  => open,
            IO => pllRate(i),
            T  => r.pllRateTri(i));

      U_pllSFout : IOBUF
         port map (
            I  => r.pllSFout(i),
            O  => open,
            IO => pllSFout(i),
            T  => r.pllSFoutTri(i));

      U_pllBwSel : IOBUF
         port map (
            I  => r.pllBwSel(i),
            O  => open,
            IO => pllBwSel(i),
            T  => r.pllBwSelTri(i));

   end generate GEN_2B;

   GEN_4B :
   for i in 3 downto 0 generate

      U_pllFrqSel : IOBUF
         port map (
            I  => r.pllFrqSel(i),
            O  => open,
            IO => pllFrqSel(i),
            T  => r.pllFrqSelTri(i));

   end generate GEN_4B;

   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      axiSlaveRegister(regCon, x"0", 0, v.pllRst);
      axiSlaveRegister(regCon, x"0", 1, v.pllInc);
      axiSlaveRegister(regCon, x"0", 2, v.pllDec);
      axiSlaveRegister(regCon, x"0", 3, v.pllDbly2By);
      axiSlaveRegister(regCon, x"0", 4, v.pllFrqTbl);
      axiSlaveRegister(regCon, x"0", 5, v.pllFrqTblTri);
      axiSlaveRegister(regCon, x"0", 12, v.pllRate);
      axiSlaveRegister(regCon, x"0", 14, v.pllRateTri);
      axiSlaveRegister(regCon, x"0", 16, v.pllSFout);
      axiSlaveRegister(regCon, x"0", 18, v.pllSFoutTri);
      axiSlaveRegister(regCon, x"0", 20, v.pllBwSel);
      axiSlaveRegister(regCon, x"0", 22, v.pllBwSelTri);
      axiSlaveRegister(regCon, x"0", 24, v.pllFrqSel);
      axiSlaveRegister(regCon, x"0", 28, v.pllFrqSelTri);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      pllRst         <= r.pllRst or axilRst;
      pllInc         <= r.pllInc;
      pllDec         <= r.pllDec;
      pllDbly2By     <= r.pllDbly2By;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
