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
    this.onPromptExport,
    this.onClose,
  });

  final CanvasStore store;
  final void Function(CanvasArtifact artifact)? onPromptIterate;
  final void Function(CanvasArtifact artifact, String prompt)? onPromptExport;
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

  int _currentSlideIndex = 0;
  bool _cardViewMode = true;

  bool _isSlideDeck(CanvasArtifact? artifact, String content) {
    if (artifact == null) return false;
    final lang = artifact.language.toLowerCase();
    final type = artifact.type.toLowerCase();
    if (lang == 'slide' || lang == 'slides' || lang == 'marp' || type == 'slide' || type == 'presentation') {
      return true;
    }
    return content.contains(RegExp(r'(?:^|\n)---\s*(?:\n|$)'));
  }

  List<String> _parseSlides(String content) {
    if (content.trim().isEmpty) return ['_Empty slide_'];
    final raw = content.split(RegExp(r'(?:^|\n)---\s*(?:\n|$)'));
    final slides = raw.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return slides.isEmpty ? [content] : slides;
  }

  void _handleExportChoice(String choice, CanvasArtifact artifact) {
    final title = artifact.title.isNotEmpty ? artifact.title : 'Presentation';
    String prompt;
    switch (choice) {
      case 'pc':
        prompt = 'I am satisfied with this deck ("$title"). Please implement and build it directly on my connected PC using PowerPoint.';
        break;
      case 'download_pptx':
        prompt = 'I am satisfied with this deck ("$title"). Please compile and export it as a downloadable PPTX / PDF file.';
        break;
      case 'google_slides':
        prompt = 'I am satisfied with this deck ("$title"). Please export this presentation to Google Slides.';
        break;
      default:
        return;
    }
    if (widget.onPromptExport != null) {
      widget.onPromptExport!(artifact, prompt);
    } else if (widget.onPromptIterate != null) {
      widget.onPromptIterate!(artifact);
    }
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
          if (_isSlideDeck(artifact, widget.store.artifact?.content ?? _textCtrl.text)) ...[
            PopupMenuButton<String>(
              tooltip: uiPopupMenuTooltipText('Export presentation'),
              icon: const Icon(Icons.ios_share_rounded, color: _muted, size: 16),
              onSelected: (choice) => _handleExportChoice(choice, artifact),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'pc',
                  child: Row(
                    children: [
                      Icon(Icons.desktop_windows_rounded, size: 16, color: _accent),
                      SizedBox(width: 8),
                      Expanded(child: Text('Build on PC (PowerPoint)')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download_pptx',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Download PPTX / PDF')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'google_slides',
                  child: Row(
                    children: [
                      Icon(Icons.slideshow_rounded, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Export to Google Slides')),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
    final artifact = widget.store.artifact;
    if (_isSlideDeck(artifact, content)) {
      return _slideDeckPreview(content, artifact);
    }

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

  Widget _slideDeckPreview(String content, CanvasArtifact? artifact) {
    final slides = _parseSlides(content);
    if (_currentSlideIndex >= slides.length) {
      _currentSlideIndex = slides.length - 1;
    }
    if (_currentSlideIndex < 0) {
      _currentSlideIndex = 0;
    }

    return Container(
      color: _bg,
      child: Column(
        children: [
          // Slide deck toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: _panelBg,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.slideshow_rounded, size: 16, color: _accent),
                const SizedBox(width: 8),
                Text(
                  _cardViewMode
                      ? 'Slide ${_currentSlideIndex + 1} of ${slides.length}'
                      : '${slides.length} Slides',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_cardViewMode) ...[
                  uiIconButton(
                    tooltip: 'Previous slide',
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: _currentSlideIndex > 0 ? _text : _muted.withValues(alpha: 0.3),
                    ),
                    onPressed: _currentSlideIndex > 0
                        ? () => setState(() => _currentSlideIndex--)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  uiIconButton(
                    tooltip: 'Next slide',
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: _currentSlideIndex < slides.length - 1
                          ? _text
                          : _muted.withValues(alpha: 0.3),
                    ),
                    onPressed: _currentSlideIndex < slides.length - 1
                        ? () => setState(() => _currentSlideIndex++)
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () => setState(() => _cardViewMode = !_cardViewMode),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _cardViewMode ? _accent.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      _cardViewMode ? 'Card' : 'Scroll',
                      style: TextStyle(
                        color: _cardViewMode ? _accent : _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Slide body
          Expanded(
            child: _cardViewMode
                ? _singleSlideCard(slides[_currentSlideIndex], _currentSlideIndex, slides.length)
                : _allSlidesScroll(slides),
          ),
        ],
      ),
    );
  }

  Widget _singleSlideCard(String slideContent, int index, int total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E2E36)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: slideContent,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: _text, fontSize: 14, height: 1.5),
                            h1: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold),
                            h3: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600),
                            listBullet: const TextStyle(color: _accent, fontSize: 14),
                            code: const TextStyle(
                              color: _text,
                              fontSize: 12,
                              fontFamily: 'Consolas',
                              backgroundColor: Color(0xFF1E1E24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 10,
                    child: Text(
                      '${index + 1} / $total',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _allSlidesScroll(List<String> slides) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: slides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SLIDE ${i + 1}',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: slides[i],
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: _text, fontSize: 14, height: 1.5),
                  h1: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.bold),
                  h3: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _footer(CanvasArtifact artifact) {
    final text = _textCtrl.text;
    final lines = '\n'.allMatches(text).length + 1;
    final chars = text.length;
    final isSlide = _isSlideDeck(artifact, text);

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
            isSlide
                ? '${_parseSlides(text).length} slides • $chars chars'
                : '$lines lines • $chars chars',
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
          if (isSlide) ...[
            PopupMenuButton<String>(
              tooltip: uiPopupMenuTooltipText('Export presentation options'),
              onSelected: (choice) => _handleExportChoice(choice, artifact),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF059669)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ios_share_rounded, size: 13, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      'Export Deck',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'pc',
                  child: Row(
                    children: [
                      Icon(Icons.desktop_windows_rounded, size: 16, color: _accent),
                      SizedBox(width: 8),
                      Expanded(child: Text('Build directly on PC (PowerPoint)')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download_pptx',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Download as PPTX / PDF')),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'google_slides',
                  child: Row(
                    children: [
                      Icon(Icons.slideshow_rounded, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Export to Google Slides')),
                    ],
                  ),
                ),
              ],
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
