-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MpsFastDeSer.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-06-15
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.MpsFastPkg.all;

entity MpsFastDeSer is
   generic (
      TPD_G           : time   := 1 ns;
      IODELAY_GROUP_G : string := "MPS_IODELAY_GRP");   
   port (
      -- Fault Message
      clk100MHz    : in  sl;
      rst100MHz    : in  sl;
      linkUp       : out sl;
      linkDown     : out sl;
      fault        : out slv(15 downto 0);
      faultUpdated : out sl;
      errDetected  : out sl;
      errDecode    : out sl;
      errDisparity : out sl;
      errComma     : out sl;
      errDataK     : out sl;
      errCheckSum  : out sl;
      errSeqCnt    : out sl;
      -- RX Serial Stream
      mpsFastIbP   : in  sl;
      mpsFastIbN   : in  sl;
      clk200MHz    : in  sl;
      clk200MHzInv : in  sl;
      rst200MHz    : in  sl);      
end MpsFastDeSer;

architecture rtl of MpsFastDeSer is

   type StateType is (
      UNLOCKED_S,
      LOCKED_S);   

   type RegType is record
      linkUp       : sl;
      clkEn        : sl;
      fault        : slv(15 downto 0);
      faultUpdated : sl;
      errDetected  : sl;
      errDecode    : sl;
      errDisparity : sl;
      errComma     : sl;
      errDataK     : sl;
      errCheckSum  : sl;
      errSeqCnt    : sl;
      seqCnt       : slv(3 downto 0);
      cnt          : natural range 0 to 39;
      stableCnt    : natural range 0 to 3;
      rx           : slv(39 downto 0);
      dataIn       : slv(39 downto 0);
      state        : StateType;
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      linkUp       => '0',
      clkEn        => '0',
      fault        => (others => '1'),
      faultUpdated => '0',
      errDetected  => '0',
      errDecode    => '0',
      errDisparity => '0',
      errComma     => '0',
      errDataK     => '0',
      errCheckSum  => '0',
      errSeqCnt    => '0',
      seqCnt       => (others => '0'),
      cnt          => 0,
      stableCnt    => 0,
      rx           => (others => '0'),
      dataIn       => (others => '0'),
      state        => UNLOCKED_S);

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;
   signal serialBit : sl;
   signal clkEn     : sl;
   signal message   : slv(39 downto 0);
   signal data      : slv(31 downto 0);
   signal dataK     : slv(3 downto 0);
   signal decErr    : slv(3 downto 0);
   signal dispErr   : slv(3 downto 0);

   function ValidCheckSum (vec : slv(31 downto 0)) return boolean is
      variable checkSum : slv(3 downto 0);
      variable retVar   : boolean;
   begin
      -- Calculate the checksum
      checkSum := vec(7 downto 4);
      checkSum := checkSum + vec(11 downto 8);
      checkSum := checkSum + vec(15 downto 12);
      checkSum := checkSum + vec(19 downto 16);
      checkSum := checkSum + vec(23 downto 20);
      -- Compare the checksum
      if checkSum = vec(3 downto 0) then
         retVar := true;
      else
         retVar := false;
      end if;
      return retVar;
   end function;

   procedure CheckForErrors (
      v           : inout RegType;
      data        : in    slv(31 downto 0);
      dataK       : in    slv(3 downto 0);
      decErr      : in    slv(3 downto 0);
      dispErr     : in    slv(3 downto 0);
      checkSeqCnt : in    sl) is
   begin
      -- Check for decode error
      if (decErr /= x"0") then
         v.errDetected := '1';
         v.errDecode   := '1';
      end if;
      -- Check for disparity error
      if (dispErr /= x"0") then
         v.errDetected  := '1';
         v.errDisparity := '1';
      end if;
      -- Check for comma error
      if (data(31 downto 24) /= MPS_FAST_COMMA_8B_C) then
         v.errDetected := '1';
         v.errComma    := '1';
      end if;
      -- Check for comma error
      if (dataK /= MPS_FAST_DATAK_C) then
         v.errDetected := '1';
         v.errDataK    := '1';
      end if;
      -- Check for checksum error
      if (ValidCheckSum(data) = false) then
         v.errDetected := '1';
         v.errCheckSum := '1';
      end if;
      -- Update seqCnt value
      v.seqCnt := data(7 downto 4);
      -- Check for seqCnt error
      if (v.seqCnt /= (r.seqCnt + 1)) and (checkSeqCnt = '1') then
         v.errDetected := '1';
         v.errSeqCnt   := '1';
      end if;
   end procedure CheckForErrors;
   
