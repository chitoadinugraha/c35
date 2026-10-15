import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/session/session_busy_registry.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:flutter/foundation.dart';

ChatConn? _chatConn;
ChatStore? _chatStore;

/// Bind the signed-in Home shell so busy checks can see prompt state.
void appUpdateBusyBind({required ChatConn conn, required ChatStore store}) {
  _chatConn = conn;
  _chatStore = store;
}

@visibleForTesting
bool appUpdateUserBusyFromSignals({
  required bool promptBusy,
  required bool promptInFlight,
  required bool liveCallActive,
  required bool remoteControlActive,
}) =>
    promptBusy || promptInFlight || liveCallActive || remoteControlActive;

/// True when an automatic idle apply should wait (manual Restart stays allowed).
bool appUpdateUserBusy() {
  final store = _chatStore;
  final conn = _chatConn;
  return appUpdateUserBusyFromSignals(
    promptBusy: store?.promptBusy ?? false,
    promptInFlight: conn?.promptInFlight ?? false,
    liveCallActive: SessionBusyRegistry.liveCallActive,
    remoteControlActive: SessionBusyRegistry.remoteControlActive,
  );
}
