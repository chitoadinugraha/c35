import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:alienai_c35/c/site/design/overlay_effect_instance.dart';
import 'overlay_effect_particle.dart';
import 'overlay_effect_pointer_frame.dart';
import 'overlay_effect_pointer_hub.dart';
import 'overlay_effect_throttle.dart';
import 'runners/autumn_leaves_painter.dart';
import 'runners/drifting_clouds_painter.dart';
import 'runners/falling_hearts_painter.dart';
import 'runners/fireworks_painter.dart';
import 'runners/floating_bubbles_painter.dart';
import 'runners/matrix_rain_painter.dart';
import 'runners/moonlight_painter.dart';
import 'runners/rain_shower_painter.dart';
import 'runners/sakura_petals_painter.dart';
import 'runners/snow_fall_painter.dart';
import 'runners/starry_night_painter.dart';
import 'runners/thunderstorm_painter.dart';

typedef _EngineTick = void Function(List<double> out, {OverlayEffectPointerFrame? pointers});

class _LocalEngine {
  _LocalEngine({
    required this.presetId,
    required this.setScale,
    required this.reload,
    required this.resize,
    required this.tick,
  });

  final String presetId;
  final void Function(double) setScale;
  final void Function(Map<String, Object?>) reload;
  final void Function(Size) resize;
  final _EngineTick tick;
}

/// Overlay effect sim host.
///
/// - **low / mid** devices: local throttled loop (reliable; density/FPS already cut)
/// - **high** devices: background isolate; falls back to local if isolate fails
class OverlayEffectHost extends ChangeNotifier {
  OverlayEffectHost();

  Float32List particles = Float32List(0);
  var count = 0;
  var simplifyShapes = false;
  var ready = false;

  Isolate? _isolate;
  SendPort? _worker;
  ReceivePort? _fromWorker;
  Timer? _timer;
  Timer? _tickWatchdog;
  OverlayEffectThrottle _throttle = OverlayEffectThrottle.provisional();
  Size _size = Size.zero;
  var _layers = <_LayerSpec>[];
  OverlayEffectPointerHub? _hub;
  var _tickInFlight = false;
  var _useIsolate = false;
  var _disposed = false;
  final _localEngines = <String, _LocalEngine>{};
  final _localOut = <double>[];

  Future<void> start({
    required List<SiteOverlayEffectDraft> effects,
    OverlayEffectPointerHub? pointerHub,
  }) async {
    _hub = pointerHub;
    _throttle = await OverlayEffectThrottle.resolve();
    if (_disposed) return;
    simplifyShapes = _throttle.simplifyShapes;
    // Local loop only. Isolate + dart:ui is flaky, and the wasm crate is deferred.
    _useIsolate = false;
    if (_useIsolate) {
      try {
        await _ensureIsolate();
      } catch (_) {
        _useIsolate = false;
        _tearDownIsolate();
      }
    }
    syncEffects(effects);
    _armTimer();
    ready = true;
    notifyListeners();
  }

  void syncEffects(List<SiteOverlayEffectDraft> effects) {
    _layers = [
      for (final e in effects.where((e) => e.active && overlayEffectPresetRunnable(e.presetId)))
        _LayerSpec(id: e.id, presetId: e.presetId, params: Map<String, Object?>.from(e.params)),
    ];
    if (_useIsolate && _worker != null) {
      _worker!.send({
        't': 'sync',
        'densityScale': _throttle.densityScale,
        'layers': [
          for (final l in _layers) {'id': l.id, 'presetId': l.presetId, 'params': l.params},
        ],
        'w': _size.width,
        'h': _size.height,
      });
    } else {
      _syncLocal();
    }
    _armTimer();
    if (_layers.isEmpty) {
      particles = Float32List(0);
      count = 0;
      notifyListeners();
    } else {
      // Kick first frame after sync/resize settles.
      scheduleMicrotask(_requestTick);
    }
  }

  void resize(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if ((size.width - _size.width).abs() < 1 && (size.height - _size.height).abs() < 1) return;
    _size = size;
    if (_useIsolate && _worker != null) {
      _worker!.send({'t': 'resize', 'w': size.width, 'h': size.height});
    } else {
      for (final e in _localEngines.values) {
        e.resize(size);
      }
    }
    // Size often arrives after timer started; force a tick so we don't wait a full interval.
    _tickInFlight = false;
    _requestTick();
  }

