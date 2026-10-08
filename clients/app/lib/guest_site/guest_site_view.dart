import 'dart:convert';
import 'dart:ui';

import 'package:alienai_c35/c/pb/c35/site.pbenum.dart';
import 'package:alienai_c35/c/site/design/site_backdrop.dart';
import 'package:alienai_c35/c/site/design/site_design_models.dart';
import 'package:alienai_c35/c/site/design/site_design_resolve.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/guest_site/guest_site_blocks.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_effect_stack.dart';
import 'package:alienai_c35/guest_site/guest_site_hours.dart';
import 'package:alienai_c35/guest_site/guest_site_pic.dart';
import 'package:alienai_c35/widgets/sites/ui_powered_by_alien.dart';
import 'package:flutter/material.dart';

const _guestTextSecondary = Color(0xFFA1A1AA);
const _guestTextPrimary = Color(0xFFF4F4F5);

/// Renders v1 site blocks from `site_boot_get` JSON (guest HTML parity in Flutter).
class GuestSiteView extends StatelessWidget {
  const GuestSiteView({
    super.key,
    required this.boot,
    this.blockKeyAt,
    this.emptyLabel = 'Empty Site Document',
  });

  factory GuestSiteView.bootJson({
    Key? key,
    required Map<String, dynamic> bootJson,
    GlobalKey? Function(int index)? blockKeyAt,
    String emptyLabel = 'Empty Site Document',
  }) =>
      GuestSiteView(
        key: key,
        boot: GuestSiteBoot.fromJson(bootJson),
        blockKeyAt: blockKeyAt,
        emptyLabel: emptyLabel,
      );

  final GuestSiteBoot boot;
  final GlobalKey? Function(int index)? blockKeyAt;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) => _GuestSiteBody(
        boot: boot,
        blockKeyAt: blockKeyAt,
        emptyLabel: emptyLabel,
      );
}

/// Fetches boot via [SiteApi.bootGet] then renders [GuestSiteView].
class GuestSiteBootLoader extends StatefulWidget {
  const GuestSiteBootLoader({
    super.key,
    required this.siteApi,
    required this.siteIid,
    this.mode = SiteBootMode.SITE_BOOT_MODE_DRAFT,
    this.blockKeyAt,
    this.emptyLabel = 'Empty Site Document',
    this.loading,
    this.error,
  });

  final SiteApi siteApi;
  final int siteIid;
  final SiteBootMode mode;
  final GlobalKey? Function(int index)? blockKeyAt;
  final String emptyLabel;
  final Widget? loading;
  final Widget? error;

  @override
  State<GuestSiteBootLoader> createState() => _GuestSiteBootLoaderState();
}

class _GuestSiteBootLoaderState extends State<GuestSiteBootLoader> {
  late Future<GuestSiteBoot> _future = _load();

  Future<GuestSiteBoot> _load() => widget.siteApi.bootGet(widget.siteIid, mode: widget.mode).then((res) {
        final raw = jsonDecode(res.bootJson);
        if (raw is! Map<String, dynamic>) throw StateError('invalid boot_json');
        return GuestSiteBoot.fromJson(raw);
      });

  @override
  void didUpdateWidget(covariant GuestSiteBootLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid || oldWidget.mode != widget.mode) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<GuestSiteBoot>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return widget.loading ??
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                );
          }
          if (snap.hasError || !snap.hasData) {
            return widget.error ??
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Could not load site preview',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ),
                );
          }
          return GuestSiteView(
            boot: snap.data!,
            blockKeyAt: widget.blockKeyAt,
            emptyLabel: widget.emptyLabel,
          );
        },
      );
}

class _GuestSiteBody extends StatelessWidget {
  const _GuestSiteBody({
    required this.boot,
    required this.blockKeyAt,
    required this.emptyLabel,
  });

  final GuestSiteBoot boot;
  final GlobalKey? Function(int index)? blockKeyAt;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final blocks = boot.homeBlocks;
    final accent = boot.accentColor;
    final openHours = boot.openHoursSlots;
    final hubShowsHours = blocks.any((b) {
      if (b['type']?.toString() != 'hub_profile') return false;
      final props = b['props'];
      return props is Map && props['show_hours'] == true;
    });

