import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:alienai_c35/c/site/design/site_font.dart';
import 'package:alienai_c35/c/site/design/site_font_loader.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';

Future<String?> fontPickerOpen(BuildContext context, {required String initial}) => showDialog<String>(
      context: context,
      builder: (ctx) => _FontPickerDialog(initial: siteFontNormalizeId(initial)),
    );

class InFont extends StatelessWidget {
  const InFont({super.key, required this.value, required this.onChanged, this.labelText = 'Font'});

  final String value;
  final ValueChanged<String> onChanged;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = siteFontNormalizeId(value);
    final label = siteFontLabel(id);
    return ListenableBuilder(
      listenable: SiteFontLoader.instance,
      builder: (context, _) {
        final preview = siteFontTextStyle(
          familyId: id,
          base: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
        );
        return Semantics(
          button: true,
          label: '$labelText: $label',
          child: InkWell(
            onTap: () async {
              final picked = await fontPickerOpen(context, initial: id);
              if (picked != null && picked != id) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
            child: InputDecorator(
              decoration: UiInputDecoration.of(context, labelText: labelText),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: preview, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Icon(Icons.unfold_more, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FontPickerDialog extends StatefulWidget {
  const _FontPickerDialog({required this.initial});

  final String initial;

  @override
  State<_FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<_FontPickerDialog> {
  late final TextEditingController _searchCtrl = TextEditingController();
  var _search = '';
  var _category = SiteFontCategory.suggested;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = siteFontEntriesFor(_category, query: _search);
    return AlertDialog(
      title: Text('io.chooseFont'.tr()),
      content: SizedBox(
        width: 400,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: UiInputDecoration.of(context, hintText: 'io.searchFonts'.tr(), isDense: true, floatingLabel: false),
              autofocus: true,
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in SiteFontCategory.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(siteFontCategoryLabel(c)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('io.noFontsMatch'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    )
                  : ListenableBuilder(
                      listenable: SiteFontLoader.instance,
                      builder: (context, _) => ListView.separated(
                        // Lazy: only visible rows build; SiteFontLoader fetches TTFs on first paint.
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = items[i];
                          final selected = e.id == widget.initial;
                          final style = siteFontTextStyle(
                            familyId: e.id,
                            base: TextStyle(fontSize: 16, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                          );
                          return ListTile(
                            dense: true,
                            title: Text(e.label, style: style),
                            trailing: selected ? const Icon(Icons.check, size: 20) : null,
                            onTap: () => Navigator.pop(context, e.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr()))],
    );
  }
}
