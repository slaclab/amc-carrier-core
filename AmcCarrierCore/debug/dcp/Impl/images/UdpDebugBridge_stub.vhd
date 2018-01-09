-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
-- Date        : Tue Jan  9 15:26:40 2018
-- Host        : rdsrv221 running 64-bit Red Hat Enterprise Linux Server release 6.9 (Santiago)
-- Command     : write_vhdl -force -mode synth_stub
--               /u1/strauman/amc-carrier-project-template/firmware/submodules/amc-carrier-core/AmcCarrierCore/debug/dcp/Impl/images/UdpDebugBridge_stub.vhd
-- Design      : UdpDebugBridge
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku040-ffva1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UdpDebugBridge is
  Port ( 
    axisClk : in STD_LOGIC;
    axisRst : in STD_LOGIC;
    \mAxisReq[tValid]\ : in STD_LOGIC;
    \mAxisReq[tData]\ : in STD_LOGIC_VECTOR ( 127 downto 0 );
    \mAxisReq[tStrb]\ : in STD_LOGIC_VECTOR ( 15 downto 0 );
    \mAxisReq[tKeep]\ : in STD_LOGIC_VECTOR ( 15 downto 0 );
    \mAxisReq[tLast]\ : in STD_LOGIC;
    \mAxisReq[tDest]\ : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \mAxisReq[tId]\ : in STD_LOGIC_VECTOR ( 7 downto 0 );
    \mAxisReq[tUser]\ : in STD_LOGIC_VECTOR ( 127 downto 0 );
    \sAxisReq[tReady]\ : out STD_LOGIC;
    \mAxisTdo[tValid]\ : out STD_LOGIC;
    \mAxisTdo[tData]\ : out STD_LOGIC_VECTOR ( 127 downto 0 );
    \mAxisTdo[tStrb]\ : out STD_LOGIC_VECTOR ( 15 downto 0 );
    \mAxisTdo[tKeep]\ : out STD_LOGIC_VECTOR ( 15 downto 0 );
    \mAxisTdo[tLast]\ : out STD_LOGIC;
    \mAxisTdo[tDest]\ : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \mAxisTdo[tId]\ : out STD_LOGIC_VECTOR ( 7 downto 0 );
    \mAxisTdo[tUser]\ : out STD_LOGIC_VECTOR ( 127 downto 0 );
    \sAxisTdo[tReady]\ : in STD_LOGIC
  );

end UdpDebugBridge;

architecture stub of UdpDebugBridge is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "axisClk,axisRst,\mAxisReq[tValid]\,\mAxisReq[tData]\[127:0],\mAxisReq[tStrb]\[15:0],\mAxisReq[tKeep]\[15:0],\mAxisReq[tLast]\,\mAxisReq[tDest]\[7:0],\mAxisReq[tId]\[7:0],\mAxisReq[tUser]\[127:0],\sAxisReq[tReady]\,\mAxisTdo[tValid]\,\mAxisTdo[tData]\[127:0],\mAxisTdo[tStrb]\[15:0],\mAxisTdo[tKeep]\[15:0],\mAxisTdo[tLast]\,\mAxisTdo[tDest]\[7:0],\mAxisTdo[tId]\[7:0],\mAxisTdo[tUser]\[127:0],\sAxisTdo[tReady]\";
begin
end;
