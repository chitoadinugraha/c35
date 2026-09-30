import 'package:alienai_c35/c/profile/profile_handle.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_store.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  var _alienIdTouched = false;
  var _taglinePick = 0;
  String? _error;

  static const _taglineMax = 120;
  static const _siteUrlPrefix = '$profileAlienDomain/';

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
    _alienIdCtrl.addListener(() => setState(() {}));
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
    if (_alienIdTouched) {
      setState(() {});
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _alienIdCtrl.clear();
    } else {
      _alienIdCtrl.text = siteAlienIdSlug(name);
    }
    setState(() {});
  }

  void _generateTagline() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a site name first');
      return;
    }
    setState(() {
      _error = null;
      _taglinePick++;
      _taglineCtrl.text = siteTaglineSuggest(
        name: name,
        locale: Localizations.localeOf(context).toString(),
        pick: _taglinePick,
      );
    });
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

  Widget _taglineSuffix(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: 'Generate tagline',
      onPressed: _busy ? null : _generateTagline,
      icon: Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.primary),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final slug = _alienIdCtrl.text.trim();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
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
                      decoration: UiInputDecoration.of(context, labelText: 'Name', hintText: 'Your site name', floatingLabel: true),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alienIdCtrl,
                onChanged: (_) => _alienIdTouched = true,
                decoration: UiInputDecoration.of(
                  context,
                  labelText: 'Site URL',
                  hintText: 'your-site',
                  prefixText: _siteUrlPrefix,
                  floatingLabel: true,
                ),
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
                  TextInputFormatter.withFunction((old, neu) {
                    final lower = neu.text.toLowerCase();
                    return lower == neu.text ? neu : neu.copyWith(text: lower);
                  }),
                ],
              ),
              if (slug.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text('https://$_siteUrlPrefix$slug', style: muted),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _taglineCtrl,
                maxLength: _taglineMax,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                minLines: 2,
                maxLines: 4,
                decoration: UiInputDecoration.of(
                  context,
                  labelText: 'Tagline',
                  hintText: 'Short description',
                  floatingLabel: true,
                  alignLabelWithHint: true,
                  suffixIcon: _taglineSuffix(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text('Tap ', style: muted),
                    Icon(Icons.auto_awesome, size: 14, color: theme.colorScheme.primary),
                    Text(' to generate a tagline', style: muted),
                  ],
                ),
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
