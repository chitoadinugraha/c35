import 'package:flutter/foundation.dart';

Future<void> Function(int deviceIid)? _disposeHook;

/// Registered when [RemoteSession] is available (native startup or web deferred load).
void registerRemoteSessionDispose(Future<void> Function(int deviceIid) dispose) {
  _disposeHook = dispose;
}

@visibleForTesting
void resetRemoteSessionDisposeHook() {
  _disposeHook = null;
}

Future<void> remoteSessionDisposeForDevice(int deviceIid) async {
  final hook = _disposeHook;
  if (hook != null) await hook(deviceIid);
}
