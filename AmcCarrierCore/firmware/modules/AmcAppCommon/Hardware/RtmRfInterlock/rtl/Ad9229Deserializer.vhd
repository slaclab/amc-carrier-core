-------------------------------------------------------------------------------
-- Title      : DDR deserializer
-------------------------------------------------------------------------------
-- File       : Ad9229Deserializer.vhd
-- Author     : Benjamin Reese  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-08-09
-- Last update: 2016-08-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 12 bit DDR deserializer using Ultrascale IDELAYE3 and ISERDESE3.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.StdRtlPkg.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity Ad9229Deserializer is
   
   generic (
      TPD_G : time := 1 ns;
      IODELAY_GROUP_G : string:= "DEFAULT_GROUP";
      IDELAYCTRL_FREQ_G : real := 200.0);
   port (
      clkSerN : in sl;
      clkSerP : in sl;
      idelayClk  : in sl;
      idelayRst  : in sl;      
      clkSerDiv2 : in sl;
      rstSerDiv2 : in sl;

      clkPar : in sl;
      rstPar : in sl;
      
      slip : in sl;

      curDelay : out slv(8 downto 0);
      setDelay : in slv(8 downto 0);
      setValid : in sl;

      iData : in  sl;
      oData : out slv(11 downto 0));

end entity Ad9229Deserializer;

architecture rtl of Ad9229Deserializer is

   type RegType is record
      -- Gearbox
      par4bitD0 : slv(3 downto 0);
      par4bitD1 : slv(3 downto 0);
      par4bitD2 : slv(3 downto 0);
      data12bitD0 : slv(11 downto 0);
      data12bitD1 : slv(11 downto 0);
      weSr : slv(2 downto 0);

      -- Slip     
      slipCnt : integer range 0 to 11;
   end record RegType;

   constant REG_INIT_C : RegType := (
      -- Gearbox   
      par4bitD0 => (others => '0'),
      par4bitD1 => (others => '0'),
      par4bitD2 => (others => '0'),
      data12bitD0 => (others => '0'), 
      data12bitD1 => (others => '0'),
      weSr  => "001",
      -- Slip 
      slipCnt => 0);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   signal s_iDataDly    : sl;
   signal s_slipSyncRe  : sl;
   signal s_serdesData  : slv(7 downto 0);   
   signal s_parData     : slv(11 downto 0);

   attribute IODELAY_GROUP : string;
   attribute IODELAY_GROUP of U_DELAY : label is IODELAY_GROUP_G;
   
