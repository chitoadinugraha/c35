import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ai/ui_serve_image.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _tbIcon = 20.0;
const _tbSize = 28.0;
const _tbGap = 10.0;
const _tbPad = EdgeInsets.zero;
const _tbConstraints = BoxConstraints(minWidth: _tbSize, minHeight: _tbSize, maxWidth: _tbSize, maxHeight: _tbSize);
final _tbStyle = IconButton.styleFrom(padding: _tbPad, minimumSize: const Size(_tbSize, _tbSize), maximumSize: const Size(_tbSize, _tbSize), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact);

class ShotHistory {
  final strokes = <List<Offset>>[];
  final _redo = <List<Offset>>[];
  List<List<Offset>>? _cleared;

  bool get canUndo => strokes.isNotEmpty || _cleared != null;
  bool get canRedo => _redo.isNotEmpty;

  void begin(Offset p) {
    strokes.add([p]);
    _redo.clear();
    _cleared = null;
  }

  void append(Offset p) {
    if (strokes.isNotEmpty) strokes.last.add(p);
  }

  void undo() {
    if (strokes.isEmpty) {
      if (_cleared == null) return;
      strokes.addAll(_cleared!);
      _cleared = null;
      return;
    }
    _redo.add(strokes.removeLast());
  }

  void redo() {
    if (_redo.isEmpty) return;
    strokes.add(_redo.removeLast());
  }

  void clear() {
    if (strokes.isEmpty) return;
    _cleared = [for (final s in strokes) List<Offset>.from(s)];
    strokes.clear();
    _redo.clear();
  }
}

void shotZoomWheel(TransformationController xf, Offset viewportPoint, double scrollDy, {double minScale = 0.5, double maxScale = 6}) {
  final scaleChange = math.exp(-scrollDy * 0.01);
  final matrix = xf.value.clone();
  final currentScale = matrix.getMaxScaleOnAxis();
  final newScale = (currentScale * scaleChange).clamp(minScale, maxScale);
  if (newScale == currentScale) return;
  final focal = MatrixUtils.transformPoint(Matrix4.inverted(matrix), viewportPoint);
  final scale = newScale / currentScale;
  matrix
    ..translateByDouble(focal.dx, focal.dy, 0, 1.0)
    ..scaleByDouble(scale, scale, 1.0, 1.0)
    ..translateByDouble(-focal.dx, -focal.dy, 0, 1.0);
  xf.value = matrix;
}

bool shotInImage(Offset p, Size image) => p.dx >= 0 && p.dy >= 0 && p.dx <= image.width && p.dy <= image.height;

Future<Uint8List?> shotAnnotatePng(Uint8List src, List<List<Offset>> strokes, {Color color = const Color(0xFFF43F5E)}) async {
  if (strokes.isEmpty) return src;
  final codec = await ui.instantiateImageCodec(src);
  final frame = await codec.getNextFrame();
  final img = frame.image;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawImage(img, Offset.zero, Paint());
  final strokeW = math.max(3.0, img.width / 280);
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeW
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  for (final pts in strokes) {
    if (pts.isEmpty) continue;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, strokeW / 2, Paint()..color = color);
      continue;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }
  final picture = rec.endRecording();
  final out = await picture.toImage(img.width, img.height);
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  out.dispose();
  codec.dispose();
  return data?.buffer.asUint8List();
}

StagedMedia stagedMediaPutImage(StagedMedia item, Uint8List png) {
  final name = item.name.contains('.') ? '${item.name.split('.').first}.png' : '${item.name}.png';
  return item.copyWith(name: name, bytes: png, mime: 'image/png', size: png.length, hash: null, uploadProgress: 0.05);
}

class UiShotThumb extends StatelessWidget {
  const UiShotThumb({super.key, this.bytes, this.servePath = '', this.width = 56, this.height = 56, this.onTap});

