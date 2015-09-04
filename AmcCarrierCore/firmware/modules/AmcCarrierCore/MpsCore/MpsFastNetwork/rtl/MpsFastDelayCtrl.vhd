-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsFastDelayCtrl.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-16
-- Last update: 2015-06-16
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

library UNISIM;
use UNISIM.vcomponents.all;

entity MpsFastDelayCtrl is
   generic (
      TPD_G           : time   := 1 ns;
      IODELAY_GROUP_G : string := "MPS_IODELAY_GRP");   
   port (
      ready     : out sl;
      clk200MHz : in  sl;
      rst200MHz : in  sl);      
end MpsFastDelayCtrl;

architecture mapping of MpsFastDelayCtrl is
   
   attribute IODELAY_GROUP                    : string;
   attribute IODELAY_GROUP of IDELAYCTRL_Inst : label is IODELAY_GROUP_G;
   
begin
   
   IDELAYCTRL_Inst : IDELAYCTRL
      port map (
         RDY    => ready,               -- 1-bit output: Ready output
         REFCLK => clk200MHz,           -- 1-bit input: Reference clock input
         RST    => rst200MHz);            -- 1-bit input: Active high reset input
         

end mapping;
