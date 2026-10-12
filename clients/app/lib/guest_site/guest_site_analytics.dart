import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Guest visitor analytics ping (parity with `c35GuestAnalytics` in `site-guest.v1.js`).
class GuestSiteAnalytics {
  static const _sessionKeyPrefix = 'c35.guest.session.v1';
  static const _maxActiveMsPerPing = 30 * 60 * 1000;

  static String get _apiBase => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  static String sessionPrefsKey(int siteIid) => '$_sessionKeyPrefix.$siteIid';

  static Future<String> sessionIdForSite(int siteIid) async {
    final prefs = await SharedPreferences.getInstance();
    final key = sessionPrefsKey(siteIid);
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 's_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_$siteIid';
    await prefs.setString(key, id);
    return id;
  }

  static bool analyticsEnabled(Map<String, dynamic> capabilities) {
    return capabilities['analytics'] != false;
  }

  /// Fire-and-forget ping when the preview tab or app goes to background.
  static Future<void> pingOnHidden({
    required int siteIid,
    required String alienId,
    required int activeDurationMs,
    String path = '/',
    String? referrer,
  }) async {
    final aid = alienId.trim();
    if (aid.isEmpty) return;
    final visitorId = await GuestAssistantApi.visitorIdForSite(siteIid);
    final sessionId = await sessionIdForSite(siteIid);
    final duration = activeDurationMs.clamp(0, _maxActiveMsPerPing);
    try {
      await http.post(
        Uri.parse('$_apiBase/v1/site/guest-analytics/ping'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'alien_id': aid,
          'session_id': sessionId,
          'path': path,
          'visitor_id': visitorId,
          if (referrer != null && referrer.isNotEmpty) 'referrer': referrer,
          'active_duration_ms': duration,
        }),
      );
    } catch (_) {
      // ingest is best-effort
    }
  }
}
