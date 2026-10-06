import 'package:alienai_c35/c/pb/c35/device.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

/// Latest `DevicePresencePush.meta_json` per device (NATS app lane heartbeats).
class DevicePresenceCache extends ChangeNotifier {
  DevicePresenceCache._();
  static final instance = DevicePresenceCache._();

  final _metaByDevice = <String, String>{};

  void apply(DevicePresencePush push) {
    final id = push.deviceIid.toString();
    if (_metaByDevice[id] == push.metaJson) return;
    _metaByDevice[id] = push.metaJson;
    notifyListeners();
  }

  /// Replace cached presence from a fresh identity list (manual recheck).
  void metasPut(Map<String, String> metaByDeviceId) {
    var changed = false;
    for (final e in metaByDeviceId.entries) {
      if (_metaByDevice[e.key] == e.value) continue;
      _metaByDevice[e.key] = e.value;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  String metaFor(Int64 deviceIid, String fallbackMetaJson) =>
      _metaByDevice[deviceIid.toString()] ?? fallbackMetaJson;
}
