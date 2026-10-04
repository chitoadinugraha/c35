import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/presentation/slide_theme.dart';
import 'package:alienai_c35/c/presentation/slide_theme_catalog.dart';
import 'package:alienai_c35/widgets/ai/io_slide_theme_pick.dart';
import 'package:alienai_c35/widgets/ai/slide_deck_pdf_exporter.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum SlidePatchAction { replace, insert, delete }

class SlidePatch {
  final SlidePatchAction action;
  final int slideIndex; // 1-indexed
  final String content;

  const SlidePatch({
    required this.action,
    required this.slideIndex,
    this.content = '',
  });

  static SlidePatch? tryParse(String raw) {
    final trimmed = raw.trim();

    final deleteMatch = RegExp(r'<!--\s*slide-patch:delete\s+(\d+)\s*-->', caseSensitive: false).firstMatch(trimmed);
    if (deleteMatch != null) {
      final idx = int.tryParse(deleteMatch.group(1) ?? '') ?? 1;
      return SlidePatch(action: SlidePatchAction.delete, slideIndex: idx);
    }

    final addMatch = RegExp(r'<!--\s*slide-patch:add\s+after=(\d+)\s*-->', caseSensitive: false).firstMatch(trimmed);
    if (addMatch != null) {
      final idx = int.tryParse(addMatch.group(1) ?? '') ?? 1;
      final body = trimmed.replaceFirst(addMatch.group(0)!, '').trim();
      return SlidePatch(action: SlidePatchAction.insert, slideIndex: idx, content: body);
    }

    final replaceMatch = RegExp(r'<!--\s*slide-patch:(\d+)\s*-->', caseSensitive: false).firstMatch(trimmed);
    if (replaceMatch != null) {
      final idx = int.tryParse(replaceMatch.group(1) ?? '') ?? 1;
      final body = trimmed.replaceFirst(replaceMatch.group(0)!, '').trim();
      return SlidePatch(action: SlidePatchAction.replace, slideIndex: idx, content: body);
    }

    return null;
  }
}

class SlideDeckData {
  SlideDeckData({
    required this.title,
    required List<String> slides,
    required this.createdAt,
    this.eyebrow,
    this.theme = 'dark',
  }) : slides = List<String>.from(slides);

  String title;
  final List<String> slides;
  final DateTime createdAt;
  final String? eyebrow;
  String theme;

  String toMarkdown() {
    return slides.join('\n\n---\n\n');
  }

  bool applyPatch(SlidePatch patch) {
    switch (patch.action) {
      case SlidePatchAction.replace:
        final idx = patch.slideIndex - 1;
        if (idx >= 0 && idx < slides.length) {
          slides[idx] = patch.content;
          return true;
        }
        return false;
      case SlidePatchAction.insert:
        final idx = patch.slideIndex;
        if (idx >= 0 && idx <= slides.length) {
          slides.insert(idx, patch.content);
          return true;
        } else {
          slides.add(patch.content);
          return true;
        }
      case SlidePatchAction.delete:
        final idx = patch.slideIndex - 1;
        if (idx >= 0 && idx < slides.length && slides.length > 1) {
          slides.removeAt(idx);
          return true;
        }
        return false;
    }
  }

  factory SlideDeckData.fromContent({
    required String title,
    required String content,
    DateTime? createdAt,
    String? eyebrow,
    String theme = 'dark',
  }) {
    final patch = SlidePatch.tryParse(content);
    if (patch != null) {
      final patchTitle = patch.action == SlidePatchAction.delete
          ? 'Slide ${patch.slideIndex} Deleted'
          : 'Slide ${patch.slideIndex} Updated';
      return SlideDeckData(
        title: title.isNotEmpty && title != 'Presentation' ? title : patchTitle,
        slides: patch.action == SlidePatchAction.delete
            ? ['_Slide ${patch.slideIndex} removed from presentation_']
            : [patch.content],
        createdAt: createdAt ?? DateTime.now(),
        eyebrow: 'SLIDE ${patch.slideIndex} UPDATED',
        theme: theme,
      );
    }

    final raw = content.split(RegExp(r'(?:^|\n)---\s*(?:\n|$)'));
    final list = raw.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    var resolvedTitle = title.trim();
    if (resolvedTitle.isEmpty ||
        resolvedTitle.toLowerCase() == 'presentation' ||
        resolvedTitle.toLowerCase() == 'slides' ||
        resolvedTitle.startsWith('snippet.')) {
      if (list.isNotEmpty) {
        final match = RegExp(r'^#+\s*(.+)$', multiLine: true).firstMatch(list.first);
        if (match != null) {
          resolvedTitle = match.group(1)?.trim() ?? resolvedTitle;
        }
      }
    }
    if (resolvedTitle.isEmpty) resolvedTitle = 'Presentation';

    return SlideDeckData(
      title: resolvedTitle,
      slides: list.isEmpty ? [content] : list,
      createdAt: createdAt ?? DateTime.now(),
      eyebrow: eyebrow,
      theme: theme,
    );
  }

