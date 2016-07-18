library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;


--------------------------------------------------------------------------------
entity  DaqMuxV2Tb is

end entity ;
--------------------------------------------------------------------------------


architecture Bhv of DaqMuxV2Tb is
  -----------------------------
  -- Port Signals 
  -----------------------------
   constant CLK_PERIOD_C : time    := 10 ns;

   -- Clocking
   signal   clk_i                 : sl := '0';
   signal   rst_i                 : sl := '0';
   signal   dec16or32_i           : sl := '1';
   signal   s_cnt                 : slv(31 downto 0);
  ----------------------------
  -- Port Signals 
  -----------------------------
   constant TPD_G             : time := 1 ns; 
   constant N_DATA_IN_G       : positive:= 2;
   constant N_DATA_OUT_G      : positive:= 2;

   signal   trigHw_i          : sl:= '0';
   signal   freezeHw_i        : sl:= '0';
   signal   trigCasc_i        : sl:= '0';
   signal   timeStamp_i       : slv(63 downto 0):= x"DEADBEEF_BA5EBA11";
   signal   sampleDataArr_i   : slv32Array(N_DATA_IN_G-1 downto 0);
   signal   dataValidVec_i    : slv(N_DATA_IN_G-1 downto 0):= (others => '1');  
   
   signal   trigCasc_o        : sl;
   
   
   signal   axilReadMaster    : AxiLiteReadMasterType:= AXI_LITE_READ_MASTER_INIT_C;
   signal   axilReadSlave     : AxiLiteReadSlaveType;
   signal   axilWriteMaster   : AxiLiteWriteMasterType:= AXI_LITE_WRITE_MASTER_INIT_C;
   signal   axilWriteSlave    : AxiLiteWriteSlaveType;
   

   signal   rxAxisMasterArr_o : AxiStreamMasterArray(N_DATA_OUT_G-1 downto 0);
   signal   rxAxisSlaveArr_i  : AxiStreamSlaveArray(N_DATA_OUT_G-1 downto 0):= (others =>AXI_STREAM_SLAVE_FORCE_C);
   signal   rxAxisCtrlArr_i   : AxiStreamCtrlArray(N_DATA_OUT_G-1 downto 0):= (others =>AXI_STREAM_CTRL_UNUSED_C);
   
begin  

   -- Generate clocks and resets
   DDR_ClkRst_Inst : entity work.ClkRst
   generic map (
     CLK_PERIOD_G      => CLK_PERIOD_C,
     RST_START_DELAY_G => 1 ns,     -- Wait this long into simulation before asserting reset
     RST_HOLD_TIME_G   => 1000 ns)  -- Hold reset for this long)
   port map (
     clkP => clk_i,
     clkN => open,
     rst  => rst_i,
     rstL => open);

  -----------------------------
  -- component instantiation 
  -----------------------------
    -----------------------------
  -- component instantiation 
  -----------------------------
  DaqMuxV2_INST: entity work.DaqMuxV2
   generic map (
      TPD_G            => TPD_G,
      N_DATA_IN_G      => N_DATA_IN_G,
      N_DATA_OUT_G     => N_DATA_OUT_G)
   port map (
      axiClk            => clk_i,
      axiRst            => rst_i,
      devClk_i          => clk_i,
      devRst_i          => rst_i,
      wfClk_i           => clk_i,
      wfRst_i           => rst_i,
      trigHw_i          => trigHw_i,
      freezeHw_i        => freezeHw_i,
      trigCasc_i        => trigCasc_i,
      trigCasc_o        => trigCasc_o,
      timeStamp_i       => timeStamp_i,
      axilReadMaster    => axilReadMaster,
      axilReadSlave     => axilReadSlave,
      axilWriteMaster   => axilWriteMaster,
      axilWriteSlave    => axilWriteSlave,
      sampleDataArr_i   => sampleDataArr_i,
      dataValidVec_i    => dataValidVec_i,
      rxAxisMasterArr_o => rxAxisMasterArr_o,
      rxAxisSlaveArr_i  => rxAxisSlaveArr_i,
      rxAxisCtrlArr_i   => rxAxisCtrlArr_i);
	
   seq : process (clk_i) is
   begin
      if (rising_edge(clk_i)) then
         if (rst_i = '1') then  
            s_cnt <= (others=>'0');
         elsif dec16or32_i = '0' then
            s_cnt <= s_cnt + 1 after TPD_G;
         else
            s_cnt <= s_cnt + 2 after TPD_G;
         end if;
      end if;
   end process seq;
   
   genInLanes : for I in N_DATA_IN_G-1 downto 0 generate
      sampleDataArr_i(I) <= s_cnt(15 downto 0)+1 & s_cnt(15 downto 0) when dec16or32_i = '1' else s_cnt;
   end generate genInLanes;
   
   StimuliProcess : process
   begin
      wait until rst_i = '0';

      wait for CLK_PERIOD_C*200;
      trigHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';
      
      wait for CLK_PERIOD_C*500;
      trigHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';
      
      wait for CLK_PERIOD_C*100;
      freezeHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      freezeHw_i <= '0';
    
      wait for CLK_PERIOD_C*1000;
      trigHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';
      
      wait for CLK_PERIOD_C*100;
      freezeHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      freezeHw_i <= '0';
      
      -- Insert error
      wait for CLK_PERIOD_C*3000;
      rxAxisSlaveArr_i(0)  <= AXI_STREAM_SLAVE_INIT_C;
      wait for CLK_PERIOD_C*20;    
      rxAxisSlaveArr_i(0)  <= AXI_STREAM_SLAVE_FORCE_C;
      
      wait for CLK_PERIOD_C*1000;
      trigHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      trigHw_i <= '0';
      
      wait for CLK_PERIOD_C*100;
      freezeHw_i <= '1';    
      wait for CLK_PERIOD_C*20;
      freezeHw_i <= '0';
      
      wait for CLK_PERIOD_C*5000;
      trigCasc_i <= '1';    
      wait for CLK_PERIOD_C*20;
      trigCasc_i <= '0';
      
      wait;
   end process StimuliProcess;
  
end architecture Bhv;