  final Uint8List? bytes;
  final String servePath;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasBytes = bytes != null && bytes!.isNotEmpty;
    final child = hasBytes
        ? Image.memory(bytes!, width: width, height: height, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
        : servePath.trim().isNotEmpty
            ? UiServeImage(path: servePath, fit: BoxFit.cover, width: width, height: height, errorBuilder: (_) => _empty())
            : _empty();
    return Material(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: SizedBox(width: width, height: height, child: child)),
    );
  }

  Widget _empty() => const Center(child: Icon(Icons.image_outlined, color: Color(0xFF71717A), size: 22));
}

class UiStagedShot extends StatelessWidget {
  const UiStagedShot({super.key, required this.item, this.onRemove, this.onReplace, this.size = 56});

  final StagedMedia item;
  final VoidCallback? onRemove;
  final ValueChanged<StagedMedia>? onReplace;
  final double size;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          UiShotThumb(
            bytes: item.bytes.isEmpty ? null : item.bytes,
            width: size,
            height: size,
            onTap: item.bytes.isEmpty
                ? null
                : () async {
                    final next = await stagedShotPreview(context, bytes: item.bytes, name: item.name, editable: true, source: item);
                    if (next != null) onReplace?.call(next);
                  },
          ),
          if (onRemove != null)
            Positioned(
              top: -5,
              right: -5,
              child: Material(
                color: const Color(0xFF27272A),
                shape: const CircleBorder(side: BorderSide(color: Color(0xFF3F3F46), width: 1.2)),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(padding: EdgeInsets.all(3), child: Icon(Icons.close_rounded, size: 13, color: Color(0xFFF4F4F5))),
                ),
              ),
            ),
        ],
      );
}

Future<StagedMedia?> stagedShotPreview(
  BuildContext context, {
  Uint8List? bytes,
  String servePath = '',
  String name = '',
  bool editable = true,
  StagedMedia? source,
  VoidCallback? onUpgradeHd,
}) =>
    showDialog<StagedMedia>(
      context: context,
      barrierColor: const Color(0xE608080A),
      barrierDismissible: false,
      builder: (ctx) => _ShotPreview(
        bytes: bytes ?? source?.bytes ?? Uint8List(0),
        servePath: servePath,
        name: name.isNotEmpty ? name : (source?.name ?? ''),
        editable: editable,
        source: source,
        onUpgradeHd: onUpgradeHd,
      ),
    );

class _ShotPreview extends StatefulWidget {
  const _ShotPreview({required this.bytes, required this.servePath, required this.name, required this.editable, this.source, this.onUpgradeHd});
  final Uint8List bytes;
  final String servePath;
  final String name;
  final bool editable;
  final StagedMedia? source;
  final VoidCallback? onUpgradeHd;

  @override
  State<_ShotPreview> createState() => _ShotPreviewState();
}

class _ShotPreviewState extends State<_ShotPreview> {
  static const _rose = Color(0xFFF43F5E);

  final _hist = ShotHistory();
  final _xf = TransformationController();
  Size? _imageSize;
  var _annotate = false;
  var _drawing = false;
  var _fitted = false;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  @override
  void dispose() {
    _xf.dispose();
    super.dispose();
  }

  String? _serveUrl() {
    final p = widget.servePath.trim();
    if (p.isEmpty) return null;
    return p.startsWith('http') ? p : '${C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '')}${p.startsWith('/') ? p : '/$p'}';
  }

