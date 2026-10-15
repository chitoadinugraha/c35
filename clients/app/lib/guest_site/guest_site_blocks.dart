import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/site/design/site_card_style.dart';
import 'package:alienai_c35/c/site/design/site_hub.dart';
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
import 'package:alienai_c35/c/site/guest_contact_api.dart';
import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:alienai_c35/c/site/guest_order_api.dart';
import 'package:alienai_c35/c/site/site_link_display.dart';
import 'package:alienai_c35/c/site/site_preview_external_url.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_shell.dart';
import 'package:alienai_c35/guest_site/guest_site_hours.dart';
import 'package:alienai_c35/guest_site/guest_site_i18n.dart';
import 'package:alienai_c35/guest_site/guest_site_layout.dart';
import 'package:alienai_c35/guest_site/guest_site_modal.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:alienai_c35/guest_site/guest_site_product.dart';
import 'package:alienai_c35/guest_site/guest_site_queue_sheet.dart';
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
  String siteAlienId = '',
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
  Map<String, dynamic> catalogMeta = const {},
  Color? foreground,
  Color? muted,
  List<Map<String, dynamic>> orderProgressSteps = const [],
  List<Map<String, dynamic>> bootQueues = const [],
  bool hubPostsUseProfileLimit = false,
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
    'contact_form' => GuestSiteContactFormBlock(props: props, accent: accent, siteIid: siteIid),
    'product_grid' => GuestSiteProductGridBlock(
        props: props,
        accent: accent,
        siteIid: siteIid,
        siteAlienId: siteAlienId,
        productDesign: products,
        products: productRows,
        commerceObjects: commerceObjects,
        initialNextCursor: productNextCursor,
        catalogMeta: catalogMeta,
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
        foreground: fg,
        muted: sub,
        hubProfileDesign: hubPostsUseProfileLimit ? design?.profileDesign : null,
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
        pageBackground: resolved?.pageBackground ?? const Color(0xFFF8F9FA),
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
    'order_track' => GuestSiteOrderTrackBlock(
        props: props,
        accent: accent,
        siteIid: siteIid,
        orderProgressSteps: orderProgressSteps,
      ),
    'map' => GuestSiteMapBlock(props: props, accent: accent),
    'queue' => GuestSiteQueueBlock(
        props: props,
        accent: accent,
        siteIid: siteIid,
        bootQueues: bootQueues,
      ),
    'embed' => GuestSiteEmbedBlock(props: props, accent: accent),
    'custom_html' => const GuestSiteCustomHtmlBlock(),
    'hours' => suppressHoursBlock
        ? const SizedBox.shrink()
        : openHours.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GuestSiteHoursCompact(openHours: openHours, fg: fg, muted: sub),
              )
            : GuestSiteHoursBlock(props: props, accent: accent, foreground: fg, muted: sub),
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
    this.openHours = const [],
    this.hoursPrimaryCta = false,
    this.showShareButton = true,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final String fallbackTitle;
  final String siteAvatar;
  final SiteProfileDesignDraft? profile;
  final Color? foreground;
  final Color? muted;
  final Key? avatarKey;
  final List<SiteScheduleSlot> openHours;
  final bool hoursPrimaryCta;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? fallbackTitle;
    final subtitle = props['subtitle']?.toString() ?? '';
    final ctaLabel =
        props['cta_label']?.toString() ?? props['cta']?.toString() ?? 'Hubungi Kami';
    final blockPic = props['pic']?.toString().trim() ?? '';
    final logo = blockPic.isNotEmpty ? blockPic : siteAvatar.trim();
    final fg = foreground ?? _guestTextPrimary;
    final sub = muted ?? _guestTextSecondary;
    final showAvatar = profile?.showAvatar ?? true;
    final showTitle = profile?.showTitle ?? true;
    final showBio = profile?.showBio ?? true;
    final titleAlign = TextAlign.center;
    final bioAlign = _guestTextAlign(profile?.bioAlign ?? 'center');
    final avatarSize = profile?.avatarSize ?? 72;
    final titleSize = profile?.titleFontSize ?? 18;
    final bioSize = profile?.bioFontSize ?? 12;
    final titleFamily = profile?.titleFontFamily.trim() ?? '';
    final bioFamily = profile?.bioFontFamily.trim() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 26),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: fg.withValues(alpha: 0.05))),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showAvatar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GuestProfileAvatar(
                    key: avatarKey,
                    accent: accent,
                    logoPic: logo,
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
                    decoration: TextDecoration.none,
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
              if (hoursPrimaryCta && openHours.isNotEmpty) ...[
                const SizedBox(height: 14),
                GuestSiteHoursCompact(
                  openHours: openHours,
                  fg: fg,
                  muted: sub,
                  primaryHubCta: true,
                  accent: accent,
                ),
              ] else if (_guestHubCtaHref(props) != null) ...[
                const SizedBox(height: 14),
                _GuestHubContactCta(
                  label: ctaLabel,
                  accent: accent,
                  href: _guestHubCtaHref(props),
                ),
              ],
            ],
            ),
          ),
          if (showShareButton)
            Positioned(
              top: -16,
              right: -4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fg.withValues(alpha: 0.05),
                      border: Border.all(color: fg.withValues(alpha: 0.1)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.share_outlined, size: 16, color: fg),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String? _guestHubCtaHref(Map<String, dynamic> props) {
  final href = props['cta_href']?.toString().trim() ?? props['cta_url']?.toString().trim() ?? '';
  return href.isEmpty ? null : href;
}

class _GuestHubContactCta extends StatelessWidget {
  const _GuestHubContactCta({required this.label, required this.accent, this.href});

  final String label;
  final Color accent;
  final String? href;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
    final decoration = BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2))],
    );
    if (href == null) {
      return DecoratedBox(decoration: decoration, child: child);
    }
    return Material(
      color: accent,
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(guestSiteLaunchUrl(href!)),
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _GuestProfileAvatar extends StatelessWidget {
  const _GuestProfileAvatar({
    super.key,
    required this.accent,
    required this.logoPic,
    required this.size,
    required this.outlineWidth,
    required this.outlineColor,
  });

  final Color accent;
  final String logoPic;
  final double size;
  final double outlineWidth;
  final String outlineColor;

  @override
  Widget build(BuildContext context) {
    final outline = outlineWidth.clamp(0, size / 2).toDouble();
    final inner = (size - outline * 2).clamp(8, size).toDouble();
    final ring = outlineColor.trim().isEmpty ? accent : siteColorParse(outlineColor);
    final placeholder = Icon(Icons.storefront_outlined, size: inner * 0.45, color: accent);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: outline > 0 ? Border.all(color: ring, width: outline) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: inner / 2,
        backgroundColor: accent.withValues(alpha: 0.15),
        child: ClipOval(
          child: logoPic.trim().isEmpty
              ? placeholder
              : GuestSitePic(
                  pic: logoPic,
                  width: inner,
                  height: inner,
                  error: placeholder,
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

class GuestSiteContactFormBlock extends StatefulWidget {
  const GuestSiteContactFormBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.siteIid,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;

  @override
  State<GuestSiteContactFormBlock> createState() => _GuestSiteContactFormBlockState();
}

class _GuestSiteContactFormBlockState extends State<GuestSiteContactFormBlock> {
  late final TextEditingController _nameCtrl = TextEditingController();
  late final TextEditingController _contactCtrl = TextEditingController();
  late final TextEditingController _messageCtrl = TextEditingController();
  var _submitting = false;
  String? _success;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _guestTextSecondary, fontSize: 12),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _guestBorder)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.accent)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  Future<void> _submit() async {
    if (widget.siteIid <= 0) {
      setState(() {
        _success = null;
        _error = 'Site tidak dikenali';
      });
      return;
    }
    final name = _nameCtrl.text.trim();
    final contactVal = _contactCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (name.isEmpty || contactVal.isEmpty) {
      setState(() {
        _success = null;
        _error = 'Lengkapi nama dan kontak';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _success = null;
      _error = null;
    });
    try {
      await GuestContactApi.contactPut(
        siteIid: widget.siteIid,
        name: name,
        contactVal: contactVal,
        message: message,
      );
      _nameCtrl.clear();
      _contactCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _success = 'Pesan terkirim';
        _error = null;
      });
    } catch (e) {
      setState(() {
        _success = null;
        _error = e.toString().replaceFirst('StateError: ', '');
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.props['title']?.toString() ?? 'Hubungi Kami';
    final submitLabel = widget.props['submit_label']?.toString() ?? 'Kirim Pesan';

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
            TextField(
              key: const Key('guest-form-name'),
              controller: _nameCtrl,
              decoration: _fieldDecoration('Nama Lengkap'),
              style: const TextStyle(color: _guestTextPrimary, fontSize: 13),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('guest-form-contact'),
              controller: _contactCtrl,
              decoration: _fieldDecoration('WhatsApp / No. HP'),
              style: const TextStyle(color: _guestTextPrimary, fontSize: 13),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('guest-form-message'),
              controller: _messageCtrl,
              decoration: _fieldDecoration('Pesan / Permintaan'),
              style: const TextStyle(color: _guestTextPrimary, fontSize: 13),
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('guest-form-submit'),
                onPressed: _submitting ? null : _submit,
                style: TextButton.styleFrom(
                  foregroundColor: widget.accent,
                  backgroundColor: widget.accent.withValues(alpha: 0.2),
                  side: BorderSide(color: widget.accent.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: _submitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: widget.accent),
                      )
                    : Text(
                        submitLabel,
                        style: TextStyle(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _success!,
                  style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuestProductInCartBadge extends StatelessWidget {
  const _GuestProductInCartBadge({required this.productId, required this.accent});

  final int productId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (productId <= 0) return const SizedBox.shrink();
    final cart = GuestSiteCartScope.maybeOf(context);
    if (cart == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final qty = cart.qtyForProduct(productId);
        if (qty <= 0) return const SizedBox.shrink();
        return Positioned(
          top: 8,
          right: 8,
          child: Container(
            key: ValueKey('guest-in-cart-$productId'),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$qty',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : _guestTextPrimary.withValues(alpha: 0.04),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? accent.withValues(alpha: 0.45) : _guestTextSecondary.withValues(alpha: 0.28),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? accent : _guestTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

typedef GuestSiteHubPostsBuilder = Widget Function({required bool postsExpanded});

class GuestSiteHubCatalogTabs extends StatefulWidget {
  const GuestSiteHubCatalogTabs({
    super.key,
    required this.shop,
    required this.postsBuilder,
    required this.accent,
    required this.profile,
    required this.postCount,
    required this.i18n,
    this.foreground,
  });

  final Widget shop;
  final GuestSiteHubPostsBuilder postsBuilder;
  final Color accent;
  final SiteProfileDesignDraft profile;
  final int postCount;
  final GuestSiteI18n i18n;
  final Color? foreground;

  @override
  State<GuestSiteHubCatalogTabs> createState() => _GuestSiteHubCatalogTabsState();
}

class _GuestSiteHubCatalogTabsState extends State<GuestSiteHubCatalogTabs> {
  late String _tab;
  var _postsExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncTab();
  }

  @override
  void didUpdateWidget(covariant GuestSiteHubCatalogTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.hubDefaultTab != widget.profile.hubDefaultTab ||
        oldWidget.postCount != widget.postCount) {
      _syncTab();
    }
  }

  void _syncTab() {
    _tab = siteHubInitialTab(
      design: widget.profile,
      hasProducts: true,
      hasPosts: widget.postCount > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.foreground ?? _guestTextPrimary;
    final muted = fg.withValues(alpha: 0.55);
    final postLimit = siteHubPostsPreviewLimit(widget.profile);
    final postsMore = !_postsExpanded && widget.postCount > postLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _hubTab(widget.i18n.hubTabShop, 'shop', fg, muted)),
                Expanded(child: _hubTab(widget.i18n.hubTabPosts, 'posts', fg, muted)),
              ],
            ),
          ),
        ),
        if (_tab == 'shop') widget.shop else ...[
          widget.postsBuilder(postsExpanded: _postsExpanded),
          if (postsMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  key: const Key('guest-hub-posts-see-all'),
                  onPressed: () => setState(() => _postsExpanded = true),
                  child: Text(widget.i18n.hubSeeAllPosts(widget.postCount)),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _hubTab(String label, String id, Color fg, Color muted) {
    final selected = _tab == id;
    return Material(
      color: selected ? fg.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _tab = id),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? fg : muted,
            ),
          ),
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
    this.siteAlienId = '',
    required this.productDesign,
    required this.products,
    this.commerceObjects = const [],
    this.initialNextCursor,
    this.catalogMeta = const {},
    this.resolved,
    this.foreground,
    this.muted,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;
  final String siteAlienId;
  final SiteProductDesignDraft productDesign;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> commerceObjects;
  final String? initialNextCursor;
  final Map<String, dynamic> catalogMeta;
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
  String? _categoryFilter;
  String _searchQuery = '';

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

  List<String> _categoryChips(List<Map<String, dynamic>> rows) {
    final blockCategory = widget.props['category']?.toString().trim() ?? '';
    if (blockCategory.isNotEmpty) return const [];
    final cats = <String>{};
    for (final p in rows) {
      final c = p['category']?.toString().trim() ?? '';
      if (c.isNotEmpty) cats.add(c);
    }
    if (cats.length < 2) return const [];
    return cats.toList()..sort();
  }

  List<Map<String, dynamic>> _filteredRows(List<Map<String, dynamic>> rows) {
    final f = _categoryFilter?.trim();
    if (f == null || f.isEmpty) return rows;
    return rows.where((p) => (p['category']?.toString().trim() ?? '') == f).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = GuestSiteI18n.fromMeta(widget.catalogMeta);
    final rawCatalogTitle = widget.props['title']?.toString().trim() ?? '';
    final showCatalogTitle =
        rawCatalogTitle.isNotEmpty && rawCatalogTitle != i18n.catalogDefaultTitle;
    final rows = _rows.isNotEmpty
        ? _rows
        : List.generate(3, (i) => {'name': 'Item ${i + 1}', 'pic': '', 'price': 0});
    final chips = _categoryChips(rows);
    var visible = _filteredRows(rows);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      visible = visible
          .where((p) => (p['name']?.toString() ?? '').toLowerCase().contains(q))
          .toList(growable: false);
    }
    final catalogDisplay = productGridDisplay(
      widget.props,
      meta: widget.catalogMeta,
      productCount: rows.length,
    );
    final layout = guestLayoutMode(widget.catalogMeta, productCount: rows.length);
    final showSearch = layout == 'store' || rows.length >= 9;

    final sectionFg = widget.foreground ?? _guestTextPrimary;
    final sectionMuted = widget.muted ?? _guestTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: sectionFg.withValues(alpha: 0.09))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCatalogTitle) ...[
            Text(
              rawCatalogTitle,
              style: TextStyle(
                color: sectionFg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (showSearch) ...[
            TextField(
              key: const Key('guest-catalog-search'),
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: sectionFg, fontSize: 14),
              decoration: InputDecoration(
                hintText: i18n.catalogSearchPlaceholder,
                hintStyle: TextStyle(color: sectionMuted),
                filled: true,
                fillColor: sectionFg.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: sectionMuted.withValues(alpha: 0.28)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: sectionMuted.withValues(alpha: 0.28)),
                ),
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: i18n.filterAll,
                    selected: (_categoryFilter ?? '').isEmpty,
                    accent: widget.accent,
                    onTap: () => setState(() => _categoryFilter = null),
                  ),
                  for (final c in chips) ...[
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: c,
                      selected: _categoryFilter == c,
                      accent: widget.accent,
                      onTap: () => setState(() => _categoryFilter = c),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // Phone site preview (~400px): list rows read better than tall 2-col cards (CSA parity).
              final useList = catalogDisplay == 'list' || constraints.maxWidth < 520;
              if (useList) {
                return Column(
                  children: [
                    for (final p in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _productListRow(widget.accent, widget.productDesign, p, i18n: i18n),
                      ),
                  ],
                );
              }
              final crossAxis = guestProductGridCrossAxisCount(constraints.maxWidth, layout);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxis,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: visible.length,
                itemBuilder: (_, i) => _productCard(widget.accent, widget.productDesign, visible[i], i18n: i18n),
              );
            },
          ),
          if (_nextCursor != null && widget.siteIid > 0) ...[
            const SizedBox(height: 12),
            Align(
              child: TextButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: Text(_loadingMore ? i18n.loading : i18n.loadMore),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _productListRow(
    Color accent,
    SiteProductDesignDraft design,
    Map<String, dynamic> p, {
    GuestSiteI18n i18n = GuestSiteI18n.english,
  }) {
    final name = p['name']?.toString() ?? 'Product';
    final desc = p['desc']?.toString() ?? p['description']?.toString() ?? '';
    final gallery = guestProductGalleryPaths(p);
    final pic = gallery.isNotEmpty ? gallery.first : (p['pic']?.toString() ?? '');
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
    ).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final stock = guestProductVisibleStock(p);
    final stockLabel = guestProductStockLabel(p);

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
      if (!guestProductCanAddToCart(price)) {
        _openProductDetail(p);
        return;
      }
      cart.openOrder(productId: pid, name: name, price: price, pic: pic, desc: desc, stockMax: stock);
    }

    final priceLabel = guestProductPriceLabel(price, i18n: i18n);
    final quoteOnly = price == guestProductPriceContact;

    final pid = (p['product_id'] as num?)?.toInt() ?? 0;
    final row = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: pic.trim().isNotEmpty
                          ? GuestSitePic(
                              pic: pic,
                              height: 68,
                              width: 68,
                              fit: BoxFit.cover,
                              error: _brokenPicPlaceholder(accent),
                            )
                          : _productThumbPlaceholder(accent, p['icon']?.toString() ?? '', size: 68),
                    ),
                    _GuestProductInCartBadge(productId: pid, accent: accent),
                  ],
                ),
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
                    if (stockLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(stockLabel, style: subtitleStyle),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!quoteOnly && priceLabel.isNotEmpty) Text(priceLabel, style: priceStyle),
                  if (quoteOnly)
                    TextButton(
                      onPressed: () => _openProductDetail(p),
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(i18n.tileContactCta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          );

    return _wrapProductTile(onProductTap, row, productId: pid);
  }

  Widget _productCard(
    Color accent,
    SiteProductDesignDraft design,
    Map<String, dynamic> p, {
    GuestSiteI18n i18n = GuestSiteI18n.english,
  }) {
    final name = p['name']?.toString() ?? 'Product';
    final desc = p['desc']?.toString() ?? p['description']?.toString() ?? '';
    final gallery = guestProductGalleryPaths(p);
    final pic = gallery.isNotEmpty ? gallery.first : (p['pic']?.toString() ?? '');
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
      fallbackSize: 11,
    );
    final priceStyle = guestSiteProductTextStyle(
      design,
      'price',
      fallbackColor: widget.accent,
      fallbackSize: 13,
      fallbackWeight: FontWeight.w700,
    ).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final priceLabel = guestProductPriceLabel(price, i18n: i18n);
    final quoteOnly = price == guestProductPriceContact;
    final stock = guestProductVisibleStock(p);
    final stockLabel = guestProductStockLabel(p);

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
      if (!guestProductCanAddToCart(price)) {
        _openProductDetail(p);
        return;
      }
      cart.openOrder(productId: pid, name: name, price: price, pic: pic, desc: desc, stockMax: stock);
    }

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (pic.trim().isNotEmpty)
                  GuestSitePic(
                    pic: pic,
                    fit: BoxFit.cover,
                    error: _brokenPicPlaceholder(accent),
                  )
                else
                  _productThumbPlaceholder(accent, p['icon']?.toString() ?? '', size: double.infinity),
                _GuestProductInCartBadge(productId: (p['product_id'] as num?)?.toInt() ?? 0, accent: accent),
                if (p['can_reserve'] == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 1)),
                        ],
                      ),
                      child: const Text('Reservasi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (stock != null && stock > 0 && stock <= 3)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55EF4444), blurRadius: 6, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Text('Sisa $stock', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(desc, style: subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              if (stockLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(stockLabel, style: subtitleStyle),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (quoteOnly)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          onPressed: () => _openProductDetail(p),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(i18n.tileContactCta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    )
                  else if (priceLabel.isNotEmpty)
                    Text(priceLabel, style: priceStyle),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final pid = (p['product_id'] as num?)?.toInt() ?? 0;
    return _wrapProductTile(onProductTap, card, rounded: true, productId: pid);
  }

  Widget _wrapProductTile(
    VoidCallback onTap,
    Widget child, {
    bool rounded = false,
    int productId = 0,
  }) {
    final cart = GuestSiteCartScope.maybeOf(context);
    Widget wrapped(Widget inner) {
      final resolved = widget.resolved;
      if (resolved != null && resolved.isBare('site_product')) {
        return InkWell(onTap: onTap, child: inner);
      }
      if (resolved != null) {
        return siteCardWrap(
          card: resolved.cardFor('site_product'),
          child: InkWell(onTap: onTap, child: inner),
        );
      }
      return Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _guestBorder.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: rounded ? Clip.antiAlias : Clip.none,
            child: inner,
          ),
        ),
      );
    }

    if (cart == null || productId <= 0) {
      return wrapped(child);
    }
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final inCart = cart.qtyForProduct(productId) > 0;
        final inner = inCart
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(rounded ? 16 : 14),
                  border: Border.all(color: widget.accent.withValues(alpha: 0.38)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              )
            : child;
        return wrapped(inner);
      },
    );
  }

  void _openProductDetail(Map<String, dynamic> product) {
    final cart = GuestSiteCartScope.maybeOf(context);
    unawaited(guestSiteOpenProductDetail(
      context: context,
      siteIid: widget.siteIid,
      product: product,
      objects: widget.commerceObjects,
      accent: widget.accent,
      cart: cart,
    ));
  }

  Widget _productThumbPlaceholder(Color accent, String icon, {double? size}) {
    final id = icon.trim().isEmpty ? 'mdi:shopping' : icon.trim();
    final side = size ?? 56.0;
    return Container(
      height: side == double.infinity ? null : side,
      width: side == double.infinity ? null : side,
      constraints: size == double.infinity ? const BoxConstraints.expand() : null,
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
    final iconLinks = items
        .where((it) => siteLinkDisplayNormalize(it['display']?.toString() ?? '') == siteLinkDisplayIcon)
        .toList(growable: false);
    final listLinks = items
        .where((it) => siteLinkDisplayNormalize(it['display']?.toString() ?? '') != siteLinkDisplayIcon)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleProp.isNotEmpty) ...[
            Text(
              titleProp,
              style: TextStyle(
                color: fg.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (iconLinks.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final item in iconLinks)
                  _guestLinkTile(
                    item,
                    fg: fg,
                    bare: bare,
                    listInset: false,
                    showDivider: false,
                  ),
              ],
            ),
            if (listLinks.isNotEmpty) const SizedBox(height: 14),
          ],
          if (listLinks.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fg.withValues(alpha: 0.07)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < listLinks.length; i++)
                    _guestLinkTile(
                      listLinks[i],
                      fg: fg,
                      bare: bare,
                      listInset: true,
                      showDivider: i < listLinks.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _guestLinkTile(
    Map<String, dynamic> item, {
    required Color fg,
    required bool bare,
    bool listInset = false,
    bool showDivider = false,
  }) {
    final mode = siteLinkDisplayNormalize(item['display']?.toString() ?? '');
    final iconId = (item['icon']?.toString().trim().isNotEmpty ?? false) ? item['icon']!.toString() : 'website';
    final label = item['label']?.toString() ?? item['title']?.toString() ?? 'Link';
    final icon = UiSitePlatformIcon(id: iconId, size: mode == siteLinkDisplayIcon ? 24 : 20);

    if (mode == siteLinkDisplayIcon) {
      return Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _guestBorder),
          color: fg.withValues(alpha: 0.04),
        ),
        child: icon,
      );
    }

    final row = Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    if (mode == siteLinkDisplayCard) {
      return SizedBox(
        width: double.infinity,
        child: _linkChrome(bare: bare, child: row),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: listInset ? 16 : 4, vertical: listInset ? 14 : 10),
        decoration: BoxDecoration(
          border: showDivider || !listInset
              ? Border(bottom: BorderSide(color: _guestBorder.withValues(alpha: listInset ? 0.35 : 0.65)))
              : null,
        ),
        child: row,
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
    this.foreground,
    this.muted,
    this.hubProfileDesign,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final List<Map<String, dynamic>> postsPreload;
  final Color? foreground;
  final Color? muted;
  final SiteProfileDesignDraft? hubProfileDesign;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? 'Update';
    final limitRaw = props['limit'];
    var limit = (limitRaw is num ? limitRaw.toInt() : 20).clamp(1, 20);
    if (hubProfileDesign != null) {
      limit = siteHubPostsPreviewLimit(hubProfileDesign!);
    }
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
            style: TextStyle(
              color: foreground ?? _guestTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
    this.pageBackground = const Color(0xFFF8F9FA),
  });

  final Map<String, dynamic> props;
  final Color accent;
  final String fallbackTitle;
  final List<SiteScheduleSlot> openHours;
  final String siteAvatar;
  final SiteProfileDesignDraft? profile;
  final Color? foreground;
  final Color? muted;
  final Color pageBackground;

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
          openHours: openHours,
          hoursPrimaryCta: showHours,
          showShareButton: false,
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
      ],
    );
  }
}

