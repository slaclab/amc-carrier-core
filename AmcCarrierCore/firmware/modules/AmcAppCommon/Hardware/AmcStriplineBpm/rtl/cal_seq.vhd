-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  cal_seq.vhd -
--
-- This file is part of 'LCLS2 BPM Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 BPM Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
--
--  Author: JEFF OLSEN
--  Created on: 8/4/2006 1:01:51 PM
--  Last change: JO 12/2/2015 4:03:06 PM


-- ModeSel
--  00 => Red
--  01 => Green
--  10 => BOTH
--  11 => Beam


-------------------------------------------------------------------------------
-- 11/03/2016
-- jjo
-- Inverted the control signals
--
-------------------------------------------------------------------------------


Library work;
use work.BpmPkg.all;


Library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Entity cal_seq is
Port (
	Clock 		: in std_logic;
	Reset 		: in std_logic;
	Clk_Ok		: in std_logic;
	Cal_Trigger : in std_logic;
	Cal_En		: in std_logic;

	ModeSel		: in std_logic_vector(1 downto 0);
	OscMode		: in std_logic_vector(1 downto 0);

	TRIG2AMP		: in std_logic_vector(19 downto 0);
	AMP2RF1		: in std_logic_vector(19 downto 0);
	RF12RF2		: in std_logic_vector(19 downto 0);
	RFWIDTH		: in std_logic_vector(19 downto 0);
	OFFTIME		: in std_logic_vector(19 downto 0);

	Trig2Beam	: in std_logic_vector(19 downto 0);
	RF2Red		: in std_logic_vector(19 downto 0);
	RF2Green		: in std_logic_vector(19 downto 0);

	CAL_SW		: out std_logic_vector(6 downto 1);
	Osc_En		: out std_logic;
	AMP_On 		: out std_logic;

	ADCTrigger	: out std_logic;

	CALDone		: out std_logic
);
end cal_seq;

Architecture Behaviour of cal_seq is

Type state_t is
(
	Idle,
	Wait_OscOn,
	Wait_AMP,
	Wait_RF1,
	RF_On1,
	Wait_Off1,
	Wait_RF2,
	RF_On2,
	Wait_Off2
);

signal NextState 	: State_t;

signal iAMP_On 		: std_logic;
signal SW1 				: std_logic;
signal SW2 				: std_logic;
signal SW3 				: std_logic;
signal SW4 				: std_logic;
signal SW5 				: std_logic;
signal SW6 				: std_logic;


signal Advance 		: std_logic;
signal LdCntr 			: std_logic;
signal Counter 		: std_logic_vector(19 downto 0);
signal NextCount 		: std_logic_vector(19 downto 0);
signal AutoOscOn 		: std_logic;

Signal PulseMux		: std_logic_vector(19 downto 0);
signal PulseSel 		: std_logic_vector(1 downto 0);
signal iPulseTrig 	: std_logic;
signal iCalDone 		: std_logic;
signal iCal_TrigSr   : std_logic_vector(1 downto 0);
signal iCal_Trig		: std_logic;
signal iEn_TrigSr    : std_logic_vector(1 downto 0);
signal iCal_En			: std_logic;

Begin

AMP_On	<= iAMP_On;
Cal_Sw 	<= not(SW6 & SW5 & SW4 & SW3 &  SW2 & SW1);

PulseSel <= SW6 & SW5;

CALDone	<= iCalDone;

TriggerMode_p: process(ModeSel,iPulseTrig,SW5,SW6,Cal_Trigger)
Begin
Case ModeSel is
When GreenMode =>
    iPulseTrig <= SW6;
When RedMode =>
    iPulseTrig <= SW5;
When BothMode =>
    iPulseTrig <= SW5;
when others =>
	iPulseTrig <= '0';
end case;
end process;

u_Pulse : pulse_delay20 
Port map (
	Clock 		=> Clock,
	Reset 		=> Reset,
	TriggerIn 	=> iPulseTrig,
	Delay  		=> PulseMux,
	Pulse 		=> ADCTrigger
	);

OscOn_p: process(AutoOscOn, OscMode)
Begin
Case OscMode is
When OscMode_Auto =>
	Osc_En <= AutoOscOn;
When OscMode_On =>
	Osc_En <= '1';
When OscMode_Off =>
	Osc_En <= '0';
When Others =>
	Osc_En <= '0';
end case;
end process;

ADCTrig_p : process(PulseSel, Trig2Beam, RF2Red, RF2Green, Cal_Trigger)
begin
	Case PulseSel is
	when "01" =>
		PulseMux 	<= RF2Red;
	when "10" =>
		PulseMux 	<= RF2Green;
	when others =>
		PulseMux 	<= Trig2Beam;
end case;
end process;

sync_p : process(Clock, Reset)
begin
if (Reset = '1') then
	iCal_TrigSr  	<= (Others => '0');
	iCal_Trig		<= '0';
	iEn_TrigSr  	<= (Others => '0');
	iCal_En			<= '0';
