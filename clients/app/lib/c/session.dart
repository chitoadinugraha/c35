import 'dart:convert';

import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/app_id_ensure.dart';
import 'package:alienai_c35/c/profile/profile_handle.dart';
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
  String allowControl = 'no';
  String thisPcName = '';
  String modelId = '';
  int referredByIid = 0;
  bool referralDismissed = false;

  bool get signedIn => uid > 0 && token.isNotEmpty;
  bool get allowControlYes => allowControl == 'yes';
  bool get isRoot => globalRoles.contains('root');
  bool get isTester => globalRoles.contains('tester');
  bool get hasReferrer => referredByIid > 0;
  bool get hasAlienId => handle.isNotEmpty && handle != 'user' && !handle.startsWith('@user');
  bool get needsReferralPrompt => signedIn && !hasReferrer && !referralDismissed;

  Future<void> restore() async {
    await appIdEnsure();
    final p = await SharedPreferences.getInstance();
    uid = p.getInt(C35AppId.sessionUid) ?? 0;
    name = p.getString(C35AppId.sessionName) ?? '';
    handle = p.getString(C35AppId.sessionHandle) ?? '';
    pic = p.getString(C35AppId.sessionPic) ?? '';
    email = p.getString(C35AppId.sessionEmail) ?? '';
    token = p.getString(C35AppId.sessionToken) ?? '';
    globalRoles = sessionGlobalRolesParse(p.getString(C35AppId.sessionGlobalRoles));
    allowControl = p.getString(C35AppId.allowControl) ?? 'no';
    thisPcName = p.getString(C35AppId.thisPcName) ?? '';
    modelId = p.getString(C35AppId.model) ?? '';
    referredByIid = p.getInt(C35AppId.sessionReferredBy) ?? 0;
    referralDismissed = p.getBool(C35AppId.sessionReferralDismissed) ?? false;
    sessionTick.value++;
  }

  Future<void> modelPut(String id) async {
    modelId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString(C35AppId.model, id);
    sessionTick.value++;
  }

  Future<void> allowControlPut(String value) async {
    allowControl = value;
    final p = await SharedPreferences.getInstance();
    await p.setString(C35AppId.allowControl, value);
    sessionTick.value++;
  }

  Future<void> thisPcNamePut(String value) async {
    thisPcName = value;
    final p = await SharedPreferences.getInstance();
    await p.setString(C35AppId.thisPcName, value);
    sessionTick.value++;
  }

  Future<void> identityMerge({
    String? name,
    String? alienId,
    String? pic,
    String? email,
    List<String>? globalRoles,
    int? referredByIid,
    bool? referralDismissed,
  }) async {
    var dirty = false;
    if (name != null && name.isNotEmpty && name != this.name) {
      this.name = name;
      dirty = true;
    }
    if (alienId != null) {
      final next = alienId.trim().isEmpty ? '' : profileHandleDisplay(alienId);
      if (next != handle) {
        handle = next;
        dirty = true;
      }
    }
    if (pic != null && pic.isNotEmpty && pic != this.pic) {
      this.pic = pic;
      dirty = true;
    }
    if (email != null && email.isNotEmpty && email != this.email) {
      this.email = email;
      dirty = true;
    }
    if (globalRoles != null && !_sameRoles(globalRoles, this.globalRoles)) {
      this.globalRoles = globalRoles;
      dirty = true;
    }
    if (referredByIid != null && referredByIid > 0 && this.referredByIid != referredByIid) {
      this.referredByIid = referredByIid;
      dirty = true;
    }
    if (referralDismissed != null && this.referralDismissed != referralDismissed) {
      this.referralDismissed = referralDismissed;
      dirty = true;
    }
    if (!dirty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(C35AppId.sessionName, this.name);
    await p.setString(C35AppId.sessionHandle, handle);
    await p.setString(C35AppId.sessionPic, this.pic);
    await p.setString(C35AppId.sessionEmail, this.email);
    await p.setString(C35AppId.sessionGlobalRoles, jsonEncode(this.globalRoles));
    await p.setInt(C35AppId.sessionReferredBy, this.referredByIid);
    await p.setBool(C35AppId.sessionReferralDismissed, this.referralDismissed);
    sessionTick.value++;
  }

  Future<void> referralDismissedPut() async {
    referralDismissed = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(C35AppId.sessionReferralDismissed, true);
    sessionTick.value++;
  }

  Future<void> referredByPut(int parentUid) async {
    referredByIid = parentUid;
    referralDismissed = true;
    final p = await SharedPreferences.getInstance();
    await p.setInt(C35AppId.sessionReferredBy, parentUid);
    await p.setBool(C35AppId.sessionReferralDismissed, true);
    sessionTick.value++;
  }

  bool _sameRoles(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> put({
    required int uid,
    required String name,
    String handle = '',
    String pic = '',
    String? email,
    String token = '',
    List<String> globalRoles = const [],
    int referredByIid = 0,
    bool referralDismissed = false,
  }) async {
    this.uid = uid;
    this.name = name;
    this.handle = handle;
    this.pic = pic;
    if (email != null) this.email = email;
    this.token = token;
    this.globalRoles = globalRoles;
    this.referredByIid = referredByIid;
    this.referralDismissed = referralDismissed;
    final p = await SharedPreferences.getInstance();
    await p.setInt(C35AppId.sessionUid, uid);
    await p.setString(C35AppId.sessionName, name);
    await p.setString(C35AppId.sessionHandle, handle);
    await p.setString(C35AppId.sessionPic, pic);
    await p.setString(C35AppId.sessionEmail, this.email);
    await p.setString(C35AppId.sessionToken, token);
    await p.setString(C35AppId.sessionGlobalRoles, jsonEncode(globalRoles));
    await p.setInt(C35AppId.sessionReferredBy, referredByIid);
    await p.setBool(C35AppId.sessionReferralDismissed, referralDismissed);
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
    allowControl = 'no';
    thisPcName = '';
    modelId = '';
    referredByIid = 0;
    referralDismissed = false;
    if (clearStored) {
      final p = await SharedPreferences.getInstance();
      await p.remove(C35AppId.sessionUid);
      await p.remove(C35AppId.sessionName);
      await p.remove(C35AppId.sessionHandle);
      await p.remove(C35AppId.sessionPic);
      await p.remove(C35AppId.sessionEmail);
      await p.remove(C35AppId.sessionToken);
      await p.remove(C35AppId.sessionGlobalRoles);
      await p.remove(C35AppId.sessionReferredBy);
      await p.remove(C35AppId.sessionReferralDismissed);
      await p.remove(C35AppId.allowControl);
      await p.remove(C35AppId.thisPcName);
      await p.remove(C35AppId.model);
    }
    sessionTick.value++;
  }
}
