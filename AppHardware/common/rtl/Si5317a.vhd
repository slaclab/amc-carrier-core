-------------------------------------------------------------------------------
-- File       : Si5317a.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2018-04-24
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
      TPD_G         : time    := 1 ns;
      TIMING_MODE_G : boolean := true);  -- true = 185 MHz clock, false = 119 MHz clock
   port (
      -- PLL Parallel Interface
      pllLos          : in    sl;
      pllLol          : in    sl;
      pllRstL         : out   sl;
      pllInc          : out   sl;
      pllDec          : out   sl;
      pllBypass       : inout sl;
      pllFrqTbl       : inout sl;
      pllRate         : inout slv(1 downto 0);
      pllSFout        : inout slv(1 downto 0);
      pllBwSel        : inout slv(1 downto 0);
      pllFrqSel       : inout slv(3 downto 0);
      pllLocked       : out   sl;
      -- Misc Interface
      userValueIn     : in    slv(31 downto 0);
      userValueOut    : out   slv(31 downto 0);
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
      los            : sl;
      lol            : sl;
      locked         : sl;
      cntRst         : sl;
      cntLos         : slv(31 downto 0);
      cntLol         : slv(31 downto 0);
      cntLocked      : slv(31 downto 0);
      cntPllRst      : slv(31 downto 0);
      pllRst         : sl;
      pllInc         : sl;
      pllDec         : sl;
      pllBypass      : sl;
      pllBypassTri   : sl;
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
      userValueOut   : slv(31 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      los            => '0',
      lol            => '0',
      locked         => '0',
      cntRst         => '1',
      cntLos         => (others => '0'),
      cntLol         => (others => '0'),
      cntLocked      => (others => '0'),
      cntPllRst      => (others => '0'),
      pllRst         => '1',
      pllInc         => '0',
      pllDec         => '0',
      -- Default: DBL2_BY  : M = CKOUT2 disabled  (See Table 14 of datasheet)
      pllBypass      => '1',
      pllBypassTri   => '1',
      -- Default: FrqTbl   : M (See Table 8 of datasheet)
      pllFrqTbl      => '1',
      pllFrqTblTri   => '1',
      -- Default: RateSel  : MM (See Table 13 of datasheet)
      pllRate        => "11",
      pllRateTri     => "11",
      -- Default: SFout    : HM = LVDS (See Table 12 of datasheet)
      pllSFout       => "11",
      pllSFoutTri    => "01",
      -- Default: BwSel    : MM (See Table 12 of datasheet)
      pllBwSel       => "11",
      pllBwSelTri    => "11",
      -- Default: FrqSel   : ite(TIMING_MODE_G,HMMH,HLLM) (See Table 12 of datasheet)
      pllFrqSel      => ite(TIMING_MODE_G, "1111", "1001"),
      pllFrqSelTri   => ite(TIMING_MODE_G, "0110", "0001"),
      -- MISC
      userValueOut   => (others => '0'),
      -- AXI-Lite
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal los    : sl;
   signal lol    : sl;
   signal locked : sl;

   -- attribute dont_touch      : string;
   -- attribute dont_touch of r : signal is "TRUE";

begin

   pllLocked <= locked;
   locked    <= not(los) and not(lol);

   U_pllLos : entity work.Debouncer
      generic map (
         TPD_G             => TPD_G,
         INPUT_POLARITY_G  => '1',
         OUTPUT_POLARITY_G => '1')
      port map (
         clk => axilClk,
         i   => pllLos,
         o   => los);

   U_pllLol : entity work.Debouncer
      generic map (
         TPD_G             => TPD_G,
         INPUT_POLARITY_G  => '1',
         OUTPUT_POLARITY_G => '1')
      port map (
         clk => axilClk,
         i   => pllLol,
         o   => lol);

   U_pllBypass : IOBUF
      port map (
         IO => pllBypass,
         I  => r.pllBypass,
         O  => open,
         T  => r.pllBypassTri);

   U_pllFrqTbl : IOBUF
      port map (
         IO => pllFrqTbl,
         I  => r.pllFrqTbl,
         O  => open,
         T  => r.pllFrqTblTri);

   GEN_2B :
   for i in 1 downto 0 generate

      U_pllRate : IOBUF
         port map (
            IO => pllRate(i),
            I  => r.pllRate(i),
            O  => open,
            T  => r.pllRateTri(i));

      U_pllSFout : IOBUF
         port map (
            IO => pllSFout(i),
            I  => r.pllSFout(i),
            O  => open,
            T  => r.pllSFoutTri(i));

      U_pllBwSel : IOBUF
         port map (
            IO => pllBwSel(i),
            I  => r.pllBwSel(i),
            O  => open,
            T  => r.pllBwSelTri(i));

   end generate GEN_2B;

   GEN_4B :
   for i in 3 downto 0 generate

      U_pllFrqSel : IOBUF
         port map (
            IO => pllFrqSel(i),
            I  => r.pllFrqSel(i),
            O  => open,
            T  => r.pllFrqSelTri(i));

   end generate GEN_4B;

   comb : process (axilReadMaster, axilRst, axilWriteMaster, locked, lol, los,
                   r, userValueIn) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobes
      v.cntRst := '0';
      v.pllRst := '0';

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Map the read only registers
      axiSlaveRegister(regCon, x"00", 0, v.userValueOut);

      -- axiSlaveRegister(regCon, x"04", 0, v.pllRst);         -- BIT[00:00] -- CPSW requires all WO variables to be 32-bit size and 32-bit aligned
      axiSlaveRegister(regCon, x"04", 1, v.pllInc);         -- BIT[01:01]
      axiSlaveRegister(regCon, x"04", 2, v.pllDec);         -- BIT[02:02]
      axiSlaveRegisterR(regCon, x"04", 3, los);             -- BIT[03:03]
      axiSlaveRegisterR(regCon, x"04", 4, lol);             -- BIT[04:04]
      axiSlaveRegisterR(regCon, x"04", 5, locked);          -- BIT[05:05]
      axiSlaveRegister(regCon, x"04", 8, v.pllBypass);      -- BIT[08:08]
      axiSlaveRegister(regCon, x"04", 9, v.pllBypassTri);   -- BIT[09:09]
      axiSlaveRegister(regCon, x"04", 10, v.pllFrqTbl);     -- BIT[10:10]
      axiSlaveRegister(regCon, x"04", 11, v.pllFrqTblTri);  -- BIT[11:11]
      axiSlaveRegister(regCon, x"04", 12, v.pllRate);       -- BIT[13:12]
      axiSlaveRegister(regCon, x"04", 14, v.pllRateTri);    -- BIT[15:14]
      axiSlaveRegister(regCon, x"04", 16, v.pllSFout);      -- BIT[17:16]
      axiSlaveRegister(regCon, x"04", 18, v.pllSFoutTri);   -- BIT[19:18]
      axiSlaveRegister(regCon, x"04", 20, v.pllBwSel);      -- BIT[21:20]
      axiSlaveRegister(regCon, x"04", 22, v.pllBwSelTri);   -- BIT[23:22]
      axiSlaveRegister(regCon, x"04", 24, v.pllFrqSel);     -- BIT[27:24]
      axiSlaveRegister(regCon, x"04", 28, v.pllFrqSelTri);  -- BIT[31:28]

      axiSlaveRegisterR(regCon, x"08", 0, userValueIn);

      axiSlaveRegisterR(regCon, x"80", 0, r.cntLos);
      axiSlaveRegisterR(regCon, x"84", 0, r.cntLol);
      axiSlaveRegisterR(regCon, x"88", 0, r.cntLocked);
      axiSlaveRegisterR(regCon, x"8C", 0, r.cntPllRst);

      axiSlaveRegister(regCon, x"F8", 0, v.pllRst);  -- BIT[00:00] -- CPSW requires all WO variables to be 32-bit size and 32-bit aligned
      axiSlaveRegister(regCon, x"FC", 0, v.cntRst);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Check a local copy 
      v.los    := los;
      v.lol    := lol;
      v.locked := locked;

      -- Check for loss of signal event
      if (r.los = '0') and (los = '1') and (r.cntLos /= x"FFFFFFFF") then
         v.cntLos := r.cntLos + 1;
      end if;

      -- Check for loss of locked event
      if (r.lol = '0') and (lol = '1') and (r.cntLol /= x"FFFFFFFF") then
         v.cntLol := r.cntLol + 1;
      end if;

      -- Check for locked event
      if (r.locked = '0') and (locked = '1') and (r.cntLocked /= x"FFFFFFFF") then
         v.cntLocked := r.cntLocked + 1;
      end if;

      -- Check for rst event
      if (r.pllRst = '1') and (r.cntPllRst /= x"FFFFFFFF") then
         v.cntPllRst := r.cntPllRst + 1;
      end if;

      -- Check for counter reset
      if (r.cntRst = '1') then
         v.cntLos    := (others => '0');
         v.cntLol    := (others => '0');
         v.cntLocked := (others => '0');
         v.cntPllRst := (others => '0');
      end if;

      -- Check for change in configuration register
      if (v.pllInc /= r.pllInc)
         or (v.pllDec /= r.pllDec)
         or (v.pllBypass /= r.pllBypass)
         or (v.pllBypassTri /= r.pllBypassTri)
         or (v.pllFrqTbl /= r.pllFrqTbl)
         or (v.pllFrqTblTri /= r.pllFrqTblTri)
         or (v.pllRate /= r.pllRate)
         or (v.pllRateTri /= r.pllRateTri)
         or (v.pllSFout /= r.pllSFout)
         or (v.pllSFoutTri /= r.pllSFoutTri)
         or (v.pllBwSel /= r.pllBwSel)
         or (v.pllBwSelTri /= r.pllBwSelTri)
         or (v.pllFrqSel /= r.pllFrqSel)
         or (v.pllFrqSelTri /= r.pllFrqSelTri) then
         -- Issue a reset automatically in firmware
         v.pllRst := '1';
      end if;

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      pllInc         <= r.pllInc;
      pllDec         <= r.pllDec;
      userValueOut   <= r.userValueOut;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_pllRst : entity work.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '1',         -- active HIGH input
         OUT_POLARITY_G => '0',         -- active LOW output
         DURATION_G     => 15625000)    -- 100 ms
      port map (
         clk    => axilClk,
         arst   => r.pllRst,
         rstOut => pllRstL);

end rtl;
