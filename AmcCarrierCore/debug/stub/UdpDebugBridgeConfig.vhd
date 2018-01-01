configuration UdpDebugBridge of UdpDebugBridgeWrapper is
   for UdpDebugBridgeWrapperImpl
      for all : AxisDebugBridge
         use entity work.AxisDebugBridge(AxisDebugBridgeStub);
      end for;
   end for;
end configuration UdpDebugBridge;
