import 'package:alienai_c35/c/share/share_inbound_listen.dart';
import 'package:alienai_c35/c/share/share_inbound_payload.dart';
import 'package:alienai_c35/c/share/share_to_home_bridge.dart';

/// Route OS share into Home composer when the shell is ready.
void presentShareToHome([ShareInboundPayload? payload]) {
  final p = payload ?? ShareInbound.instance.pending;
  if (p == null || p.isEmpty) return;
  if (!ShareToHomeBridge.instance.homeReady) return;
  ShareInbound.instance.clearPending();
  ShareToHomeBridge.instance.deliver(p);
}

void shareInboundBindPresenter() {
  ShareInbound.instance.onPayload = presentShareToHome;
  presentShareToHome();
}
