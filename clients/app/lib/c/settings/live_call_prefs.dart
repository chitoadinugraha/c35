import 'package:shared_preferences/shared_preferences.dart';

class LiveCallPrefs {
  LiveCallPrefs._();

  static const _keyLastOffer = 'live_call_last_offer_id';

  static Future<String> lastOfferId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyLastOffer) ?? '';
  }

  static Future<void> setLastOfferId(String id) async {
    final p = await SharedPreferences.getInstance();
    if (id.trim().isEmpty) {
      await p.remove(_keyLastOffer);
    } else {
      await p.setString(_keyLastOffer, id.trim());
    }
  }
}
