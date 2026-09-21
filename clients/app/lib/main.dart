import 'dart:async';
import 'dart:io';

import 'package:alienai_c35/c/api/settings_conn.dart';
import 'package:alienai_c35/c/auth/auth_service.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/locale/app_locale.dart';
import 'package:alienai_c35/c/nav.dart';
import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/settings/settings_bootstrap.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/update/app_release.dart';
import 'package:alienai_c35/c/update/app_update_host.dart';
import 'package:alienai_c35/c/update/app_update_service.dart';
import 'package:alienai_c35/pages/auth/page_sign_in.dart';
import 'package:alienai_c35/pages/auth/ui_session_lock_gate.dart';
import 'package:alienai_c35/pages/page_ai_home.dart';
import 'package:alienai_c35/widgets/ui/ui_error_fallback.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_update_banner.dart';
import 'package:alienai_c35/widgets/ui/ui_update_countdown_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

bool get _desktop => defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS;

String _windowsIconPath() {
  final bundled = File('${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}assets${Platform.pathSeparator}icons${Platform.pathSeparator}app_icon.ico');
  if (bundled.existsSync()) return bundled.path;
  return 'assets/icons/app_icon.ico';
}

const _bg = Color(0xFF08080A);

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    uiErrorHook();
    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();
    if (_desktop) await windowManager.ensureInitialized();
    runApp(
      EasyLocalization(
        supportedLocales: appLocaleSupported,
        path: 'assets/translations',
        fallbackLocale: appLocales.first.locale,
        startLocale: appLocales.first.locale,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: const C35App(),
      ),
    );
    if (_desktop) {
      final title = 'Alien AI ${appVersionLabel()}';
      final opts = WindowOptions(title: title, titleBarStyle: TitleBarStyle.hidden, backgroundColor: _bg);
      await windowManager.waitUntilReadyToShow(opts, () async {
        await windowManager.setTitle(title);
        try {
          await windowManager.setIcon(_windowsIconPath());
        } catch (_) {}
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }, (e, s) {
    uiErrorLog(e, s);
    uiErrorPut(e);
  });
}

class C35App extends StatefulWidget {
  const C35App({super.key});

  @override
  State<C35App> createState() => _C35AppState();
}

class _C35AppState extends State<C35App> {
  final _auth = AuthService();
  var _ready = false;
  var _bootError = '';

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuth);
    if (defaultTargetPlatform == TargetPlatform.windows) {
      AppUpdateService.instance.registerAutoUpdatePrompt(_autoUpdatePrompt);
    }
    _boot();
  }

  Future<void> _boot() async {
    try {
      await serverHostInit();
      await _auth.restore();
      await settingsBootstrap();
      if (Session.instance.allowControlYes) AppStore.instance.thisPcAllow(name: Session.instance.thisPcName);
      if (mounted) {
        setState(() {
          _ready = true;
          _bootError = '';
        });
        if (defaultTargetPlatform == TargetPlatform.windows) AppUpdateService.instance.start();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ready = true;
          _bootError = e.toString();
        });
      }
    }
  }

  Future<void> _bootRetry() async {
    setState(() {
      _ready = false;
      _bootError = '';
    });
    await _boot();
  }

  @override
  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      AppUpdateService.instance.registerAutoUpdatePrompt(null);
      AppUpdateService.instance.dispose();
    }
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  void _autoUpdatePrompt(AppRelease release) {
    final ctx = c35NavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      AppUpdateService.instance.countdownDismissed();
      return;
    }
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => UiUpdateCountdownDialog(
        version: release.label,
        onConfirm: () => AppUpdateService.instance.installNow(),
        onCancel: () => AppUpdateService.instance.postponeAutoUpdate(),
      ),
    ).then((_) => AppUpdateService.instance.countdownDismissed());
  }

  void _onAuth() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Object?>(
        valueListenable: uiError,
        builder: (_, err, __) {
          if (err != null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: _bg),
              home: UiErrorFallback(showChrome: true, onRetry: uiErrorClear),
            );
          }
          return MaterialApp(
            navigatorKey: c35NavigatorKey,
            title: 'Alien AI',
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: _bg,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF22C55E), brightness: Brightness.dark),
              useMaterial3: true,
            ),
            builder: (context, child) => UiErrorHost(
              child: Listener(
                onPointerDown: (_) => AppUpdateService.instance.recordUserActivity(),
                onPointerMove: (_) => AppUpdateService.instance.recordUserActivity(),
                child: UiDesktopChrome(child: child ?? const SizedBox.shrink()),
              ),
            ),
            home: AppUpdateHost(
              appReady: _ready,
              child: !_ready
                  ? const Scaffold(backgroundColor: _bg, body: UILoading())
                  : _bootError.isNotEmpty
                      ? Scaffold(backgroundColor: _bg, body: UiErrorFallback(onRetry: _bootRetry))
                      : _auth.signedIn
                          ? _HomeShell(auth: _auth)
                          : PageSignIn(auth: _auth, onSignedIn: () => setState(() {})),
            ),
          );
        },
      );
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) => UiSessionLockGate(
        auth: auth,
        conn: SettingsConn(),
        child: UiUpdateForceGate(child: PageAIHome(auth: auth)),
      );
}
