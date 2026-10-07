import 'dart:async';
import 'dart:io';

import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/files/msg_attachment.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/widgets/ai/composer_attachment_history.dart';
import 'package:alienai_c35/widgets/ai/composer_mention_text.dart';
import 'package:alienai_c35/widgets/ai/composer_action.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_model_chip.dart';
import 'package:alienai_c35/widgets/ai/ui_audio_waveform.dart';
import 'package:alienai_c35/widgets/ai/ui_speak_indicator.dart';
import 'package:alienai_c35/widgets/ai/ui_staged_shot.dart';
import 'package:alienai_c35/widgets/media/in_media.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

const zinc100 = Color(0xFFF4F4F5);
const zinc500 = Color(0xFF71717A);
const _mentionIconGrey = Color(0xFFA1A1AA);

enum _MentionPickKind { image, file, mention }

class _MentionPickRow {
  const _MentionPickRow({required this.kind, this.mention});

  final _MentionPickKind kind;
  final CatalogMention? mention;
}

bool _mentionCatalogMatchesQuery(CatalogMention m, String q) {
  if (q.isEmpty) return true;
  final lq = q.toLowerCase();
  if (m.id.toLowerCase().contains(lq)) return true;
  if (m.displayLabel.toLowerCase().contains(lq)) return true;
  final cap = m.displayCaption;
  if (cap.isNotEmpty && cap.toLowerCase().contains(lq)) return true;
  return false;
}

bool _mentionQueryShowsImage(String q) => q.isEmpty || 'image'.contains(q.toLowerCase());

bool _mentionQueryShowsFile(String q) => q.isEmpty || 'file'.contains(q.toLowerCase());

Widget _mentionLeadingIcon(CatalogMention m) {
  if (m.isDevice) return const Icon(Icons.computer_rounded, size: 16, color: _mentionIconGrey);
  if (m.isSite) return const Icon(Icons.language_rounded, size: 16, color: _mentionIconGrey);
  if (m.id == 'image_high' || m.topicId == 'image') {
    return const Icon(Icons.image_outlined, size: 16, color: _mentionIconGrey);
  }
  final raw = m.icon.trim();
  if (raw.startsWith('iconify://') || (raw.contains(':') && !raw.contains(' '))) {
    return UiIcon(raw, size: 16, color: _mentionIconGrey, recolor: true);
  }
  return const Icon(Icons.alternate_email_rounded, size: 16, color: _mentionIconGrey);
}

class SlashCommand {
  const SlashCommand({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.rootOnly = false,
  });

  final String id;
  final String label;
  final String description;
  final IconData icon;
  final bool rootOnly;
}

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
    this.promptHistory = const [],
    this.onNewChat,
    this.controller,
    this.focusNode,
    this.showSpeakIndicator = true,
    this.followupRows = const [],
    this.onFollowupSteer,
    this.onFollowupRemove,
    this.viewerIsRoot = false,
    this.onTestMultitask,
    this.compact = false,
  });

  /// Bot / simple chat: attach + mic only — no @ mentions, model chip, slash menu, or follow-ups.
  final bool compact;

  final void Function(String text, List<MsgAttachment> attachments, {String? toolMode, List<String>? mentionIds, String? displayContent}) onSend;
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
  final List<String> promptHistory;
  final VoidCallback? onNewChat;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool showSpeakIndicator;
  final List<PromptFollowupRow> followupRows;
  final void Function(PromptFollowupRow row)? onFollowupSteer;
  final void Function(PromptFollowupRow row)? onFollowupRemove;
  final bool viewerIsRoot;
  final VoidCallback? onTestMultitask;

  @override
  State<InComposer> createState() => _InComposerState();
}

class _InComposerState extends State<InComposer> {
  TextEditingController? _internalController;
  TextEditingController get _controller => widget.controller ?? (_internalController ??= TextEditingController());

  String _preRecordingDraft = '';

