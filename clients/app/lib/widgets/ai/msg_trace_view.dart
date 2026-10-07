import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/settings/prompt_usage_prefs.dart';
import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter/material.dart';

import 'package:alienai_c35/widgets/ai/ui_citation_chips.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
enum MsgTracePart { chips, citations, all }

class MsgTraceView {
  const MsgTraceView({this.chips = const [], this.view = const TraceView(), this.citations = const []});
  final List<MsgTraceToolChip> chips;
  final TraceView view;
  final List<Citation> citations;
  bool get isEmpty => chips.isEmpty && citations.isEmpty;
  bool get hasChips => chips.isNotEmpty;
  bool get hasCitations => citations.isNotEmpty;
}

MsgTraceView msgTraceViewForReq(ChatConn conn, {required String reqId}) {
  final logs = conn.traceCacheGet(reqId);
  final view = buildTraceView(logs);
  final citations = citationsFromTraceLogs(logs);
  return MsgTraceView(chips: traceToolChipsFromView(view), view: view, citations: citations);
}

class UiMsgTraceLoader extends StatefulWidget {
  const UiMsgTraceLoader({
    super.key,
    required this.conn,
    required this.reqId,
    this.compact = true,
    this.live = false,
    this.part = MsgTracePart.all,
  });
  final ChatConn conn;
  final String reqId;
  final bool compact;
  final bool live;
  final MsgTracePart part;

  @override
  State<UiMsgTraceLoader> createState() => _UiMsgTraceLoaderState();
}

class _UiMsgTraceLoaderState extends State<UiMsgTraceLoader> {
  MsgTraceView? _view;
  var _loading = false;
  Timer? _poll;
  StreamSubscription<String>? _traceSub;
  var _idlePollTicks = 0;

  @override
  void initState() {
    super.initState();
    _traceSub = widget.conn.onTraceCachePut.listen((reqId) {
      if (reqId == widget.reqId.trim()) unawaited(_load());
    });
    unawaited(_load());
    _syncPoll();
  }

  @override
  void didUpdateWidget(covariant UiMsgTraceLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conn != widget.conn) {
      _traceSub?.cancel();
      _traceSub = widget.conn.onTraceCachePut.listen((reqId) {
        if (reqId == widget.reqId.trim()) unawaited(_load());
      });
    }
    if (oldWidget.live && !widget.live) {
      _poll?.cancel();
      _poll = null;
      _idlePollTicks = 0;
      _loading = false;
    }
    if (oldWidget.reqId != widget.reqId || oldWidget.live != widget.live || oldWidget.part != widget.part) unawaited(_load());
    _syncPoll();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _traceSub?.cancel();
    super.dispose();
  }

  bool _partEmpty(MsgTraceView view) => switch (widget.part) {
        MsgTracePart.chips => !view.hasChips,
        MsgTracePart.citations => !view.hasCitations,
        MsgTracePart.all => view.isEmpty,
      };

  void _syncPoll() {
    final needsPoll = widget.live || _view == null || _partEmpty(_view!);
    if (!needsPoll) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    if (_poll != null) return;
    if (widget.live) _idlePollTicks = 0;
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!widget.live) _idlePollTicks++;
      unawaited(_load());
      if (!widget.live && (_idlePollTicks >= 8 || (_view != null && !_partEmpty(_view!)))) {
        _poll?.cancel();
        _poll = null;
      }
    });
  }

  Future<void> _load() async {
    final reqId = widget.reqId.trim();
    if (reqId.isEmpty) return;
    var view = msgTraceViewForReq(widget.conn, reqId: reqId);
    final cacheEmpty = view.isEmpty;
    final partMissing = _partEmpty(view);
    final needsFetch = cacheEmpty || (widget.live && partMissing);
    if (needsFetch) {
      if (mounted && !_loading) setState(() => _loading = true);
      await widget.conn.tracePrefetch(reqId, force: cacheEmpty);
      view = msgTraceViewForReq(widget.conn, reqId: reqId);
    }
    if (!mounted) return;
    if (_loading) setState(() => _loading = false);
    if (_partEmpty(view) && !widget.live) {
      setState(() => _view = view);
      _syncPoll();
      return;
    }
    if (_partEmpty(view) && widget.live) {
      _syncPoll();
      return;
    }
    final prev = _view;
    final changed = prev == null ||
        prev.chips.length != view.chips.length ||
        prev.citations.length != view.citations.length ||
        (prev.chips.isNotEmpty && view.chips.isNotEmpty && prev.chips.last.label != view.chips.last.label) ||
        (widget.part == MsgTracePart.citations &&
            prev.citations.length == view.citations.length &&
            prev.citations.isNotEmpty &&
            view.citations.isNotEmpty &&
            prev.citations.last.url != view.citations.last.url);
    if (!changed) {
      _syncPoll();
      return;
    }
    setState(() => _view = view);
    _syncPoll();
  }

  bool _hideToolTraceWhenIdle() =>
      !widget.live && widget.part != MsgTracePart.citations && !PromptUsagePrefs.instance.showUsageStats;

  Widget _buildBody() {
    if (_hideToolTraceWhenIdle()) return const SizedBox.shrink();
    final v = _view;
    if (v == null || _partEmpty(v)) return const SizedBox.shrink();
    return UiMsgTraceView(view: v, compact: widget.compact, live: widget.live, part: widget.part);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.part == MsgTracePart.citations) return _buildBody();
    return ListenableBuilder(listenable: PromptUsagePrefs.instance, builder: (context, _) => _buildBody());
  }
}

