import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_color.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart'
    show
        SiteFeaturedStripDraft,
        SiteProfileDesignDraft,
        siteFeaturedClientsDefaultHeader,
        siteFeaturedPartnersDefaultHeader,
        siteFeaturedStripItemModeCard,
        siteFeaturedStripItemModeIconLabel,
        siteFeaturedStripItemModeNormalize;
import 'package:alienai_c35/c/site/design/site_design_resolve.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/site/guest_order_api.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_hours.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:alienai_c35/guest_site/guest_site_reservation_sheet.dart';
import 'package:alienai_c35/guest_site/guest_site_product_design.dart';
import 'package:alienai_c35/widgets/ai/ui_markdown_body.dart';
import 'package:alienai_c35/widgets/sites/ui_site_platform_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _guestTextPrimary = Color(0xFFF4F4F5);
const _guestTextSecondary = Color(0xFFA1A1AA);
const _guestBorder = Color(0xFF26262C);

TextAlign _guestTextAlign(String raw) => switch (raw.trim()) {
      'left' || 'start' => TextAlign.left,
      'right' || 'end' => TextAlign.right,
      _ => TextAlign.center,
    };

Alignment _guestAlignment(String raw) => switch (raw.trim()) {
      'left' || 'start' => Alignment.centerLeft,
      'right' || 'end' => Alignment.centerRight,
      _ => Alignment.center,
    };

WrapAlignment _guestWrapAlignment(String raw) => switch (raw.trim()) {
      'left' || 'start' => WrapAlignment.start,
      'right' || 'end' => WrapAlignment.end,
      _ => WrapAlignment.center,
    };

