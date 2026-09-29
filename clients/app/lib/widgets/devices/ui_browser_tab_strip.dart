import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
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
        tabId: j['tabId']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        active: j['active'] == true,
      );
}

class UiBrowserTabStrip extends StatefulWidget {
  const UiBrowserTabStrip({super.key, required this.session});

  final RemoteSession session;

  @override
  State<UiBrowserTabStrip> createState() => _UiBrowserTabStripState();
}

class _UiBrowserTabStripState extends State<UiBrowserTabStrip> {
  var _tabs = <BrowserTabInfo>[];
  var _loading = false;
  var _error = '';

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final raw = await widget.session.browserInvoke('tabs', {'op': 'list'});
      final list = (raw['tabs'] as List?) ?? [];
      setState(() {
        _tabs = list.map((e) => BrowserTabInfo.fromJson(Map<String, dynamic>.from(e as Map))).where((t) => t.tabId.isNotEmpty).toList();
        _loading = false;
      });
    } catch (e) {
      lError('browser tab list: $e');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _activate(String tabId) async {
    await widget.session.browserInvoke('tabs', {'op': 'activate', 'tab_id': tabId});
    await _refresh();
  }

  Future<void> _newTab() async {
    await widget.session.browserInvoke('tabs', {'op': 'new', 'url': 'about:blank'});
    await _refresh();
  }

  Future<void> _close(String tabId) async {
    await widget.session.browserInvoke('tabs', {'op': 'close', 'tab_id': tabId});
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF18181B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                const Text('Tabs', style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  tooltip: 'New tab',
                  iconSize: 18,
                  onPressed: _loading ? null : () => unawaited(_newTab()),
                  icon: const Icon(Icons.add, color: _muted),
                ),
                IconButton(
                  tooltip: 'Refresh tab list',
                  iconSize: 18,
                  onPressed: _loading ? null : () => unawaited(_refresh()),
                  icon: const Icon(Icons.refresh, color: _muted),
                ),
              ],
            ),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(_error, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11), maxLines: 2),
            ),
          if (_loading && _tabs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final t = _tabs[i];
                  final label = t.title.isNotEmpty ? t.title : (t.url.isNotEmpty ? t.url : t.tabId);
                  return InputChip(
                    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: t.active ? _text : _muted, fontSize: 11)),
                    backgroundColor: t.active ? const Color(0xFF27272A) : const Color(0xFF111114),
                    side: BorderSide(color: t.active ? _accent : _border),
                    onPressed: () => unawaited(_activate(t.tabId)),
                    onDeleted: () => unawaited(_close(t.tabId)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
