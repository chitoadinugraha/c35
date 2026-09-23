import 'package:alienai_c35/c/pb/c35/log.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _head = Color(0xFF18181B);
const _panel = Color(0xFF111114);
const _accent = Color(0xFF34D399);

class UiAdminLogTable extends StatefulWidget {
  const UiAdminLogTable({
    super.key,
    required this.logs,
    this.userNames = const {},
    this.loading = false,
  });

  final List<Log> logs;
  final Map<int, String> userNames;
  final bool loading;

  @override
  State<UiAdminLogTable> createState() => _UiAdminLogTableState();
}

class _UiAdminLogTableState extends State<UiAdminLogTable> {
  final _expanded = <Int64>{};

  String _fmtTime(Log row) {
    final ms = row.createdTsMs.toInt();
    if (ms <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _userName(Log row) => widget.userNames[row.ownerIid.toInt()] ?? '${row.ownerIid}';

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    if (widget.logs.isEmpty) {
      return const Center(child: Text('No logs', style: TextStyle(color: _muted, fontSize: 13)));
    }
    return ColoredBox(
      color: _panel,
      child: ListView.separated(
        itemCount: widget.logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
        itemBuilder: (context, i) {
          final row = widget.logs[i];
          final expanded = _expanded.contains(row.id);
          return Material(
            color: expanded ? _head : Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => expanded ? _expanded.remove(row.id) : _expanded.add(row.id)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 64, child: Text(_fmtTime(row), style: const TextStyle(color: _muted, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()]))),
                        SizedBox(width: 100, child: Text(_userName(row), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 12))),
                        SizedBox(width: 88, child: Text(row.topic, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11))),
                        SizedBox(width: 64, child: Text(row.kind, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _accent, fontSize: 11))),
                        Expanded(child: Text(row.text, maxLines: expanded ? null : 1, overflow: expanded ? null : TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 12))),
                        Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: _muted),
                      ],
                    ),
                    if (expanded && row.metaJson.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SelectableText(row.metaJson, style: const TextStyle(color: _muted, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
