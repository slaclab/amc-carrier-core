-------------------------------------------------------------------------------
-- File       : AmcCarrierMpsEncoder.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-09-17
-- Last update: 2016-05-26
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;

entity AmcCarrierMpsEncoder is
   generic (
      TPD_G            : time                   := 1 ns;
      MPS_SYNTH_G      : boolean                := true;
      MPS_THRESHOLD_G  : natural range 0 to 256 := 256;
      AXI_ERROR_RESP_G : slv(1 downto 0)        := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0)       := (others => '0'));
   port (
      -- AXI-Lite Interface: [AXI_BASE_ADDR_G+0x00000000:AXI_BASE_ADDR_G+0x000003FF]
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Inbound Message Value
      ibValid         : in  sl;
      ibValue         : in  slv(31 downto 0);
      -- Outbound Encode MPS Value
      obValid         : out sl;
      obValue         : out slv(7 downto 0));   
end AmcCarrierMpsEncoder;

architecture rtl of AmcCarrierMpsEncoder is

   constant NUM_AXI_MASTERS_C : natural := 8;
   
   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      0               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000000"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      1               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000080"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      2               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000100"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      3               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000180"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      4               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000200"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      5               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000280"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      6               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000300"),
         addrBits     => 7,
         connectivity => X"FFFF"),
      7               => (
         baseAddr     => (AXI_BASE_ADDR_G + x"00000380"),
         addrBits     => 7,
         connectivity => X"FFFF"));  

   signal ramWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal ramReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   
   type StateType is (
      IDLE_S,
      ENCODE_S); 

   type RegType is record
      cnt     : natural range 0 to 256;
      obValid : sl;
      obValue : slv(7 downto 0);
      state   : StateType;
   end record RegType;
   constant REG_INIT_C : RegType := (
      cnt     => 0,
      obValid => '0',
      obValue => (others => '0'),
      state   => IDLE_S);      

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal comparatorValid : slv(31 downto 0);
   signal comparatorValue : slv(255 downto 0);

   -- attribute dont_touch             : string;
   -- attribute dont_touch of r        : signal is "TRUE";      

begin

   DONT_SYNTH : if (MPS_SYNTH_G = false) generate

      obValid <= '0';
      obValue <= (others => '0');

      U_AxiLiteEmpty : entity work.AxiLiteEmpty
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_RESP_OK_C)  -- Don't respond with error
         port map (
            axiClk         => axilClk,
            axiClkRst      => axilRst,
            axiReadMaster  => axilReadMaster,
            axiReadSlave   => axilReadSlave,
            axiWriteMaster => axilWriteMaster,
            axiWriteSlave  => axilWriteSlave);

   end generate;

   MPS_SYNTH : if (MPS_SYNTH_G = true) generate

      U_XBAR : entity work.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
            MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
         port map (
            axiClk              => axilClk,
            axiClkRst           => axilRst,
            sAxiWriteMasters(0) => axilWriteMaster,
            sAxiWriteSlaves(0)  => axilWriteSlave,
            sAxiReadMasters(0)  => axilReadMaster,
            sAxiReadSlaves(0)   => axilReadSlave,
            mAxiWriteMasters    => ramWriteMasters,
            mAxiWriteSlaves     => ramWriteSlaves,
            mAxiReadMasters     => ramReadMasters,
            mAxiReadSlaves      => ramReadSlaves);   

      GEN_VEC :
      for i in 7 downto 0 generate

         U_Compare : entity work.AmcCarrierMpsComparator
            generic map (
               TPD_G            => TPD_G,
               MPS_SYNTH_G      => ite((MPS_THRESHOLD_G > (i*32)), true, false),
               MPS_THRESHOLD_G  => ite((MPS_THRESHOLD_G > (i*32)+31), 32, (MPS_THRESHOLD_G mod 32)),
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
            port map (
               -- AXI-Lite Interface
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => ramReadMasters(i),
               axilReadSlave   => ramReadSlaves(i),
               axilWriteMaster => ramWriteMasters(i),
               axilWriteSlave  => ramWriteSlaves(i),
               -- Inbound Message Value
               ibValid         => ibValid,
               ibValue         => ibValue,
               -- Inbound Comparator Value
               obValid         => comparatorValid(i),
               obValue         => comparatorValue((i*32)+31 downto (i*32)));

      end generate GEN_VEC;

      comb : process (axilRst, comparatorValid, comparatorValue, r) is
         variable v : RegType;
         variable i : natural;
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
               if (comparatorValid(0) = '1') then
                  -- Reset the comparator output
                  v.obValue := (others => '0');
                  -- Next state
                  v.state   := ENCODE_S;
               end if;
            ----------------------------------------------------------------------
            when ENCODE_S =>
               -- Loop through the comparator bits
               for i in 0 to 7 loop
                  -- Check the value
                  if comparatorValue(v.cnt) = '1' then
                     v.obValue := toSlv(v.cnt, 8);
                  end if;
                  -- Increment the counter
                  v.cnt := v.cnt + 1;
               end loop;
               --  Check the counter value
               if v.cnt >= MPS_THRESHOLD_G then
                  -- Reset the counter
                  v.cnt     := 0;
                  -- Forward the encoded value
                  v.obValid := '1';
                  -- Next state
                  v.state   := IDLE_S;
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