Widget guestSiteBlock({
  required Map<String, dynamic> block,
  required Color accent,
  required String siteName,
  int siteIid = 0,
  SiteProductDesignDraft productDesign = const SiteProductDesignDraft(),
  List<Map<String, dynamic>> productRows = const [],
  List<Map<String, dynamic>> commerceObjects = const [],
  String? productNextCursor,
  List<Map<String, dynamic>> hubLinks = const [],
  List<Map<String, dynamic>> postsPreload = const [],
  List<SiteScheduleSlot> openHours = const [],
  bool suppressHoursBlock = false,
  String siteAvatar = '',
  SiteDesignStore? design,
  List<Map<String, dynamic>> featuredContacts = const [],
  Color? foreground,
  Color? muted,
}) {
  final type = block['type']?.toString() ?? 'markdown';
  final props = block['props'] is Map<String, dynamic>
      ? block['props'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final resolved = design == null ? null : siteDesignResolve(design);
  final fg = foreground ?? resolved?.fg ?? _guestTextPrimary;
  final sub = muted ?? resolved?.muted ?? _guestTextSecondary;
  final products = design?.productDesign ?? productDesign;

  return switch (type) {
    'hero' => GuestSiteHeroBlock(props: props, accent: accent, fallbackTitle: siteName, siteAvatar: siteAvatar),
    'contact_form' => GuestSiteContactFormBlock(props: props, accent: accent),
    'product_grid' => GuestSiteProductGridBlock(
        props: props,
        accent: accent,
        siteIid: siteIid,
        productDesign: products,
        products: productRows,
        commerceObjects: commerceObjects,
        initialNextCursor: productNextCursor,
        resolved: resolved,
        foreground: fg,
        muted: sub,
      ),
    'gallery' => GuestSiteGalleryBlock(props: props, accent: accent),
    'image' => GuestSiteImageBlock(props: props, accent: accent),
    'links' => GuestSiteLinksBlock(
        props: props,
        accent: accent,
        hubLinks: hubLinks,
        resolved: resolved,
        foreground: fg,
      ),
    'social_feed' => GuestSiteSocialFeedBlock(
        props: props,
        accent: accent,
        postsPreload: postsPreload,
      ),
    'hub_profile' => GuestSiteHubProfileBlock(
        props: props,
        accent: accent,
        fallbackTitle: siteName,
        openHours: openHours,
        siteAvatar: siteAvatar,
        profile: design?.profileDesign,
        foreground: fg,
        muted: sub,
      ),
    'partners_display' => GuestSiteFeaturedStripBlock(
        kind: 'partners',
        strip: design?.featuredStripGet('partners') ?? const SiteFeaturedStripDraft(header: siteFeaturedPartnersDefaultHeader),
        contacts: featuredContacts,
        resolved: resolved,
        foreground: fg,
        muted: sub,
      ),
    'clients_display' => GuestSiteFeaturedStripBlock(
        kind: 'clients',
        strip: design?.featuredStripGet('clients') ?? const SiteFeaturedStripDraft(header: siteFeaturedClientsDefaultHeader),
        contacts: featuredContacts,
        resolved: resolved,
        foreground: fg,
        muted: sub,
      ),
    'order_track' => GuestSiteOrderTrackBlock(props: props, accent: accent, siteIid: siteIid),
    'map' => GuestSiteMapBlock(props: props, accent: accent),
    'queue' => GuestSiteQueueBlock(props: props, accent: accent, siteIid: siteIid),
    'embed' => GuestSiteEmbedBlock(props: props, accent: accent),
    'custom_html' => const GuestSiteCustomHtmlBlock(),
    'hours' => suppressHoursBlock
        ? const SizedBox.shrink()
        : openHours.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GuestSiteHoursCompact(openHours: openHours),
              )
            : GuestSiteHoursBlock(props: props, accent: accent),
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
    this.siteAvatar = '',
    this.profile,
    this.foreground,
    this.muted,
    this.avatarKey,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final String fallbackTitle;
  final String siteAvatar;
  final SiteProfileDesignDraft? profile;
  final Color? foreground;
  final Color? muted;
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? fallbackTitle;
    final subtitle = props['subtitle']?.toString() ?? '';
    final ctaLabel =
        props['cta_label']?.toString() ?? props['cta']?.toString() ?? 'Hubungi Kami';
    final blockPic = props['pic']?.toString().trim() ?? '';
    final logo = blockPic.isNotEmpty ? blockPic : siteAvatar.trim();
    final logoUrl = guestSitePicUrl(logo);
    final fg = foreground ?? _guestTextPrimary;
    final sub = muted ?? _guestTextSecondary;
    final showAvatar = profile?.showAvatar ?? true;
    final showTitle = profile?.showTitle ?? true;
    final showBio = profile?.showBio ?? true;
    final titleAlign = _guestTextAlign(profile?.titleAlign ?? 'center');
    final bioAlign = _guestTextAlign(profile?.bioAlign ?? 'center');
    final avatarSize = profile?.avatarSize ?? 72;
    final titleSize = profile?.titleFontSize ?? 18;
    final bioSize = profile?.bioFontSize ?? 12;
    final titleFamily = profile?.titleFontFamily.trim() ?? '';
    final bioFamily = profile?.bioFontFamily.trim() ?? '';

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
          if (showAvatar)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GuestProfileAvatar(
                key: avatarKey,
                accent: accent,
                logoUrl: logoUrl,
                size: avatarSize,
                outlineWidth: profile?.avatarOutlineWidth ?? 0,
                outlineColor: profile?.avatarOutlineColor ?? '',
              ),
            ),
          if (showTitle)
            Text(
              title,
              textAlign: titleAlign,
              style: TextStyle(
                color: fg,
                fontSize: titleSize,
                fontFamily: titleFamily.isEmpty ? null : titleFamily,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          if (showBio && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: bioAlign,
              style: TextStyle(
                color: sub,
                fontSize: bioSize,
                height: 1.4,
                fontFamily: bioFamily.isEmpty ? null : bioFamily,
              ),
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

class _GuestProfileAvatar extends StatelessWidget {
  const _GuestProfileAvatar({
    super.key,
    required this.accent,
    required this.logoUrl,
    required this.size,
    required this.outlineWidth,
    required this.outlineColor,
  });

  final Color accent;
  final String logoUrl;
  final double size;
  final double outlineWidth;
  final String outlineColor;

  @override
  Widget build(BuildContext context) {
    final outline = outlineWidth.clamp(0, size / 2).toDouble();
    final inner = (size - outline * 2).clamp(8, size).toDouble();
    final ring = outlineColor.trim().isEmpty ? accent : siteColorParse(outlineColor);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: outline > 0 ? Border.all(color: ring, width: outline) : null,
      ),
      child: CircleAvatar(
        radius: inner / 2,
        backgroundColor: accent.withValues(alpha: 0.15),
        child: ClipOval(
          child: logoUrl.isEmpty
              ? Icon(Icons.storefront_outlined, size: inner * 0.45, color: accent)
              : Image.network(
                  logoUrl,
                  width: inner,
                  height: inner,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.storefront_outlined, size: inner * 0.45, color: accent),
                ),
        ),
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

    return KeyedSubtree(
      key: const Key('guest-form'),
      child: Container(
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
    required this.productDesign,
    required this.products,
    this.commerceObjects = const [],
    this.initialNextCursor,
    this.resolved,
    this.foreground,
    this.muted,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;
  final SiteProductDesignDraft productDesign;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> commerceObjects;
  final String? initialNextCursor;
  final SiteResolvedDesign? resolved;
  final Color? foreground;
  final Color? muted;

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
          for (final p in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _productListRow(widget.accent, widget.productDesign, p),
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

  Widget _productListRow(Color accent, SiteProductDesignDraft design, Map<String, dynamic> p) {
    final name = p['name']?.toString() ?? 'Product';
    final desc = p['desc']?.toString() ?? p['description']?.toString() ?? '';
    final picUrl = guestSitePicUrl(p['pic']?.toString() ?? '');
    final price = p['price'] is num ? (p['price'] as num).toInt() : 0;
    final fg = widget.foreground ?? _guestTextPrimary;
    final sub = widget.muted ?? _guestTextSecondary;
    final titleStyle = guestSiteProductTextStyle(
      design,
      'title',
      fallbackColor: fg,
      fallbackSize: 14,
      fallbackWeight: FontWeight.w600,
    );
    final subtitleStyle = guestSiteProductTextStyle(
      design,
      'subtitle',
      fallbackColor: sub,
      fallbackSize: 12,
    );
    final priceStyle = guestSiteProductTextStyle(
      design,
      'price',
      fallbackColor: sub,
      fallbackSize: 13,
      fallbackWeight: FontWeight.w700,
    );

    void onProductTap() {
      final cart = GuestSiteCartScope.maybeOf(context);
      final pid = (p['product_id'] as num?)?.toInt() ?? 0;
      if (cart == null || pid <= 0) return;
      if (p['can_reserve'] == true) {
        unawaited(showGuestSiteReservationSheet(
          context: context,
          siteIid: widget.siteIid,
          product: p,
          objects: widget.commerceObjects,
          accent: accent,
        ));
        return;
      }
      if (price <= 0) return;
      cart.addProduct(productId: pid, name: name, price: price);
    }

    final stock = guestProductVisibleStock(p);

    final row = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: picUrl.isNotEmpty
                    ? Image.network(
                        picUrl,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _brokenPicPlaceholder(accent),
                      )
                    : _productThumbPlaceholder(accent, p['icon']?.toString() ?? ''),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, key: const Key('guest-product-title'), style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(desc, style: subtitleStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    if (stock != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Stock: $stock', style: subtitleStyle),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price > 0) Text(moneyFmtIdr(price), style: priceStyle),
                  IconButton(
                    tooltip: 'Detail',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => _openProductDetail(p),
                    icon: Icon(Icons.info_outline, size: 18, color: sub),
                  ),
                ],
              ),
            ],
          );

    final resolved = widget.resolved;
    if (resolved != null && resolved.isBare('site_product')) {
      return InkWell(onTap: onProductTap, child: row);
    }
    if (resolved != null) {
      return siteCardWrap(
        card: resolved.cardFor('site_product'),
        child: InkWell(onTap: onProductTap, child: row),
      );
    }
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onProductTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _guestBorder),
          ),
          child: row,
        ),
      ),
    );
  }

  void _openProductDetail(Map<String, dynamic> product) {
    final cart = GuestSiteCartScope.maybeOf(context);
    unawaited(showGuestSiteProductDetailSheet(
      context: context,
      siteIid: widget.siteIid,
      product: product,
      objects: widget.commerceObjects,
      accent: widget.accent,
      cart: cart,
    ));
  }

  Widget _productThumbPlaceholder(Color accent, String icon) {
    final id = icon.trim().isEmpty ? 'mdi:shopping' : icon.trim();
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: UiIcon('iconify://$id', size: 22, color: accent)),
    );
  }

  Widget _brokenPicPlaceholder(Color accent) => Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Icon(Icons.shopping_bag_outlined, size: 22, color: accent)),
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
    this.resolved,
    this.foreground,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final List<Map<String, dynamic>> hubLinks;
  final SiteResolvedDesign? resolved;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final titleProp = props['title']?.toString().trim() ?? '';
    final linksRaw = props['links'] ?? props['items'];
    final fromProps =
        linksRaw is List ? linksRaw.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];
    final items = fromProps.isNotEmpty ? fromProps : hubLinks;

    if (items.isEmpty) return const SizedBox.shrink();

    final fg = foreground ?? _guestTextPrimary;
    final bare = resolved?.isBare('link') ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleProp.isNotEmpty) ...[
            Text(
              titleProp,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
          ],
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _linkChrome(
                bare: bare,
                child: Row(
                  children: [
                    UiSitePlatformIcon(
                      id: (item['icon']?.toString().trim().isNotEmpty ?? false) ? item['icon']!.toString() : 'website',
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['label']?.toString() ?? item['title']?.toString() ?? 'Link',
                        style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _linkChrome({required bool bare, required Widget child}) {
    if (bare) return child;
    if (resolved != null) {
      return KeyedSubtree(
        key: const Key('guest-link-card'),
        child: siteCardWrap(card: resolved!.cardFor('link'), child: child),
      );
    }
    return Material(
      key: const Key('guest-link-card'),
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _guestBorder),
        ),
        child: child,
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
    this.openHours = const [],
    this.siteAvatar = '',
    this.profile,
    this.foreground,
    this.muted,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final String fallbackTitle;
  final List<SiteScheduleSlot> openHours;
  final String siteAvatar;
  final SiteProfileDesignDraft? profile;
  final Color? foreground;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final location = props['location_label']?.toString().trim() ?? '';
    final showLocation = location.isNotEmpty && (profile?.showLocation ?? true);
    final showHours = (profile?.showHours ?? true) && props['show_hours'] == true && openHours.isNotEmpty;
    final sub = muted ?? _guestTextSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuestSiteHeroBlock(
          props: props,
          accent: accent,
          fallbackTitle: fallbackTitle,
          siteAvatar: siteAvatar,
          profile: profile,
          foreground: foreground,
          muted: muted,
          avatarKey: const Key('guest-profile-avatar'),
        ),
        if (showLocation)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Center(
              child: Material(
                color: _guestTextPrimary.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _guestTextSecondary.withValues(alpha: 0.28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: sub),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 276),
                        child: Text(location, style: TextStyle(color: sub, fontSize: 12, height: 1.35)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (showHours)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GuestSiteHoursCompact(openHours: openHours),
          ),
      ],
    );
  }
}

class GuestSiteOrderTrackBlock extends StatefulWidget {
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
  State<GuestSiteOrderTrackBlock> createState() => _GuestSiteOrderTrackBlockState();
}

class _GuestSiteOrderTrackBlockState extends State<GuestSiteOrderTrackBlock> {
  late final TextEditingController _txCtrl = TextEditingController();
  String? _status;
  String? _error;

  @override
  void dispose() {
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _poll() async {
    if (widget.siteIid <= 0) return;
    final txId = int.tryParse(_txCtrl.text.trim()) ?? 0;
    if (txId <= 0) {
      setState(() => _error = 'Masukkan nomor pesanan');
      return;
    }
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      final res = await GuestOrderApi.orderGet(siteIid: widget.siteIid, txId: txId);
      final tx = res['tx'];
      if (tx is! Map) throw StateError('Pesanan tidak ditemukan');
      final label = tx['progress_label']?.toString() ?? tx['state']?.toString() ?? '—';
      setState(() => _status = label);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.props['title']?.toString() ?? 'Lacak pesanan';
    final hint = widget.props['hint']?.toString() ?? '';
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
            controller: _txCtrl,
            decoration: InputDecoration(
              labelText: 'No. pesanan',
              labelStyle: const TextStyle(color: _guestTextSecondary, fontSize: 12),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _guestBorder)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accent)),
            ),
            style: const TextStyle(color: _guestTextPrimary, fontSize: 13),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: widget.siteIid > 0 ? _poll : null, child: const Text('Cek status')),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_status!, style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11)),
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
    return InkWell(
      onTap: () => showGuestSitePostDetailSheet(context: context, post: post),
      child: Padding(
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

class GuestSiteFeaturedStripBlock extends StatelessWidget {
  const GuestSiteFeaturedStripBlock({
    super.key,
    required this.kind,
    required this.strip,
    required this.contacts,
    this.resolved,
    this.foreground,
    this.muted,
  });

  final String kind;
  final SiteFeaturedStripDraft strip;
  final List<Map<String, dynamic>> contacts;
  final SiteResolvedDesign? resolved;
  final Color? foreground;
  final Color? muted;

  String get _blockId => kind == 'partners' ? 'partners_display' : 'clients_display';

  Key get _headerKey => Key(kind == 'partners' ? 'guest-partners-header' : 'guest-clients-header');

  Key get _itemKey => Key(kind == 'partners' ? 'guest-partners-item' : 'guest-clients-item');

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? _guestTextPrimary;
    final sub = muted ?? _guestTextSecondary;
    final headerFamily = strip.headerFontFamily.trim();
    final items = [
      for (final c in contacts)
        if ((c['featured']?.toString() ?? '') == kind) c,
    ];
    final mode = siteFeaturedStripItemModeNormalize(strip.itemMode);
    final showName = strip.showLabel || mode == siteFeaturedStripItemModeIconLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: _guestAlignment(strip.headerAlign),
            child: Text(
              strip.header,
              key: _headerKey,
              textAlign: _guestTextAlign(strip.headerAlign),
              style: TextStyle(
                color: fg,
                fontSize: strip.headerFontSize,
                fontFamily: headerFamily.isEmpty ? null : headerFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: _guestAlignment(strip.itemAlign),
              child: Wrap(
                alignment: _guestWrapAlignment(strip.itemAlign),
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items) _item(item, mode: mode, showName: showName, fg: fg, sub: sub),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(
    Map<String, dynamic> item, {
    required String mode,
    required bool showName,
    required Color fg,
    required Color sub,
  }) {
    final name = item['name']?.toString() ?? '';
    final picUrl = guestSitePicUrl(item['pic']?.toString() ?? '');
    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: fg.withValues(alpha: 0.08),
      backgroundImage: picUrl.isEmpty ? null : NetworkImage(picUrl),
      child: picUrl.isEmpty ? Icon(Icons.person_outline, size: 18, color: sub) : null,
    );
    final label = showName && name.isNotEmpty
        ? Text(name, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600))
        : null;
    final body = mode == siteFeaturedStripItemModeCard || mode == siteFeaturedStripItemModeIconLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              if (label != null) ...[const SizedBox(width: 8), label],
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              if (label != null) ...[const SizedBox(height: 4), label],
            ],
          );
    if (mode == siteFeaturedStripItemModeCard && resolved != null && !resolved!.isBare(_blockId)) {
      return KeyedSubtree(
        key: _itemKey,
        child: siteCardWrap(card: resolved!.cardFor(_blockId), child: body),
      );
    }
    if (mode == siteFeaturedStripItemModeCard) {
      return Container(
        key: _itemKey,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _guestBorder),
        ),
        child: body,
      );
    }
    return KeyedSubtree(key: _itemKey, child: body);
  }
}

