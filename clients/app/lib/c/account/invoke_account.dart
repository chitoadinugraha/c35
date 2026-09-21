import 'dart:convert';
import 'dart:typed_data';

class UserSettingsRes {
  const UserSettingsRes({this.hasPassword = false, this.hasPin = false, this.sessionUnlockMode = 'tap', this.activeClientId = '', this.isSessionLocked = false});
  final bool hasPassword;
  final bool hasPin;
  final String sessionUnlockMode;
  final String activeClientId;
  final bool isSessionLocked;
}

class AccountLiveConn {
  const AccountLiveConn({this.dv = '', this.clientId = '', this.platform = 0, this.label = '', this.live = false, this.osName = ''});
  final String dv;
  final String clientId;
  final int platform;
  final String label;
  final bool live;
  final String osName;
}

class SessionStatusRes {
  const SessionStatusRes({this.isLocked = false, this.unlockMode = 'tap', this.activeClientId = ''});
  final bool isLocked;
  final String unlockMode;
  final String activeClientId;
}

class InvokeAccountRes {
  const InvokeAccountRes({
    this.reqId = '',
    this.statusCode = 0,
    this.errorMessage = '',
    this.userSettings,
    this.unlockMode = '',
    this.sessionStatus,
    this.sessionUnlockOk = false,
    this.liveConns = const [],
    this.revoked = 0,
  });
  final String reqId;
  final int statusCode;
  final String errorMessage;
  final UserSettingsRes? userSettings;
  final String unlockMode;
  final SessionStatusRes? sessionStatus;
  final bool sessionUnlockOk;
  final List<AccountLiveConn> liveConns;
  final int revoked;
  bool get ok => statusCode == 0 || statusCode == 200;
}

Uint8List invokeUserSettingsBytes({required String reqId, required int uid}) => _req(reqId, uid, 118, const []);

Uint8List invokePasswordSetBytes({required String reqId, required int uid, required String currentPassword, required String newPassword}) {
  final inner = BytesBuilder();
  _string(inner, 1, currentPassword);
  _string(inner, 2, newPassword);
  return _req(reqId, uid, 119, inner.takeBytes());
}

Uint8List invokePinSetBytes({required String reqId, required int uid, String currentPin = '', required String newPin}) {
  final inner = BytesBuilder();
  _string(inner, 1, currentPin);
  _string(inner, 2, newPin);
  return _req(reqId, uid, 120, inner.takeBytes());
}

Uint8List invokeUnlockModePutBytes({required String reqId, required int uid, required String mode}) {
  final inner = BytesBuilder();
  _string(inner, 1, mode);
  return _req(reqId, uid, 121, inner.takeBytes());
}

Uint8List invokeSessionStatusBytes({required String reqId, required int uid, required String clientId}) {
  final inner = BytesBuilder();
  _string(inner, 1, clientId);
  return _req(reqId, uid, 122, inner.takeBytes());
}

Uint8List invokeSessionUnlockBytes({required String reqId, required int uid, required String clientId, String pin = ''}) {
  final inner = BytesBuilder();
  _string(inner, 1, clientId);
  _string(inner, 2, pin);
  return _req(reqId, uid, 123, inner.takeBytes());
}

Uint8List invokeLiveConnsBytes({required String reqId, required int uid, int targetUid = 0}) {
  final inner = BytesBuilder();
  if (targetUid != 0) _int64(inner, 1, targetUid);
  return _req(reqId, uid, 124, inner.takeBytes());
}

Uint8List invokeDeviceLabelPutBytes({required String reqId, required int uid, required String dv, required String labelUser}) {
  final inner = BytesBuilder();
  _string(inner, 1, dv);
  _string(inner, 2, labelUser);
  return _req(reqId, uid, 125, inner.takeBytes());
}

Uint8List invokeLiveConnRevokeBytes({required String reqId, required int uid, required String dv}) {
  final inner = BytesBuilder();
  _string(inner, 1, dv);
  return _req(reqId, uid, 141, inner.takeBytes());
}

Uint8List invokeLiveConnRevokeOthersBytes({required String reqId, required int uid, required String selfDv}) {
  final inner = BytesBuilder();
  _string(inner, 1, selfDv);
  return _req(reqId, uid, 142, inner.takeBytes());
}

InvokeAccountRes invokeAccountResParse(List<int> raw) {
  final r = _PbReader(raw);
  var reqId = '';
  var statusCode = 0;
  var errorMessage = '';
  UserSettingsRes? userSettings;
  var unlockMode = '';
  SessionStatusRes? sessionStatus;
  var sessionUnlockOk = false;
  var liveConns = const <AccountLiveConn>[];
  var revoked = 0;
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 2 && field == 1) {
      reqId = r.string();
    } else if (wire == 0 && field == 2) {
      statusCode = r.varint();
    } else if (wire == 2 && field == 3) {
      errorMessage = r.string();
    } else if (wire == 2 && field == 126) {
      userSettings = _userSettingsParse(r.lenBytes());
    } else if (wire == 2 && field == 129) {
      unlockMode = _unlockModeParse(r.lenBytes());
    } else if (wire == 2 && field == 130) {
      sessionStatus = _sessionStatusParse(r.lenBytes());
    } else if (wire == 2 && field == 131) {
      sessionUnlockOk = _okParse(r.lenBytes());
    } else if (wire == 2 && field == 132) {
      liveConns = _liveConnsParse(r.lenBytes());
    } else if (wire == 2 && field == 142) {
      revoked = _revokedParse(r.lenBytes());
    } else {
      r.skip(wire);
    }
  }
  return InvokeAccountRes(
    reqId: reqId,
    statusCode: statusCode,
    errorMessage: errorMessage,
    userSettings: userSettings,
    unlockMode: unlockMode,
    sessionStatus: sessionStatus,
    sessionUnlockOk: sessionUnlockOk,
    liveConns: liveConns,
    revoked: revoked,
  );
}

