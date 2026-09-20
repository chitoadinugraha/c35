import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_shares.dart';
import 'package:flutter/material.dart';

class UiReferralShareInput extends StatefulWidget {
  const UiReferralShareInput({
    super.key,
    required this.value,
    required this.max,
    required this.parentId,
    required this.childId,
    required this.accountMap,
    required this.percentages,
    this.readonly = false,
    this.onChanged,
  });

  final int value;
  final int max;
  final int parentId;
  final int childId;
  final Map<int, ReferralTreeNode> accountMap;
  final Map<String, int> percentages;
  final bool readonly;
  final Future<void> Function(int value)? onChanged;

  @override
  State<UiReferralShareInput> createState() => _UiReferralShareInputState();
}

class _UiReferralShareInputState extends State<UiReferralShareInput> {
  final _anchorKey = GlobalKey();
  OverlayEntry? _overlay;
  var _saving = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    _saving = false;
  }

  void _togglePopover() {
    if (_overlay != null) {
      if (_saving) return;
      _removeOverlay();
      return;
    }
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    _overlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: _saving ? null : _removeOverlay, behavior: HitTestBehavior.opaque)),
          Positioned(
            left: (offset.dx + size.width - 260).clamp(8.0, MediaQuery.sizeOf(ctx).width - 268),
            top: (offset.dy + size.height + 4).clamp(8.0, MediaQuery.sizeOf(ctx).height - 240),
            width: 260,
            child: _ShareEditorPopover(
              initialValue: widget.value,
              max: widget.max,
              parentId: widget.parentId,
              childId: widget.childId,
              accountMap: widget.accountMap,
              percentages: widget.percentages,
              onConfirm: (v) async {
                _saving = true;
                _overlay?.markNeedsBuild();
                try {
                  await widget.onChanged?.call(v);
                  if (mounted) _removeOverlay();
                } catch (_) {
                  _saving = false;
                  _overlay?.markNeedsBuild();
                  rethrow;
                }
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      key: _anchorKey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3F3F46)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Text(
        '${widget.value}%',
        style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 11, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
      ),
    );
    if (widget.readonly) return child;
    return GestureDetector(onTap: _togglePopover, behavior: HitTestBehavior.opaque, child: child);
  }
}

class _ShareEditorPopover extends StatefulWidget {
  const _ShareEditorPopover({
    required this.initialValue,
    required this.max,
    required this.parentId,
    required this.childId,
    required this.accountMap,
    required this.percentages,
    required this.onConfirm,
  });

  final int initialValue;
  final int max;
  final int parentId;
  final int childId;
  final Map<int, ReferralTreeNode> accountMap;
  final Map<String, int> percentages;
  final Future<void> Function(int value) onConfirm;

  @override
  State<_ShareEditorPopover> createState() => _ShareEditorPopoverState();
}

class _ShareEditorPopoverState extends State<_ShareEditorPopover> {
  late int _draft = widget.initialValue;
  var _saving = false;
  String? _error;

  bool get _changed => _draft != widget.initialValue;

  List<ReferralShareKeepRow> get _keepChain =>
      referralShareKeepChain(widget.parentId, widget.childId, _draft, widget.accountMap, widget.percentages);

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirm(_draft);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF18181B);
    const text = Color(0xFFF4F4F5);
    const muted = Color(0xFFA1A1AA);
    const accent = Color(0xFF22C55E);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Share', style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w600))),
                Text(
                  '$_draft%',
                  style: const TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ],
            ),
            Slider(
              value: _draft.toDouble().clamp(0, widget.max.toDouble()),
              min: 0,
              max: widget.max.toDouble() <= 0 ? 1 : widget.max.toDouble(),
              divisions: widget.max > 0 ? widget.max : 1,
              label: '$_draft%',
              activeColor: accent,
              onChanged: _saving || widget.max <= 0 ? null : (v) => setState(() => _draft = v.round().clamp(0, widget.max)),
            ),
            if (_keepChain.isNotEmpty)
              ..._keepChain.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(row.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11)),
                      ),
                      Text(
                        '${row.percent}%',
                        style: const TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 11)),
            ],
            if (_changed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('OK'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
