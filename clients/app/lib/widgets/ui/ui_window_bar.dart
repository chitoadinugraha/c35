import 'package:alienai_c35/c/parts/csai__version.dart';
import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/nav.dart';
import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:alienai_c35/widgets/ui/ui_update_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

bool get uiDesktopWindow =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

bool get uiCustomWindowBar => uiDesktopWindow && defaultTargetPlatform != TargetPlatform.windows;

const _kTopResize = 12.0;

class UiDesktopChrome extends StatefulWidget {
  const UiDesktopChrome({super.key, required this.child});
  final Widget child;

  @override
  State<UiDesktopChrome> createState() => _UiDesktopChromeState();
}

class _UiDesktopChromeState extends State<UiDesktopChrome> with WindowListener {
  var _maximized = false;
  var _fullScreen = false;

  @override
  void initState() {
    super.initState();
    if (!uiDesktopWindow) return;
    windowManager.addListener(this);
    _chromeLoad();
  }

  @override
  void dispose() {
    if (uiDesktopWindow) windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _chromeLoad() async {
    final max = await windowManager.isMaximized();
    final full = await windowManager.isFullScreen();
    if (!mounted) return;
    setState(() {
      _maximized = max;
      _fullScreen = full;
    });
  }

  Widget _chrome() => Material(
      color: const Color(0xFF08080A),
      child: Column(
        children: [
          const SizedBox(height: 36, child: UiWindowBar()),
          Expanded(child: widget.child),
        ],
      ),
    );

  Widget _resize(Widget child) {
    if (_maximized || _fullScreen) return child;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return DragToResizeArea(
        resizeEdgeSize: _kTopResize,
        enableResizeEdges: const [ResizeEdge.topLeft, ResizeEdge.top, ResizeEdge.topRight],
        child: child,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.linux) return DragToResizeArea(resizeEdgeSize: _kTopResize, child: child);
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (!uiDesktopWindow) return widget.child;
    if (!uiCustomWindowBar) return widget.child;
    return _resize(_chrome());
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  void onWindowEnterFullScreen() => setState(() => _fullScreen = true);

  @override
  void onWindowLeaveFullScreen() => setState(() => _fullScreen = false);
}

class UiWindowBar extends StatefulWidget {
  const UiWindowBar({super.key, this.title = 'Alien AI'});
  final String title;

  @override
  State<UiWindowBar> createState() => _UiWindowBarState();
}

class _UiWindowBarState extends State<UiWindowBar> with WindowListener {
  final _titleKey = GlobalKey();
  var _menuOpen = false;
  var _maximized = false;
  DateTime? _menuClosedAt;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _maximizedLoad();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _maximizedLoad() async {
    final max = await windowManager.isMaximized();
    if (mounted) setState(() => _maximized = max);
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  String get _displayTitle => '${widget.title} ${appVersionLabel()}';

  Future<void> _versionMenu() async {
    final nav = c35NavigatorKey.currentState;
    if (nav == null || !nav.mounted) return;
    final menuCtx = nav.context;
    if (nav.overlay == null || !nav.overlay!.mounted) return;
    if (_menuOpen) {
      Navigator.of(menuCtx).pop();
      return;
    }
    final closedAt = _menuClosedAt;
    if (closedAt != null && DateTime.now().difference(closedAt) < const Duration(milliseconds: 250)) return;
    final box = _titleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _menuOpen = true;
    try {
      await showMenu<void>(
        context: menuCtx,
        color: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFF27272A))),
        position: uiMenuPositionBelow(menuCtx, box, gap: -8),
        items: [
          PopupMenuItem<void>(
            enabled: false,
            height: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Version ${csaiVersionBuild()}', style: const TextStyle(fontSize: 12, color: Color(0xFFE4E4E7), fontWeight: FontWeight.w500)),
                Text(csaiVersionFull, style: const TextStyle(fontSize: 10, color: Color(0xFF71717A))),
              ],
            ),
          ),
        ],
      );
    } finally {
      _menuOpen = false;
      _menuClosedAt = DateTime.now();
    }
  }

  Widget _titleText() => DefaultTextStyle(
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFA1A1AA), decoration: TextDecoration.none),
        child: Text(_displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  Widget _title() => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: _titleKey,
          onTap: _versionMenu,
          child: _titleText(),
        ),
      );

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF08080A),
        child: Row(
          children: [
            Expanded(
              child: DragToMoveArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: _toggleMaximize,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset('assets/icons/app_icon.png', width: 16, height: 16, filterQuality: FilterQuality.medium),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _title(),
                      const Expanded(child: SizedBox.shrink()),
                      const UiUpdateChrome(),
                    ],
                  ),
                ),
              ),
            ),
            WindowCaptionButton.minimize(
              brightness: Brightness.dark,
              onPressed: () async {
                if (await windowManager.isMinimized()) {
                  await windowManager.restore();
                } else {
                  await windowManager.minimize();
                }
              },
            ),
            _maximized
                ? WindowCaptionButton.unmaximize(brightness: Brightness.dark, onPressed: windowManager.unmaximize)
                : WindowCaptionButton.maximize(brightness: Brightness.dark, onPressed: windowManager.maximize),
            WindowCaptionButton.close(brightness: Brightness.dark, onPressed: windowManager.close),
          ],
        ),
      );

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);
}
