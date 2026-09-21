import 'package:alienai_c35/c/locale/app_locale.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

class UiLocalePickerDialog extends StatefulWidget {
  const UiLocalePickerDialog({super.key, this.value});
  final Locale? value;

  @override
  State<UiLocalePickerDialog> createState() => _UiLocalePickerDialogState();
}

class _UiLocalePickerDialogState extends State<UiLocalePickerDialog> {
  late final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_searchFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = appLocaleFilter(_searchCtrl.text);
    final current = widget.value;
    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(children: [
              const Expanded(child: Text('Language', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 20, fontWeight: FontWeight.w600))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Color(0xFFA1A1AA))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14),
              decoration: UiInputDecoration.of(
                context,
                hintText: 'English, Indonesia…',
                floatingLabel: false,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF71717A)),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF27272A)),
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
                        title: Text(entry.name, style: const TextStyle(color: Color(0xFFF4F4F5))),
                        subtitle: Text(entry.locale.toLanguageTag(), style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                        trailing: selected ? const Icon(Icons.check, color: Color(0xFF34D399)) : null,
                        onTap: () => Navigator.pop(context, entry.locale),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

Future<Locale?> askAppLocale({required BuildContext context, Locale? value}) => showDialog<Locale>(context: context, builder: (_) => UiLocalePickerDialog(value: value));
