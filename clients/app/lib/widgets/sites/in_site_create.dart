import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';

class SiteCreateResult {
  const SiteCreateResult({required this.siteIid});

  final int siteIid;
}

Future<SiteCreateResult?> inSiteCreateShow(
  BuildContext context, {
  required SiteStore store,
}) async {
  return showDialog<SiteCreateResult>(
    context: context,
    builder: (ctx) => _InSiteCreateDialog(store: store),
  );
}

class _InSiteCreateDialog extends StatefulWidget {
  const _InSiteCreateDialog({required this.store});

  final SiteStore store;

  @override
  State<_InSiteCreateDialog> createState() => _InSiteCreateDialogState();
}

class _InSiteCreateDialogState extends State<_InSiteCreateDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _alienIdCtrl;
  late bool _product;
  late bool _pos;
  late bool _attendance;
  late bool _reservation;
  late bool _busy;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _taglineCtrl = TextEditingController();
    _alienIdCtrl = TextEditingController();
    _product = true;
    _pos = false;
    _attendance = false;
    _reservation = false;
    _busy = false;
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _alienIdCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final slug = siteAlienIdSlug(name);
    if (_alienIdCtrl.text.trim().isEmpty) _alienIdCtrl.text = slug;
    if (_taglineCtrl.text.trim().isEmpty) {
      final locale = Localizations.localeOf(context).toString();
      _taglineCtrl.text = siteTaglineSuggest(name: name, locale: locale);
    }
    setState(() {});
  }

  SiteCreateFeatures get _features => SiteCreateFeatures(
        product: _product,
        pos: _pos,
        attendance: _attendance,
        reservation: _reservation,
      );

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final iid = await widget.store.siteCreate(
        name: name,
        alienId: _alienIdCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim(),
        features: _features,
      );
      if (!mounted) return;
      Navigator.of(context).pop(SiteCreateResult(siteIid: iid));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text.trim();
    return AlertDialog(
      title: const Text('Create site'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  UiUserAvatar(name: name.isEmpty ? 'Site' : name, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: UiInputDecoration.of(context, labelText: 'Name', hintText: 'Grosir Prakarya', floatingLabel: true),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taglineCtrl,
                decoration: UiInputDecoration.of(context, labelText: 'Tagline', hintText: 'Short description', floatingLabel: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alienIdCtrl,
                decoration: UiInputDecoration.of(context, labelText: 'Site URL', hintText: 'grosirprakarya', floatingLabel: true),
              ),
              const SizedBox(height: 16),
              Text('Features', style: Theme.of(context).textTheme.titleSmall),
              CheckboxListTile(
                value: _product,
                onChanged: _busy ? null : (v) => setState(() => _product = v ?? false),
                title: const Text('Product'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: _pos,
                onChanged: _busy ? null : (v) => setState(() => _pos = v ?? false),
                title: const Text('POS'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: _attendance,
                onChanged: _busy ? null : (v) => setState(() => _attendance = v ?? false),
                title: const Text('Attendance'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: _reservation,
                onChanged: _busy ? null : (v) => setState(() => _reservation = v ?? false),
                title: const Text('Reservasi'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create')),
      ],
    );
  }
}
