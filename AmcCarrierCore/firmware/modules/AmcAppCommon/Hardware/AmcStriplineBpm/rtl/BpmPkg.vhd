------------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--      bpm_pkg.vhd - 
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
--      Last change: JO 12/2/2015 4:08:49 PM
--
-- 
-- Created by Jeff Olsen 02/16/05
--
--  Filename: bpm_pkg.vhd
--
--  Function:
--  Package declarations for LCLS BPM

--
--  Modifications:


Library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.NUMERIC_STD.all;

Library work;
use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

Package BPMPkg is



Constant OscOn_Tick 					: slv(19 downto 0) := x"004B0";
Constant OscMode_Auto	: std_logic_vector(1 downto 0) := "00";
Constant OscMode_On		: std_logic_vector(1 downto 0) := "01";
Constant OscMode_Off		: std_logic_vector(1 downto 0) := "10";
Constant OscMode_Unused	: std_logic_vector(1 downto 0) := "11";


--Constant CAL_CLK_FREQ				: real := 156.25E6;

--Constant TRIG2AMP_Default	: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,2.0E3),20);	-- 1/500us 	= 2.0E3
--Constant RF12RF2_Default	: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,500.0E3),20);	-- 1/2us 	= 500.0E3
--Constant RFWIDTH_Default	: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,3.33E6),20);	-- 1/300ns 	= 3.33E6
--Constant OFFTIME_Default	: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,500.0E3),20);	-- 1/2us 	= 500.0E3
		
--Constant Trig2Beam_Default	: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,10.0E6),20);	-- 1/100ns  = 310E6
--Constant RF2Red_Default		: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,3.33E6),20);	-- 1/300ns 	= 3.33E6
--Constant RF2Green_Default	: slv(19 downto 0) := toslv(getTimeRatio(CAL_CLK_FREQ,3.33E6),20);	-- 1/300ns 	= 3.33E6


Constant NoCalMode			: slv(1 downto 0) := "00";
Constant RedMode				: slv(1 downto 0) := "01";
Constant GreenMode			: slv(1 downto 0) := "10";
Constant BothMode				: slv(1 downto 0) := "11";

component cal_seq is
Port (
	Clock 		: in sl;
	Reset 		: in sl;
	Clk_Ok		: in sl;
	Cal_Trigger : in sl;
	Cal_En		: in sl;

	ModeSel		: in slv(1 downto 0);
	OscMode		: in slv(1 downto 0);

	TRIG2AMP		: in slv(19 downto 0);
	AMP2RF1		: in slv(19 downto 0);
	RF12RF2		: in slv(19 downto 0);
	RFWIDTH		: in slv(19 downto 0);
	OFFTIME		: in slv(19 downto 0);

	Trig2Beam	: in slv(19 downto 0);
	RF2Red		: in slv(19 downto 0);
	RF2Green		: in slv(19 downto 0);

	CAL_SW		: out slv(6 downto 1);
	Osc_En		: out sl;
	AMP_On 		: out sl;

	ADCTrigger	: out sl;

	CALDone		: out sl
    );
end component; --cal_seq

component pulse_delay20
Port (
	Clock 		: in sl;
	Reset 		: in sl;
	TriggerIn 	: in sl;
	Delay  		: in slv(19 downto 0);
	Pulse 		: out sl
	);
end component; --pulse_delay20;


--jjo

  procedure axiSlaveRegisterSat (
      signal axiWriteMaster  	: in    AxiLiteWriteMasterType;
      signal axiReadMaster   	: in    AxiLiteReadMasterType;
      variable axiWriteSlave 	: inout AxiLiteWriteSlaveType;
      variable axiReadSlave  	: inout AxiLiteReadSlaveType;
      variable axiStatus     	: in    AxiLiteStatusType;
      addr                   	: in    slv;
      offset                 	: in    integer;
      reg                    	: inout slv;
      Max	             		: in    integer;
      Min              	     	: in    integer);
      
end BpmPkg;

package body BpmPkg is

  procedure axiSlaveRegisterSat (
      signal axiWriteMaster 	: in    AxiLiteWriteMasterType;
      signal axiReadMaster    : in    AxiLiteReadMasterType;
      variable axiWriteSlave  : inout AxiLiteWriteSlaveType;
      variable axiReadSlave  	: inout AxiLiteReadSlaveType;
      variable axiStatus     	: in    AxiLiteStatusType;
      addr                   	: in    slv;
      offset                 	: in    integer;
      reg                   	: inout slv;
      Max	             		: in    integer;
      Min              	    	: in    integer) is
      
      variable tmpMax	: slv(31 downto 0);
      variable tmpMin	: slv(31 downto 0);
      variable Data		: integer;
  begin
  		tmpMax 	:= std_logic_vector(to_signed(Max,32));
  		tmpMin	:= std_logic_vector(to_signed(Min,32));
  		data		:= to_integer(signed(axiWriteMaster.wdata));
      -- Read must come first so as not to overwrite the variable if read and write happen at once
      if (axiStatus.readEnable = '1') then
         if (std_match(axiReadMaster.araddr(addr'length-1 downto 0), addr)) then
            axiReadSlave.rdata(offset+reg'length-1 downto offset) := reg;
            axiSlaveReadResponse(axiReadSlave);
         end if;
      end if;

      if (axiStatus.writeEnable = '1') then
         if (std_match(axiWriteMaster.awaddr(addr'length-1 downto 0), addr)) then
				if (Data  > Max) then
              	reg := tmpMax(offset+reg'length-1 downto offset);
				elsif (Data < Min) then
					reg := tmpMin(offset+reg'length-1 downto offset);	
				else
					reg := axiWriteMaster.wdata(offset+reg'length-1 downto offset);
				end if;

            axiSlaveWriteResponse(axiWriteSlave);
         end if;
      end if;

   end procedure;

end package body BpmPkg;