  factory SlideDeckData.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? 'Presentation';
    final content = json['content']?.toString() ?? '';
    final theme = json['theme']?.toString() ?? 'dark';
    final slidesRaw = json['slides'];
    List<String> slides = const [];
    if (slidesRaw is List) {
      slides = slidesRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    final timeMs = json['created_at_ms'] as int? ?? json['createdAtMs'] as int?;
    final dt = timeMs != null ? DateTime.fromMillisecondsSinceEpoch(timeMs) : DateTime.now();

    if (slides.isEmpty && content.isNotEmpty) {
      return SlideDeckData.fromContent(
        title: title,
        content: content,
        createdAt: dt,
        eyebrow: json['eyebrow']?.toString(),
        theme: theme,
      );
    }

    return SlideDeckData(
      title: title,
      slides: slides.isEmpty ? ['_Empty slide_'] : slides,
      createdAt: dt,
      eyebrow: json['eyebrow']?.toString(),
      theme: theme,
    );
  }
}

class UiSlideDeckCard extends StatefulWidget {
  const UiSlideDeckCard({
    super.key,
    required this.deck,
    this.initiallyExpanded = false,
    this.onOpenInCanvas,
    this.onExport,
  });

  final SlideDeckData deck;
  final bool initiallyExpanded;
  final VoidCallback? onOpenInCanvas;
  final VoidCallback? onExport;

  @override
  State<UiSlideDeckCard> createState() => _UiSlideDeckCardState();
}

