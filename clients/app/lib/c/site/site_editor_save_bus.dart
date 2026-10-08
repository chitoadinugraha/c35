import 'package:flutter/foundation.dart';

/// CSA-style autosave state for site editor chrome (`Saving…` subtitle).
class SiteEditorSaveBus extends ChangeNotifier {
  var saving = false;
  var error = '';

  void beginSave() {
    var changed = false;
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
    if (!saving) return;
    saving = false;
    notifyListeners();
  }

  void endSaveError(String message) {
    var changed = false;
    if (saving) {
      saving = false;
      changed = true;
    }
    if (error != message) {
      error = message;
      changed = true;
    }
    if (changed) notifyListeners();
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
