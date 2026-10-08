import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

class PageNotifyHistory extends StatefulWidget {
  const PageNotifyHistory({super.key, required this.conn});

  final ChatConn conn;

  @override
  State<PageNotifyHistory> createState() => _PageNotifyHistoryState();
}

class _PageNotifyHistoryState extends State<PageNotifyHistory> {
  static const _bg = Color(0xFF08080A);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);

  var _loading = true;
  String? _error;
  List<NotifyItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.conn.notifyList(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _onTap(NotifyItem item) async {
    try {
      await widget.conn.notifyRead(ids: [item.id.toInt()]);
      if (!mounted) return;
      setState(() {
        item.status = 'read';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  String _when(NotifyItem item) {
    final ms = item.sentTsMs != 0 ? item.sentTsMs : item.createdTsMs;
    if (ms == 0) return item.status;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        title: const Text('Notifications'),
      ),
      body: _loading
          ? const Center(child: UILoading())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: _items.isEmpty ? 1 : _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  if (_items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(child: Text(_error ?? 'No notifications', style: const TextStyle(color: _muted))),
                    );
                  }
                  final item = _items[index];
                  final unread = item.status != 'read';
                  return Material(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                      onTap: () => _onTap(item),
                      title: Text(
                        item.title.isEmpty ? 'Notification' : item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _text, fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
                      ),
                      subtitle: Text(
                        item.body.isEmpty ? _when(item) : item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      trailing: Text(_when(item), style: const TextStyle(color: _muted, fontSize: 11)),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
