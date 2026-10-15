import 'dart:async';

/// Coalesces debounced editor saves and flushes pending work before navigation.
class SiteEditorFlushCoordinator {
  final Map<String, Timer> _timers = {};
  final Map<String, Future<void> Function()> _pending = {};
  final Map<String, Future<void>> _inflight = {};

  void schedule(String key, Duration debounce, Future<void> Function() save) {
    _pending[key] = save;
    _timers[key]?.cancel();
    _timers[key] = Timer(debounce, () => unawaited(_runKey(key)));
  }

  void cancel(String key) {
    _timers.remove(key)?.cancel();
    _pending.remove(key);
  }

  Future<void> _runKey(String key) async {
    _timers.remove(key)?.cancel();
    if (_inflight.containsKey(key)) return;

    final fn = _pending.remove(key);
    if (fn == null) return;

    final run = fn();
    _inflight[key] = run;
    try {
      await run;
    } catch (_) {
      // [siteEditorSaveRun] reports errors on the save bus; coordinator only serializes.
    } finally {
      _inflight.remove(key);
      if (_pending.containsKey(key)) {
        await _runKey(key);
      }
    }
  }

  /// Cancel debounce timers and run every pending save (navigation / dispose).
  Future<void> flush() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();

    if (_inflight.isNotEmpty) {
      await Future.wait(_inflight.values.toList(growable: false));
    }
    while (_pending.isNotEmpty) {
      final keys = _pending.keys.toList(growable: false);
      for (final key in keys) {
        await _runKey(key);
      }
    }
  }

  bool get hasPending => _pending.isNotEmpty || _timers.isNotEmpty || _inflight.isNotEmpty;
}
