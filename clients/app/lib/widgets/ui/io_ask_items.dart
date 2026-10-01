import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:flutter/material.dart';

class IoAskItem {
  const IoAskItem({required this.id, required this.title, this.subtitle = '', this.icon, this.accent});

  final String id;
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? accent;
}

Future<IoAskItem?> ioAskItemsShow(
  BuildContext context, {
  required String title,
  required List<IoAskItem> items,
  String searchHint = 'Search…',
  double width = 360,
  double height = 420,
}) =>
    uiDialogShow<IoAskItem>(
      context: context,
      builder: (_) => _IoAskItemsDialog(title: title, items: items, searchHint: searchHint, width: width, height: height),
    );

class _IoAskItemsDialog extends StatefulWidget {
  const _IoAskItemsDialog({required this.title, required this.items, required this.searchHint, required this.width, required this.height});

  final String title;
  final List<IoAskItem> items;
  final String searchHint;
  final double width;
  final double height;

  @override
  State<_IoAskItemsDialog> createState() => _IoAskItemsDialogState();
}

class _IoAskItemsDialogState extends State<_IoAskItemsDialog> {
  late final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<IoAskItem> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) => '${item.title} ${item.subtitle}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        namesRoute: true,
        label: widget.title,
        child: UiDialog(
          width: widget.width,
          height: widget.height,
          padding: uiDialogInsetCompact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiDialogSearchHeader(controller: _search, hintText: widget.searchHint, onChanged: (_) => setState(() {})),
              const SizedBox(height: 10),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(child: Text('No matches', style: TextStyle(color: uiDialogMuted, fontSize: 13)))
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final item = _filtered[i];
                          final accent = item.accent ?? uiDialogAccent;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.pop(context, item),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                child: Row(
                                  children: [
                                    if (item.icon != null)
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
                                        child: Icon(item.icon, size: 18, color: accent),
                                      ),
                                    if (item.icon != null) const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.title, style: const TextStyle(color: uiDialogTitleColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                          if (item.subtitle.isNotEmpty) Text(item.subtitle, style: const TextStyle(color: uiDialogMuted, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
}