    if (blocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            emptyLabel,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
          ),
        ),
      );
    }

    final resolved = boot.design == null ? null : siteDesignResolve(boot.design!);
    final fg = resolved?.fg ?? _guestTextPrimary;
    final muted = resolved?.muted ?? _guestTextSecondary;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++)
          KeyedSubtree(
            key: blockKeyAt?.call(i),
            child: guestSiteBlock(
              block: blocks[i],
              accent: accent,
              siteName: boot.name,
              siteIid: boot.siteIid,
              productDesign: boot.productDesign,
              productRows: boot.productsForBlock(blocks[i]['id']?.toString() ?? ''),
              commerceObjects: boot.commerceObjects,
              productNextCursor: boot.nextProductCursorForBlock(blocks[i]['id']?.toString() ?? ''),
              hubLinks: boot.links,
              postsPreload: boot.postsPreload,
              openHours: openHours,
              suppressHoursBlock: hubShowsHours,
              siteAvatar: boot.avatarUrl,
              design: boot.design,
              featuredContacts: boot.featuredContacts,
              foreground: fg,
              muted: muted,
            ),
          ),
        if (boot.shouldShowMetaLocation) _GuestSiteMetaLocationChip(accent: accent, label: boot.locationLabel),
        if (boot.shouldShowMetaHours && !hubShowsHours)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GuestSiteHoursCompact(openHours: openHours),
          ),
        const SizedBox(height: 28),
        Center(child: UiPoweredByAlien(color: muted, strongColor: fg)),
        const SizedBox(height: 88),
      ],
    );

    if (resolved == null) return GuestSiteEffectStack(effects: boot.effects, child: column);
    return _GuestSiteCanvas(resolved: resolved, effects: boot.effects, child: column);
  }
}

/// Backdrop host. [backdropId] is the normalized preset (`none`, `glow`, `mesh`, `grain`, `diamond`, `aurora`).
class GuestSiteBackdrop extends StatelessWidget {
  const GuestSiteBackdrop({super.key, required this.backdropId, required this.child});

  final String backdropId;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        label: backdropId,
        container: true,
        child: child,
      );
}

class _GuestSiteCanvas extends StatelessWidget {
  const _GuestSiteCanvas({required this.resolved, required this.effects, required this.child});

  final SiteResolvedDesign resolved;
  final List<Map<String, dynamic>> effects;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = resolved.background;
    final backdropId = siteBackdropNormalizeId(resolved.backdrop.id);
    return ColoredBox(
      color: resolved.pageBackground,
      child: Stack(
        children: [
          if (bg.type == 'image') Positioned.fill(child: _GuestSiteBackgroundImage(background: bg)),
          if (bg.overlay > 0)
            Positioned.fill(
              child: ColoredBox(
                color: (bg.overlayTone == 'light' ? Colors.white : Colors.black).withValues(alpha: bg.overlay.clamp(0, 1)),
              ),
            ),
          Positioned.fill(
            child: GuestSiteBackdrop(
              key: const Key('guest-backdrop'),
              backdropId: backdropId,
              child: siteBackdropLayer(
                style: resolved.backdrop,
                theme: resolved.theme,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          GuestSiteEffectStack(effects: effects, child: child),
        ],
      ),
    );
  }
}

class _GuestSiteBackgroundImage extends StatelessWidget {
  const _GuestSiteBackgroundImage({required this.background});

  final SiteBackgroundDraft background;

  @override
  Widget build(BuildContext context) {
    final url = guestSitePicUrl(background.url);
    if (url.isEmpty) return const SizedBox.expand();
    Widget image = DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      child: const SizedBox.expand(),
    );
    if (background.blur > 0) {
      final sigma = background.blur;
      image = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: image);
    }
    return image;
  }
}

class _GuestSiteMetaLocationChip extends StatelessWidget {
  const _GuestSiteMetaLocationChip({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                  Icon(Icons.location_on_outlined, size: 14, color: accent),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 276),
                    child: Text(label, style: const TextStyle(color: _guestTextSecondary, fontSize: 12, height: 1.35)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
