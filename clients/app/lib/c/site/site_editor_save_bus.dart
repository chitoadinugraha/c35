import 'package:flutter/foundation.dart';

/// CSA-style autosave state for site editor chrome (`Saving…` subtitle).
class SiteEditorSaveBus extends ChangeNotifier {
  var _inFlight = 0;
  var saving = false;
  var error = '';

  void beginSave() {
    var changed = false;
    _inFlight++;
    if (!saving) {
      saving = true;
      changed = true;
    }
    if (error.isNotEmpty) {
      error = '';
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void endSaveSuccess() {
    if (_release()) notifyListeners();
  }

  void endSaveError(String message) {
    var changed = false;
    if (message.isNotEmpty && error != message) {
      error = message;
      changed = true;
    }
    changed = _release() || changed;
    if (changed) notifyListeners();
  }

  /// Decrements in-flight count; returns whether UI state changed.
  bool _release() {
    if (_inFlight <= 0) return false;
    _inFlight--;
    if (_inFlight == 0 && saving) {
      saving = false;
      return true;
    }
    return false;
  }
}

Future<T> siteEditorSaveRun<T>(SiteEditorSaveBus bus, Future<T> Function() fn) async {
  bus.beginSave();
  try {
    final out = await fn();
    bus.endSaveSuccess();
    return out;
  } catch (e) {
    bus.endSaveError('$e');
    rethrow;
  }
}
