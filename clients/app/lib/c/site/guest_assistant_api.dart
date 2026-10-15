import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuestAssistantApi {
  static String get _apiBase => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  static String visitorPrefsKey(int siteIid) => 'c35.guest.visitor.v1.$siteIid';

  static Future<String> visitorIdForSite(int siteIid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = visitorPrefsKey(siteIid);
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 'v_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_$siteIid';
    await prefs.setString(key, id);
    return id;
  }

  static Future<String> sendChat({
    required int siteIid,
    required String visitorId,
    required String message,
    Map<String, dynamic>? cart,
    String bootMode = 'published',
    http.Client? client,
  }) async {
    final token = sessionAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final mode = bootMode.trim().toLowerCase();
    final postClient = client ?? http.Client();
    final shouldClose = client == null;
    http.Response resp;
    try {
      resp = await postClient.post(
        Uri.parse('$_apiBase/v1/site/guest-assistant/chat'),
        headers: headers,
        body: jsonEncode({
          'site_iid': siteIid,
          'visitor_id': visitorId,
          'message': message,
          if (mode == 'draft') 'boot_mode': 'draft',
          if (cart != null) 'cart': cart,
        }),
      );
    } finally {
      if (shouldClose) {
        postClient.close();
      }
    }
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg);
    }
    if (data is! Map<String, dynamic>) throw StateError('invalid guest chat response');
    return data['text']?.toString() ?? '';
  }

  static Future<ResSiteGuestAssistantLiveSetup> liveSetup({
    required int siteIid,
    required String visitorId,
    String bootMode = 'published',
    http.Client? client,
  }) async {
    final token = sessionAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final mode = bootMode.trim().toLowerCase();
    final postClient = client ?? http.Client();
    final shouldClose = client == null;
    http.Response resp;
    try {
      resp = await postClient.post(
        Uri.parse('$_apiBase/v1/site/guest-assistant/live/setup'),
        headers: headers,
        body: jsonEncode({
          'site_iid': siteIid,
          'visitor_id': visitorId,
          if (mode == 'draft') 'boot_mode': 'draft',
        }),
      );
    } finally {
      if (shouldClose) {
        postClient.close();
      }
    }

    final dynamic data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg.isEmpty ? 'HTTP ${resp.statusCode}' : msg);
    }
    if (data is! Map<String, dynamic>) throw StateError('invalid guest live setup response');
    final res = ResSiteGuestAssistantLiveSetup(
      ok: data['ok'] == true,
      error: data['error']?.toString() ?? '',
      reqId: data['req_id']?.toString() ?? '',
      liveSessionId: data['live_session_id']?.toString() ?? '',
      wsPath: data['ws_path']?.toString() ?? '',
      maxDurationSec: (data['max_duration_sec'] as num?)?.toInt() ?? 0,
    );
    if (!res.ok && res.error.isNotEmpty) {
      throw StateError(res.error);
    }
    return res;
  }
}

