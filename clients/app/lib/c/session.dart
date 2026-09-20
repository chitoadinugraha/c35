import 'dart:convert';

import 'package:alienai_c35/c/app_id.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sessionTick = ValueNotifier(0);

String sessionAuthToken() => Session.instance.token.trim();

List<String> sessionGlobalRolesParse(Object? raw) {
  if (raw is List) return raw.map((e) => '$e'.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
  if (raw is String && raw.isNotEmpty) {
    try {
      return sessionGlobalRolesParse(jsonDecode(raw));
    } catch (_) {}
  }
  return const [];
}

class Session {
  Session._();
  static final Session instance = Session._();

  String token = '';
  int uid = 0;
  String name = '';
  String handle = '';
  String pic = '';
  String email = '';
  List<String> globalRoles = const [];

  bool get signedIn => uid > 0 && token.isNotEmpty;
  bool get isRoot => globalRoles.contains('root');

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    uid = p.getInt(C35AppId.sessionUid) ?? 0;
    name = p.getString(C35AppId.sessionName) ?? '';
    handle = p.getString(C35AppId.sessionHandle) ?? '';
    pic = p.getString(C35AppId.sessionPic) ?? '';
    email = p.getString(C35AppId.sessionEmail) ?? '';
    token = p.getString(C35AppId.sessionToken) ?? '';
    globalRoles = sessionGlobalRolesParse(p.getString(C35AppId.sessionGlobalRoles));
    sessionTick.value++;
  }

  Future<void> put({
    required int uid,
    required String name,
    String handle = '',
    String pic = '',
    String? email,
    String token = '',
    List<String> globalRoles = const [],
  }) async {
    this.uid = uid;
    this.name = name;
    this.handle = handle;
    this.pic = pic;
    if (email != null) this.email = email;
    this.token = token;
    this.globalRoles = globalRoles;
    final p = await SharedPreferences.getInstance();
    await p.setInt(C35AppId.sessionUid, uid);
    await p.setString(C35AppId.sessionName, name);
    await p.setString(C35AppId.sessionHandle, handle);
    await p.setString(C35AppId.sessionPic, pic);
    await p.setString(C35AppId.sessionEmail, this.email);
    await p.setString(C35AppId.sessionToken, token);
    await p.setString(C35AppId.sessionGlobalRoles, jsonEncode(globalRoles));
    sessionTick.value++;
  }

  Future<void> clear({bool clearStored = true}) async {
    uid = 0;
    name = '';
    handle = '';
    pic = '';
    email = '';
    token = '';
    globalRoles = const [];
    if (clearStored) {
      final p = await SharedPreferences.getInstance();
      await p.remove(C35AppId.sessionUid);
      await p.remove(C35AppId.sessionName);
      await p.remove(C35AppId.sessionHandle);
      await p.remove(C35AppId.sessionPic);
      await p.remove(C35AppId.sessionEmail);
      await p.remove(C35AppId.sessionToken);
      await p.remove(C35AppId.sessionGlobalRoles);
    }
    sessionTick.value++;
  }
}