  void _onLiveTranscript() {
    if (!mounted || !_recording) return;
    final live = SttService.instance.liveTranscript.value.trim();
    if (live.isEmpty) return;
    final prefix = _preRecordingDraft.trim();
    final newText = prefix.isEmpty ? live : '$prefix $live';
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newText.length);
  }

  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());
  final _attachmentHistory = ComposerAttachmentHistory();
  List<StagedMedia> get _attachments => _attachmentHistory.current;
  var _composerLastEditAttachments = false;
  var _focused = false;
  var _recording = false;
  var _submitting = false;
  var _isDragging = false;
  var _historyIndex = -1;
  var _draftText = '';
  var _highlightedSlashIndex = 0;
  var _wasStacked = false;
  double _inputAreaWidth = 0;
  ComposerMentionSpanBuilder? _composerSpanBuilder;
  List<CatalogMention> _composerSpanBuilderMentions = const [];
  double _composerShellHeight = 0;
  final _composerShellKey = GlobalKey();
  final _mentionLayerLink = LayerLink();
  OverlayEntry? _mentionMenuOverlayEntry;
  final _mentionListScrollController = ScrollController();
  final Map<int, GlobalKey> _mentionMenuRowKeys = {};
  final _mentionMenuHighlight = ValueNotifier<int>(0);

  GlobalKey _mentionMenuRowKey(int index) => _mentionMenuRowKeys.putIfAbsent(index, GlobalKey.new);

  void _clearMentionMenuRowKeys() => _mentionMenuRowKeys.clear();

  static const _slashCommandsBase = [
    SlashCommand(
      id: 'ask',
      label: '/ask',
      description: 'Ask directly without tool execution',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    SlashCommand(
      id: 'model',
      label: '/model',
      description: 'Switch AI assistant model',
      icon: Icons.tune_rounded,
    ),
    SlashCommand(
      id: 'clear',
      label: '/clear',
      description: 'Start a new conversation',
      icon: Icons.add_comment_outlined,
    ),
  ];

  List<SlashCommand> get _slashCommands => [
        ..._slashCommandsBase,
        if (widget.viewerIsRoot)
          const SlashCommand(
            id: 'test-multitask',
            label: '/test-multitask',
            description: 'Root only',
            icon: Icons.hub_outlined,
            rootOnly: true,
          ),
      ];

  bool get _hasText => composerMentionTextNonempty(_textWithoutActiveMentionDraft) || _attachments.isNotEmpty;
  bool get _canSubmit => widget.enabled && !_submitting && !_recording && _hasText;
  String get _hintText => _recording ? 'composer.listening'.tr() : (widget.busy ? 'Send follow-up' : widget.hint);
  bool get _askActive => widget.toolMode == 'ask';
  List<CatalogMention> get _composerMentions => widget.mentions
      .where((m) => m.id != 'image' && (!m.rootOnly || widget.viewerIsRoot))
      .toList(growable: false);

  Set<String> get _inlineMentionIds => composerMentionIdsParse(_controller.text).toSet();

  String? get _activeMentionQuery {
    final sel = _controller.selection;
    if (!sel.isValid || sel.baseOffset < 0 || sel.baseOffset > _controller.text.length) return null;
    final textBefore = _controller.text.substring(0, sel.baseOffset);
    final match = RegExp(r'@([a-zA-Z0-9_\-\.]*)$').firstMatch(textBefore);
    return match?.group(1);
  }

  bool get _mentionPickerActive => _activeMentionQuery != null;

  String get _textWithoutActiveMentionDraft {
    final sel = _controller.selection;
    if (_activeMentionQuery == null || !sel.isValid) return _controller.text;
    final textBefore = _controller.text.substring(0, sel.baseOffset);
    final textAfter = _controller.text.substring(sel.baseOffset);
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex < 0) return _controller.text;
    return textBefore.substring(0, atIndex) + textAfter;
  }

  String? get _activeSlashQuery {
    final sel = _controller.selection;
    if (!sel.isValid || sel.baseOffset < 1 || sel.baseOffset > _controller.text.length) return null;
    final textBefore = _controller.text.substring(0, sel.baseOffset);
    if (!textBefore.startsWith('/')) return null;
    if (textBefore.contains(' ')) return null;
    return textBefore.substring(1).toLowerCase();
  }

  List<SlashCommand> get _slashMatches {
    if (widget.compact) return const [];
    final q = _activeSlashQuery;
    if (q == null) return const [];
    if (q.isEmpty) return _slashCommands;
    return _slashCommands.where((c) => c.id.startsWith(q) || c.label.startsWith('/$q')).toList();
  }

  void _pickSlash(SlashCommand cmd) {
    if (cmd.id == 'ask') {
      _controller.text = '/ask ';
      _controller.selection = const TextSelection.collapsed(offset: 5);
    } else if (cmd.id == 'model') {
      _controller.clear();
      _modelTap()?.call();
    } else if (cmd.id == 'clear') {
      _controller.clear();
      widget.onNewChat?.call();
    } else if (cmd.id == 'test-multitask') {
      _controller.clear();
      widget.onTestMultitask?.call();
    }
    _highlightedSlashIndex = 0;
    setState(() {});
    _focus.requestFocus();
  }

  List<CatalogMention> get _mentionMatches {
    if (!_mentionPickerActive || widget.onMentionToggle == null) return const [];
    final q = _activeMentionQuery!.toLowerCase();
    return _composerMentions.where((m) => _mentionCatalogMatchesQuery(m, q)).take(20).toList(growable: false);
  }

  void _requestComposerFocus([int? cursorOffset]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.canRequestFocus) return;
      _focus.requestFocus();
      if (cursorOffset != null) {
        final len = _controller.text.length;
        _controller.selection = TextSelection.collapsed(offset: cursorOffset.clamp(0, len));
      }
    });
  }

  void _restoreComposerFocus([TextSelection? selection]) {
    final sel = selection ?? _controller.selection;
    void apply() {
      if (!mounted || !_focus.canRequestFocus) return;
      _focus.requestFocus();
      if (!sel.isValid) return;
      final len = _controller.text.length;
      _controller.selection = TextSelection(
        baseOffset: sel.baseOffset.clamp(0, len),
        extentOffset: sel.extentOffset.clamp(0, len),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      apply();
      if (defaultTargetPlatform != TargetPlatform.android || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        apply();
        if (_focus.hasFocus) {
          unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
        }
      });
    });
  }

  void _syncComposerStackedLayout(bool nextStacked) {
    if (nextStacked == _wasStacked) return;
    final hadFocus = _focus.hasFocus;
    final sel = _controller.selection;
    _wasStacked = nextStacked;
    if (hadFocus) _restoreComposerFocus(sel);
  }

  void _scheduleComposerStackedSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncComposerStackedLayout(_shouldUseStackedLayout(context, _inputAreaWidth));
    });
  }

  ComposerMentionSpanBuilder _composerSpecialTextSpanBuilder() {
    final mentions = _composerMentions;
    if (_composerSpanBuilder == null || !listEquals(_composerSpanBuilderMentions, mentions)) {
      _composerSpanBuilderMentions = mentions;
      _composerSpanBuilder = ComposerMentionSpanBuilder(mentions: mentions);
    }
    return _composerSpanBuilder!;
  }

  Widget _composerFieldChrome({required Widget child}) => ClipRect(
        child: Align(alignment: Alignment.topCenter, child: child),
      );

  void _clearActiveMentionQuery() {
    final sel = _controller.selection;
    if (!sel.isValid || sel.baseOffset < 0 || sel.baseOffset > _controller.text.length) return;
    final textBefore = _controller.text.substring(0, sel.baseOffset);
    final textAfter = _controller.text.substring(sel.baseOffset);
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex < 0) return;
    final newText = textBefore.substring(0, atIndex) + textAfter;
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: atIndex);
  }

  void _dismissMentionPicker() {
    _clearActiveMentionQuery();
    _removeMentionMenuOverlay();
    _clearMentionMenuRowKeys();
    _mentionMenuHighlight.value = 0;
  }

  void _insertMentionTrigger() {
    if (!widget.enabled || widget.busy) return;
    if (_mentionPickerActive) {
      _focus.requestFocus();
      _measureComposerShell();
      return;
    }
    final sel = _controller.selection;
    final text = _controller.text;
    final offset = sel.isValid ? sel.baseOffset.clamp(0, text.length) : text.length;
    final before = text.substring(0, offset);
    final after = text.substring(offset);
    final needsSpace = before.isNotEmpty && !before.endsWith(' ') && !before.endsWith('\n');
    final insert = needsSpace ? ' @' : '@';
    final newText = before + insert + after;
    final newOffset = offset + insert.length;
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newOffset);
    _clearMentionMenuRowKeys();
    _mentionMenuHighlight.value = 0;
    setState(() {});
    _syncMentionMenuOverlay();
    _focus.requestFocus();
    _measureComposerShell();
  }

  void _scrollHighlightedMentionIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _mentionMenuRowKeys[_mentionMenuHighlight.value]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _mentionMenuHighlightKeyboard(int index) {
    if (_mentionMenuHighlight.value == index) return;
    _mentionMenuHighlight.value = index;
    _scrollHighlightedMentionIntoView();
  }

  void _mentionMenuHighlightHover(int index) {
    if (_mentionMenuHighlight.value == index) return;
    _mentionMenuHighlight.value = index;
  }

  void _measureComposerShell() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _composerShellKey.currentContext?.findRenderObject() as RenderBox?;
      final h = box != null && box.hasSize ? box.size.height : null;
      if (h != null && (h - _composerShellHeight).abs() > 0.5) setState(() => _composerShellHeight = h);
      if (_mentionPickerActive) _mentionMenuOverlayEntry?.markNeedsBuild();
    });
  }

  void _syncMentionMenuOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mentionPickerActive) {
        _ensureMentionMenuOverlay();
      } else {
        _removeMentionMenuOverlay();
      }
    });
  }

  void _ensureMentionMenuOverlay() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    if (_mentionMenuOverlayEntry != null) return;
    _mentionMenuOverlayEntry = OverlayEntry(builder: (context) => _mentionMenuOverlayLayer());
    overlay.insert(_mentionMenuOverlayEntry!);
  }

  void _removeMentionMenuOverlay() {
    _mentionMenuOverlayEntry?.remove();
    _mentionMenuOverlayEntry = null;
  }

  Widget _mentionMenuOverlayLayer() {
    final shellBox = _composerShellKey.currentContext?.findRenderObject() as RenderBox?;
    final menuWidth = shellBox != null && shellBox.hasSize ? (shellBox.size.width - 16).clamp(200.0, 640.0) : 320.0;
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _dismissMentionPicker(),
          ),
        ),
        CompositedTransformFollower(
          link: _mentionLayerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(8, -6),
          child: SizedBox(
            width: menuWidth,
            child: ValueListenableBuilder<int>(
              valueListenable: _mentionMenuHighlight,
              builder: (context, highlightIndex, _) => _mentionMenu(highlightIndex: highlightIndex),
            ),
          ),
        ),
      ],
    );
  }

  List<_MentionPickRow> get _mentionPickRows {
    if (!_mentionPickerActive) return const [];
    final q = _activeMentionQuery ?? '';
    final matches = _mentionMatches;
    final tools = matches.where((m) => !m.isDevice && !m.isRootCommand).toList(growable: false);
    final rootOnly = matches.where((m) => m.isRootCommand).toList(growable: false);
    final devices = matches.where((m) => m.isDevice).toList(growable: false);
    final rows = <_MentionPickRow>[];
    if (_mentionQueryShowsImage(q)) rows.add(const _MentionPickRow(kind: _MentionPickKind.image));
    if (_mentionQueryShowsFile(q)) rows.add(const _MentionPickRow(kind: _MentionPickKind.file));
    for (final m in tools) {
      rows.add(_MentionPickRow(kind: _MentionPickKind.mention, mention: m));
    }
    for (final m in rootOnly) {
      rows.add(_MentionPickRow(kind: _MentionPickKind.mention, mention: m));
    }
    for (final m in devices) {
      rows.add(_MentionPickRow(kind: _MentionPickKind.mention, mention: m));
    }
    return rows;
  }

  void _pickMentionRow(_MentionPickRow row) {
    if (row.kind == _MentionPickKind.image) {
      _dismissMentionPicker();
      unawaited(_attachImage());
      return;
    }
    if (row.kind == _MentionPickKind.file) {
      _dismissMentionPicker();
      unawaited(_attachFile());
      return;
    }
    if (row.mention != null) _pickMention(row.mention!);
  }

  void _pickMention(CatalogMention m) {
    if (m.isRootCommand && widget.onTestMultitask != null) {
      _dismissMentionPicker();
      widget.onTestMultitask!();
      return;
    }
    _removeMentionMenuOverlay();
    _clearMentionMenuRowKeys();
    _mentionMenuHighlight.value = 0;
    _clearActiveMentionQuery();
    final offset = _controller.selection.isValid ? _controller.selection.baseOffset : _controller.text.length;
    final text = _controller.text;
    final before = text.substring(0, offset.clamp(0, text.length));
    final after = text.substring(offset.clamp(0, text.length));
    final token = composerMentionToken(m.id);
    final needsSpace = before.isNotEmpty && !before.endsWith(' ') && !before.endsWith('\n');
    final insert = '${needsSpace ? ' ' : ''}$token ';
    final newText = before + insert + after;
    final cursor = before.length + insert.length;
    _controller.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: cursor));
    setState(() {});
    _requestComposerFocus(cursor);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focus.hasFocus);
    if (_focus.hasFocus) unawaited(SttService.instance.prewarm());
  }

  void _attachmentHistoryRecord() => _attachmentHistory.record();

  void _attachmentHistoryClear() => _attachmentHistory.clear();

  bool _attachmentHistoryUndo() => _attachmentHistory.undo();

  bool _attachmentHistoryRedo() => _attachmentHistory.redo();

  void _composerMarkAttachmentEdit() => _composerLastEditAttachments = true;

  void _composerMarkTextEdit() => _composerLastEditAttachments = false;

  bool _composerEditShortcut(KeyDownEvent event) {
    final mod = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    if (!mod) return false;
    if (event.logicalKey == LogicalKeyboardKey.keyZ && HardwareKeyboard.instance.isShiftPressed) {
      if (_attachmentHistoryRedo()) {
        setState(() {});
        return true;
      }
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyY) {
      if (_attachmentHistoryRedo()) {
        setState(() {});
        return true;
      }
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyZ && _composerLastEditAttachments && _attachmentHistoryUndo()) {
      _composerLastEditAttachments = false;
      setState(() {});
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    _focus.onKeyEvent = _onKeyEvent;
  }

  @override
  void dispose() {
    _mentionListScrollController.dispose();
    _mentionMenuHighlight.dispose();
    _removeMentionMenuOverlay();
    SttService.instance.onAutoStop = null;
    SttService.instance.liveTranscript.removeListener(_onLiveTranscript);
    if (_recording || SttService.instance.isRecording.value) {
      unawaited(SttService.instance.cancel());
    }
    _focus.removeListener(_onFocusChange);
    if (_internalFocus != null) _focus.onKeyEvent = null;
    _internalController?.dispose();
    _internalFocus?.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_composerEditShortcut(event)) return KeyEventResult.handled;

    if (widget.compact) {
      if (event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed && _canSubmit) {
        unawaited(_submit());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final slashMatches = _slashMatches;
    if (slashMatches.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _highlightedSlashIndex = (_highlightedSlashIndex + 1) % slashMatches.length;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _highlightedSlashIndex = (_highlightedSlashIndex - 1 + slashMatches.length) % slashMatches.length;
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
        final target = slashMatches[_highlightedSlashIndex.clamp(0, slashMatches.length - 1)];
        _pickSlash(target);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _controller.clear();
        setState(() {});
        return KeyEventResult.handled;
      }
    }

    final pickRows = _mentionPickRows;
    if (pickRows.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _mentionMenuHighlightKeyboard((_mentionMenuHighlight.value + 1) % pickRows.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _mentionMenuHighlightKeyboard((_mentionMenuHighlight.value - 1 + pickRows.length) % pickRows.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
        final target = pickRows[_mentionMenuHighlight.value.clamp(0, pickRows.length - 1)];
        _pickMentionRow(target);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _dismissMentionPicker();
        return KeyEventResult.handled;
      }
    }

    if (_mentionPickerActive && event.logicalKey == LogicalKeyboardKey.escape) {
      _dismissMentionPicker();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp && widget.promptHistory.isNotEmpty && _attachments.isEmpty) {
      final sel = _controller.selection;
      if (!sel.isValid || sel.baseOffset == 0 || composerMentionPlainText(_controller.text).isEmpty) {
        if (_historyIndex == -1) _draftText = _controller.text;
        if (_historyIndex + 1 < widget.promptHistory.length) {
          _historyIndex++;
          final prompt = widget.promptHistory[_historyIndex];
          _controller.text = prompt;
          _controller.selection = TextSelection.collapsed(offset: prompt.length);
          setState(() {});
          return KeyEventResult.handled;
        }
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown && _historyIndex >= 0) {
      _historyIndex--;
      if (_historyIndex == -1) {
        _controller.text = _draftText;
        _controller.selection = TextSelection.collapsed(offset: _draftText.length);
      } else {
        final prompt = widget.promptHistory[_historyIndex];
        _controller.text = prompt;
        _controller.selection = TextSelection.collapsed(offset: prompt.length);
      }
      setState(() {});
      return KeyEventResult.handled;
    }

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
    _attachmentHistoryRecord();
    _composerMarkAttachmentEdit();
    setState(() {
      _historyIndex = -1;
      _draftText = '';
      _attachments.addAll(items);
    });
    for (final item in items) {
      unawaited(_uploadItem(item));
    }
  }

  void _replaceItem(int i, StagedMedia next) {
    if (!mounted || i < 0 || i >= _attachments.length) return;
    _attachmentHistoryRecord();
    _composerMarkAttachmentEdit();
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
    final picked = await askMedia(context: context, types: const [MediaType.image], allowMultiple: true);
    if (picked != null) _stageItems(picked.map((m) => m.copyWith(uploadProgress: 0.05)).toList());
  }

  Future<void> _attachFile() async {
    final picked = await askMedia(context: context, types: const [MediaType.document, MediaType.any], allowMultiple: true);
    if (picked != null) _stageItems(picked.map((m) => m.copyWith(uploadProgress: 0.05)).toList());
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    _submitting = true;

    _historyIndex = -1;
    _draftText = '';

    final raw = _controller.text.trim();
    if (raw == '/clear') {
      _controller.clear();
      _attachmentHistoryClear();
      setState(() => _submitting = false);
      widget.onNewChat?.call();
      return;
    }
    if (raw == '/model') {
      _controller.clear();
      _attachmentHistoryClear();
      setState(() => _submitting = false);
      _modelTap()?.call();
      return;
    }

    String? turnToolMode;
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

    final draft = _textWithoutActiveMentionDraft;
    final mentionIds = [
      ...composerMentionIdsParse(draft),
      ...widget.selectedMentionIds.where((id) => id != 'image' && !_inlineMentionIds.contains(id)),
    ].toList(growable: false);

    var submitText = widget.compact ? draft.trim() : composerMentionTextForWire(draft, _composerMentions, mentionIds: mentionIds);
    if (!widget.compact && (submitText.startsWith('/ask ') || submitText == '/ask')) {
      turnToolMode = 'ask';
      submitText = submitText.length > 4 ? submitText.substring(4).trim() : '';
    }

    if (submitText.isEmpty && atts.isEmpty && (widget.compact || mentionIds.isEmpty)) {
      _submitting = false;
      return;
    }

    _controller.clear();
    _attachmentHistoryClear();
    setState(() {});

    try {
      widget.onSend(submitText, atts, toolMode: turnToolMode, mentionIds: mentionIds, displayContent: draft.trim());
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

    _preRecordingDraft = _controller.text;
    SttService.instance.liveTranscript.removeListener(_onLiveTranscript);
    SttService.instance.liveTranscript.addListener(_onLiveTranscript);
    SttService.instance.onAutoStop = () {
      if (mounted && _recording) unawaited(_stopMic());
    };

    final ok = await SttService.instance.startRecording();
    if (!mounted) return;
    if (!ok) {
      SttService.instance.onAutoStop = null;
      SttService.instance.liveTranscript.removeListener(_onLiveTranscript);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SttService.instance.lastStartError ?? sttMicErrorMessage()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _recording = true);
    _focus.requestFocus();
  }

  Future<void> _stopMic() async {
    if (!_recording) return;
    SttService.instance.onAutoStop = null;
    SttService.instance.liveTranscript.removeListener(_onLiveTranscript);
    if (mounted) setState(() => _recording = false);

    final text = await SttService.instance.stopAndTranscribe(lang: VoicePrefs.instance.speechLang);
    if (!mounted) return;

    final transcript = (text ?? SttService.instance.liveTranscript.value).trim();
    if (transcript.isEmpty) {
      final err = SttService.instance.lastTranscribeError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'No speech detected'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final prefix = _preRecordingDraft.trim();
    final newText = prefix.isEmpty ? transcript : '$prefix $transcript';
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newText.length);
    setState(() {});
    if (VoicePrefs.instance.sttAutoSend && _controller.text.trim().isNotEmpty) {
      await _submit();
      return;
    }
    _focus.requestFocus();
  }

  Future<void> _cancelMic() async {
    if (!_recording) return;
    SttService.instance.onAutoStop = null;
    SttService.instance.liveTranscript.removeListener(_onLiveTranscript);
    await SttService.instance.cancel();
    if (!mounted) return;
    _controller.text = _preRecordingDraft;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    setState(() => _recording = false);
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

  Widget _followupQueueBox() {
    if (widget.compact) return const SizedBox.shrink();
    final rows = widget.followupRows;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text('${rows.length} queued', style: const TextStyle(color: zinc500, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: zinc100, fontSize: 13),
                    ),
                  ),
                  if (widget.onFollowupSteer != null)
                    TextButton.icon(
                      onPressed: () => widget.onFollowupSteer!(row),
                      icon: const Icon(Icons.subdirectory_arrow_left_rounded, size: 16),
                      label: const Text('Steer'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8), padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  if (widget.onFollowupRemove != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: zinc500),
                      onPressed: () => widget.onFollowupRemove!(row),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _slashSuggestionsBox() {
    if (widget.compact) return const SizedBox.shrink();
    final matches = _slashMatches;
    if (matches.isEmpty) return const SizedBox.shrink();

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
        itemCount: matches.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF3F3F46)),
        itemBuilder: (context, i) {
          final cmd = matches[i];
          final isHighlighted = i == _highlightedSlashIndex;
          return InkWell(
            onTap: () => _pickSlash(cmd),
            child: Container(
              color: isHighlighted ? const Color(0xFF3F3F46) : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(cmd.icon, size: 16, color: const Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Text(cmd.label, style: const TextStyle(color: zinc100, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(cmd.description, style: const TextStyle(color: zinc500, fontSize: 11)),
                  const Spacer(),
                  if (isHighlighted)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text('↵', style: TextStyle(color: zinc500, fontSize: 12)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mentionMenuTile({
    required int rowIndex,
    required int highlightIndex,
    required VoidCallback onTap,
    required Widget leading,
    required String label,
    String caption = '',
    bool selected = false,
  }) {
    final isHighlighted = rowIndex == highlightIndex;
    return KeyedSubtree(
      key: _mentionMenuRowKey(rowIndex),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _mentionMenuHighlightHover(rowIndex),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: isHighlighted ? const Color(0xFF3F3F46) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: zinc100, fontSize: 13, fontWeight: FontWeight.w500)),
                if (caption.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(caption, style: const TextStyle(color: zinc500, fontSize: 11)),
                ],
                const Spacer(),
                if (isHighlighted)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Text('↵', style: TextStyle(color: zinc500, fontSize: 12)),
                  ),
                if (selected) const Icon(Icons.check_rounded, size: 16, color: Color(0xFF22C55E)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mentionSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: const TextStyle(color: zinc500, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _mentionMenu({required int highlightIndex}) {
    if (!_mentionPickerActive) return const SizedBox.shrink();
    final pickRows = _mentionPickRows;
    if (pickRows.isEmpty) return const SizedBox.shrink();

    final matches = _mentionMatches;
    final tools = matches.where((m) => !m.isDevice && !m.isRootCommand).toList(growable: false);
    final rootOnly = matches.where((m) => m.isRootCommand).toList(growable: false);
    final devices = matches.where((m) => m.isDevice).toList(growable: false);
    final q = _activeMentionQuery ?? '';
    var rowIndex = 0;

    final children = <Widget>[];
    if (_mentionQueryShowsImage(q)) {
      children.add(
        _mentionMenuTile(
          rowIndex: rowIndex++,
          highlightIndex: highlightIndex,
          onTap: () => _pickMentionRow(const _MentionPickRow(kind: _MentionPickKind.image)),
          leading: const Icon(Icons.image_outlined, size: 16, color: _mentionIconGrey),
          label: 'Image',
        ),
      );
      if (_mentionQueryShowsFile(q) || tools.isNotEmpty || devices.isNotEmpty) {
        children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      }
    }
    if (_mentionQueryShowsFile(q)) {
      children.add(
        _mentionMenuTile(
          rowIndex: rowIndex++,
          highlightIndex: highlightIndex,
          onTap: () => _pickMentionRow(const _MentionPickRow(kind: _MentionPickKind.file)),
          leading: const Icon(Icons.attach_file_rounded, size: 16, color: _mentionIconGrey),
          label: 'File',
        ),
      );
      if (tools.isNotEmpty || rootOnly.isNotEmpty || devices.isNotEmpty) {
        children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      }
    }
    if (tools.isNotEmpty) {
      children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      children.add(_mentionSectionHeader('Tools'));
      for (final m in tools) {
        final i = rowIndex++;
        children.add(
          _mentionMenuTile(
            rowIndex: i,
            highlightIndex: highlightIndex,
            onTap: () => _pickMention(m),
            leading: _mentionLeadingIcon(m),
            label: m.displayLabel,
            caption: m.displayCaption,
            selected: _inlineMentionIds.contains(m.id),
          ),
        );
        if (m != tools.last) children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      }
    }
    if (rootOnly.isNotEmpty) {
      children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      children.add(_mentionSectionHeader('Root'));
      for (final m in rootOnly) {
        final i = rowIndex++;
        children.add(
          _mentionMenuTile(
            rowIndex: i,
            highlightIndex: highlightIndex,
            onTap: () => _pickMention(m),
            leading: _mentionLeadingIcon(m),
            label: m.displayLabel,
            caption: m.displayCaption,
            selected: _inlineMentionIds.contains(m.id),
          ),
        );
        if (m != rootOnly.last) children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      }
    }
    if (devices.isNotEmpty) {
      children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      children.add(_mentionSectionHeader('Devices'));
      for (final m in devices) {
        final i = rowIndex++;
        children.add(
          _mentionMenuTile(
            rowIndex: i,
            highlightIndex: highlightIndex,
            onTap: () => _pickMention(m),
            leading: _mentionLeadingIcon(m),
            label: m.displayLabel,
            caption: m.displayCaption,
            selected: _inlineMentionIds.contains(m.id),
          ),
        );
        if (m != devices.last) children.add(const Divider(height: 1, color: Color(0xFF3F3F46)));
      }
    }
    return Material(
      elevation: 8,
      shadowColor: Colors.black54,
      color: const Color(0xFF27272A),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3F3F46)),
        ),
        constraints: const BoxConstraints(maxHeight: 280),
        child: Scrollbar(
          controller: _mentionListScrollController,
          child: ListView(
            controller: _mentionListScrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const ClampingScrollPhysics(),
            children: children,
          ),
        ),
      ),
    );
  }

  static const _attachBtnWidth = 32.0;
  static const _attachTextGap = 4.0;

  double get _leadingActionsWidth => _attachBtnWidth;
  static const _actionBtnWidth = 38.0;
  static const _modelChipWidth = 150.0;
  static const _modePillWidth = 64.0;
  static const _inlineMinWidth = 360.0;

  bool get _modePillVisible => _askActive && widget.onToolModeToggle != null;

  double get _modePillLayoutWidth => _modePillVisible ? _modePillWidth : 0;

  bool _shouldUseStackedLayout(BuildContext context, double totalWidth) {
    if (totalWidth < _inlineMinWidth) return true;
    final modelW = widget.compact ? 0.0 : _modelChipWidth;
    final textWidth = totalWidth - _leadingActionsWidth - _modePillLayoutWidth - modelW - _actionBtnWidth - 32;
    return textWidth <= 48;
  }

  Duration get _composerShellAnimDuration =>
      _focus.hasFocus ? Duration.zero : const Duration(milliseconds: 120);

  VoidCallback? _modelTap() => widget.enabled
      ? () async {
          final next = await agentModelPick(context, widget.model, widget.models, modelsLoading: widget.modelsLoading);
          if (next != null) widget.onModel(next);
        }
      : null;

  Widget _mentionMenuButton() => uiIconButton(
        tooltip: 'Mention menu',
        onPressed: widget.enabled && !widget.busy ? _insertMentionTrigger : null,
        icon: Icon(Icons.add_rounded, size: 21, color: _mentionPickerActive ? zinc100 : zinc500),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(_attachBtnWidth, _attachBtnWidth),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );

  Future<void> _openCompactAttachMenu() async {
    final ctx = context;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final action = await showMenu<String>(
      context: ctx,
      color: const Color(0xFF27272A),
      position: RelativeRect.fromLTRB(offset.dx, offset.dy - 4, offset.dx + box.size.width, offset.dy),
      items: const [
        PopupMenuItem(
          value: 'image',
          height: 40,
          child: Row(children: [Icon(Icons.image_outlined, size: 18, color: _mentionIconGrey), SizedBox(width: 10), Text('Photo', style: TextStyle(color: zinc100, fontSize: 13))]),
        ),
        PopupMenuItem(
          value: 'file',
          height: 40,
          child: Row(children: [Icon(Icons.attach_file_rounded, size: 18, color: _mentionIconGrey), SizedBox(width: 10), Text('File', style: TextStyle(color: zinc100, fontSize: 13))]),
        ),
      ],
    );
    if (action == 'image') unawaited(_attachImage());
    if (action == 'file') unawaited(_attachFile());
  }

  Widget _compactAttachButton() => uiIconButton(
        tooltip: 'Attach',
        onPressed: widget.enabled && !widget.busy ? () => unawaited(_openCompactAttachMenu()) : null,
        icon: const Icon(Icons.add_rounded, size: 21, color: zinc500),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(_attachBtnWidth, _attachBtnWidth),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );

  Widget _leadingActionButtons() => widget.compact ? _compactAttachButton() : _mentionMenuButton();

  Widget _modePill() {
    if (!_modePillVisible) return const SizedBox.shrink();
    return uiTooltip(
      message: 'Ask Mode: Direct reply without tools (fast). Tap to switch back to Agent.',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.enabled && !widget.busy ? widget.onToolModeToggle : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF38BDF8)),
              SizedBox(width: 4),
              Text('Ask', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modelChip() => widget.compact ? const SizedBox.shrink() : UiAssistantModelChip(model: widget.model, onTap: _modelTap());

  Widget _actionButton() => _ActionButton(kind: composerActionKind(streaming: widget.busy, recording: _recording, hasText: _hasText), onAction: _onAction);

  EdgeInsets _composerTextAreaPadding(bool stacked) =>
      EdgeInsets.fromLTRB(0, stacked ? 4 : 0, 4, stacked ? 4 : 0);

  EdgeInsets _composerFieldContentPadding(bool stacked) =>
      EdgeInsets.fromLTRB(2, stacked ? 10 : 7, 4, stacked ? 10 : 7);

  Widget _composerTextArea({required bool stacked}) {
    if (widget.compact) {
      return Padding(
        padding: _composerTextAreaPadding(stacked),
        child: _composerFieldChrome(
          child: TextField(
          key: const ValueKey('composer_text_field'),
          controller: _controller,
          focusNode: _focus,
          enabled: widget.enabled && !_recording,
          minLines: 1,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textAlignVertical: stacked ? TextAlignVertical.top : TextAlignVertical.center,
          style: const TextStyle(color: zinc100, fontSize: 14, height: 1.35),
          cursorColor: zinc100,
          onChanged: (_) {
            _composerMarkTextEdit();
            final hadFocus = _focus.hasFocus;
            final sel = _controller.selection;
            setState(() {});
            _syncComposerStackedLayout(_shouldUseStackedLayout(context, _inputAreaWidth));
            if (hadFocus) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _focus.hasFocus) return;
                _restoreComposerFocus(sel);
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
            contentPadding: _composerFieldContentPadding(stacked),
          ),
        ),
        ),
      );
    }
    final field = ExtendedTextField(
      key: const ValueKey('composer_text_field'),
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled && !_recording,
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textAlignVertical: stacked ? TextAlignVertical.top : TextAlignVertical.center,
      style: const TextStyle(color: zinc100, fontSize: 14, height: 1.35),
      cursorColor: zinc100,
      specialTextSpanBuilder: _composerSpecialTextSpanBuilder(),
      onChanged: (_) {
        _composerMarkTextEdit();
        final hadFocus = _focus.hasFocus;
        final sel = _controller.selection;
        _mentionMenuHighlight.value = 0;
        setState(() {});
        _syncMentionMenuOverlay();
        if (_mentionPickerActive) _measureComposerShell();
        _syncComposerStackedLayout(_shouldUseStackedLayout(context, _inputAreaWidth));
        if (hadFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _focus.hasFocus) return;
            _restoreComposerFocus(sel);
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
        contentPadding: _composerFieldContentPadding(stacked),
      ),
    );
    return Padding(padding: _composerTextAreaPadding(stacked), child: _composerFieldChrome(child: field));
  }

  Widget _inputArea(double maxWidth) {
    if (_recording) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: UiAudioWaveform(
          recordingElapsedMs: SttService.instance.recordingElapsedMs,
          amplitude: SttService.instance.audioAmplitude,
          amplitudeHistory: SttService.instance.amplitudeHistory,
          liveTranscript: SttService.instance.liveTranscript,
          isLiveInterim: SttService.instance.isLiveInterim,
          isTranscribing: SttService.instance.isTranscribing,
          engine: VoicePrefs.instance.sttEngine,
          maxRecordingSeconds: SttService.instance.sessionMaxRecordingSeconds,
          onCancel: _cancelMic,
          onCommit: _stopMic,
        ),
      );
    }
    _inputAreaWidth = maxWidth;
    final stacked = _shouldUseStackedLayout(context, maxWidth);
    if (stacked != _wasStacked) _scheduleComposerStackedSync();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: stacked ? 0 : _leadingActionsWidth,
              child: stacked ? null : _leadingActionButtons(),
            ),
            if (!stacked) const SizedBox(width: _attachTextGap),
            Expanded(child: _composerTextArea(stacked: stacked)),
            if (!stacked) ...[
              if (!widget.compact && _modePillVisible) ...[
                _modePill(),
                const SizedBox(width: 4),
              ],
              if (!widget.compact) ...[
                _modelChip(),
                const SizedBox(width: 4),
              ],
              _actionButton(),
            ],
          ],
        ),
        if (stacked)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _leadingActionButtons(),
                if (!widget.compact && _modePillVisible) ...[
                  _modePill(),
                  const SizedBox(width: 4),
                ],
                const Spacer(),
                if (!widget.compact) ...[
                  _modelChip(),
                  const SizedBox(width: 4),
                ],
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
                      onRemove: widget.enabled && !widget.busy
                          ? () {
                              _attachmentHistoryRecord();
                              _composerMarkAttachmentEdit();
                              setState(() => _attachments.removeAt(i));
                            }
                          : null,
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
                if (idx >= 0) {
                  _attachmentHistoryRecord();
                  _composerMarkAttachmentEdit();
                  setState(() => _attachments.removeAt(idx));
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.compact && _mentionPickerActive) {
      _measureComposerShell();
      _syncMentionMenuOverlay();
    } else {
      _removeMentionMenuOverlay();
    }
    final border = _isDragging
        ? const Color(0xFF38BDF8)
        : (_focused ? const Color(0xFF3F3F46) : const Color(0xFF27272A));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSpeakIndicator && !widget.compact) const Align(alignment: Alignment.centerLeft, child: UiSpeakIndicator()),
        Stack(
          clipBehavior: Clip.none,
          children: [
            DropTarget(
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              onDragDone: (detail) async {
                setState(() => _isDragging = false);
                if (!widget.enabled || widget.busy) return;
                final staged = <StagedMedia>[];
                for (final xFile in detail.files.take(defaultMaxMediaFiles - _attachments.length)) {
                  try {
                    final bytes = await xFile.readAsBytes();
                    if (bytes.isEmpty) continue;
                    final name = xFile.name;
                    final mime = mimeForFilename(name);
                    staged.add(StagedMedia(name: name, bytes: bytes, mime: mime, type: mediaTypeForMime(mime), size: bytes.length, uploadProgress: 0.05));
                  } catch (_) {}
                }
                if (staged.isNotEmpty) _stageItems(staged);
              },
              child: AnimatedContainer(
                key: _composerShellKey,
                duration: _composerShellAnimDuration,
                decoration: BoxDecoration(
                  color: _isDragging ? const Color(0xFF0F172A) : const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: _isDragging ? 1.5 : 1.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isDragging)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF38BDF8)),
                            SizedBox(width: 6),
                            Text('Drop files to attach', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    _followupQueueBox(),
                    _slashSuggestionsBox(),
                    _attachmentRow(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
                      child: CompositedTransformTarget(
                        link: _mentionLayerLink,
                        child: LayoutBuilder(builder: (context, constraints) => _inputArea(constraints.maxWidth)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
