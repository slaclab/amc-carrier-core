-------------------------------------------------------------------------------
-- File       : MpsMitMsgRx.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-01-26
-- Last update: 2017-01-26
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Note: Do not forget to configure the ATCA crate to drive the clock from the slot#2 MPS link node
-- For the 7-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
-- For the 16-slot crate:
--    $ ipmitool -I lan -H ${SELF_MANAGER} -t 0x84 -b 0 -A NONE raw 0x2e 0x39 0x0a 0x40 0x00 0x00 0x00 0x31 0x01
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library amc_carrier_core;
use amc_carrier_core.AppMpsPkg.all;


entity MpsMitMsgRx is
   generic (
      TPD_G  : time  := 1 ns);
   port (
      -- System Signals
      clk          : in  sl;
      rst          : in  sl;
      -- Incoming data
      mpsMaster     : in  AxiStreamMasterType;
      mpsSlave      : out AxiStreamSlaveType:= AXI_STREAM_SLAVE_FORCE_C;
      mpsCtrl       : out AxiStreamCtrlType := AXI_STREAM_CTRL_UNUSED_C;
      -- Message Out
      mitMessage      : out MpsMitigationMsgType;
      msgError        : out sl
   );
end MpsMitMsgRx;

architecture rtl of MpsMitMsgRx is

   type StateType is (      
      HEADER0_S,
      HEADER1_S,
      HEADER2_S,
      CLASS_S);

   type RegType is record
      cnt            : natural range 0 to 15;
      mitMessage     : MpsMitigationMsgType;
      intError       : sl;
      msgError       : sl;
      --
      state          : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      cnt            => 0,
      mitMessage     => MPS_MITIGATION_MSG_INIT_C,
      intError       => '0',
      msgError       => '0',
      --
      state          => HEADER0_S
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin
  
   -- State machine
   comb : process (rst, r, mpsMaster) is
      variable v : RegType;
   begin

      v := r;

      -- Init
      v.mitMessage.strobe := '0';
      v.msgError  := '0';

      -- State
      case r.state is

         -- Wait for first part of frame
         when HEADER0_S =>
            v.intError := '0';
            -- Get message Latch Diag
            v.mitMessage.latchDiag  := mpsMaster.tData(14);

            -- Detect error:
            -- Check mitigation flag
            -- Check message size
            -- Check SOF
            if (mpsMaster.tData(15) /= '1'                            or 
                mpsMaster.tData(7 downto 0) /= x"0E"                  or 
                ssiGetUserSof(MPS_AXIS_CONFIG_C,mpsMaster) /= '1'       
            ) then
               v.intError := '1';
            end if;

            if mpsMaster.tValid = '1' then
               if mpsMaster.tLast = '1' then
                  v.msgError := '1';
                  v.state    := HEADER0_S;
               else
                  v.state := HEADER1_S;
               end if;
            end if;

         -- Second word
         when HEADER1_S =>

            -- Get address (ID)
            v.mitMessage.tag := mpsMaster.tData(15 downto 0);

            if mpsMaster.tValid = '1' then
               if mpsMaster.tLast = '1' then
                  v.msgError := '1';
                  v.state    := HEADER0_S;
               else
                  v.state := HEADER2_S;
               end if;
            end if;

         -- Third Word
         when HEADER2_S =>
            v.cnt := 0;

            -- Get address (ID)
            v.mitMessage.timeStamp := mpsMaster.tData(15 downto 0);

            if mpsMaster.tValid = '1' then
               if mpsMaster.tLast = '1' then
                  v.msgError := '1';
                  v.state    := HEADER0_S;
               else
                  v.state := CLASS_S;
               end if;
            end if;

         -- Payload
         when CLASS_S =>

            -- Message data
            v.mitMessage.class(r.cnt)     := mpsMaster.tData(3  downto 0);
            v.mitMessage.class(r.cnt+1)   := mpsMaster.tData(7  downto 4);
            v.mitMessage.class(r.cnt+2)   := mpsMaster.tData(11 downto 8);
            v.mitMessage.class(r.cnt+3)   := mpsMaster.tData(15 downto 12);
            
            if mpsMaster.tValid = '1' then
               v.cnt := r.cnt + 4;

               -- Message should be done but is not
               if r.cnt = 12 and mpsMaster.tLast = '0' then
                  v.intError := '1';

               -- Message should not be done but is
               elsif r.cnt /= 12 and mpsMaster.tLast = '1' then
                  v.msgError := '1';
                  v.state    := HEADER0_S;

               -- Message is done
               elsif mpsMaster.tLast = '1' then
                  v.msgError  := r.intError or ssiGetUserEofe(MPS_AXIS_CONFIG_C,mpsMaster);
                  v.mitMessage.strobe := not v.msgError;
                  v.state     := HEADER0_S;
               end if;
            end if;

         when others=>
            v.state := HEADER0_S;

      end case;

      if rst = '1' then
         v := REG_INIT_C;
      end if;

      rin <= v;

      -- Outputs
      mitMessage <= r.mitMessage;
      msgError   <= r.msgError;

   end process;

   seq : process (clk) is
   begin
      if rising_edge(clk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;

