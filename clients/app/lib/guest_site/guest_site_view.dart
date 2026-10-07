import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pbenum.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/guest_site/guest_site_blocks.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:flutter/material.dart';

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

    return Column(
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
              productRows: boot.productsForBlock(blocks[i]['id']?.toString() ?? ''),
              productNextCursor:
                  boot.nextProductCursorForBlock(blocks[i]['id']?.toString() ?? ''),
              hubLinks: boot.links,
              postsPreload: boot.postsPreload,
            ),
          ),
      ],
    );
  }
}
