import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
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
    final id = 'v_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_${siteIid}';
    await prefs.setString(key, id);
    return id;
  }

  static Future<String> sendChat({
    required int siteIid,
    required String visitorId,
    required String message,
    Map<String, dynamic>? cart,
  }) async {
    final resp = await http.post(
      Uri.parse('$_apiBase/v1/site/guest-assistant/chat'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'site_iid': siteIid,
        'visitor_id': visitorId,
        'message': message,
        if (cart != null) 'cart': cart,
      }),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      final msg = data is Map ? data['error']?.toString() ?? resp.body : resp.body;
      throw StateError(msg);
    }
    if (data is! Map<String, dynamic>) throw StateError('invalid guest chat response');
    return data['text']?.toString() ?? '';
  }
}
