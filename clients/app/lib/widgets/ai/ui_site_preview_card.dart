import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SitePreviewData {
  SitePreviewData({
    required this.siteIid,
    required this.alienId,
    required this.name,
    required this.url,
    this.theme = 'dark',
    this.doc = const {},
  });

  final int siteIid;
  final String alienId;
  final String name;
  final String url;
  final String theme;
  final Map<String, dynamic> doc;

  factory SitePreviewData.fromJson(Map<String, dynamic> json) {
    final iid = json['site_iid'] as int? ?? json['siteIid'] as int? ?? 0;
    final alienId = json['alien_id']?.toString() ?? json['alienId']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Website';
    final url = json['url']?.toString() ?? (alienId.isNotEmpty ? 'alienai.id/$alienId' : '');
    final theme = json['theme']?.toString() ?? 'dark';
    final docRaw = json['doc'];
    final doc = docRaw is Map<String, dynamic>
        ? docRaw
        : (docRaw is String ? (jsonDecode(docRaw) as Map<String, dynamic>? ?? const {}) : const <String, dynamic>{});

    return SitePreviewData(
      siteIid: iid,
      alienId: alienId,
      name: name,
      url: url,
      theme: theme,
      doc: doc,
    );
  }

  List<Map<String, dynamic>> get blocks {
    final pages = doc['pages'];
    if (pages is List && pages.isNotEmpty) {
      final first = pages.first;
      if (first is Map<String, dynamic> && first['blocks'] is List) {
        return (first['blocks'] as List).whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  Color get accentColor {
    final t = doc['theme'];
    if (t is Map<String, dynamic> && t['accent'] != null) {
      final hex = t['accent'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    switch (theme.toLowerCase()) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'midnight':
      case 'indigo':
        return const Color(0xFF6366F1);
      case 'sunset':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFFF97316); // Alien Orange
    }
  }
}

class UiSitePreviewCard extends StatefulWidget {
  const UiSitePreviewCard({
    super.key,
    required this.data,
    this.initiallyExpanded = false,
  });

  final SitePreviewData data;
  final bool initiallyExpanded;

  @override
  State<UiSitePreviewCard> createState() => _UiSitePreviewCardState();
}

class _UiSitePreviewCardState extends State<UiSitePreviewCard> {
  late bool _expanded;

  static const _cardBg = Color(0xFF141418);
  static const _canvasBg = Color(0xFF0D0D11);
  static const _border = Color(0xFF26262C);
  static const _textPrimary = Color(0xFFF4F4F5);
  static const _textSecondary = Color(0xFFA1A1AA);

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _copyUrl(BuildContext context) {
    final u = widget.data.url.isNotEmpty ? widget.data.url : 'alienai.id/${widget.data.alienId}';
    Clipboard.setData(ClipboardData(text: 'https://$u'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL copied: https://$u'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openSite() async {
    final u = widget.data.url.isNotEmpty ? widget.data.url : 'alienai.id/${widget.data.alienId}';
    final uri = Uri.tryParse('https://$u');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _expanded ? _buildExpanded(context) : _buildCollapsed(context),
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final accent = widget.data.accentColor;
    final handle = widget.data.alienId.isNotEmpty ? '@${widget.data.alienId}' : '@site';

    return InkWell(
      onTap: () => setState(() => _expanded = true),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(Icons.language_rounded, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.data.name,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          handle,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Preview',
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Open',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final accent = widget.data.accentColor;
    final handle = widget.data.alienId.isNotEmpty ? '@${widget.data.alienId}' : '@site';
    final blocks = widget.data.blocks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Icon(Icons.language_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.data.name,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      handle,
                      style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copy URL',
                icon: const Icon(Icons.copy_rounded, size: 16, color: _textSecondary),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                onPressed: () => _copyUrl(context),
              ),
              IconButton(
                tooltip: 'Visit website',
                icon: Icon(Icons.open_in_new_rounded, size: 16, color: accent),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                onPressed: _openSite,
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Collapse',
                icon: const Icon(Icons.close_rounded, size: 16, color: _textSecondary),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                onPressed: () => setState(() => _expanded = false),
              ),
            ],
          ),
        ),

        // Live Simulated Web Preview Canvas
        Container(
          color: _canvasBg,
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Browser URL Bar simulator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: const Color(0xFF18181D),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'https://${widget.data.url}',
                            style: const TextStyle(color: _textSecondary, fontSize: 11, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Rendered Blocks
                if (blocks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Empty Site Document',
                        style: TextStyle(color: _textSecondary.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...blocks.map((block) => _buildBlock(block, accent)),
              ],
            ),
          ),
        ),

        // Action Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: _cardBg,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${blocks.length} sections · Live draft ready',
                  style: const TextStyle(color: _textSecondary, fontSize: 11),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyUrl(context),
                icon: const Icon(Icons.share_outlined, size: 14),
                label: const Text('Share URL', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openSite,
                icon: const Icon(Icons.launch_rounded, size: 14),
                label: const Text('Visit Site', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlock(Map<String, dynamic> block, Color accent) {
    final type = block['type']?.toString() ?? 'markdown';
    final props = block['props'] as Map<String, dynamic>? ?? const {};

    switch (type) {
      case 'hero':
        final title = props['title']?.toString() ?? widget.data.name;
        final subtitle = props['subtitle']?.toString() ?? '';
        final ctaLabel = props['cta_label']?.toString() ?? 'Hubungi Kami';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.withValues(alpha: 0.15), Colors.transparent],
            ),
            border: const Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'contact_form':
        final title = props['title']?.toString() ?? 'Hubungi Kami';
        final submitLabel = props['submit_label']?.toString() ?? 'Kirim Pesan';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: const Text(
                  'Nama Anda / Email...',
                  style: TextStyle(color: Color(0xFF52525B), fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    submitLabel,
                    style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'gallery':
      case 'product_grid':
        final title = props['title']?.toString() ?? 'Katalog & Layanan';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _productMockCard(accent, 'Item 1')),
                  const SizedBox(width: 8),
                  Expanded(child: _productMockCard(accent, 'Item 2')),
                  const SizedBox(width: 8),
                  Expanded(child: _productMockCard(accent, 'Item 3')),
                ],
              ),
            ],
          ),
        );

      default:
        // Markdown / general text
        final content = props['content']?.toString() ?? '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
          ),
          child: Text(
            content,
            style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12, height: 1.5),
          ),
        );
    }
  }

  Widget _productMockCard(Color accent, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(Icons.shopping_bag_outlined, size: 16, color: accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: _textPrimary, fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