begin

   MpsFastDeSerOverSmpl_Inst : entity work.MpsFastDeSerOverSmpl
      generic map (
         TPD_G           => TPD_G,
         IODELAY_GROUP_G => IODELAY_GROUP_G)
      port map (
         -- Oversampling Serial Stream
         mpsFastIbP   => mpsFastIbP,
         mpsFastIbN   => mpsFastIbN,
         clk200MHz    => clk200MHz,
         clk200MHzInv => clk200MHzInv,
         -- Down Converted serial stream
         clk100MHz    => clk100MHz,
         rst100MHz    => rst100MHz,
         serialBit    => serialBit);      

   Decoder8b10b_Inst : entity work.Decoder8b10b
      generic map (
         TPD_G       => TPD_G,
         NUM_BYTES_G => 4)
      port map (
         clkEn    => r.clkEn,
         clk      => clk100MHz,
         rst      => '0',
         dataIn   => r.dataIn,
         dataOut  => data,
         dataKOut => dataK,
         codeErr  => decErr,
         dispErr  => dispErr);        

   comb : process (data, dataK, decErr, dispErr, r, rst100MHz, serialBit) is
      variable v : RegType;
   begin
      -- Latch the current value
      v := r;

      -- Reset strobing signals
      v.clkEn        := '0';
      v.faultUpdated := '0';
      v.errDetected  := '0';
      v.errDecode    := '0';
      v.errDisparity := '0';
      v.errComma     := '0';
      v.errDataK     := '0';
      v.errCheckSum  := '0';
      v.errSeqCnt    := '0';

      -- Shift in the data the message (LSB first)
      v.rx(39)          := serialBit;
      v.rx(38 downto 0) := r.rx(39 downto 1);

      -- State Machine
      case r.state is
         ----------------------------------------------------------------------
         when UNLOCKED_S =>
            -- Check for valid message
            if (r.stableCnt = 0) then
               -- Check for comma
               if (v.rx(39 downto 30) = MPS_FAST_COMMA_10B_C(0)) or (v.rx(39 downto 30) = MPS_FAST_COMMA_10B_C(1)) then
                  v.clkEn  := '1';
                  v.dataIn := v.rx;
                  -- Check for errors
                  CheckForErrors(v, data, dataK, decErr, dispErr, '0');
                  -- Check for valid message
                  if v.errDetected = '0' then
                     -- Increment the counter
                     v.stableCnt := r.stableCnt + 1;
                     -- Reset the counter
                     v.cnt       := 0;
                  end if;
               end if;
            else
               -- Increment the counter
               v.cnt := r.cnt + 1;
               -- Check the counter
               if r.cnt = 39 then
                  -- Reset the counter
                  v.cnt    := 0;
                  -- Set the flag
                  v.clkEn  := '1';
                  v.dataIn := v.rx;
                  -- Check for errors
                  CheckForErrors(v, data, dataK, decErr, dispErr, '1');
                  -- Check for valid message
                  if v.errDetected = '0' then
                     -- Increment the counter
                     v.stableCnt := r.stableCnt + 1;
                     -- Check the counter
                     if r.stableCnt = 3 then
                        -- Reset the counter
                        v.stableCnt := 0;
                        -- Set the flag
                        v.linkUp    := '1';
                        -- Update the fault and seqCnt value
                        v.fault     := data(23 downto 8);
                        v.seqCnt    := data(7 downto 4);
                        -- Next State
                        v.state     := LOCKED_S;
                     end if;
                  else
                     -- Reset the counter
                     v.stableCnt := 0;
                  end if;
               end if;
            end if;
            -- Don't forward errors yet because still locking
            v.errDetected := '0';
         ----------------------------------------------------------------------
         when LOCKED_S =>
            -- Increment the counter
            v.cnt := r.cnt + 1;
            -- Check the counter
            if r.cnt = 39 then
               -- Reset the counter
               v.cnt    := 0;
               -- Set the flag
               v.clkEn  := '1';
               v.dataIn := v.rx;
               -- Update the fault value
               v.fault  := data(23 downto 8);
               -- Check for errors
               CheckForErrors(v, data, dataK, decErr, dispErr, '1');
               -- Check the error detected flag
               if (v.errDetected = '1') then
                  -- Reset the flag
                  v.linkUp := '0';
                  -- Force a fault
                  v.fault  := (others => '1');
                  -- Next State
                  v.state  := UNLOCKED_S;
               else
                  v.faultUpdated := '1';
               end if;
            end if;
      ----------------------------------------------------------------------
      end case;

      -- Synchronous Reset
      if (rst100MHz = '1') then
         -- Reset the registers
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs 
      linkUp       <= r.linkUp;
      linkDown     <= not(r.linkUp);
      fault        <= r.fault;
      faultUpdated <= r.faultUpdated;
      errDetected  <= r.errDetected;
      errDecode    <= r.errDecode and r.errDetected;
      errDisparity <= r.errDisparity and r.errDetected;
      errComma     <= r.errComma and r.errDetected;
      errDataK     <= r.errDataK and r.errDetected;
      errCheckSum  <= r.errCheckSum and r.errDetected;
      errSeqCnt    <= r.errSeqCnt and r.errDetected;

   end process comb;

   seq : process (clk100MHz) is
   begin
      if rising_edge(clk100MHz) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
