import 'dart:convert';

import 'package:alienai_c35/c/app_id.dart';
import 'package:alienai_c35/c/pb/c35/session.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

String sessionInitSinceKey(int uid) => '${C35AppId.id}_session_init_since_ms.$uid';
String sessionInitPbKey(int uid) => '${C35AppId.id}_session_init_pb.$uid';
String sessionInitModelsPbKey(int uid) => '${C35AppId.id}_session_init_models_pb.$uid';

class SessionInitCache {
  static Future<int> sinceMs() async {
    final uid = Session.instance.uid;
    if (uid <= 0) return 0;
    final p = await SharedPreferences.getInstance();
    return p.getInt(sessionInitSinceKey(uid)) ?? 0;
  }

  static Future<ResSessionInit?> load() async {
    final uid = Session.instance.uid;
    if (uid <= 0) return null;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(sessionInitPbKey(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      return ResSessionInit.fromBuffer(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<List<PromptModelOption>> loadModels() async {
    final uid = Session.instance.uid;
    if (uid <= 0) return const [];
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(sessionInitModelsPbKey(uid));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final init = ResSessionInit.fromBuffer(base64Decode(raw));
      return init.models;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> persist(ResSessionInit init) async {
    final uid = Session.instance.uid;
    if (uid <= 0) return;
    final watermark = init.serverTimeMs.toInt() > 0 ? init.serverTimeMs.toInt() : init.sinceMs.toInt();
    final p = await SharedPreferences.getInstance();
    if (watermark > 0) await p.setInt(sessionInitSinceKey(uid), watermark);
    final shell = init.clone()..models.clear();
    await p.setString(sessionInitPbKey(uid), base64Encode(shell.writeToBuffer()));
    if (init.models.length > 1) {
      await p.setString(sessionInitModelsPbKey(uid), base64Encode(ResSessionInit(models: init.models).writeToBuffer()));
    }
  }

  static Future<void> clearForUid(int uid) async {
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    await p.remove(sessionInitSinceKey(uid));
    await p.remove(sessionInitPbKey(uid));
    await p.remove(sessionInitModelsPbKey(uid));
  }
}