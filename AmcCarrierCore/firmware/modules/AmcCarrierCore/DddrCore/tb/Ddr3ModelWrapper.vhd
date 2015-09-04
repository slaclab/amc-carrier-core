-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Ddr3ModelWrapper.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-08-06
-- Last update: 2015-08-06
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

entity Ddr3ModelWrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      ddrDm   : inout slv(7 downto 0);
      ddrDqsP : inout slv(7 downto 0);
      ddrDqsN : inout slv(7 downto 0);
      ddrDq   : inout slv(63 downto 0);
      ddrA    : in    slv(15 downto 0);
      ddrBa   : in    slv(2 downto 0);
      ddrCsL  : in    slv(1 downto 0);
      ddrOdt  : in    slv(1 downto 0);
      ddrCke  : in    slv(1 downto 0);
      ddrCkP  : in    slv(1 downto 0);
      ddrCkN  : in    slv(1 downto 0);
      ddrWeL  : in    sl;
      ddrRasL : in    sl;
      ddrCasL : in    sl;
      ddrRstL : in    sl);
end Ddr3ModelWrapper;

architecture wrapper of Ddr3ModelWrapper is

   component ddr3
      port (
         rst_n   : in    sl;
         ck      : in    sl;
         ck_n    : in    sl;
         cke     : in    sl;
         cs_n    : in    sl;
         ras_n   : in    sl;
         cas_n   : in    sl;
         we_n    : in    sl;
         dm_tdqs : inout slv(0 downto 0);
         ba      : in    slv(2 downto 0);
         addr    : in    slv(15 downto 0);
         dq      : inout slv(7 downto 0);
         dqs     : inout slv(0 downto 0);
         dqs_n   : inout slv(0 downto 0);
         tdqs_n  : out   slv(0 downto 0);
         odt     : in    sl);     
   end component;

   constant MRS_C : slv(2 downto 0) := "000";
   constant REF_C : slv(2 downto 0) := "001";
   constant PRE_C : slv(2 downto 0) := "010";
   constant ACT_C : slv(2 downto 0) := "011";
   constant WR_C  : slv(2 downto 0) := "100";
   constant RD_C  : slv(2 downto 0) := "101";
   constant ZQC_C : slv(2 downto 0) := "110";
   constant NOP_C : slv(2 downto 0) := "111";
   
   type StateType is (
      DSEL_S,
      MRS_S,
      REF_S,
      PRE_S,
      ACT_S,
      WR_S,
      RD_S,
      ZQC_S,
      NOP_S,
      UNDEFINE_S);   

   signal ddrState : StateType       := UNDEFINE_S;
   signal ddrCmd   : slv(2 downto 0) := (others => '0');
   signal tDqsN    : slv(7 downto 0) := (others => '0');
   
begin

   GEN_RANK :
   for rank in 1 downto 0 generate
      GEN_IC :
      for ic in 7 downto 0 generate
         DDR3_Inst : ddr3
            port map (
               rst_n      => ddrRstL,
               ck         => ddrCkP(rank),
               ck_n       => ddrCkN(rank),
               cke        => ddrCke(rank),
               cs_n       => ddrCsL(rank),
               ras_n      => ddrRasL,
               cas_n      => ddrCasL,
               we_n       => ddrWeL,
               dm_tdqs(0) => ddrDm(ic),
               ba         => ddrBa,
               addr       => ddrA,
               dq         => ddrDq(7+(8*ic) downto (8*ic)),
               dqs(0)     => ddrDqsP(ic),
               dqs_n(0)   => ddrDqsN(ic),
               tdqs_n(0)  => tDqsN(ic),
               odt        => ddrOdt(rank));     
      end generate GEN_IC;
   end generate GEN_RANK;

   ddrCmd <= ddrRasL & ddrCasL & ddrWeL;

   process(ddrCmd, ddrCsL)
   begin
      if ddrCsL = "11" then
         ddrState <= DSEL_S;
      else
         case ddrCmd is
            when MRS_C =>
               ddrState <= MRS_S;
            when REF_C =>
               ddrState <= REF_S;
            when PRE_C =>
               ddrState <= PRE_S;
            when ACT_C =>
               ddrState <= ACT_S;
            when WR_C =>
               ddrState <= WR_S;
            when RD_C =>
               ddrState <= RD_S;
            when ZQC_C =>
               ddrState <= ZQC_S;
            when NOP_C =>
               ddrState <= NOP_S;
            when others =>
               ddrState <= UNDEFINE_S;
         end case;
      end if;
   end process;

end wrapper;
