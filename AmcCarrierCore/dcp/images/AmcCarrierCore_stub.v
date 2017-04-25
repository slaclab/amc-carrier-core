// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
// Date        : Tue Apr 25 13:02:22 2017
// Host        : rdsrv223 running 64-bit Red Hat Enterprise Linux Server release 6.9 (Santiago)
// Command     : write_verilog -force -mode synth_stub
//               /u/re/ruckman/projects/lcls/amc-carrier-dev/firmware/submodules/amc-carrier-core/AmcCarrierCore/dcp/images/AmcCarrierCore_stub.v
// Design      : AmcCarrierCore
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku040-ffva1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module AmcCarrierCore(timingClk, timingRst, \timingBus[strobe] , 
  \timingBus[valid] , \timingBus[message][version] , \timingBus[message][pulseId] , 
  \timingBus[message][timeStamp] , \timingBus[message][fixedRates] , 
  \timingBus[message][acRates] , \timingBus[message][acTimeSlot] , 
  \timingBus[message][acTimeSlotPhase] , \timingBus[message][resync] , 
  \timingBus[message][beamRequest] , \timingBus[message][beamEnergy][0] , 
  \timingBus[message][beamEnergy][1] , \timingBus[message][beamEnergy][2] , 
  \timingBus[message][beamEnergy][3] , \timingBus[message][photonWavelen][0] , 
  \timingBus[message][photonWavelen][1] , \timingBus[message][syncStatus] , 
  \timingBus[message][mpsValid] , \timingBus[message][bcsFault] , 
  \timingBus[message][mpsLimit] , \timingBus[message][mpsClass][0] , 
  \timingBus[message][mpsClass][1] , \timingBus[message][mpsClass][2] , 
  \timingBus[message][mpsClass][3] , \timingBus[message][mpsClass][4] , 
  \timingBus[message][mpsClass][5] , \timingBus[message][mpsClass][6] , 
  \timingBus[message][mpsClass][7] , \timingBus[message][mpsClass][8] , 
  \timingBus[message][mpsClass][9] , \timingBus[message][mpsClass][10] , 
  \timingBus[message][mpsClass][11] , \timingBus[message][mpsClass][12] , 
  \timingBus[message][mpsClass][13] , \timingBus[message][mpsClass][14] , 
  \timingBus[message][mpsClass][15] , \timingBus[message][bsaInit] , 
  \timingBus[message][bsaActive] , \timingBus[message][bsaAvgDone] , 
  \timingBus[message][bsaDone] , \timingBus[message][control][0] , 
  \timingBus[message][control][1] , \timingBus[message][control][2] , 
  \timingBus[message][control][3] , \timingBus[message][control][4] , 
  \timingBus[message][control][5] , \timingBus[message][control][6] , 
  \timingBus[message][control][7] , \timingBus[message][control][8] , 
  \timingBus[message][control][9] , \timingBus[message][control][10] , 
  \timingBus[message][control][11] , \timingBus[message][control][12] , 
  \timingBus[message][control][13] , \timingBus[message][control][14] , 
  \timingBus[message][control][15] , \timingBus[message][control][16] , 
  \timingBus[message][control][17] , \timingBus[stream][pulseId] , 
  \timingBus[stream][eventCodes] , \timingBus[stream][dbuff][dtype] , 
  \timingBus[stream][dbuff][version] , \timingBus[stream][dbuff][dmod] , 
  \timingBus[stream][dbuff][epicsTime] , \timingBus[stream][dbuff][edefAvgDn] , 
  \timingBus[stream][dbuff][edefMinor] , \timingBus[stream][dbuff][edefMajor] , 
  \timingBus[stream][dbuff][edefInit] , \timingBus[v1][linkUp] , 
  \timingBus[v1][gtRxData] , \timingBus[v1][gtRxDataK] , \timingBus[v1][gtRxDispErr] , 
  \timingBus[v1][gtRxDecErr] , \timingBus[v2][linkUp] , \timingPhy[dataK] , 
  \timingPhy[data] , \timingPhy[control][reset] , \timingPhy[control][inhibit] , 
  \timingPhy[control][polarity] , \timingPhy[control][bufferByRst] , 
  \timingPhy[control][pllReset] , timingPhyClk, timingPhyRst, timingRefClk, 
  timingRefClkDiv2, diagnosticClk, diagnosticRst, \diagnosticBus[strobe] , 
  \diagnosticBus[data][31] , \diagnosticBus[data][30] , \diagnosticBus[data][29] , 
  \diagnosticBus[data][28] , \diagnosticBus[data][27] , \diagnosticBus[data][26] , 
  \diagnosticBus[data][25] , \diagnosticBus[data][24] , \diagnosticBus[data][23] , 
  \diagnosticBus[data][22] , \diagnosticBus[data][21] , \diagnosticBus[data][20] , 
  \diagnosticBus[data][19] , \diagnosticBus[data][18] , \diagnosticBus[data][17] , 
  \diagnosticBus[data][16] , \diagnosticBus[data][15] , \diagnosticBus[data][14] , 
  \diagnosticBus[data][13] , \diagnosticBus[data][12] , \diagnosticBus[data][11] , 
  \diagnosticBus[data][10] , \diagnosticBus[data][9] , \diagnosticBus[data][8] , 
  \diagnosticBus[data][7] , \diagnosticBus[data][6] , \diagnosticBus[data][5] , 
  \diagnosticBus[data][4] , \diagnosticBus[data][3] , \diagnosticBus[data][2] , 
  \diagnosticBus[data][1] , \diagnosticBus[data][0] , \diagnosticBus[sevr][31] , 
  \diagnosticBus[sevr][30] , \diagnosticBus[sevr][29] , \diagnosticBus[sevr][28] , 
  \diagnosticBus[sevr][27] , \diagnosticBus[sevr][26] , \diagnosticBus[sevr][25] , 
  \diagnosticBus[sevr][24] , \diagnosticBus[sevr][23] , \diagnosticBus[sevr][22] , 
  \diagnosticBus[sevr][21] , \diagnosticBus[sevr][20] , \diagnosticBus[sevr][19] , 
  \diagnosticBus[sevr][18] , \diagnosticBus[sevr][17] , \diagnosticBus[sevr][16] , 
  \diagnosticBus[sevr][15] , \diagnosticBus[sevr][14] , \diagnosticBus[sevr][13] , 
  \diagnosticBus[sevr][12] , \diagnosticBus[sevr][11] , \diagnosticBus[sevr][10] , 
  \diagnosticBus[sevr][9] , \diagnosticBus[sevr][8] , \diagnosticBus[sevr][7] , 
  \diagnosticBus[sevr][6] , \diagnosticBus[sevr][5] , \diagnosticBus[sevr][4] , 
  \diagnosticBus[sevr][3] , \diagnosticBus[sevr][2] , \diagnosticBus[sevr][1] , 
  \diagnosticBus[sevr][0] , \diagnosticBus[fixed] , \diagnosticBus[mpsIgnore] , 
  \diagnosticBus[timingMessage][version] , \diagnosticBus[timingMessage][pulseId] , 
  \diagnosticBus[timingMessage][timeStamp] , 
  \diagnosticBus[timingMessage][fixedRates] , 
  \diagnosticBus[timingMessage][acRates] , 
  \diagnosticBus[timingMessage][acTimeSlot] , 
  \diagnosticBus[timingMessage][acTimeSlotPhase] , 
  \diagnosticBus[timingMessage][resync] , 
  \diagnosticBus[timingMessage][beamRequest] , 
  \diagnosticBus[timingMessage][beamEnergy][0] , 
  \diagnosticBus[timingMessage][beamEnergy][1] , 
  \diagnosticBus[timingMessage][beamEnergy][2] , 
  \diagnosticBus[timingMessage][beamEnergy][3] , 
  \diagnosticBus[timingMessage][photonWavelen][0] , 
  \diagnosticBus[timingMessage][photonWavelen][1] , 
  \diagnosticBus[timingMessage][syncStatus] , 
  \diagnosticBus[timingMessage][mpsValid] , \diagnosticBus[timingMessage][bcsFault] , 
  \diagnosticBus[timingMessage][mpsLimit] , 
  \diagnosticBus[timingMessage][mpsClass][0] , 
  \diagnosticBus[timingMessage][mpsClass][1] , 
  \diagnosticBus[timingMessage][mpsClass][2] , 
  \diagnosticBus[timingMessage][mpsClass][3] , 
  \diagnosticBus[timingMessage][mpsClass][4] , 
  \diagnosticBus[timingMessage][mpsClass][5] , 
  \diagnosticBus[timingMessage][mpsClass][6] , 
  \diagnosticBus[timingMessage][mpsClass][7] , 
  \diagnosticBus[timingMessage][mpsClass][8] , 
  \diagnosticBus[timingMessage][mpsClass][9] , 
  \diagnosticBus[timingMessage][mpsClass][10] , 
  \diagnosticBus[timingMessage][mpsClass][11] , 
  \diagnosticBus[timingMessage][mpsClass][12] , 
  \diagnosticBus[timingMessage][mpsClass][13] , 
  \diagnosticBus[timingMessage][mpsClass][14] , 
  \diagnosticBus[timingMessage][mpsClass][15] , 
  \diagnosticBus[timingMessage][bsaInit] , \diagnosticBus[timingMessage][bsaActive] , 
  \diagnosticBus[timingMessage][bsaAvgDone] , 
  \diagnosticBus[timingMessage][bsaDone] , 
  \diagnosticBus[timingMessage][control][0] , 
  \diagnosticBus[timingMessage][control][1] , 
  \diagnosticBus[timingMessage][control][2] , 
  \diagnosticBus[timingMessage][control][3] , 
  \diagnosticBus[timingMessage][control][4] , 
  \diagnosticBus[timingMessage][control][5] , 
  \diagnosticBus[timingMessage][control][6] , 
  \diagnosticBus[timingMessage][control][7] , 
  \diagnosticBus[timingMessage][control][8] , 
  \diagnosticBus[timingMessage][control][9] , 
  \diagnosticBus[timingMessage][control][10] , 
  \diagnosticBus[timingMessage][control][11] , 
  \diagnosticBus[timingMessage][control][12] , 
  \diagnosticBus[timingMessage][control][13] , 
  \diagnosticBus[timingMessage][control][14] , 
  \diagnosticBus[timingMessage][control][15] , 
  \diagnosticBus[timingMessage][control][16] , 
  \diagnosticBus[timingMessage][control][17] , waveformClk, waveformRst, 
  \obAppWaveformMasters[1][3][tValid] , \obAppWaveformMasters[1][3][tData] , 
  \obAppWaveformMasters[1][3][tStrb] , \obAppWaveformMasters[1][3][tKeep] , 
  \obAppWaveformMasters[1][3][tLast] , \obAppWaveformMasters[1][3][tDest] , 
  \obAppWaveformMasters[1][3][tId] , \obAppWaveformMasters[1][3][tUser] , 
  \obAppWaveformMasters[1][2][tValid] , \obAppWaveformMasters[1][2][tData] , 
  \obAppWaveformMasters[1][2][tStrb] , \obAppWaveformMasters[1][2][tKeep] , 
  \obAppWaveformMasters[1][2][tLast] , \obAppWaveformMasters[1][2][tDest] , 
  \obAppWaveformMasters[1][2][tId] , \obAppWaveformMasters[1][2][tUser] , 
  \obAppWaveformMasters[1][1][tValid] , \obAppWaveformMasters[1][1][tData] , 
  \obAppWaveformMasters[1][1][tStrb] , \obAppWaveformMasters[1][1][tKeep] , 
  \obAppWaveformMasters[1][1][tLast] , \obAppWaveformMasters[1][1][tDest] , 
  \obAppWaveformMasters[1][1][tId] , \obAppWaveformMasters[1][1][tUser] , 
  \obAppWaveformMasters[1][0][tValid] , \obAppWaveformMasters[1][0][tData] , 
  \obAppWaveformMasters[1][0][tStrb] , \obAppWaveformMasters[1][0][tKeep] , 
  \obAppWaveformMasters[1][0][tLast] , \obAppWaveformMasters[1][0][tDest] , 
  \obAppWaveformMasters[1][0][tId] , \obAppWaveformMasters[1][0][tUser] , 
  \obAppWaveformMasters[0][3][tValid] , \obAppWaveformMasters[0][3][tData] , 
  \obAppWaveformMasters[0][3][tStrb] , \obAppWaveformMasters[0][3][tKeep] , 
  \obAppWaveformMasters[0][3][tLast] , \obAppWaveformMasters[0][3][tDest] , 
  \obAppWaveformMasters[0][3][tId] , \obAppWaveformMasters[0][3][tUser] , 
  \obAppWaveformMasters[0][2][tValid] , \obAppWaveformMasters[0][2][tData] , 
  \obAppWaveformMasters[0][2][tStrb] , \obAppWaveformMasters[0][2][tKeep] , 
  \obAppWaveformMasters[0][2][tLast] , \obAppWaveformMasters[0][2][tDest] , 
  \obAppWaveformMasters[0][2][tId] , \obAppWaveformMasters[0][2][tUser] , 
  \obAppWaveformMasters[0][1][tValid] , \obAppWaveformMasters[0][1][tData] , 
  \obAppWaveformMasters[0][1][tStrb] , \obAppWaveformMasters[0][1][tKeep] , 
  \obAppWaveformMasters[0][1][tLast] , \obAppWaveformMasters[0][1][tDest] , 
  \obAppWaveformMasters[0][1][tId] , \obAppWaveformMasters[0][1][tUser] , 
  \obAppWaveformMasters[0][0][tValid] , \obAppWaveformMasters[0][0][tData] , 
  \obAppWaveformMasters[0][0][tStrb] , \obAppWaveformMasters[0][0][tKeep] , 
  \obAppWaveformMasters[0][0][tLast] , \obAppWaveformMasters[0][0][tDest] , 
  \obAppWaveformMasters[0][0][tId] , \obAppWaveformMasters[0][0][tUser] , 
  \obAppWaveformSlaves[1][3][slave][tReady] , 
  \obAppWaveformSlaves[1][3][ctrl][pause] , 
  \obAppWaveformSlaves[1][3][ctrl][overflow] , 
  \obAppWaveformSlaves[1][3][ctrl][idle] , 
  \obAppWaveformSlaves[1][2][slave][tReady] , 
  \obAppWaveformSlaves[1][2][ctrl][pause] , 
  \obAppWaveformSlaves[1][2][ctrl][overflow] , 
  \obAppWaveformSlaves[1][2][ctrl][idle] , 
  \obAppWaveformSlaves[1][1][slave][tReady] , 
  \obAppWaveformSlaves[1][1][ctrl][pause] , 
  \obAppWaveformSlaves[1][1][ctrl][overflow] , 
  \obAppWaveformSlaves[1][1][ctrl][idle] , 
  \obAppWaveformSlaves[1][0][slave][tReady] , 
  \obAppWaveformSlaves[1][0][ctrl][pause] , 
  \obAppWaveformSlaves[1][0][ctrl][overflow] , 
  \obAppWaveformSlaves[1][0][ctrl][idle] , 
  \obAppWaveformSlaves[0][3][slave][tReady] , 
  \obAppWaveformSlaves[0][3][ctrl][pause] , 
  \obAppWaveformSlaves[0][3][ctrl][overflow] , 
  \obAppWaveformSlaves[0][3][ctrl][idle] , 
  \obAppWaveformSlaves[0][2][slave][tReady] , 
  \obAppWaveformSlaves[0][2][ctrl][pause] , 
  \obAppWaveformSlaves[0][2][ctrl][overflow] , 
  \obAppWaveformSlaves[0][2][ctrl][idle] , 
  \obAppWaveformSlaves[0][1][slave][tReady] , 
  \obAppWaveformSlaves[0][1][ctrl][pause] , 
  \obAppWaveformSlaves[0][1][ctrl][overflow] , 
  \obAppWaveformSlaves[0][1][ctrl][idle] , 
  \obAppWaveformSlaves[0][0][slave][tReady] , 
  \obAppWaveformSlaves[0][0][ctrl][pause] , 
  \obAppWaveformSlaves[0][0][ctrl][overflow] , 
  \obAppWaveformSlaves[0][0][ctrl][idle] , \ibAppWaveformMasters[1][3][tValid] , 
  \ibAppWaveformMasters[1][3][tData] , \ibAppWaveformMasters[1][3][tStrb] , 
  \ibAppWaveformMasters[1][3][tKeep] , \ibAppWaveformMasters[1][3][tLast] , 
  \ibAppWaveformMasters[1][3][tDest] , \ibAppWaveformMasters[1][3][tId] , 
  \ibAppWaveformMasters[1][3][tUser] , \ibAppWaveformMasters[1][2][tValid] , 
  \ibAppWaveformMasters[1][2][tData] , \ibAppWaveformMasters[1][2][tStrb] , 
  \ibAppWaveformMasters[1][2][tKeep] , \ibAppWaveformMasters[1][2][tLast] , 
  \ibAppWaveformMasters[1][2][tDest] , \ibAppWaveformMasters[1][2][tId] , 
  \ibAppWaveformMasters[1][2][tUser] , \ibAppWaveformMasters[1][1][tValid] , 
  \ibAppWaveformMasters[1][1][tData] , \ibAppWaveformMasters[1][1][tStrb] , 
  \ibAppWaveformMasters[1][1][tKeep] , \ibAppWaveformMasters[1][1][tLast] , 
  \ibAppWaveformMasters[1][1][tDest] , \ibAppWaveformMasters[1][1][tId] , 
  \ibAppWaveformMasters[1][1][tUser] , \ibAppWaveformMasters[1][0][tValid] , 
  \ibAppWaveformMasters[1][0][tData] , \ibAppWaveformMasters[1][0][tStrb] , 
  \ibAppWaveformMasters[1][0][tKeep] , \ibAppWaveformMasters[1][0][tLast] , 
  \ibAppWaveformMasters[1][0][tDest] , \ibAppWaveformMasters[1][0][tId] , 
  \ibAppWaveformMasters[1][0][tUser] , \ibAppWaveformMasters[0][3][tValid] , 
  \ibAppWaveformMasters[0][3][tData] , \ibAppWaveformMasters[0][3][tStrb] , 
  \ibAppWaveformMasters[0][3][tKeep] , \ibAppWaveformMasters[0][3][tLast] , 
  \ibAppWaveformMasters[0][3][tDest] , \ibAppWaveformMasters[0][3][tId] , 
  \ibAppWaveformMasters[0][3][tUser] , \ibAppWaveformMasters[0][2][tValid] , 
  \ibAppWaveformMasters[0][2][tData] , \ibAppWaveformMasters[0][2][tStrb] , 
  \ibAppWaveformMasters[0][2][tKeep] , \ibAppWaveformMasters[0][2][tLast] , 
  \ibAppWaveformMasters[0][2][tDest] , \ibAppWaveformMasters[0][2][tId] , 
  \ibAppWaveformMasters[0][2][tUser] , \ibAppWaveformMasters[0][1][tValid] , 
  \ibAppWaveformMasters[0][1][tData] , \ibAppWaveformMasters[0][1][tStrb] , 
  \ibAppWaveformMasters[0][1][tKeep] , \ibAppWaveformMasters[0][1][tLast] , 
  \ibAppWaveformMasters[0][1][tDest] , \ibAppWaveformMasters[0][1][tId] , 
  \ibAppWaveformMasters[0][1][tUser] , \ibAppWaveformMasters[0][0][tValid] , 
  \ibAppWaveformMasters[0][0][tData] , \ibAppWaveformMasters[0][0][tStrb] , 
  \ibAppWaveformMasters[0][0][tKeep] , \ibAppWaveformMasters[0][0][tLast] , 
  \ibAppWaveformMasters[0][0][tDest] , \ibAppWaveformMasters[0][0][tId] , 
  \ibAppWaveformMasters[0][0][tUser] , \ibAppWaveformSlaves[1][3][slave][tReady] , 
  \ibAppWaveformSlaves[1][3][ctrl][pause] , 
  \ibAppWaveformSlaves[1][3][ctrl][overflow] , 
  \ibAppWaveformSlaves[1][3][ctrl][idle] , 
  \ibAppWaveformSlaves[1][2][slave][tReady] , 
  \ibAppWaveformSlaves[1][2][ctrl][pause] , 
  \ibAppWaveformSlaves[1][2][ctrl][overflow] , 
  \ibAppWaveformSlaves[1][2][ctrl][idle] , 
  \ibAppWaveformSlaves[1][1][slave][tReady] , 
  \ibAppWaveformSlaves[1][1][ctrl][pause] , 
  \ibAppWaveformSlaves[1][1][ctrl][overflow] , 
  \ibAppWaveformSlaves[1][1][ctrl][idle] , 
  \ibAppWaveformSlaves[1][0][slave][tReady] , 
  \ibAppWaveformSlaves[1][0][ctrl][pause] , 
  \ibAppWaveformSlaves[1][0][ctrl][overflow] , 
  \ibAppWaveformSlaves[1][0][ctrl][idle] , 
  \ibAppWaveformSlaves[0][3][slave][tReady] , 
  \ibAppWaveformSlaves[0][3][ctrl][pause] , 
  \ibAppWaveformSlaves[0][3][ctrl][overflow] , 
  \ibAppWaveformSlaves[0][3][ctrl][idle] , 
  \ibAppWaveformSlaves[0][2][slave][tReady] , 
  \ibAppWaveformSlaves[0][2][ctrl][pause] , 
  \ibAppWaveformSlaves[0][2][ctrl][overflow] , 
  \ibAppWaveformSlaves[0][2][ctrl][idle] , 
  \ibAppWaveformSlaves[0][1][slave][tReady] , 
  \ibAppWaveformSlaves[0][1][ctrl][pause] , 
  \ibAppWaveformSlaves[0][1][ctrl][overflow] , 
  \ibAppWaveformSlaves[0][1][ctrl][idle] , 
  \ibAppWaveformSlaves[0][0][slave][tReady] , 
  \ibAppWaveformSlaves[0][0][ctrl][pause] , 
  \ibAppWaveformSlaves[0][0][ctrl][overflow] , 
  \ibAppWaveformSlaves[0][0][ctrl][idle] , \obBpMsgClientMaster[tValid] , 
  \obBpMsgClientMaster[tData] , \obBpMsgClientMaster[tStrb] , 
  \obBpMsgClientMaster[tKeep] , \obBpMsgClientMaster[tLast] , 
  \obBpMsgClientMaster[tDest] , \obBpMsgClientMaster[tId] , 
  \obBpMsgClientMaster[tUser] , \obBpMsgClientSlave[tReady] , 
  \ibBpMsgClientMaster[tValid] , \ibBpMsgClientMaster[tData] , 
  \ibBpMsgClientMaster[tStrb] , \ibBpMsgClientMaster[tKeep] , 
  \ibBpMsgClientMaster[tLast] , \ibBpMsgClientMaster[tDest] , 
  \ibBpMsgClientMaster[tId] , \ibBpMsgClientMaster[tUser] , 
  \ibBpMsgClientSlave[tReady] , \obBpMsgServerMaster[tValid] , 
  \obBpMsgServerMaster[tData] , \obBpMsgServerMaster[tStrb] , 
  \obBpMsgServerMaster[tKeep] , \obBpMsgServerMaster[tLast] , 
  \obBpMsgServerMaster[tDest] , \obBpMsgServerMaster[tId] , 
  \obBpMsgServerMaster[tUser] , \obBpMsgServerSlave[tReady] , 
  \ibBpMsgServerMaster[tValid] , \ibBpMsgServerMaster[tData] , 
  \ibBpMsgServerMaster[tStrb] , \ibBpMsgServerMaster[tKeep] , 
  \ibBpMsgServerMaster[tLast] , \ibBpMsgServerMaster[tDest] , 
  \ibBpMsgServerMaster[tId] , \ibBpMsgServerMaster[tUser] , 
  \ibBpMsgServerSlave[tReady] , \obAppDebugMaster[tValid] , \obAppDebugMaster[tData] , 
  \obAppDebugMaster[tStrb] , \obAppDebugMaster[tKeep] , \obAppDebugMaster[tLast] , 
  \obAppDebugMaster[tDest] , \obAppDebugMaster[tId] , \obAppDebugMaster[tUser] , 
  \obAppDebugSlave[tReady] , \ibAppDebugMaster[tValid] , \ibAppDebugMaster[tData] , 
  \ibAppDebugMaster[tStrb] , \ibAppDebugMaster[tKeep] , \ibAppDebugMaster[tLast] , 
  \ibAppDebugMaster[tDest] , \ibAppDebugMaster[tId] , \ibAppDebugMaster[tUser] , 
  \ibAppDebugSlave[tReady] , recTimingClk, recTimingRst, ref156MHzClk, ref156MHzRst, 
  gthFabClk, \axilReadMasters[1][araddr] , \axilReadMasters[1][arprot] , 
  \axilReadMasters[1][arvalid] , \axilReadMasters[1][rready] , 
  \axilReadMasters[0][araddr] , \axilReadMasters[0][arprot] , 
  \axilReadMasters[0][arvalid] , \axilReadMasters[0][rready] , 
  \axilReadSlaves[1][arready] , \axilReadSlaves[1][rdata] , \axilReadSlaves[1][rresp] , 
  \axilReadSlaves[1][rvalid] , \axilReadSlaves[0][arready] , 
  \axilReadSlaves[0][rdata] , \axilReadSlaves[0][rresp] , \axilReadSlaves[0][rvalid] , 
  \axilWriteMasters[1][awaddr] , \axilWriteMasters[1][awprot] , 
  \axilWriteMasters[1][awvalid] , \axilWriteMasters[1][wdata] , 
  \axilWriteMasters[1][wstrb] , \axilWriteMasters[1][wvalid] , 
  \axilWriteMasters[1][bready] , \axilWriteMasters[0][awaddr] , 
  \axilWriteMasters[0][awprot] , \axilWriteMasters[0][awvalid] , 
  \axilWriteMasters[0][wdata] , \axilWriteMasters[0][wstrb] , 
  \axilWriteMasters[0][wvalid] , \axilWriteMasters[0][bready] , 
  \axilWriteSlaves[1][awready] , \axilWriteSlaves[1][wready] , 
  \axilWriteSlaves[1][bresp] , \axilWriteSlaves[1][bvalid] , 
  \axilWriteSlaves[0][awready] , \axilWriteSlaves[0][wready] , 
  \axilWriteSlaves[0][bresp] , \axilWriteSlaves[0][bvalid] , \ethReadMaster[araddr] , 
  \ethReadMaster[arprot] , \ethReadMaster[arvalid] , \ethReadMaster[rready] , 
  \ethReadSlave[arready] , \ethReadSlave[rdata] , \ethReadSlave[rresp] , 
  \ethReadSlave[rvalid] , \ethWriteMaster[awaddr] , \ethWriteMaster[awprot] , 
  \ethWriteMaster[awvalid] , \ethWriteMaster[wdata] , \ethWriteMaster[wstrb] , 
  \ethWriteMaster[wvalid] , \ethWriteMaster[bready] , \ethWriteSlave[awready] , 
  \ethWriteSlave[wready] , \ethWriteSlave[bresp] , \ethWriteSlave[bvalid] , localMac, 
  localIp, ethLinkUp, \timingReadMaster[araddr] , \timingReadMaster[arprot] , 
  \timingReadMaster[arvalid] , \timingReadMaster[rready] , \timingReadSlave[arready] , 
  \timingReadSlave[rdata] , \timingReadSlave[rresp] , \timingReadSlave[rvalid] , 
  \timingWriteMaster[awaddr] , \timingWriteMaster[awprot] , 
  \timingWriteMaster[awvalid] , \timingWriteMaster[wdata] , \timingWriteMaster[wstrb] , 
  \timingWriteMaster[wvalid] , \timingWriteMaster[bready] , 
  \timingWriteSlave[awready] , \timingWriteSlave[wready] , \timingWriteSlave[bresp] , 
  \timingWriteSlave[bvalid] , \bsaReadMaster[araddr] , \bsaReadMaster[arprot] , 
  \bsaReadMaster[arvalid] , \bsaReadMaster[rready] , \bsaReadSlave[arready] , 
  \bsaReadSlave[rdata] , \bsaReadSlave[rresp] , \bsaReadSlave[rvalid] , 
  \bsaWriteMaster[awaddr] , \bsaWriteMaster[awprot] , \bsaWriteMaster[awvalid] , 
  \bsaWriteMaster[wdata] , \bsaWriteMaster[wstrb] , \bsaWriteMaster[wvalid] , 
  \bsaWriteMaster[bready] , \bsaWriteSlave[awready] , \bsaWriteSlave[wready] , 
  \bsaWriteSlave[bresp] , \bsaWriteSlave[bvalid] , \ddrReadMaster[araddr] , 
  \ddrReadMaster[arprot] , \ddrReadMaster[arvalid] , \ddrReadMaster[rready] , 
  \ddrReadSlave[arready] , \ddrReadSlave[rdata] , \ddrReadSlave[rresp] , 
  \ddrReadSlave[rvalid] , \ddrWriteMaster[awaddr] , \ddrWriteMaster[awprot] , 
  \ddrWriteMaster[awvalid] , \ddrWriteMaster[wdata] , \ddrWriteMaster[wstrb] , 
  \ddrWriteMaster[wvalid] , \ddrWriteMaster[bready] , \ddrWriteSlave[awready] , 
  \ddrWriteSlave[wready] , \ddrWriteSlave[bresp] , \ddrWriteSlave[bvalid] , ddrMemReady, 
  ddrMemError, fabClkP, fabClkN, ethRxP, ethRxN, ethTxP, ethTxN, ethClkP, ethClkN, timingRxP, 
  timingRxN, timingTxP, timingTxN, timingRefClkInP, timingRefClkInN, timingRecClkOutP, 
  timingRecClkOutN, timingClkSel, enAuxPwrL, ddrClkP, ddrClkN, ddrDm, ddrDqsP, ddrDqsN, ddrDq, ddrA, 
  ddrBa, ddrCsL, ddrOdt, ddrCke, ddrCkP, ddrCkN, ddrWeL, ddrRasL, ddrCasL, ddrRstL, ddrAlertL, ddrPg, 
  ddrPwrEnL)
