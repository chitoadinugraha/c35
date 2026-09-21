import 'dart:async';
import 'dart:io';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/catalog/catalog_translation_cache.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/widgets/ai/composer_action.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_model_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_staged_shot.dart';
import 'package:alienai_c35/widgets/media/in_media.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

const zinc100 = Color(0xFFF4F4F5);
const zinc500 = Color(0xFF71717A);

class InComposer extends StatefulWidget {
  const InComposer({
    super.key,
    required this.onSend,
    required this.model,
    required this.onModel,
    this.models = AgentModel.fallback,
    this.onAbort,
    this.hint = 'Message Alien AI…',
    this.enabled = true,
    this.busy = false,
    this.mentions = const [],
    this.selectedMentionIds = const {},
    this.toolMode,
    this.onMentionToggle,
    this.onToolModeToggle,
  });

  final void Function(String text, List<MsgAttachment> attachments) onSend;
  final AgentModel model;
  final ValueChanged<AgentModel> onModel;
  final List<AgentModel> models;
  final VoidCallback? onAbort;
  final String hint;
  final bool enabled;
  final bool busy;
  final List<CatalogMention> mentions;
  final Set<String> selectedMentionIds;
  final String? toolMode;
  final void Function(String id)? onMentionToggle;
  final VoidCallback? onToolModeToggle;

  @override
  State<InComposer> createState() => _InComposerState();
}

