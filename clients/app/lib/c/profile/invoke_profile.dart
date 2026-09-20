import 'dart:convert';
import 'dart:typed_data';

class ProfilePutRes {
  const ProfilePutRes({this.name = '', this.avatarUrl = '', this.handle = '', this.authEmail = ''});
  final String name;
  final String avatarUrl;
  final String handle;
  final String authEmail;
}

class ProfileAlienIdCheckRes {
  const ProfileAlienIdCheckRes({this.available = false, this.message = ''});
  final bool available;
  final String message;
}

class InvokeProfileRes {
  const InvokeProfileRes({this.reqId = '', this.statusCode = 0, this.errorMessage = '', this.profilePut, this.alienIdCheck});
  final String reqId;
  final int statusCode;
  final String errorMessage;
  final ProfilePutRes? profilePut;
  final ProfileAlienIdCheckRes? alienIdCheck;
  bool get ok => statusCode == 0 || statusCode == 200;
}

Uint8List invokeProfilePutBytes({required String reqId, required int uid, String? name, String? avatarUrl, String? handle, String? authEmail}) {
  final inner = BytesBuilder();
  if (name != null) _string(inner, 1, name);
  if (avatarUrl != null) _string(inner, 2, avatarUrl);
  if (handle != null) _string(inner, 3, handle);
  if (authEmail != null) _string(inner, 4, authEmail);
  final out = BytesBuilder();
  _string(out, 1, reqId);
  _int64(out, 2, uid);
  _bytes(out, 116, inner.takeBytes());
  return Uint8List.fromList(out.takeBytes());
}

Uint8List invokeAlienIdCheckBytes({required String reqId, required int uid, required String alienId}) {
  final inner = BytesBuilder();
  _string(inner, 1, alienId);
  final out = BytesBuilder();
  _string(out, 1, reqId);
  _int64(out, 2, uid);
  _bytes(out, 117, inner.takeBytes());
  return Uint8List.fromList(out.takeBytes());
}

InvokeProfileRes invokeProfileResParse(List<int> raw) {
  final r = _PbReader(raw);
  var reqId = '';
  var statusCode = 0;
  var errorMessage = '';
  ProfilePutRes? profilePut;
  ProfileAlienIdCheckRes? alienIdCheck;
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 2 && field == 1) {
      reqId = r.string();
    } else if (wire == 0 && field == 2) {
      statusCode = r.varint();
    } else if (wire == 2 && field == 3) {
      errorMessage = r.string();
    } else if (wire == 2 && field == 116) {
      profilePut = _profilePutParse(r.lenBytes());
    } else if (wire == 2 && field == 117) {
      alienIdCheck = _alienIdCheckParse(r.lenBytes());
    } else {
      r.skip(wire);
    }
  }
  return InvokeProfileRes(reqId: reqId, statusCode: statusCode, errorMessage: errorMessage, profilePut: profilePut, alienIdCheck: alienIdCheck);
}

ProfilePutRes _profilePutParse(List<int> raw) {
  final r = _PbReader(raw);
  var name = '';
  var avatarUrl = '';
  var handle = '';
  var authEmail = '';
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire != 2) {
      r.skip(wire);
      continue;
    }
    switch (field) {
      case 1:
        name = r.string();
      case 2:
        avatarUrl = r.string();
      case 3:
        handle = r.string();
      case 4:
        authEmail = r.string();
      default:
        r.skip(wire);
    }
  }
  return ProfilePutRes(name: name, avatarUrl: avatarUrl, handle: handle, authEmail: authEmail);
}

ProfileAlienIdCheckRes _alienIdCheckParse(List<int> raw) {
  final r = _PbReader(raw);
  var available = false;
  var message = '';
  while (r.remaining) {
    final (field, wire) = r.tag();
    if (wire == 0 && field == 1) {
      available = r.varint() != 0;
    } else if (wire == 2 && field == 2) {
      message = r.string();
    } else {
      r.skip(wire);
    }
  }
  return ProfileAlienIdCheckRes(available: available, message: message);
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