String guestSiteOsmCoord(num value) {
  final d = value.toDouble();
  if (!d.isFinite) return '0';
  if (d == d.truncateToDouble()) return d.truncate().toString();
  return d.toString();
}

String guestSiteOsmUrl(Map<String, dynamic> props) {
  final lat = props['lat'] is num ? props['lat'] as num : 0;
  final lng = props['lng'] is num ? props['lng'] as num : 0;
  final zoomRaw = props['zoom'];
  final zoom = zoomRaw is num ? zoomRaw.toInt() : 14;
  final latText = guestSiteOsmCoord(lat);
  final lngText = guestSiteOsmCoord(lng);
  return 'https://www.openstreetmap.org/?mlat=$latText&mlon=$lngText#map=$zoom/$latText/$lngText';
}

String guestSiteMapLabel(Map<String, dynamic> props) {
  final address = props['address']?.toString().trim() ?? '';
  if (address.isNotEmpty) return address;
  final lat = props['lat'] is num ? props['lat'] as num : 0;
  final lng = props['lng'] is num ? props['lng'] as num : 0;
  return '${guestSiteOsmCoord(lat)}, ${guestSiteOsmCoord(lng)}';
}

Future<void> guestSiteLaunchUrl(String raw) async {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !uri.hasScheme) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

