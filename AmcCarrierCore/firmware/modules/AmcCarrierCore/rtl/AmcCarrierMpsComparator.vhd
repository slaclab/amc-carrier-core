-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsComparator.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-17
-- Last update: 2015-10-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2015 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity AmcCarrierMpsComparator is
   generic (
      TPD_G            : time                  := 1 ns;
      MPS_SYNTH_G      : boolean               := true;
      MPS_THRESHOLD_G  : natural range 0 to 32 := 32;
      AXI_ERROR_RESP_G : slv(1 downto 0)       := AXI_RESP_DECERR_C);
   port (
      -- AXI-Lite Interface: [0x00000000:0x0000007F]
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Inbound Message Value
      ibValid         : in  sl;
      ibValue         : in  slv(31 downto 0);
      -- Outbound Comparator Value
      obValid         : out sl;
      obValue         : out slv(31 downto 0));      
end AmcCarrierMpsComparator;

architecture rtl of AmcCarrierMpsComparator is

   type StateType is (
      IDLE_S,
      COMPARE_S,
      INCREMENT_S); 

   type RegType is record
      cnt     : natural range 0 to 31;
      addr    : slv(4 downto 0);
      obValid : sl;
      obValue : slv(31 downto 0);
      state   : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt     => 0,
      addr    => (others => '0'),
      obValid => '0',
      obValue => (others => '0'),
      state   => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal threshold : slv(31 downto 0);

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";   
   
begin
   
   DONT_SYNTH : if (MPS_SYNTH_G = false) generate

      obValid <= '0';
      obValue <= (others => '0');

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)            
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave);

   end generate;

   MPS_SYNTH : if (MPS_SYNTH_G = true) generate
      
      U_LUTRAM : entity work.AxiDualPortRam
         generic map (
            TPD_G        => TPD_G,
            BRAM_EN_G    => false,
            REG_EN_G     => false,
            MODE_G       => "write-first",
            ADDR_WIDTH_G => 5,
            DATA_WIDTH_G => 32)
         port map (
            -- Axi Port
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave,
            -- Standard Port
            clk            => axilClk,
            addr           => r.addr,
            dout           => threshold);

      comb : process (axilRst, ibValid, ibValue, r, threshold) is
         variable v : RegType;
      begin
         -- Latch the current value
         v := r;

         -- Reset the flags
         v.obValid := '0';

         -- State Machine
         case r.state is
            ----------------------------------------------------------------------
            when IDLE_S =>
               -- Check for inbound valid
               if (ibValid = '1') then
                  -- Next state
                  v.state := COMPARE_S;
               end if;
            ----------------------------------------------------------------------
            when COMPARE_S =>
               -- Compare inbound value with threshold
               if ibValue > threshold then
                  -- Update the comparator mask
                  v.obValue(r.cnt) := '1';
               end if;
               -- Increment the counter
               v.addr  := r.addr + 1;
               -- Next state
               v.state := INCREMENT_S;
            ----------------------------------------------------------------------
            when INCREMENT_S =>
               -- Check for last transfer
               if r.cnt = (MPS_THRESHOLD_G-1) then
                  -- Reset the counter
                  v.addr    := (others => '0');
                  v.cnt     := 0;
                  -- Forward the comparator value
                  v.obValid := '1';
                  -- Next state
                  v.state   := IDLE_S;
               else
                  -- Increment the counter
                  v.cnt   := r.cnt + 1;
                  -- Next state
                  v.state := COMPARE_S;
               end if;
         ----------------------------------------------------------------------
         end case;

         -- Reset
         if (axilRst = '1') then
            v := REG_INIT_C;
         end if;

         -- Register the variable for next clock cycle
         rin <= v;

         -- Outputs        
         obValid <= r.obValid;
         obValue <= r.obValue;

      end process comb;

      seq : process (axilClk) is
      begin
         if rising_edge(axilClk) then
            r <= rin after TPD_G;
         end if;
      end process seq;
      
   end generate;
   
end rtl;
