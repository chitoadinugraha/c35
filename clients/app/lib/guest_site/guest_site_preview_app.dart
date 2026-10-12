import 'package:alienai_c35/c/site/design/site_design_resolve.dart';
import 'package:alienai_c35/c/site/design/site_theme.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_shell.dart';
import 'package:flutter/material.dart';

ThemeData _guestSitePreviewTheme(GuestSiteBoot boot) {
  if (boot.design != null) {
    return siteThemeMaterial(siteDesignResolve(boot.design!).theme);
  }
  return siteThemeMaterial(siteThemeResolve('zinc', true).tokens);
}

/// Guest hub inside a clipped preview viewport — nested [MaterialApp] (CSA [UiSitePreviewApp]).
class GuestSitePreviewApp extends StatefulWidget {
  const GuestSitePreviewApp({
    super.key,
    required this.boot,
    this.blockKeyAt,
    this.emptyLabel = 'Empty Site Document',
  });

  factory GuestSitePreviewApp.bootJson({
    Key? key,
    required Map<String, dynamic> bootJson,
    GlobalKey? Function(int index)? blockKeyAt,
    String emptyLabel = 'Empty Site Document',
  }) =>
      GuestSitePreviewApp(
        key: key,
        boot: GuestSiteBoot.fromJson(bootJson),
        blockKeyAt: blockKeyAt,
        emptyLabel: emptyLabel,
      );

  final GuestSiteBoot boot;
  final GlobalKey? Function(int index)? blockKeyAt;
  final String emptyLabel;

  @override
  State<GuestSitePreviewApp> createState() => _GuestSitePreviewAppState();
}

class _GuestSitePreviewAppState extends State<GuestSitePreviewApp> {
  final _shellNavObserver = _GuestSiteShellNavObserver();
  var _innerCanPop = false;

  @override
  void initState() {
    super.initState();
    _shellNavObserver.onStackChanged = _onShellStackChanged;
  }

  void _onShellStackChanged() {
    final canPop = _shellNavObserver.navigator?.canPop() ?? false;
    if (canPop != _innerCanPop && mounted) setState(() => _innerCanPop = canPop);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _guestSitePreviewTheme(widget.boot);
    return PopScope(
      canPop: !_innerCanPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _shellNavObserver.navigator?.maybePop();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.hasBoundedHeight ? constraints.maxHeight : 844.0;
          final viewSize = Size(w, h);
          final media = MediaQuery.of(context).copyWith(size: viewSize);
          return MediaQuery(
            data: media,
            child: MaterialApp(
              key: ValueKey('guest-preview-${widget.boot.siteIid}-${theme.brightness}'),
              debugShowCheckedModeBanner: false,
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: media,
                child: SizedBox(width: w, height: h, child: child),
              ),
              home: GuestSiteShell(
                boot: widget.boot,
                blockKeyAt: widget.blockKeyAt,
                emptyLabel: widget.emptyLabel,
                navigatorObservers: [_shellNavObserver],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuestSiteShellNavObserver extends NavigatorObserver {
  VoidCallback? onStackChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onStackChanged?.call();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => onStackChanged?.call();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => onStackChanged?.call();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => onStackChanged?.call();
}

/// Fixed-height clipped host for chat card / inline previews.
class GuestSitePreviewViewport extends StatelessWidget {
  const GuestSitePreviewViewport({
    super.key,
    required this.boot,
    required this.height,
    this.blockKeyAt,
    this.emptyLabel = 'Empty Site Document',
    this.borderRadius = BorderRadius.zero,
  });

  final GuestSiteBoot boot;
  final double height;
  final GlobalKey? Function(int index)? blockKeyAt;
  final String emptyLabel;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: GuestSitePreviewApp(
          boot: boot,
          blockKeyAt: blockKeyAt,
          emptyLabel: emptyLabel,
        ),
      ),
    );
  }
}