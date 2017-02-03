-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      Pulse_Delay20.vhd -
--
-- This file is part of 'LCLS2 BPM Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 BPM Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
--
--      Author: Jeff Olsen
--      Created on: 08/23/05 
--      Last change: JO 12/2/2015 4:05:14 PM
--
-- 
-- Created by Jeff Olsen 08/23/05
--
--  Filename: prog_strobe.vhd
--
--  Function:
--  Generate delayed  Pulse
--
--  Modifications:
--  04/21/06 jjo
--  Changed to 24 bit registers
--  Use only 1 counter for both delay and width
--
-- Documented by Chengcheng Xu 07/26/12
-- This module will generate a delayed pulse base on the input delay variable
-- The delay is measured from the triggerin + the delay(note the delay is based on the clk freq)
-- The pulse width control is controled by the width of the triggerin pulse
--
--
--

Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Entity pulse_delay20 is
Port (
	Clock 		: in std_logic;
	Reset 		: in std_logic;
	TriggerIn 	: in std_logic;
	Delay  		: in std_logic_vector(19 downto 0);
	Pulse 		: out std_logic
	);
end pulse_delay20 ;

Architecture Behaviour of pulse_delay20 is
					
signal Cntr 		: std_logic_vector(19 downto 0);
signal TrigSr 		: std_logic_vector(1 downto 0);

Begin

DelayandPulse: Process(CLock, Reset)
Begin
If (Reset = '1') then
	Cntr		<= (Others => '0');
	TrigSr	<= "00";
	Pulse 	<= '0';
elsif (Clock'event and Clock = '1') then
	TrigSr <= TrigSr(0) & TriggerIn;
	Pulse <= '0';
	if (Trigsr = "01") then
		if (Delay = x"00") then
			Pulse <= '1';
		else
			Cntr <= Delay;
		end if;
	end if;
	
	if (cntr /= x"00000") then
		cntr <= cntr - 1;
	end if;

	if (cntr = x"00001") then
		Pulse <= '1';
	end if;

end if;

end process; --DelayandPulse

end Behaviour;