  void _armTimer() {
    _timer?.cancel();
    if (_layers.isEmpty) return;
    _timer = Timer.periodic(_throttle.frameInterval, (_) => _requestTick());
  }

  void _requestTick() {
    if (_tickInFlight || _layers.isEmpty || _size.width <= 0) return;
    _tickInFlight = true;
    final frame = _hub?.snapshotAndClear() ?? const OverlayEffectPointerFrame();
    if (!_useIsolate || _worker == null) {
      _tickLocal(frame);
      return;
    }
    _tickWatchdog?.cancel();
    _tickWatchdog = Timer(const Duration(milliseconds: 500), () {
      // Isolate hung or died — fall back to local so animation keeps moving.
      if (!_tickInFlight) return;
      _tickInFlight = false;
      _useIsolate = false;
      _tearDownIsolate();
      _syncLocal();
      _requestTick();
    });
    try {
      _worker!.send({
        't': 'tick',
        'pointers': [
          for (final e in frame.pointers.entries) [e.key, e.value.dx, e.value.dy],
        ],
        'downs': [
          for (final p in frame.downs) [p.dx, p.dy],
        ],
        'ups': [
          for (final p in frame.ups) [p.dx, p.dy],
        ],
      });
    } catch (_) {
      _tickWatchdog?.cancel();
      _tickInFlight = false;
      _useIsolate = false;
      _tearDownIsolate();
      _syncLocal();
      _tickLocal(frame);
    }
  }

  void _syncLocal() {
    final keep = <String>{};
    for (final layer in _layers) {
      keep.add(layer.id);
      final existing = _localEngines[layer.id];
      if (existing == null || existing.presetId != layer.presetId) {
        final engine = _localEngineCreate(layer.presetId, layer.params, _throttle.densityScale);
        if (engine != null) {
          _localEngines[layer.id] = engine;
          if (_size.width > 0) engine.resize(_size);
        }
      } else {
        existing.setScale(_throttle.densityScale);
        existing.reload(layer.params);
        if (_size.width > 0) existing.resize(_size);
      }
    }
    _localEngines.removeWhere((id, _) => !keep.contains(id));
  }

  void _tickLocal(OverlayEffectPointerFrame frame) {
    try {
      if (_localEngines.isEmpty) _syncLocal();
      _localOut.clear();
      for (final e in _localEngines.values) {
        e.tick(_localOut, pointers: frame);
      }
      count = _localOut.length ~/ effectParticleStride;
      particles = Float32List.fromList(_localOut);
    } catch (_) {
      count = 0;
      particles = Float32List(0);
    }
    _tickInFlight = false;
    notifyListeners();
  }

  Future<void> _ensureIsolate() async {
    if (_worker != null) return;
    final fromWorker = ReceivePort();
    _fromWorker = fromWorker;
    final ready = Completer<void>();
    fromWorker.listen((msg) {
      if (msg is SendPort) {
        _worker = msg;
        if (!ready.isCompleted) ready.complete();
        return;
      }
      _onWorkerMessage(msg);
    });
    _isolate = await Isolate.spawn(
      _overlayEffectWorkerMain,
      fromWorker.sendPort,
      debugName: 'overlay_effects',
      errorsAreFatal: false,
    );
    await ready.future.timeout(const Duration(seconds: 2));
  }

  void _onWorkerMessage(dynamic msg) {
    if (msg is! Map) return;
    if (msg['t'] == 'frame') {
      _tickWatchdog?.cancel();
      _tickInFlight = false;
      final td = msg['data'];
      final c = msg['count'] as int? ?? 0;
      if (td is Float32List) {
        particles = td;
        count = c;
      } else if (td is TransferableTypedData) {
        particles = td.materialize().asFloat32List();
        count = c;
      } else if (td is List) {
        particles = Float32List.fromList(td.cast<num>().map((n) => n.toDouble()).toList());
        count = c;
      } else {
        particles = Float32List(0);
        count = 0;
      }
      notifyListeners();
    }
  }

  void _tearDownIsolate() {
    _tickWatchdog?.cancel();
    try {
      _worker?.send({'t': 'stop'});
    } catch (_) {}
    _isolate?.kill(priority: Isolate.immediate);
    _fromWorker?.close();
    _isolate = null;
    _worker = null;
    _fromWorker = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _tickWatchdog?.cancel();
    _tearDownIsolate();
    _localEngines.clear();
    super.dispose();
  }
}

