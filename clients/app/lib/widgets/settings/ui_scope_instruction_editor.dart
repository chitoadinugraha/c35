import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

const _modes = ['always', 'auto', 'disabled'];

String scopeInstructionModeLabel(String mode) {
  switch (mode) {
    case 'always':
      return 'Always';
    case 'auto':
      return 'Auto';
    case 'disabled':
    default:
      return 'Disabled';
  }
}

/// Shared assistant-instruction editor (user Settings or site Settings).
class UiScopeInstructionEditor extends StatefulWidget {
  const UiScopeInstructionEditor({
    super.key,
    required this.conn,
    required this.scopeKind,
    required this.scopeIid,
    this.title = 'Assistant instructions',
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  final ChatConn conn;
  final String scopeKind;
  final int scopeIid;
  final String title;
  final String? subtitle;
  final EdgeInsets padding;

  @override
  State<UiScopeInstructionEditor> createState() => _UiScopeInstructionEditorState();
}

class _UiScopeInstructionEditorState extends State<UiScopeInstructionEditor> {
  late final _bodyCtrl = TextEditingController();
  var _loading = true;
  var _saving = false;
  String? _error;
  String _mode = 'disabled';
  Timer? _saveTimer;
  var _suppress = false;

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(_onBodyChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiScopeInstructionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scopeIid != widget.scopeIid || oldWidget.scopeKind != widget.scopeKind) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.conn.scopeInstructionGet(
        scopeKind: widget.scopeKind,
        scopeIid: widget.scopeIid,
      );
      final inst = res.instruction;
      _suppress = true;
      _mode = inst.mode.isEmpty ? 'disabled' : inst.mode;
      _bodyCtrl.text = inst.body;
      _suppress = false;
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onBodyChanged() {
    if (_suppress || _loading) return;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () => unawaited(_save()));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final res = await widget.conn.scopeInstructionPut(
        scopeKind: widget.scopeKind,
        scopeIid: widget.scopeIid,
        mode: _mode,
        body: _bodyCtrl.text,
      );
      final inst = res.instruction;
      if (inst.mode.isNotEmpty) _mode = inst.mode;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setMode(String mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: widget.padding,
        child: const Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: widget.padding,
        child: Text(_error!, style: const TextStyle(color: Color(0xFFFECACA), fontSize: 12)),
      );
    }
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!, style: const TextStyle(color: _muted, fontSize: 12, height: 1.35)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ModeDropdown(mode: _mode, enabled: !_saving, onChanged: _setMode),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyCtrl,
            minLines: 3,
            maxLines: 8,
            style: const TextStyle(color: _text, fontSize: 13, height: 1.4),
            decoration: UiInputDecoration.of(
              context,
              hintText: 'How should the assistant behave?',
            ).copyWith(
              filled: true,
              fillColor: const Color(0xFF121214),
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Saving...', style: TextStyle(color: _muted, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _ModeDropdown extends StatelessWidget {
  const _ModeDropdown({required this.mode, required this.enabled, required this.onChanged});

  final String mode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121214),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _modes.contains(mode) ? mode : 'disabled',
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 18, color: _muted),
          style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
          items: _modes
              .map((m) => DropdownMenuItem(value: m, child: Text(scopeInstructionModeLabel(m))))
              .toList(growable: false),
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
        ),
      ),
    );
  }
}

/// User-scoped editor for Settings page.
class UiUserScopeInstructionEditor extends StatelessWidget {
  const UiUserScopeInstructionEditor({super.key, required this.conn});

  final ChatConn conn;

  @override
  Widget build(BuildContext context) {
    final uid = Session.instance.uid;
    return UiScopeInstructionEditor(
      conn: conn,
      scopeKind: 'user',
      scopeIid: uid,
      title: 'Instructions',
      subtitle: 'Included in Home chat per mode: Always, Auto (keyword match), or Disabled.',
    );
  }
}
