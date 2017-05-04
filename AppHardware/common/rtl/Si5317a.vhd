-------------------------------------------------------------------------------
-- File       : Si5317a.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2017-05-04
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

entity Si5317a is
   generic (
      TPD_G            : time            := 1 ns;
      TIMING_MODE_G    : boolean         := true;  -- true = 185 MHz clock, false = 119 MHz clock
      AXI_ERROR_RESP_G : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      -- PLL Parallel Interface
      pllLos          : in    sl;
      pllLol          : in    sl;
      pllRstL         : out   sl;
      pllInc          : out   sl;
      pllDec          : out   sl;
      pllDbl2By       : inout sl;
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
end Si5317a;

architecture rtl of Si5317a is

   type RegType is record
      pllRst         : sl;
      pllInc         : sl;
      pllDec         : sl;
      pllDbl2By      : sl;
      pllDbl2ByTri   : sl;
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
      -- Default: DBL2_BY  : M = CKOUT2 disabled  (See Table 14 of datasheet)
      pllDbl2By      => '1',
      pllDbl2ByTri   => '1',
      -- Default: FrqTbl   : M (See Table 8 of datasheet)
      pllFrqTbl      => '1',
      pllFrqTblTri   => '1',
      -- Default: RateSel  : MM (See Table 13 of datasheet)
      pllRate        => "11",
      pllRateTri     => "11",
      -- Default: SFout    : HM = LVDS (See Table 12 of datasheet)
      pllSFout       => "11",
      pllSFoutTri    => "01",
      -- Default: BwSel    : HM (See Table 12 of datasheet)
      pllBwSel       => "11",
      pllBwSelTri    => "01",
      -- Default: FrqSel   : ite(TIMING_MODE_G,HMMH,HLLM) (See Table 12 of datasheet)
      pllFrqSel      => ite(TIMING_MODE_G, "1111", "1001"),
      pllFrqSelTri   => ite(TIMING_MODE_G, "0110", "0001"),
      -- AXI-Lite
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   attribute dont_touch      : string;
   attribute dont_touch of r : signal is "TRUE";

begin

   U_pllDbl2By : OBUFT
      port map (
         O => pllDbl2By,
         I => r.pllDbl2By,
         T => r.pllDbl2ByTri);

   U_pllFrqTbl : OBUFT
      port map (
         O => pllFrqTbl,
         I => r.pllFrqTbl,
         T => r.pllFrqTblTri);

   GEN_2B :
   for i in 1 downto 0 generate

      U_pllRate : OBUFT
         port map (
            O => pllRate(i),
            I => r.pllRate(i),
            T => r.pllRateTri(i));

      U_pllSFout : OBUFT
         port map (
            O => pllSFout(i),
            I => r.pllSFout(i),
            T => r.pllSFoutTri(i));

      U_pllBwSel : OBUFT
         port map (
            O => pllBwSel(i),
            I => r.pllBwSel(i),
            T => r.pllBwSelTri(i));

   end generate GEN_2B;

   GEN_4B :
   for i in 3 downto 0 generate

      U_pllFrqSel : OBUFT
         port map (
            O => pllFrqSel(i),
            I => r.pllFrqSel(i),
            T => r.pllFrqSelTri(i));

   end generate GEN_4B;

   comb : process (axilReadMaster, axilRst, axilWriteMaster, pllLol, pllLos, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      axiSlaveRegister(regCon, x"0", 0, v.pllRst);         -- BIT[00:00]
      axiSlaveRegister(regCon, x"0", 1, v.pllInc);         -- BIT[01:01]
      axiSlaveRegister(regCon, x"0", 2, v.pllDec);         -- BIT[02:02]
      axiSlaveRegisterR(regCon, x"0", 3, pllLos);          -- BIT[03:03]
      axiSlaveRegisterR(regCon, x"0", 4, pllLol);          -- BIT[04:04]
      axiSlaveRegister(regCon, x"0", 8, v.pllDbl2By);      -- BIT[08:08]
      axiSlaveRegister(regCon, x"0", 9, v.pllDbl2ByTri);   -- BIT[09:09]
      axiSlaveRegister(regCon, x"0", 10, v.pllFrqTbl);     -- BIT[10:10]
      axiSlaveRegister(regCon, x"0", 11, v.pllFrqTblTri);  -- BIT[11:11]
      axiSlaveRegister(regCon, x"0", 12, v.pllRate);       -- BIT[13:12]
      axiSlaveRegister(regCon, x"0", 14, v.pllRateTri);    -- BIT[15:14]
      axiSlaveRegister(regCon, x"0", 16, v.pllSFout);      -- BIT[17:16]
      axiSlaveRegister(regCon, x"0", 18, v.pllSFoutTri);   -- BIT[19:18]
      axiSlaveRegister(regCon, x"0", 20, v.pllBwSel);      -- BIT[21:20]
      axiSlaveRegister(regCon, x"0", 22, v.pllBwSelTri);   -- BIT[23:22]
      axiSlaveRegister(regCon, x"0", 24, v.pllFrqSel);     -- BIT[27:24]
      axiSlaveRegister(regCon, x"0", 28, v.pllFrqSelTri);  -- BIT[31:28]

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
      pllRstL        <= not(r.pllRst) and not(axilRst);
      pllInc         <= r.pllInc;
      pllDec         <= r.pllDec;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