UserSettingsRes _userSettingsParse(List<int> raw) {
  final r = _PbReader(raw);
  var hasPassword = false, hasPin = false, isLocked = false;
  var mode = 'tap', active = '';
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 0 && field == 1) {
      hasPassword = r.varint() != 0;
    } else if (wire == 0 && field == 2) {
      hasPin = r.varint() != 0;
    } else if (wire == 2 && field == 3) {
      mode = r.string();
    } else if (wire == 2 && field == 4) {
      active = r.string();
    } else if (wire == 0 && field == 5) {
      isLocked = r.varint() != 0;
    } else {
      r.skip(wire);
    }
  }
  return UserSettingsRes(hasPassword: hasPassword, hasPin: hasPin, sessionUnlockMode: mode.isEmpty ? 'tap' : mode, activeClientId: active, isSessionLocked: isLocked);
}

String _unlockModeParse(List<int> raw) {
  final r = _PbReader(raw);
  var mode = '';
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 2 && field == 1) {
      mode = r.string();
    } else {
      r.skip(wire);
    }
  }
  return mode;
}

SessionStatusRes _sessionStatusParse(List<int> raw) {
  final r = _PbReader(raw);
  var locked = false, mode = 'tap', active = '';
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 0 && field == 1) {
      locked = r.varint() != 0;
    } else if (wire == 2 && field == 2) {
      mode = r.string();
    } else if (wire == 2 && field == 3) {
      active = r.string();
    } else {
      r.skip(wire);
    }
  }
  return SessionStatusRes(isLocked: locked, unlockMode: mode.isEmpty ? 'tap' : mode, activeClientId: active);
}

bool _okParse(List<int> raw) {
  final r = _PbReader(raw);
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 0 && field == 1) return r.varint() != 0;
    r.skip(wire);
  }
  return false;
}

List<AccountLiveConn> _liveConnsParse(List<int> raw) {
  final r = _PbReader(raw);
  final out = <AccountLiveConn>[];
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 2 && field == 1) {
      out.add(_liveConnParse(r.lenBytes()));
    } else {
      r.skip(wire);
    }
  }
  return out;
}

AccountLiveConn _liveConnParse(List<int> raw) {
  final r = _PbReader(raw);
  var dv = '', clientId = '', label = '', osName = '';
  var platform = 0, live = false;
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 2 && field == 1) {
      dv = r.string();
    } else if (wire == 2 && field == 2) {
      clientId = r.string();
    } else if (wire == 0 && field == 3) {
      platform = r.varint();
    } else if (wire == 2 && field == 4) {
      label = r.string();
    } else if (wire == 0 && field == 5) {
      live = r.varint() != 0;
    } else if (wire == 2 && field == 6) {
      osName = r.string();
    } else {
      r.skip(wire);
    }
  }
  return AccountLiveConn(dv: dv, clientId: clientId, platform: platform, label: label, live: live, osName: osName);
}

int _revokedParse(List<int> raw) {
  final r = _PbReader(raw);
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 0 && field == 1) return r.varint();
    r.skip(wire);
  }
  return 0;
}

Uint8List _req(String reqId, int uid, int field, List<int> inner) {
  final out = BytesBuilder();
  _string(out, 1, reqId);
  _int64(out, 2, uid);
  _bytes(out, field, inner);
  return Uint8List.fromList(out.takeBytes());
}

void _string(BytesBuilder b, int field, String v) => _bytes(b, field, utf8.encode(v));

void _bytes(BytesBuilder b, int field, List<int> v) {
  _tag(b, field, 2);
  _varint(b, v.length);
  b.add(v);
}

void _int64(BytesBuilder b, int field, int v) {
  _tag(b, field, 0);
  _varint(b, v);
}

void _tag(BytesBuilder b, int field, int wire) => _varint(b, (field << 3) | wire);

void _varint(BytesBuilder b, int value) {
  var v = value;
  while (v > 0x7f) {
    b.addByte((v & 0x7f) | 0x80);
    v >>= 7;
  }
  b.addByte(v);
}

class _PbReader {
  _PbReader(List<int> raw) : _data = raw;
  final List<int> _data;
  var _i = 0;

  bool get remaining => _i < _data.length;

  (int, int) tag() {
    final n = varint();
    return (n >> 3, n & 7);
  }

  int varint() {
    var result = 0;
    var shift = 0;
    while (true) {
      if (_i >= _data.length) throw const FormatException('truncated protobuf');
      final b = _data[_i++];
      result |= (b & 0x7f) << shift;
      if (b < 0x80) return result;
      shift += 7;
    }
  }

  List<int> lenBytes() {
    final n = varint();
    if (_i + n > _data.length) throw const FormatException('truncated protobuf');
    final slice = _data.sublist(_i, _i + n);
    _i += n;
    return slice;
  }

  String string() => utf8.decode(lenBytes());

  void skip(int wire) {
    switch (wire) {
      case 0:
        varint();
      case 1:
        _i += 8;
      case 2:
        lenBytes();
      case 5:
        _i += 4;
      default:
        throw FormatException('unknown protobuf wire $wire');
    }
  }
}
