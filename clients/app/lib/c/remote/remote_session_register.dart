import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/remote/remote_session_bridge.dart';

void registerRemoteSessionBridge() {
  registerRemoteSessionDispose(RemoteSession.dispose);
}
