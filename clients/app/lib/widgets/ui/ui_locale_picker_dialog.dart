import 'package:alienai_c35/c/locale/app_locale.dart';
import 'package:alienai_c35/widgets/ui/ui_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

class UiLocalePickerDialog extends StatefulWidget {
  const UiLocalePickerDialog({super.key, this.value});
  final Locale? value;

  @override
  State<UiLocalePickerDialog> createState() => _UiLocalePickerDialogState();
}

class _UiLocalePickerDialogState extends State<UiLocalePickerDialog> {
  late final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = appLocaleFilter(_searchCtrl.text);
    final current = widget.value;
    return UiDialog(
      maxWidth: 360,
      padding: EdgeInsets.zero,
      inset: true,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: uiDialogInsetCompact,
          child: UiDialogSearchHeader(
            controller: _searchCtrl,
            hintText: 'English, Indonesia…',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Divider(height: 1, color: uiDialogBorder),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: filtered.isEmpty
              ? const Padding(padding: EdgeInsets.all(24), child: Text('No matches', textAlign: TextAlign.center))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final entry = filtered[i];
                    final selected = current != null && appLocaleSame(entry.locale, current);
                    return ListTile(
                      leading: UiImg(src: entry.flag, width: 22, height: 22, recolor: false),
                      title: Text(entry.name, style: const TextStyle(color: uiDialogTitleColor)),
                      subtitle: Text(entry.locale.toLanguageTag(), style: const TextStyle(color: uiDialogMuted, fontSize: 12)),
                      trailing: selected ? const Icon(Icons.check, color: uiDialogAccent) : null,
                      onTap: () => Navigator.pop(context, entry.locale),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

Future<Locale?> askAppLocale({required BuildContext context, Locale? value}) =>
    uiDialogShow<Locale>(context: context, builder: (_) => UiLocalePickerDialog(value: value));
