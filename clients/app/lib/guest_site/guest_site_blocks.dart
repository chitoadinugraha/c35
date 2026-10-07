import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:alienai_c35/widgets/ai/ui_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _guestTextPrimary = Color(0xFFF4F4F5);
const _guestTextSecondary = Color(0xFFA1A1AA);
const _guestBorder = Color(0xFF26262C);

Widget guestSiteBlock({
  required Map<String, dynamic> block,
  required Color accent,
  required String siteName,
  int siteIid = 0,
  List<Map<String, dynamic>> productRows = const [],
  String? productNextCursor,
  List<Map<String, dynamic>> hubLinks = const [],
  List<Map<String, dynamic>> postsPreload = const [],
}) {
  final type = block['type']?.toString() ?? 'markdown';
  final props = block['props'] is Map<String, dynamic>
      ? block['props'] as Map<String, dynamic>
      : const <String, dynamic>{};

  return switch (type) {
    'hero' => GuestSiteHeroBlock(props: props, accent: accent, fallbackTitle: siteName),
    'contact_form' => GuestSiteContactFormBlock(props: props, accent: accent),
    'product_grid' => GuestSiteProductGridBlock(
        props: props,
        accent: accent,
        siteIid: siteIid,
        products: productRows,
        initialNextCursor: productNextCursor,
      ),
    'gallery' => GuestSiteGalleryBlock(props: props, accent: accent),
    'image' => GuestSiteImageBlock(props: props, accent: accent),
    'links' => GuestSiteLinksBlock(props: props, accent: accent, hubLinks: hubLinks),
    'social_feed' => GuestSiteSocialFeedBlock(
        props: props,
        accent: accent,
        postsPreload: postsPreload,
      ),
    'hub_profile' => GuestSiteHubProfileBlock(props: props, accent: accent, fallbackTitle: siteName),
    'order_track' => GuestSiteOrderTrackBlock(props: props, accent: accent, siteIid: siteIid),
    'hours' => GuestSiteHoursBlock(props: props, accent: accent),
    'spacer' => GuestSiteSpacerBlock(props: props),
    _ => GuestSiteMarkdownBlock(props: props),
  };
}