class _UiSlideDeckCardState extends State<UiSlideDeckCard> {
  late bool _expanded;
  int _currentSlide = 0;
  late SlideTheme _theme;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _theme = SlideThemeCatalog.resolve(widget.deck.theme);
    _pageController = PageController();
    SlideThemeCatalog.refresh();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  String _formatTimestamp(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dt.month - 1];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'am' : 'pm';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $m, $h:$min $ampm';
  }

  void _goToSlide(int index) {
    final total = widget.deck.slides.length;
    if (index < 0 || index >= total) return;
    setState(() => _currentSlide = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }
  }

  void _copyMarkdown(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.deck.toMarkdown()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${widget.deck.slides.length} slides markdown to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportToPptx(BuildContext context) async {
    if (widget.onExport != null) {
      widget.onExport!();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PowerPoint presentation (.pptx)...'),
          ],
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
      final url = Uri.parse('$base/v1/presentation/export');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': widget.deck.title,
          'eyebrow': widget.deck.eyebrow,
          'slides_markdown': widget.deck.toMarkdown(),
          'theme': _theme.id,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final downloadUrl = data['download_url']?.toString();
        final fileName = data['filename']?.toString() ?? '${_sanitizeFilename(widget.deck.title)}.pptx';
        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          final fullUrl = downloadUrl.startsWith('http') ? downloadUrl : '$base$downloadUrl';
          final uri = Uri.parse(fullUrl);

          // On mobile & desktop, save with human-readable filename and open
          if (!kIsWeb) {
            try {
              final bytesRes = await http.get(uri);
              if (bytesRes.statusCode == 200) {
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/$fileName');
                await file.writeAsBytes(bytesRes.bodyBytes);
                await OpenFilex.open(file.path);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Saved and opened: $fileName'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
            } catch (_) {}
          }

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Downloading $fileName...'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        }
      }

      throw Exception('Server returned ${res.statusCode}: ${res.body}');
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PowerPoint export unavailable offline. Markdown copied!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      Clipboard.setData(ClipboardData(text: widget.deck.toMarkdown()));
    }
  }

  String _sanitizeFilename(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'presentation' : cleaned;
  }

  Future<void> _exportToPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generating PDF slides...'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await SlideDeckPdfExporter.export(widget.deck, _theme);
      messenger.hideCurrentSnackBar();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDeckMenu(BuildContext anchorContext) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final action = await showMenu<String>(
      context: anchorContext,
      color: _theme.cardBg,
      position: RelativeRect.fromLTRB(
        offset.dx - 180,
        offset.dy + box.size.height + 4,
        offset.dx + box.size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(value: 'theme', child: Text('Theme', style: TextStyle(color: _theme.textPrimary))),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'fullscreen', child: Text('Fullscreen Presentation', style: TextStyle(color: _theme.textPrimary))),
        if (widget.onOpenInCanvas != null)
          PopupMenuItem(value: 'canvas', child: Text('Open in Canvas', style: TextStyle(color: _theme.textPrimary))),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'pptx', child: Text('Export to PowerPoint (.pptx)', style: TextStyle(color: _theme.textPrimary))),
        PopupMenuItem(value: 'pdf', child: Text('Export to PDF (.pdf)', style: TextStyle(color: _theme.textPrimary))),
        PopupMenuItem(value: 'copy', child: Text('Copy Slides Markdown', style: TextStyle(color: _theme.textPrimary))),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'collapse', child: Text('Collapse Preview', style: TextStyle(color: _theme.textPrimary))),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'theme':
        final picked = await ioSlideThemePick(anchorContext, current: _theme);
        if (picked != null && mounted) {
          setState(() {
            _theme = picked;
            widget.deck.theme = picked.id;
          });
        }
      case 'fullscreen':
        _openFullscreenPresentation(anchorContext);
      case 'canvas':
        widget.onOpenInCanvas?.call();
      case 'pptx':
        await _exportToPptx(anchorContext);
      case 'pdf':
        await _exportToPdf(anchorContext);
      case 'copy':
        _copyMarkdown(anchorContext);
      case 'collapse':
        setState(() => _expanded = false);
    }
  }

  void _openFullscreenPresentation(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, anim1, anim2) => _FullscreenDeckView(
          deck: widget.deck,
          initialSlide: _currentSlide,
          theme: _theme,
        ),
        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: _theme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _theme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _expanded ? _buildExpandedPreview() : _buildCollapsedCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedCard() {
    final slideCount = widget.deck.slides.length;
    final timeStr = _formatTimestamp(widget.deck.createdAt);

    return InkWell(
      onTap: () => setState(() => _expanded = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_theme.accent.withValues(alpha: 0.25), _theme.secondaryAccent.withValues(alpha: 0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _theme.accent.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.slideshow_rounded,
                color: _theme.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.deck.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _theme.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$slideCount slides • $timeStr',
                    style: TextStyle(
                      color: _theme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => setState(() => _expanded = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Open',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPreview() {
    final total = widget.deck.slides.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Toolbar (Mobile-friendly: Title, Slide Nav, Hamburger Menu, Collapse)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
          child: Row(
            children: [
              // Deck title with presentation icon
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.slideshow_rounded, size: 16, color: _theme.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.deck.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _theme.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Slide pager pill: [ < ] 1/3 [ > ]
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Previous slide',
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: _currentSlide > 0 ? Colors.white : Colors.white24,
                      ),
                      onPressed: _currentSlide > 0 ? () => _goToSlide(_currentSlide - 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${_currentSlide + 1}/$total',
                        style: TextStyle(
                          color: _theme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next slide',
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: _currentSlide < total - 1 ? Colors.white : Colors.white24,
                      ),
                      onPressed: _currentSlide < total - 1 ? () => _goToSlide(_currentSlide + 1) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Hamburger Menu Button [ ☰ ]
              Builder(
                builder: (btnCtx) => IconButton(
                  tooltip: 'Options',
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  icon: Icon(Icons.menu_rounded, color: _theme.textPrimary),
                  onPressed: () => _openDeckMenu(btnCtx),
                ),
              ),
            ],
          ),
        ),
        // 16:9 Presentation Canvas Container (Scales 960x540 canvas faithfully via FittedBox)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: _theme.canvasBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _theme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: total,
                  onPageChanged: (idx) => setState(() => _currentSlide = idx),
                  itemBuilder: (context, idx) {
                    return FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 960,
                        height: 540,
                        child: _SlideCanvasView(
                          deck: widget.deck,
                          slideIndex: idx,
                          totalSlides: total,
                          theme: _theme,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullscreenDeckView extends StatefulWidget {
  const _FullscreenDeckView({
    required this.deck,
    required this.initialSlide,
    required this.theme,
  });

  final SlideDeckData deck;
  final int initialSlide;
  final SlideTheme theme;

  @override
  State<_FullscreenDeckView> createState() => _FullscreenDeckViewState();
}

class _FullscreenDeckViewState extends State<_FullscreenDeckView> {
  late int _currentSlide;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentSlide = widget.initialSlide;
    _pageController = PageController(initialPage: widget.initialSlide);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSlide(int index) {
    final total = widget.deck.slides.length;
    if (index < 0 || index >= total) return;
    setState(() => _currentSlide = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.deck.slides.length;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.slideshow_rounded, color: widget.theme.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.deck.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentSlide + 1} / $total',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Fullscreen 16:9 Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.theme.canvasBg,
                          gradient: widget.theme.slideGradient,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.theme.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: widget.theme.accent.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                              PointerDeviceKind.stylus,
                            },
                          ),
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                            itemCount: total,
                            onPageChanged: (idx) => setState(() => _currentSlide = idx),
                            itemBuilder: (context, idx) {
                              return FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 960,
                                  height: 540,
                                  child: _SlideCanvasView(
                                    deck: widget.deck,
                                    slideIndex: idx,
                                    totalSlides: total,
                                    theme: widget.theme,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
                    onPressed: _currentSlide > 0 ? () => _goToSlide(_currentSlide - 1) : null,
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      for (int i = 0; i < total; i++)
                        InkWell(
                          onTap: () => _goToSlide(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentSlide ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentSlide ? widget.theme.accent : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70),
                    onPressed: _currentSlide < total - 1 ? () => _goToSlide(_currentSlide + 1) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Canonical 16:9 widescreen presentation slide canvas (960 x 540).
/// Identical layout, typography hierarchy, card geometry, and colors across
/// Preview, Fullscreen, PDF, and PowerPoint (.pptx) exports.
class _SlideCanvasView extends StatelessWidget {
  const _SlideCanvasView({
    required this.deck,
    required this.slideIndex,
    required this.totalSlides,
    required this.theme,
  });

  final SlideDeckData deck;
  final int slideIndex;
  final int totalSlides;
  final SlideTheme theme;

  @override
  Widget build(BuildContext context) {
    final rawContent = deck.slides[slideIndex];
    final cleanContent = rawContent.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '').trim();
    final rawLines = cleanContent.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (rawLines.isEmpty) return const SizedBox.shrink();

    String? imageUrl;
    final imgRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final lines = <String>[];
    for (final line in rawLines) {
      final m = imgRegex.firstMatch(line);
      if (m != null && imageUrl == null) {
        imageUrl = m.group(2);
      } else {
        lines.add(line);
      }
    }

    if (lines.isEmpty && imageUrl != null) {
      return Container(
        width: 960,
        height: 540,
        color: theme.canvasBg,
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: UiImg(src: imageUrl, fit: BoxFit.contain),
        ),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink();

    final slideTitle = lines[0].replaceAll(RegExp(r'^#+\s*'), '');
    String? subtitle;
    int bodyStartIndex = 1;
    if (lines.length > 1 &&
        !lines[1].startsWith('-') &&
        !lines[1].startsWith('*') &&
        !lines[1].startsWith('•') &&
        !RegExp(r'^\d+\.').hasMatch(lines[1])) {
      subtitle = lines[1].replaceAll(RegExp(r'^#+\s*'), '');
      bodyStartIndex = 2;
    }

    final bodyLines = lines.skip(bodyStartIndex).toList();
    final isCoverSlide = slideIndex == 0 && bodyLines.isEmpty;

    return Container(
      width: 960,
      height: 540,
      decoration: BoxDecoration(
        color: theme.canvasBg,
        gradient: theme.slideGradient,
      ),
      child: Stack(
        children: [
          // Top decorative accent line (full width 960, 4pt height)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 4, color: theme.accent),
          ),

          // Slide Content Canvas
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 34, 56, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge pill
                if (isCoverSlide)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.bulletCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.accent, width: 1),
                    ),
                    child: Text(
                      (deck.eyebrow?.isNotEmpty == true ? deck.eyebrow! : 'PRESENTATION').toUpperCase(),
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.bulletCardBg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: theme.accent, width: 0.8),
                    ),
                    child: Text(
                      'SLIDE ${slideIndex + 1} OF $totalSlides',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                SizedBox(height: isCoverSlide ? 28 : 12),

                // Main Content Body
                Expanded(
                  child: isCoverSlide
                      ? _buildCoverBody(slideTitle, subtitle, imageUrl)
                      : _buildContentBody(slideTitle, subtitle, bodyLines, imageUrl),
                ),

                // Bottom Navigation & Branding Bar (Identical to PDF & PPTX!)
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Alien AI',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var d = 0; d < totalSlides; d++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: d == slideIndex ? 22 : 6,
                            height: 4,
                            decoration: BoxDecoration(
                              color: d == slideIndex ? theme.accent : Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'Slide ${slideIndex + 1} of $totalSlides',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverBody(String title, String? subtitle, String? imageUrl) {
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          width: 64,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.accent, theme.secondaryAccent]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );

    if (imageUrl != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: textColumn),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 330,
                decoration: BoxDecoration(
                  color: theme.bulletCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
                child: UiImg(src: imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      );
    }

    return textColumn;
  }

  Widget _buildContentBody(String title, String? subtitle, List<String> bodyLines, String? imageUrl) {
    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (subtitle != null && subtitle.isNotEmpty) ...[
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
        ] else if (title.isNotEmpty) ...[
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: bodyLines.length,
            itemBuilder: (context, i) {
              final raw = bodyLines[i].replaceFirst(RegExp(r'^[-*•\d\.]+\s*'), '');
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.bulletCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: theme.accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        raw,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: bodyLines.length <= 3 ? 15 : 13.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (imageUrl != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 6, child: contentColumn),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 330,
                decoration: BoxDecoration(
                  color: theme.bulletCardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border),
                ),
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
                child: UiImg(src: imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      );
    }

    return contentColumn;
  }
}
