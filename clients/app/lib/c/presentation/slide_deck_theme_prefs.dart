/// Per-chat slide theme chosen in the deck UI (survives rebuilds and new patch blocks).
class SlideDeckThemePrefs {
  SlideDeckThemePrefs._();

  static final SlideDeckThemePrefs instance = SlideDeckThemePrefs._();

  final Map<int, String> _byChatId = {};

  String? themeFor(int chatId) {
    if (chatId <= 0) return null;
    return _byChatId[chatId];
  }

  void set(int chatId, String themeId) {
    if (chatId <= 0) return;
    final t = themeId.trim();
    if (t.isEmpty) return;
    _byChatId[chatId] = t;
  }
}