int? guestProductVisibleStock(Map<String, dynamic> product) {
  if (!_guestStockShownToCustomer(product)) return null;
  final direct = _guestStockCount(product['stock'] ?? product['stock_qty']);
  if (direct != null) return direct;
  final extras = _guestProductJsonMap(product['product_json']);
  return _guestStockCount(extras['stock'] ?? extras['stock_qty']);
}

bool _guestStockShownToCustomer(Map<String, dynamic> product) {
  if (product['stock_show_to_customer'] == true) return true;
  final extras = _guestProductJsonMap(product['product_json']);
  return extras['stock_show_to_customer'] == true;
}

Map<String, dynamic> _guestProductJsonMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return const {};
}

int? _guestStockCount(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final n = num.tryParse(raw.trim());
    if (n != null) return n.toInt();
  }
  return null;
}

class GuestSiteMapBlock extends StatelessWidget {
  const GuestSiteMapBlock({super.key, required this.props, required this.accent});

  final Map<String, dynamic> props;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final label = guestSiteMapLabel(props);
    final url = guestSiteOsmUrl(props);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: () => guestSiteLaunchUrl(url),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: accent,
          ),
        ),
      ),
    );
  }
}

class GuestSiteQueueBlock extends StatefulWidget {
  const GuestSiteQueueBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.siteIid,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;

