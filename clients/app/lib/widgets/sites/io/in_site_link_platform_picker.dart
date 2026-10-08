import 'package:alienai_c35/c/site/site_link_platform.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/sites/ui_site_platform_icon.dart';
import 'package:flutter/material.dart';

Future<String?> siteLinkPlatformPickerOpen(BuildContext context, {required String initial}) => showDialog<String>(
      context: context,
      builder: (ctx) => _SiteLinkPlatformPickerDialog(initial: initial),
    );

class InSiteLinkPlatformButton extends StatelessWidget {
  const InSiteLinkPlatformButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  Future<void> _open(BuildContext context) async {
    if (readOnly) return;
    final picked = await siteLinkPlatformPickerOpen(context, initial: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final id = siteLinkPlatformNormalize(value);
    return Semantics(
      button: true,
      label: 'Platform: ${siteLinkPlatformLabel(id)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: readOnly ? null : () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: siteEditorFieldBorder),
              color: siteEditorFieldFill,
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(child: UiSitePlatformIcon(id: id, size: 28)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SiteLinkPlatformPickerDialog extends StatefulWidget {
  const _SiteLinkPlatformPickerDialog({required this.initial});

  final String initial;

  @override
  State<_SiteLinkPlatformPickerDialog> createState() => _SiteLinkPlatformPickerDialogState();
}

class _SiteLinkPlatformPickerDialogState extends State<_SiteLinkPlatformPickerDialog> {
  late final _searchCtrl = TextEditingController();
  var _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = siteLinkPlatformNormalize(widget.initial);
    final platforms = siteLinkPlatformFilter(_search);
    return AlertDialog(
      backgroundColor: siteEditorCardBg,
      title: const Text('Choose platform', style: TextStyle(color: siteEditorFormText, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: siteEditorFormText, fontSize: 13),
              decoration: siteEditorInputDecoration(hintText: 'Search platforms').copyWith(
                prefixIcon: const Icon(Icons.search, size: 20, color: siteEditorFormMuted),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 12),
            if (platforms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No matches', style: TextStyle(color: siteEditorFormMuted)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: platforms.length,
                  itemBuilder: (context, i) {
                    final id = platforms[i];
                    return _DialogTile(
                      id: id,
                      selected: selected == id,
                      onTap: () => Navigator.pop(context, id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}

class _DialogTile extends StatelessWidget {
  const _DialogTile({required this.id, required this.selected, required this.onTap});

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? siteEditorFormAccent : siteEditorFieldBorder,
                width: selected ? 1.5 : 1,
              ),
              color: selected ? siteEditorFormAccent.withValues(alpha: 0.12) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Column(
                children: [
                  Expanded(child: Center(child: UiSitePlatformIcon(id: id, size: 28))),
                  Text(
                    siteLinkPlatformLabel(id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.15,
                      color: siteEditorFormText,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
