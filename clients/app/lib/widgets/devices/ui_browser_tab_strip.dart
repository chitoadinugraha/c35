import 'dart:async';

import 'package:alienai_c35/c/browser/browser_search_engine.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/widgets/devices/ui_browser_search_engine_dialog.dart';
import 'package:flutter/material.dart';

const _barBg = Color(0xFF18181B);
const _tabBg = Color(0xFF27272A);
const _tabActive = Color(0xFF09090B);
const _border = Color(0xFF3F3F46);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class BrowserTabInfo {
  const BrowserTabInfo({
    required this.tabId,
    required this.title,
    required this.url,
    required this.active,
    this.loading = false,
    this.favicon = '',
    this.windowFocused = false,
    this.windowId,
  });

  final String tabId;
  final String title;
  final String url;
  final bool active;
  final bool loading;
  final String favicon;
  final bool windowFocused;
  final int? windowId;

  factory BrowserTabInfo.fromJson(Map<String, dynamic> j) => BrowserTabInfo(
        tabId: j['tabId']?.toString() ?? j['tab_id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        active: j['active'] == true,
        loading: j['loading'] == true,
        favicon: j['favicon']?.toString() ?? '',
        windowFocused: j['windowFocused'] == true,
        windowId: j['windowId'] is int ? j['windowId'] as int : int.tryParse('${j['windowId']}'),
      );
}

/// Chrome-like remote browser chrome: tabs + omnibox with back / forward / reload.
class UiBrowserTabStrip extends StatefulWidget {
  const UiBrowserTabStrip({
    super.key,
    required this.session,
    this.compact = false,
    this.onLoadingChanged,
  });

  final RemoteSession session;
  final bool compact;
  final ValueChanged<bool>? onLoadingChanged;

  @override
  State<UiBrowserTabStrip> createState() => _UiBrowserTabStripState();
}

class _UiBrowserTabStripState extends State<UiBrowserTabStrip> {
  var _tabs = <BrowserTabInfo>[];
  var _loading = false;
  var _refreshGen = 0;
  late final TextEditingController _urlCtrl;
  var _urlDirty = false;
  Timer? _pollTimer;
  BrowserSearchEngine _engine = browserSearchEnginesFallback.first;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    widget.session.connected.addListener(_onSessionLink);
    unawaited(_loadEngine());
    unawaited(_refresh(retryOnEngine: true));
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (widget.session.connected.value) unawaited(_refresh());
    });
  }

  Future<void> _loadEngine() async {
    final id = await browserSearchEngineIdLoad();
    if (!mounted) return;
    setState(() => _engine = browserSearchEngineById(id));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    widget.session.connected.removeListener(_onSessionLink);
    _urlCtrl.dispose();
    super.dispose();
  }

  void _onSessionLink() {
    if (!widget.session.connected.value) return;
    unawaited(_refresh());
  }

  BrowserTabInfo? get _activeTab {
    for (final t in _tabs) {
      if (t.windowFocused && t.active) return t;
    }
    for (final t in _tabs) {
      if (t.active) return t;
    }
    return _tabs.isNotEmpty ? _tabs.first : null;
  }

  int get _tabCount => _tabs.isEmpty ? 1 : _tabs.length;

  void _syncUrlField() {
    if (_urlDirty) return;
    final t = _activeTab;
    final u = t?.url ?? '';
    final shown = browserTabIsHome(u) ? '' : u;
    if (_urlCtrl.text != shown) _urlCtrl.text = shown;
  }

  bool _engineRetryable(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('engine ipc') ||
        s.contains('waiting for launch') ||
        s.contains('engine worker') ||
        s.contains('browser_engine');
  }

  bool _silentError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('agent offline') ||
        s.contains('agent unreachable') ||
        s.contains('no response from agent') ||
        s.contains('rpc timeout') ||
        s.contains('tabs list timeout');
  }

  void _setLoading(bool loading) {
    if (_loading == loading) return;
    setState(() => _loading = loading);
    final cb = widget.onLoadingChanged;
    if (cb == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loading != loading) return;
      cb(loading);
    });
  }

  Future<void> _refresh({bool retryOnEngine = false}) async {
    if (!widget.session.connected.value) return;
    final gen = ++_refreshGen;
    _setLoading(true);
    const attempts = 6;
    for (var i = 0; i < attempts; i++) {
      if (!mounted || gen != _refreshGen) return;
      try {
        final raw = await _browserInvoke('tabs', {'op': 'list'}, retryOnEngine: retryOnEngine);
        final list = (raw['tabs'] as List?) ?? [];
        if (!mounted || gen != _refreshGen) return;
        setState(() {
          _tabs = list
              .map((e) => BrowserTabInfo.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((t) => t.tabId.isNotEmpty)
              .toList();
        });
        _setLoading(false);
        _syncUrlField();
        return;
      } catch (e) {
        if (!_silentError(e)) lError('browser tab list: $e');
        final retry = retryOnEngine && _engineRetryable(e) && i + 1 < attempts;
        if (retry) {
          await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
          continue;
        }
        if (!mounted || gen != _refreshGen) return;
        _setLoading(false);
        return;
      }
    }
  }

  Future<Map<String, dynamic>> _browserInvoke(
    String method,
    Map<String, dynamic> params, {
    bool retryOnEngine = true,
  }) async {
    const attempts = 6;
    for (var i = 0; i < attempts; i++) {
      try {
        return await widget.session.browserInvoke(method, params);
      } catch (e) {
        final retry = retryOnEngine && _engineRetryable(e) && i + 1 < attempts;
        if (retry) {
          await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
          continue;
        }
        rethrow;
      }
    }
    return {};
  }

  Future<void> _activate(String tabId) async {
    await _browserInvoke('tabs', {'op': 'activate', 'tab_id': tabId});
    _urlDirty = false;
    await _refresh();
  }

  Future<void> _newTab() async {
    await _browserInvoke('tabs', {'op': 'new', 'url': browserHomeUrl});
    _urlDirty = false;
    await _refresh();
  }

  Future<void> _close(String tabId) async {
    await _browserInvoke('tabs', {'op': 'close', 'tab_id': tabId});
    await _refresh();
  }

  Future<void> _navigate() async {
    final url = browserOmniboxTarget(_urlCtrl.text, engine: _engine);
    if (url.isEmpty) return;
    try {
      await _browserInvoke('navigate', {'url': url});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser navigate: $e');
    }
  }

  Future<void> _historyBack() async {
    try {
      await _browserInvoke('history.back', {});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser back: $e');
    }
  }

  Future<void> _historyForward() async {
    try {
      await _browserInvoke('history.forward', {});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser forward: $e');
    }
  }

  Future<void> _reload() async {
    try {
      await _browserInvoke('reload', {});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser reload: $e');
    }
  }

  Widget _navButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) => IconButton(
        tooltip: tooltip,
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: _loading ? null : onPressed,
        icon: Icon(icon, color: _muted),
      );

  Widget _tabFavicon(BrowserTabInfo t) {
    if (t.loading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: _muted),
      );
    }
    final src = browserTabFaviconUrl(t.url, favicon: t.favicon);
    const globe = Icon(Icons.public, size: 14, color: _muted);
    if (src.isEmpty) return globe;
    return Image.network(
      src,
      width: 14,
      height: 14,
      errorBuilder: (_, __, ___) => globe,
      frameBuilder: (_, child, frame, __) => frame == null ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)) : child,
    );
  }

  Future<void> _pickSearchEngine() async {
    final picked = await browserSearchEngineDialogShow(context, selectedId: _engine.id);
    if (!mounted || picked == null) return;
    await browserSearchEngineIdSave(picked.id);
    setState(() => _engine = picked);
  }

  BoxDecoration _tabShellDecoration(bool active) => BoxDecoration(
        color: active ? _tabActive : _tabBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: Border.all(color: _border),
      );

  Widget _tabChip(BrowserTabInfo t, {VoidCallback? onClose}) {
    final label = t.title.isNotEmpty ? t.title : browserTabTitleFromUrl(t.url);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(_activate(t.tabId)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.compact ? 200 : 168, minWidth: 72),
          height: 32,
          decoration: _tabShellDecoration(t.active),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (t.active) const ColoredBox(color: _accent, child: SizedBox(height: 2)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  child: Row(
                    children: [
                      _tabFavicon(t),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.active ? _text : _muted,
                            fontSize: 12,
                            fontWeight: t.active ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (onClose != null)
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 14, color: _muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _onHome => browserTabIsHome(_activeTab?.url ?? '');

  Widget _omnibox() => DecoratedBox(
        decoration: BoxDecoration(
          color: _tabBg,
          borderRadius: BorderRadius.circular(widget.compact ? 24 : 20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(_onHome ? Icons.search_rounded : Icons.lock_outline, size: 16, color: _muted),
            ),
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: browserOmniboxHintFor(_engine),
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                onChanged: (_) => _urlDirty = true,
                onSubmitted: (_) => unawaited(_navigate()),
              ),
            ),
            IconButton(
              tooltip: 'Search engine: ${_engine.name}',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: () => unawaited(_pickSearchEngine()),
              icon: const Icon(Icons.manage_search_rounded, color: _muted),
            ),
            IconButton(
              tooltip: 'Go',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: () => unawaited(_navigate()),
              icon: const Icon(Icons.arrow_forward, color: _muted),
            ),
          ],
        ),
      );

  Widget _mobileTabSwitcher() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : () => unawaited(_openTabSheet()),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            constraints: const BoxConstraints(minWidth: 44),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _tabBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_tabCount',
                  style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.grid_view_rounded, size: 16, color: _muted),
              ],
            ),
          ),
        ),
      );

  Future<void> _openTabSheet() async {
    await _refresh();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _barBg,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Tabs', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      unawaited(_newTab());
                    },
                    icon: const Icon(Icons.add, size: 18, color: _accent),
                    label: const Text('New tab', style: TextStyle(color: _accent)),
                  ),
                ],
              ),
            ),
            if (_tabs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No tabs yet. Tap New tab or connect Remote stream.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 13)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tabs.length,
                  itemBuilder: (_, i) {
                    final t = _tabs[i];
                    return ListTile(
                      leading: SizedBox(width: 20, height: 20, child: _tabFavicon(t)),
                      title: Text(
                        t.title.isNotEmpty ? t.title : browserTabTitleFromUrl(t.url),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.active ? _text : _muted),
                      ),
                      subtitle: t.url.isNotEmpty ? Text(t.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _muted),
                        onPressed: () => unawaited(_close(t.tabId).then((_) => _refresh())),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        unawaited(_activate(t.tabId));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _desktopTabRow() => SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: _tabs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _loading ? null : () => unawaited(_newTab()),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                child: Container(
                                  height: 32,
                                  decoration: _tabShellDecoration(true),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const ColoredBox(color: _accent, child: SizedBox(height: 2)),
                                      const Expanded(
                                        child: Center(
                                          child: Text('New tab', style: TextStyle(color: _text, fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 6, top: 4),
                          itemCount: _tabs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 2),
                          itemBuilder: (_, i) => _tabChip(_tabs[i], onClose: () => unawaited(_close(_tabs[i].tabId))),
                        ),
            ),
            IconButton(
              tooltip: 'New tab',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _loading ? null : () => unawaited(_newTab()),
              icon: const Icon(Icons.add, color: _muted),
            ),
          ],
        ),
      );

  Widget _toolbar({required bool mobileTabs}) => Padding(
        padding: EdgeInsets.fromLTRB(mobileTabs ? 4 : 6, widget.compact ? 6 : 0, 8, 6),
        child: Row(
          children: [
            _navButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: () => unawaited(_historyBack())),
            _navButton(icon: Icons.arrow_forward_rounded, tooltip: 'Forward', onPressed: () => unawaited(_historyForward())),
            _navButton(icon: Icons.refresh_rounded, tooltip: 'Reload', onPressed: () => unawaited(_reload())),
            const SizedBox(width: 4),
            Expanded(child: _omnibox()),
            if (mobileTabs) _mobileTabSwitcher(),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _barBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.compact) _desktopTabRow(),
          _toolbar(mobileTabs: widget.compact),
        ],
      ),
    );
  }
}
