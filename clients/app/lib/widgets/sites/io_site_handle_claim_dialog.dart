import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/auth/ui_auth_logo.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFF8E8E98);
const _accent = Color(0xFF10B981);
const _card = Color(0xFF141418);

/// Returns claimed handle slug, or null if cancelled.
Future<String?> ioSiteHandleClaimDialogOpen(
  BuildContext context, {
  required String siteName,
  String initialHandle = '',
  bool isChange = false,
}) =>
    showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _SiteHandleClaimDialog(
        siteName: siteName,
        initialHandle: initialHandle,
        isChange: isChange,
      ),
    );

class _SiteHandleClaimDialog extends StatefulWidget {
  const _SiteHandleClaimDialog({
    required this.siteName,
    required this.initialHandle,
    required this.isChange,
  });

  final String siteName;
  final String initialHandle;
  final bool isChange;

  @override
  State<_SiteHandleClaimDialog> createState() => _SiteHandleClaimDialogState();
}

class _SiteHandleClaimDialogState extends State<_SiteHandleClaimDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initialHandle);
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final err = siteHandleFormatError(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, siteAlienIdSlug(_ctrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final slug = siteAlienIdSlug(_ctrl.text);
    final title = widget.isChange ? 'Change site link' : 'Pick your handle';
    return Dialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(child: UiAuthLogo(size: 44)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alien AI',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isChange
                    ? 'Pick a new public URL for ${widget.siteName}.'
                    : 'Choose a memorable link for ${widget.siteName}. Until then, visitors use your numeric site ID.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: _text, fontSize: 15),
                decoration: UiInputDecoration.of(
                  context,
                  labelText: 'Handle',
                  hintText: 'kopi-senja',
                  prefixText: siteUrlPrefix,
                ).copyWith(
                  errorText: _error,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
                    borderSide: BorderSide(color: _error != null ? const Color(0xFFF87171) : const Color(0xFF26262E)),
                  ),
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
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    'https://$siteUrlPrefix$slug',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: _muted)),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: _submit,
                    child: Text(widget.isChange ? 'Save' : 'Claim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
