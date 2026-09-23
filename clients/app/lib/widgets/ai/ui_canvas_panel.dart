import 'package:alienai_c35/c/canvas/canvas_diff.dart';
import 'package:alienai_c35/c/store/canvas_store.dart';
import 'package:alienai_c35/widgets/ai/ui_canvas_diff_view.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class UiCanvasPanel extends StatefulWidget {
  const UiCanvasPanel({
    super.key,
    required this.store,
    this.onPromptIterate,
    this.onClose,
  });

  final CanvasStore store;
  final void Function(CanvasArtifact artifact)? onPromptIterate;
  final VoidCallback? onClose;

  @override
  State<UiCanvasPanel> createState() => _UiCanvasPanelState();
}

class _UiCanvasPanelState extends State<UiCanvasPanel> {
  static const _bg = Color(0xFF0C0C0E);
  static const _panelBg = Color(0xFF141418);
  static const _border = Color(0xFF27272A);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFF71717A);
  static const _accent = Color(0xFF06B6D4);

  late final TextEditingController _textCtrl;
  String _lastSyncedContent = '';
  var _copied = false;

  @override
  void initState() {
    super.initState();
    _lastSyncedContent = widget.store.artifact?.content ?? '';
    _textCtrl = TextEditingController(text: _lastSyncedContent);
    widget.store.addListener(_onStoreChange);
  }

  @override
  void didUpdateWidget(covariant UiCanvasPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_onStoreChange);
      widget.store.addListener(_onStoreChange);
      _syncFromStore();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChange);
    _textCtrl.dispose();
    super.dispose();
  }

  void _onStoreChange() {
    if (!mounted) return;
    final current = widget.store.artifact?.content ?? '';
    if (current != _lastSyncedContent && current != _textCtrl.text) {
      _syncFromStore();
    }
    setState(() {});
  }

  void _syncFromStore() {
    final content = widget.store.artifact?.content ?? '';
    _lastSyncedContent = content;
    _textCtrl.value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(offset: content.length),
    );
  }

  Future<void> _copyContent() async {
    final text = widget.store.artifact?.content ?? _textCtrl.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _saveNewVersion() {
    widget.store.updateContent(
      _textCtrl.text,
      createVersion: true,
      description: 'Manual snapshot',
    );
    _lastSyncedContent = _textCtrl.text;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Version snapshot saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _header(CanvasArtifact artifact) {
    final versions = artifact.versions;
    final activeVerIdx = artifact.activeVersionIndex;
    final isCode = artifact.type == 'code';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Icon(
            isCode ? Icons.code_rounded : Icons.article_rounded,
            size: 18,
            color: _accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    artifact.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _panelBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    artifact.language.toUpperCase(),
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (versions.length > 1) ...[
            PopupMenuButton<int>(
              tooltip: uiPopupMenuTooltipText('Version history'),
              initialValue: activeVerIdx,
              onSelected: (idx) {
                widget.store.restoreVersion(idx);
                _syncFromStore();
              },
              child: uiPopupMenuChild(
                tooltip: 'Version history',
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _panelBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v${activeVerIdx + 1}',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: _muted, size: 16),
                  ],
                ),
              ),
              ),
              itemBuilder: (ctx) => [
                for (var i = 0; i < versions.length; i++)
                  PopupMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Text('Version ${i + 1}'),
                        if (i == activeVerIdx) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, size: 14, color: _accent),
                        ],
                        if (versions[i].description.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '(${versions[i].description})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _muted, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          // Tab switcher
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tabButton('Code', CanvasTab.editor),
                _tabButton('Preview', CanvasTab.preview),
                _tabButton('Diff', CanvasTab.diff),
              ],
            ),
          ),
          const SizedBox(width: 8),
          uiIconButton(
            tooltip: _copied ? 'Copied!' : 'Copy to clipboard',
            icon: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              color: _copied ? _accent : _muted,
              size: 16,
            ),
            onPressed: _copyContent,
          ),
          uiIconButton(
            tooltip: 'Close canvas',
            icon: const Icon(Icons.close_rounded, color: _muted, size: 18),
            onPressed: widget.onClose ?? widget.store.close,
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, CanvasTab tab) {
    final active = widget.store.activeTab == tab;
    return InkWell(
      onTap: () => widget.store.setActiveTab(tab),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? _accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _accent : _muted,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _editorView() {
    final lineCount = '\n'.allMatches(_textCtrl.text).length + 1;
    final lineNumbersText = List.generate(lineCount, (i) => '${i + 1}').join('\n');

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line numbers gutter
              Container(
                width: 32,
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Text(
                  lineNumbersText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF4A4A52),
                  ),
                ),
              ),
              Container(width: 1, height: (lineCount * 19).toDouble(), color: _border),
              const SizedBox(width: 12),
              // Editable text field
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 13,
                    height: 1.45,
                    color: _text,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    widget.store.updateContent(val);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewView() {
    final content = widget.store.artifact?.content ?? _textCtrl.text;
    return Container(
      color: _bg,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: content.isNotEmpty ? content : '_Empty content_',
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: _text, fontSize: 14, height: 1.5),
            h1: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.bold),
            h3: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
            code: const TextStyle(
              color: _text,
              fontSize: 13,
              fontFamily: 'Consolas',
              backgroundColor: Color(0xFF1E1E24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(CanvasArtifact artifact) {
    final text = _textCtrl.text;
    final lines = '\n'.allMatches(text).length + 1;
    final chars = text.length;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _panelBg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text(
            '$lines lines • $chars chars',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          const Spacer(),
          if (text != _lastSyncedContent) ...[
            TextButton.icon(
              onPressed: _saveNewVersion,
              icon: const Icon(Icons.save_rounded, size: 14, color: _accent),
              label: const Text(
                'Save snapshot',
                style: TextStyle(color: _accent, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (widget.onPromptIterate != null)
            ElevatedButton.icon(
              onPressed: () => widget.onPromptIterate!(artifact),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent.withValues(alpha: 0.15),
                foregroundColor: _accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFF0891B2)),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 13),
              label: const Text(
                'Iterate with AI',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fileTabBar() {
    final artifacts = widget.store.artifacts;
    if (artifacts.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F12),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artifacts.length,
        itemBuilder: (ctx, idx) {
          final art = artifacts[idx];
          final active = idx == widget.store.activeArtifactIndex;
          final isCode = art.type == 'code';

          return InkWell(
            onTap: () {
              widget.store.selectArtifact(idx);
              _syncFromStore();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active ? _bg : Colors.transparent,
                border: Border(
                  right: const BorderSide(color: _border),
                  bottom: active
                      ? const BorderSide(color: _accent, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCode ? Icons.code_rounded : Icons.article_rounded,
                    size: 14,
                    color: active ? _accent : _muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    art.title,
                    style: TextStyle(
                      color: active ? _text : _muted,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      widget.store.closeArtifact(idx);
                      _syncFromStore();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close_rounded, size: 12, color: _muted),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _diffView(CanvasArtifact artifact) {
    final activeVerIdx = artifact.activeVersionIndex;
    final versions = artifact.versions;

    String oldContent = '';
    String oldLabel = 'v1';
    final currentContent = _textCtrl.text;
    String newLabel = 'v${activeVerIdx + 1}';

    if (activeVerIdx > 0 && activeVerIdx < versions.length) {
      oldContent = versions[activeVerIdx - 1].content;
      oldLabel = 'v$activeVerIdx';
      newLabel = 'v${activeVerIdx + 1}';
    } else if (versions.isNotEmpty) {
      oldContent = versions.first.content;
      oldLabel = 'v1';
      newLabel = currentContent != oldContent ? 'Draft' : 'v1';
    }

    final diffLines = computeCanvasDiff(oldContent, currentContent);
    return UiCanvasDiffView(
      oldTitle: oldLabel,
      newTitle: newLabel,
      diffLines: diffLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artifact = widget.store.artifact;
    if (artifact == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: _bg),
        child: Center(
          child: Text(
            'No canvas content open',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(left: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          _header(artifact),
          _fileTabBar(),
          Expanded(
            child: switch (widget.store.activeTab) {
              CanvasTab.editor => _editorView(),
              CanvasTab.preview => _previewView(),
              CanvasTab.diff => _diffView(artifact),
            },
          ),
          _footer(artifact),
        ],
      ),
    );
  }
}