class _GuestOrderProgressSteps extends StatelessWidget {
  const _GuestOrderProgressSteps({
    required this.steps,
    required this.activeState,
    required this.accent,
  });

  final List<Map<String, dynamic>> steps;
  final String activeState;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step['state']?.toString() == activeState ? accent : _guestTextSecondary.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    step['label']?.toString() ?? step['state']?.toString() ?? '',
                    style: TextStyle(
                      color: step['state']?.toString() == activeState ? accent : _guestTextSecondary,
                      fontSize: 11,
                      fontWeight: step['state']?.toString() == activeState ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class GuestSiteOrderTrackBlock extends StatefulWidget {
  const GuestSiteOrderTrackBlock({
    super.key,
    required this.props,
    required this.accent,
    required this.siteIid,
    this.orderProgressSteps = const [],
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;
  final List<Map<String, dynamic>> orderProgressSteps;

  @override
  State<GuestSiteOrderTrackBlock> createState() => _GuestSiteOrderTrackBlockState();
}

class _GuestSiteOrderTrackBlockState extends State<GuestSiteOrderTrackBlock> {
  late final TextEditingController _txCtrl = TextEditingController();
  String? _status;
  String? _activeState;
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
      _activeState = null;
    });
    try {
      final visitorId = await GuestAssistantApi.visitorIdForSite(widget.siteIid);
      final res = await GuestOrderApi.orderGet(siteIid: widget.siteIid, txId: txId, visitorId: visitorId);
      final tx = res['tx'];
      if (tx is! Map) throw StateError('Pesanan tidak ditemukan');
      final txMap = Map<String, dynamic>.from(tx);
      final label = guestOrderTrackPollLabel(txMap);
      final state = txMap['state']?.toString() ?? txMap['status']?.toString() ?? '';
      setState(() {
        _status = label;
        _activeState = state;
      });
    } catch (e) {
      setState(() {
        _status = null;
        _activeState = null;
        _error = e.toString();
      });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.orderProgressSteps.isNotEmpty && (_activeState ?? '').isNotEmpty)
                    _GuestOrderProgressSteps(
                      steps: widget.orderProgressSteps,
                      activeState: _activeState!,
                      accent: widget.accent,
                    ),
                  Text(_status!, style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
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
      onTap: () => unawaited(guestSiteOpenPostDetail(context: context, post: post, accent: accent)),
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
  const GuestSiteHoursBlock({
    super.key,
    required this.props,
    required this.accent,
    this.foreground,
    this.muted,
  });

  final Map<String, dynamic> props;
  final Color accent;
  final Color? foreground;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final title = props['title']?.toString() ?? 'Jam Operasional';
    final hoursRaw = props['hours'] ?? props['schedule'];
    final rows = hoursRaw is List ? hoursRaw.whereType<Map<String, dynamic>>().toList(growable: false) : const <Map<String, dynamic>>[];

    if (rows.isEmpty) return const SizedBox.shrink();

    final fg = foreground ?? _guestTextPrimary;
    final sub = muted ?? _guestTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: fg.withValues(alpha: 0.09))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w600),
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
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text(
                        '${r['open'] ?? r['from'] ?? ''} – ${r['close'] ?? r['to'] ?? ''}',
                        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500),
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

/// Guest stock line (`Stock: 4 pcs`, capped as `9+`) when show-to-customer is on.
String? guestProductStockLabel(Map<String, dynamic> product) {
  final qty = guestProductVisibleStock(product);
  if (qty == null || qty <= 0) return null;
  final extras = _guestProductJsonMap(product['product_json']);
  final unit = (extras['stock_unit']?.toString() ?? product['stock_unit']?.toString() ?? '').trim();
  final max = (extras['stock_show_max_qty'] as num?)?.toInt() ??
      (product['stock_show_max_qty'] as num?)?.toInt() ??
      0;
  final display = max > 0 && qty > max ? '$max+' : '$qty';
  final suffix = unit.isEmpty ? '' : ' $unit';
  return 'Stock: $display$suffix';
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
    this.bootQueues = const [],
  });

