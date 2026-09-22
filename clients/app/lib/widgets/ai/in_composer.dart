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
    this.models = const [AgentModel.alien],
    this.modelsLoading = false,
    this.onAbort,
    this.hint = 'Message Alien AI…',
    this.enabled = true,
    this.busy = false,
    this.mentions = const [],
    this.selectedMentionIds = const {},
    this.toolMode,
    this.onMentionToggle,
    this.onMentionSearch,
    this.onToolModeToggle,
  });

  final void Function(String text, List<MsgAttachment> attachments) onSend;
  final AgentModel model;
  final ValueChanged<AgentModel> onModel;
  final List<AgentModel> models;
  final bool modelsLoading;
  final VoidCallback? onAbort;
  final String hint;
  final bool enabled;
  final bool busy;
  final List<CatalogMention> mentions;
  final Set<String> selectedMentionIds;
  final String? toolMode;
  final void Function(String id)? onMentionToggle;
  final Future<List<CatalogMention>> Function(String q)? onMentionSearch;
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
  Timer? _mentionSearchDebounce;
  List<CatalogMention> _mentionSearchResults = const [];
  var _mentionSearching = false;

  bool get _hasText => _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
  bool get _canSubmit => widget.enabled && !widget.busy && !_submitting && !_recording && _hasText;
  String get _hintText => _recording ? 'Listening…' : widget.hint;
  bool get _askActive => widget.toolMode == 'ask';
  List<CatalogMention> get _composerMentions => widget.mentions.where((m) => m.id != 'image').toList(growable: false);
  bool get _hasSelectedMentions => widget.selectedMentionIds.any((id) => id != 'image');

  String? get _activeMentionQuery {
    final sel = _controller.selection;
    if (!sel.isValid || sel.baseOffset < 0 || sel.baseOffset > _controller.text.length) return null;
    final textBefore = _controller.text.substring(0, sel.baseOffset);
    final match = RegExp(r'@([a-zA-Z0-9_\-\.]*)$').firstMatch(textBefore);
    return match?.group(1);
  }

  void _pickMention(CatalogMention m) {
    widget.onMentionToggle?.call(m.id);
    final sel = _controller.selection;
    if (sel.isValid && sel.baseOffset >= 0 && sel.baseOffset <= _controller.text.length) {
      final textBefore = _controller.text.substring(0, sel.baseOffset);
      final textAfter = _controller.text.substring(sel.baseOffset);
      final atIndex = textBefore.lastIndexOf('@');
      if (atIndex >= 0) {
        final newText = textBefore.substring(0, atIndex) + textAfter;
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: atIndex);
      }
    }
    setState(() {});
    _focus.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    _focus.onKeyEvent = _onKeyEvent;
  }

  @override
  void dispose() {
    _mentionSearchDebounce?.cancel();
    if (_recording || SttService.instance.isRecording.value) unawaited(SttService.instance.cancel());
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scheduleMentionSearch(String? query) {
    _mentionSearchDebounce?.cancel();
    if (query == null || widget.onMentionSearch == null) {
      if (_mentionSearchResults.isNotEmpty || _mentionSearching) {
        setState(() {
          _mentionSearchResults = const [];
          _mentionSearching = false;
        });
      }
      return;
    }
    final q = query;
    if (q.isEmpty) {
      if (_mentionSearchResults.isNotEmpty || _mentionSearching) {
        setState(() {
          _mentionSearchResults = const [];
          _mentionSearching = false;
        });
      }
      return;
    }
    _mentionSearchDebounce = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) return;
      setState(() => _mentionSearching = true);
      try {
        final results = await widget.onMentionSearch!(q);
        if (!mounted) return;
        setState(() {
          _mentionSearchResults = results;
          _mentionSearching = false;
        });
      } catch (_) {
        if (mounted) setState(() => _mentionSearching = false);
      }
    });
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
    final tools = _composerMentions.where((m) => !m.isDevice).toList();
    final devices = _composerMentions.where((m) => m.isDevice).toList();
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
                if (tools.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFF27272A)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Tools', style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.w600))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in tools)
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
                if (devices.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFF27272A)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Devices', style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.w600))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in devices)
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
      final err = SttService.instance.lastTranscribeError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'No speech detected'),
        behavior: SnackBarBehavior.floating,
      ));
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

  Widget _mentionSuggestionsBox() {
    final query = _activeMentionQuery;
    if (query == null || widget.onMentionToggle == null) return const SizedBox.shrink();
    final q = query.toLowerCase();
    final matches = (q.isNotEmpty && widget.onMentionSearch != null)
        ? _mentionSearchResults
        : _composerMentions.where((m) {
            final label = m.displayLabel;
            return m.id.toLowerCase().contains(q) || label.toLowerCase().contains(q);
          }).take(6).toList(growable: false);
    if (matches.isEmpty && !_mentionSearching) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46)),
      ),
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: matches.length + (_mentionSearching ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF3F3F46)),
        itemBuilder: (context, i) {
          if (i >= matches.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final m = matches[i];
          final label = m.displayLabel;
          final caption = m.displayCaption;
          final isDev = m.isDevice;
          final selected = widget.selectedMentionIds.contains(m.id);
          return InkWell(
            onTap: () => _pickMention(m),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isDev ? Icons.computer_rounded : Icons.alternate_email_rounded,
                    size: 16,
                    color: isDev ? const Color(0xFF38BDF8) : const Color(0xFFA1A1AA),
                  ),
                  const SizedBox(width: 8),
                  Text('@$label', style: const TextStyle(color: zinc100, fontSize: 13, fontWeight: FontWeight.w500)),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(caption, style: const TextStyle(color: zinc500, fontSize: 11)),
                  ],
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_rounded, size: 16, color: Color(0xFF22C55E)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectedMentionRow() {
    if ((!_hasSelectedMentions && !_askActive) || widget.onMentionToggle == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ValueListenableBuilder<int>(
        valueListenable: catalogTranslationTick,
        builder: (context, _, __) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_askActive)
              _AskChip(
                label: catalogT('composer.ask.label'),
                caption: catalogT('composer.ask.caption'),
                onTap: widget.onToolModeToggle,
              ),
            for (final m in _composerMentions.where((m) => widget.selectedMentionIds.contains(m.id)))
              _MentionChip(mention: m, selected: true, onTap: () => widget.onMentionToggle!(m.id)),
          ],
        ),
      ),
    );
  }

  static const _attachBtnWidth = 40.0;
  static const _actionBtnWidth = 38.0;
  static const _modelChipWidth = 150.0;
  static const _inlineMinWidth = 300.0;

  bool _shouldUseStackedLayout(BuildContext context, double totalWidth) {
    if (totalWidth < _inlineMinWidth) return true;
    if (_controller.text.contains('\n')) return true;
    final textWidth = totalWidth - _attachBtnWidth - _modelChipWidth - _actionBtnWidth - 24;
    if (textWidth <= 48) return true;
    final painter = TextPainter(
      text: TextSpan(
        text: _controller.text.isEmpty ? ' ' : _controller.text,
        style: const TextStyle(fontSize: 14, height: 1.35),
      ),
      textDirection: Directionality.of(context),
      maxLines: 6,
    );
    painter.layout(maxWidth: textWidth);
    return painter.computeLineMetrics().length > 1;
  }

  VoidCallback? _modelTap() => widget.enabled
      ? () async {
          final next = await agentModelPick(context, widget.model, widget.models, modelsLoading: widget.modelsLoading);
          if (next != null) widget.onModel(next);
        }
      : null;

  Widget _attachButton() => uiIconButton(
        tooltip: 'Attach',
        onPressed: widget.enabled && !widget.busy ? _attach : null,
        icon: const Icon(Icons.attach_file_rounded, size: 20, color: zinc500),
        style: IconButton.styleFrom(minimumSize: const Size(_attachBtnWidth, _attachBtnWidth), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
      );

  Widget _modelChip() => UiAssistantModelChip(model: widget.model, onTap: _modelTap());

  Widget _actionButton() => _ActionButton(kind: composerActionKind(streaming: widget.busy, recording: _recording, hasText: _hasText), onAction: _onAction);

  Widget _textField({required bool stacked}) => TextField(
        key: const ValueKey('composer_text_field'),
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled && !widget.busy && !_recording,
        minLines: 1,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        style: const TextStyle(color: zinc100, fontSize: 14, height: 1.35),
        cursorColor: zinc100,
        onChanged: (_) {
          final hadFocus = _focus.hasFocus;
          _scheduleMentionSearch(_activeMentionQuery);
          setState(() {});
          if (hadFocus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _focus.canRequestFocus) _focus.requestFocus();
            });
          }
        },
        decoration: InputDecoration(
          hintText: _hintText,
          hintStyle: const TextStyle(color: zinc500, fontSize: 14, height: 1.35),
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(4, 8, 4, stacked ? 4 : 8),
        ),
      );

  Widget _inputArea(double maxWidth) {
    final stacked = _shouldUseStackedLayout(context, maxWidth);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!stacked) _attachButton(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(stacked ? 4 : 0, 0, stacked ? 4 : 0, 0),
                child: _textField(stacked: stacked),
              ),
            ),
            if (!stacked) ...[
              _modelChip(),
              const SizedBox(width: 4),
              _actionButton(),
            ],
          ],
        ),
        if (stacked)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              children: [
                _attachButton(),
                _modelChip(),
                const Spacer(),
                _actionButton(),
              ],
            ),
          ),
      ],
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
          _mentionSuggestionsBox(),
          _selectedMentionRow(),
          _attachmentRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: LayoutBuilder(builder: (context, constraints) => _inputArea(constraints.maxWidth)),
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

class _AskChip extends StatelessWidget {
  const _AskChip({required this.label, required this.caption, this.onTap});

  final String label;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text('@$label'),
        tooltip: caption,
        selected: true,
        onSelected: (_) => onTap?.call(),
        showCheckmark: false,
        labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
        selectedColor: const Color(0xFF60A5FA),
        backgroundColor: const Color(0xFF1A1A1D),
        side: const BorderSide(color: Color(0xFF27272A)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
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
    final label = mention.displayLabel;
    final caption = mention.displayCaption;
    final isDevice = mention.isDevice;
    Widget? avatar;
    if (isDevice) {
      avatar = Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: _chipColor,
          shape: BoxShape.circle,
        ),
      );
    }
    return FilterChip(
      avatar: avatar,
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
