import 'package:flutter/foundation.dart';

/// Notifies when a font family is ready. Families resolve through the platform
/// font fallback until a loader is attached; the picker still lists CSA families.
class SiteFontLoader extends ChangeNotifier {
  SiteFontLoader._();
  static final SiteFontLoader instance = SiteFontLoader._();

  bool isReady(String family) => family.isEmpty;

  void ensureLoaded(String family) {}
}