elsif (clock'event and clock = '1') then
	iCal_TrigSr		<= iCal_TrigSr(0) & Cal_Trigger;
	iCal_Trig		<= iCal_TrigSr(1) and NOT(iCal_TrigSr(0));

	if (iCalDone = '1') then
		iEn_TrigSr 		<= (Others => '0');
	else
		iEn_TrigSr		<= iEn_TrigSr(0) & Cal_En;
	end if;
end if;
end process;
		
cntr_p : process(clock, reset)
begin
if (reset = '1') then
	Counter 	<= (Others => '0');
	Advance 	<= '0';
elsif (clock'event and clock = '1') then
	if (LdCntr = '1') then
		if (NextCount /= x"00000") then
			Counter 		<= NextCount;
			Advance 		<= '0';
		else
			Advance		<= '1';
		end if;
	elsif (Counter = x"00001") then
		Counter 		<= Counter - 1;
		Advance 		<= '1';
	elsif (Counter = x"00000") then
		Advance 		<= '0';
	else
		Counter 		<= Counter - 1;
	end if;
end if;
end process; -- cntr_p

CalSeq_p: Process(CLock, Reset, Clk_Ok)
Begin

If ((Reset = '1') or (Clk_Ok = '0')) then
	iAMP_On 		<= '0';
	SW1  			<= '0';
	SW2			<= '0';
	SW5			<= '0';
	SW6			<= '0';
	SW3			<= '0';
	SW4			<= '0';
	AutoOscOn 	<= '0';
	iCALDone		<= '0';
	LdCntr		<= '0';
	NextCount	<= (Others => '0');
	NextState 	<= Idle;
elsif (Clock'event and Clock = '1') then
	SW5 			<= SW1 and SW3;
	SW6 			<= SW1 and SW4;
	iCalDone		<= '0';
	LdCntr 		<= '0';

Case NextState is
When Idle =>
	iCalDone		<= '0';	
	If ((iEn_TrigSr(1) = '1') and (iCal_Trig = '1') ) then
		AutoOscOn 	<= '1';
		If (ModeSel = NoCalMode) then
			iCalDone 	<= '1';
			NextState 	<= Idle;
		else
			LdCntr 		<= '1';
			NextCount 	<= TRIG2AMP;
			NextState 	<= Wait_AMP;
		end if;
	else
		iAMP_On 		<= '0';
		SW1  			<= '0';
		SW2			<= '0';
		SW5			<= '0';
		SW6			<= '0';
		SW3			<= '0';
		SW4			<= '0';
		iCALDone		<= '0';
		AutoOscOn 	<= '0';
		NextState 	<= Idle;
	end if;

When Wait_AMP =>
	If (Advance = '1') then
		iAMP_On <= '1';
		Case ModeSel is
		When GreenMode =>
			SW4 <= '1';
		When others =>
			SW2 <= '1';
			SW3 <= '1';
		end case;
		LdCntr 		<= '1';
		NextCount 	<= AMP2RF1;
		NextState 	<= Wait_RF1;
	else
		NextState 	<= Wait_AMP;
	end if;

When Wait_RF1 =>
	If (Advance = '1') then
		SW1			<= '1';
		LdCntr 		<= '1';
		NextCount 	<= RFWIDTH;
		NextState 	<= RF_On1;
 	else
    	NextState 	<= Wait_RF1;
    end if;

When RF_On1 =>
	If (Advance = '1') then
		SW1			<= '0';
		LdCntr 		<= '1';
		NextCount 	<= OFFTIME;
		NextState 	<= Wait_Off1;
 	else
		NextState 	<= RF_On1;
    end if;

When Wait_Off1 =>
	If (Advance = '1') then
		Case ModeSel is
		When BOTHMode =>
			SW2 			<= '0';
			SW3			<= '0';
			SW4			<= '1';
			LdCntr 		<= '1';
			NextCount 	<= RF12RF2;
			NextState 	<= Wait_RF2;
		When others =>
			iCalDone			<= '1';
			NextState 	<= Idle;
		end case;
	else
		NextState 	<= Wait_Off1;
	end if;

When Wait_RF2 =>
	If (Advance = '1') then
		SW1			<= '1';
		LdCntr 		<= '1';
		NextCount 	<= RFWIDTH ;
		NextState 	<= RF_On2;
	else
		NextState 	<= Wait_RF2;
	end if;

When RF_On2 =>
	If (Advance = '1') then
		SW1			<= '0';
		LdCntr 		<= '1';
		NextCount 	<= OFFTIME ;
		NextState 	<= Wait_Off2;
	else
		NextState 	<= RF_On2;
	end if;

When Wait_Off2 =>
	If (Advance = '1') then
		iCalDone		<= '1';
		NextState 	<= Idle;
	else
		NextState 	<= Wait_Off2;
	end if;

When others =>
	NextState 	<= Idle;
end Case;
end if;
end process; --CalSeq_p


end behaviour;