class _LayerSpec {
  const _LayerSpec({required this.id, required this.presetId, required this.params});
  final String id;
  final String presetId;
  final Map<String, Object?> params;
}

_LocalEngine? _localEngineCreate(String presetId, Map<String, Object?> params, double densityScale) {
  switch (overlayEffectPresetCanonical(presetId)) {
    case 'rain-shower':
      final s = RainShowerState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'falling-hearts':
      final s = FallingHeartsState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'snow-fall':
      final s = SnowFallState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'floating-bubbles':
      final s = FloatingBubblesState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'thunderstorm':
      final s = ThunderstormState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'fireworks':
      final s = FireworksState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'starry-night':
      final s = StarryNightState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'drifting-clouds':
      final s = DriftingCloudsState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'matrix-rain':
      final s = MatrixRainState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'sakura-petals':
      final s = SakuraPetalsState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'moonlight':
      final s = MoonlightState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    case 'autumn-leaves':
      final s = AutumnLeavesState(params)..densityScale = densityScale;
      s.reload(params);
      return _LocalEngine(presetId: presetId, setScale: (v) => s.densityScale = v, reload: s.reload, resize: s.resize, tick: s.tick);
    default:
      return null;
  }
}

void _overlayEffectWorkerMain(SendPort mainPort) {
  final inbox = ReceivePort();
  mainPort.send(inbox.sendPort);
  final engines = <String, _LocalEngine>{};
  var densityScale = 1.0;
  var width = 0.0;
  var height = 0.0;
  final out = <double>[];

  void sendFrame() {
    final count = out.length ~/ effectParticleStride;
    // Plain Float32List — TransferableTypedData nested in Map is unreliable on some Android builds.
    mainPort.send({'t': 'frame', 'count': count, 'data': Float32List.fromList(out)});
  }

  inbox.listen((dynamic raw) {
    if (raw is! Map) return;
    try {
      switch (raw['t']) {
        case 'stop':
          inbox.close();
          return;
        case 'sync':
          densityScale = (raw['densityScale'] as num?)?.toDouble() ?? 1.0;
          width = (raw['w'] as num?)?.toDouble() ?? width;
          height = (raw['h'] as num?)?.toDouble() ?? height;
          final layers = (raw['layers'] as List?) ?? const [];
          final keep = <String>{};
          for (final layer in layers) {
            if (layer is! Map) continue;
            final id = layer['id'] as String? ?? '';
            final presetId = layer['presetId'] as String? ?? '';
            final params = Map<String, Object?>.from(layer['params'] as Map? ?? {});
            keep.add(id);
            final existing = engines[id];
            if (existing == null || existing.presetId != presetId) {
              final engine = _localEngineCreate(presetId, params, densityScale);
              if (engine != null) {
                engines[id] = engine;
                if (width > 0 && height > 0) engine.resize(Size(width, height));
              }
            } else {
              existing.setScale(densityScale);
              existing.reload(params);
              if (width > 0 && height > 0) existing.resize(Size(width, height));
            }
          }
          engines.removeWhere((id, _) => !keep.contains(id));
          return;
        case 'resize':
          width = (raw['w'] as num?)?.toDouble() ?? width;
          height = (raw['h'] as num?)?.toDouble() ?? height;
          final size = Size(width, height);
          for (final e in engines.values) {
            e.resize(size);
          }
          return;
        case 'tick':
          final pointers = <int, Offset>{};
          for (final row in (raw['pointers'] as List?) ?? const []) {
            if (row is! List || row.length < 3) continue;
            pointers[(row[0] as num).toInt()] = Offset((row[1] as num).toDouble(), (row[2] as num).toDouble());
          }
          final downs = <Offset>[
            for (final row in (raw['downs'] as List?) ?? const [])
              if (row is List && row.length >= 2) Offset((row[0] as num).toDouble(), (row[1] as num).toDouble()),
          ];
          final ups = <Offset>[
            for (final row in (raw['ups'] as List?) ?? const [])
              if (row is List && row.length >= 2) Offset((row[0] as num).toDouble(), (row[1] as num).toDouble()),
          ];
          final frame = OverlayEffectPointerFrame(pointers: pointers, downs: downs, ups: ups);
          out.clear();
          for (final e in engines.values) {
            e.tick(out, pointers: frame);
          }
          sendFrame();
          return;
      }
    } catch (_) {
      out.clear();
      sendFrame();
    }
  });
}
