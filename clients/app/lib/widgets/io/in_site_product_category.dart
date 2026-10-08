import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:flutter/material.dart';

const _addCategoryIdPrefix = 'add:';

String siteCategoryTitleCase(String raw) {
  final q = raw.trim();
  if (q.isEmpty) return q;
  return q
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

/// Category labels already used on products. Duplicates are kept so the picker can show counts.
List<String> siteProductCategoryLabels(Iterable<String> categories) =>
    categories.map((c) => c.trim()).where((c) => c.isNotEmpty).toList(growable: false);

class InSiteProductCategory extends StatelessWidget {
  const InSiteProductCategory({
    super.key,
    required this.value,
    required this.categories,
    required this.onCommit,
    this.enabled = true,
  });

  final String value;
  final List<String> categories;
  final Future<void> Function(String value) onCommit;
  final bool enabled;

  String get _current => value.trim();

  Map<String, int> get _counts {
    final counts = <String, int>{};
    for (final raw in categories) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  String _countSubtitle(int n) {
    if (n <= 0) return '';
    return n == 1 ? '1 product' : '$n products';
  }

  Future<void> _pick(BuildContext context) async {
    final counts = _counts;
    final names = <String>{...counts.keys, if (_current.isNotEmpty) _current}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final items = <IoAskItem>[
      const IoAskItem(
        id: '',
        title: 'No category',
        subtitle: 'Leave unset',
        icon: Icons.label_off_outlined,
      ),
      ...names.map(
        (name) => IoAskItem(
          id: name,
          title: name,
          subtitle: _countSubtitle(counts[name] ?? 0),
          icon: Icons.category_outlined,
        ),
      ),
    ];
    final picked = await ioAskItemsShow(
      context,
      title: 'Pick category',
      items: items,
      searchHint: 'Search category...',
      noMatchItem: (q) => IoAskItem(
        id: '$_addCategoryIdPrefix$q',
        title: siteCategoryTitleCase(q),
        subtitle: 'New category',
        icon: Icons.category_outlined,
        trailingIcon: Icons.add,
        trailingLabel: 'Add new',
      ),
    );
    if (picked == null) return;
    if (picked.id.startsWith(_addCategoryIdPrefix)) {
      final name = siteCategoryTitleCase(picked.id.substring(_addCategoryIdPrefix.length));
      if (name.isEmpty) return;
      await onCommit(name);
      return;
    }
    await onCommit(picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final empty = _current.isEmpty;
    return Material(
      color: siteEditorFieldFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: siteEditorFieldBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => _pick(context) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.category_outlined, size: 16, color: empty ? siteEditorFormMuted : siteEditorFormAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  empty ? 'Optional category' : _current,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: empty ? siteEditorFormMuted : siteEditorFormText, fontSize: 13),
                ),
              ),
              const Icon(Icons.expand_more, size: 20, color: siteEditorFormMuted),
            ],
          ),
        ),
      ),
    );
  }
}