  Future<void> _loadSize() async {
    if (widget.bytes.isNotEmpty) {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        codec.dispose();
        return;
      }
      setState(() {
        _imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
        _fitted = false;
      });
      frame.image.dispose();
      codec.dispose();
      return;
    }
    final url = _serveUrl();
    if (url == null) return;
    final token = sessionAuthToken();
    final image = NetworkImage(url, headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'});
    final completer = Completer<Size>();
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (info, _) {
          if (completer.isCompleted) return;
          completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
        },
        onError: (_, __) {
          if (!completer.isCompleted) completer.complete(const Size(800, 600));
        },
      ),
    );
    final size = await completer.future.timeout(const Duration(seconds: 12), onTimeout: () => const Size(800, 600));
    if (!mounted) return;
    setState(() {
      _imageSize = size;
      _fitted = false;
    });
  }

  void _fitToViewport(Size viewport) {
    final size = _imageSize;
    if (size == null || viewport.isEmpty) return;
    final scale = math.min(viewport.width / size.width, viewport.height / size.height).clamp(0.05, 1.0);
    _xf.value = Matrix4.identity()
      ..translateByDouble(viewport.width / 2 - scale * size.width / 2, viewport.height / 2 - scale * size.height / 2, 0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  void _ensureFit(Size viewport) {
    if (_fitted || _imageSize == null || viewport.isEmpty) return;
    _fitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitToViewport(viewport);
    });
  }

  Future<void> _done() async {
    if (_hist.strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final src = widget.source;
    if (src == null) {
      Navigator.pop(context);
      return;
    }
    final png = await shotAnnotatePng(widget.bytes, _hist.strokes);
    if (!mounted) return;
    if (png == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, stagedMediaPutImage(src, png));
  }

  void _undo() {
    if (_hist.canUndo) setState(_hist.undo);
  }

  void _redo() {
    if (_hist.canRedo) setState(_hist.redo);
  }

  void _clear() {
    if (_hist.canUndo && _hist.strokes.isNotEmpty) setState(_hist.clear);
  }

  void _toggleAnnotate() => setState(() => _annotate = !_annotate);

  void _onPointerSignal(PointerSignalEvent event) {
    if (_annotate || event is! PointerScrollEvent) return;
    if (!HardwareKeyboard.instance.isControlPressed) return;
    shotZoomWheel(_xf, event.localPosition, event.scrollDelta.dy);
  }

  void _paintDown(PointerDownEvent e) {
    final size = _imageSize;
    if (size == null) return;
    final p = e.localPosition;
    if (!shotInImage(p, size)) return;
    _drawing = true;
    setState(() => _hist.begin(p));
  }

  void _paintMove(PointerMoveEvent e) {
    if (!_drawing) return;
    final size = _imageSize;
    if (size == null) return;
    final p = e.localPosition;
    if (!shotInImage(p, size)) return;
    setState(() => _hist.append(p));
  }

  void _paintEnd() => _drawing = false;

  @override
  Widget build(BuildContext context) {
    const zinc100 = Color(0xFFF4F4F5);
    const zinc500 = Color(0xFF71717A);
    final imageSize = _imageSize;
    final editable = widget.editable;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.maybePop(context),
        if (editable) ...{
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _redo,
        },
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            children: [
              SizedBox(
                height: _tbSize,
                child: Row(
                  children: [
                    uiIconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: zinc100, size: _tbIcon), iconSize: _tbIcon, padding: _tbPad, constraints: _tbConstraints, style: _tbStyle),
                    if (!editable && widget.onUpgradeHd != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onUpgradeHd?.call();
                        },
                        icon: const Icon(Icons.hd_rounded, size: 18, color: zinc100),
                        label: Text(catalogT('chat.image.upgrade_hd'), style: const TextStyle(color: zinc100, fontWeight: FontWeight.w600, fontSize: 13)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), minimumSize: const Size(0, _tbSize), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                    if (editable) ...[
                      const Spacer(),
                      uiIconButton(
                        tooltip: _annotate ? 'Pan & zoom' : 'Annotate',
                        onPressed: imageSize == null ? null : _toggleAnnotate,
                        icon: Icon(_annotate ? Icons.edit : Icons.edit_outlined, color: _annotate ? _rose : zinc500, size: _tbIcon),
                        iconSize: _tbIcon,
                        padding: _tbPad,
                        constraints: _tbConstraints,
                        style: _tbStyle,
                      ),
                      const SizedBox(width: _tbGap),
                      uiIconButton(tooltip: 'Undo', onPressed: _hist.canUndo ? _undo : null, icon: Icon(Icons.undo_rounded, color: _hist.canUndo ? zinc100 : zinc500, size: _tbIcon), iconSize: _tbIcon, padding: _tbPad, constraints: _tbConstraints, style: _tbStyle),
                      const SizedBox(width: _tbGap),
                      uiIconButton(tooltip: 'Redo', onPressed: _hist.canRedo ? _redo : null, icon: Icon(Icons.redo_rounded, color: _hist.canRedo ? zinc100 : zinc500, size: _tbIcon), iconSize: _tbIcon, padding: _tbPad, constraints: _tbConstraints, style: _tbStyle),
                      const SizedBox(width: _tbGap),
                      uiIconButton(tooltip: 'Clear drawings', onPressed: _hist.strokes.isEmpty ? null : _clear, icon: Icon(Icons.format_color_reset_outlined, color: _hist.strokes.isEmpty ? zinc500 : zinc100, size: _tbIcon), iconSize: _tbIcon, padding: _tbPad, constraints: _tbConstraints, style: _tbStyle),
                      const SizedBox(width: _tbGap),
                      TextButton(
                        onPressed: _done,
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), minimumSize: const Size(0, _tbSize), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                        child: Text(_hist.strokes.isEmpty ? 'Done' : 'Save', style: const TextStyle(color: zinc100, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(constraints.maxWidth, constraints.maxHeight);
                    _ensureFit(viewport);
                    return DecoratedBox(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF0C0C0E)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageSize == null
                            ? const UILoading()
                            : Listener(
                                onPointerSignal: _onPointerSignal,
                                child: InteractiveViewer(
                                  transformationController: _xf,
                                  constrained: false,
                                  alignment: Alignment.topLeft,
                                  clipBehavior: Clip.hardEdge,
                                  boundaryMargin: const EdgeInsets.all(double.infinity),
                                  panEnabled: !editable || !_annotate,
                                  scaleEnabled: !editable || !_annotate,
                                  minScale: 0.05,
                                  maxScale: 6,
                                  child: _ShotCanvas(
                                    bytes: widget.bytes,
                                    servePath: widget.servePath,
                                    imageSize: imageSize,
                                    strokes: editable ? _hist.strokes : const [],
                                    annotate: editable && _annotate,
                                    onPointerDown: _paintDown,
                                    onPointerMove: _paintMove,
                                    onPointerUp: (_) => _paintEnd(),
                                    onPointerCancel: (_) => _paintEnd(),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShotCanvas extends StatelessWidget {
  const _ShotCanvas({
    required this.bytes,
    required this.servePath,
    required this.imageSize,
    required this.strokes,
    this.annotate = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  final Uint8List bytes;
  final String servePath;
  final Size imageSize;
  final List<List<Offset>> strokes;
  final bool annotate;
  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerCancelEventListener? onPointerCancel;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: imageSize.width,
        height: imageSize.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: bytes.isNotEmpty
                  ? Image.memory(bytes, fit: BoxFit.contain, filterQuality: FilterQuality.high)
                  : UiServeImage(path: servePath, fit: BoxFit.contain, errorBuilder: (_) => const Center(child: Icon(Icons.broken_image_rounded, color: Color(0xFF71717A), size: 28))),
            ),
            if (strokes.isNotEmpty) Positioned.fill(child: CustomPaint(painter: _StrokePainter(strokes: strokes, imageSize: imageSize))),
            if (annotate)
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: onPointerDown,
                  onPointerMove: onPointerMove,
                  onPointerUp: onPointerUp,
                  onPointerCancel: onPointerCancel,
                  child: MouseRegion(cursor: SystemMouseCursors.precise, child: const SizedBox.expand()),
                ),
              ),
          ],
        ),
      );
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({required this.strokes, required this.imageSize});

  final List<List<Offset>> strokes;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = math.max(3.0, imageSize.width / 280)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final pts in strokes) {
      if (pts.isEmpty) continue;
      if (pts.length == 1) {
        canvas.drawCircle(pts.first, paint.strokeWidth / 2, Paint()..color = paint.color);
        continue;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}