begin

   -- Slip sync and one shot
   U_SyncOneShot: entity work.SynchronizerOneShot
   generic map (
      TPD_G           => TPD_G,
      BYPASS_SYNC_G   => false)
   port map (
      clk     => clkSerDiv2,
      rst     => rstSerDiv2,
      dataIn  => slip,
      dataOut => s_slipSyncRe);

   -- ADC frame delay
   U_DELAY : IDELAYE3
      generic map (
         CASCADE => "NONE", -- Cascade setting (MASTER, NONE, SLAVE_END, SLAVE_MIDDLE)
         DELAY_FORMAT => "COUNT", -- Units of the DELAY_VALUE (COUNT, TIME)
         DELAY_SRC => "IDATAIN", -- Delay input (DATAIN, IDATAIN)
         DELAY_TYPE => "VAR_LOAD", -- Set the type of tap delay line (FIXED, VARIABLE, VAR_LOAD)
         DELAY_VALUE => 0, -- Input delay value setting
         IS_CLK_INVERTED => '0', -- Optional inversion for CLK
         IS_RST_INVERTED => '0', -- Optional inversion for RST
         REFCLK_FREQUENCY => IDELAYCTRL_FREQ_G, -- IDELAYCTRL clock input frequency in MHz (200.0-2400.0)
         UPDATE_MODE => "ASYNC" -- Determines when updates to the delay will take effect (ASYNC, MANUAL, SYNC)
      )
      port map (
      
         CASC_OUT => open, -- 1-bit output: Cascade delay output to ODELAY input cascade
         DATAIN => '0', -- 1-bit input: Data input from the logic
         IDATAIN => iData, -- 1-bit input: Data input from the IOBUF
         DATAOUT => s_iDataDly, -- 1-bit output: Delayed data output
         CASC_IN => '1', -- 1-bit input: Cascade delay input from slave ODELAY CASCADE_OUT
         CASC_RETURN => '1', -- 1-bit input: Cascade delay returning from slave ODELAY DATAOUT
         CE => '0', -- 1-bit input: Active high enable increment/decrement input
         CLK => idelayClk, -- 1-bit input: Clock input
         CNTVALUEIN => setDelay, -- 9-bit input: Counter value input
         CNTVALUEOUT => curDelay, -- 9-bit output: Counter value output
         LOAD => setValid, -- 1-bit input: Load DELAY_VALUE input
         EN_VTC => '0', -- 1-bit input: Keep delay constant over VT
         INC => '1', -- 1-bit input: Increment / Decrement tap delay input
         RST => idelayRst); -- 1-bit input: Asynchronous Reset to the DELAY_VALUE
   
   U_ISERDESE3 : ISERDESE3
   generic map (
      DATA_WIDTH => 4, -- Parallel data width (4,8)
      FIFO_ENABLE => "FALSE", -- Enables the use of the FIFO
      FIFO_SYNC_MODE => "FALSE", -- Enables the use of internal 2-stage synchronizers on the FIFO
      IS_CLK_B_INVERTED => '0', -- Optional inversion for CLK_B
      IS_CLK_INVERTED => '0', -- Optional inversion for CLK
      IS_RST_INVERTED => '0' -- Optional inversion for RST
   )
   port map (
      FIFO_EMPTY => open, -- 1-bit output: FIFO empty flag
      INTERNAL_DIVCLK => open, 
      CLK    => clkSerP, -- 1-bit input: High-speed clock
      CLK_B  => clkSerN, -- 1-bit input: Inversion of High-speed clock CLK
      CLKDIV => clkSerDiv2, -- 1-bit input: Divided Clock
      D => s_iDataDly, -- 1-bit input: Serial Data Input
      Q => s_serdesData, -- 8-bit registered output
      FIFO_RD_CLK => '1', -- 1-bit input: FIFO read clock
      FIFO_RD_EN => '0', -- 1-bit input: Enables reading the FIFO when asserted
      RST => rstSerDiv2 -- 1-bit input: Asynchronous Reset
   );
   
   -- Slip shifter
   with r.slipCnt select
   s_parData <= r.data12bitD0                                            when 0,
                r.data12bitD1(0)           & r.data12bitD0(11 downto 1)  when 1,
                r.data12bitD1(1  downto 0) & r.data12bitD0(11 downto 2)  when 2,
                r.data12bitD1(2  downto 0) & r.data12bitD0(11 downto 3)  when 3,
                r.data12bitD1(3  downto 0) & r.data12bitD0(11 downto 4)  when 4,
                r.data12bitD1(4  downto 0) & r.data12bitD0(11 downto 5)  when 5,
                r.data12bitD1(5  downto 0) & r.data12bitD0(11 downto 6)  when 6,
                r.data12bitD1(6  downto 0) & r.data12bitD0(11 downto 7)  when 7,
                r.data12bitD1(7  downto 0) & r.data12bitD0(11 downto 8)  when 8,
                r.data12bitD1(8  downto 0) & r.data12bitD0(11 downto 9)  when 9,
                r.data12bitD1(9  downto 0) & r.data12bitD0(11 downto 10) when 10,
                r.data12bitD1(10 downto 0) & r.data12bitD0(11)           when 11,
                r.data12bitD0                                            when others;
   
   comb : process (r, rstSerDiv2, s_serdesData, s_slipSyncRe) is
      variable v : RegType;
   begin
      v := r;
      -------------------
      
      -- GearBox 3x4bit = 12bit parallel word
      v.par4bitD0 := bitReverse(s_serdesData(3 downto 0));
      v.par4bitD1 := r.par4bitD0;
      v.par4bitD2 := r.par4bitD1;
      
      v.data12bitD0 := r.par4bitD2 & r.par4bitD1 & r.par4bitD0;
      
      -- Generate gearbox we
      -- Shift left to get a /3 we 
      v.weSr := r.weSr(1 downto 0) & r.weSr(2);
       
      -- Previous data save
      if (r.weSr(2)='1') then      
         v.data12bitD1 := r.data12bitD0;
      end if;

      -- Slip counter increment
      if (s_slipSyncRe = '1' and r.slipCnt=11) then
         v.slipCnt := 0;
      elsif (s_slipSyncRe = '1') then
         v.slipCnt := r.slipCnt+1;
      end if;
     
      if (rstSerDiv2 = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
      
   end process comb;

   seq : process (clkSerDiv2) is
   begin
      if (rising_edge(clkSerDiv2)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
   
   -- Output synchronizer
   U_SyncFifo : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => oData'length
         )
      port map (
         wr_clk => clkSerDiv2,
         wr_en  => r.weSr(2),
         din    => s_parData,
         rd_clk => clkPar,
         dout   => oData
         );
   

end architecture rtl;
