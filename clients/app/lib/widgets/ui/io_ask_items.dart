import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

class IoAskItemAction {
  const IoAskItemAction({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
}

class IoAskItem {
  const IoAskItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.icon,
    this.accent,
    this.imageUrl,
    this.actions = const [],
    this.trailingLabel,
    this.trailingIcon,
    this.trailing,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? accent;
  final String? imageUrl;
  final List<IoAskItemAction> actions;
  final String? trailingLabel;
  final IconData? trailingIcon;
  final Widget? trailing;
}

Future<IoAskItem?> ioAskItemsShow(
  BuildContext context, {
  required String title,
  required List<IoAskItem> items,
  String searchHint = 'Search…',
  double width = uiDialogAskWidth,
  double height = uiDialogAskHeight,
  IoAskItem? Function(String query)? noMatchItem,
}) =>
    uiDialogShow<IoAskItem>(
      context: context,
      builder: (_) => IoAskItemsDialog(semanticsLabel: title, items: items, searchHint: searchHint, width: width, height: height, noMatchItem: noMatchItem),
    );

class IoAskItemsDialog extends StatefulWidget {
  const IoAskItemsDialog({
    super.key,
    required this.semanticsLabel,
    required this.items,
    this.searchHint = 'Search…',
    this.width = uiDialogAskWidth,
    this.height = uiDialogAskHeight,
    this.loading = false,
    this.emptyText = 'No matches',
    this.noMatchText = 'No matches',
    this.sourceItemCount,
    this.clientSearch = true,
    this.onSearchChanged,
    this.searchController,
    this.searchSuffix,
    this.searchPrefix,
    this.beforeClose = const [],
    this.dividerBelowHeader = false,
    this.bodyGap = 10,
    this.popOnSelect = true,
    this.noMatchItem,
  });

  final String semanticsLabel;
  final List<IoAskItem> items;
  final String searchHint;
  final double width;
  final double height;
  final bool loading;
  final String emptyText;
  final String noMatchText;
  final int? sourceItemCount;
  final bool clientSearch;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final Widget? searchSuffix;
  final Widget? searchPrefix;
  final List<Widget> beforeClose;
  final bool dividerBelowHeader;
  final double bodyGap;
  final bool popOnSelect;
  final IoAskItem? Function(String query)? noMatchItem;

  @override
  State<IoAskItemsDialog> createState() => _IoAskItemsDialogState();
}

class _IoAskItemsDialogState extends State<IoAskItemsDialog> {
  late final TextEditingController _search = widget.searchController ?? TextEditingController();
  var _ownsSearch = false;

  @override
  void initState() {
    super.initState();
    _ownsSearch = widget.searchController == null;
  }

  @override
  void dispose() {
    if (_ownsSearch) _search.dispose();
    super.dispose();
  }

  List<IoAskItem> get _filtered {
    if (!widget.clientSearch) return widget.items;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) => '${item.title} ${item.subtitle}'.toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged(String value) {
    widget.onSearchChanged?.call(value);
    if (widget.clientSearch) setState(() {});
  }

  void _onItemTap(IoAskItem item) {
    if (item.actions.isNotEmpty || !widget.popOnSelect) return;
    Navigator.pop(context, item);
  }

  Widget _body() {
    if (widget.loading) return uiDialogAskLoading();
    var filtered = _filtered;
    if (filtered.isEmpty) {
      final q = _search.text.trim();
      final synthetic = q.isNotEmpty ? widget.noMatchItem?.call(q) : null;
      if (synthetic != null) filtered = [synthetic];
    }
    if (filtered.isEmpty) {
      if (widget.clientSearch && widget.items.isNotEmpty) return uiDialogAskEmptyText(widget.noMatchText);
      final sourceCount = widget.sourceItemCount;
      if (sourceCount != null && sourceCount > 0) return uiDialogAskEmptyText(widget.noMatchText);
      return uiDialogAskEmptyText(widget.emptyText);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) => ioAskItemTile(context, filtered[i], onTap: () => _onItemTap(filtered[i])),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
        namesRoute: true,
        label: widget.semanticsLabel,
        child: UiDialogAskShell(
          width: widget.width,
          height: widget.height,
          searchController: _search,
          hintText: widget.searchHint,
          onSearchChanged: _onSearchChanged,
          searchSuffix: widget.searchSuffix,
          searchPrefix: widget.searchPrefix,
          beforeClose: widget.beforeClose,
          dividerBelowHeader: widget.dividerBelowHeader,
          bodyGap: widget.bodyGap,
          bodyPadding: EdgeInsets.zero,
          body: _body(),
        ),
      );
}

Widget ioAskItemTile(BuildContext context, IoAskItem item, {VoidCallback? onTap}) {
  final accent = item.accent ?? uiDialogAccent;
  final hasLeading = item.imageUrl != null && item.imageUrl!.isNotEmpty || item.icon != null;
  final trailingBadge = item.trailingLabel != null;
  final hasTrailingMenu = item.trailing != null;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: item.actions.isNotEmpty ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          crossAxisAlignment: trailingBadge || hasTrailingMenu ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            if (hasLeading) ...[
              ioAskItemLeading(item: item, accent: accent),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: uiDialogTitleColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (item.subtitle.isNotEmpty)
                    Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: uiDialogMuted, fontSize: 11)),
                  if (item.actions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      children: item.actions.map((a) => ioAskItemActionChip(label: a.label, icon: a.icon, onTap: a.onTap)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingBadge) IgnorePointer(child: ioAskItemTrailingBadge(item.trailingLabel!, accent: accent, leadingIcon: item.trailingIcon)),
            if (hasTrailingMenu) item.trailing!,
          ],
        ),
      ),
    ),
  );
}

Widget ioAskItemTrailingBadge(String label, {Color? accent, IconData? leadingIcon}) {
  final c = accent ?? uiDialogAccent;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 13, color: c),
          const SizedBox(width: 3),
        ],
        Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

Widget ioAskItemLeading({required IoAskItem item, required Color accent}) {
  final url = item.imageUrl?.trim() ?? '';
  final fallback = ioAskItemIconBox(icon: item.icon ?? Icons.language_outlined, accent: accent);
  if (url.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: UiImg(src: url, width: 34, height: 34, fit: BoxFit.cover, fallback: fallback),
    );
  }
  return fallback;
}

Widget ioAskItemIconBox({required IconData icon, required Color accent}) => Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 18, color: accent),
    );

Widget ioAskItemActionChip({required String label, required VoidCallback onTap, IconData? icon}) => Material(
      color: const Color(0xFF3F3F46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF52525B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFFE4E4E7)),
                const SizedBox(width: 4),
              ],
              Text(label, style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