class UiMsgTraceView extends StatelessWidget {
  const UiMsgTraceView({super.key, required this.view, this.compact = true, this.live = false, this.part = MsgTracePart.all});
  final MsgTraceView view;
  final bool compact;
  final bool live;
  final MsgTracePart part;

  @override
  Widget build(BuildContext context) {
    final showChips = part == MsgTracePart.chips || part == MsgTracePart.all;
    final showCitations = part == MsgTracePart.citations || part == MsgTracePart.all;
    if ((showChips && view.chips.isEmpty) && (showCitations && view.citations.isEmpty)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showChips && view.chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: view.chips.map((t) => UiMsgTraceToolChip(chip: t, compact: compact)).toList(),
            ),
          ),
        if (showCitations && view.citations.isNotEmpty)
          UiCitationChips(
            citations: view.citations,
            marginTop: part == MsgTracePart.citations ? 12 : 6,
          ),
      ],
    );
  }
}

class UiTraceScreenshotPreview extends StatelessWidget {
  const UiTraceScreenshotPreview({super.key, required this.screenshot, this.maxWidth = 280});

  final TraceScreenshot screenshot;
  final double maxWidth;

  static const _muted = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    final src = screenshot.imageSrc;
    if (src.isEmpty) return const SizedBox.shrink();
    final dim = screenshot.width > 0 && screenshot.height > 0 ? '${screenshot.width}×${screenshot.height}' : '';
    final flags = [
      if (screenshot.som) 'SoM',
      if (screenshot.marker) 'marker',
    ].join(' · ');
    final caption = [dim, flags].where((s) => s.isNotEmpty).join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: UiImg(
              src: src,
              fit: BoxFit.contain,
              width: maxWidth,
              fallback: const SizedBox(
                height: 80,
                child: Center(child: Icon(Icons.broken_image_outlined, size: 20, color: _muted)),
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(caption, style: const TextStyle(color: _muted, fontSize: 10, height: 1.2)),
          ),
      ],
    );
  }
}

class UiMsgTraceToolChip extends StatefulWidget {
  const UiMsgTraceToolChip({super.key, required this.chip, this.compact = true});

  final MsgTraceToolChip chip;
  final bool compact;

  @override
  State<UiMsgTraceToolChip> createState() => _UiMsgTraceToolChipState();
}

class _UiMsgTraceToolChipState extends State<UiMsgTraceToolChip> {
  static const _muted = Color(0xFF71717A);
  static const _text = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);
  static const _error = Color(0xFFEF4444);

  var _previewExpanded = false;

  @override
  Widget build(BuildContext context) {
    final chip = widget.chip;
    final compact = widget.compact;
    final ms = uiFmtDurationMs(chip.durationMs);
    final canPreview = chip.hasScreenshotPreview;
    final maxW = compact ? 240.0 : 280.0;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _chipIcon(chip),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    chip.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(color: _text, fontSize: 12, height: 1.2),
                  ),
                ),
                if (ms.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(ms, style: const TextStyle(color: _muted, fontSize: 12, height: 1.2)),
                ],
                if (canPreview) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() => _previewExpanded = !_previewExpanded),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        _previewExpanded ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                        size: 16,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_previewExpanded && canPreview && chip.screenshot != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: UiTraceScreenshotPreview(screenshot: chip.screenshot!, maxWidth: maxW - 4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chipIcon(MsgTraceToolChip chip) {
    if (!chip.ok) return const Icon(Icons.error_outline, size: 14, color: _error);
    if (chip.iconUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.network(
          chip.iconUrl,
          width: 14,
          height: 14,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.public, size: 14, color: _muted),
        ),
      );
    }
    return const Icon(Icons.check_circle_outline, size: 14, color: _muted);
  }
}
