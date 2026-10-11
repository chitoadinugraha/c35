import 'dart:async';

/// Coalesces debounced editor saves and flushes pending work before navigation.
class SiteEditorFlushCoordinator {
  final Map<String, Timer> _timers = {};
  final Map<String, Future<void> Function()> _pending = {};

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
    final fn = _pending.remove(key);
    if (fn == null) return;
    await fn();
  }

  /// Cancel debounce timers and run every pending save (navigation / dispose).
  Future<void> flush() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    final ops = _pending.values.toList(growable: false);
    _pending.clear();
    for (final op in ops) {
      await op();
    }
  }

  bool get hasPending => _pending.isNotEmpty || _timers.isNotEmpty;
}
