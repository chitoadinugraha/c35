import 'dart:async';

import 'package:alienai_c35/guest_site/guest_site_blocks.dart';
import 'package:alienai_c35/guest_site/guest_site_boot.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:alienai_c35/guest_site/guest_site_analytics.dart';
import 'package:alienai_c35/guest_site/guest_site_assistant.dart';
import 'package:alienai_c35/guest_site/guest_site_view.dart';
import 'package:flutter/material.dart';

/// Marks preview routes (`/products/*`, `/posts/*`) owned by [GuestSiteShell]'s nested [Navigator].
class GuestSiteShellScope extends InheritedWidget {
  const GuestSiteShellScope({
    super.key,
    required this.navigatorKey,
    required super.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  static GlobalKey<NavigatorState>? maybeNavigatorKey(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GuestSiteShellScope>()
        ?.navigatorKey;
  }

  @override
  bool updateShouldNotify(GuestSiteShellScope oldWidget) =>
      navigatorKey != oldWidget.navigatorKey;
}

/// Guest hub with cart chrome when site commerce is enabled (preview + boot loader).
class GuestSiteShell extends StatefulWidget {
  const GuestSiteShell({
    super.key,
    required this.boot,
    this.blockKeyAt,
    this.emptyLabel = 'Empty Site Document',
    this.navigatorObservers = const [],
  });

  factory GuestSiteShell.bootJson({
    Key? key,
    required Map<String, dynamic> bootJson,
    GlobalKey? Function(int index)? blockKeyAt,
    String emptyLabel = 'Empty Site Document',
  }) =>
      GuestSiteShell(
        key: key,
        boot: GuestSiteBoot.fromJson(bootJson),
        blockKeyAt: blockKeyAt,
        emptyLabel: emptyLabel,
      );

  final GuestSiteBoot boot;
  final GlobalKey? Function(int index)? blockKeyAt;
  final String emptyLabel;
  final List<NavigatorObserver> navigatorObservers;

  @override
  State<GuestSiteShell> createState() => _GuestSiteShellState();
}

class _GuestSiteShellState extends State<GuestSiteShell> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late GuestSiteCartController _cart = _newCart(widget.boot);
  int _analyticsActiveStartMs = 0;
  int _analyticsActiveMs = 0;
  bool _analyticsVisible = true;

  static GuestSiteCartController _newCart(GuestSiteBoot boot) {
    final cart = GuestSiteCartController(siteIid: boot.siteIid);
    cart.applyCommerceBoot(boot.commerceBoot);
    return cart;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _analyticsActiveStartMs = DateTime.now().millisecondsSinceEpoch;
    unawaited(_cart.load());
  }

  @override
  void didUpdateWidget(covariant GuestSiteShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boot.siteIid != widget.boot.siteIid) {
      _cart = _newCart(widget.boot);
      unawaited(_cart.load());
    } else if (oldWidget.boot.commerceBoot != widget.boot.commerceBoot) {
      _cart.applyCommerceBoot(widget.boot.commerceBoot);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_flushAnalyticsPing());
    _cart.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _accumulateAnalyticsActive();
      _analyticsVisible = false;
      unawaited(_flushAnalyticsPing());
    } else if (state == AppLifecycleState.resumed) {
      _analyticsVisible = true;
      _analyticsActiveStartMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _accumulateAnalyticsActive() {
    if (!_analyticsVisible) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _analyticsActiveMs += now - _analyticsActiveStartMs;
    _analyticsActiveStartMs = now;
  }

  Future<void> _flushAnalyticsPing() async {
    if (!GuestSiteAnalytics.analyticsEnabled(widget.boot.capabilities)) return;
    _accumulateAnalyticsActive();
    final ms = _analyticsActiveMs;
    _analyticsActiveMs = 0;
    if (ms <= 0) return;
    await GuestSiteAnalytics.pingOnHidden(
      siteIid: widget.boot.siteIid,
      alienId: widget.boot.alienId,
      activeDurationMs: ms,
    );
  }

  Widget _home() {
    final view = GuestSiteView(
      boot: widget.boot,
      blockKeyAt: widget.blockKeyAt,
      emptyLabel: widget.emptyLabel,
    );
    final layered = GuestSiteAssistantLayer(boot: widget.boot, child: view);
    if (!widget.boot.commerceEnabled) return layered;
    return GuestSiteCartScope(
      controller: _cart,
      child: GuestSiteCartChrome(
        controller: _cart,
        accent: widget.boot.accentColor,
        child: layered,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GuestSiteShellScope(
      navigatorKey: _navigatorKey,
      child: Navigator(
        key: _navigatorKey,
        observers: widget.navigatorObservers,
        onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/') {
          return MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/'),
            builder: (_) => _home(),
          );
        }
        final productMatch = RegExp(r'^/products/(\d+)$').firstMatch(name);
        if (productMatch != null && settings.arguments is GuestSiteProductRouteArgs) {
          return MaterialPageRoute<void>(
            settings: RouteSettings(name: name),
            builder: (_) => GuestSiteProductRoutePage(args: settings.arguments! as GuestSiteProductRouteArgs),
          );
        }
        final postMatch = RegExp(r'^/posts/([^/]+)$').firstMatch(name);
        if (postMatch != null && settings.arguments is GuestSitePostRouteArgs) {
          return MaterialPageRoute<void>(
            settings: RouteSettings(name: name),
            builder: (_) => GuestSitePostRoutePage(args: settings.arguments! as GuestSitePostRouteArgs),
          );
        }
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) => _home(),
        );
      },
      ),
    );
  }
}

class GuestSiteProductRoutePage extends StatelessWidget {
  const GuestSiteProductRoutePage({super.key, required this.args});

  final GuestSiteProductRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: const Color(0xFFF4F4F5),
        title: const Text('Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GuestSiteProductDetailContent(
          key: const Key('guest-product-detail'),
          siteIid: args.siteIid,
          product: args.product,
          objects: args.objects,
          accent: args.accent,
          cart: args.cart,
        ),
      ),
    );
  }
}

class GuestSitePostRoutePage extends StatelessWidget {
  const GuestSitePostRoutePage({super.key, required this.args});

  final GuestSitePostRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: const Color(0xFFF4F4F5),
        title: const Text('Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GuestSitePostDetailContent(
          key: const Key('guest-post-detail'),
          post: args.post,
          accent: args.accent,
        ),
      ),
    );
  }
}