import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

class UiBotMemoriesSheet extends StatefulWidget {
  const UiBotMemoriesSheet({super.key, required this.conn});
  final ChatConn conn;

  static Future<void> show(BuildContext context, {required ChatConn conn}) => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF18181B),
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => UiBotMemoriesSheet(conn: conn),
      );

  @override
  State<UiBotMemoriesSheet> createState() => _UiBotMemoriesSheetState();
}

class _UiBotMemoriesSheetState extends State<UiBotMemoriesSheet> {
  var _loading = true;
  var _memories = <UserMemory>[];
  var _filter = 'all';
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final res = await widget.conn.memoryList();
      if (!mounted) return;
      setState(() => _memories = res.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = uiFriendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(UserMemory item) async {
    try {
      final res = await widget.conn.memoryDelete(id: item.id.toInt());
      if (!res.ok) return;
      setState(() => _memories.removeWhere((m) => m.id == item.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Forgot "${item.key}"'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    }
  }

  Color _categoryColor(String category) => switch (category.toLowerCase()) {
        'preference' => const Color(0xFFA78BFA),
        'correction' => const Color(0xFFFBBF24),
        'tool_fix' => const Color(0xFF34D399),
        _ => const Color(0xFF60A5FA),
      };

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all' ? _memories : _memories.where((m) => m.category.toLowerCase() == _filter).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF3F3F46), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.psychology_outlined, color: Color(0xFF34D399), size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Learned Memories', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w600)), Text('Facts and preferences distilled from your chats', style: TextStyle(color: Color(0xFF71717A), fontSize: 12))])),
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF71717A), size: 20), onPressed: _load),
        ]),
        const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_filterChip('All', 'all'), const SizedBox(width: 8), _filterChip('Preferences', 'preference'), const SizedBox(width: 8), _filterChip('Facts', 'fact'), const SizedBox(width: 8), _filterChip('Corrections', 'correction')])),
        const SizedBox(height: 14),
        const Divider(color: Color(0xFF27272A), height: 1),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? const UILoading()
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.cloud_off_outlined, size: 40, color: Color(0xFF71717A)),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ]),
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.auto_awesome, size: 40, color: const Color(0xFF71717A).withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('No distilled memories yet', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: Text('Chat naturally. Facts, preferences, and corrections are distilled automatically.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF71717A), fontSize: 12))),
                      ]),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = filtered[idx];
                        final catColor = _categoryColor(item.category);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF27272A).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3F3F46).withValues(alpha: 0.4))),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(item.category.toUpperCase(), style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold))),
                                  const SizedBox(width: 8),
                                  Text(item.key, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                                  const Spacer(),
                                  Text('${(item.confidence * 100).toInt()}% conf', style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                                ]),
                                const SizedBox(height: 6),
                                Text(item.content, style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 13)),
                              ]),
                            ),
                            uiIconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF71717A)), tooltip: 'Forget memory', onPressed: () => _delete(item)),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: selected ? const Color(0xFF34D399).withValues(alpha: 0.15) : const Color(0xFF27272A), borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? const Color(0xFF34D399) : const Color(0xFF3F3F46))),
        child: Text(label, style: TextStyle(color: selected ? const Color(0xFF34D399) : const Color(0xFFA1A1AA), fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
