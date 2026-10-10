import 'package:alienai_c35/widgets/ui/io_ask_items.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const posTxTagsButtonKey = Key('pos-tx-tags');

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _accent = Color(0xFF34D399);
const _addTagIdPrefix = 'add:';

/// Strip a leading `#` and surrounding space. Empty input is not a tag.
String? normalizeTxTag(String raw) {
  var s = raw.trim();
  while (s.startsWith('#')) {
    s = s.substring(1).trim();
  }
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return null;
  return s;
}

String? _sameTag(Iterable<String> tags, String tag) {
  final key = tag.toLowerCase();
  for (final existing in tags) {
    if (existing.toLowerCase() == key) return existing;
  }
  return null;
}

class TxTagSelection {
  const TxTagSelection({required this.catalog, required this.selected});

  final List<String> catalog;
  final List<String> selected;
}

/// `#` button. Opens a searchable multi-select list; a query with no match can create a tag.
class InSiteTxTags extends StatelessWidget {
  const InSiteTxTags({
    super.key,
    required this.catalog,
    required this.selected,
    required this.onChanged,
  });

  final List<String> catalog;
  final List<String> selected;
  final ValueChanged<TxTagSelection> onChanged;

  Future<void> _pick(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TxTagPickerDialog(
        catalog: catalog,
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = selected.isNotEmpty;
    return Tooltip(
      message: 'site.pos.tags'.tr(),
      child: Material(
        color: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border),
        ),
        child: InkWell(
          key: posTxTagsButtonKey,
          borderRadius: BorderRadius.circular(8),
          onTap: () => _pick(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              '#',
              style: TextStyle(
                color: active ? _accent : _muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TxTagPickerDialog extends StatefulWidget {
  const _TxTagPickerDialog({
    required this.catalog,
    required this.selected,
    required this.onChanged,
  });

  final List<String> catalog;
  final List<String> selected;
  final ValueChanged<TxTagSelection> onChanged;

  @override
  State<_TxTagPickerDialog> createState() => _TxTagPickerDialogState();
}

class _TxTagPickerDialogState extends State<_TxTagPickerDialog> {
  final _search = TextEditingController();
  late List<String> _catalog = List<String>.of(widget.catalog);
  late final List<String> _selected = List<String>.of(widget.selected);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(TxTagSelection(
      catalog: List<String>.unmodifiable(_catalog),
      selected: List<String>.unmodifiable(_selected),
    ));
  }

  void _toggle(String tag) {
    setState(() {
      final existing = _sameTag(_selected, tag);
      if (existing != null) {
        _selected.remove(existing);
      } else {
        _selected.add(tag);
      }
    });
    _emit();
  }

  void _create(String raw) {
    final tag = normalizeTxTag(raw);
    if (tag == null) return;
    final known = _sameTag(_catalog, tag);
    setState(() {
      final name = known ?? tag;
      if (known == null) {
        _catalog = [..._catalog, name]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }
      if (_sameTag(_selected, name) == null) _selected.add(name);
      _search.clear();
    });
    _emit();
  }

  bool _matches(String name, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final n = name.toLowerCase();
    if (n.contains(q)) return true;
    final normalized = normalizeTxTag(query)?.toLowerCase();
    return normalized != null && n.contains(normalized);
  }

  List<IoAskItem> _items(String query) {
    final names = [..._catalog]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final visible = names.where((name) => _matches(name, query)).toList();
    final items = visible
        .map(
          (name) => IoAskItem(
            id: name,
            title: name,
            icon: Icons.tag,
            trailing: _sameTag(_selected, name) != null ? const Icon(Icons.check, size: 18, color: _accent) : null,
          ),
        )
        .toList();
    final normalized = normalizeTxTag(query);
    final exact = normalized == null ? null : _sameTag(_catalog, normalized);
    if (normalized != null && exact == null && visible.isEmpty) {
      items.add(IoAskItem(
        id: '$_addTagIdPrefix$normalized',
        title: normalized,
        subtitle: 'site.pos.newTag'.tr(),
        icon: Icons.tag,
        trailingIcon: Icons.add,
        trailingLabel: 'site.pos.addNew'.tr(),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(_search.text);
    return Semantics(
      namesRoute: true,
      label: 'site.pos.tags'.tr(),
      child: UiDialogAskShell(
        width: uiDialogAskWidth,
        height: uiDialogAskHeight,
        searchController: _search,
        hintText: 'site.pos.searchTag'.tr(),
        onSearchChanged: (_) => setState(() {}),
        bodyPadding: EdgeInsets.zero,
        body: items.isEmpty
            ? uiDialogAskEmptyText('site.pos.noTags'.tr())
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ioAskItemTile(
                    context,
                    item,
                    onTap: () {
                      if (item.id.startsWith(_addTagIdPrefix)) {
                        _create(item.id.substring(_addTagIdPrefix.length));
                        return;
                      }
                      _toggle(item.id);
                    },
                  );
                },
              ),
      ),
    );
  }
}