/* synthesis syn_black_box black_box_pad_pin="timingClk,timingRst,\timingBus[strobe] ,\timingBus[valid] ,\timingBus[message][version] [15:0],\timingBus[message][pulseId] [63:0],\timingBus[message][timeStamp] [63:0],\timingBus[message][fixedRates] [9:0],\timingBus[message][acRates] [5:0],\timingBus[message][acTimeSlot] [2:0],\timingBus[message][acTimeSlotPhase] [11:0],\timingBus[message][resync] ,\timingBus[message][beamRequest] [31:0],\timingBus[message][beamEnergy][0] [15:0],\timingBus[message][beamEnergy][1] [15:0],\timingBus[message][beamEnergy][2] [15:0],\timingBus[message][beamEnergy][3] [15:0],\timingBus[message][photonWavelen][0] [15:0],\timingBus[message][photonWavelen][1] [15:0],\timingBus[message][syncStatus] ,\timingBus[message][mpsValid] ,\timingBus[message][bcsFault] [0:0],\timingBus[message][mpsLimit] [15:0],\timingBus[message][mpsClass][0] [3:0],\timingBus[message][mpsClass][1] [3:0],\timingBus[message][mpsClass][2] [3:0],\timingBus[message][mpsClass][3] [3:0],\timingBus[message][mpsClass][4] [3:0],\timingBus[message][mpsClass][5] [3:0],\timingBus[message][mpsClass][6] [3:0],\timingBus[message][mpsClass][7] [3:0],\timingBus[message][mpsClass][8] [3:0],\timingBus[message][mpsClass][9] [3:0],\timingBus[message][mpsClass][10] [3:0],\timingBus[message][mpsClass][11] [3:0],\timingBus[message][mpsClass][12] [3:0],\timingBus[message][mpsClass][13] [3:0],\timingBus[message][mpsClass][14] [3:0],\timingBus[message][mpsClass][15] [3:0],\timingBus[message][bsaInit] [63:0],\timingBus[message][bsaActive] [63:0],\timingBus[message][bsaAvgDone] [63:0],\timingBus[message][bsaDone] [63:0],\timingBus[message][control][0] [15:0],\timingBus[message][control][1] [15:0],\timingBus[message][control][2] [15:0],\timingBus[message][control][3] [15:0],\timingBus[message][control][4] [15:0],\timingBus[message][control][5] [15:0],\timingBus[message][control][6] [15:0],\timingBus[message][control][7] [15:0],\timingBus[message][control][8] [15:0],\timingBus[message][control][9] [15:0],\timingBus[message][control][10] [15:0],\timingBus[message][control][11] [15:0],\timingBus[message][control][12] [15:0],\timingBus[message][control][13] [15:0],\timingBus[message][control][14] [15:0],\timingBus[message][control][15] [15:0],\timingBus[message][control][16] [15:0],\timingBus[message][control][17] [15:0],\timingBus[stream][pulseId] [31:0],\timingBus[stream][eventCodes] [255:0],\timingBus[stream][dbuff][dtype] [15:0],\timingBus[stream][dbuff][version] [15:0],\timingBus[stream][dbuff][dmod] [191:0],\timingBus[stream][dbuff][epicsTime] [63:0],\timingBus[stream][dbuff][edefAvgDn] [31:0],\timingBus[stream][dbuff][edefMinor] [31:0],\timingBus[stream][dbuff][edefMajor] [31:0],\timingBus[stream][dbuff][edefInit] [31:0],\timingBus[v1][linkUp] ,\timingBus[v1][gtRxData] [15:0],\timingBus[v1][gtRxDataK] [1:0],\timingBus[v1][gtRxDispErr] [1:0],\timingBus[v1][gtRxDecErr] [1:0],\timingBus[v2][linkUp] ,\timingPhy[dataK] [1:0],\timingPhy[data] [15:0],\timingPhy[control][reset] ,\timingPhy[control][inhibit] ,\timingPhy[control][polarity] ,\timingPhy[control][bufferByRst] ,\timingPhy[control][pllReset] ,timingPhyClk,timingPhyRst,timingRefClk,timingRefClkDiv2,diagnosticClk,diagnosticRst,\diagnosticBus[strobe] ,\diagnosticBus[data][31] [31:0],\diagnosticBus[data][30] [31:0],\diagnosticBus[data][29] [31:0],\diagnosticBus[data][28] [31:0],\diagnosticBus[data][27] [31:0],\diagnosticBus[data][26] [31:0],\diagnosticBus[data][25] [31:0],\diagnosticBus[data][24] [31:0],\diagnosticBus[data][23] [31:0],\diagnosticBus[data][22] [31:0],\diagnosticBus[data][21] [31:0],\diagnosticBus[data][20] [31:0],\diagnosticBus[data][19] [31:0],\diagnosticBus[data][18] [31:0],\diagnosticBus[data][17] [31:0],\diagnosticBus[data][16] [31:0],\diagnosticBus[data][15] [31:0],\diagnosticBus[data][14] [31:0],\diagnosticBus[data][13] [31:0],\diagnosticBus[data][12] [31:0],\diagnosticBus[data][11] [31:0],\diagnosticBus[data][10] [31:0],\diagnosticBus[data][9] [31:0],\diagnosticBus[data][8] [31:0],\diagnosticBus[data][7] [31:0],\diagnosticBus[data][6] [31:0],\diagnosticBus[data][5] [31:0],\diagnosticBus[data][4] [31:0],\diagnosticBus[data][3] [31:0],\diagnosticBus[data][2] [31:0],\diagnosticBus[data][1] [31:0],\diagnosticBus[data][0] [31:0],\diagnosticBus[sevr][31] [1:0],\diagnosticBus[sevr][30] [1:0],\diagnosticBus[sevr][29] [1:0],\diagnosticBus[sevr][28] [1:0],\diagnosticBus[sevr][27] [1:0],\diagnosticBus[sevr][26] [1:0],\diagnosticBus[sevr][25] [1:0],\diagnosticBus[sevr][24] [1:0],\diagnosticBus[sevr][23] [1:0],\diagnosticBus[sevr][22] [1:0],\diagnosticBus[sevr][21] [1:0],\diagnosticBus[sevr][20] [1:0],\diagnosticBus[sevr][19] [1:0],\diagnosticBus[sevr][18] [1:0],\diagnosticBus[sevr][17] [1:0],\diagnosticBus[sevr][16] [1:0],\diagnosticBus[sevr][15] [1:0],\diagnosticBus[sevr][14] [1:0],\diagnosticBus[sevr][13] [1:0],\diagnosticBus[sevr][12] [1:0],\diagnosticBus[sevr][11] [1:0],\diagnosticBus[sevr][10] [1:0],\diagnosticBus[sevr][9] [1:0],\diagnosticBus[sevr][8] [1:0],\diagnosticBus[sevr][7] [1:0],\diagnosticBus[sevr][6] [1:0],\diagnosticBus[sevr][5] [1:0],\diagnosticBus[sevr][4] [1:0],\diagnosticBus[sevr][3] [1:0],\diagnosticBus[sevr][2] [1:0],\diagnosticBus[sevr][1] [1:0],\diagnosticBus[sevr][0] [1:0],\diagnosticBus[fixed] [31:0],\diagnosticBus[mpsIgnore] [31:0],\diagnosticBus[timingMessage][version] [15:0],\diagnosticBus[timingMessage][pulseId] [63:0],\diagnosticBus[timingMessage][timeStamp] [63:0],\diagnosticBus[timingMessage][fixedRates] [9:0],\diagnosticBus[timingMessage][acRates] [5:0],\diagnosticBus[timingMessage][acTimeSlot] [2:0],\diagnosticBus[timingMessage][acTimeSlotPhase] [11:0],\diagnosticBus[timingMessage][resync] ,\diagnosticBus[timingMessage][beamRequest] [31:0],\diagnosticBus[timingMessage][beamEnergy][0] [15:0],\diagnosticBus[timingMessage][beamEnergy][1] [15:0],\diagnosticBus[timingMessage][beamEnergy][2] [15:0],\diagnosticBus[timingMessage][beamEnergy][3] [15:0],\diagnosticBus[timingMessage][photonWavelen][0] [15:0],\diagnosticBus[timingMessage][photonWavelen][1] [15:0],\diagnosticBus[timingMessage][syncStatus] ,\diagnosticBus[timingMessage][mpsValid] ,\diagnosticBus[timingMessage][bcsFault] [0:0],\diagnosticBus[timingMessage][mpsLimit] [15:0],\diagnosticBus[timingMessage][mpsClass][0] [3:0],\diagnosticBus[timingMessage][mpsClass][1] [3:0],\diagnosticBus[timingMessage][mpsClass][2] [3:0],\diagnosticBus[timingMessage][mpsClass][3] [3:0],\diagnosticBus[timingMessage][mpsClass][4] [3:0],\diagnosticBus[timingMessage][mpsClass][5] [3:0],\diagnosticBus[timingMessage][mpsClass][6] [3:0],\diagnosticBus[timingMessage][mpsClass][7] [3:0],\diagnosticBus[timingMessage][mpsClass][8] [3:0],\diagnosticBus[timingMessage][mpsClass][9] [3:0],\diagnosticBus[timingMessage][mpsClass][10] [3:0],\diagnosticBus[timingMessage][mpsClass][11] [3:0],\diagnosticBus[timingMessage][mpsClass][12] [3:0],\diagnosticBus[timingMessage][mpsClass][13] [3:0],\diagnosticBus[timingMessage][mpsClass][14] [3:0],\diagnosticBus[timingMessage][mpsClass][15] [3:0],\diagnosticBus[timingMessage][bsaInit] [63:0],\diagnosticBus[timingMessage][bsaActive] [63:0],\diagnosticBus[timingMessage][bsaAvgDone] [63:0],\diagnosticBus[timingMessage][bsaDone] [63:0],\diagnosticBus[timingMessage][control][0] [15:0],\diagnosticBus[timingMessage][control][1] [15:0],\diagnosticBus[timingMessage][control][2] [15:0],\diagnosticBus[timingMessage][control][3] [15:0],\diagnosticBus[timingMessage][control][4] [15:0],\diagnosticBus[timingMessage][control][5] [15:0],\diagnosticBus[timingMessage][control][6] [15:0],\diagnosticBus[timingMessage][control][7] [15:0],\diagnosticBus[timingMessage][control][8] [15:0],\diagnosticBus[timingMessage][control][9] [15:0],\diagnosticBus[timingMessage][control][10] [15:0],\diagnosticBus[timingMessage][control][11] [15:0],\diagnosticBus[timingMessage][control][12] [15:0],\diagnosticBus[timingMessage][control][13] [15:0],\diagnosticBus[timingMessage][control][14] [15:0],\diagnosticBus[timingMessage][control][15] [15:0],\diagnosticBus[timingMessage][control][16] [15:0],\diagnosticBus[timingMessage][control][17] [15:0],waveformClk,waveformRst,\obAppWaveformMasters[1][3][tValid] ,\obAppWaveformMasters[1][3][tData] [127:0],\obAppWaveformMasters[1][3][tStrb] [15:0],\obAppWaveformMasters[1][3][tKeep] [15:0],\obAppWaveformMasters[1][3][tLast] ,\obAppWaveformMasters[1][3][tDest] [7:0],\obAppWaveformMasters[1][3][tId] [7:0],\obAppWaveformMasters[1][3][tUser] [127:0],\obAppWaveformMasters[1][2][tValid] ,\obAppWaveformMasters[1][2][tData] [127:0],\obAppWaveformMasters[1][2][tStrb] [15:0],\obAppWaveformMasters[1][2][tKeep] [15:0],\obAppWaveformMasters[1][2][tLast] ,\obAppWaveformMasters[1][2][tDest] [7:0],\obAppWaveformMasters[1][2][tId] [7:0],\obAppWaveformMasters[1][2][tUser] [127:0],\obAppWaveformMasters[1][1][tValid] ,\obAppWaveformMasters[1][1][tData] [127:0],\obAppWaveformMasters[1][1][tStrb] [15:0],\obAppWaveformMasters[1][1][tKeep] [15:0],\obAppWaveformMasters[1][1][tLast] ,\obAppWaveformMasters[1][1][tDest] [7:0],\obAppWaveformMasters[1][1][tId] [7:0],\obAppWaveformMasters[1][1][tUser] [127:0],\obAppWaveformMasters[1][0][tValid] ,\obAppWaveformMasters[1][0][tData] [127:0],\obAppWaveformMasters[1][0][tStrb] [15:0],\obAppWaveformMasters[1][0][tKeep] [15:0],\obAppWaveformMasters[1][0][tLast] ,\obAppWaveformMasters[1][0][tDest] [7:0],\obAppWaveformMasters[1][0][tId] [7:0],\obAppWaveformMasters[1][0][tUser] [127:0],\obAppWaveformMasters[0][3][tValid] ,\obAppWaveformMasters[0][3][tData] [127:0],\obAppWaveformMasters[0][3][tStrb] [15:0],\obAppWaveformMasters[0][3][tKeep] [15:0],\obAppWaveformMasters[0][3][tLast] ,\obAppWaveformMasters[0][3][tDest] [7:0],\obAppWaveformMasters[0][3][tId] [7:0],\obAppWaveformMasters[0][3][tUser] [127:0],\obAppWaveformMasters[0][2][tValid] ,\obAppWaveformMasters[0][2][tData] [127:0],\obAppWaveformMasters[0][2][tStrb] [15:0],\obAppWaveformMasters[0][2][tKeep] [15:0],\obAppWaveformMasters[0][2][tLast] ,\obAppWaveformMasters[0][2][tDest] [7:0],\obAppWaveformMasters[0][2][tId] [7:0],\obAppWaveformMasters[0][2][tUser] [127:0],\obAppWaveformMasters[0][1][tValid] ,\obAppWaveformMasters[0][1][tData] [127:0],\obAppWaveformMasters[0][1][tStrb] [15:0],\obAppWaveformMasters[0][1][tKeep] [15:0],\obAppWaveformMasters[0][1][tLast] ,\obAppWaveformMasters[0][1][tDest] [7:0],\obAppWaveformMasters[0][1][tId] [7:0],\obAppWaveformMasters[0][1][tUser] [127:0],\obAppWaveformMasters[0][0][tValid] ,\obAppWaveformMasters[0][0][tData] [127:0],\obAppWaveformMasters[0][0][tStrb] [15:0],\obAppWaveformMasters[0][0][tKeep] [15:0],\obAppWaveformMasters[0][0][tLast] ,\obAppWaveformMasters[0][0][tDest] [7:0],\obAppWaveformMasters[0][0][tId] [7:0],\obAppWaveformMasters[0][0][tUser] [127:0],\obAppWaveformSlaves[1][3][slave][tReady] ,\obAppWaveformSlaves[1][3][ctrl][pause] ,\obAppWaveformSlaves[1][3][ctrl][overflow] ,\obAppWaveformSlaves[1][3][ctrl][idle] ,\obAppWaveformSlaves[1][2][slave][tReady] ,\obAppWaveformSlaves[1][2][ctrl][pause] ,\obAppWaveformSlaves[1][2][ctrl][overflow] ,\obAppWaveformSlaves[1][2][ctrl][idle] ,\obAppWaveformSlaves[1][1][slave][tReady] ,\obAppWaveformSlaves[1][1][ctrl][pause] ,\obAppWaveformSlaves[1][1][ctrl][overflow] ,\obAppWaveformSlaves[1][1][ctrl][idle] ,\obAppWaveformSlaves[1][0][slave][tReady] ,\obAppWaveformSlaves[1][0][ctrl][pause] ,\obAppWaveformSlaves[1][0][ctrl][overflow] ,\obAppWaveformSlaves[1][0][ctrl][idle] ,\obAppWaveformSlaves[0][3][slave][tReady] ,\obAppWaveformSlaves[0][3][ctrl][pause] ,\obAppWaveformSlaves[0][3][ctrl][overflow] ,\obAppWaveformSlaves[0][3][ctrl][idle] ,\obAppWaveformSlaves[0][2][slave][tReady] ,\obAppWaveformSlaves[0][2][ctrl][pause] ,\obAppWaveformSlaves[0][2][ctrl][overflow] ,\obAppWaveformSlaves[0][2][ctrl][idle] ,\obAppWaveformSlaves[0][1][slave][tReady] ,\obAppWaveformSlaves[0][1][ctrl][pause] ,\obAppWaveformSlaves[0][1][ctrl][overflow] ,\obAppWaveformSlaves[0][1][ctrl][idle] ,\obAppWaveformSlaves[0][0][slave][tReady] ,\obAppWaveformSlaves[0][0][ctrl][pause] ,\obAppWaveformSlaves[0][0][ctrl][overflow] ,\obAppWaveformSlaves[0][0][ctrl][idle] ,\ibAppWaveformMasters[1][3][tValid] ,\ibAppWaveformMasters[1][3][tData] [127:0],\ibAppWaveformMasters[1][3][tStrb] [15:0],\ibAppWaveformMasters[1][3][tKeep] [15:0],\ibAppWaveformMasters[1][3][tLast] ,\ibAppWaveformMasters[1][3][tDest] [7:0],\ibAppWaveformMasters[1][3][tId] [7:0],\ibAppWaveformMasters[1][3][tUser] [127:0],\ibAppWaveformMasters[1][2][tValid] ,\ibAppWaveformMasters[1][2][tData] [127:0],\ibAppWaveformMasters[1][2][tStrb] [15:0],\ibAppWaveformMasters[1][2][tKeep] [15:0],\ibAppWaveformMasters[1][2][tLast] ,\ibAppWaveformMasters[1][2][tDest] [7:0],\ibAppWaveformMasters[1][2][tId] [7:0],\ibAppWaveformMasters[1][2][tUser] [127:0],\ibAppWaveformMasters[1][1][tValid] ,\ibAppWaveformMasters[1][1][tData] [127:0],\ibAppWaveformMasters[1][1][tStrb] [15:0],\ibAppWaveformMasters[1][1][tKeep] [15:0],\ibAppWaveformMasters[1][1][tLast] ,\ibAppWaveformMasters[1][1][tDest] [7:0],\ibAppWaveformMasters[1][1][tId] [7:0],\ibAppWaveformMasters[1][1][tUser] [127:0],\ibAppWaveformMasters[1][0][tValid] ,\ibAppWaveformMasters[1][0][tData] [127:0],\ibAppWaveformMasters[1][0][tStrb] [15:0],\ibAppWaveformMasters[1][0][tKeep] [15:0],\ibAppWaveformMasters[1][0][tLast] ,\ibAppWaveformMasters[1][0][tDest] [7:0],\ibAppWaveformMasters[1][0][tId] [7:0],\ibAppWaveformMasters[1][0][tUser] [127:0],\ibAppWaveformMasters[0][3][tValid] ,\ibAppWaveformMasters[0][3][tData] [127:0],\ibAppWaveformMasters[0][3][tStrb] [15:0],\ibAppWaveformMasters[0][3][tKeep] [15:0],\ibAppWaveformMasters[0][3][tLast] ,\ibAppWaveformMasters[0][3][tDest] [7:0],\ibAppWaveformMasters[0][3][tId] [7:0],\ibAppWaveformMasters[0][3][tUser] [127:0],\ibAppWaveformMasters[0][2][tValid] ,\ibAppWaveformMasters[0][2][tData] [127:0],\ibAppWaveformMasters[0][2][tStrb] [15:0],\ibAppWaveformMasters[0][2][tKeep] [15:0],\ibAppWaveformMasters[0][2][tLast] ,\ibAppWaveformMasters[0][2][tDest] [7:0],\ibAppWaveformMasters[0][2][tId] [7:0],\ibAppWaveformMasters[0][2][tUser] [127:0],\ibAppWaveformMasters[0][1][tValid] ,\ibAppWaveformMasters[0][1][tData] [127:0],\ibAppWaveformMasters[0][1][tStrb] [15:0],\ibAppWaveformMasters[0][1][tKeep] [15:0],\ibAppWaveformMasters[0][1][tLast] ,\ibAppWaveformMasters[0][1][tDest] [7:0],\ibAppWaveformMasters[0][1][tId] [7:0],\ibAppWaveformMasters[0][1][tUser] [127:0],\ibAppWaveformMasters[0][0][tValid] ,\ibAppWaveformMasters[0][0][tData] [127:0],\ibAppWaveformMasters[0][0][tStrb] [15:0],\ibAppWaveformMasters[0][0][tKeep] [15:0],\ibAppWaveformMasters[0][0][tLast] ,\ibAppWaveformMasters[0][0][tDest] [7:0],\ibAppWaveformMasters[0][0][tId] [7:0],\ibAppWaveformMasters[0][0][tUser] [127:0],\ibAppWaveformSlaves[1][3][slave][tReady] ,\ibAppWaveformSlaves[1][3][ctrl][pause] ,\ibAppWaveformSlaves[1][3][ctrl][overflow] ,\ibAppWaveformSlaves[1][3][ctrl][idle] ,\ibAppWaveformSlaves[1][2][slave][tReady] ,\ibAppWaveformSlaves[1][2][ctrl][pause] ,\ibAppWaveformSlaves[1][2][ctrl][overflow] ,\ibAppWaveformSlaves[1][2][ctrl][idle] ,\ibAppWaveformSlaves[1][1][slave][tReady] ,\ibAppWaveformSlaves[1][1][ctrl][pause] ,\ibAppWaveformSlaves[1][1][ctrl][overflow] ,\ibAppWaveformSlaves[1][1][ctrl][idle] ,\ibAppWaveformSlaves[1][0][slave][tReady] ,\ibAppWaveformSlaves[1][0][ctrl][pause] ,\ibAppWaveformSlaves[1][0][ctrl][overflow] ,\ibAppWaveformSlaves[1][0][ctrl][idle] ,\ibAppWaveformSlaves[0][3][slave][tReady] ,\ibAppWaveformSlaves[0][3][ctrl][pause] ,\ibAppWaveformSlaves[0][3][ctrl][overflow] ,\ibAppWaveformSlaves[0][3][ctrl][idle] ,\ibAppWaveformSlaves[0][2][slave][tReady] ,\ibAppWaveformSlaves[0][2][ctrl][pause] ,\ibAppWaveformSlaves[0][2][ctrl][overflow] ,\ibAppWaveformSlaves[0][2][ctrl][idle] ,\ibAppWaveformSlaves[0][1][slave][tReady] ,\ibAppWaveformSlaves[0][1][ctrl][pause] ,\ibAppWaveformSlaves[0][1][ctrl][overflow] ,\ibAppWaveformSlaves[0][1][ctrl][idle] ,\ibAppWaveformSlaves[0][0][slave][tReady] ,\ibAppWaveformSlaves[0][0][ctrl][pause] ,\ibAppWaveformSlaves[0][0][ctrl][overflow] ,\ibAppWaveformSlaves[0][0][ctrl][idle] ,\obBpMsgClientMaster[tValid] ,\obBpMsgClientMaster[tData] [127:0],\obBpMsgClientMaster[tStrb] [15:0],\obBpMsgClientMaster[tKeep] [15:0],\obBpMsgClientMaster[tLast] ,\obBpMsgClientMaster[tDest] [7:0],\obBpMsgClientMaster[tId] [7:0],\obBpMsgClientMaster[tUser] [127:0],\obBpMsgClientSlave[tReady] ,\ibBpMsgClientMaster[tValid] ,\ibBpMsgClientMaster[tData] [127:0],\ibBpMsgClientMaster[tStrb] [15:0],\ibBpMsgClientMaster[tKeep] [15:0],\ibBpMsgClientMaster[tLast] ,\ibBpMsgClientMaster[tDest] [7:0],\ibBpMsgClientMaster[tId] [7:0],\ibBpMsgClientMaster[tUser] [127:0],\ibBpMsgClientSlave[tReady] ,\obBpMsgServerMaster[tValid] ,\obBpMsgServerMaster[tData] [127:0],\obBpMsgServerMaster[tStrb] [15:0],\obBpMsgServerMaster[tKeep] [15:0],\obBpMsgServerMaster[tLast] ,\obBpMsgServerMaster[tDest] [7:0],\obBpMsgServerMaster[tId] [7:0],\obBpMsgServerMaster[tUser] [127:0],\obBpMsgServerSlave[tReady] ,\ibBpMsgServerMaster[tValid] ,\ibBpMsgServerMaster[tData] [127:0],\ibBpMsgServerMaster[tStrb] [15:0],\ibBpMsgServerMaster[tKeep] [15:0],\ibBpMsgServerMaster[tLast] ,\ibBpMsgServerMaster[tDest] [7:0],\ibBpMsgServerMaster[tId] [7:0],\ibBpMsgServerMaster[tUser] [127:0],\ibBpMsgServerSlave[tReady] ,\obAppDebugMaster[tValid] ,\obAppDebugMaster[tData] [127:0],\obAppDebugMaster[tStrb] [15:0],\obAppDebugMaster[tKeep] [15:0],\obAppDebugMaster[tLast] ,\obAppDebugMaster[tDest] [7:0],\obAppDebugMaster[tId] [7:0],\obAppDebugMaster[tUser] [127:0],\obAppDebugSlave[tReady] ,\ibAppDebugMaster[tValid] ,\ibAppDebugMaster[tData] [127:0],\ibAppDebugMaster[tStrb] [15:0],\ibAppDebugMaster[tKeep] [15:0],\ibAppDebugMaster[tLast] ,\ibAppDebugMaster[tDest] [7:0],\ibAppDebugMaster[tId] [7:0],\ibAppDebugMaster[tUser] [127:0],\ibAppDebugSlave[tReady] ,recTimingClk,recTimingRst,ref156MHzClk,ref156MHzRst,gthFabClk,\axilReadMasters[1][araddr] [31:0],\axilReadMasters[1][arprot] [2:0],\axilReadMasters[1][arvalid] ,\axilReadMasters[1][rready] ,\axilReadMasters[0][araddr] [31:0],\axilReadMasters[0][arprot] [2:0],\axilReadMasters[0][arvalid] ,\axilReadMasters[0][rready] ,\axilReadSlaves[1][arready] ,\axilReadSlaves[1][rdata] [31:0],\axilReadSlaves[1][rresp] [1:0],\axilReadSlaves[1][rvalid] ,\axilReadSlaves[0][arready] ,\axilReadSlaves[0][rdata] [31:0],\axilReadSlaves[0][rresp] [1:0],\axilReadSlaves[0][rvalid] ,\axilWriteMasters[1][awaddr] [31:0],\axilWriteMasters[1][awprot] [2:0],\axilWriteMasters[1][awvalid] ,\axilWriteMasters[1][wdata] [31:0],\axilWriteMasters[1][wstrb] [3:0],\axilWriteMasters[1][wvalid] ,\axilWriteMasters[1][bready] ,\axilWriteMasters[0][awaddr] [31:0],\axilWriteMasters[0][awprot] [2:0],\axilWriteMasters[0][awvalid] ,\axilWriteMasters[0][wdata] [31:0],\axilWriteMasters[0][wstrb] [3:0],\axilWriteMasters[0][wvalid] ,\axilWriteMasters[0][bready] ,\axilWriteSlaves[1][awready] ,\axilWriteSlaves[1][wready] ,\axilWriteSlaves[1][bresp] [1:0],\axilWriteSlaves[1][bvalid] ,\axilWriteSlaves[0][awready] ,\axilWriteSlaves[0][wready] ,\axilWriteSlaves[0][bresp] [1:0],\axilWriteSlaves[0][bvalid] ,\ethReadMaster[araddr] [31:0],\ethReadMaster[arprot] [2:0],\ethReadMaster[arvalid] ,\ethReadMaster[rready] ,\ethReadSlave[arready] ,\ethReadSlave[rdata] [31:0],\ethReadSlave[rresp] [1:0],\ethReadSlave[rvalid] ,\ethWriteMaster[awaddr] [31:0],\ethWriteMaster[awprot] [2:0],\ethWriteMaster[awvalid] ,\ethWriteMaster[wdata] [31:0],\ethWriteMaster[wstrb] [3:0],\ethWriteMaster[wvalid] ,\ethWriteMaster[bready] ,\ethWriteSlave[awready] ,\ethWriteSlave[wready] ,\ethWriteSlave[bresp] [1:0],\ethWriteSlave[bvalid] ,localMac[47:0],localIp[31:0],ethLinkUp,\timingReadMaster[araddr] [31:0],\timingReadMaster[arprot] [2:0],\timingReadMaster[arvalid] ,\timingReadMaster[rready] ,\timingReadSlave[arready] ,\timingReadSlave[rdata] [31:0],\timingReadSlave[rresp] [1:0],\timingReadSlave[rvalid] ,\timingWriteMaster[awaddr] [31:0],\timingWriteMaster[awprot] [2:0],\timingWriteMaster[awvalid] ,\timingWriteMaster[wdata] [31:0],\timingWriteMaster[wstrb] [3:0],\timingWriteMaster[wvalid] ,\timingWriteMaster[bready] ,\timingWriteSlave[awready] ,\timingWriteSlave[wready] ,\timingWriteSlave[bresp] [1:0],\timingWriteSlave[bvalid] ,\bsaReadMaster[araddr] [31:0],\bsaReadMaster[arprot] [2:0],\bsaReadMaster[arvalid] ,\bsaReadMaster[rready] ,\bsaReadSlave[arready] ,\bsaReadSlave[rdata] [31:0],\bsaReadSlave[rresp] [1:0],\bsaReadSlave[rvalid] ,\bsaWriteMaster[awaddr] [31:0],\bsaWriteMaster[awprot] [2:0],\bsaWriteMaster[awvalid] ,\bsaWriteMaster[wdata] [31:0],\bsaWriteMaster[wstrb] [3:0],\bsaWriteMaster[wvalid] ,\bsaWriteMaster[bready] ,\bsaWriteSlave[awready] ,\bsaWriteSlave[wready] ,\bsaWriteSlave[bresp] [1:0],\bsaWriteSlave[bvalid] ,\ddrReadMaster[araddr] [31:0],\ddrReadMaster[arprot] [2:0],\ddrReadMaster[arvalid] ,\ddrReadMaster[rready] ,\ddrReadSlave[arready] ,\ddrReadSlave[rdata] [31:0],\ddrReadSlave[rresp] [1:0],\ddrReadSlave[rvalid] ,\ddrWriteMaster[awaddr] [31:0],\ddrWriteMaster[awprot] [2:0],\ddrWriteMaster[awvalid] ,\ddrWriteMaster[wdata] [31:0],\ddrWriteMaster[wstrb] [3:0],\ddrWriteMaster[wvalid] ,\ddrWriteMaster[bready] ,\ddrWriteSlave[awready] ,\ddrWriteSlave[wready] ,\ddrWriteSlave[bresp] [1:0],\ddrWriteSlave[bvalid] ,ddrMemReady,ddrMemError,fabClkP,fabClkN,ethRxP[3:0],ethRxN[3:0],ethTxP[3:0],ethTxN[3:0],ethClkP,ethClkN,timingRxP,timingRxN,timingTxP,timingTxN,timingRefClkInP,timingRefClkInN,timingRecClkOutP,timingRecClkOutN,timingClkSel,enAuxPwrL,ddrClkP,ddrClkN,ddrDm[7:0],ddrDqsP[7:0],ddrDqsN[7:0],ddrDq[63:0],ddrA[15:0],ddrBa[2:0],ddrCsL[1:0],ddrOdt[1:0],ddrCke[1:0],ddrCkP[1:0],ddrCkN[1:0],ddrWeL,ddrRasL,ddrCasL,ddrRstL,ddrAlertL,ddrPg,ddrPwrEnL" */;
  input timingClk;
  input timingRst;
  output \timingBus[strobe] ;
  output \timingBus[valid] ;
  output [15:0]\timingBus[message][version] ;
  output [63:0]\timingBus[message][pulseId] ;
  output [63:0]\timingBus[message][timeStamp] ;
  output [9:0]\timingBus[message][fixedRates] ;
  output [5:0]\timingBus[message][acRates] ;
  output [2:0]\timingBus[message][acTimeSlot] ;
  output [11:0]\timingBus[message][acTimeSlotPhase] ;
  output \timingBus[message][resync] ;
  output [31:0]\timingBus[message][beamRequest] ;
  output [15:0]\timingBus[message][beamEnergy][0] ;
  output [15:0]\timingBus[message][beamEnergy][1] ;
  output [15:0]\timingBus[message][beamEnergy][2] ;
  output [15:0]\timingBus[message][beamEnergy][3] ;
  output [15:0]\timingBus[message][photonWavelen][0] ;
  output [15:0]\timingBus[message][photonWavelen][1] ;
  output \timingBus[message][syncStatus] ;
  output \timingBus[message][mpsValid] ;
  output [0:0]\timingBus[message][bcsFault] ;
  output [15:0]\timingBus[message][mpsLimit] ;
  output [3:0]\timingBus[message][mpsClass][0] ;
  output [3:0]\timingBus[message][mpsClass][1] ;
  output [3:0]\timingBus[message][mpsClass][2] ;
  output [3:0]\timingBus[message][mpsClass][3] ;
  output [3:0]\timingBus[message][mpsClass][4] ;
  output [3:0]\timingBus[message][mpsClass][5] ;
  output [3:0]\timingBus[message][mpsClass][6] ;
  output [3:0]\timingBus[message][mpsClass][7] ;
  output [3:0]\timingBus[message][mpsClass][8] ;
  output [3:0]\timingBus[message][mpsClass][9] ;
  output [3:0]\timingBus[message][mpsClass][10] ;
  output [3:0]\timingBus[message][mpsClass][11] ;
  output [3:0]\timingBus[message][mpsClass][12] ;
  output [3:0]\timingBus[message][mpsClass][13] ;
  output [3:0]\timingBus[message][mpsClass][14] ;
  output [3:0]\timingBus[message][mpsClass][15] ;
  output [63:0]\timingBus[message][bsaInit] ;
  output [63:0]\timingBus[message][bsaActive] ;
  output [63:0]\timingBus[message][bsaAvgDone] ;
  output [63:0]\timingBus[message][bsaDone] ;
  output [15:0]\timingBus[message][control][0] ;
  output [15:0]\timingBus[message][control][1] ;
  output [15:0]\timingBus[message][control][2] ;
  output [15:0]\timingBus[message][control][3] ;
  output [15:0]\timingBus[message][control][4] ;
  output [15:0]\timingBus[message][control][5] ;
  output [15:0]\timingBus[message][control][6] ;
  output [15:0]\timingBus[message][control][7] ;
  output [15:0]\timingBus[message][control][8] ;
  output [15:0]\timingBus[message][control][9] ;
  output [15:0]\timingBus[message][control][10] ;
  output [15:0]\timingBus[message][control][11] ;
  output [15:0]\timingBus[message][control][12] ;
  output [15:0]\timingBus[message][control][13] ;
  output [15:0]\timingBus[message][control][14] ;
  output [15:0]\timingBus[message][control][15] ;
  output [15:0]\timingBus[message][control][16] ;
  output [15:0]\timingBus[message][control][17] ;
  output [31:0]\timingBus[stream][pulseId] ;
  output [255:0]\timingBus[stream][eventCodes] ;
  output [15:0]\timingBus[stream][dbuff][dtype] ;
  output [15:0]\timingBus[stream][dbuff][version] ;
  output [191:0]\timingBus[stream][dbuff][dmod] ;
  output [63:0]\timingBus[stream][dbuff][epicsTime] ;
  output [31:0]\timingBus[stream][dbuff][edefAvgDn] ;
  output [31:0]\timingBus[stream][dbuff][edefMinor] ;
  output [31:0]\timingBus[stream][dbuff][edefMajor] ;
  output [31:0]\timingBus[stream][dbuff][edefInit] ;
  output \timingBus[v1][linkUp] ;
  output [15:0]\timingBus[v1][gtRxData] ;
  output [1:0]\timingBus[v1][gtRxDataK] ;
  output [1:0]\timingBus[v1][gtRxDispErr] ;
  output [1:0]\timingBus[v1][gtRxDecErr] ;
  output \timingBus[v2][linkUp] ;
  input [1:0]\timingPhy[dataK] ;
  input [15:0]\timingPhy[data] ;
  input \timingPhy[control][reset] ;
  input \timingPhy[control][inhibit] ;
  input \timingPhy[control][polarity] ;
  input \timingPhy[control][bufferByRst] ;
  input \timingPhy[control][pllReset] ;
  output timingPhyClk;
  output timingPhyRst;
  output timingRefClk;
  output timingRefClkDiv2;
  input diagnosticClk;
  input diagnosticRst;
  input \diagnosticBus[strobe] ;
  input [31:0]\diagnosticBus[data][31] ;
  input [31:0]\diagnosticBus[data][30] ;
  input [31:0]\diagnosticBus[data][29] ;
  input [31:0]\diagnosticBus[data][28] ;
  input [31:0]\diagnosticBus[data][27] ;
  input [31:0]\diagnosticBus[data][26] ;
  input [31:0]\diagnosticBus[data][25] ;
  input [31:0]\diagnosticBus[data][24] ;
  input [31:0]\diagnosticBus[data][23] ;
  input [31:0]\diagnosticBus[data][22] ;
  input [31:0]\diagnosticBus[data][21] ;
  input [31:0]\diagnosticBus[data][20] ;
  input [31:0]\diagnosticBus[data][19] ;
  input [31:0]\diagnosticBus[data][18] ;
  input [31:0]\diagnosticBus[data][17] ;
  input [31:0]\diagnosticBus[data][16] ;
  input [31:0]\diagnosticBus[data][15] ;
  input [31:0]\diagnosticBus[data][14] ;
  input [31:0]\diagnosticBus[data][13] ;
  input [31:0]\diagnosticBus[data][12] ;
  input [31:0]\diagnosticBus[data][11] ;
  input [31:0]\diagnosticBus[data][10] ;
  input [31:0]\diagnosticBus[data][9] ;
  input [31:0]\diagnosticBus[data][8] ;
  input [31:0]\diagnosticBus[data][7] ;
  input [31:0]\diagnosticBus[data][6] ;
  input [31:0]\diagnosticBus[data][5] ;
  input [31:0]\diagnosticBus[data][4] ;
  input [31:0]\diagnosticBus[data][3] ;
  input [31:0]\diagnosticBus[data][2] ;
  input [31:0]\diagnosticBus[data][1] ;
  input [31:0]\diagnosticBus[data][0] ;
  input [1:0]\diagnosticBus[sevr][31] ;
  input [1:0]\diagnosticBus[sevr][30] ;
  input [1:0]\diagnosticBus[sevr][29] ;
  input [1:0]\diagnosticBus[sevr][28] ;
  input [1:0]\diagnosticBus[sevr][27] ;
  input [1:0]\diagnosticBus[sevr][26] ;
  input [1:0]\diagnosticBus[sevr][25] ;
  input [1:0]\diagnosticBus[sevr][24] ;
  input [1:0]\diagnosticBus[sevr][23] ;
  input [1:0]\diagnosticBus[sevr][22] ;
  input [1:0]\diagnosticBus[sevr][21] ;
  input [1:0]\diagnosticBus[sevr][20] ;
  input [1:0]\diagnosticBus[sevr][19] ;
  input [1:0]\diagnosticBus[sevr][18] ;
  input [1:0]\diagnosticBus[sevr][17] ;
  input [1:0]\diagnosticBus[sevr][16] ;
  input [1:0]\diagnosticBus[sevr][15] ;
  input [1:0]\diagnosticBus[sevr][14] ;
  input [1:0]\diagnosticBus[sevr][13] ;
  input [1:0]\diagnosticBus[sevr][12] ;
  input [1:0]\diagnosticBus[sevr][11] ;
  input [1:0]\diagnosticBus[sevr][10] ;
  input [1:0]\diagnosticBus[sevr][9] ;
  input [1:0]\diagnosticBus[sevr][8] ;
  input [1:0]\diagnosticBus[sevr][7] ;
  input [1:0]\diagnosticBus[sevr][6] ;
  input [1:0]\diagnosticBus[sevr][5] ;
  input [1:0]\diagnosticBus[sevr][4] ;
  input [1:0]\diagnosticBus[sevr][3] ;
  input [1:0]\diagnosticBus[sevr][2] ;
  input [1:0]\diagnosticBus[sevr][1] ;
  input [1:0]\diagnosticBus[sevr][0] ;
  input [31:0]\diagnosticBus[fixed] ;
  input [31:0]\diagnosticBus[mpsIgnore] ;
  input [15:0]\diagnosticBus[timingMessage][version] ;
  input [63:0]\diagnosticBus[timingMessage][pulseId] ;
  input [63:0]\diagnosticBus[timingMessage][timeStamp] ;
  input [9:0]\diagnosticBus[timingMessage][fixedRates] ;
  input [5:0]\diagnosticBus[timingMessage][acRates] ;
  input [2:0]\diagnosticBus[timingMessage][acTimeSlot] ;
  input [11:0]\diagnosticBus[timingMessage][acTimeSlotPhase] ;
  input \diagnosticBus[timingMessage][resync] ;
  input [31:0]\diagnosticBus[timingMessage][beamRequest] ;
  input [15:0]\diagnosticBus[timingMessage][beamEnergy][0] ;
  input [15:0]\diagnosticBus[timingMessage][beamEnergy][1] ;
  input [15:0]\diagnosticBus[timingMessage][beamEnergy][2] ;
  input [15:0]\diagnosticBus[timingMessage][beamEnergy][3] ;
  input [15:0]\diagnosticBus[timingMessage][photonWavelen][0] ;
  input [15:0]\diagnosticBus[timingMessage][photonWavelen][1] ;
  input \diagnosticBus[timingMessage][syncStatus] ;
  input \diagnosticBus[timingMessage][mpsValid] ;
  input [0:0]\diagnosticBus[timingMessage][bcsFault] ;
  input [15:0]\diagnosticBus[timingMessage][mpsLimit] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][0] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][1] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][2] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][3] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][4] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][5] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][6] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][7] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][8] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][9] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][10] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][11] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][12] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][13] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][14] ;
  input [3:0]\diagnosticBus[timingMessage][mpsClass][15] ;
  input [63:0]\diagnosticBus[timingMessage][bsaInit] ;
  input [63:0]\diagnosticBus[timingMessage][bsaActive] ;
  input [63:0]\diagnosticBus[timingMessage][bsaAvgDone] ;
  input [63:0]\diagnosticBus[timingMessage][bsaDone] ;
  input [15:0]\diagnosticBus[timingMessage][control][0] ;
  input [15:0]\diagnosticBus[timingMessage][control][1] ;
  input [15:0]\diagnosticBus[timingMessage][control][2] ;
  input [15:0]\diagnosticBus[timingMessage][control][3] ;
  input [15:0]\diagnosticBus[timingMessage][control][4] ;
  input [15:0]\diagnosticBus[timingMessage][control][5] ;
  input [15:0]\diagnosticBus[timingMessage][control][6] ;
  input [15:0]\diagnosticBus[timingMessage][control][7] ;
  input [15:0]\diagnosticBus[timingMessage][control][8] ;
  input [15:0]\diagnosticBus[timingMessage][control][9] ;
  input [15:0]\diagnosticBus[timingMessage][control][10] ;
  input [15:0]\diagnosticBus[timingMessage][control][11] ;
  input [15:0]\diagnosticBus[timingMessage][control][12] ;
  input [15:0]\diagnosticBus[timingMessage][control][13] ;
  input [15:0]\diagnosticBus[timingMessage][control][14] ;
  input [15:0]\diagnosticBus[timingMessage][control][15] ;
  input [15:0]\diagnosticBus[timingMessage][control][16] ;
  input [15:0]\diagnosticBus[timingMessage][control][17] ;
  output waveformClk;
  output waveformRst;
  input \obAppWaveformMasters[1][3][tValid] ;
  input [127:0]\obAppWaveformMasters[1][3][tData] ;
  input [15:0]\obAppWaveformMasters[1][3][tStrb] ;
  input [15:0]\obAppWaveformMasters[1][3][tKeep] ;
  input \obAppWaveformMasters[1][3][tLast] ;
  input [7:0]\obAppWaveformMasters[1][3][tDest] ;
  input [7:0]\obAppWaveformMasters[1][3][tId] ;
  input [127:0]\obAppWaveformMasters[1][3][tUser] ;
  input \obAppWaveformMasters[1][2][tValid] ;
  input [127:0]\obAppWaveformMasters[1][2][tData] ;
  input [15:0]\obAppWaveformMasters[1][2][tStrb] ;
  input [15:0]\obAppWaveformMasters[1][2][tKeep] ;
  input \obAppWaveformMasters[1][2][tLast] ;
  input [7:0]\obAppWaveformMasters[1][2][tDest] ;
  input [7:0]\obAppWaveformMasters[1][2][tId] ;
  input [127:0]\obAppWaveformMasters[1][2][tUser] ;
  input \obAppWaveformMasters[1][1][tValid] ;
  input [127:0]\obAppWaveformMasters[1][1][tData] ;
  input [15:0]\obAppWaveformMasters[1][1][tStrb] ;
  input [15:0]\obAppWaveformMasters[1][1][tKeep] ;
  input \obAppWaveformMasters[1][1][tLast] ;
  input [7:0]\obAppWaveformMasters[1][1][tDest] ;
  input [7:0]\obAppWaveformMasters[1][1][tId] ;
  input [127:0]\obAppWaveformMasters[1][1][tUser] ;
  input \obAppWaveformMasters[1][0][tValid] ;
  input [127:0]\obAppWaveformMasters[1][0][tData] ;
  input [15:0]\obAppWaveformMasters[1][0][tStrb] ;
  input [15:0]\obAppWaveformMasters[1][0][tKeep] ;
  input \obAppWaveformMasters[1][0][tLast] ;
  input [7:0]\obAppWaveformMasters[1][0][tDest] ;
  input [7:0]\obAppWaveformMasters[1][0][tId] ;
  input [127:0]\obAppWaveformMasters[1][0][tUser] ;
  input \obAppWaveformMasters[0][3][tValid] ;
  input [127:0]\obAppWaveformMasters[0][3][tData] ;
  input [15:0]\obAppWaveformMasters[0][3][tStrb] ;
  input [15:0]\obAppWaveformMasters[0][3][tKeep] ;
  input \obAppWaveformMasters[0][3][tLast] ;
  input [7:0]\obAppWaveformMasters[0][3][tDest] ;
  input [7:0]\obAppWaveformMasters[0][3][tId] ;
  input [127:0]\obAppWaveformMasters[0][3][tUser] ;
  input \obAppWaveformMasters[0][2][tValid] ;
  input [127:0]\obAppWaveformMasters[0][2][tData] ;
  input [15:0]\obAppWaveformMasters[0][2][tStrb] ;
  input [15:0]\obAppWaveformMasters[0][2][tKeep] ;
  input \obAppWaveformMasters[0][2][tLast] ;
  input [7:0]\obAppWaveformMasters[0][2][tDest] ;
  input [7:0]\obAppWaveformMasters[0][2][tId] ;
  input [127:0]\obAppWaveformMasters[0][2][tUser] ;
  input \obAppWaveformMasters[0][1][tValid] ;
  input [127:0]\obAppWaveformMasters[0][1][tData] ;
  input [15:0]\obAppWaveformMasters[0][1][tStrb] ;
  input [15:0]\obAppWaveformMasters[0][1][tKeep] ;
  input \obAppWaveformMasters[0][1][tLast] ;
  input [7:0]\obAppWaveformMasters[0][1][tDest] ;
  input [7:0]\obAppWaveformMasters[0][1][tId] ;
  input [127:0]\obAppWaveformMasters[0][1][tUser] ;
  input \obAppWaveformMasters[0][0][tValid] ;
  input [127:0]\obAppWaveformMasters[0][0][tData] ;
  input [15:0]\obAppWaveformMasters[0][0][tStrb] ;
  input [15:0]\obAppWaveformMasters[0][0][tKeep] ;
  input \obAppWaveformMasters[0][0][tLast] ;
  input [7:0]\obAppWaveformMasters[0][0][tDest] ;
  input [7:0]\obAppWaveformMasters[0][0][tId] ;
  input [127:0]\obAppWaveformMasters[0][0][tUser] ;
  output \obAppWaveformSlaves[1][3][slave][tReady] ;
  output \obAppWaveformSlaves[1][3][ctrl][pause] ;
  output \obAppWaveformSlaves[1][3][ctrl][overflow] ;
  output \obAppWaveformSlaves[1][3][ctrl][idle] ;
  output \obAppWaveformSlaves[1][2][slave][tReady] ;
  output \obAppWaveformSlaves[1][2][ctrl][pause] ;
  output \obAppWaveformSlaves[1][2][ctrl][overflow] ;
  output \obAppWaveformSlaves[1][2][ctrl][idle] ;
  output \obAppWaveformSlaves[1][1][slave][tReady] ;
  output \obAppWaveformSlaves[1][1][ctrl][pause] ;
  output \obAppWaveformSlaves[1][1][ctrl][overflow] ;
  output \obAppWaveformSlaves[1][1][ctrl][idle] ;
  output \obAppWaveformSlaves[1][0][slave][tReady] ;
  output \obAppWaveformSlaves[1][0][ctrl][pause] ;
  output \obAppWaveformSlaves[1][0][ctrl][overflow] ;
  output \obAppWaveformSlaves[1][0][ctrl][idle] ;
  output \obAppWaveformSlaves[0][3][slave][tReady] ;
  output \obAppWaveformSlaves[0][3][ctrl][pause] ;
  output \obAppWaveformSlaves[0][3][ctrl][overflow] ;
  output \obAppWaveformSlaves[0][3][ctrl][idle] ;
  output \obAppWaveformSlaves[0][2][slave][tReady] ;
  output \obAppWaveformSlaves[0][2][ctrl][pause] ;
  output \obAppWaveformSlaves[0][2][ctrl][overflow] ;
  output \obAppWaveformSlaves[0][2][ctrl][idle] ;
  output \obAppWaveformSlaves[0][1][slave][tReady] ;
  output \obAppWaveformSlaves[0][1][ctrl][pause] ;
  output \obAppWaveformSlaves[0][1][ctrl][overflow] ;
  output \obAppWaveformSlaves[0][1][ctrl][idle] ;
  output \obAppWaveformSlaves[0][0][slave][tReady] ;
  output \obAppWaveformSlaves[0][0][ctrl][pause] ;
  output \obAppWaveformSlaves[0][0][ctrl][overflow] ;
  output \obAppWaveformSlaves[0][0][ctrl][idle] ;
  output \ibAppWaveformMasters[1][3][tValid] ;
  output [127:0]\ibAppWaveformMasters[1][3][tData] ;
  output [15:0]\ibAppWaveformMasters[1][3][tStrb] ;
  output [15:0]\ibAppWaveformMasters[1][3][tKeep] ;
  output \ibAppWaveformMasters[1][3][tLast] ;
  output [7:0]\ibAppWaveformMasters[1][3][tDest] ;
  output [7:0]\ibAppWaveformMasters[1][3][tId] ;
  output [127:0]\ibAppWaveformMasters[1][3][tUser] ;
  output \ibAppWaveformMasters[1][2][tValid] ;
  output [127:0]\ibAppWaveformMasters[1][2][tData] ;
  output [15:0]\ibAppWaveformMasters[1][2][tStrb] ;
  output [15:0]\ibAppWaveformMasters[1][2][tKeep] ;
  output \ibAppWaveformMasters[1][2][tLast] ;
  output [7:0]\ibAppWaveformMasters[1][2][tDest] ;
  output [7:0]\ibAppWaveformMasters[1][2][tId] ;
  output [127:0]\ibAppWaveformMasters[1][2][tUser] ;
  output \ibAppWaveformMasters[1][1][tValid] ;
  output [127:0]\ibAppWaveformMasters[1][1][tData] ;
  output [15:0]\ibAppWaveformMasters[1][1][tStrb] ;
  output [15:0]\ibAppWaveformMasters[1][1][tKeep] ;
  output \ibAppWaveformMasters[1][1][tLast] ;
  output [7:0]\ibAppWaveformMasters[1][1][tDest] ;
  output [7:0]\ibAppWaveformMasters[1][1][tId] ;
  output [127:0]\ibAppWaveformMasters[1][1][tUser] ;
  output \ibAppWaveformMasters[1][0][tValid] ;
  output [127:0]\ibAppWaveformMasters[1][0][tData] ;
  output [15:0]\ibAppWaveformMasters[1][0][tStrb] ;
  output [15:0]\ibAppWaveformMasters[1][0][tKeep] ;
  output \ibAppWaveformMasters[1][0][tLast] ;
  output [7:0]\ibAppWaveformMasters[1][0][tDest] ;
  output [7:0]\ibAppWaveformMasters[1][0][tId] ;
  output [127:0]\ibAppWaveformMasters[1][0][tUser] ;
  output \ibAppWaveformMasters[0][3][tValid] ;
  output [127:0]\ibAppWaveformMasters[0][3][tData] ;
  output [15:0]\ibAppWaveformMasters[0][3][tStrb] ;
  output [15:0]\ibAppWaveformMasters[0][3][tKeep] ;
  output \ibAppWaveformMasters[0][3][tLast] ;
  output [7:0]\ibAppWaveformMasters[0][3][tDest] ;
  output [7:0]\ibAppWaveformMasters[0][3][tId] ;
  output [127:0]\ibAppWaveformMasters[0][3][tUser] ;
  output \ibAppWaveformMasters[0][2][tValid] ;
  output [127:0]\ibAppWaveformMasters[0][2][tData] ;
  output [15:0]\ibAppWaveformMasters[0][2][tStrb] ;
  output [15:0]\ibAppWaveformMasters[0][2][tKeep] ;
  output \ibAppWaveformMasters[0][2][tLast] ;
  output [7:0]\ibAppWaveformMasters[0][2][tDest] ;
  output [7:0]\ibAppWaveformMasters[0][2][tId] ;
  output [127:0]\ibAppWaveformMasters[0][2][tUser] ;
  output \ibAppWaveformMasters[0][1][tValid] ;
  output [127:0]\ibAppWaveformMasters[0][1][tData] ;
  output [15:0]\ibAppWaveformMasters[0][1][tStrb] ;
  output [15:0]\ibAppWaveformMasters[0][1][tKeep] ;
  output \ibAppWaveformMasters[0][1][tLast] ;
  output [7:0]\ibAppWaveformMasters[0][1][tDest] ;
  output [7:0]\ibAppWaveformMasters[0][1][tId] ;
  output [127:0]\ibAppWaveformMasters[0][1][tUser] ;
  output \ibAppWaveformMasters[0][0][tValid] ;
  output [127:0]\ibAppWaveformMasters[0][0][tData] ;
  output [15:0]\ibAppWaveformMasters[0][0][tStrb] ;
  output [15:0]\ibAppWaveformMasters[0][0][tKeep] ;
  output \ibAppWaveformMasters[0][0][tLast] ;
  output [7:0]\ibAppWaveformMasters[0][0][tDest] ;
  output [7:0]\ibAppWaveformMasters[0][0][tId] ;
  output [127:0]\ibAppWaveformMasters[0][0][tUser] ;
  input \ibAppWaveformSlaves[1][3][slave][tReady] ;
  input \ibAppWaveformSlaves[1][3][ctrl][pause] ;
  input \ibAppWaveformSlaves[1][3][ctrl][overflow] ;
  input \ibAppWaveformSlaves[1][3][ctrl][idle] ;
  input \ibAppWaveformSlaves[1][2][slave][tReady] ;
  input \ibAppWaveformSlaves[1][2][ctrl][pause] ;
  input \ibAppWaveformSlaves[1][2][ctrl][overflow] ;
  input \ibAppWaveformSlaves[1][2][ctrl][idle] ;
  input \ibAppWaveformSlaves[1][1][slave][tReady] ;
  input \ibAppWaveformSlaves[1][1][ctrl][pause] ;
  input \ibAppWaveformSlaves[1][1][ctrl][overflow] ;
  input \ibAppWaveformSlaves[1][1][ctrl][idle] ;
  input \ibAppWaveformSlaves[1][0][slave][tReady] ;
  input \ibAppWaveformSlaves[1][0][ctrl][pause] ;
  input \ibAppWaveformSlaves[1][0][ctrl][overflow] ;
  input \ibAppWaveformSlaves[1][0][ctrl][idle] ;
  input \ibAppWaveformSlaves[0][3][slave][tReady] ;
  input \ibAppWaveformSlaves[0][3][ctrl][pause] ;
  input \ibAppWaveformSlaves[0][3][ctrl][overflow] ;
  input \ibAppWaveformSlaves[0][3][ctrl][idle] ;
  input \ibAppWaveformSlaves[0][2][slave][tReady] ;
  input \ibAppWaveformSlaves[0][2][ctrl][pause] ;
  input \ibAppWaveformSlaves[0][2][ctrl][overflow] ;
  input \ibAppWaveformSlaves[0][2][ctrl][idle] ;
  input \ibAppWaveformSlaves[0][1][slave][tReady] ;
  input \ibAppWaveformSlaves[0][1][ctrl][pause] ;
  input \ibAppWaveformSlaves[0][1][ctrl][overflow] ;
  input \ibAppWaveformSlaves[0][1][ctrl][idle] ;
  input \ibAppWaveformSlaves[0][0][slave][tReady] ;
  input \ibAppWaveformSlaves[0][0][ctrl][pause] ;
  input \ibAppWaveformSlaves[0][0][ctrl][overflow] ;
  input \ibAppWaveformSlaves[0][0][ctrl][idle] ;
  input \obBpMsgClientMaster[tValid] ;
  input [127:0]\obBpMsgClientMaster[tData] ;
  input [15:0]\obBpMsgClientMaster[tStrb] ;
  input [15:0]\obBpMsgClientMaster[tKeep] ;
  input \obBpMsgClientMaster[tLast] ;
  input [7:0]\obBpMsgClientMaster[tDest] ;
  input [7:0]\obBpMsgClientMaster[tId] ;
  input [127:0]\obBpMsgClientMaster[tUser] ;
  output \obBpMsgClientSlave[tReady] ;
  output \ibBpMsgClientMaster[tValid] ;
  output [127:0]\ibBpMsgClientMaster[tData] ;
  output [15:0]\ibBpMsgClientMaster[tStrb] ;
  output [15:0]\ibBpMsgClientMaster[tKeep] ;
  output \ibBpMsgClientMaster[tLast] ;
  output [7:0]\ibBpMsgClientMaster[tDest] ;
  output [7:0]\ibBpMsgClientMaster[tId] ;
  output [127:0]\ibBpMsgClientMaster[tUser] ;
  input \ibBpMsgClientSlave[tReady] ;
  input \obBpMsgServerMaster[tValid] ;
  input [127:0]\obBpMsgServerMaster[tData] ;
  input [15:0]\obBpMsgServerMaster[tStrb] ;
  input [15:0]\obBpMsgServerMaster[tKeep] ;
  input \obBpMsgServerMaster[tLast] ;
  input [7:0]\obBpMsgServerMaster[tDest] ;
  input [7:0]\obBpMsgServerMaster[tId] ;
  input [127:0]\obBpMsgServerMaster[tUser] ;
  output \obBpMsgServerSlave[tReady] ;
  output \ibBpMsgServerMaster[tValid] ;
  output [127:0]\ibBpMsgServerMaster[tData] ;
  output [15:0]\ibBpMsgServerMaster[tStrb] ;
  output [15:0]\ibBpMsgServerMaster[tKeep] ;
  output \ibBpMsgServerMaster[tLast] ;
  output [7:0]\ibBpMsgServerMaster[tDest] ;
  output [7:0]\ibBpMsgServerMaster[tId] ;
  output [127:0]\ibBpMsgServerMaster[tUser] ;
  input \ibBpMsgServerSlave[tReady] ;
  input \obAppDebugMaster[tValid] ;
  input [127:0]\obAppDebugMaster[tData] ;
  input [15:0]\obAppDebugMaster[tStrb] ;
  input [15:0]\obAppDebugMaster[tKeep] ;
  input \obAppDebugMaster[tLast] ;
  input [7:0]\obAppDebugMaster[tDest] ;
  input [7:0]\obAppDebugMaster[tId] ;
  input [127:0]\obAppDebugMaster[tUser] ;
  output \obAppDebugSlave[tReady] ;
  output \ibAppDebugMaster[tValid] ;
  output [127:0]\ibAppDebugMaster[tData] ;
  output [15:0]\ibAppDebugMaster[tStrb] ;
  output [15:0]\ibAppDebugMaster[tKeep] ;
  output \ibAppDebugMaster[tLast] ;
  output [7:0]\ibAppDebugMaster[tDest] ;
  output [7:0]\ibAppDebugMaster[tId] ;
  output [127:0]\ibAppDebugMaster[tUser] ;
  input \ibAppDebugSlave[tReady] ;
  output recTimingClk;
  output recTimingRst;
  output ref156MHzClk;
  output ref156MHzRst;
  output gthFabClk;
  output [31:0]\axilReadMasters[1][araddr] ;
  output [2:0]\axilReadMasters[1][arprot] ;
  output \axilReadMasters[1][arvalid] ;
  output \axilReadMasters[1][rready] ;
  output [31:0]\axilReadMasters[0][araddr] ;
  output [2:0]\axilReadMasters[0][arprot] ;
  output \axilReadMasters[0][arvalid] ;
  output \axilReadMasters[0][rready] ;
  input \axilReadSlaves[1][arready] ;
  input [31:0]\axilReadSlaves[1][rdata] ;
  input [1:0]\axilReadSlaves[1][rresp] ;
  input \axilReadSlaves[1][rvalid] ;
  input \axilReadSlaves[0][arready] ;
  input [31:0]\axilReadSlaves[0][rdata] ;
  input [1:0]\axilReadSlaves[0][rresp] ;
  input \axilReadSlaves[0][rvalid] ;
  output [31:0]\axilWriteMasters[1][awaddr] ;
  output [2:0]\axilWriteMasters[1][awprot] ;
  output \axilWriteMasters[1][awvalid] ;
  output [31:0]\axilWriteMasters[1][wdata] ;
  output [3:0]\axilWriteMasters[1][wstrb] ;
  output \axilWriteMasters[1][wvalid] ;
  output \axilWriteMasters[1][bready] ;
  output [31:0]\axilWriteMasters[0][awaddr] ;
  output [2:0]\axilWriteMasters[0][awprot] ;
  output \axilWriteMasters[0][awvalid] ;
  output [31:0]\axilWriteMasters[0][wdata] ;
  output [3:0]\axilWriteMasters[0][wstrb] ;
  output \axilWriteMasters[0][wvalid] ;
  output \axilWriteMasters[0][bready] ;
  input \axilWriteSlaves[1][awready] ;
  input \axilWriteSlaves[1][wready] ;
  input [1:0]\axilWriteSlaves[1][bresp] ;
  input \axilWriteSlaves[1][bvalid] ;
  input \axilWriteSlaves[0][awready] ;
  input \axilWriteSlaves[0][wready] ;
  input [1:0]\axilWriteSlaves[0][bresp] ;
  input \axilWriteSlaves[0][bvalid] ;
  input [31:0]\ethReadMaster[araddr] ;
  input [2:0]\ethReadMaster[arprot] ;
  input \ethReadMaster[arvalid] ;
  input \ethReadMaster[rready] ;
  output \ethReadSlave[arready] ;
  output [31:0]\ethReadSlave[rdata] ;
  output [1:0]\ethReadSlave[rresp] ;
  output \ethReadSlave[rvalid] ;
  input [31:0]\ethWriteMaster[awaddr] ;
  input [2:0]\ethWriteMaster[awprot] ;
  input \ethWriteMaster[awvalid] ;
  input [31:0]\ethWriteMaster[wdata] ;
  input [3:0]\ethWriteMaster[wstrb] ;
  input \ethWriteMaster[wvalid] ;
  input \ethWriteMaster[bready] ;
  output \ethWriteSlave[awready] ;
  output \ethWriteSlave[wready] ;
  output [1:0]\ethWriteSlave[bresp] ;
  output \ethWriteSlave[bvalid] ;
  input [47:0]localMac;
  input [31:0]localIp;
  output ethLinkUp;
  input [31:0]\timingReadMaster[araddr] ;
  input [2:0]\timingReadMaster[arprot] ;
  input \timingReadMaster[arvalid] ;
  input \timingReadMaster[rready] ;
  output \timingReadSlave[arready] ;
  output [31:0]\timingReadSlave[rdata] ;
  output [1:0]\timingReadSlave[rresp] ;
  output \timingReadSlave[rvalid] ;
  input [31:0]\timingWriteMaster[awaddr] ;
  input [2:0]\timingWriteMaster[awprot] ;
  input \timingWriteMaster[awvalid] ;
  input [31:0]\timingWriteMaster[wdata] ;
  input [3:0]\timingWriteMaster[wstrb] ;
  input \timingWriteMaster[wvalid] ;
  input \timingWriteMaster[bready] ;
  output \timingWriteSlave[awready] ;
  output \timingWriteSlave[wready] ;
  output [1:0]\timingWriteSlave[bresp] ;
  output \timingWriteSlave[bvalid] ;
  input [31:0]\bsaReadMaster[araddr] ;
  input [2:0]\bsaReadMaster[arprot] ;
  input \bsaReadMaster[arvalid] ;
  input \bsaReadMaster[rready] ;
  output \bsaReadSlave[arready] ;
  output [31:0]\bsaReadSlave[rdata] ;
  output [1:0]\bsaReadSlave[rresp] ;
  output \bsaReadSlave[rvalid] ;
  input [31:0]\bsaWriteMaster[awaddr] ;
  input [2:0]\bsaWriteMaster[awprot] ;
  input \bsaWriteMaster[awvalid] ;
  input [31:0]\bsaWriteMaster[wdata] ;
  input [3:0]\bsaWriteMaster[wstrb] ;
  input \bsaWriteMaster[wvalid] ;
  input \bsaWriteMaster[bready] ;
  output \bsaWriteSlave[awready] ;
  output \bsaWriteSlave[wready] ;
  output [1:0]\bsaWriteSlave[bresp] ;
  output \bsaWriteSlave[bvalid] ;
  input [31:0]\ddrReadMaster[araddr] ;
  input [2:0]\ddrReadMaster[arprot] ;
  input \ddrReadMaster[arvalid] ;
  input \ddrReadMaster[rready] ;
  output \ddrReadSlave[arready] ;
  output [31:0]\ddrReadSlave[rdata] ;
  output [1:0]\ddrReadSlave[rresp] ;
  output \ddrReadSlave[rvalid] ;
  input [31:0]\ddrWriteMaster[awaddr] ;
  input [2:0]\ddrWriteMaster[awprot] ;
  input \ddrWriteMaster[awvalid] ;
  input [31:0]\ddrWriteMaster[wdata] ;
  input [3:0]\ddrWriteMaster[wstrb] ;
  input \ddrWriteMaster[wvalid] ;
  input \ddrWriteMaster[bready] ;
  output \ddrWriteSlave[awready] ;
  output \ddrWriteSlave[wready] ;
  output [1:0]\ddrWriteSlave[bresp] ;
  output \ddrWriteSlave[bvalid] ;
  output ddrMemReady;
  output ddrMemError;
  input fabClkP;
  input fabClkN;
  input [3:0]ethRxP;
  input [3:0]ethRxN;
  output [3:0]ethTxP;
  output [3:0]ethTxN;
  input ethClkP;
  input ethClkN;
  input timingRxP;
  input timingRxN;
  output timingTxP;
  output timingTxN;
  input timingRefClkInP;
  input timingRefClkInN;
  output timingRecClkOutP;
  output timingRecClkOutN;
  output timingClkSel;
  output enAuxPwrL;
  input ddrClkP;
  input ddrClkN;
  output [7:0]ddrDm;
  inout [7:0]ddrDqsP;
  inout [7:0]ddrDqsN;
  inout [63:0]ddrDq;
  output [15:0]ddrA;
  output [2:0]ddrBa;
  output [1:0]ddrCsL;
  output [1:0]ddrOdt;
  output [1:0]ddrCke;
  output [1:0]ddrCkP;
  output [1:0]ddrCkN;
  output ddrWeL;
  output ddrRasL;
  output ddrCasL;
  output ddrRstL;
  input ddrAlertL;
  input ddrPg;
  output ddrPwrEnL;
endmodule
