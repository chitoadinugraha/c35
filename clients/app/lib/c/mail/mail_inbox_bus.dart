import 'dart:async';

import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avatar-menu mail unread (all mailboxes) — from [ResSessionInit.nav], cached per uid.
class MailInboxBus extends ChangeNotifier {
  int _inboxCount = 0;
  bool _menuVisible = false;
  int _updatedTsMs = 0;

  int get inboxCount => _inboxCount;
  bool get menuVisible => _menuVisible;
  int get updatedTsMs => _updatedTsMs;

  /// Legacy alias — true when server says mail menu is available.
  bool get hasMailboxAccess => _menuVisible;

  static String unreadMenuLabel(int count) {
    if (count <= 0) return '';
    if (count > 9) return '9+';
    return '$count';
  }

  void applyFromNav(NavCounts nav) {
    _menuVisible = nav.mailMenuVisible;
    _setCount(nav.mailInboxUnread, tsMs: DateTime.now().millisecondsSinceEpoch);
  }

  void applyFromInit(int count, {bool menuVisible = true}) => applyFromNav(
        NavCounts(mailInboxUnread: count, mailMenuVisible: menuVisible),
      );

  void setMailboxAccess(bool value) {
    if (_menuVisible == value) return;
    _menuVisible = value;
    unawaited(_persist());
    notifyListeners();
  }

  void setCount(int count, {int? tsMs}) => _setCount(count, tsMs: tsMs ?? DateTime.now().millisecondsSinceEpoch);

  void _setCount(int count, {required int tsMs}) {
    final c = count < 0 ? 0 : count;
    if (_inboxCount == c && _updatedTsMs == tsMs) return;
    _inboxCount = c;
    _updatedTsMs = tsMs;
    unawaited(_persist());
    notifyListeners();
  }

  void bump() => setCount(_inboxCount + 1);

  void clear() {
    _inboxCount = 0;
    _menuVisible = false;
    _updatedTsMs = 0;
    unawaited(_persist());
    notifyListeners();
  }

  Future<void> restoreForSession() async {
    final uid = Session.instance.uid;
    if (uid <= 0) {
      clear();
      return;
    }
    final p = await SharedPreferences.getInstance();
    final cachedUid = p.getInt(_kUid) ?? 0;
    if (cachedUid != uid) {
      _inboxCount = 0;
      _menuVisible = false;
      _updatedTsMs = 0;
      notifyListeners();
      return;
    }
    _inboxCount = p.getInt(_kCount) ?? 0;
    _menuVisible = p.getBool(_kMenuVisible) ?? false;
    _updatedTsMs = p.getInt(_kUpdatedMs) ?? 0;
    notifyListeners();
  }

  Future<void> _persist() async {
    final uid = Session.instance.uid;
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kUid, uid);
    await p.setInt(_kCount, _inboxCount);
    await p.setBool(_kMenuVisible, _menuVisible);
    await p.setInt(_kUpdatedMs, _updatedTsMs);
  }
}

const _kUid = '${C35AppId.id}_mail_inbox_uid';
const _kCount = '${C35AppId.id}_mail_inbox_count';
const _kMenuVisible = '${C35AppId.id}_mail_menu_visible';
const _kUpdatedMs = '${C35AppId.id}_mail_inbox_updated_ms';

final mailInboxBus = MailInboxBus();
