import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:flutter/material.dart';

const _barBg = Color(0xFF18181B);
const _tabBg = Color(0xFF27272A);
const _tabActive = Color(0xFF09090B);
const _border = Color(0xFF3F3F46);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class BrowserTabInfo {
  const BrowserTabInfo({required this.tabId, required this.title, required this.url, required this.active});

  final String tabId;
  final String title;
  final String url;
  final bool active;

  factory BrowserTabInfo.fromJson(Map<String, dynamic> j) => BrowserTabInfo(
        tabId: j['tabId']?.toString() ?? j['tab_id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        active: j['active'] == true,
      );
}

/// Chrome-like remote browser chrome: tabs + omnibox with back / forward / reload.
class UiBrowserTabStrip extends StatefulWidget {
  const UiBrowserTabStrip({super.key, required this.session, this.compact = false});

  final RemoteSession session;
  final bool compact;

  @override
  State<UiBrowserTabStrip> createState() => _UiBrowserTabStripState();
}

class _UiBrowserTabStripState extends State<UiBrowserTabStrip> {
  var _tabs = <BrowserTabInfo>[];
  var _loading = false;
  var _refreshGen = 0;
  late final TextEditingController _urlCtrl;
  var _urlDirty = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController();
    widget.session.connected.addListener(_onSessionLink);
    unawaited(_refresh(retryOnEngine: true));
  }

  @override
  void dispose() {
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
      if (t.active) return t;
    }
    return _tabs.isNotEmpty ? _tabs.first : null;
  }

  int get _tabCount => _tabs.isEmpty ? 1 : _tabs.length;

  void _syncUrlField() {
    if (_urlDirty) return;
    final t = _activeTab;
    final u = t?.url ?? '';
    if (_urlCtrl.text != u) _urlCtrl.text = u;
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
        s.contains('no response from agent');
  }

  Future<void> _refresh({bool retryOnEngine = false}) async {
    if (!widget.session.connected.value) return;
    final gen = ++_refreshGen;
    setState(() => _loading = true);
    const attempts = 6;
    for (var i = 0; i < attempts; i++) {
      if (!mounted || gen != _refreshGen) return;
      try {
        final raw = await widget.session.browserInvoke('tabs', {'op': 'list'});
        final list = (raw['tabs'] as List?) ?? [];
        if (!mounted || gen != _refreshGen) return;
        setState(() {
          _tabs = list
              .map((e) => BrowserTabInfo.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((t) => t.tabId.isNotEmpty)
              .toList();
          _loading = false;
        });
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
        setState(() => _loading = false);
        return;
      }
    }
  }

  Future<void> _activate(String tabId) async {
    await widget.session.browserInvoke('tabs', {'op': 'activate', 'tab_id': tabId});
    _urlDirty = false;
    await _refresh();
  }

  Future<void> _newTab() async {
    await widget.session.browserInvoke('tabs', {'op': 'new', 'url': 'about:blank'});
    _urlDirty = false;
    await _refresh();
  }

  Future<void> _close(String tabId) async {
    await widget.session.browserInvoke('tabs', {'op': 'close', 'tab_id': tabId});
    await _refresh();
  }

  String _normalizeUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://') || t.startsWith('about:')) return t;
    return 'https://$t';
  }

  Future<void> _navigate() async {
    final url = _normalizeUrl(_urlCtrl.text);
    if (url.isEmpty) return;
    try {
      await widget.session.browserInvoke('navigate', {'url': url});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser navigate: $e');
    }
  }

  Future<void> _historyBack() async {
    try {
      await widget.session.browserInvoke('history.back', {});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser back: $e');
    }
  }

  Future<void> _historyForward() async {
    try {
      await widget.session.browserInvoke('history.forward', {});
      _urlDirty = false;
      await _refresh();
    } catch (e) {
      if (!_silentError(e)) lError('browser forward: $e');
    }
  }

  Future<void> _reload() async {
    try {
      await widget.session.browserInvoke('reload', {});
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

  Widget _tabChip(BrowserTabInfo t, {VoidCallback? onClose}) {
    final label = t.title.isNotEmpty
        ? t.title
        : (t.url.isNotEmpty && !t.url.startsWith('data:') ? t.url : 'New tab');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => unawaited(_activate(t.tabId)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.compact ? 200 : 168, minWidth: 72),
          height: 32,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: BoxDecoration(
            color: t.active ? _tabActive : _tabBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: Border(
              top: BorderSide(color: t.active ? _accent : _border, width: t.active ? 2 : 1),
              left: const BorderSide(color: _border),
              right: const BorderSide(color: _border),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.public, size: 14, color: t.active ? _muted : const Color(0xFF52525B)),
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
    );
  }

  Widget _omnibox() => DecoratedBox(
        decoration: BoxDecoration(
          color: _tabBg,
          borderRadius: BorderRadius.circular(widget.compact ? 24 : 20),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.lock_outline, size: 16, color: _muted),
            ),
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search or enter URL',
                  hintStyle: TextStyle(color: _muted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                onChanged: (_) => _urlDirty = true,
                onSubmitted: (_) => unawaited(_navigate()),
              ),
            ),
            IconButton(
              tooltip: 'Go',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: () => unawaited(_navigate()),
              icon: const Icon(Icons.arrow_forward, color: _accent),
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
                      leading: Icon(Icons.public, color: t.active ? _accent : _muted, size: 20),
                      title: Text(
                        t.title.isNotEmpty ? t.title : (t.url.isNotEmpty ? t.url : 'New tab'),
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
              child: _loading && _tabs.isEmpty
                  ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                      : _tabs.isEmpty
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _tabActive,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    border: const Border(top: BorderSide(color: _accent, width: 2), left: BorderSide(color: _border), right: BorderSide(color: _border)),
                                  ),
                                  child: const Text('New tab', style: TextStyle(color: _text, fontSize: 12)),
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