class GuestSiteHeroBlock extends StatelessWidget {
  const GuestSiteHeroBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.fallbackTitle,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? fallbackTitle;
    final subtitle = props['subtitle']?.toString() ?? '';
    final ctaLabel =
        props['cta_label']?.toString() ?? props['cta']?.toString() ?? 'Hubungi Kami';
    final pic = props['pic']?.toString() ?? '';
    final picUrl = guestSitePicUrl(pic);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.14), Colors.transparent],
        ),
        border: const Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (picUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  picUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _guestTextPrimary,
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
              style: const TextStyle(color: _guestTextSecondary, fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
            child: Text(
              ctaLabel,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class GuestSiteMarkdownBlock extends StatelessWidget {
  const GuestSiteMarkdownBlock({super.key, required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final content = props['body']?.toString() ?? props['content']?.toString() ?? '';
    if (content.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
      ),
      child: UiMarkdownBody(
        data: content,
        styleSheet: uiMarkdownChatStyleSheet(
          p: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12, height: 1.5),
          h1: const TextStyle(color: _guestTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          h2: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          h3: const TextStyle(color: _guestTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class GuestSiteContactFormBlock extends StatelessWidget {
  const GuestSiteContactFormBlock({super.key, required this.props, required this.accent});

  final Map<String, dynamic> props;
  final Color accent;

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _guestBorder),
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
  }
}

class GuestSiteProductGridBlock extends StatefulWidget {
  const GuestSiteProductGridBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.siteIid,
    required this.products,
    this.initialNextCursor,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;
  final List<Map<String, dynamic>> products;
  final String? initialNextCursor;

  @override
  State<GuestSiteProductGridBlock> createState() => _GuestSiteProductGridBlockState();
}

class _GuestSiteProductGridBlockState extends State<GuestSiteProductGridBlock> {
  late List<Map<String, dynamic>> _rows = List<Map<String, dynamic>>.from(widget.products);
  late String? _nextCursor = widget.initialNextCursor?.trim().isEmpty ?? true
      ? null
      : widget.initialNextCursor?.trim();
  var _loadingMore = false;

  @override
  void didUpdateWidget(covariant GuestSiteProductGridBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products || oldWidget.initialNextCursor != widget.initialNextCursor) {
      _rows = List<Map<String, dynamic>>.from(widget.products);
      _nextCursor = widget.initialNextCursor?.trim().isEmpty ?? true
          ? null
          : widget.initialNextCursor?.trim();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || widget.siteIid <= 0 || (_nextCursor ?? '').isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final filter = widget.props['filter']?.toString() ?? 'all';
      final category = widget.props['category']?.toString() ?? '';
      final uri = Uri.parse('$authApiProductionUrl/v1/site/guest-product/list');
      final resp = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'site_iid': widget.siteIid,
          'filter': filter,
          'category': category,
          'cursor': _nextCursor,
          'limit': 24,
        }),
      );
      if (resp.statusCode != 200) throw StateError('guest product list failed');
      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) throw StateError('invalid guest product response');
      final items = data['items'];
      if (items is List) {
        _rows.addAll(items.whereType<Map<String, dynamic>>());
      }
      final next = data['next_cursor']?.toString() ?? '';
      _nextCursor = next.isEmpty ? null : next;
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.props['title']?.toString() ?? 'Katalog & Layanan';
    final rows = _rows.isNotEmpty
        ? _rows
        : List.generate(3, (i) => {'name': 'Item ${i + 1}', 'pic': '', 'price': 0});

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
            style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 360 ? 3 : 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in rows)
                    SizedBox(
                      width: (constraints.maxWidth - (cols - 1) * 8) / cols,
                      child: _productCard(widget.accent, p),
                    ),
                ],
              );
            },
          ),
          if (_nextCursor != null && widget.siteIid > 0) ...[
            const SizedBox(height: 12),
            Align(
              child: TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? 'Memuat…' : 'Muat lebih banyak'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _productCard(Color accent, Map<String, dynamic> p) {
    final name = p['name']?.toString() ?? 'Product';
    final picUrl = guestSitePicUrl(p['pic']?.toString() ?? '');
    final price = p['price'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _guestBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: picUrl.isNotEmpty
                ? Image.network(
                    picUrl,
                    height: 48,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _productPlaceholder(accent),
                  )
                : _productPlaceholder(accent),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(color: _guestTextPrimary, fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (price > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Rp $price',
                style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productPlaceholder(Color accent) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: Icon(Icons.shopping_bag_outlined, size: 16, color: accent)),
      );
}

class GuestSiteSpacerBlock extends StatelessWidget {
  const GuestSiteSpacerBlock({super.key, required this.props});

  final Map<String, dynamic> props;

  @override
  Widget build(BuildContext context) {
    final h = (props['height'] as num?)?.toDouble() ?? 16;
    return SizedBox(height: h.clamp(4, 120));
  }
}

class GuestSiteGalleryBlock extends StatelessWidget {
  const GuestSiteGalleryBlock({super.key, required this.props, required this.accent});

  final Map<String, dynamic> props;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? '';
    final picsRaw = props['pics'];
    final pics = picsRaw is List
        ? picsRaw.map((p) => p.toString()).where((s) => s.isNotEmpty).toList(growable: false)
        : const <String>[];

    if (pics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pic in pics)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    guestSitePicUrl(pic),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.white.withValues(alpha: 0.05),
                      child: Icon(Icons.broken_image_outlined, size: 20, color: _guestTextSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class GuestSiteImageBlock extends StatelessWidget {
  const GuestSiteImageBlock({super.key, required this.props, required this.accent});

  final Map<String, dynamic> props;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pic = props['pic']?.toString() ?? '';
    final alt = props['alt']?.toString() ?? '';
    final caption = props['caption']?.toString() ?? '';
    final url = guestSitePicUrl(pic);

    if (url.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              semanticLabel: alt.isNotEmpty ? alt : null,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _guestTextSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class GuestSiteLinksBlock extends StatelessWidget {
  const GuestSiteLinksBlock({
    super.key,
    required this.props,
    required this.accent,
    this.hubLinks = const [],
  });

  final Map<String, dynamic> props;
  final Color accent;
  final List<Map<String, dynamic>> hubLinks;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? '';
    final linksRaw = props['links'] ?? props['items'];
    final fromProps =
        linksRaw is List ? linksRaw.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
    final items = fromProps.isNotEmpty ? fromProps : hubLinks;

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x15FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _guestBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 14, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['label']?.toString() ?? item['title']?.toString() ?? 'Link',
                            style: const TextStyle(color: _guestTextPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 12, color: _guestTextSecondary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class GuestSiteSocialFeedBlock extends StatelessWidget {
  const GuestSiteSocialFeedBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.postsPreload,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final List<Map<String, dynamic>> postsPreload;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? 'Update';
    final limitRaw = props['limit'];
    final limit = (limitRaw is num ? limitRaw.toInt() : 20).clamp(1, 20);
    final posts = postsPreload.take(limit).toList(growable: false);
    if (posts.isEmpty) return const SizedBox.shrink();

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
            style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          for (final post in posts) GuestSitePostSummary(post: post, accent: accent),
        ],
      ),
    );
  }
}

class GuestSiteHubProfileBlock extends StatelessWidget {
  const GuestSiteHubProfileBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.fallbackTitle,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) => GuestSiteHeroBlock(
        props: props,
        accent: accent,
        fallbackTitle: fallbackTitle,
      );
}

class GuestSiteOrderTrackBlock extends StatelessWidget {
  const GuestSiteOrderTrackBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.siteIid,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? 'Lacak pesanan';
    final hint = props['hint']?.toString() ?? '';
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
            style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(hint, style: const TextStyle(color: _guestTextSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'No. pesanan',
              labelStyle: const TextStyle(color: _guestTextSecondary, fontSize: 12),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _guestBorder)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accent)),
            ),
            style: const TextStyle(color: _guestTextPrimary, fontSize: 13),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          Text(
            siteIid > 0 ? 'Status — cek di situs publik' : 'Preview lacak pesanan',
            style: TextStyle(color: accent.withValues(alpha: 0.85), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class GuestSitePostSummary extends StatelessWidget {
  const GuestSitePostSummary({super.key, required this.post, required this.accent});

  final Map<String, dynamic> post;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = post['title']?.toString() ?? 'Post';
    final caption = post['caption']?.toString() ?? '';
    final thumbUrl = guestSitePicUrl(post['thumb']?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(thumbUrl, width: 48, height: 48, fit: BoxFit.cover),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _guestTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _guestTextSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: accent),
        ],
      ),
    );
  }
}

class GuestSiteHoursBlock extends StatelessWidget {
  const GuestSiteHoursBlock({super.key, required this.props, required this.accent});

  final Map<String, dynamic> props;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? 'Jam Operasional';
    final hoursRaw = props['hours'] ?? props['schedule'];
    final rows = hoursRaw is List ? hoursRaw.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];

    if (rows.isEmpty) return const SizedBox.shrink();

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
            style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
            children: [
              for (final r in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Text(
                        r['day']?.toString() ?? r['label']?.toString() ?? '',
                        style: const TextStyle(color: _guestTextSecondary, fontSize: 11),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text(
                        '${r['open'] ?? r['from'] ?? ''} – ${r['close'] ?? r['to'] ?? ''}',
                        style: const TextStyle(color: _guestTextPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
