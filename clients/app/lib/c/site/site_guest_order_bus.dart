import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/sync.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:flutter/foundation.dart';

class SiteGuestOrderEvent {
  const SiteGuestOrderEvent({
    required this.siteIid,
    required this.txId,
    required this.subjectName,
    required this.total,
  });

  final int siteIid;
  final int txId;
  final String subjectName;
  final int total;
}

/// Realtime guest storefront orders (`c35.user.{uid}.app.site_order` → WS `SyncPush.tx`).
class SiteGuestOrderBus extends ChangeNotifier {
  SiteGuestOrderEvent? _last;
  StreamSubscription<SyncPush>? _sub;
  ChatConn? _conn;

  SiteGuestOrderEvent? get last => _last;

  void attachOnce(ChatConn conn) {
    if (_conn == conn && _sub != null) return;
    unawaited(_sub?.cancel());
    _conn = conn;
    _sub = conn.onSyncPush.listen(_onSyncPush);
  }

  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
    _conn = null;
  }

  void _onSyncPush(SyncPush push) {
    if (!push.hasTx()) return;
    final tx = push.tx;
    if (tx.inputSource != TxInputSource.TX_INPUT_SOURCE_WEB) return;
    if (tx.siteIid.toInt() <= 0 || tx.txId.toInt() <= 0) return;
    _last = SiteGuestOrderEvent(
      siteIid: tx.siteIid.toInt(),
      txId: tx.txId.toInt(),
      subjectName: tx.subjectName.trim(),
      total: tx.total.toInt(),
    );
    notifyListeners();
  }
}

final siteGuestOrderBus = SiteGuestOrderBus();