class _InComposerState extends State<InComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _attachments = <StagedMedia>[];
  var _focused = false;
  var _recording = false;
  var _submitting = false;

  bool get _hasText => _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
  bool get _canSubmit => widget.enabled && !widget.busy && !_submitting && !_recording && _hasText;
  String get _hintText => _recording ? 'Listening…' : widget.hint;
  bool get _askActive => widget.toolMode == 'ask';
  List<CatalogMention> get _composerMentions => widget.mentions.where((m) => m.id != 'image').toList(growable: false);
  bool get _hasSelectedMentions => widget.selectedMentionIds.any((id) => id != 'image');

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    _focus.onKeyEvent = _onKeyEvent;
  }

  @override
  void dispose() {
    if (_recording || SttService.instance.isRecording.value) unawaited(SttService.instance.cancel());
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed && _canSubmit) {
      unawaited(_submit());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyV && (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
      unawaited(_pasteClipboard());
    }
    return KeyEventResult.ignored;
  }

  Future<void> _pasteClipboard() async {
    if (!widget.enabled || widget.busy) return;
    final image = await Pasteboard.image;
    if (image != null && image.isNotEmpty) {
      _stageItems([StagedMedia(name: 'pasted_image.png', bytes: image, mime: 'image/png', type: MediaType.image, size: image.length, uploadProgress: 0.05)]);
      return;
    }
    final files = await Pasteboard.files();
    if (files.isEmpty) return;
    final staged = <StagedMedia>[];
    for (final path in files.take(defaultMaxMediaFiles - _attachments.length)) {
      try {
        final bytes = await File(path).readAsBytes();
        if (bytes.isEmpty) continue;
        final name = path.split(RegExp(r'[\\/]')).last;
        final mime = mimeForFilename(name);
        staged.add(StagedMedia(name: name, bytes: bytes, mime: mime, type: mediaTypeForMime(mime), size: bytes.length, uploadProgress: 0.05));
      } catch (_) {}
    }
    if (staged.isNotEmpty) _stageItems(staged);
  }

  void _stageItems(List<StagedMedia> items) {
    if (!mounted || items.isEmpty) return;
    setState(() => _attachments.addAll(items));
    for (final item in items) {
      unawaited(_uploadItem(item));
    }
  }

  void _replaceItem(int i, StagedMedia next) {
    if (!mounted || i < 0 || i >= _attachments.length) return;
    setState(() => _attachments[i] = next);
    unawaited(_uploadItem(next));
  }

  Future<void> _uploadItem(StagedMedia item) async {
    if (item.bytes.isEmpty) return;
    try {
      final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name, onProgress: (p) {
        if (!mounted) return;
        final i = _attachments.indexWhere((m) => m.id == item.id);
        if (i >= 0) setState(() => _attachments[i] = _attachments[i].copyWith(uploadProgress: p));
      });
      if (!mounted || res == null) return;
      final i = _attachments.indexWhere((m) => m.id == item.id);
      if (i >= 0) setState(() => _attachments[i] = _attachments[i].copyWith(hash: res.hash, uploadProgress: 1.0));
    } catch (_) {
      if (!mounted) return;
      final i = _attachments.indexWhere((m) => m.id == item.id);
      if (i >= 0) setState(() => _attachments[i] = _attachments[i].copyWith(uploadProgress: null));
    }
  }

  Future<void> _attachImage() async {
    final picked = await askMedia(types: const [MediaType.image], allowMultiple: true);
    if (picked != null) _stageItems(picked.map((m) => m.copyWith(uploadProgress: 0.05)).toList());
  }

  Future<void> _attachFile() async {
    final picked = await askMedia(types: const [MediaType.document, MediaType.any], allowMultiple: true);
    if (picked != null) _stageItems(picked.map((m) => m.copyWith(uploadProgress: 0.05)).toList());
  }

  Future<void> _attach() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: catalogTranslationTick,
          builder: (context, _, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.image_outlined, color: zinc100), title: const Text('Image', style: TextStyle(color: zinc100)), onTap: () => Navigator.pop(ctx, 'image')),
              ListTile(leading: const Icon(Icons.attach_file_rounded, color: zinc100), title: const Text('File', style: TextStyle(color: zinc100)), onTap: () => Navigator.pop(ctx, 'file')),
              if (widget.onToolModeToggle != null)
                ListTile(
                  leading: Icon(_askActive ? Icons.chat_bubble_outline : Icons.question_answer_outlined, color: zinc100),
                  title: Text(_askActive ? 'Disable ${catalogT('composer.ask.label')}' : catalogT('composer.ask.label'), style: const TextStyle(color: zinc100)),
                  subtitle: Text(catalogT('composer.ask.caption'), style: const TextStyle(color: zinc500, fontSize: 12)),
                  onTap: () => Navigator.pop(ctx, 'ask'),
                ),
              if (widget.onMentionToggle != null && _composerMentions.isNotEmpty) ...[
                const Divider(height: 1, color: Color(0xFF27272A)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Tools', style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.w600))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final m in _composerMentions)
                        _MentionChip(
                          mention: m,
                          selected: widget.selectedMentionIds.contains(m.id),
                          onTap: () {
                            widget.onMentionToggle!(m.id);
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (action == 'image') await _attachImage();
    if (action == 'file') await _attachFile();
    if (action == 'ask') widget.onToolModeToggle?.call();
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    _submitting = true;

    final text = _controller.text.trim();
    final atts = <MsgAttachment>[];
    for (var item in _attachments) {
      if ((item.hash == null || item.hash!.isEmpty) && item.bytes.isNotEmpty) {
        final res = await casUpload(bytes: item.bytes, mime: item.mime, name: item.name);
        if (res != null) item = item.copyWith(hash: res.hash, uploadProgress: 1.0);
      }
      if (item.bytes.isNotEmpty || (item.hash != null && item.hash!.isNotEmpty)) {
        atts.add(MsgAttachment.fromStaged(item));
      }
    }

    if (text.isEmpty && atts.isEmpty) {
      _submitting = false;
      return;
    }

    _controller.clear();
    _attachments.clear();
    setState(() {});

    try {
      widget.onSend(text, atts);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      } else {
        _submitting = false;
      }
    }
  }

  Future<void> _startMic() async {
    if (!widget.enabled || widget.busy || _recording) return;
    final ok = await SttService.instance.startRecording();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(SttService.instance.lastStartError ?? sttMicErrorMessage()), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _recording = true);
    _focus.requestFocus();
  }

  Future<void> _stopMic() async {
    if (!_recording) return;
    final text = await SttService.instance.stopAndTranscribe(lang: VoicePrefs.instance.speechLang);
    if (!mounted) return;
    setState(() => _recording = false);
    final transcript = text?.trim() ?? '';
    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No speech detected'), behavior: SnackBarBehavior.floating));
      return;
    }
    final cur = _controller.text;
    final sep = cur.isEmpty || cur.endsWith(' ') || cur.endsWith('\n') ? '' : ' ';
    _controller.text = '$cur$sep$transcript';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    setState(() {});
    _focus.requestFocus();
  }

  void _onAction() {
    final kind = composerActionKind(streaming: widget.busy, recording: _recording, hasText: _hasText);
    if (kind == ComposerActionKind.abort) {
      widget.onAbort?.call();
      return;
    }
    if (kind == ComposerActionKind.recStop) {
      unawaited(_stopMic());
      return;
    }
    if (kind == ComposerActionKind.send) {
      unawaited(_submit());
      return;
    }
    if (kind == ComposerActionKind.mic) unawaited(_startMic());
  }

  Widget _selectedMentionRow() {
    if (!_hasSelectedMentions || widget.onMentionToggle == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ValueListenableBuilder<int>(
        valueListenable: catalogTranslationTick,
        builder: (context, _, __) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in _composerMentions.where((m) => widget.selectedMentionIds.contains(m.id)))
              _MentionChip(mention: m, selected: true, onTap: () => widget.onMentionToggle!(m.id)),
          ],
        ),
      ),
    );
  }

  Widget _attachmentRow() {
    if (_attachments.isEmpty) return const SizedBox.shrink();
    final docs = <StagedMedia>[];
    final images = <StagedMedia>[];
    for (final a in _attachments) {
      (a.isImage ? images : docs).add(a);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (images.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _attachments.length; i++)
                  if (_attachments[i].isImage)
                    UiStagedShot(
                      item: _attachments[i],
                      onRemove: widget.enabled && !widget.busy ? () => setState(() => _attachments.removeAt(i)) : null,
                      onReplace: widget.enabled && !widget.busy ? (next) => _replaceItem(i, next) : null,
                    ),
              ],
            ),
          if (docs.isNotEmpty) ...[
            if (images.isNotEmpty) const SizedBox(height: 8),
            InMedia(
              items: docs,
              compact: true,
              enabled: !widget.busy,
              onRemove: (i) {
                final doc = docs[i];
                final idx = _attachments.indexWhere((m) => m.id == doc.id);
                if (idx >= 0) setState(() => _attachments.removeAt(idx));
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = _focused ? const Color(0xFF3F3F46) : const Color(0xFF27272A);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(color: const Color(0xFF18181B), borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _selectedMentionRow(),
          _attachmentRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                uiIconButton(
                  tooltip: 'Attach',
                  onPressed: widget.enabled && !widget.busy ? _attach : null,
                  icon: const Icon(Icons.attach_file_rounded, size: 20, color: zinc500),
                  style: IconButton.styleFrom(minimumSize: const Size(40, 40), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    enabled: widget.enabled && !widget.busy && !_recording,
                    minLines: 1,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(color: zinc100, fontSize: 14, height: 1.35),
                    cursorColor: zinc100,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _hintText,
                      hintStyle: const TextStyle(color: zinc500, fontSize: 14, height: 1.35),
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ),
                ),
                UiAssistantModelChip(
                  model: widget.model,
                  onTap: widget.enabled
                      ? () async {
                          final next = await agentModelPick(context, widget.model, widget.models);
                          if (next != null) widget.onModel(next);
                        }
                      : null,
                ),
                const SizedBox(width: 4),
                _ActionButton(kind: composerActionKind(streaming: widget.busy, recording: _recording, hasText: _hasText), onAction: _onAction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.kind, required this.onAction});

  static const _size = 34.0;
  final ComposerActionKind kind;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _size,
        height: _size,
        child: switch (kind) {
          ComposerActionKind.abort || ComposerActionKind.recStop => IconButton(icon: const Icon(Icons.stop_rounded), color: const Color(0xFFEF4444), iconSize: 20, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: _size, minHeight: _size), onPressed: onAction),
          ComposerActionKind.send => GestureDetector(onTap: onAction, child: Container(width: _size, height: _size, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFF4F4F5), shape: BoxShape.circle), child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF18181B), size: 17))),
          ComposerActionKind.mic => IconButton(icon: const Icon(Icons.mic_rounded), color: const Color(0xFF9CA3AF), iconSize: 20, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: _size, minHeight: _size), onPressed: onAction),
        },
      );
}

class _MentionChip extends StatelessWidget {
  const _MentionChip({required this.mention, required this.selected, required this.onTap});

  final CatalogMention mention;
  final bool selected;
  final VoidCallback onTap;

  Color get _chipColor {
    final s = mention.color.trim();
    if (s.isEmpty) return const Color(0xFF22C55E);
    var hex = s.startsWith('#') ? s.substring(1) : s;
    if (hex.length == 6) hex = 'FF$hex';
    final v = int.tryParse(hex, radix: 16);
    return v == null ? const Color(0xFF22C55E) : Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final label = mention.labelKey.isNotEmpty ? catalogT(mention.labelKey) : mention.id;
    final caption = mention.captionKey.isNotEmpty ? catalogT(mention.captionKey) : '';
    return FilterChip(
      label: Text('@$label'),
      tooltip: caption.isNotEmpty ? caption : label,
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(color: selected ? Colors.black : zinc100, fontSize: 12),
      selectedColor: _chipColor,
      backgroundColor: const Color(0xFF1A1A1D),
      side: const BorderSide(color: Color(0xFF27272A)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
