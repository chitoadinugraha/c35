import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String mailboxLocalPartNorm(String input) => input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._+-]'), '');

String mailboxJoinAddress(String local, String domain) {
  final l = mailboxLocalPartNorm(local).trim();
  final d = domain.trim().toLowerCase();
  if (l.isEmpty || d.isEmpty) return '';
  return '$l@$d';
}

class InMailbox extends StatefulWidget {
  const InMailbox({
    super.key,
    required this.domains,
    this.localPart = '',
    this.domain = '',
    this.labelText = 'Email',
    this.enabled = true,
    this.onChanged,
  });

  final List<String> domains;
  final String localPart;
  final String domain;
  final String labelText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<InMailbox> createState() => InMailboxState();
}

class InMailboxState extends State<InMailbox> {
  late final TextEditingController _localCtrl;
  late String _domain;

  String get address => mailboxJoinAddress(_localCtrl.text, _domain);

  @override
  void initState() {
    super.initState();
    final initial = widget.localPart.trim();
    if (initial.contains('@')) {
      final at = initial.lastIndexOf('@');
      _localCtrl = TextEditingController(text: mailboxLocalPartNorm(initial.substring(0, at)));
      _domain = initial.substring(at + 1).trim().toLowerCase();
    } else {
      _localCtrl = TextEditingController(text: mailboxLocalPartNorm(initial));
      _domain = widget.domain.trim().toLowerCase();
    }
    if (_domain.isEmpty && widget.domains.isNotEmpty) _domain = widget.domains.first;
    _localCtrl.addListener(_notify);
  }

  @override
  void didUpdateWidget(InMailbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.domains.isNotEmpty && !widget.domains.contains(_domain)) {
      _domain = widget.domains.first;
      _notify();
    }
  }

  @override
  void dispose() {
    _localCtrl.removeListener(_notify);
    _localCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged?.call(address);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final domains = widget.domains;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.labelText, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _localCtrl,
                enabled: widget.enabled,
                decoration: UiInputDecoration.of(context, hintText: 'support'),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._+\-]'))],
                textInputAction: TextInputAction.done,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('@', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              flex: 4,
              child: domains.isEmpty
                  ? Text('—', style: TextStyle(color: cs.onSurfaceVariant))
                  : DropdownButtonFormField<String>(
                      value: domains.contains(_domain) ? _domain : domains.first,
                      items: [for (final d in domains) DropdownMenuItem(value: d, child: Text(d))],
                      onChanged: widget.enabled
                          ? (v) {
                              if (v == null) return;
                              setState(() => _domain = v);
                              _notify();
                            }
                          : null,
                      decoration: UiInputDecoration.of(context),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
