import 'package:alienai_c35/c/remote/webrtc_module.dart' deferred as webrtc;

bool _webrtcModuleReady = false;

Future<void> ensureWebRtcModule() async {
  if (_webrtcModuleReady) return;
  await webrtc.loadLibrary();
  webrtc.registerRemoteSessionBridge();
  _webrtcModuleReady = true;
}