  @override
  State<GuestSiteQueueBlock> createState() => _GuestSiteQueueBlockState();
}

class _GuestSiteQueueBlockState extends State<GuestSiteQueueBlock> {
  String? _status;
  String? _error;
  var _busy = false;

  int get _queueId {
    final raw = widget.props['queue_id'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  Future<void> _take() async {
    if (widget.siteIid <= 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await http.post(
        Uri.parse('$authApiProductionUrl/v1/site/guest-queue/take'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'site_iid': widget.siteIid,
          'queue_id': _queueId,
        }),
      );
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) throw StateError('Gagal ambil nomor');
      if (decoded['ok'] != true) {
        final err = decoded['error']?.toString().trim() ?? '';
        throw StateError(err.isEmpty ? 'Gagal ambil nomor' : err);
      }
      final ticket = decoded['ticket_no'];
      final serving = decoded['serving_ticket_no'];
      if (mounted) {
        setState(() => _status = 'Nomor Anda: $ticket (sedang dilayani: $serving)');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is StateError ? e.message : 'Gagal ambil nomor');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.props['title']?.toString().trim().isNotEmpty == true
        ? widget.props['title'].toString()
        : (widget.props['label']?.toString().trim().isNotEmpty == true
            ? widget.props['label'].toString()
            : 'Antrian');
    final mode = widget.props['mode']?.toString() ?? '';
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
          if (mode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(mode, style: const TextStyle(color: _guestTextSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.siteIid > 0 && !_busy ? _take : null,
            child: const Text('Ambil nomor'),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_status!, style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class GuestSiteEmbedBlock extends StatelessWidget {
  const GuestSiteEmbedBlock({super.key, required this.props, required this.accent});

  final Map<String, dynamic> props;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? '';
    final url = props['url']?.toString() ?? '';
    if (title.isEmpty && url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          if (url.isNotEmpty) ...[
            if (title.isNotEmpty) const SizedBox(height: 6),
            InkWell(
              onTap: () => guestSiteLaunchUrl(url),
              child: Text(
                url,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GuestSiteCustomHtmlBlock extends StatelessWidget {
  const GuestSiteCustomHtmlBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'Custom HTML is on the published page only.',
        style: TextStyle(color: _guestTextSecondary, fontSize: 12),
      ),
    );
  }
}

Future<void> showGuestSiteProductDetailSheet({
  required BuildContext context,
  required int siteIid,
  required Map<String, dynamic> product,
  required List<Map<String, dynamic>> objects,
  required Color accent,
  GuestSiteCartController? cart,
}) {
  final name = product['name']?.toString() ?? 'Product';
  final desc = product['desc']?.toString() ?? product['description']?.toString() ?? '';
  final price = product['price'] is num ? (product['price'] as num).toInt() : 0;
  final pid = (product['product_id'] as num?)?.toInt() ?? 0;
  final canReserve = product['can_reserve'] == true;
  final picUrl = guestSitePicUrl(product['pic']?.toString() ?? '');
  final icon = product['icon']?.toString() ?? '';
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(sheetContext).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (picUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    picUrl,
                    height: 96,
                    width: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _guestDetailIcon(accent, icon),
                  ),
                )
              else
                _guestDetailIcon(accent, icon),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(color: _guestTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(color: _guestTextSecondary, fontSize: 13, height: 1.4)),
              ],
              if (price > 0) ...[
                const SizedBox(height: 8),
                Text(
                  moneyFmtIdr(price),
                  style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 12),
              if (canReserve && cart != null && pid > 0)
                TextButton(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await showGuestSiteReservationSheet(
                      context: context,
                      siteIid: siteIid,
                      product: product,
                      objects: objects,
                      accent: accent,
                    );
                  },
                  child: const Text('Reservasi'),
                )
              else if (!canReserve && cart != null && pid > 0 && price > 0)
                TextButton(
                  onPressed: () {
                    cart.addProduct(productId: pid, name: name, price: price);
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('+ Pesan'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _guestDetailIcon(Color accent, String icon) {
  final id = icon.trim().isEmpty ? 'mdi:shopping' : icon.trim();
  return Container(
    height: 96,
    width: 96,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(child: UiIcon('iconify://$id', size: 28, color: accent)),
  );
}

Future<void> showGuestSitePostDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> post,
}) {
  final title = post['title']?.toString() ?? 'Post';
  final caption = post['caption']?.toString() ?? '';
  final body = post['body']?.toString() ?? '';
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(sheetContext).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: _guestTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(caption, style: const TextStyle(color: _guestTextSecondary, fontSize: 13)),
              ],
              if (body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(body, style: const TextStyle(color: _guestTextPrimary, fontSize: 13, height: 1.45)),
              ],
            ],
          ),
        ),
      );
    },
  );
}
