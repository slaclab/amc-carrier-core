-------------------------------------------------------------------------------
-- File       : AmcCarrierIbufGt.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: 
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

library unisim;
use unisim.vcomponents.all;

entity AmcCarrierIbufGt is
   generic (
      REFCLK_EN_TX_PATH  : bit                           := '0';
      REFCLK_HROW_CK_SEL : std_logic_vector (1 downto 0) := "00";
      REFCLK_ICNTL_RX    : std_logic_vector (1 downto 0) := "00");
   port (
      O     : out std_ulogic;
      ODIV2 : out std_ulogic;
      CEB   : in  std_ulogic;
      I     : in  std_ulogic;
      IB    : in  std_ulogic);
end AmcCarrierIbufGt;

architecture mapping of AmcCarrierIbufGt is

begin

   U_IBUFDS_GT : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => REFCLK_EN_TX_PATH,  -- Refer to Transceiver User Guide
         REFCLK_HROW_CK_SEL => REFCLK_HROW_CK_SEL,  -- Refer to Transceiver User Guide
         REFCLK_ICNTL_RX    => REFCLK_ICNTL_RX)  -- Refer to Transceiver User Guide
      port map (
         O     => O,      -- 1-bit output: Refer to Transceiver User Guide
         ODIV2 => ODIV2,  -- 1-bit output: Refer to Transceiver User Guide
         CEB   => CEB,    -- 1-bit input: Refer to Transceiver User Guide
         I     => I,      -- 1-bit input: Refer to Transceiver User Guide
         IB    => IB);    -- 1-bit input: Refer to Transceiver User Guide

end mapping;