  final Map<String, dynamic> props;
  final Color accent;
  final int siteIid;
  final List<Map<String, dynamic>> bootQueues;

  @override
  State<GuestSiteQueueBlock> createState() => _GuestSiteQueueBlockState();
}

class _GuestSiteQueueBlockState extends State<GuestSiteQueueBlock> {
  String? _status;
  String? _error;
  var _opening = false;
  GuestQueueTrackPoller? _poller;

  int get _queueId {
    final raw = widget.props['queue_id'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> get _fields => guestQueueResolveFields(
        props: widget.props,
        bootQueues: widget.bootQueues,
        queueId: _queueId,
      );

  bool get _takeOnline => guestQueueTakeOnline(widget.props, widget.bootQueues, _queueId);

  @override
  void initState() {
    super.initState();
    unawaited(_restoreTrack());
  }

  @override
  void dispose() {
    _poller?.dispose();
    super.dispose();
  }

  Future<void> _restoreTrack() async {
    if (widget.siteIid <= 0 || _queueId <= 0) return;
    final token = await guestQueueReadTrackToken(widget.siteIid, _queueId);
    if (token == null || token.isEmpty || !mounted) return;
    _startPolling(token);
  }

  void _startPolling(String trackToken) {
    _poller?.dispose();
    _poller = GuestQueueTrackPoller(
      siteIid: widget.siteIid,
      trackToken: trackToken,
      onStatus: (label) {
        if (mounted) setState(() => _status = label);
      },
    );
    _poller!.start();
  }

  void _onTaken(Map<String, dynamic> result) {
    final label = result['display_label']?.toString().trim() ?? '';
    final trackToken = result['track_token']?.toString().trim() ?? '';
    if (label.isNotEmpty) {
      setState(() => _status = label);
    } else {
      setState(() => _status = guestQueueFormatTrackStatus(result));
    }
    if (trackToken.isNotEmpty) {
      unawaited(guestQueuePersistTrackToken(widget.siteIid, _queueId, trackToken));
      _startPolling(trackToken);
    }
  }

  Future<void> _openTake() async {
    if (widget.siteIid <= 0 || _opening) return;
    if (!_takeOnline) {
      setState(() => _error = 'Antrian online tidak tersedia');
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final title = widget.props['title']?.toString().trim().isNotEmpty == true
          ? widget.props['title'].toString()
          : (widget.props['label']?.toString().trim().isNotEmpty == true
              ? widget.props['label'].toString()
              : 'Antrian');
      if (_fields.isEmpty) {
        final result = await guestQueueTake(
          siteIid: widget.siteIid,
          queueId: _queueId,
          answers: const {},
        );
        if (mounted) _onTaken(result);
        return;
      }
      if (!mounted) return;
      await showGuestSiteQueueSheet(
        context: context,
        siteIid: widget.siteIid,
        queueId: _queueId,
        title: title,
        fields: _fields,
        accent: widget.accent,
        onTaken: _onTaken,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is StateError ? e.message : 'Gagal ambil nomor');
      }
    } finally {
      if (mounted) setState(() => _opening = false);
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
    return KeyedSubtree(
      key: const Key('guest-queue-block'),
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
            if (mode.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(mode, style: const TextStyle(color: _guestTextSecondary, fontSize: 11)),
            ],
            const SizedBox(height: 8),
            TextButton(
              key: const Key('guest-queue-open'),
              onPressed: widget.siteIid > 0 && !_opening && _takeOnline ? _openTake : null,
              child: const Text('Ambil nomor'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _status!,
                  key: const Key('guest-queue-status'),
                  style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11)),
              ),
          ],
        ),
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

/// Route args for `/products/{id}` in-app preview (public URL parity).
class GuestSiteProductRouteArgs {
  const GuestSiteProductRouteArgs({
    required this.siteIid,
    required this.product,
    required this.objects,
    required this.accent,
    this.cart,
  });

  final int siteIid;
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> objects;
  final Color accent;
  final GuestSiteCartController? cart;
}

class GuestSitePostRouteArgs {
  const GuestSitePostRouteArgs({required this.post, required this.accent});

  final Map<String, dynamic> post;
  final Color accent;
}

class GuestSiteProductDetailContent extends StatelessWidget {
  const GuestSiteProductDetailContent({
    super.key,
    required this.siteIid,
    required this.product,
    required this.objects,
    required this.accent,
    this.cart,
    this.onClose,
  });

  final int siteIid;
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> objects;
  final Color accent;
  final GuestSiteCartController? cart;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Product';
    final desc = product['desc']?.toString() ?? product['description']?.toString() ?? '';
    final price = product['price'] is num ? (product['price'] as num).toInt() : 0;
    final pid = (product['product_id'] as num?)?.toInt() ?? 0;
    final canReserve = product['can_reserve'] == true;
    final gallery = guestProductGalleryPaths(product);
    final pic = gallery.isNotEmpty ? gallery.first : (product['pic']?.toString() ?? '');
    final icon = product['icon']?.toString() ?? '';
    final stock = guestProductVisibleStock(product);
    final stockLabel = guestProductStockLabel(product);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (gallery.isEmpty)
          _guestDetailIcon(accent, icon)
        else if (gallery.length == 1)
          GestureDetector(
            onTap: () => unawaited(showGuestSitePicViewer(context, gallery.first)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GuestSitePic(
                pic: gallery.first,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                variant: GuestSitePicVariant.display,
                error: _guestDetailIcon(accent, icon),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: PageView.builder(
              itemCount: gallery.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => unawaited(showGuestSitePicViewer(context, gallery[i])),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GuestSitePic(
                      pic: gallery[i],
                      fit: BoxFit.cover,
                      variant: GuestSitePicVariant.display,
                      error: _guestDetailIcon(accent, icon),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(color: _guestTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: _guestTextSecondary, fontSize: 13, height: 1.4)),
        ],
        if (guestProductPriceLabel(price).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            guestProductPriceLabel(price),
            style: const TextStyle(color: _guestTextPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
        if (stockLabel != null) ...[
          const SizedBox(height: 6),
          Text(stockLabel, style: const TextStyle(color: _guestTextSecondary, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        if (canReserve && cart != null && pid > 0)
          TextButton(
            onPressed: () async {
              onClose?.call();
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
        else if (!canReserve && cart != null && pid > 0 && guestProductCanAddToCart(price))
          TextButton(
            onPressed: () {
              cart!.openOrder(productId: pid, name: name, price: price, pic: pic, desc: desc, stockMax: stock);
              onClose?.call();
            },
            child: const Text('+ Pesan'),
          ),
      ],
    );
  }
}

class GuestSitePostDetailContent extends StatelessWidget {
  const GuestSitePostDetailContent({super.key, required this.post, required this.accent});

  final Map<String, dynamic> post;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = post['title']?.toString() ?? 'Post';
    final caption = post['caption']?.toString() ?? '';
    final body = post['body']?.toString() ?? '';
    final thumb = post['thumb']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (thumb.trim().isNotEmpty) ...[
          GestureDetector(
            onTap: () => unawaited(showGuestSitePicViewer(context, thumb)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GuestSitePic(
                pic: thumb,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                variant: GuestSitePicVariant.display,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
  return guestSiteShowModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    builder: (sheetContext) {
      return Padding(
        key: const Key('guest-product-detail'),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(sheetContext).bottom),
        child: SingleChildScrollView(
          child: GuestSiteProductDetailContent(
            siteIid: siteIid,
            product: product,
            objects: objects,
            accent: accent,
            cart: cart,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      );
    },
  );
}

Future<void> guestSiteOpenProductDetail({
  required BuildContext context,
  required int siteIid,
  required Map<String, dynamic> product,
  required List<Map<String, dynamic>> objects,
  required Color accent,
  GuestSiteCartController? cart,
}) async {
  final pid = (product['product_id'] as num?)?.toInt() ?? 0;
  if (pid <= 0) return;
  final shellNav = GuestSiteShellScope.maybeNavigatorKey(context)?.currentState;
  if (shellNav != null) {
    await shellNav.pushNamed<void>(
      '/products/$pid',
      arguments: GuestSiteProductRouteArgs(
        siteIid: siteIid,
        product: product,
        objects: objects,
        accent: accent,
        cart: cart,
      ),
    );
    return;
  }
  await showGuestSiteProductDetailSheet(
    context: context,
    siteIid: siteIid,
    product: product,
    objects: objects,
    accent: accent,
    cart: cart,
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
  Color accent = const Color(0xFFF97316),
}) {
  return guestSiteShowModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    builder: (sheetContext) {
      return Padding(
        key: const Key('guest-post-detail'),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewPaddingOf(sheetContext).bottom),
        child: SingleChildScrollView(
          child: GuestSitePostDetailContent(post: post, accent: accent),
        ),
      );
    },
  );
}

Future<void> guestSiteOpenPostDetail({
  required BuildContext context,
  required Map<String, dynamic> post,
  required Color accent,
}) async {
  final id = post['id']?.toString() ?? '';
  final shellNav = GuestSiteShellScope.maybeNavigatorKey(context)?.currentState;
  if (shellNav != null && id.isNotEmpty) {
    await shellNav.pushNamed<void>(
      '/posts/$id',
      arguments: GuestSitePostRouteArgs(post: post, accent: accent),
    );
    return;
  }
  await showGuestSitePostDetailSheet(context: context, post: post, accent: accent);
}
