import 'package:alienai_c35/c/share/share_inbound_payload.dart';
import 'package:flutter/foundation.dart';

/// Queues inbound share payloads until [PageAIHome] consumes them.
class ShareToHomeBridge extends ChangeNotifier {
  ShareToHomeBridge._();
  static final instance = ShareToHomeBridge._();

  ShareInboundPayload? _queued;
  var _homeReady = false;

  bool get homeReady => _homeReady;

  void setHomeReady(bool ready) {
    if (_homeReady == ready) return;
    _homeReady = ready;
    if (ready && _queued != null) notifyListeners();
  }

  void deliver(ShareInboundPayload payload) {
    if (payload.isEmpty) return;
    _queued = payload;
    notifyListeners();
  }

  ShareInboundPayload? takeQueued() {
    final p = _queued;
    _queued = null;
    return p;
  }
}
